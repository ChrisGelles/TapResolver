//
//  SurveyPointStore.swift
//  TapResolver
//
//  Data store for Survey Marker RSSI collection sessions.
//  Survey points are identified by their 2D map coordinates.
//

import Foundation
import Combine
import UIKit

// MARK: - Data Structures

/// Lean RSSI sample — just timestamp and signal strength
public struct RssiSample: Codable, Equatable {
    public let ms: Int64      // Milliseconds since session start
    public let rssi: Int      // Signal strength (dBm), 0 = boundary marker
    
    public init(ms: Int64, rssi: Int) {
        self.ms = ms
        self.rssi = rssi
    }
    
    /// Create a boundary marker (rssi=0)
    public static func boundaryMarker(ms: Int64) -> RssiSample {
        RssiSample(ms: ms, rssi: 0)
    }
}

/// Device pose snapshot for pose track (captured independently of RSSI)
public struct PoseSample: Codable, Equatable {
    public let ms: Int64      // Milliseconds since session start
    public let x: Float       // Position X (meters, AR coordinates)
    public let y: Float       // Position Y (meters)
    public let z: Float       // Position Z (meters)
    public let qx: Float      // Quaternion X
    public let qy: Float      // Quaternion Y
    public let qz: Float      // Quaternion Z
    public let qw: Float      // Quaternion W
    
    public init(ms: Int64, x: Float, y: Float, z: Float, qx: Float, qy: Float, qz: Float, qw: Float) {
        self.ms = ms
        self.x = x
        self.y = y
        self.z = z
        self.qx = qx
        self.qy = qy
        self.qz = qz
        self.qw = qw
    }
    
    /// Create from SurveyDevicePose with timestamp
    public init(ms: Int64, pose: SurveyDevicePose) {
        self.ms = ms
        self.x = pose.x
        self.y = pose.y
        self.z = pose.z
        self.qx = pose.qx
        self.qy = pose.qy
        self.qz = pose.qz
        self.qw = pose.qw
    }
}

/// Raw magnetometer sample for magnetic distortion mapping
public struct MagnetometerSample: Codable, Equatable {
    public let ms: Int64      // Milliseconds since session start
    public let x: Float       // Microteslas, device X axis
    public let y: Float       // Microteslas, device Y axis
    public let z: Float       // Microteslas, device Z axis
    
    public init(ms: Int64, x: Float, y: Float, z: Float) {
        self.ms = ms
        self.x = x
        self.y = y
        self.z = z
    }
}

/// Statistical summary of RSSI measurements for one beacon
public struct SurveyStats: Codable, Equatable {
    public let median_dbm: Int
    public let mad_db: Int           // Median Absolute Deviation
    public let p10_dbm: Int          // 10th percentile
    public let p90_dbm: Int          // 90th percentile
    public let sampleCount: Int      // Total samples collected
    
    public init(median_dbm: Int, mad_db: Int, p10_dbm: Int, p90_dbm: Int, sampleCount: Int) {
        self.median_dbm = median_dbm
        self.mad_db = mad_db
        self.p10_dbm = p10_dbm
        self.p90_dbm = p90_dbm
        self.sampleCount = sampleCount
    }
}

/// Histogram of RSSI values in 1dB bins
public struct SurveyHistogram: Codable, Equatable {
    public let binMin_dbm: Int       // Typically -100
    public let binMax_dbm: Int       // Typically -30
    public let binSize_db: Int       // Typically 1
    public let counts: [Int]         // Bin counts array
    
    public init(binMin_dbm: Int, binMax_dbm: Int, binSize_db: Int, counts: [Int]) {
        self.binMin_dbm = binMin_dbm
        self.binMax_dbm = binMax_dbm
        self.binSize_db = binSize_db
        self.counts = counts
    }
}

/// Beacon metadata captured at survey time
public struct SurveyBeaconMeta: Codable, Equatable {
    public let name: String
    public let model: String
    public let txPower: Int?
    public let advertisingInterval_ms: Int?
    
    public init(name: String, model: String, txPower: Int?, advertisingInterval_ms: Int?) {
        self.name = name
        self.model = model
        self.txPower = txPower
        self.advertisingInterval_ms = advertisingInterval_ms
    }
}

