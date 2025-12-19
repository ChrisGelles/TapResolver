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
import UIKit

// MARK: - Position History Types (Milestone 2)

/// Categorizes how an AR position was recorded
public enum SourceType: String, Codable {
    case calibration      // Manual placement during triangle calibration
    case ghostConfirm     // User confirmed ghost position was accurate
    case ghostAdjust      // User adjusted ghost to correct position
    case relocalized      // Position derived from session transform
}

/// Records a single AR position measurement for a MapPoint
public struct ARPositionRecord: Codable, Identifiable {
    public let id: UUID
    let position: SIMD3<Float>      // 3D AR position (simd_float3)
    let sessionID: UUID              // Which AR session created this
    let timestamp: Date              // When recorded
    let sourceType: SourceType       // How it was recorded
    let distortionVector: SIMD3<Float>?  // Difference from estimated (nil if no adjustment)
    let confidenceScore: Float       // 0.0 - 1.0, used for weighted averaging
    
    public init(
        id: UUID = UUID(),
        position: SIMD3<Float>,
        sessionID: UUID,
        timestamp: Date = Date(),
        sourceType: SourceType,
        distortionVector: SIMD3<Float>? = nil,
        confidenceScore: Float
    ) {
        self.id = id
        self.position = position
        self.sessionID = sessionID
        self.timestamp = timestamp
        self.sourceType = sourceType
        self.distortionVector = distortionVector
        self.confidenceScore = confidenceScore
    }
    
    // MARK: - Codable (encode simd_float3 as [Float])
    
    enum CodingKeys: String, CodingKey {
        case id, sessionID, timestamp, sourceType, confidenceScore
        case positionArray, distortionArray
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        sessionID = try container.decode(UUID.self, forKey: .sessionID)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        sourceType = try container.decode(SourceType.self, forKey: .sourceType)
        confidenceScore = try container.decode(Float.self, forKey: .confidenceScore)
        
        let posArray = try container.decode([Float].self, forKey: .positionArray)
        position = SIMD3<Float>(posArray[0], posArray[1], posArray[2])
        
        if let distArray = try container.decodeIfPresent([Float].self, forKey: .distortionArray) {
            distortionVector = SIMD3<Float>(distArray[0], distArray[1], distArray[2])
        } else {
            distortionVector = nil
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(sessionID, forKey: .sessionID)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(sourceType, forKey: .sourceType)
        try container.encode(confidenceScore, forKey: .confidenceScore)
        try container.encode([position.x, position.y, position.z], forKey: .positionArray)
        
        if let dist = distortionVector {
            try container.encode([dist.x, dist.y, dist.z], forKey: .distortionArray)
        }
    }
}

extension ARPositionRecord: CustomDebugStringConvertible {
    public var debugDescription: String {
        let ts = timestamp.formatted(date: .omitted, time: .standard)
        return "[\(sourceType.rawValue)] (\(String(format: "%.2f", position.x)), \(String(format: "%.2f", position.y)), \(String(format: "%.2f", position.z))) • \(ts) • conf: \(String(format: "%.2f", confidenceScore))"
    }
}

public enum MapPointRole: String, Codable, CaseIterable, Identifiable {
    case triangleEdge = "triangle_edge"
    case featureMarker = "feature_marker"
    case directionalNorth = "directional_north"
    case directionalSouth = "directional_south"
    
