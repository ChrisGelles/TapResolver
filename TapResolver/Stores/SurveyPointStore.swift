//
//  SurveyPointStore.swift
//  TapResolver
//
//  Data store for Survey Marker RSSI collection sessions.
//  Survey points are identified by their 2D map coordinates.
//

import Foundation
import Combine

// MARK: - Data Structures

/// A single RSSI sample with timestamp
public struct RssiSample: Codable, Equatable {
    public let ms: Int64      // Milliseconds from session start
    public let rssi: Int      // dBm value, 0 = signal gap marker
    
    public init(ms: Int64, rssi: Int) {
        self.ms = ms
        self.rssi = rssi
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

/// RSSI measurements for a single beacon during one survey session
public struct SurveyBeaconMeasurement: Codable, Equatable {
    public let beaconID: String
    public let stats: SurveyStats
    public let histogram: SurveyHistogram
    public let samples: [RssiSample]     // Always present, zero-bookended for gaps
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
    
    // Device pose during collection
    public let devicePose: SurveyDevicePose
    
    // Beacon measurements
    public let beacons: [SurveyBeaconMeasurement]
    
    public init(id: String, locationID: String, startISO: String, endISO: String, duration_s: Double, devicePose: SurveyDevicePose, beacons: [SurveyBeaconMeasurement]) {
        self.id = id
        self.locationID = locationID
        self.startISO = startISO
        self.endISO = endISO
        self.duration_s = duration_s
        self.devicePose = devicePose
        self.beacons = beacons
    }
}

/// A survey point identified by its 2D map coordinates
public struct SurveyPoint: Codable, Identifiable, Equatable {
    public var id: String { coordinateKey }
    
    public let coordinateKey: String     // "XX.XX,YY.YY" format
    public let mapX_m: Double            // Parsed X coordinate in meters
    public let mapY_m: Double            // Parsed Y coordinate in meters
    public let createdISO: String        // Timestamp of first session
    public var sessions: [SurveySession] // Multiple sessions can accumulate
    
    public init(coordinateKey: String, mapX_m: Double, mapY_m: Double, createdISO: String, sessions: [SurveySession]) {
        self.coordinateKey = coordinateKey
        self.mapX_m = mapX_m
        self.mapY_m = mapY_m
        self.createdISO = createdISO
        self.sessions = sessions
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
    private var locationID: String = ""
    
    private var storageKey: String {
        "surveyPoints_\(locationID)"
    }
    
    // MARK: - Initialization
    
    public init() {
        // Location must be set via setLocation() before use
    }
    
    // MARK: - Location Management
    
    /// Set the current location context. Call this when location changes.
    public func setLocation(_ locationID: String) {
        self.locationID = locationID
        load()
        print("📍 [SurveyPointStore] Set location: \(locationID), loaded \(surveyPoints.count) survey points")
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
            // Append to existing point
            existing.sessions.append(session)
            surveyPoints[key] = existing
            print("📊 [SurveyPointStore] Added session to existing point \(key), now has \(existing.sessions.count) sessions")
        } else {
            // Create new point
            let newPoint = SurveyPoint(
                coordinateKey: key,
                mapX_m: x,
                mapY_m: y,
                createdISO: session.startISO,
                sessions: [session]
            )
            surveyPoints[key] = newPoint
            print("📊 [SurveyPointStore] Created new survey point \(key)")
        }
        
        save()
    }
    
    /// Remove a specific session from a survey point
    public func removeSession(sessionID: String, from coordinateKey: String) {
        guard var point = surveyPoints[coordinateKey] else {
            print("⚠️ [SurveyPointStore] Cannot remove session - point \(coordinateKey) not found")
            return
        }
        
        let beforeCount = point.sessions.count
        point.sessions.removeAll { $0.id == sessionID }
        
        if point.sessions.isEmpty {
            // Remove point entirely if no sessions remain
            surveyPoints.removeValue(forKey: coordinateKey)
            print("🗑️ [SurveyPointStore] Removed point \(coordinateKey) (last session deleted)")
        } else {
            surveyPoints[coordinateKey] = point
            print("🗑️ [SurveyPointStore] Removed session from \(coordinateKey), \(beforeCount) → \(point.sessions.count) sessions")
        }
        
        save()
    }
    
    /// Remove an entire survey point and all its sessions
    public func removePoint(at coordinateKey: String) {
        if surveyPoints.removeValue(forKey: coordinateKey) != nil {
            print("🗑️ [SurveyPointStore] Removed survey point \(coordinateKey)")
            save()
        }
    }
    
    /// Clear all survey points for current location
    public func clearAll() {
        let count = surveyPoints.count
        surveyPoints.removeAll()
        save()
        print("🗑️ [SurveyPointStore] Cleared all \(count) survey points for location \(locationID)")
    }
    
    /// Get total session count across all points
    public var totalSessionCount: Int {
        surveyPoints.values.reduce(0) { $0 + $1.sessions.count }
    }
    
    // MARK: - Persistence
    
    private func save() {
        guard !locationID.isEmpty else {
            print("⚠️ [SurveyPointStore] Cannot save - no location set")
            return
        }
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(Array(surveyPoints.values))
            defaults.set(data, forKey: storageKey)
            print("💾 [SurveyPointStore] Saved \(surveyPoints.count) points to \(storageKey)")
        } catch {
            print("❌ [SurveyPointStore] Save failed: \(error)")
        }
    }
    
    private func load() {
        guard !locationID.isEmpty else {
            surveyPoints = [:]
            return
        }
        
        guard let data = defaults.data(forKey: storageKey) else {
            surveyPoints = [:]
            print("📂 [SurveyPointStore] No existing data for \(storageKey)")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            let points = try decoder.decode([SurveyPoint].self, from: data)
            surveyPoints = Dictionary(uniqueKeysWithValues: points.map { ($0.coordinateKey, $0) })
            print("📂 [SurveyPointStore] Loaded \(surveyPoints.count) points from \(storageKey)")
        } catch {
            print("❌ [SurveyPointStore] Load failed: \(error)")
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
            print("❌ [SurveyPointStore] Export failed: \(error)")
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
                if var existing = surveyPoints[point.coordinateKey] {
                    // Avoid duplicate session IDs
                    let existingIDs = Set(existing.sessions.map { $0.id })
                    let newSessions = point.sessions.filter { !existingIDs.contains($0.id) }
                    existing.sessions.append(contentsOf: newSessions)
                    surveyPoints[point.coordinateKey] = existing
                } else {
                    surveyPoints[point.coordinateKey] = point
                }
            }
            print("📥 [SurveyPointStore] Merged \(importedPoints.count) points")
        } else {
            // Replace: clear and load
            surveyPoints = Dictionary(uniqueKeysWithValues: importedPoints.map { ($0.coordinateKey, $0) })
            print("📥 [SurveyPointStore] Replaced with \(importedPoints.count) points")
        }
        
        save()
    }
}