/// Device pose during survey collection (AR coordinates)
public struct SurveyDevicePose: Codable, Equatable {
    // Position in AR space
    public let x: Float
    public let y: Float
    public let z: Float
    // Rotation as quaternion
    public let qx: Float
    public let qy: Float
    public let qz: Float
    public let qw: Float
    
    public init(x: Float, y: Float, z: Float, qx: Float, qy: Float, qz: Float, qw: Float) {
        self.x = x
        self.y = y
        self.z = z
        self.qx = qx
        self.qy = qy
        self.qz = qz
        self.qw = qw
    }
    
    /// Identity pose (no translation, no rotation)
    public static let identity = SurveyDevicePose(x: 0, y: 0, z: 0, qx: 0, qy: 0, qz: 0, qw: 1)
}

// MARK: - Quality Tracking

/// Angular coverage tracking across 8 compass sectors
public struct AngularCoverage: Codable, Equatable {
    /// Accumulated dwell time per compass sector (seconds)
    /// Index 0 = North (337.5? to 22.5?), proceeding clockwise
    /// Index 1 = NE, 2 = E, 3 = SE, 4 = S, 5 = SW, 6 = W, 7 = NW
    public var sectorTime_s: [Double]
    
    public init() {
        sectorTime_s = Array(repeating: 0.0, count: 8)
    }
    
    public init(sectorTime_s: [Double]) {
        self.sectorTime_s = sectorTime_s
    }
    
    /// Number of sectors with meaningful data (?1 second)
    public var coveredSectorCount: Int {
        sectorTime_s.filter { $0 >= 1.0 }.count
    }
    
    /// Add time to appropriate sector(s) based on heading
    /// Includes blurring: headings within 10? of boundary credit both sectors partially
    public mutating func addTime(_ seconds: Double, atHeading heading: Double) {
        // Normalize heading to 0-360
        var h = heading.truncatingRemainder(dividingBy: 360.0)
        if h < 0 { h += 360.0 }
        
        // Each sector is 45?, starting at -22.5? from north
        // Sector 0: 337.5? to 22.5? (North)
        let sectorSize = 45.0
        let halfSector = sectorSize / 2.0
        
        // Calculate primary sector
        let adjustedHeading = (h + halfSector).truncatingRemainder(dividingBy: 360.0)
        let primarySector = Int(adjustedHeading / sectorSize) % 8
        
        // Calculate distance to nearest boundary for blurring
        let sectorCenter = Double(primarySector) * sectorSize
        let distanceFromCenter = abs(h - sectorCenter)
        let normalizedDistance = min(distanceFromCenter, 360.0 - distanceFromCenter)
        
        // Blur zone: within 10? of boundary
        let blurZone = 10.0
        let boundaryDistance = halfSector - normalizedDistance
        
        if boundaryDistance < blurZone && boundaryDistance > 0 {
            // Near boundary: split time between sectors
            let blurFactor = boundaryDistance / blurZone  // 0 at boundary, 1 at edge of blur zone
            let primaryWeight = 0.5 + (blurFactor * 0.5)  // 0.5 to 1.0
            let secondaryWeight = 1.0 - primaryWeight      // 0.5 to 0.0
            
            // Determine secondary sector (clockwise or counter-clockwise neighbor)
            let secondarySector: Int
            if normalizedDistance > 0 {
                secondarySector = (primarySector + 1) % 8
            } else {
                secondarySector = (primarySector + 7) % 8
            }
            
            sectorTime_s[primarySector] += seconds * primaryWeight
            sectorTime_s[secondarySector] += seconds * secondaryWeight
        } else {
            // Not near boundary: all time to primary sector
            sectorTime_s[primarySector] += seconds
        }
    }
}

/// Quality tier for visual feedback
public enum DataQualityTier: String, Codable {
    case red      // No data or < 3 seconds
    case yellow   // 3-9 seconds
    case green    // 9+ seconds, limited angular coverage
    case blue     // 9+ seconds AND 3+ sectors covered
}

/// Quality metrics for a survey point
public struct SurveyPointQuality: Codable, Equatable {
    public var totalDwellTime_s: Double
    public var angularCoverage: AngularCoverage
    public var sessionCount: Int
    
