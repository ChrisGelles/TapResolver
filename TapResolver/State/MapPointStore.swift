//
//  MapPointStore.swift
//  TapResolver
//
//  Created by restructuring on 9/24/25.
//

import SwiftUI
import CoreGraphics
import Combine
import simd

// Notification for when map points reload
extension Notification.Name {
    static let mapPointsDidReload = Notification.Name("mapPointsDidReload")
    static let scanSessionSaved = Notification.Name("scanSessionSaved")
}

// MARK: - Store of Map Points (log points) with map-local positions
public final class MapPointStore: ObservableObject {
    internal let ctx = PersistenceContext.shared
    private var scanSessionCancellable: AnyCancellable?
    
    // CRITICAL: Prevent data loss during reload operations
    internal var isReloading: Bool = false
    
    // DIAGNOSTIC: Track which instance this is
    internal let instanceID = UUID().uuidString
    
    public struct MapPoint: Identifiable {
        public let id: UUID
        public var mapPoint: CGPoint    // map-local (untransformed) coords
        public let createdDate: Date
        public var sessions: [ScanSession] = []  // Full scan session data stored in UserDefaults
        var linkedARMarkerID: UUID?  // Optional - links to legacy ARMarker if one exists
        public var arMarkerID: String?  // Links to ARWorldMapStore marker
        
        // Initializer that accepts existing ID or generates new one
        init(id: UUID? = nil, mapPoint: CGPoint, createdDate: Date? = nil, sessions: [ScanSession] = []) {
            self.id = id ?? UUID()
            self.mapPoint = mapPoint
            self.createdDate = createdDate ?? Date()
            self.sessions = sessions
            self.linkedARMarkerID = nil
            self.arMarkerID = nil
        }
    }
    
    // Scan session data structure - mirrors the v1 JSON schema
    public struct ScanSession: Codable, Identifiable {
        public let scanID: String
        public let sessionID: String
        public let pointID: String
        public let locationID: String
        
        public let timingStartISO: String
        public let timingEndISO: String
        public let duration_s: Double
        
        public let deviceHeight_m: Double
        public let facing_deg: Double?
        
        public let beacons: [BeaconData]
        
        public var id: String { sessionID }
        
        public struct RssiSample: Codable {
            public let rssi: Int  // RSSI value in dBm
            public let ms: Int64  // Milliseconds since session start
        }
        
        public struct BeaconData: Codable {
            public let beaconID: String
            public let stats: Stats
            public let hist: Histogram
            public let samples: [RssiSample]?  // Optional for backward compatibility
            public let meta: Metadata
            
            public struct Stats: Codable {
                public let median_dbm: Int
                public let mad_db: Int
                public let p10_dbm: Int
                public let p90_dbm: Int
                public let samples: Int
            }
            
            public struct Histogram: Codable {
                public let binMin_dbm: Int
                public let binMax_dbm: Int
                public let binSize_db: Int
                public let counts: [Int]
            }
            
            public struct Metadata: Codable {
                public let name: String
                public let model: String?
                public let txPower: Int?
                public let msInt: Int?
            }
        }
    }

    @Published public internal(set) var points: [MapPoint] = []
    @Published var arMarkers: [ARMarker] = []
    @Published var anchorPackages: [AnchorPointPackage] = []
    
    // Calibration state (session-only, never persisted)
    @Published var calibrationPoints: [CalibrationMarker] = []
    @Published var isCalibrated: Bool = false
    
    @Published public private(set) var activePointID: UUID? = nil
    
    // Interpolation mode state
    @Published var isInterpolationMode: Bool = false
    @Published var interpolationFirstPointID: UUID? = nil
    @Published var interpolationSecondPointID: UUID? = nil
    
    /// Get the currently active map point
    public var activePoint: MapPoint? {
        guard let activeID = activePointID else { return nil }
        return points.first { $0.id == activeID }
    }
    
    /// Reload data for the active location
    public func reloadForActiveLocation() {
        clearAndReloadForActiveLocation()
    }
    
