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
    
    // MARK: - Initialization
    
    init() {}
    
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
        
        // Build file path
        let pointDir = context.locationDir
            .appendingPathComponent("scan_records_v1", isDirectory: true)
            .appendingPathComponent(pointID, isDirectory: true)
        let fileURL = pointDir.appendingPathComponent("\(sessionID).json")
        
        // Delete file
        try FileManager.default.removeItem(at: fileURL)
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
        let scanRecordsDir = context.locationDir
            .appendingPathComponent("scan_records_v1", isDirectory: true)
        
        // Check if directory exists
        guard FileManager.default.fileExists(atPath: scanRecordsDir.path) else {
            print("ℹ️ No scan_records_v1 directory found")
            return []
        }
        
        // Get all subdirectories (each is a pointID)
        let pointDirs = try FileManager.default.contentsOfDirectory(
            at: scanRecordsDir,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ).filter { url in
            (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
        }
        
        var entries: [MapPointLogEntry] = []
        
        for pointDir in pointDirs {
            let pointID = pointDir.lastPathComponent
            
            // Get all JSON files in this point directory
            let sessionFiles = try FileManager.default.contentsOfDirectory(
                at: pointDir,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: [.skipsHiddenFiles]
            ).filter { $0.pathExtension == "json" }
            
            guard !sessionFiles.isEmpty else { continue }
            
            // Parse metadata from each session file
            var sessionMetadata: [SessionMetadata] = []
            
            for fileURL in sessionFiles {
                if let metadata = try? await extractSessionMetadata(from: fileURL) {
                    sessionMetadata.append(metadata)
                }
            }
            
            // Get coordinates and color from MapPointStore
            let mapPoint = mapPointStore?.points.first { $0.id.uuidString == pointID }
            let coordinates = mapPoint?.mapPoint ?? .zero
            // MapPoint doesn't store color, generate from pointID hash
            let color = mapPoint != nil ? colorForPointID(pointID) : .gray
            
            entries.append(MapPointLogEntry(
                id: pointID,
                coordinates: coordinates,
                color: color,
                sessions: sessionMetadata.sorted { $0.timestamp > $1.timestamp }
            ))
        }
        
        return entries
    }
    
    /// Extract metadata from a scan record JSON file without loading full data
    private func extractSessionMetadata(from fileURL: URL) async throws -> SessionMetadata {
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
            fileURL: fileURL
        )
    }
    
    /// Build array of MapPointData for export by loading full scan records
    private func buildMapPointDataArray() async throws -> [MapPointData] {
        var result: [MapPointData] = []
        
        for entry in mapPoints {
            var scanRecords: [MapPointScanUtility.ScanRecord] = []
            
            for session in entry.sessions {
                let data = try Data(contentsOf: session.fileURL)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let record = try decoder.decode(MapPointScanUtility.ScanRecord.self, from: data)
                scanRecords.append(record)
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