    public init() {
        totalDwellTime_s = 0.0
        angularCoverage = AngularCoverage()
        sessionCount = 0
    }
    
    public init(totalDwellTime_s: Double, angularCoverage: AngularCoverage, sessionCount: Int) {
        self.totalDwellTime_s = totalDwellTime_s
        self.angularCoverage = angularCoverage
        self.sessionCount = sessionCount
    }
    
    /// Compute display color tier
    public var colorTier: DataQualityTier {
        if totalDwellTime_s < 3.0 {
            return .red
        } else if totalDwellTime_s < 9.0 {
            return .yellow
        } else if angularCoverage.coveredSectorCount >= 3 {
            return .blue
        } else {
            return .green
        }
    }
}

/// RSSI measurements for a single beacon during one survey session
public struct SurveyBeaconMeasurement: Codable, Equatable {
    public let beaconID: String
    public let stats: SurveyStats
    public let histogram: SurveyHistogram
    public let samples: [RssiSample]  // Raw timeline, bookended with rssi=0
    public let meta: SurveyBeaconMeta
    
    public init(beaconID: String, stats: SurveyStats, histogram: SurveyHistogram, samples: [RssiSample], meta: SurveyBeaconMeta) {
        self.beaconID = beaconID
        self.stats = stats
        self.histogram = histogram
        self.samples = samples
        self.meta = meta
    }
}

/// A single survey collection session at a grid point
public struct SurveySession: Codable, Identifiable, Equatable {
    public let id: String                // UUID string
    public let locationID: String
    
    // Timing
    public let startISO: String          // ISO8601 timestamp
    public let endISO: String            // ISO8601 timestamp
    public let duration_s: Double        // Should be 3+ seconds
    
    // Device pose during collection (reference snapshot at session start)
    public let devicePose: SurveyDevicePose
    
    // Compass snapshot for magnetic distortion mapping
    public let compassHeading_deg: Float
    
    // Device pose track (sampled at 4 Hz, independent of beacon readings)
    public let poseTrack: [PoseSample]
    
    // Magnetometer track (sampled at same timestamps as pose for correlation)
    public let magnetometerTrack: [MagnetometerSample]
    
    // Beacon measurements
    public let beacons: [SurveyBeaconMeasurement]
    
    public init(id: String, locationID: String, startISO: String, endISO: String, duration_s: Double, devicePose: SurveyDevicePose, compassHeading_deg: Float, poseTrack: [PoseSample], magnetometerTrack: [MagnetometerSample], beacons: [SurveyBeaconMeasurement]) {
        self.id = id
        self.locationID = locationID
        self.startISO = startISO
        self.endISO = endISO
        self.duration_s = duration_s
        self.devicePose = devicePose
        self.compassHeading_deg = compassHeading_deg
        self.poseTrack = poseTrack
        self.magnetometerTrack = magnetometerTrack
        self.beacons = beacons
    }
}

/// A survey location with accumulated sessions and quality metrics
public struct SurveyPoint: Codable, Identifiable, Equatable {
    public let id: String                     // Stable ID (derived from initial coordinates)
    public var mapX: Double                   // Map X coordinate (pixels) - weighted average
    public var mapY: Double                   // Map Y coordinate (pixels) - weighted average
    public var sessions: [SurveySession]
    public var quality: SurveyPointQuality
    
    // For weighted coordinate averaging when merging nearby points
    public var weightedSumX: Double           // ?(mapX ? dwellTime)
    public var weightedSumY: Double           // ?(mapY ? dwellTime)
    // Note: totalWeight is quality.totalDwellTime_s
    
    public init(id: String, mapX: Double, mapY: Double, sessions: [SurveySession] = [], quality: SurveyPointQuality = SurveyPointQuality()) {
        self.id = id
        self.mapX = mapX
        self.mapY = mapY
        self.sessions = sessions
        self.quality = quality
        // Initialize weighted sums from current coordinates and quality
        self.weightedSumX = mapX * quality.totalDwellTime_s
        self.weightedSumY = mapY * quality.totalDwellTime_s
    }
    