    public func clearAndReloadForActiveLocation() {
        print("🔄 MapPointStore: Starting reload for location '\(ctx.locationID)'")
        
        // Set flag to prevent saves during reload
        isReloading = true
        
        // Clear in-memory data
        points.removeAll()
        activePointID = nil
        
        // Load fresh data for current location
        load()
        
        // Re-enable saves
        isReloading = false
        
        objectWillChange.send()
        
        // Notify that map points have reloaded - trigger session index rebuild
        NotificationCenter.default.post(name: .mapPointsDidReload, object: nil)
        
        print("✅ MapPointStore: Reload complete - \(points.count) points loaded")
    }
    
    /// Explicitly clear all map points for the current location
    /// This bypasses the empty-save protection and WILL delete data
    public func clearAllPoints() {
        print("🗑️ MapPointStore: Explicitly clearing all points for location '\(ctx.locationID)'")
        print("   Previous count: \(points.count)")
        
        points.removeAll()
        activePointID = nil
        
        // Temporarily allow empty save for explicit clear
        let wasReloading = isReloading
        isReloading = false
        save()
        isReloading = wasReloading
        
        print("   ✅ All points cleared and saved")
    }
    
    func flush() {
        points.removeAll()
        activePointID = nil
        objectWillChange.send()
    }

    // MARK: persistence keys
    private let pointsKey = "MapPoints_v1"
    private let activePointKey = "MapPointsActive_v1"

    public init() {
        print("ðŸ§  MapPointStore init â€” ID: \(String(instanceID.prefix(8)))...")
        load()
        
        // Listen for scan session saves
        scanSessionCancellable = NotificationCenter.default.publisher(for: .scanSessionSaved)
            .sink { [weak self] notification in
                guard let userInfo = notification.userInfo,
                      let pointID = userInfo["pointID"] as? UUID,
                      let sessionData = userInfo["sessionData"] as? ScanSession else {
                    print("âš ï¸ scanSessionSaved notification missing required data")
                    return
                }
                
                self?.addSession(pointID: pointID, session: sessionData)
            }
        
        // Listen for location changes and reload points
        NotificationCenter.default.addObserver(
            forName: .locationDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("📍 MapPointStore: Location changed, reloading...")
            self?.reloadForActiveLocation()
            
            // AR markers are now session-only; skip reloading persisted markers
            // self?.loadARMarkers()
        }
    }

    /// Add a new map point at the specified coordinates
    /// Returns false if a point already exists at those coordinates
    public func addPoint(at mapPoint: CGPoint) -> Bool {
        // Check if a point already exists at these coordinates (within 1 pixel tolerance)
        let tolerance: CGFloat = 1.0
        let existsAtLocation = points.contains { point in
            abs(point.mapPoint.x - mapPoint.x) < tolerance &&
            abs(point.mapPoint.y - mapPoint.y) < tolerance
        }
        
        if existsAtLocation {
            return false // Cannot add duplicate coordinates
        }
        
        let newPoint = MapPoint(mapPoint: mapPoint)
        points.append(newPoint)
        // Set the new point as active (deactivating any previous active point)
        activePointID = newPoint.id
        print("âœ¨ Map Point Created:")
        print("   ID: \(newPoint.id.uuidString)")
        print("   Position: (\(Int(mapPoint.x)), \(Int(mapPoint.y)))")
        save()
        return true
    }

    /// Remove a map point by its ID
    public func removePoint(id: UUID) {
        if let idx = points.firstIndex(where: { $0.id == id }) {
            points.remove(at: idx)
            // If the removed point was active, clear the active state
            if activePointID == id {
                activePointID = nil
            }
            save()
            print("Removed map point with ID \(id)")
        }
    }

    /// Update a map point's position (used while dragging)
    public func updatePoint(id: UUID, to newPoint: CGPoint) {
        if let idx = points.firstIndex(where: { $0.id == id }) {
            points[idx].mapPoint = newPoint
            save()
        }
    }

