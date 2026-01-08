//
//  ARWorldMapStore.swift
//  TapResolver
//
//  ARWorldMap-first persistence: survey → plant → relocalize
//

import Foundation
import ARKit
import Combine
import simd
import UIKit
import CoreGraphics

public final class ARWorldMapStore: ObservableObject {
    private let ctx = PersistenceContext.shared
    
    // MARK: - Published state
    
    @Published public var globalMapExists: Bool = false
    @Published public var globalMapVersion: Int = 1
    @Published public var globalMapMeta: GlobalMapMetadata?
    @Published public var markers: [ARMarker] = []
    @Published public var isLoading: Bool = false
    
    // RELOCALIZATION PREP: Current AR session identifier
    // Every time a new AR session starts, generate a new UUID.
    // This tracks which markers belong to which session for coordinate system management.
    // TODO: When implementing relocalization, use this to detect when markers from different
    // sessions are being mixed, and trigger the transformation calculation.
    @Published public var currentSessionID: UUID = UUID()
    @Published public var currentSessionStartTime: Date = Date()
    
    /// Completed calibration sessions (persisted)
    @Published public var completedSessions: [ARCalibrationSession] = []
    private let sessionsStorageKey = "ARCalibrationSessions_v1"
    
    // RELOCALIZATION PREP: Historical session metadata
    // TODO: Store all previous session origins and transformations
    // var sessionTransforms: [UUID: SessionTransform] = [:]
    // struct SessionTransform {
    //     let sessionID: UUID
    //     let originTransform: simd_float4x4  // Where the origin was in world space
    //     let transformToCurrentSession: simd_float4x4?  // Transformation matrix to current session
    // }
    
    // MARK: - Debounce helpers
    
    private var lastConfigSig: String = ""
    private var lastConfigRunAt: Date = .distantPast
    
    // MARK: - Data models
    
    public struct GlobalMapMetadata: Codable {
        public let version: Int
        public let featurePointCount: Int
        public let anchorCount: Int
        public let capturedAt: Date
        public let deviceModel: String
        public let iOSVersion: String
        public let fileSize_bytes: Int
    }
    
    public struct ARMarker: Codable, Identifiable {
        public let id: String
        public let mapPointID: String
        public let worldTransform: CodableTransform
        public let createdAt: Date
        public var observations: MarkerObservations?
        
        // RELOCALIZATION PREP: Session tracking
        // When we implement lightweight relocalization, this will identify which AR session
        // created this marker. Markers from different sessions have different coordinate origins.
        // TODO: Use this to group markers by session and calculate transformations between sessions.
        public let sessionID: UUID
        public let sessionTimestamp: Date
        
        // RELOCALIZATION PREP: Original position at time of placement
        // This is the raw position relative to the session's origin (0,0,0).
        // When relocalization is implemented, we'll transform this using the session transform matrix.
        public var positionInSession: simd_float3 {
            let transform = worldTransform.toSimd()
            return simd_float3(
                transform.columns.3.x,
                transform.columns.3.y,
                transform.columns.3.z
            )
        }
        
        // RELOCALIZATION PREP: Future property for transformed position
        // TODO: When implementing relocalization, add:
        // var transformedPosition: simd_float3?  // Position after applying session transformation
        // var isRelocalized: Bool                 // Has this been transformed to current session?
        
        public init(id: String, mapPointID: String, worldTransform: CodableTransform, createdAt: Date = Date(), observations: MarkerObservations? = nil, sessionID: UUID, sessionTimestamp: Date) {
            self.id = id
            self.mapPointID = mapPointID
            self.worldTransform = worldTransform
            self.createdAt = createdAt
            self.observations = observations
            self.sessionID = sessionID
            self.sessionTimestamp = sessionTimestamp
        }
        
        // MARK: - Codable Implementation (with backward compatibility)
        
        enum CodingKeys: String, CodingKey {
            case id
            case mapPointID
            case worldTransform
            case createdAt
            case observations
            case sessionID
            case sessionTimestamp
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            id = try container.decode(String.self, forKey: .id)
            mapPointID = try container.decode(String.self, forKey: .mapPointID)
            worldTransform = try container.decode(CodableTransform.self, forKey: .worldTransform)
            createdAt = try container.decode(Date.self, forKey: .createdAt)
            observations = try container.decodeIfPresent(MarkerObservations.self, forKey: .observations)
            