    /// Recalculate mapX/mapY from weighted sums after adding new data
    public mutating func recalculateCoordinates() {
        guard quality.totalDwellTime_s > 0 else { return }
        mapX = weightedSumX / quality.totalDwellTime_s
        mapY = weightedSumY / quality.totalDwellTime_s
    }
    
    /// Add a session and update quality metrics
    /// - Parameters:
    ///   - session: The session to add
    ///   - atMapX: Map X coordinate where session was collected
    ///   - atMapY: Map Y coordinate where session was collected
    public mutating func addSession(_ session: SurveySession, atMapX: Double, atMapY: Double) {
        sessions.append(session)
        
        // Update quality metrics
        quality.sessionCount += 1
        quality.totalDwellTime_s += session.duration_s
        
        // Update weighted coordinate sums
        weightedSumX += atMapX * session.duration_s
        weightedSumY += atMapY * session.duration_s
        
        // Recalculate centroid
        recalculateCoordinates()
    }
    
    /// Create a coordinate key from map coordinates (2 decimal places)
    public static func makeKey(x: Double, y: Double) -> String {
        return String(format: "%.2f,%.2f", x, y)
    }
    
    /// Parse coordinate key back to (x, y) tuple
    public static func parseKey(_ key: String) -> (x: Double, y: Double)? {
        let parts = key.split(separator: ",")
        guard parts.count == 2,
              let x = Double(parts[0]),
              let y = Double(parts[1]) else {
            return nil
        }
        return (x, y)
    }
}

// MARK: - Survey Point Store

@MainActor
public class SurveyPointStore: ObservableObject {
    
    // MARK: - Published State
    
    @Published public private(set) var surveyPoints: [String: SurveyPoint] = [:]
    
    // MARK: - Private Properties
    
    private let defaults = UserDefaults.standard
    
    // MARK: - Public Properties
    
    /// Current location ID
    public private(set) var locationID: String = ""
    
    private var storageKey: String {
        "locations.\(locationID).surveyPoints_v1"
    }
    
    // MARK: - Initialization
    
    public init() {
        // Subscribe to location changes
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
        let newLocationID = PersistenceContext.shared.locationID
        print("?? [SurveyPointStore] Location changed ? \(newLocationID)")
        setLocation(newLocationID)
    }
    
    // MARK: - Location Management
    
    /// Set the current location context. Call this when location changes.
    public func setLocation(_ locationID: String) {
        self.locationID = locationID
        load()
        print("?? [SurveyPointStore] Set location: \(locationID), loaded \(surveyPoints.count) survey points")
    }
    
    // MARK: - Public API
    
    /// Get all survey points as an array
    public var allPoints: [SurveyPoint] {
        Array(surveyPoints.values)
    }
    
    /// Get survey point by coordinate key
    public func point(at key: String) -> SurveyPoint? {
        surveyPoints[key]
    }
    
    /// Get survey point by coordinates
    public func point(x: Double, y: Double) -> SurveyPoint? {
        let key = SurveyPoint.makeKey(x: x, y: y)
        return surveyPoints[key]
    }
    
    /// Add a new session to a survey point (creates point if needed)
    public func addSession(_ session: SurveySession, at x: Double, y: Double) {
        let key = SurveyPoint.makeKey(x: x, y: y)
        
        if var existing = surveyPoints[key] {
            // Append to existing point using new addSession method
            existing.addSession(session, atMapX: x, atMapY: y)
            surveyPoints[key] = existing
            print("?? [SurveyPointStore] Added session to existing point \(key), now has \(existing.sessions.count) sessions")
        } else {
            // Create new point
            var newPoint = SurveyPoint(
                id: key,
                mapX: x,
                mapY: y
            )
            newPoint.addSession(session, atMapX: x, atMapY: y)
            surveyPoints[key] = newPoint
            print("?? [SurveyPointStore] Created new survey point \(key)")
        }
        
        save()
    }
    
    // MARK: - Session Management
    