    public func clear() {
        points.removeAll()
        activePointID = nil
        save()
    }

    /// Toggle the active state of a map point (only one can be active at a time)
    public func toggleActive(id: UUID) {
        if activePointID == id {
            // Deactivate if currently active
            activePointID = nil
        } else {
            // Activate this point (deactivating any other active point)
            activePointID = id
        }
        save()
    }

    /// Deactivate all map points (called when drawer closes)
    public func deactivateAll() {
        activePointID = nil
        save()
    }

    /// Select a point by ID (used when tapping on map dots)
    public func selectPoint(id: UUID) {
        activePointID = id
        save()
    }

    /// Check if a point is currently active
    public func isActive(_ id: UUID) -> Bool {
        return activePointID == id
    }

    /// Get coordinate string for display in drawer
    public func coordinateString(for point: MapPoint) -> String {
        return "(\(Int(point.mapPoint.x)),\(Int(point.mapPoint.y)))"
    }

    // MARK: - Persistence

    private struct MapPointDTO: Codable {
        let id: UUID
        let x: CGFloat
        let y: CGFloat
        let createdDate: Date
        let sessions: [ScanSession]
        let linkedARMarkerID: UUID?
        let arMarkerID: String?
    }

    internal func save() {
        // CRITICAL: Never save during reload operations (prevents data loss)
        guard !isReloading else {
            print("⚠️ MapPointStore.save() blocked during reload operation")
            return
        }
        
        // CRITICAL: Never save empty data if we previously had data
        if points.isEmpty {
            // Check if UserDefaults has existing data
            if let existingDTO: [MapPointDTO] = ctx.read(pointsKey, as: [MapPointDTO].self),
               !existingDTO.isEmpty {
                print("🛑 CRITICAL: Blocked save of empty array - UserDefaults has \(existingDTO.count) points")
                print("   This prevents accidental data loss. If you want to delete all points, use clearAllPoints() explicitly.")
                return
            }
        }
        
        let dto = points.map { MapPointDTO(
            id: $0.id,
            x: $0.mapPoint.x,
            y: $0.mapPoint.y,
            createdDate: $0.createdDate,
            sessions: $0.sessions,
            linkedARMarkerID: $0.linkedARMarkerID,
            arMarkerID: $0.arMarkerID
        )}
        ctx.write(pointsKey, value: dto)
        if let activeID = activePointID {
            ctx.write(activePointKey, value: activeID)
        }
        
        print("💾 Saved \(points.count) Map Point(s) to UserDefaults for location: \(ctx.locationID)")
        
        // Save AR Markers
        // saveARMarkers()  // AR Markers no longer persisted
    }

    private func load() {
        print("\nðŸ”„ MapPointStore.load() CALLED")
        print("   Instance ID: \(String(instanceID.prefix(8)))...")
        print("   Current locationID: \(ctx.locationID)")
        
        if let dto: [MapPointDTO] = ctx.read(pointsKey, as: [MapPointDTO].self) {
            
            // DIAGNOSTIC: Print raw museum data if this is museum location
            // Museum diagnostic removed - use external tools for detailed inspection
            
            self.points = dto.map { dtoItem in
                var point = MapPoint(
                    id: dtoItem.id,
                    mapPoint: CGPoint(x: dtoItem.x, y: dtoItem.y),
                    createdDate: dtoItem.createdDate,
                    sessions: dtoItem.sessions
                )
                point.linkedARMarkerID = dtoItem.linkedARMarkerID
                point.arMarkerID = dtoItem.arMarkerID
                return point
            }
            // Only log if there are points loaded
            if !points.isEmpty {
                print("ðŸ“‚ Loaded \(points.count) Map Point(s) with \(points.reduce(0) { $0 + $1.sessions.count }) sessions")
            }
        } else {
            self.points = []
        }
        
        // Load AR Markers
        loadARMarkers()
        
        // AR markers are session-only; skip loading persisted marker data
        // Load Anchor Packages
        loadAnchorPackages()
        
        // REMOVED: No longer load activePointID from UserDefaults
        // User must explicitly select a MapPoint each session
        
        // Removed verbose logging - data loaded successfully
    }
    