            // Backward compatibility: If sessionID/sessionTimestamp are missing, use defaults
            // This handles old markers saved before session tracking was implemented
            if let sessionID = try? container.decode(UUID.self, forKey: .sessionID),
               let sessionTimestamp = try? container.decode(Date.self, forKey: .sessionTimestamp) {
                self.sessionID = sessionID
                self.sessionTimestamp = sessionTimestamp
            } else {
                // Legacy marker - assign to a default "unknown" session
                // This marks it as needing re-calibration in a new session
                self.sessionID = UUID(uuidString: "00000000-0000-0000-0000-000000000000") ?? UUID()
                self.sessionTimestamp = createdAt
                print("⚠️ Loaded legacy marker \(id) without session info - assigned to unknown session")
            }
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(id, forKey: .id)
            try container.encode(mapPointID, forKey: .mapPointID)
            try container.encode(worldTransform, forKey: .worldTransform)
            try container.encode(createdAt, forKey: .createdAt)
            try container.encodeIfPresent(observations, forKey: .observations)
            try container.encode(sessionID, forKey: .sessionID)
            try container.encode(sessionTimestamp, forKey: .sessionTimestamp)
        }
    }
    
    // MARK: - Calibration Session Record
    
    /// Records metadata about a completed calibration session for analytics and drift detection
    public struct ARCalibrationSession: Codable, Identifiable {
        public let id: UUID                           // Same as currentSessionID
        public let startTimestamp: Date
        public let endTimestamp: Date
        public var duration: TimeInterval { endTimestamp.timeIntervalSince(startTimestamp) }
        
        public let trianglesCalibratedCount: Int      // Number of triangles completed
        public let mapPointsPlacedCount: Int          // Number of MapPoints that received position data
        
        public let exitReason: ExitReason
        
        public enum ExitReason: String, Codable {
            case completed      // User finished calibration normally (dismissed AR view)
            case aborted        // User tapped reset/cancel
        }
        
        public init(
            id: UUID,
            startTimestamp: Date,
            endTimestamp: Date,
            trianglesCalibratedCount: Int,
            mapPointsPlacedCount: Int,
            exitReason: ExitReason
        ) {
            self.id = id
            self.startTimestamp = startTimestamp
            self.endTimestamp = endTimestamp
            self.trianglesCalibratedCount = trianglesCalibratedCount
            self.mapPointsPlacedCount = mapPointsPlacedCount
            self.exitReason = exitReason
        }
    }
    
    public struct MarkerObservations: Codable {
        public let distances_m: [Float]
        public let yawCoverage_deg: [Float]
        public let trackingQuality: [String]
        public let jitterStdDev_m: Float?
    }
    
    public struct CodableTransform: Codable {
        public let columns: [[Float]]
        
        public init(from transform: simd_float4x4) {
            columns = [
                [transform.columns.0.x, transform.columns.0.y, transform.columns.0.z, transform.columns.0.w],
                [transform.columns.1.x, transform.columns.1.y, transform.columns.1.z, transform.columns.1.w],
                [transform.columns.2.x, transform.columns.2.y, transform.columns.2.z, transform.columns.2.w],
                [transform.columns.3.x, transform.columns.3.y, transform.columns.3.z, transform.columns.3.w]
            ]
        }
        
        public func toSimd() -> simd_float4x4 {
            simd_float4x4(
                SIMD4<Float>(columns[0][0], columns[0][1], columns[0][2], columns[0][3]),
                SIMD4<Float>(columns[1][0], columns[1][1], columns[1][2], columns[1][3]),
                SIMD4<Float>(columns[2][0], columns[2][1], columns[2][2], columns[2][3]),
                SIMD4<Float>(columns[3][0], columns[3][1], columns[3][2], columns[3][3])
            )
        }
    }
    
    // MARK: - Directory helpers
    