    /// Add a survey session at the given map coordinate
    /// Handles spatial merging (0-3cm) and creates new points as needed
    public func addSession(_ session: SurveySession, atMapCoordinate coordinate: CGPoint) {
        let mapX = Double(coordinate.x)
        let mapY = Double(coordinate.y)
        
        // Find nearest existing point
        let (nearestPoint, distance) = findNearestPoint(to: coordinate)
        
        // Merge zone: 0-3cm (0.03 meters, but coordinates are in pixels)
        // Convert 3cm to pixels using approximate scale (will need refinement)
        // For now, use 3 pixels as rough equivalent
        let mergeThresholdPixels: Double = 3.0
        
        if let existingPoint = nearestPoint, distance < mergeThresholdPixels {
            // Merge into existing point
            mergeSession(session, into: existingPoint.id, atMapX: mapX, atMapY: mapY)
            print("📊 [SurveyPointStore] Merged session into existing point \(String(existingPoint.id.prefix(8))) (distance: \(String(format: "%.2f", distance)) px)")
        } else {
            // Create new point
            let newPointID = UUID().uuidString
            var newPoint = SurveyPoint(
                id: newPointID,
                mapX: mapX,
                mapY: mapY
            )
            newPoint.addSession(session, atMapX: mapX, atMapY: mapY)
            surveyPoints[newPointID] = newPoint
            save()
            print("📊 [SurveyPointStore] Created new survey point \(String(newPointID.prefix(8))) at (\(String(format: "%.1f", mapX)), \(String(format: "%.1f", mapY)))")
        }
    }
    
    /// Merge a session into an existing point with weighted coordinate averaging
    private func mergeSession(_ session: SurveySession, into pointID: String, atMapX: Double, atMapY: Double) {
        guard var point = surveyPoints[pointID] else {
            print("⚠️ [SurveyPointStore] Cannot merge - point \(pointID) not found")
            return
        }
        
        point.addSession(session, atMapX: atMapX, atMapY: atMapY)
        surveyPoints[pointID] = point
        save()
    }
    
    /// Find the nearest survey point to given coordinates
    /// Returns (point, distance) or (nil, .infinity) if no points exist
    private func findNearestPoint(to coordinate: CGPoint) -> (SurveyPoint?, Double) {
        var nearest: SurveyPoint?
        var minDistance = Double.infinity
        
        let x = Double(coordinate.x)
        let y = Double(coordinate.y)
        
        for point in surveyPoints.values {
            let dx = point.mapX - x
            let dy = point.mapY - y
            let distance = sqrt(dx * dx + dy * dy)
            
            if distance < minDistance {
                minDistance = distance
                nearest = point
            }
        }
        
        return (nearest, minDistance)
    }
    
    // MARK: - Spatial Queries for Marker Coloring

    /// Query accumulated dwell time near a coordinate with linear distance falloff
    /// - Parameters:
    ///   - coordinate: Map coordinate in pixels
    ///   - radiusPixels: Influence radius in pixels (points beyond this contribute nothing)
    /// - Returns: Weighted sum of dwell time from nearby SurveyPoints
    public func weightedDwellTimeNear(coordinate: CGPoint, radiusPixels: Double) -> Double {
        guard radiusPixels > 0 else { return 0.0 }
        
        let x = Double(coordinate.x)
        let y = Double(coordinate.y)
        var weightedSum: Double = 0.0
        
        for point in surveyPoints.values {
            let dx = point.mapX - x
            let dy = point.mapY - y
            let distance = sqrt(dx * dx + dy * dy)
            
            // Skip points outside influence radius
            guard distance < radiusPixels else { continue }
            
            // Linear falloff: 1.0 at center, 0.0 at edge
            let weight = 1.0 - (distance / radiusPixels)
            weightedSum += weight * point.quality.totalDwellTime_s
        }
        
        return weightedSum
    }
    
    /// Remove a specific session from a survey point
    public func removeSession(sessionID: String, from coordinateKey: String) {
        guard var point = surveyPoints[coordinateKey] else {
            print("?? [SurveyPointStore] Cannot remove session - point \(coordinateKey) not found")
            return
        }
        
        let beforeCount = point.sessions.count
        point.sessions.removeAll { $0.id == sessionID }
        
        if point.sessions.isEmpty {
            // Remove point entirely if no sessions remain
            surveyPoints.removeValue(forKey: coordinateKey)
            print("??? [SurveyPointStore] Removed point \(coordinateKey) (last session deleted)")
        } else {
            surveyPoints[coordinateKey] = point
            print("??? [SurveyPointStore] Removed session from \(coordinateKey), \(beforeCount) ? \(point.sessions.count) sessions")
        }
        
        save()
    }
    