    public var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .triangleEdge: return "Triangle Edge"
        case .featureMarker: return "Feature Marker"
        case .directionalNorth: return "North Calibration"
        case .directionalSouth: return "South Calibration"
        }
    }
    
    var icon: String {
        switch self {
        case .triangleEdge: return "triangle"
        case .featureMarker: return "mappin.circle"
        case .directionalNorth: return "location.north.fill"
        case .directionalSouth: return "s.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .triangleEdge: return .blue
        case .featureMarker: return .green
        case .directionalNorth: return .red
        case .directionalSouth: return .orange
        }
    }
}

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
    
    // MARK: - Bake-Down Freshness Tracking (Milestone 5)
    
    /// Timestamp of last successful bake-down operation
    @Published public var lastBakeTimestamp: Date? = nil
    
    /// Number of sessions that were included in the last bake
    public var lastBakeSessionCount: Int = 0
    
    /// UserDefaults key for persisting bake timestamp
    private var bakeTimestampKey: String {
        return ctx.key("BakeTimestamp_v1")
    }
    
    /// UserDefaults key for persisting bake session count
    private var bakeSessionCountKey: String {
        return ctx.key("BakeSessionCount_v1")
    }
    
    // DIAGNOSTIC: Track which instance this is
    internal let instanceID = UUID().uuidString
    
    public struct MapPoint: Codable, Identifiable {
        public let id: UUID
        public var position: CGPoint    // map-local (untransformed) coords
        public var name: String?
        public let createdDate: Date
        public var sessions: [ScanSession] = []  // Full scan session data stored in UserDefaults
        var linkedARMarkerID: UUID?  // Optional - links to legacy ARMarker if one exists
        public var arMarkerID: String?  // Links to ARWorldMapStore marker
        public var roles: Set<MapPointRole> = []
        public var locationPhotoData: Data? = nil
        public var photoFilename: String? = nil  // NEW: Filename of photo on disk
        public var photoOutdated: Bool? = nil  // Flagged when MapPoint position changes after photo was captured
        public var photoCapturedAtPosition: CGPoint? = nil  // Position when photo was last captured
        public var triangleMemberships: [UUID] = []
        public var isLocked: Bool = true  // ✅ New points default to locked
        
        // MARK: - Position History (Milestone 2)
        public var arPositionHistory: [ARPositionRecord] = []
        
        // MARK: - Baked Canonical Position (Milestone 5)
        
        // These values are computed at calibration end and represent the MapPoint's
        // position in a map-centered canonical coordinate frame.
        public var bakedCanonicalPosition: SIMD3<Float>?  // Position in canonical frame
        public var bakedConfidence: Float?                 // Aggregate confidence (0.0-1.0)
        public var bakedSampleCount: Int = 0               // Number of calibration sessions that contributed
        
        public var mapPoint: CGPoint {
            get { position }
            set { position = newValue }
        }
        
        // Initializer that accepts existing ID or generates new one
        init(
            id: UUID? = nil,
            mapPoint: CGPoint,
            name: String? = nil,
            createdDate: Date? = nil,
            sessions: [ScanSession] = [],
            roles: Set<MapPointRole> = [],
            locationPhotoData: Data? = nil,
            photoFilename: String? = nil,  // NEW
            triangleMemberships: [UUID] = [],
            isLocked: Bool = true,  // ✅ ADD THIS PARAMETER
            arPositionHistory: [ARPositionRecord] = [],
            bakedCanonicalPosition: SIMD3<Float>? = nil,
            bakedConfidence: Float? = nil,
            bakedSampleCount: Int = 0
        ) {
            self.id = id ?? UUID()
            self.position = mapPoint
            self.name = name
            self.createdDate = createdDate ?? Date()
            self.sessions = sessions
            self.linkedARMarkerID = nil
            self.arMarkerID = nil
            self.roles = roles
            self.locationPhotoData = locationPhotoData
            self.photoFilename = photoFilename  // NEW
            self.triangleMemberships = triangleMemberships
            self.isLocked = isLocked  // ✅ ADD THIS ASSIGNMENT
            self.arPositionHistory = arPositionHistory  // NEW
            self.bakedCanonicalPosition = bakedCanonicalPosition
            self.bakedConfidence = bakedConfidence
            self.bakedSampleCount = bakedSampleCount
        }
        
        // MARK: - Consensus Position (Milestone 2)
        
        private static let outlierThresholdMeters: Float = 0.15
        
        /// Calculates weighted average position with outlier rejection
        var consensusPosition: SIMD3<Float>? {
            guard !arPositionHistory.isEmpty else { return nil }
            
            // Single record - return it directly
            if arPositionHistory.count == 1 {
                return arPositionHistory[0].position
            }
            
            // Calculate initial centroid (unweighted)
            var sum = SIMD3<Float>(0, 0, 0)
            for record in arPositionHistory {
                sum += record.position
            }
            let centroid = sum / Float(arPositionHistory.count)
            
            // Filter outliers (distance > threshold from centroid)
            let inliers = arPositionHistory.filter { record in
                let dist = simd_distance(record.position, centroid)
                return dist <= Self.outlierThresholdMeters
            }
            
            // If all filtered out, fall back to all records
            let recordsToUse = inliers.isEmpty ? arPositionHistory : inliers
            
            // Weighted average using confidence scores
            var weightedSum = SIMD3<Float>(0, 0, 0)
            var totalWeight: Float = 0
            
            for record in recordsToUse {
                weightedSum += record.position * record.confidenceScore
                totalWeight += record.confidenceScore
            }
            
            guard totalWeight > 0 else { return nil }
            return weightedSum / totalWeight
        }
        
        /// Prints position history for debugging
        public func debugHistory() {
            print("🧠 History for MapPoint \(id.uuidString.prefix(8)) (\(arPositionHistory.count) records):")
            if arPositionHistory.isEmpty {
                print("   (empty)")
            } else {
                for record in arPositionHistory {
                    print("   • \(record.debugDescription)")
                }
            }
            if let consensus = consensusPosition {
                print("   📍 Consensus: (\(String(format: "%.2f", consensus.x)), \(String(format: "%.2f", consensus.y)), \(String(format: "%.2f", consensus.z)))")
            }
        }
        
        // MARK: - Codable
        
        enum CodingKeys: String, CodingKey {
            case id, position, name, createdDate, sessions
            case linkedARMarkerID, arMarkerID, roles
            case locationPhotoData, photoFilename, photoOutdated, photoCapturedAtPosition
            case triangleMemberships, isLocked, arPositionHistory
            case bakedCanonicalPositionArray, bakedConfidence, bakedSampleCount
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(UUID.self, forKey: .id)
            position = try container.decode(CGPoint.self, forKey: .position)
            name = try container.decodeIfPresent(String.self, forKey: .name)
            createdDate = try container.decode(Date.self, forKey: .createdDate)
            sessions = try container.decode([ScanSession].self, forKey: .sessions)
            linkedARMarkerID = try container.decodeIfPresent(UUID.self, forKey: .linkedARMarkerID)
            arMarkerID = try container.decodeIfPresent(String.self, forKey: .arMarkerID)
            
            // Decode roles
            if let rolesArray = try container.decodeIfPresent([MapPointRole].self, forKey: .roles) {
                roles = Set(rolesArray)
            } else {
                roles = []
            }
            
            locationPhotoData = try container.decodeIfPresent(Data.self, forKey: .locationPhotoData)
            photoFilename = try container.decodeIfPresent(String.self, forKey: .photoFilename)
            photoOutdated = try container.decodeIfPresent(Bool.self, forKey: .photoOutdated)
            photoCapturedAtPosition = try container.decodeIfPresent(CGPoint.self, forKey: .photoCapturedAtPosition)
            
            triangleMemberships = try container.decodeIfPresent([UUID].self, forKey: .triangleMemberships) ?? []
            isLocked = try container.decodeIfPresent(Bool.self, forKey: .isLocked) ?? true
            arPositionHistory = try container.decodeIfPresent([ARPositionRecord].self, forKey: .arPositionHistory) ?? []
            
            // Decode baked canonical position (Milestone 5)
            if let bakedArray = try container.decodeIfPresent([Float].self, forKey: .bakedCanonicalPositionArray),
               bakedArray.count == 3 {
                bakedCanonicalPosition = SIMD3<Float>(bakedArray[0], bakedArray[1], bakedArray[2])
            } else {
                bakedCanonicalPosition = nil
            }
            bakedConfidence = try container.decodeIfPresent(Float.self, forKey: .bakedConfidence)
            bakedSampleCount = try container.decodeIfPresent(Int.self, forKey: .bakedSampleCount) ?? 0
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(position, forKey: .position)
            try container.encodeIfPresent(name, forKey: .name)
            try container.encode(createdDate, forKey: .createdDate)
            try container.encode(sessions, forKey: .sessions)
            try container.encodeIfPresent(linkedARMarkerID, forKey: .linkedARMarkerID)
            try container.encodeIfPresent(arMarkerID, forKey: .arMarkerID)
            try container.encode(Array(roles), forKey: .roles)
            try container.encodeIfPresent(locationPhotoData, forKey: .locationPhotoData)
            try container.encodeIfPresent(photoFilename, forKey: .photoFilename)
            try container.encodeIfPresent(photoOutdated, forKey: .photoOutdated)
            try container.encodeIfPresent(photoCapturedAtPosition, forKey: .photoCapturedAtPosition)
            
            if !triangleMemberships.isEmpty {
                try container.encode(triangleMemberships, forKey: .triangleMemberships)
            }
            try container.encode(isLocked, forKey: .isLocked)
            if !arPositionHistory.isEmpty {
                try container.encode(arPositionHistory, forKey: .arPositionHistory)
            }
            
            // Encode baked canonical position (Milestone 5)
            if let baked = bakedCanonicalPosition {
                try container.encode([baked.x, baked.y, baked.z], forKey: .bakedCanonicalPositionArray)
            }
            try container.encodeIfPresent(bakedConfidence, forKey: .bakedConfidence)
            if bakedSampleCount > 0 {
                try container.encode(bakedSampleCount, forKey: .bakedSampleCount)
            }
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
    // TODO: Re-enable after Phase 4 coordinator integration
    // @Published var calibrationPoints: [CalibrationMarker] = []
    @Published var isCalibrated: Bool = false
    
    @Published public private(set) var activePointID: UUID? = nil
    @Published var selectedPointID: UUID? = nil
    
    // Interpolation mode state
    @Published var isInterpolationMode: Bool = false
    @Published var interpolationFirstPointID: UUID? = nil
    @Published var interpolationSecondPointID: UUID? = nil
    
    var mapPoints: [MapPoint] {
        get { points }
        set { points = newValue }
    }
    
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
        selectedPointID = nil
        
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
        selectedPointID = nil
        
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
        selectedPointID = nil
        objectWillChange.send()
    }

    // MARK: persistence keys
    private let pointsKey = "MapPoints_v1"
    private let activePointKey = "MapPointsActive_v1"

    public init() {
        print("🧱 MapPointStore init — ID: \(String(instanceID.prefix(8)))...")
        
        // Delay load() until locationID is set to avoid race condition
        Task {
            // Wait briefly for locationID to propagate from LocationManager
            try? await Task.sleep(nanoseconds: 300_000_000)  // 0.3 sec
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                print("🔄 MapPointStore: Initial load for location '\(ctx.locationID)'")
                self.load()
            }
        }
        
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
        // Set the new point as active and selected
        activePointID = newPoint.id
        selectedPointID = newPoint.id
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
    public func updatePoint(id: UUID, to newPosition: CGPoint) {
        guard let index = points.firstIndex(where: { $0.id == id }) else { return }
        let point = points[index]
        
        // Check if position changed significantly and photo exists
        if let capturedPosition = point.photoCapturedAtPosition,
           point.locationPhotoData != nil || point.photoFilename != nil {
            let distance = sqrt(
                pow(newPosition.x - capturedPosition.x, 2) +
                pow(newPosition.y - capturedPosition.y, 2)
            )
            // Mark as outdated if moved more than 1 pixel (movementThreshold)
            // Using epsilon tolerance for float precision (0.1 pixels)
            let movementThreshold: CGFloat = 1.0
            let epsilon: CGFloat = 0.1
            if distance > (movementThreshold + epsilon) {
                points[index].photoOutdated = true
                print("⚠️ Photo marked as outdated: MapPoint moved \(String(format: "%.2f", distance)) pixels from capture position (threshold: \(movementThreshold))")
            }
        } else if (point.locationPhotoData != nil || point.photoFilename != nil) && point.photoCapturedAtPosition == nil {
            // Migration: Existing photos without capture position are considered outdated
            // until they are recaptured with proper position tracking
            if point.photoOutdated == nil {
                points[index].photoOutdated = true
                print("⚠️ Photo marked as outdated: No capture position recorded (migration)")
            }
        }
        
        points[index].position = newPosition
        // Note: We don't save() here to avoid excessive I/O during drag
        // The position will be saved when drag ends via the existing save mechanism
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
            if selectedPointID == id {
                selectedPointID = nil
            }
        } else {
            // Activate this point (deactivating any other active point)
            activePointID = id
            selectedPointID = id
        }
        save()
    }

    /// Deactivate all map points (called when drawer closes)
    public func deactivateAll() {
        activePointID = nil
        selectedPointID = nil
        save()
    }

    // DEPRECATED: selectPoint() removed - use selectedPointID directly for UI selection
    // activePointID is only for scan operations, set it explicitly when needed

    /// Check if a point is currently active
    public func isActive(_ id: UUID) -> Bool {
        return activePointID == id
    }

    /// Toggle the lock state of a map point
    public func toggleLock(id: UUID) {
        guard let index = points.firstIndex(where: { $0.id == id }) else { return }
        points[index].isLocked.toggle()
        print("🔒 Map Point \(points[index].isLocked ? "locked" : "unlocked"): \(id)")
        save()
    }
    
    /// Check if a point is locked
    public func isLocked(_ id: UUID) -> Bool {
        return points.first(where: { $0.id == id })?.isLocked ?? true
    }
    
    // MARK: - Position History (Milestone 2)
    
    private let maxHistoryRecords = 20
    
    /// Adds a position record to a MapPoint's history with FIFO eviction
    func addPositionRecord(mapPointID: UUID, record: ARPositionRecord) {
        guard let index = points.firstIndex(where: { $0.id == mapPointID }) else {
            print("⚠️ [POSITION_HISTORY] MapPoint not found: \(mapPointID.uuidString.prefix(8))")
            return
        }
        
        points[index].arPositionHistory.append(record)
        
        // FIFO eviction if over limit
        if points[index].arPositionHistory.count > maxHistoryRecords {
            let removed = points[index].arPositionHistory.removeFirst()
            print("🗑️ [POSITION_HISTORY] Evicted oldest record from \(mapPointID.uuidString.prefix(8)) (session: \(removed.sessionID.uuidString.prefix(8)))")
        }
        
        print("📍 [POSITION_HISTORY] \(record.sourceType.rawValue) → MapPoint \(mapPointID.uuidString.prefix(8)) (#\(points[index].arPositionHistory.count))")
        print("   ↳ pos: (\(String(format: "%.2f", record.position.x)), \(String(format: "%.2f", record.position.y)), \(String(format: "%.2f", record.position.z))) @ \(record.timestamp.formatted(date: .omitted, time: .standard))")
        
        save()
    }
    
    /// Prints position history for all MapPoints that have history
    func debugAllHistories() {
        let pointsWithHistory = points.filter { !$0.arPositionHistory.isEmpty }
        
        if pointsWithHistory.isEmpty {
            print("📊 [DEBUG] No MapPoints have position history yet")
            return
        }
        
        print("📊 [DEBUG] Position histories for \(pointsWithHistory.count) MapPoint(s):")
        for point in pointsWithHistory {
            point.debugHistory()
            print("")  // Blank line between entries
        }
    }
    
    /// Prints a compact summary of consensus positions
    func debugConsensusSummary() {
        print("📍 [CONSENSUS SUMMARY]")
        var count = 0
        for point in points {
            if let consensus = point.consensusPosition {
                print("   MP \(point.id.uuidString.prefix(8)) → (\(String(format: "%.2f", consensus.x)), \(String(format: "%.2f", consensus.y)), \(String(format: "%.2f", consensus.z)))")
                count += 1
            }
        }
        if count == 0 {
            print("   (no consensus positions available)")
        }
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
        let name: String?
        let createdDate: Date
        let sessions: [ScanSession]
        let linkedARMarkerID: UUID?
        let arMarkerID: String?
        let roles: [MapPointRole]?
        let locationPhotoData: Data?
        let photoFilename: String?  // NEW
        let photoOutdated: Bool?  // Optional for backward compatibility
        let photoCapturedAtPositionX: CGFloat?  // Optional for backward compatibility
        let photoCapturedAtPositionY: CGFloat?  // Optional for backward compatibility
        let triangleMemberships: [UUID]?
        let isLocked: Bool?  // ✅ Optional for backward compatibility
        let arPositionHistory: [ARPositionRecord]?  // Optional for migration from old data
        
        // Baked canonical position (Milestone 5)
        let bakedCanonicalPositionArray: [Float]?  // [x, y, z] in canonical frame
        let bakedConfidence: Float?
        let bakedSampleCount: Int?
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
                print("🛑 CRITICAL: Blocked save of empty array (prevents data loss)")
                return
            }
        }
        
        let dto = points.map { point -> MapPointDTO in
            // Only include locationPhotoData if there's no filename (legacy data)
            let photoData: Data?
            if point.photoFilename != nil {
                // Photo is on disk, don't save to UserDefaults
                photoData = nil
            } else {
                // Legacy: photo still in memory
                photoData = point.locationPhotoData
            }
            
            return MapPointDTO(
                id: point.id,
                x: point.mapPoint.x,
                y: point.mapPoint.y,
                name: point.name,
                createdDate: point.createdDate,
                sessions: point.sessions,
                linkedARMarkerID: point.linkedARMarkerID,
                arMarkerID: point.arMarkerID,
                roles: Array(point.roles),
                locationPhotoData: photoData,
                photoFilename: point.photoFilename,  // NEW
                photoOutdated: point.photoOutdated,
                photoCapturedAtPositionX: point.photoCapturedAtPosition?.x,
                photoCapturedAtPositionY: point.photoCapturedAtPosition?.y,
                triangleMemberships: point.triangleMemberships.isEmpty ? nil : point.triangleMemberships,
                isLocked: point.isLocked,
                arPositionHistory: point.arPositionHistory.isEmpty ? nil : point.arPositionHistory,
                // Baked canonical position (Milestone 5)
                bakedCanonicalPositionArray: point.bakedCanonicalPosition.map { [$0.x, $0.y, $0.z] },
                bakedConfidence: point.bakedConfidence,
                bakedSampleCount: point.bakedSampleCount > 0 ? point.bakedSampleCount : nil
            )
        }
        
        ctx.write(pointsKey, value: dto)
        
        if let activeID = activePointID {
            ctx.write(activePointKey, value: activeID)
        }
        
        // Summary log only
        print("💾 Saved \(points.count) Map Point(s)")
        
        // Also persist bake metadata
        if let bakeTime = lastBakeTimestamp {
            UserDefaults.standard.set(bakeTime, forKey: bakeTimestampKey)
            UserDefaults.standard.set(lastBakeSessionCount, forKey: bakeSessionCountKey)
        }
        
        // Save AR Markers
        // saveARMarkers()  // AR Markers no longer persisted
    }
    
    /// Purges all AR position history from MapPoints for the current location
    /// This resets the consensus position calculations while preserving 2D map coordinates
    func purgeARPositionHistory() {
        print("================================================================================")
        print("🧹 PURGE AR POSITION HISTORY")
        print("================================================================================")
        print("📍 Location: '\(ctx.locationID)'")
        print("📊 MapPoints to purge: \(points.count)")
        
        var totalRecordsPurged = 0
        
        for i in points.indices {
            let recordCount = points[i].arPositionHistory.count
            if recordCount > 0 {
                print("   🗑️ \(String(points[i].id.uuidString.prefix(8))): purging \(recordCount) position record(s)")
                totalRecordsPurged += recordCount
                points[i].arPositionHistory = []
            }
        }
        
        save()
        
        print("================================================================================")
        print("✅ Purged \(totalRecordsPurged) AR position record(s) from \(points.count) MapPoint(s)")
        print("   2D map coordinates preserved")
        print("   Triangle structure preserved")
        print("   Ready for fresh calibration")
        print("================================================================================")
    }
    
    // MARK: - Photo Management
    
    /// Purge all photo assets for current location
    func purgeAllPhotos() {
        let location = PersistenceContext.shared.locationID
        print("🗑️ PURGING ALL PHOTOS for location '\(location)'")
        
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let mapPointsPath = documentsURL.appendingPathComponent("locations/\(location)/map-points")
        
        var deletedCount = 0
        var failedCount = 0
        
        // Delete all .jpg files in map-points directory
        if FileManager.default.fileExists(atPath: mapPointsPath.path) {
            if let files = try? FileManager.default.contentsOfDirectory(at: mapPointsPath, includingPropertiesForKeys: nil) {
                for fileURL in files where fileURL.pathExtension == "jpg" {
                    do {
                        try FileManager.default.removeItem(at: fileURL)
                        deletedCount += 1
                        print("🗑️ Deleted: \(fileURL.lastPathComponent)")
                    } catch {
                        failedCount += 1
                        print("⚠️ Failed to delete \(fileURL.lastPathComponent): \(error)")
                    }
                }
            }
        } else {
            print("⚠️ Map-points directory does not exist: \(mapPointsPath.path)")
        }
        
        // Clear photoFilename from all MapPoints
        for i in 0..<points.count {
            points[i].photoFilename = nil
            points[i].photoOutdated = false
            points[i].photoCapturedAtPosition = nil
        }
        
        // Save updated points
        save()
        
        print("✅ Photo purge complete:")
        print("   Deleted: \(deletedCount) files")
        print("   Failed: \(failedCount) files")
        print("   Cleared photo metadata from \(points.count) Map Points")
    }

    private func load() {
        // Load map points from persistence
        if let dto: [MapPointDTO] = ctx.read(pointsKey, as: [MapPointDTO].self) {
            var needsSave = false
            var loadedPoints = dto.map { dtoItem -> MapPoint in
                // Load photo from disk if filename exists, otherwise use legacy data
                var photoData: Data? = nil
                if let filename = dtoItem.photoFilename {
                    // Load from disk
                    let fileManager = FileManager.default
                    if let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
                        let locationID = ctx.locationID
                        let photoURL = documentsURL
                            .appendingPathComponent("locations/\(locationID)/map-points")
                            .appendingPathComponent(filename)
                        
                        photoData = try? Data(contentsOf: photoURL)
                    }
                } else {
                    // Legacy: load from UserDefaults
                    photoData = dtoItem.locationPhotoData
                }
                
                // Reconstruct photoCapturedAtPosition from separate x/y fields
                let capturedPosition: CGPoint? = {
                    if let x = dtoItem.photoCapturedAtPositionX,
                       let y = dtoItem.photoCapturedAtPositionY {
                        return CGPoint(x: x, y: y)
                    }
                    return nil
                }()
                
                // Reconstruct baked canonical position from array
                let bakedPosition: SIMD3<Float>? = {
                    if let arr = dtoItem.bakedCanonicalPositionArray, arr.count == 3 {
                        return SIMD3<Float>(arr[0], arr[1], arr[2])
                    }
                    return nil
                }()
                
                var point = MapPoint(
                    id: dtoItem.id,
                    mapPoint: CGPoint(x: dtoItem.x, y: dtoItem.y),
                    name: dtoItem.name,
                    createdDate: dtoItem.createdDate,
                    sessions: dtoItem.sessions,
                    roles: Set(dtoItem.roles ?? []),
                    locationPhotoData: photoData,
                    photoFilename: dtoItem.photoFilename,  // NEW
                    triangleMemberships: dtoItem.triangleMemberships ?? [],
                    isLocked: dtoItem.isLocked ?? true,  // Default to locked for backward compatibility
                    arPositionHistory: dtoItem.arPositionHistory ?? [],
                    // Baked canonical position (Milestone 5)
                    bakedCanonicalPosition: bakedPosition,
                    bakedConfidence: dtoItem.bakedConfidence,
                    bakedSampleCount: dtoItem.bakedSampleCount ?? 0
                )
                
                // Set photo tracking fields
                point.photoOutdated = dtoItem.photoOutdated
                point.photoCapturedAtPosition = capturedPosition
                
                // Migration: Mark photos without capture position as outdated
                if (point.locationPhotoData != nil || point.photoFilename != nil) && capturedPosition == nil {
                    if point.photoOutdated == nil {
                        point.photoOutdated = true
                        needsSave = true
                        print("⚠️ Migration: Marked photo as outdated for MapPoint \(String(point.id.uuidString.prefix(8))) (no capture position)")
                    }
                }
                if dtoItem.roles == nil || dtoItem.triangleMemberships == nil || dtoItem.isLocked == nil {
                    needsSave = true
                }
                point.linkedARMarkerID = dtoItem.linkedARMarkerID
                point.arMarkerID = dtoItem.arMarkerID
                return point
            }
            
            // One-time migration: purge legacy AR position history (pre-rigid-transform data)
            MapPointStore.purgeLegacyARPositionHistoryIfNeeded(from: &loadedPoints)
            
            self.points = loadedPoints
            
            // Summary log only
            if needsSave {
                print("📦 Migrated \(points.count) MapPoint(s) to include role metadata")
                save()
            }
            print("✅ MapPointStore: Reload complete - \(points.count) points loaded")
            
            // Diagnostic: Aggregate data summary
            let totalRecords = points.reduce(0) { $0 + $1.arPositionHistory.count }
            let uniqueSessions = Set(points.flatMap { $0.arPositionHistory.map { $0.sessionID } })
            let pointsWithHistory = points.filter { !$0.arPositionHistory.isEmpty }.count
            print("📊 [DATA_SUMMARY] \(points.count) MapPoints, \(pointsWithHistory) with history, \(totalRecords) total position records across \(uniqueSessions.count) sessions")
        } else {
            self.points = []
            print("✅ MapPointStore: No saved data found - starting fresh")
        }
        
        selectedPointID = nil
        
        // Load AR Markers
        loadARMarkers()
        
        // AR markers are session-only; skip loading persisted marker data
        // Load Anchor Packages
        loadAnchorPackages()
        
        // REMOVED: No longer load activePointID from UserDefaults
        // User must explicitly select a MapPoint each session
        
        // Load bake metadata
        lastBakeTimestamp = UserDefaults.standard.object(forKey: bakeTimestampKey) as? Date
        lastBakeSessionCount = UserDefaults.standard.integer(forKey: bakeSessionCountKey)
        
        if let bakeTime = lastBakeTimestamp {
            print("📦 [BAKE_META] Last bake: \(bakeTime.formatted()), sessions: \(lastBakeSessionCount)")
        } else {
            print("📦 [BAKE_META] No previous bake found")
        }
        
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
                let markerKey = "locations.\(ctx.locationID).ARMarkers_v1"
                let markerSize = UserDefaults.standard.data(forKey: markerKey)?.count ?? 0
                let markerKB = Double(markerSize) / 1024
                print("📍 Legacy AR Markers in storage: \(legacyMarkers.count) (will not be loaded)")
                print("   💾 Size: \(String(format: "%.2f KB", markerKB)) - can be purged with 'Purge Legacy AR Markers'")
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
    
    /// Validates and assigns role to a MapPoint. Returns error message if validation fails.
    func assignRole(_ role: MapPointRole, to pointID: UUID) -> String? {
        if role == .directionalNorth {
            if let existingNorth = points.first(where: { $0.roles.contains(.directionalNorth) && $0.id != pointID }) {
                print("⚠️ North calibration already assigned to \(existingNorth.id)")
                return "Another point is already designated as North"
            }
        }
        
        if role == .directionalSouth {
            if let existingSouth = points.first(where: { $0.roles.contains(.directionalSouth) && $0.id != pointID }) {
                print("⚠️ South calibration already assigned to \(existingSouth.id)")
                return "Another point is already designated as South"
            }
        }
        
        guard let index = points.firstIndex(where: { $0.id == pointID }) else {
            return "Map point not found"
        }
        
        if !points[index].roles.contains(role) {
            points[index].roles.insert(role)
            objectWillChange.send()
            save()
        }
        
        return nil
    }
    
    /// Removes a role from a MapPoint.
    func removeRole(_ role: MapPointRole, from pointID: UUID) {
        guard let index = points.firstIndex(where: { $0.id == pointID }) else { return }
        if points[index].roles.remove(role) != nil {
            objectWillChange.send()
            save()
        }
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
    
    // MARK: - Photo Disk Storage Helpers
    
    /// Save photo to disk and update point with filename
    func savePhotoToDisk(for pointID: UUID, photoData: Data) -> Bool {
        guard let index = points.firstIndex(where: { $0.id == pointID }) else {
            return false
        }
        
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return false
        }
        
        let locationDir = documentsURL.appendingPathComponent("locations/\(ctx.locationID)/map-points")
        
        // Create directory if needed
        try? fileManager.createDirectory(at: locationDir, withIntermediateDirectories: true)
        
        // Save with short UUID as filename
        let filename = "\(String(pointID.uuidString.prefix(8))).jpg"
        let fileURL = locationDir.appendingPathComponent(filename)
        
        do {
            // Compress to JPEG
            if let image = UIImage(data: photoData),
               let jpegData = image.jpegData(compressionQuality: 0.8) {
                try jpegData.write(to: fileURL)
                
                // Update point with filename and clear memory data
                points[index].photoFilename = filename
                points[index].locationPhotoData = nil  // Clear from memory
                points[index].photoCapturedAtPosition = points[index].position  // Record capture position
                points[index].photoOutdated = false  // Clear outdated flag when new photo is captured
                
                print("📸 Saved photo to disk: \(filename) (\(jpegData.count / 1024) KB)")
                return true
            }
        } catch {
            print("❌ Failed to save photo: \(error)")
        }
        
        return false
    }
    
    /// Load photo from disk for a point
    func loadPhotoFromDisk(for pointID: UUID) -> Data? {
        guard let point = points.first(where: { $0.id == pointID }),
              let filename = point.photoFilename else {
            return nil
        }
        
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let fileURL = documentsURL
            .appendingPathComponent("locations/\(ctx.locationID)/map-points")
            .appendingPathComponent(filename)
        
        return try? Data(contentsOf: fileURL)
    }
    
    // MARK: - Legacy Data Migration
    
    /// One-time migration to purge legacy AR position history data
    /// Legacy data was collected without session origin tracking, making it geometrically inconsistent
    /// This runs once per installation, gated by UserDefaults flag
    static func purgeLegacyARPositionHistoryIfNeeded(from points: inout [MapPoint]) {
        let flagKey = "hasPurgedLegacyARPositionHistory"
        
        // Check if already run
        guard !UserDefaults.standard.bool(forKey: flagKey) else {
            print("🧹 [PURGE] Skipped - legacy AR position history already purged")
            return
        }
        
        print("🧹 [PURGE] Starting one-time legacy AR position history migration...")
        
        // Step 1: Archive existing data before deletion
        var archiveData: [[String: Any]] = []
        var totalRecords = 0
        var affectedPoints = 0
        
        for point in points {
            if !point.arPositionHistory.isEmpty {
                affectedPoints += 1
                totalRecords += point.arPositionHistory.count
                
                // Build archive entry for this MapPoint
                let records: [[String: Any]] = point.arPositionHistory.map { record in
                    [
                        "id": record.id.uuidString,
                        "sessionID": record.sessionID.uuidString,
                        "timestamp": record.timestamp.timeIntervalSinceReferenceDate,
                        "sourceType": record.sourceType.rawValue,
                        "confidenceScore": record.confidenceScore,
                        "position": [record.position.x, record.position.y, record.position.z],
                        "distortionVector": record.distortionVector.map { [$0.x, $0.y, $0.z] } as Any
                    ]
                }
                
                archiveData.append([
                    "mapPointID": point.id.uuidString,
                    "mapPosition": ["x": point.position.x, "y": point.position.y],
                    "recordCount": point.arPositionHistory.count,
                    "records": records
                ])
            }
        }
        
        // Step 2: Export archive to Documents directory
        if !archiveData.isEmpty {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd-HHmmss"
            let timestamp = formatter.string(from: Date())
            let filename = "TapResolver-LegacyPositionHistory-\(timestamp).json"
            
            if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let archiveURL = documentsURL.appendingPathComponent(filename)
                
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: archiveData, options: .prettyPrinted)
                    try jsonData.write(to: archiveURL)
                    print("📦 [PURGE] Archived \(totalRecords) record(s) from \(affectedPoints) MapPoint(s)")
                    print("   Archive path: \(archiveURL.path)")
                } catch {
                    print("⚠️ [PURGE] Failed to archive data: \(error.localizedDescription)")
                    print("   Proceeding with purge anyway...")
                }
            }
        }
        
        // Step 3: Purge position history from all MapPoints
        for i in points.indices {
            if !points[i].arPositionHistory.isEmpty {
                points[i].arPositionHistory = []
            }
        }
        
        // Step 4: Set flag to prevent re-running
        UserDefaults.standard.set(true, forKey: flagKey)
        
        print("✅ [PURGE] Migration complete!")
        print("   Purged \(totalRecords) legacy AR position record(s)")
        print("   Affected \(affectedPoints) MapPoint(s)")
        print("   Ghost placement will use 2D map geometry until fresh data accumulates")
    }
    
    // MARK: - Retrospective Bake-Down System (Milestone 5)
    
    /// Checks if baked positions need to be recalculated
    /// Returns true if there's new position history since last bake
    func checkBakeFreshness() -> Bool {
        // Find the most recent position history timestamp
        let latestHistoryTimestamp = points
            .flatMap { $0.arPositionHistory }
            .map { $0.timestamp }
            .max()
        
        guard let latestHistory = latestHistoryTimestamp else {
            print("📦 [BAKE_FRESH] No position history exists")
            return false  // Nothing to bake
        }
        
        guard let lastBake = lastBakeTimestamp else {
            print("📦 [BAKE_FRESH] No previous bake — needs full bake")
            return true  // Never baked, need to bake
        }
        
        let needsRebake = latestHistory > lastBake
        if needsRebake {
            print("📦 [BAKE_FRESH] New data since last bake (\(latestHistory.formatted()) > \(lastBake.formatted()))")
        } else {
            print("📦 [BAKE_FRESH] Baked data is current")
        }
        
        return needsRebake
    }
    
    /// Bakes down ALL historical position data into canonical positions
    /// This processes every session in the history, requiring no active AR session
    ///
    /// - Parameters:
    ///   - mapSize: Size of the map image in pixels
    ///   - metersPerPixel: Scale factor from MetricSquare calibration
    /// - Returns: Number of MapPoints updated, or nil if bake failed
    func bakeDownHistoricalData(mapSize: CGSize, metersPerPixel: Float) -> Int? {
        let startTime = Date()
        print("\n" + String(repeating: "=", count: 70))
        print("🔥 [HISTORICAL_BAKE] Starting RETROSPECTIVE bake-down")
        print("   This processes ALL historical sessions — no AR required")
        print(String(repeating: "=", count: 70))
        
        // Create canonical frame (map-centered coordinate system)
        let pixelsPerMeter = 1.0 / metersPerPixel
        let canonicalOrigin = CGPoint(x: mapSize.width / 2, y: mapSize.height / 2)
        let floorHeight: Float = -1.1  // Typical phone height
        
        print("📐 [HISTORICAL_BAKE] Canonical frame:")
        print("   Map size: \(Int(mapSize.width)) × \(Int(mapSize.height)) pixels")
        print("   Origin: (\(Int(canonicalOrigin.x)), \(Int(canonicalOrigin.y))) pixels (map center)")
        print("   Scale: \(String(format: "%.1f", pixelsPerMeter)) pixels/meter")
        print("   Floor height: \(floorHeight)m")
        
        // Step 1: Collect all unique session IDs from history
        var sessionIDs = Set<UUID>()
        for point in points {
            for record in point.arPositionHistory {
                sessionIDs.insert(record.sessionID)
            }
        }
        
        print("\n📊 [HISTORICAL_BAKE] Found \(sessionIDs.count) historical session(s) to process")
        
        if sessionIDs.isEmpty {
            print("⚠️ [HISTORICAL_BAKE] No historical data to bake")
            return nil
        }
        
        // Step 2: Build index of positions by session
        // sessionPositions[sessionID][mapPointID] = (arPosition, confidence)
        var sessionPositions: [UUID: [UUID: (position: SIMD3<Float>, confidence: Float)]] = [:]
        
        for point in points {
            for record in point.arPositionHistory {
                if sessionPositions[record.sessionID] == nil {
                    sessionPositions[record.sessionID] = [:]
                }
                // If multiple records from same session, keep highest confidence
                if let existing = sessionPositions[record.sessionID]?[point.id] {
                    if record.confidenceScore > existing.confidence {
                        sessionPositions[record.sessionID]?[point.id] = (record.position, record.confidenceScore)
                    }
                } else {
                    sessionPositions[record.sessionID]?[point.id] = (record.position, record.confidenceScore)
                }
            }
        }
        
        // Step 3: For each session, compute transform and bake positions
        var bakedPositionsAccumulator: [UUID: [(position: SIMD3<Float>, weight: Float)]] = [:]
        var sessionsProcessed = 0
        var sessionsSkipped = 0
        
        for sessionID in sessionIDs {
            guard let positionsInSession = sessionPositions[sessionID] else { continue }
            
            let sessionPrefix = String(sessionID.uuidString.prefix(8))
            print("\n🔄 [SESSION] Processing \(sessionPrefix) (\(positionsInSession.count) MapPoint(s))")
            
            // Need at least 2 MapPoints to compute transform
            guard positionsInSession.count >= 2 else {
                print("   ⏭️ Skipping — need 2+ MapPoints for transform, have \(positionsInSession.count)")
                sessionsSkipped += 1
                continue
            }
            
            // Pick 2 reference MapPoints (use first two that have good confidence)
            let sortedByConfidence = positionsInSession.sorted { $0.value.confidence > $1.value.confidence }
            let ref1ID = sortedByConfidence[0].key
            let ref2ID = sortedByConfidence[1].key
            
            guard let ref1MapPoint = points.first(where: { $0.id == ref1ID }),
                  let ref2MapPoint = points.first(where: { $0.id == ref2ID }) else {
                print("   ⚠️ Could not find reference MapPoints in store")
                sessionsSkipped += 1
                continue
            }
            
            let ref1AR = sortedByConfidence[0].value.position
            let ref2AR = sortedByConfidence[1].value.position
            let ref1Map = ref1MapPoint.position
            let ref2Map = ref2MapPoint.position
            
            print("   📍 Reference 1: \(String(ref1ID.uuidString.prefix(8))) map=(\(Int(ref1Map.x)), \(Int(ref1Map.y))) AR=(\(String(format: "%.2f", ref1AR.x)), \(String(format: "%.2f", ref1AR.y)), \(String(format: "%.2f", ref1AR.z)))")
            print("   📍 Reference 2: \(String(ref2ID.uuidString.prefix(8))) map=(\(Int(ref2Map.x)), \(Int(ref2Map.y))) AR=(\(String(format: "%.2f", ref2AR.x)), \(String(format: "%.2f", ref2AR.y)), \(String(format: "%.2f", ref2AR.z)))")
            
            // Convert map positions to canonical 3D
            let ref1Canonical = SIMD3<Float>(
                Float(ref1Map.x - canonicalOrigin.x) / pixelsPerMeter,
                floorHeight,
                Float(ref1Map.y - canonicalOrigin.y) / pixelsPerMeter
            )
            let ref2Canonical = SIMD3<Float>(
                Float(ref2Map.x - canonicalOrigin.x) / pixelsPerMeter,
                floorHeight,
                Float(ref2Map.y - canonicalOrigin.y) / pixelsPerMeter
            )
            
            // Compute session→canonical transform
            // Edge vectors in XZ plane
            let canonicalEdge = SIMD2<Float>(ref2Canonical.x - ref1Canonical.x, ref2Canonical.z - ref1Canonical.z)
            let sessionEdge = SIMD2<Float>(ref2AR.x - ref1AR.x, ref2AR.z - ref1AR.z)
            
            let canonicalLength = simd_length(canonicalEdge)
            let sessionLength = simd_length(sessionEdge)
            
            guard canonicalLength > 0.001, sessionLength > 0.001 else {
                print("   ⚠️ Degenerate edge — reference points too close")
                sessionsSkipped += 1
                continue
            }
            
            // Scale: canonical meters per session meter
            let scale = canonicalLength / sessionLength
            
            // Rotation: angle from session edge to canonical edge
            let canonicalAngle = atan2(canonicalEdge.y, canonicalEdge.x)
            let sessionAngle = atan2(sessionEdge.y, sessionEdge.x)
            let rotation = canonicalAngle - sessionAngle
            
            // Translation: compute where session origin maps to in canonical space
            let cosR = cos(rotation)
            let sinR = sin(rotation)
            let scaledRef1AR = ref1AR * scale
            let rotatedRef1AR = SIMD3<Float>(
                scaledRef1AR.x * cosR - scaledRef1AR.z * sinR,
                scaledRef1AR.y,
                scaledRef1AR.x * sinR + scaledRef1AR.z * cosR
            )
            let translation = ref1Canonical - rotatedRef1AR
            
            // Verify transform quality using second reference point
            let scaledRef2AR = ref2AR * scale
            let rotatedRef2AR = SIMD3<Float>(
                scaledRef2AR.x * cosR - scaledRef2AR.z * sinR,
                scaledRef2AR.y,
                scaledRef2AR.x * sinR + scaledRef2AR.z * cosR
            )
            let transformedRef2 = rotatedRef2AR + translation
            let verificationError = simd_distance(transformedRef2, ref2Canonical)
            
            print("   📐 Transform: scale=\(String(format: "%.4f", scale)) rot=\(String(format: "%.1f", rotation * 180 / .pi))° trans=(\(String(format: "%.2f", translation.x)), \(String(format: "%.2f", translation.z)))")
            print("   ✅ Verification error: \(String(format: "%.3f", verificationError))m")
            
            if verificationError > 0.5 {
                print("   ⚠️ High verification error — session may have scale drift, including with reduced weight")
            }
            
            // Apply transform to all positions from this session
            for (mapPointID, (arPosition, confidence)) in positionsInSession {
                // Apply transform: scale, rotate, translate
                let scaled = arPosition * scale
                let rotated = SIMD3<Float>(
                    scaled.x * cosR - scaled.z * sinR,
                    scaled.y,
                    scaled.x * sinR + scaled.z * cosR
                )
                let canonical = rotated + translation
                
                // Weight by confidence, reduced if verification error was high
                let adjustedWeight = verificationError > 0.5 ? confidence * 0.5 : confidence
                
                if bakedPositionsAccumulator[mapPointID] == nil {
                    bakedPositionsAccumulator[mapPointID] = []
                }
                bakedPositionsAccumulator[mapPointID]?.append((position: canonical, weight: adjustedWeight))
            }
            
            sessionsProcessed += 1
            print("   ✅ Transformed \(positionsInSession.count) position(s) to canonical frame")
        }
        
        print("\n" + String(repeating: "-", count: 70))
        print("📊 [HISTORICAL_BAKE] Session summary:")
        print("   Processed: \(sessionsProcessed)")
        print("   Skipped: \(sessionsSkipped)")
        print(String(repeating: "-", count: 70))
        
        // Step 4: Compute weighted average for each MapPoint and update baked positions
        var updatedCount = 0
        
        print("\n📦 [HISTORICAL_BAKE] Computing baked positions...")
        
        for (mapPointID, samples) in bakedPositionsAccumulator {
            guard let index = points.firstIndex(where: { $0.id == mapPointID }) else {
                continue
            }
            
            // Weighted average
            var weightedSum = SIMD3<Float>(0, 0, 0)
            var totalWeight: Float = 0
            
            for sample in samples {
                weightedSum += sample.position * sample.weight
                totalWeight += sample.weight
            }
            
            guard totalWeight > 0 else { continue }
            
            let bakedPosition = weightedSum / totalWeight
            let avgConfidence = totalWeight / Float(samples.count)
            
            // Update MapPoint
            points[index].bakedCanonicalPosition = bakedPosition
            points[index].bakedConfidence = avgConfidence
            points[index].bakedSampleCount = samples.count
            
            print("   ✅ \(String(mapPointID.uuidString.prefix(8))): (\(String(format: "%.2f", bakedPosition.x)), \(String(format: "%.2f", bakedPosition.y)), \(String(format: "%.2f", bakedPosition.z))) [samples: \(samples.count), conf: \(String(format: "%.2f", avgConfidence))]")
            
            updatedCount += 1
        }
        
        // Step 5: Update metadata and save
        lastBakeTimestamp = Date()
        lastBakeSessionCount = sessionsProcessed
        save()
        
        let duration = Date().timeIntervalSince(startTime) * 1000
        
        print("\n" + String(repeating: "=", count: 70))
        print("🔥 [HISTORICAL_BAKE] Complete!")
        print("   MapPoints updated: \(updatedCount)")
        print("   Sessions processed: \(sessionsProcessed)")
        print("   Duration: \(String(format: "%.1f", duration))ms")
        print("   Bake timestamp: \(lastBakeTimestamp!.formatted())")
        print(String(repeating: "=", count: 70) + "\n")
        
        return updatedCount
    }
    
    /// Convenience method to trigger bake if data is stale
    /// Call this on map load
    ///
    /// - Parameters:
    ///   - mapSize: Size of the map image in pixels
    ///   - metersPerPixel: Scale factor from MetricSquare calibration
    /// - Returns: true if bake was performed, false if skipped
    @discardableResult
    func bakeIfNeeded(mapSize: CGSize, metersPerPixel: Float) -> Bool {
        guard checkBakeFreshness() else {
            return false
        }
        
        let _ = bakeDownHistoricalData(mapSize: mapSize, metersPerPixel: metersPerPixel)
        return true
    }
    
    // MARK: - Baked Position Diagnostics
    
    /// Prints summary of baked canonical positions
    func debugBakedPositionSummary() {
        let pointsWithBaked = points.filter { $0.bakedCanonicalPosition != nil }
        let pointsWithHistory = points.filter { !$0.arPositionHistory.isEmpty }
        
        print("\n" + String(repeating: "=", count: 60))
        print("📦 [BAKED_POSITION] Summary")
        print(String(repeating: "=", count: 60))
        print("   Total MapPoints: \(points.count)")
        print("   With position history: \(pointsWithHistory.count)")
        print("   With baked canonical position: \(pointsWithBaked.count)")
        
        if !pointsWithBaked.isEmpty {
            print("\n   Baked positions:")
            for point in pointsWithBaked {
                if let baked = point.bakedCanonicalPosition,
                   let confidence = point.bakedConfidence {
                    print("   • \(String(point.id.uuidString.prefix(8))): (\(String(format: "%.2f", baked.x)), \(String(format: "%.2f", baked.y)), \(String(format: "%.2f", baked.z))) conf=\(String(format: "%.2f", confidence)) samples=\(point.bakedSampleCount)")
                }
            }
        }
        print(String(repeating: "=", count: 60) + "\n")
    }
    
    // MARK: - Duplicate MapPoint Detection & Merge
    
    /// Represents a group of MapPoints that are suspiciously close together
    public struct DuplicateGroup {
        let points: [MapPoint]
        let maxDistance: CGFloat
        
        /// The point with the most data (sessions + arPositionHistory)
        var keeper: MapPoint {
            points.max(by: { dataScore($0) < dataScore($1) }) ?? points[0]
        }
        
        /// Points that should be merged into keeper
        var duplicates: [MapPoint] {
            points.filter { $0.id != keeper.id }
        }
        
        private func dataScore(_ point: MapPoint) -> Int {
            point.sessions.count + point.arPositionHistory.count
        }
    }
    
    /// Find MapPoints that are within `thresholdPixels` of each other
    /// Returns groups of duplicates (empty if no duplicates found)
    public func findDuplicateMapPoints(thresholdPixels: CGFloat = 3.0) -> [DuplicateGroup] {
        var groups: [DuplicateGroup] = []
        var processed: Set<UUID> = []
        
        for point in points {
            guard !processed.contains(point.id) else { continue }
            
            // Find all points within threshold of this point
            var cluster: [MapPoint] = [point]
            var maxDist: CGFloat = 0
            
            for other in points {
                guard other.id != point.id else { continue }
                guard !processed.contains(other.id) else { continue }
                
                let dist = hypot(point.position.x - other.position.x,
                               point.position.y - other.position.y)
                
                if dist <= thresholdPixels {
                    cluster.append(other)
                    maxDist = max(maxDist, dist)
                }
            }
            
            // Only create a group if there are duplicates
            if cluster.count > 1 {
                groups.append(DuplicateGroup(points: cluster, maxDistance: maxDist))
                cluster.forEach { processed.insert($0.id) }
            } else {
                processed.insert(point.id)
            }
        }
        
        return groups
    }
    
    /// Log duplicate groups for diagnostic purposes
    public func logDuplicateMapPoints() {
        let groups = findDuplicateMapPoints()
        
        if groups.isEmpty {
            print("✅ [DUPLICATE_SCAN] No duplicate MapPoints found")
            return
        }
        
        print("⚠️ [DUPLICATE_SCAN] Found \(groups.count) duplicate group(s):")
        
        for (index, group) in groups.enumerated() {
            print("   Group \(index + 1): \(group.points.count) points within \(String(format: "%.1f", group.maxDistance)) pixels")
            print("   └─ Keeper: \(String(group.keeper.id.uuidString.prefix(8))) (\(group.keeper.sessions.count) sessions, \(group.keeper.arPositionHistory.count) AR records)")
            
            for dup in group.duplicates {
                let triangleRefs = dup.triangleMemberships.map { String($0.uuidString.prefix(8)) }.joined(separator: ", ")
                print("   └─ Duplicate: \(String(dup.id.uuidString.prefix(8))) (\(dup.sessions.count) sessions, \(dup.arPositionHistory.count) AR records) triangles: [\(triangleRefs)]")
            }
        }
    }
    
    /// Safely merge duplicate MapPoints, updating all triangle references
    /// Returns number of MapPoints removed
    func mergeDuplicateMapPoints(triangleStore: TrianglePatchStore) -> Int {
        let groups = findDuplicateMapPoints()
        
        if groups.isEmpty {
            print("✅ [DUPLICATE_MERGE] No duplicates to merge")
            return 0
        }
        
        var removedCount = 0
        
        for group in groups {
            let keeper = group.keeper
            let keeperID = keeper.id
            
            guard let keeperIndex = points.firstIndex(where: { $0.id == keeperID }) else {
                print("⚠️ [DUPLICATE_MERGE] Keeper \(String(keeperID.uuidString.prefix(8))) not found, skipping group")
                continue
            }
            
            for duplicate in group.duplicates {
                let dupID = duplicate.id
                
                print("🔀 [DUPLICATE_MERGE] Merging \(String(dupID.uuidString.prefix(8))) into \(String(keeperID.uuidString.prefix(8)))")
                
                // 1. Transfer sessions
                points[keeperIndex].sessions.append(contentsOf: duplicate.sessions)
                
                // 2. Transfer AR position history
                points[keeperIndex].arPositionHistory.append(contentsOf: duplicate.arPositionHistory)
                
                // 3. Update triangle references (CRITICAL)
                for (triIndex, triangle) in triangleStore.triangles.enumerated() {
                    if triangle.vertexIDs.contains(dupID) {
                        // Replace duplicate ID with keeper ID in vertex list
                        var updatedVertexIDs = triangle.vertexIDs
                        for (vIndex, vID) in updatedVertexIDs.enumerated() {
                            if vID == dupID {
                                updatedVertexIDs[vIndex] = keeperID
                                print("   📐 Updated triangle \(String(triangle.id.uuidString.prefix(8))) vertex \(vIndex): \(String(dupID.uuidString.prefix(8))) → \(String(keeperID.uuidString.prefix(8)))")
                            }
                        }
                        
                        // Create updated triangle (vertexIDs is let, so we rebuild)
                        triangleStore.triangles[triIndex] = TrianglePatch(
                            id: triangle.id,
                            vertexIDs: updatedVertexIDs,
                            isCalibrated: triangle.isCalibrated,
                            calibrationQuality: triangle.calibrationQuality,
                            transform: triangle.transform,
                            createdAt: triangle.createdAt,
                            lastCalibratedAt: triangle.lastCalibratedAt,
                            arMarkerIDs: triangle.arMarkerIDs,
                            userPositionWhenCalibrated: triangle.userPositionWhenCalibrated,
                            legMeasurements: triangle.legMeasurements,
                            worldMapFilename: triangle.worldMapFilename,
                            worldMapFilesByStrategy: triangle.worldMapFilesByStrategy
                        )
                        
                        // Update keeper's triangle memberships if not already present
                        if !points[keeperIndex].triangleMemberships.contains(triangle.id) {
                            points[keeperIndex].triangleMemberships.append(triangle.id)
                        }
                    }
                }
                
                // 4. Remove the duplicate MapPoint
                points.removeAll { $0.id == dupID }
                removedCount += 1
            }
        }
        
        // Save both stores
        save()
        triangleStore.save()
        
        print("✅ [DUPLICATE_MERGE] Merged \(removedCount) duplicate MapPoint(s)")
        return removedCount
    }
    
}
