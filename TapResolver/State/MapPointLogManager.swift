//
//  MapPointLogManager.swift
//  TapResolver
//
//  Created on 10/12/2025
//
//  Role: Manages discovery, indexing, and export of scan session data across all map points.
//  - Scans {locationDir}/scan_records_v1/{pointID}/ for JSON files
//  - Provides in-memory index of sessions per map point
//  - Handles deletion of individual sessions
//  - Generates master export JSON containing all sessions
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class MapPointLogManager: ObservableObject {
    
    // MARK: - Published State
    
    /// All map points that have recorded scan data
    @Published private(set) var mapPoints: [MapPointLogEntry] = []
    
    /// Loading state
    @Published private(set) var isLoading = false
    
    /// Last error encountered
    @Published private(set) var lastError: String?
    
    // MARK: - Dependencies
    
    /// Reference to MapPointStore to get coordinates and colors
    private weak var mapPointStore: MapPointStore?
    
    /// Current persistence context
    private var currentContext: PersistenceContext?
    
    /// Combine subscription bag
    private var bag = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        // Reload scan data when location changes (matches BeaconListsStore pattern)
        NotificationCenter.default.publisher(for: .locationDidChange)
            .sink { [weak self] _ in
                guard let self = self else { return }
                Task { @MainActor in
                    print("📍 MapPointLogManager: Location changed, reloading scan data...")
                    await self.loadAll(context: PersistenceContext.shared)
                }
            }
            .store(in: &bag)
    }
    
    /// Wire up dependency to MapPointStore (call from AppBootstrap)
    func setMapPointStore(_ store: MapPointStore) {
        self.mapPointStore = store
    }
    
    // MARK: - Public API
    
    /// Scan filesystem and build index of all map points with scan data
    /// - Parameter context: The current location's persistence context
    func loadAll(context: PersistenceContext) async {
        isLoading = true
        lastError = nil
        currentContext = context
        
        do {
            let entries = try await discoverMapPoints(context: context)
            self.mapPoints = entries.sorted { $0.id < $1.id }
            print("📊 Loaded \(mapPoints.count) map points")
        } catch {
            lastError = "Failed to load scan data: \(error.localizedDescription)"
            print("❌ MapPointLogManager.loadAll error: \(error)")
        }
        
        isLoading = false
    }
    
    /// Delete a specific scan session from disk and update index
    /// - Parameters:
    ///   - pointID: The map point identifier
    ///   - sessionID: The session identifier (filename without .json)
    func deleteSession(pointID: String, sessionID: String) async throws {
        guard let context = currentContext else {
            throw MapPointLogError.noContext
        }
        
        // Find the actual file URL from the session metadata
        guard let pointEntry = mapPoints.first(where: { $0.id == pointID }),
              let session = pointEntry.sessions.first(where: { $0.id == sessionID }) else {
            throw MapPointLogError.invalidSession
        }
        
        // Delete using the actual file URL from metadata
        try FileManager.default.removeItem(at: session.fileURL)
        print("🗑️ Deleted session: \(pointID)/\(sessionID)")
        
        // Update in-memory index
        if let pointIndex = mapPoints.firstIndex(where: { $0.id == pointID }) {
            var updatedPoint = mapPoints[pointIndex]
            updatedPoint.sessions.removeAll { $0.id == sessionID }
            
            // If no sessions left, remove the entire map point entry
            if updatedPoint.sessions.isEmpty {
                mapPoints.remove(at: pointIndex)
            } else {
                mapPoints[pointIndex] = updatedPoint
            }
        }
    }
    
    /// Generate master export JSON containing all current scan data
    /// - Returns: JSON data ready for export
    func exportMasterJSON() async throws -> Data {
        guard let context = currentContext else {
            throw MapPointLogError.noContext
        }
        
        // Build master export structure
        let masterExport = MasterExport(
            exportDate: ISO8601DateFormatter().string(from: Date()),
            locationID: context.locationID,
            metadata: ExportMetadata(
                appVersion: appVersion(),
                totalMapPoints: mapPoints.count,
                totalSessions: mapPoints.reduce(0) { $0 + $1.sessions.count }
            ),
            mapPoints: try await buildMapPointDataArray()
        )
        
        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        return try encoder.encode(masterExport)
    }
    
    // MARK: - Private Helpers
    
    /// Scan filesystem for all map points with scan data
    private func discoverMapPoints(context: PersistenceContext) async throws -> [MapPointLogEntry] {
        // Use PersistenceService to list all scans (matches how scans are actually saved)
        let scanURLs = try PersistenceService.listScans(locationID: context.locationID)
        
        guard !scanURLs.isEmpty else {
            print("ℹ️ No scans found via PersistenceService")
            return []
        }
        
        print("📁 Found \(scanURLs.count) scan files")
        
        // Group scans by pointID
        var scansByPoint: [String: [URL]] = [:]
        for url in scanURLs {
            do {
                let scan = try PersistenceService.readScan(url)
                scansByPoint[scan.pointID, default: []].append(url)
            } catch {
                print("⚠️ Failed to read scan at \(url): \(error)")
                continue
            }
        }
        
        var entries: [MapPointLogEntry] = []
        
        for (pointID, urls) in scansByPoint {
            // Parse metadata from each session file
            var sessionMetadata: [SessionMetadata] = []
            
            for fileURL in urls {
                if let metadata = try? await extractSessionMetadataFromV1(from: fileURL) {
                    sessionMetadata.append(metadata)
                }
            }
            
            guard !sessionMetadata.isEmpty else { continue }
            
            // Get coordinates IN METERS from the first scan file (all scans at same point have same coordinates)
            var coordinates: CGPoint = .zero
            if let firstURL = urls.first {
                do {
                    let scan = try PersistenceService.readScan(firstURL)
                    // Use meters from scan data, not pixels from MapPointStore
                    // Note: xy_m is optional, so safely unwrap it
                    if let xy_m = scan.point.xy_m, xy_m.count == 2 {
                        coordinates = CGPoint(x: xy_m[0], y: xy_m[1])
                    }
                } catch {
                    print("⚠️ Failed to read coordinates from scan: \(error)")
                }
            }
            
            let color = colorForPointID(pointID)
            
            entries.append(MapPointLogEntry(
                id: pointID,
                coordinates: coordinates,
                color: color,
                sessions: sessionMetadata.sorted { $0.timestamp > $1.timestamp }
            ))
        }
        
        print("📊 Discovered \(entries.count) map points with scan data")
        return entries
    }
    
    /// Extract metadata from a V1 scan record JSON file
    private func extractSessionMetadataFromV1(from fileURL: URL) async throws -> SessionMetadata {
        let scan = try PersistenceService.readScan(fileURL)
        
        // Use scan ID from filename (more reliable than embedded scanID)
        let sessionID = fileURL.deletingPathExtension().lastPathComponent
        let timestamp = ISO8601DateFormatter().date(from: scan.timing.startISO) ?? Date()
        let duration = scan.timing.duration_s
        let beaconCount = scan.beacons.count
        
        return SessionMetadata(
            id: sessionID,
            timestamp: timestamp,
            duration: duration,
            beaconCount: beaconCount,
            facing: scan.user.facing_deg,
            fileURL: fileURL
        )
    }
    
    /// Extract metadata from a scan record JSON file without loading full data (LEGACY FORMAT)
    private func extractSessionMetadataLegacy(from fileURL: URL) async throws -> SessionMetadata {
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // Parse just enough to get metadata
        let record = try decoder.decode(MapPointScanUtility.ScanRecord.self, from: data)
        
        let sessionID = fileURL.deletingPathExtension().lastPathComponent
        let timestamp = ISO8601DateFormatter().date(from: record.timingStartISO) ?? Date()
        let duration = record.duration_s
        let beaconCount = record.beacons.count
        
        return SessionMetadata(
            id: sessionID,
            timestamp: timestamp,
            duration: duration,
            beaconCount: beaconCount,
            facing: record.userFacing_deg,
            fileURL: fileURL
        )
    }
    
    /// Build array of MapPointData for export by loading full scan records
    private func buildMapPointDataArray() async throws -> [MapPointData] {
        var result: [MapPointData] = []
        
        for entry in mapPoints {
            var scanRecords: [MapPointScanUtility.ScanRecord] = []
            
            for session in entry.sessions {
                do {
                    // Try V1 format first
                    let scan = try PersistenceService.readScan(session.fileURL)
                    // Convert V1 ScanRecordV1 to old ScanRecord format for export compatibility
                    // For now, skip this - we'll update export format separately
                    // Just load the scan to verify it exists
                    print("✓ Loaded V1 scan: \(session.id)")
                } catch {
                    // Fall back to legacy format
                    let data = try Data(contentsOf: session.fileURL)
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let record = try decoder.decode(MapPointScanUtility.ScanRecord.self, from: data)
                    scanRecords.append(record)
                }
            }
            
            result.append(MapPointData(
                pointID: entry.id,
                coordinates: entry.coordinates,
                sessions: scanRecords
            ))
        }
        
        return result
    }
    
    /// Get app version string
    private func appVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }
    
    /// Generate a consistent color for a point ID
    private func colorForPointID(_ pointID: String) -> Color {
        let hash = abs(pointID.hashValue)
        let hue = Double(hash % 360) / 360.0
        return Color(hue: hue, saturation: 0.7, brightness: 0.8)
    }
}