    /// Remove an entire survey point and all its sessions
    public func removePoint(at coordinateKey: String) {
        if surveyPoints.removeValue(forKey: coordinateKey) != nil {
            print("??? [SurveyPointStore] Removed survey point \(coordinateKey)")
            save()
        }
    }
    
    /// Clear all survey points for current location
    public func clearAll() {
        let count = surveyPoints.count
        surveyPoints.removeAll()
        save()
        print("??? [SurveyPointStore] Cleared all \(count) survey points for location \(locationID)")
    }
    
    /// Purge all survey points (alias for clearAll for consistency)
    public func purgeAll() {
        let count = surveyPoints.count
        let key = storageKey
        surveyPoints.removeAll()
        save()
        print("🗑️ [SurveyPointStore] Purged \(count) points from \(key)")
    }
    
    /// Get all survey points as an array (alias for allPoints for consistency)
    public var points: [SurveyPoint] {
        allPoints
    }
    
    /// Get total session count across all points
    public var totalSessionCount: Int {
        surveyPoints.values.reduce(0) { $0 + $1.sessions.count }
    }
    
    // MARK: - Persistence
    
    private func save() {
        guard !locationID.isEmpty else {
            print("?? [SurveyPointStore] Cannot save - no location set")
            return
        }
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(Array(surveyPoints.values))
            defaults.set(data, forKey: storageKey)
            print("?? [SurveyPointStore] Saved \(surveyPoints.count) points to \(storageKey)")
        } catch {
            print("? [SurveyPointStore] Save failed: \(error)")
        }
    }
    
    private func load() {
        guard !locationID.isEmpty else {
            surveyPoints = [:]
            return
        }
        
        guard let data = defaults.data(forKey: storageKey) else {
            surveyPoints = [:]
            print("?? [SurveyPointStore] No existing data for \(storageKey)")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            let points = try decoder.decode([SurveyPoint].self, from: data)
            surveyPoints = Dictionary(uniqueKeysWithValues: points.map { ($0.id, $0) })
            print("?? [SurveyPointStore] Loaded \(surveyPoints.count) points from \(storageKey)")
        } catch {
            print("? [SurveyPointStore] Load failed: \(error)")
            surveyPoints = [:]
        }
    }
    
    // MARK: - Export
    
    /// Export all survey points as JSON data
    public func exportJSON() -> Data? {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            return try encoder.encode(Array(surveyPoints.values))
        } catch {
            print("? [SurveyPointStore] Export failed: \(error)")
            return nil
        }
    }
    
    /// Import survey points from JSON data (merges with existing)
    public func importJSON(_ data: Data, merge: Bool = true) throws {
        let decoder = JSONDecoder()
        let importedPoints = try decoder.decode([SurveyPoint].self, from: data)
        
        if merge {
            // Merge: append sessions to existing points, add new points
            for point in importedPoints {
                if var existing = surveyPoints[point.id] {
                    // Avoid duplicate session IDs
                    let existingIDs = Set(existing.sessions.map { $0.id })
                    let newSessions = point.sessions.filter { !existingIDs.contains($0.id) }
                    // Add each new session using addSession to update quality metrics
                    for session in newSessions {
                        existing.addSession(session, atMapX: point.mapX, atMapY: point.mapY)
                    }
                    surveyPoints[point.id] = existing
                } else {
                    surveyPoints[point.id] = point
                }
            }
            print("?? [SurveyPointStore] Merged \(importedPoints.count) points")
        } else {
            // Replace: clear and load
            surveyPoints = Dictionary(uniqueKeysWithValues: importedPoints.map { ($0.id, $0) })
            print("?? [SurveyPointStore] Replaced with \(importedPoints.count) points")
        }
        
        save()
    }
}

// MARK: - UIColor Extension for DataQualityTier

extension DataQualityTier {
    public var uiColor: UIColor {
        switch self {
        case .red: return .systemRed
        case .yellow: return .systemYellow
        case .green: return .systemGreen
        case .blue: return .systemBlue
        }
    }
}