    private func loadARMarkers() {
        print("🔍 DEBUG: loadARMarkers() called for location '\(ctx.locationID)'")
        let markersKey = "ARMarkers_v1"
        if let markersData = ctx.read(markersKey, as: Data.self) {
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let legacyMarkers = try decoder.decode([ARMarker].self, from: markersData)
                arMarkers = []
                print("📍 Legacy AR Markers in storage: \(legacyMarkers.count) (will not be loaded)")
                print("   AR Markers are now created on-demand during AR sessions")
            } catch {
                arMarkers = []
                print("⚠️ Failed to decode legacy AR Markers: \(error)")
            }
        } else {
            arMarkers = []
            print("📍 No persisted AR Markers found (ephemeral session-only mode)")
        }
    }
    
    // MARK: - Session Management
    
    /// Add a complete scan session to a map point
    public func addSession(pointID: UUID, session: ScanSession) {
        if let idx = points.firstIndex(where: { $0.id == pointID }) {
            points[idx].sessions.append(session)
            save()
            print("âœ… Added session \(String(session.sessionID.prefix(8)))... to point \(String(pointID.uuidString.prefix(8)))...")
        } else {
            print("âš ï¸ Cannot add session: Map point \(pointID) not found")
        }
    }
    
    /// Get all sessions for a map point
    public func getSessions(pointID: UUID) -> [ScanSession] {
        return points.first(where: { $0.id == pointID })?.sessions ?? []
    }
    
    /// Remove a session by sessionID
    public func removeSession(pointID: UUID, sessionID: String) {
        if let idx = points.firstIndex(where: { $0.id == pointID }) {
            points[idx].sessions.removeAll { $0.sessionID == sessionID }
            save()
            print("ðŸ—‘ï¸ Removed session \(sessionID) from point \(pointID)")
        }
    }
    
    /// Get total session count across all points
    public func totalSessionCount() -> Int {
        return points.reduce(0) { $0 + $1.sessions.count }
    }
    
    // MARK: - Diagnostics

    /// Diagnostic function to check what's actually stored in UserDefaults
    public func printUserDefaultsDiagnostic() {
        print("\n" + String(repeating: "=", count: 80))
        print("ðŸ“Š MAP POINT STORE - USERDEFAULTS DIAGNOSTIC")
        print(String(repeating: "=", count: 80))
        
        let locID = ctx.locationID
        print("Current locationID: \(locID)")
        print("Points key: \(pointsKey)")
        
        // Check what's in memory
        print("\nðŸ“± IN-MEMORY STATE:")
        print("   Points loaded: \(points.count)")
        print("   Active point: \(activePointID?.uuidString ?? "none")")
        
        // Try to read raw data from UserDefaults
        if let data = UserDefaults.standard.data(forKey: pointsKey) {
            print("\nðŸ’¾ USERDEFAULTS RAW DATA:")
            print("   Data size: \(data.count) bytes (\(String(format: "%.2f", Double(data.count) / 1024.0)) KB)")
            
            // Try to decode it
            do {
                let decoder = JSONDecoder()
                let dto = try decoder.decode([MapPointDTO].self, from: data)
                print("   âœ… Successfully decoded \(dto.count) map points from UserDefaults")
                
                // Print summary
                let totalSessions = dto.reduce(0) { $0 + $1.sessions.count }
                print("   Total sessions across all points: \(totalSessions)")
                
                // Print first 10 points
                print("\nðŸ“ FIRST 10 POINTS IN USERDEFAULTS:")
                for (index, point) in dto.prefix(10).enumerated() {
                    let shortID = String(point.id.uuidString.prefix(8))
                    print("   \(index + 1). \(shortID)... @ (\(Int(point.x)),\(Int(point.y))) - \(point.sessions.count) sessions")
                }
                
                if dto.count > 10 {
                    print("   ... and \(dto.count - 10) more points")
                }
                
                // Check for discrepancy
                if dto.count != points.count {
                    print("\nâš ï¸  DISCREPANCY DETECTED!")
                    print("   UserDefaults has: \(dto.count) points")
                    print("   Memory has: \(points.count) points")
                    print("   Missing: \(dto.count - points.count) points")
                }
                
            } catch {
                print("   âŒ Failed to decode UserDefaults data")
                print("   Error: \(error)")
                
                // Try to get more details about the error
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .dataCorrupted(let context):
                        print("   Context: \(context)")
                    case .keyNotFound(let key, let context):
                        print("   Missing key: \(key), context: \(context)")
                    case .typeMismatch(let type, let context):
                        print("   Type mismatch: expected \(type), context: \(context)")
                    case .valueNotFound(let type, let context):
                        print("   Value not found: \(type), context: \(context)")
                    @unknown default:
                        print("   Unknown decoding error")
                    }
                }
            }
        } else {
            print("\nâŒ NO DATA in UserDefaults for key '\(pointsKey)'")
        }
        
        // Check if there's a locationID-specific key being used
        let locationSpecificKey = "locations.\(locID).mapPoints.v1"
        if let locData = UserDefaults.standard.data(forKey: locationSpecificKey) {
            print("\nðŸ” FOUND LOCATION-SPECIFIC KEY: '\(locationSpecificKey)'")
            print("   Size: \(locData.count) bytes")
        }
        
        // List all UserDefaults keys that might be related
        print("\nðŸ”‘ ALL USERDEFAULTS KEYS (filtered for 'map', 'point', 'location'):")
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        let relevantKeys = allKeys.filter {
            $0.lowercased().contains("map") ||
            $0.lowercased().contains("point") ||
            $0.lowercased().contains("location")
        }.sorted()
        
        for key in relevantKeys {
            if let data = UserDefaults.standard.data(forKey: key) {
                print("   \(key): \(data.count) bytes")
            } else if let value = UserDefaults.standard.object(forKey: key) {
                print("   \(key): \(type(of: value))")
            }
        }
        
        print(String(repeating: "=", count: 80) + "\n")
    }

    /// Force reload from UserDefaults (for diagnostic purposes)
    public func forceReload() {
        print("ðŸ”„ Forcing reload from UserDefaults...")
        points.removeAll()
        activePointID = nil
        load()
        print("âœ… Reload complete: \(points.count) points loaded")
    }
    
    /// ONE-TIME CLEANUP: Delete legacy Scans directory
    /// Removes old V1 session JSON files that are now redundant (data in UserDefaults)
    public func deleteScansDirectory() {
        print("\n" + String(repeating: "=", count: 80))
        print("🗑️ CLEANUP: Deleting legacy Scans directory")
        print(String(repeating: "=", count: 80))
        
        let scansDir = ctx.locationDir.appendingPathComponent("Scans", isDirectory: true)
        let fileManager = FileManager.default
        
        guard fileManager.fileExists(atPath: scansDir.path) else {
            print("ℹ️ No Scans directory found - nothing to delete")
            print(String(repeating: "=", count: 80) + "\n")
            return
        }
        
        do {
            // Count files before deletion
            let files = try fileManager.contentsOfDirectory(atPath: scansDir.path)
            let jsonFiles = files.filter { $0.hasSuffix(".json") }
            
            print("📁 Found Scans directory at: \(scansDir.path)")
            print("   Contains \(jsonFiles.count) JSON files")
            print("   Total items: \(files.count)")
            
            // Delete the entire directory
            try fileManager.removeItem(at: scansDir)
            
            print("\n✅ CLEANUP COMPLETE")
            print("   Deleted: \(scansDir.path)")
            print("   Files removed: \(jsonFiles.count)")
            print("   All session data is safely stored in UserDefaults")
            print(String(repeating: "=", count: 80) + "\n")
            
        } catch {
            print("❌ Cleanup failed: \(error)")
            print(String(repeating: "=", count: 80) + "\n")
        }
    }
    
    /// Purge all session data from all map points (keeps map points, removes sessions only)
    public func purgeAllSessions() {
        print("\n" + String(repeating: "=", count: 80))
        print("🗑️ PURGE: Removing all session data from map points")
        print(String(repeating: "=", count: 80))
        
        let totalSessionsBefore = totalSessionCount()
        let pointsCount = points.count
        
        print("   Map Points: \(pointsCount)")
        print("   Total Sessions Before: \(totalSessionsBefore)")
        
        // Remove all sessions from all points
        for i in 0..<points.count {
            points[i].sessions.removeAll()
        }
        
        // Save to UserDefaults
        save()
        
        print("\n✅ PURGE COMPLETE")
        print("   Map Points Kept: \(pointsCount)")
        print("   Sessions Removed: \(totalSessionsBefore)")
        print("   Map points still exist at their coordinates")
        print("   Ready for fresh scanning sessions")
        print(String(repeating: "=", count: 80) + "\n")
    }
    
    private func saveARMarkers() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(arMarkers)
            ctx.write("ARMarkers_v1", value: data)
            print("💾 Saved \(arMarkers.count) AR Marker(s)")
        } catch {
            print("❌ Failed to save AR Markers: \(error)")
        }
    }
    
    func saveAnchorPackages() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(anchorPackages)
            ctx.write("AnchorPackages_v1", value: data)
            print("💾 Saved \(anchorPackages.count) Anchor Package(s)")
        } catch {
            print("❌ Failed to save Anchor Packages: \(error)")
        }
    }
    
    private func loadAnchorPackages() {
        let packagesKey = "AnchorPackages_v1"
        if let packagesData = ctx.read(packagesKey, as: Data.self) {
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                anchorPackages = try decoder.decode([AnchorPointPackage].self, from: packagesData)
                print("📍 Loaded \(anchorPackages.count) Anchor Package(s) for location '\(ctx.locationID)'")
            } catch {
                print("⚠️ Failed to decode Anchor Packages: \(error)")
                anchorPackages = []
            }
        } else {
            anchorPackages = []
            print("📍 No Anchor Packages found for location '\(ctx.locationID)'")
        }
    }
    
    func createAnchorPackage(mapPointID: UUID, patchID: UUID?, mapCoordinates: CGPoint, anchorPosition: simd_float3, anchorSessionTransform: simd_float4x4, spatialData: AnchorSpatialData) {
        var package = AnchorPointPackage(
            mapPointID: mapPointID,
            patchID: patchID,
            mapCoordinates: mapCoordinates,
            anchorPosition: anchorPosition,
            anchorSessionTransform: anchorSessionTransform,
            visualDescription: nil
        )
        
        // Update with captured spatial data
        package.spatialData = spatialData
        
        anchorPackages.append(package)
        saveAnchorPackages()
        
        print("✅ Created Anchor Package \(package.id) for MapPoint \(mapPointID)")
        if let patchID {
            print("   Linked Patch ID: \(patchID)")
        } else {
            print("   Linked Patch ID: none (legacy)")
        }
        print("   Feature points: \(spatialData.featureCloud.pointCount)")
        print("   Planes: \(spatialData.planes.count)")
        print("   Data size: \(spatialData.totalDataSize) bytes")
    }
    
    func deleteAnchorPackage(_ packageID: UUID) {
        guard let index = anchorPackages.firstIndex(where: { $0.id == packageID }) else {
            print("⚠️ Anchor package \(packageID) not found")
            return
        }
        
        let package = anchorPackages[index]
        anchorPackages.remove(at: index)
        saveAnchorPackages()
        
        print("🗑️ Deleted Anchor Package \(packageID)")
        print("   Was for MapPoint: \(package.mapPointID)")
        print("   Remaining packages: \(anchorPackages.count)")
    }
    
    func deleteAllAnchorPackagesForMapPoint(_ mapPointID: UUID) {
        let beforeCount = anchorPackages.count
        anchorPackages.removeAll { $0.mapPointID == mapPointID }
        saveAnchorPackages()
        
        let deletedCount = beforeCount - anchorPackages.count
        print("🗑️ Deleted \(deletedCount) Anchor Package(s) for MapPoint \(mapPointID)")
    }
    
    func anchorPackages(forPatchID patchID: UUID) -> [AnchorPointPackage] {
        let filtered = anchorPackages.filter { $0.patchID == patchID }
        print("📍 Filtered \(filtered.count) Anchor Package(s) for patch \(patchID)")
        return filtered
    }
    
    // MARK: - AR Marker Management
    
    func createARMarker(linkedMapPointID: UUID, arPosition: simd_float3, mapCoordinates: CGPoint) {
        let marker = ARMarker(
            linkedMapPointID: linkedMapPointID,
            arPosition: arPosition,
            mapCoordinates: mapCoordinates
        )
        
        arMarkers.append(marker)
        
        // Link the MapPoint to this marker
        if let index = points.firstIndex(where: { $0.id == linkedMapPointID }) {
            points[index].linkedARMarkerID = marker.id
        }
        
        // saveARMarkers()  // AR Markers are session-only
        // save()  // Skip persisting MapPoint for ephemeral markers
        
        print("✅ Created AR Marker \(marker.id) linked to MapPoint \(linkedMapPointID)")
    }
    
    func deleteARMarker(_ markerID: UUID) {
        guard let marker = arMarkers.first(where: { $0.id == markerID }) else {
            print("⚠️ AR Marker \(markerID) not found")
            return
        }
        
        // Unlink from MapPoint
        if let index = points.firstIndex(where: { $0.linkedARMarkerID == markerID }) {
            points[index].linkedARMarkerID = nil
        }
        
        // Remove marker
        arMarkers.removeAll { $0.id == markerID }
        
        saveARMarkers()  // Still saves for manual cleanup of legacy markers
        save()
        
        print("🗑️ Deleted legacy AR Marker: \(markerID)")
        print("   (Manual cleanup - new markers are not persisted)")
    }
    
    func getARMarker(for mapPointID: UUID) -> ARMarker? {
        return arMarkers.first { $0.linkedMapPointID == mapPointID }
    }
    
    func getAllARMarkersForLocation() -> [ARMarker] {
        return arMarkers
    }
    
    deinit {
        print("ðŸ'¥ MapPointStore \(String(instanceID.prefix(8)))... deinitialized")
    }
    
    // MARK: - Interpolation Mode

    func startInterpolationMode(firstPointID: UUID) {
        guard points.contains(where: { $0.id == firstPointID }) else {
            print("❌ Cannot start interpolation: first point not found")
            return
        }
        
        isInterpolationMode = true
        interpolationFirstPointID = firstPointID
        interpolationSecondPointID = nil
        
        print("🔗 Interpolation mode started with point: \(firstPointID)")
    }

    func selectSecondPoint(secondPointID: UUID) {
        guard isInterpolationMode else {
            print("❌ Not in interpolation mode")
            return
        }
        
        guard points.contains(where: { $0.id == secondPointID }) else {
            print("❌ Second point not found")
            return
        }
        
        guard secondPointID != interpolationFirstPointID else {
            print("❌ Cannot select same point twice")
            return
        }
        
        interpolationSecondPointID = secondPointID
        
        print("🔗 Second point selected: \(secondPointID)")
        print("✅ Ready for interpolation between \(interpolationFirstPointID!) and \(secondPointID)")
    }

    func cancelInterpolationMode() {
        isInterpolationMode = false
        interpolationFirstPointID = nil
        interpolationSecondPointID = nil
        
        print("❌ Interpolation mode cancelled")
    }

    func canStartInterpolation() -> Bool {
        return isInterpolationMode && 
               interpolationFirstPointID != nil && 
               interpolationSecondPointID != nil
    }
    
}