    private func baseDirectory() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs
            .appendingPathComponent("locations")
            .appendingPathComponent(ctx.locationID)
            .appendingPathComponent("ARSpatial", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    private func globalMapURL(version: Int) -> URL {
        baseDirectory().appendingPathComponent("global_v\(version).armap")
    }
    
    private func globalMapMetaURL(version: Int) -> URL {
        baseDirectory().appendingPathComponent("global_v\(version)_meta.json")
    }
    
    private func markersDirectory() -> URL {
        let dir = baseDirectory().appendingPathComponent("Markers", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    private func markerDirectory(markerID: String) -> URL {
        let dir = markersDirectory().appendingPathComponent(markerID, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    private func markerMetaURL(markerID: String) -> URL {
        markerDirectory(markerID: markerID).appendingPathComponent("marker.json")
    }
    
    private func markerPatchURL(markerID: String) -> URL {
        markerDirectory(markerID: markerID).appendingPathComponent("patch.armap")
    }
    
    private func markerObservationsURL(markerID: String) -> URL {
        markerDirectory(markerID: markerID).appendingPathComponent("observations.json")
    }

    private func patchesDirectory() -> URL {
        let dir = baseDirectory().appendingPathComponent("Patches", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func patchURL(for id: UUID) -> URL {
        patchesDirectory().appendingPathComponent("\(id.uuidString).armap")
    }

    private func patchIndexURL() -> URL {
        patchesDirectory().appendingPathComponent("patch_index.json")
    }
    
    // MARK: - Strategy-specific directory helpers
    
    /// Get the base directory for relocalization strategies
    private func strategiesDirectory() -> URL {
        let dir = baseDirectory().appendingPathComponent("Strategies", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    /// Get directory for a specific strategy
    private func strategyDirectory(strategyID: String) -> URL {
        let dir = strategiesDirectory().appendingPathComponent(strategyID, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    /// Get URL for a world map file in a strategy-specific folder
    /// - Parameters:
    ///   - triangleID: The triangle ID
    ///   - strategyID: The strategy identifier (e.g., "worldmap")
    /// - Returns: URL to the .armap file
    static func strategyWorldMapURL(for triangleID: UUID, strategyID: String) -> URL {
        let ctx = PersistenceContext.shared
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs
            .appendingPathComponent("locations")
            .appendingPathComponent(ctx.locationID)
            .appendingPathComponent("ARSpatial", isDirectory: true)
            .appendingPathComponent("Strategies", isDirectory: true)
            .appendingPathComponent(strategyID, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("\(triangleID.uuidString).armap")
    }
    
    /// Get URL for saving a world map in a strategy-specific folder
    private func strategyWorldMapURL(for triangleID: UUID, strategyID: String) -> URL {
        strategyDirectory(strategyID: strategyID).appendingPathComponent("\(triangleID.uuidString).armap")
    }
    
    // MARK: - Lifecycle
    
    // Static flag to ensure init message only prints once
    private static var hasLoggedInit = false
    // Static flag to ensure session loading message only prints once
    private static var hasLoggedSessionLoad = false
    
    public init() {
        // Only log initialization once (for debugging)
        if !Self.hasLoggedInit {
            print("🧠 ARWorldMapStore init (ARWorldMap-first architecture)")
            Self.hasLoggedInit = true
        }
        loadGlobalMapMetadata()
        loadCompletedSessions()
        // LEGACY: Marker loading removed - markers are now created on-demand during sessions
        // No longer loading persisted marker metadata at startup
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(locationDidChange),
            name: .locationDidChange,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func locationDidChange() {
        print("📍 ARWorldMapStore: Location changed → \(ctx.locationID)")
        DispatchQueue.main.async {
            self.loadGlobalMapMetadata()
            // LEGACY: Marker loading removed - markers are now created on-demand during sessions
        }
    }
    
    // MARK: - Global map persistence
    
    public func saveGlobalMap(_ map: ARWorldMap, version: Int? = nil) throws {
        let targetVersion = version ?? globalMapVersion
        let url = globalMapURL(version: targetVersion)
        
        let data = try NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
        try data.write(to: url, options: .atomic)
        
        let meta = GlobalMapMetadata(
            version: targetVersion,
            featurePointCount: map.rawFeaturePoints.points.count,
            anchorCount: map.anchors.count,
            capturedAt: Date(),
            deviceModel: UIDevice.current.model,
            iOSVersion: UIDevice.current.systemVersion,
            fileSize_bytes: data.count
        )
        
        let metaData = try JSONEncoder().encode(meta)
        try metaData.write(to: globalMapMetaURL(version: targetVersion), options: .atomic)
        
        DispatchQueue.main.async {
            self.globalMapExists = true
            self.globalMapVersion = targetVersion
            self.globalMapMeta = meta
        }
        
        print("📦 Saved GlobalMap v\(targetVersion)")
        print("   Feature points: \(meta.featurePointCount)")
        print("   Size: \(String(format: "%.1f", Double(meta.fileSize_bytes) / 1_048_576)) MB")
    }
    
    public func loadGlobalMap(version: Int? = nil) throws -> ARWorldMap? {
        let targetVersion = version ?? globalMapVersion
        let url = globalMapURL(version: targetVersion)
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("⚠️ No GlobalMap found at v\(targetVersion)")
            return nil
        }
        
        let data = try Data(contentsOf: url)
        let map = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data)
        print("📂 Loaded GlobalMap v\(targetVersion)")
        return map
    }

    @discardableResult
    public func loadWorldMap(version: Int? = nil) -> ARWorldMap? {
        do {
            return try loadGlobalMap(version: version)
        } catch {
            print("❌ Failed to load GlobalMap: \(error)")
            return nil
        }
    }

    // MARK: - Multi-Patch Support

    /// Save a patch with metadata (legacy: saves to Patches/ folder)
    public func savePatch(_ map: ARWorldMap, meta: WorldMapPatchMeta) throws {
        let data = try NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
        let patchFile = patchURL(for: meta.id)
        try data.write(to: patchFile, options: .atomic)
        
        let finalMeta = WorldMapPatchMeta(
            id: meta.id,
            name: meta.name,
            captureDate: meta.captureDate,
            featureCount: meta.featureCount,
            byteSize: data.count,
            center2D: meta.center2D,
            radiusM: meta.radiusM,
            version: meta.version
        )
        
        var index = loadPatchIndex() ?? WorldMapPatchIndex(locationID: ctx.locationID)
        index.patches.removeAll { $0.id == meta.id }
        index.patches.append(finalMeta)
        index.updated = Date()
        try savePatchIndex(index)
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        let sizeString = formatter.string(fromByteCount: Int64(finalMeta.byteSize))
        
        print("📦 Saved patch '\(finalMeta.name)'")
        print("   Features: \(finalMeta.featureCount)")
        print("   Size: \(sizeString)")
        print("   Center: (\(Int(finalMeta.center2D.x)), \(Int(finalMeta.center2D.y)))")
        print("   Total patches for location: \(index.patches.count)")
    }
    
    /// Save a patch to a strategy-specific folder
    /// - Parameters:
    ///   - map: The ARWorldMap to save
    ///   - triangleID: The triangle ID (used as filename)
    ///   - strategyID: The strategy identifier (e.g., "worldmap")
    public func savePatchForStrategy(_ map: ARWorldMap, triangleID: UUID, strategyID: String) throws {
        let url = strategyWorldMapURL(for: triangleID, strategyID: strategyID)
        let data = try NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
        try data.write(to: url, options: .atomic)
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        let sizeString = formatter.string(fromByteCount: Int64(data.count))
        
        print("📦 Saved ARWorldMap for strategy '\(strategyID)'")
        print("   Triangle: \(String(triangleID.uuidString.prefix(8)))")
        print("   Features: \(map.rawFeaturePoints.points.count)")
        print("   Size: \(sizeString)")
        print("   Path: \(url.path)")
    }

    /// Load a specific patch by ID
    public func loadPatch(id: UUID) -> ARWorldMap? {
        let patchFile = patchURL(for: id)
        guard FileManager.default.fileExists(atPath: patchFile.path) else {
            print("⚠️ No patch found with ID: \(id)")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: patchFile)
            let map = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data)
            print("📂 Loaded patch: \(id)")
            return map
        } catch {
            print("❌ Failed to decode patch: \(error)")
            return nil
        }
    }

    /// Load patch index
    public func loadPatchIndex() -> WorldMapPatchIndex? {
        let indexFile = patchIndexURL()
        guard FileManager.default.fileExists(atPath: indexFile.path) else { return nil }
        
        do {
            let data = try Data(contentsOf: indexFile)
            let index = try JSONDecoder().decode(WorldMapPatchIndex.self, from: data)
            return index
        } catch {
            print("❌ Failed to decode patch index: \(error)")
            return nil
        }
    }

    /// Save patch index
    private func savePatchIndex(_ index: WorldMapPatchIndex) throws {
        let indexFile = patchIndexURL()
        let data = try JSONEncoder().encode(index)
        try data.write(to: indexFile, options: .atomic)
    }

    /// Choose best patch for a map point
    public func chooseBestPatch(for mapPoint: CGPoint) -> (meta: WorldMapPatchMeta, map: ARWorldMap)? {
        guard let index = loadPatchIndex(), let nearest = index.nearestPatch(to: mapPoint) else {
            print("⚠️ No patches available")
            return nil
        }
        
        guard let map = loadPatch(id: nearest.id) else {
            print("⚠️ Failed to load nearest patch")
            return nil
        }
        
        let dx = nearest.center2D.x - mapPoint.x
        let dy = nearest.center2D.y - mapPoint.y
        let distance = sqrt(dx * dx + dy * dy)
        
        print("🎯 Selected patch '\(nearest.name)'")
        print("   Distance: \(String(format: "%.1f", distance)) map units")
        print("   Features: \(nearest.featureCount)")
        
        return (nearest, map)
    }
    
    private func loadGlobalMapMetadata() {
        let url = globalMapMetaURL(version: globalMapVersion)
        guard FileManager.default.fileExists(atPath: url.path) else {
            DispatchQueue.main.async {
                self.globalMapExists = false
                self.globalMapMeta = nil
            }
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let meta = try JSONDecoder().decode(GlobalMapMetadata.self, from: data)
            DispatchQueue.main.async {
                self.globalMapExists = true
                self.globalMapMeta = meta
            }
        } catch {
            print("❌ Failed to load GlobalMap metadata: \(error)")
            DispatchQueue.main.async {
                self.globalMapExists = false
                self.globalMapMeta = nil
            }
        }
    }
    
    // MARK: - Marker persistence
    
    public func saveMarker(_ marker: ARMarker, patch: ARWorldMap? = nil) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let markerData = try encoder.encode(marker)
        try markerData.write(to: markerMetaURL(markerID: marker.id), options: .atomic)
        
        if let patch = patch {
            let patchData = try NSKeyedArchiver.archivedData(withRootObject: patch, requiringSecureCoding: true)
            try patchData.write(to: markerPatchURL(markerID: marker.id), options: .atomic)
            print("   💾 Saved patch: \(String(format: "%.1f", Double(patchData.count) / 1_048_576)) MB")
        }
        
        if let observations = marker.observations {
            let obsData = try encoder.encode(observations)
            try obsData.write(to: markerObservationsURL(markerID: marker.id), options: .atomic)
        }
        
        DispatchQueue.main.async {
            if let index = self.markers.firstIndex(where: { $0.id == marker.id }) {
                self.markers[index] = marker
            } else {
                self.markers.append(marker)
            }
        }
        
        print("📍 Saved marker \(marker.id) (MapPoint: \(marker.mapPointID))")
    }
    
    public func loadMarkerPatch(markerID: String) throws -> ARWorldMap? {
        let url = markerPatchURL(markerID: markerID)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        return try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data)
    }
    
    // LEGACY: Marker loading removed - markers are now created on-demand during AR sessions
    // This function is kept for diagnostic purposes only (loads markers on-demand for inspection)
    private func loadMarkersForDiagnostics() -> [ARMarker] {
        let dir = markersDirectory()
        guard let entries = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else {
            return []
        }
        
        var loaded: [ARMarker] = []
        for entry in entries where entry.hasDirectoryPath {
            let markerID = entry.lastPathComponent
            let metaURL = markerMetaURL(markerID: markerID)
            guard FileManager.default.fileExists(atPath: metaURL.path) else { continue }
            do {
                let data = try Data(contentsOf: metaURL)
                let marker = try JSONDecoder().decode(ARMarker.self, from: data)
                loaded.append(marker)
            } catch {
                print("❌ Failed to load marker \(markerID): \(error)")
            }
        }
        
        return loaded.sorted { $0.createdAt < $1.createdAt }
    }
    
    // MARK: - Marker Access Helpers
    
    /// Find a marker by its ID (UUID string)
    public func marker(withID id: UUID) -> ARMarker? {
        let idString = id.uuidString
        return markers.first(where: { $0.id == idString })
    }
    
    // MARK: - Diagnostic Functions
    
    /// Inspect persisted AR markers for the current location (loads on-demand from disk)
    public func inspectMarkers() {
        let locationID = ctx.locationID
        // Load markers on-demand for diagnostics (legacy markers only)
        let loadedMarkers = loadMarkersForDiagnostics()
        let count = loadedMarkers.count
        
        print("\n" + String(repeating: "=", count: 80))
        print("🔍 AR MARKER INSPECTION: '\(locationID)'")
        print(String(repeating: "=", count: 80))
        print("⚠️  NOTE: These are legacy persisted markers (not used by current system)")
        print("   Current system creates markers on-demand during AR sessions")
        print("")
        print("📊 Total legacy markers found: \(count)")
        print("")
        
        if loadedMarkers.isEmpty {
            print("📍 No persisted markers found")
            print("   Path: \(markersDirectory().path)")
        } else {
            for (index, marker) in loadedMarkers.enumerated() {
                let position = marker.worldTransform.toSimd().columns.3
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .short
                
                print("  [\(index + 1)] 📍 Marker ID: \(marker.id)")
                print("      mapPointID: \(marker.mapPointID)")
                print("      createdAt: \(dateFormatter.string(from: marker.createdAt))")
                print("      Position: (\(String(format: "%.3f", position.x)), \(String(format: "%.3f", position.y)), \(String(format: "%.3f", position.z)))")
                
                if let observations = marker.observations {
                    print("      Observations:")
                    print("        - Distances: \(observations.distances_m.count) samples")
                    print("        - Yaw coverage: \(observations.yawCoverage_deg.count) samples")
                    if let jitter = observations.jitterStdDev_m {
                        print("        - Jitter std dev: \(String(format: "%.4f", jitter)) m")
                    }
                } else {
                    print("      Observations: None")
                }
                print("")
            }
        }
        
        print(String(repeating: "=", count: 80) + "\n")
    }
    
    /// Delete all persisted marker metadata files for the current location
    public func deleteAllMarkers() {
        let locationID = ctx.locationID
        let markersDir = markersDirectory()
        
        print("\n" + String(repeating: "=", count: 80))
        print("🗑️ DELETING ALL AR MARKERS: '\(locationID)'")
        print(String(repeating: "=", count: 80))
        print("   Path: \(markersDir.path)")
        print("")
        
        guard FileManager.default.fileExists(atPath: markersDir.path) else {
            print("📍 No markers directory found - nothing to delete")
            print(String(repeating: "=", count: 80) + "\n")
            return
        }
        
        do {
            let markerDirs = try FileManager.default.contentsOfDirectory(
                at: markersDir,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ).filter { $0.hasDirectoryPath }
            
            var deletedCount = 0
            var failedCount = 0
            
            for dir in markerDirs {
                do {
                    try FileManager.default.removeItem(at: dir)
                    deletedCount += 1
                    print("  ✅ Deleted: \(dir.lastPathComponent)")
                } catch {
                    failedCount += 1
                    print("  ❌ Failed to delete \(dir.lastPathComponent): \(error.localizedDescription)")
                }
            }
            
            print("")
            print(String(repeating: "-", count: 80))
            print("📊 DELETION RESULTS:")
            print("   Deleted: \(deletedCount) marker(s)")
            if failedCount > 0 {
                print("   Failed: \(failedCount) marker(s)")
            }
            print("")
            print("✅ Marker deletion complete")
            print(String(repeating: "=", count: 80) + "\n")
            
            // Clear in-memory markers array (legacy, but kept for consistency)
            DispatchQueue.main.async {
                self.markers = []
            }
            
        } catch {
            print("❌ Failed to access markers directory: \(error.localizedDescription)")
            print(String(repeating: "=", count: 80) + "\n")
        }
    }
    
    // MARK: - Config preservation
    
    public func preserveAndRun(
        _ mutate: (ARWorldTrackingConfiguration) -> Void,
        session: ARSession
    ) {
        guard let current = session.configuration as? ARWorldTrackingConfiguration else {
            print("❌ Cannot preserve config - not ARWorldTrackingConfiguration")
            return
        }
        
        let cfg = ARWorldTrackingConfiguration()
        cfg.worldAlignment = current.worldAlignment
        cfg.planeDetection = current.planeDetection
        cfg.environmentTexturing = current.environmentTexturing
        cfg.sceneReconstruction = current.sceneReconstruction
        cfg.maximumNumberOfTrackedImages = current.maximumNumberOfTrackedImages
        
        mutate(cfg)
        
        let sig = "di:\(cfg.detectionImages?.count ?? 0)|mt:\(cfg.maximumNumberOfTrackedImages)|pd:\(cfg.planeDetection.rawValue)|sr:\(cfg.sceneReconstruction.rawValue)"
        let now = Date()
        if sig == lastConfigSig, now.timeIntervalSince(lastConfigRunAt) < 0.30 {
            print("⏱️ Skipping config run (debounced & identical)")
            return
        }
        lastConfigSig = sig
        lastConfigRunAt = now
        
        session.run(cfg, options: [])
        
        print("🔧 Config updated:")
        print("   Detection images: \(cfg.detectionImages?.count ?? 0)")
        print("   Max tracked: \(cfg.maximumNumberOfTrackedImages)")
    }
    
    // MARK: - Session Management
    
    /// Call this when a new AR session begins to generate a new session ID
    /// RELOCALIZATION PREP: In the future, this will also detect known markers and calculate transformations
    public func startNewSession() {
        currentSessionID = UUID()
        currentSessionStartTime = Date()
        print("🆕 New AR session started: \(currentSessionID)")
        print("   Session timestamp: \(currentSessionStartTime)")
        
        // RELOCALIZATION TODO: When implementing relocalization:
        // 1. Detect if any known markers are visible in the new session
        // 2. Compare their old positions (from previous session) with new positions
        // 3. Calculate transformation matrix: old -> new
        // 4. Apply transformation to all markers from previous sessions
        // 5. Store the transformation for future use
    }
    
    /// Records a completed calibration session
    /// - Parameters:
    ///   - trianglesCalibratedCount: Number of triangles calibrated this session
    ///   - mapPointsPlacedCount: Number of MapPoints that received position data
    ///   - exitReason: Why the session ended
    public func endSession(
        trianglesCalibratedCount: Int,
        mapPointsPlacedCount: Int,
        exitReason: ARCalibrationSession.ExitReason
    ) {
        let session = ARCalibrationSession(
            id: currentSessionID,
            startTimestamp: currentSessionStartTime,
            endTimestamp: Date(),
            trianglesCalibratedCount: trianglesCalibratedCount,
            mapPointsPlacedCount: mapPointsPlacedCount,
            exitReason: exitReason
        )
        
        completedSessions.append(session)
        saveCompletedSessions()
        
        print("📍 [SESSION_END] Session \(String(currentSessionID.uuidString.prefix(8))) ended")
        print("   Duration: \(String(format: "%.1f", session.duration))s")
        print("   Triangles: \(trianglesCalibratedCount)")
        print("   MapPoints: \(mapPointsPlacedCount)")
        print("   Exit reason: \(exitReason.rawValue)")
    }
    
    private func saveCompletedSessions() {
        let key = ctx.key(sessionsStorageKey)
        if let data = try? JSONEncoder().encode(completedSessions) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    private func loadCompletedSessions() {
        let key = ctx.key(sessionsStorageKey)
        if let data = UserDefaults.standard.data(forKey: key),
           let sessions = try? JSONDecoder().decode([ARCalibrationSession].self, from: data) {
            completedSessions = sessions
            // Only log once to prevent spam from multiple ARWorldMapStore instances
            if !Self.hasLoggedSessionLoad {
                print("📖 [SESSION_HISTORY] Loaded \(sessions.count) completed session(s)")
                Self.hasLoggedSessionLoad = true
            }
        }
    }
    
    // MARK: - Diagnostics
    
    public func printDiagnostic() {
        print("\n📊 ARWorldMapStore Diagnostic")
        print("Location: \(ctx.locationID)")
        print("GlobalMap exists: \(globalMapExists)")
        print("Current session: \(currentSessionID)")
        if let meta = globalMapMeta {
            print("  Version: \(meta.version)")
            print("  Feature points: \(meta.featurePointCount)")
            print("  Anchors: \(meta.anchorCount)")
            print("  Size: \(String(format: "%.1f", Double(meta.fileSize_bytes) / 1_048_576)) MB")
            print("  Captured: \(meta.capturedAt)")
        }
        print("Markers: \(markers.count)")
        for marker in markers {
            print("  • \(marker.id)")
            print("    MapPoint: \(marker.mapPointID)")
            print("    Created: \(marker.createdAt)")
            print("    Session: \(marker.sessionID)")
        }
        print()
    }
}