// MARK: - Data Models

extension MapPointLogManager {
    
    /// Represents a map point with its scan sessions
    struct MapPointLogEntry: Identifiable {
        let id: String // pointID
        var coordinates: CGPoint
        let color: Color
        var sessions: [SessionMetadata]
    }
    
    /// Lightweight metadata for a scan session
    struct SessionMetadata: Identifiable {
        let id: String // sessionID (filename without .json)
        let timestamp: Date
        let duration: TimeInterval
        let beaconCount: Int
        let facing: Double? // degrees, 0-360
        let fileURL: URL
    }
}

// MARK: - Export Models

/// Master export structure containing all scan data
struct MasterExport: Codable {
    let exportDate: String // ISO8601
    let locationID: String
    let metadata: ExportMetadata
    let mapPoints: [MapPointData]
}

/// Export metadata summary
struct ExportMetadata: Codable {
    let appVersion: String
    let totalMapPoints: Int
    let totalSessions: Int
}

/// Map point data for export
struct MapPointData: Codable {
    let pointID: String
    let coordinates: CGPoint
    let sessions: [MapPointScanUtility.ScanRecord]
}

// MARK: - Errors

enum MapPointLogError: LocalizedError {
    case noContext
    case invalidSession
    case exportFailed
    
    var errorDescription: String? {
        switch self {
        case .noContext:
            return "No location context available"
        case .invalidSession:
            return "Invalid session data"
        case .exportFailed:
            return "Failed to generate export"
        }
    }
}

