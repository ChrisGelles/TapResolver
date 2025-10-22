//
//  MapPointStore.swift
//  TapResolver
//
//  Created by restructuring on 9/24/25.
//

import SwiftUI
import CoreGraphics
import Combine

// Notification for when map points reload
extension Notification.Name {
    static let mapPointsDidReload = Notification.Name("mapPointsDidReload")
    static let scanSessionSaved = Notification.Name("scanSessionSaved")
}

// MARK: - Store of Map Points (log points) with map-local positions
public final class MapPointStore: ObservableObject {
    private let ctx = PersistenceContext.shared
    private var scanSessionCancellable: AnyCancellable?
    
    // CRITICAL: Prevent data loss during reload operations
    private var isReloading: Bool = false
    
    // DIAGNOSTIC: Track which instance this is
    internal let instanceID = UUID().uuidString
    
    public struct MapPoint: Identifiable {
        public let id: UUID
        public var mapPoint: CGPoint    // map-local (untransformed) coords
        public let createdDate: Date
        public var sessions: [ScanSession] = []  // Full scan session data stored in UserDefaults
        
        // Initializer that accepts existing ID or generates new one
        init(id: UUID? = nil, mapPoint: CGPoint, createdDate: Date? = nil, sessions: [ScanSession] = []) {
            self.id = id ?? UUID()
            self.mapPoint = mapPoint
            self.createdDate = createdDate ?? Date()
            self.sessions = sessions
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

    @Published public private(set) var points: [MapPoint] = []
    @Published public private(set) var activePointID: UUID? = nil
    
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
    
    /// ONE-TIME RECOVERY: Rebuild map points from orphaned session files
    /// This recovers data lost during the location switching bug
    public func recoverFromSessionFiles() {
        print("\n" + String(repeating: "=", count: 80))
        print("🔧 RECOVERY: Rebuilding map points from session files")
        print(String(repeating: "=", count: 80))
        
        let scansDir = ctx.locationDir.appendingPathComponent("Scans", isDirectory: true)
        let fileManager = FileManager.default
        
        guard fileManager.fileExists(atPath: scansDir.path) else {
            print("❌ No Scans directory found")
            print(String(repeating: "=", count: 80) + "\n")
            return
        }
        
        do {
            // Step 1: Read all session files
            let files = try fileManager.contentsOfDirectory(atPath: scansDir.path)
            let jsonFiles = files.filter { $0.hasSuffix(".json") }
            
            print("📁 Found \(jsonFiles.count) session files")
            
            // Group by mapPointID with coordinates
            var pointData: [UUID: (x: CGFloat, y: CGFloat, earliestDate: Date)] = [:]
            var successCount = 0
            var failCount = 0
            
            // Step 2: Parse each file - extract ONLY mapPointID and coordinates
            for file in jsonFiles {
                let fileURL = scansDir.appendingPathComponent(file)
                
                guard let data = try? Data(contentsOf: fileURL),
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    print("⚠️ Failed to read: \(file)")
                    failCount += 1
                    continue
                }
                
                // Extract the key fields from OLD v1 format
                guard let mapPointIDString = json["mapPointID"] as? String,
                      let mapPointID = UUID(uuidString: mapPointIDString),
                      let x = json["coordinatesX"] as? Double,
                      let y = json["coordinatesY"] as? Double else {
                    print("⚠️ Missing mapPointID or coordinates in: \(file)")
                    failCount += 1
                    continue
                }
                
                // Get timestamp for determining earliest creation date
                let dateString = json["endTime"] as? String ?? json["startTime"] as? String ?? ""
                let date = ISO8601DateFormatter().date(from: dateString) ?? Date()
                
                // Track this point and its earliest date
                if let existing = pointData[mapPointID] {
                    // Keep earliest date
                    if date < existing.earliestDate {
                        pointData[mapPointID] = (x: CGFloat(x), y: CGFloat(y), earliestDate: date)
                    }
                } else {
                    pointData[mapPointID] = (x: CGFloat(x), y: CGFloat(y), earliestDate: date)
                }
                
                successCount += 1
            }
            
            print("✅ Successfully parsed: \(successCount) files")
            print("❌ Failed to parse: \(failCount) files")
            print("📍 Found \(pointData.count) unique map points")
            
            // Step 3: Build MapPoint objects (WITHOUT sessions for now)
            var recoveredPoints: [MapPoint] = []
            
            for (pointID, data) in pointData {
                let point = MapPoint(
                    id: pointID,
                    mapPoint: CGPoint(x: data.x, y: data.y),
                    createdDate: data.earliestDate,
                    sessions: []  // Empty for now - sessions can be re-scanned
                )
                
                recoveredPoints.append(point)
                
                print("   📍 Point \(String(pointID.uuidString.prefix(8)))... at (\(Int(data.x)), \(Int(data.y)))")
                print("      Created: \(data.earliestDate)")
            }
            
            // Step 4: Merge with existing points (keep any test points)
            let existingPointIDs = Set(self.points.map { $0.id })
            let recoveredPointIDs = Set(recoveredPoints.map { $0.id })
            
            // Keep existing points that aren't being recovered
            let existingPoints = self.points.filter { point in
                !recoveredPointIDs.contains(point.id)
            }
            
            let mergedPoints = existingPoints + recoveredPoints
            
            print("\n📊 Recovery Summary:")
            print("   Existing points kept: \(existingPoints.count)")
            print("   Recovered points: \(recoveredPoints.count)")
            print("   Total points: \(mergedPoints.count)")
            print("\n⚠️  NOTE: Map points recovered, but old session data is in v1 format")
            print("   Sessions are empty - you can re-scan at each point to collect new data")
            
            // Step 5: Save to UserDefaults
            self.points = mergedPoints
            
            // Temporarily disable protection for this save
            let wasReloading = isReloading
            isReloading = false
            save()
            isReloading = wasReloading
            
            print("\n✅ RECOVERY COMPLETE")
            print("   Map points have been rebuilt and saved to UserDefaults")
            print("   You can now see all recovered points on the map")
            print(String(repeating: "=", count: 80) + "\n")
            
        } catch {
            print("❌ Recovery failed: \(error)")
            print(String(repeating: "=", count: 80) + "\n")
        }
    }
    
    /// RECOVERY STEP 2: Reconnect orphaned session files to recovered map points
    /// Converts old v1 session format to current ScanSession format
    public func reconnectSessionFiles() {
        print("\n" + String(repeating: "=", count: 80))
        print("🔗 RECOVERY: Reconnecting session files to map points")
        print(String(repeating: "=", count: 80))
        
        let scansDir = ctx.locationDir.appendingPathComponent("Scans", isDirectory: true)
        let fileManager = FileManager.default
        
        guard fileManager.fileExists(atPath: scansDir.path) else {
            print("❌ No Scans directory found")
            print(String(repeating: "=", count: 80) + "\n")
            return
        }
        
        do {
            // Step 1: Read all session files
            let files = try fileManager.contentsOfDirectory(atPath: scansDir.path)
            let jsonFiles = files.filter { $0.hasSuffix(".json") }
            
            print("📁 Found \(jsonFiles.count) session files to process")
            
            // Group sessions by mapPointID
            var sessionsByPoint: [UUID: [ScanSession]] = [:]
            var successCount = 0
            var failCount = 0
            
            // Step 2: Parse each file and convert to current format
            for (index, file) in jsonFiles.enumerated() {
                let fileURL = scansDir.appendingPathComponent(file)
                
                guard let data = try? Data(contentsOf: fileURL),
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    failCount += 1
                    continue
                }
                
                // Extract required fields
                guard let mapPointIDString = json["mapPointID"] as? String,
                      let mapPointID = UUID(uuidString: mapPointIDString) else {
                    failCount += 1
                    continue
                }
                
                // Check if this map point exists
                guard points.contains(where: { $0.id == mapPointID }) else {
                    print("⚠️  Skipping session for non-existent point: \(String(mapPointIDString.prefix(8)))...")
                    failCount += 1
                    continue
                }
                
                // Convert old v1 format to current ScanSession format
                guard let convertedSession = convertV1SessionToCurrent(json: json, fileURL: fileURL) else {
                    failCount += 1
                    continue
                }
                
                // Group by point
                if sessionsByPoint[mapPointID] == nil {
                    sessionsByPoint[mapPointID] = []
                }
                sessionsByPoint[mapPointID]?.append(convertedSession)
                successCount += 1
                
                // Progress indicator
                if (index + 1) % 10 == 0 {
                    print("   Processed \(index + 1)/\(jsonFiles.count)...")
                }
            }
            
            print("\n✅ Successfully converted: \(successCount) sessions")
            print("❌ Failed to convert: \(failCount) sessions")
            print("📍 Sessions distributed across \(sessionsByPoint.count) map points")
            
            // Step 3: Attach sessions to map points
            var updatedCount = 0
            for i in 0..<points.count {
                let pointID = points[i].id
                if let sessions = sessionsByPoint[pointID] {
                    points[i].sessions = sessions
                    updatedCount += 1
                    print("   📍 Point \(String(pointID.uuidString.prefix(8)))... now has \(sessions.count) sessions")
                }
            }
            
            print("\n📊 Reconnection Summary:")
            print("   Map points updated: \(updatedCount)")
            print("   Total sessions reconnected: \(successCount)")
            
            // Step 4: Save to UserDefaults
            let wasReloading = isReloading
            isReloading = false
            save()
            isReloading = wasReloading
            
            print("\n✅ RECONNECTION COMPLETE")
            print("   All sessions have been reconnected to their map points")
            print(String(repeating: "=", count: 80) + "\n")
            
        } catch {
            print("❌ Reconnection failed: \(error)")
            print(String(repeating: "=", count: 80) + "\n")
        }
    }
    
    /// Convert old v1 session format to current ScanSession format
    private func convertV1SessionToCurrent(json: [String: Any], fileURL: URL) -> ScanSession? {
        // Extract basic session info
        guard let mapPointIDString = json["mapPointID"] as? String,
              let startTime = json["startTime"] as? String ?? json["endTime"] as? String,
              let endTime = json["endTime"] as? String,
              let duration = json["duration"] as? Double else {
            return nil
        }
        
        let sessionID = fileURL.deletingPathExtension().lastPathComponent
        let scanID = "scan_\(startTime.replacingOccurrences(of: ":", with: "-"))_\(mapPointIDString)"
        
        let deviceHeight = json["deviceHeight"] as? Double ?? 1.05
        let facing = json["facing"] as? Double
        
        // Convert beacon data from old format
        var beacons: [ScanSession.BeaconData] = []
        
        if let obinsPerBeacon = json["obinsPerBeacon"] as? [String: [[String: Any]]] {
            for (beaconID, bins) in obinsPerBeacon {
                // Calculate stats from histogram bins
                let (median, mad, p10, p90, sampleCount) = calculateStatsFromBins(bins)
                
                // Build histogram
                let (binMin, binMax, binSize, counts) = buildHistogramFromBins(bins)
                
                // Get metadata
                let model = json["deviceModel"] as? String ?? "Unknown"
                let txPower = json["txPower_\(beaconID)"] as? Int  // if stored per-beacon
                let msInt = json["interval"] as? Int ?? 100
                
                let beaconData = ScanSession.BeaconData(
                    beaconID: beaconID,
                    stats: ScanSession.BeaconData.Stats(
                        median_dbm: median,
                        mad_db: mad,
                        p10_dbm: p10,
                        p90_dbm: p90,
                        samples: sampleCount
                    ),
                    hist: ScanSession.BeaconData.Histogram(
                        binMin_dbm: binMin,
                        binMax_dbm: binMax,
                        binSize_db: binSize,
                        counts: counts
                    ),
                    samples: nil,  // Old format didn't store raw samples
                    meta: ScanSession.BeaconData.Metadata(
                        name: beaconID,
                        model: model,
                        txPower: txPower,
                        msInt: msInt
                    )
                )
                
                beacons.append(beaconData)
            }
        }
        
        return ScanSession(
            scanID: scanID,
            sessionID: sessionID,
            pointID: mapPointIDString,
            locationID: ctx.locationID,
            timingStartISO: startTime,
            timingEndISO: endTime,
            duration_s: duration,
            deviceHeight_m: deviceHeight,
            facing_deg: facing,
            beacons: beacons
        )
    }
    
    /// Calculate statistics from histogram bins
    private func calculateStatsFromBins(_ bins: [[String: Any]]) -> (median: Int, mad: Int, p10: Int, p90: Int, count: Int) {
        var allRssi: [Int] = []
        
        // Expand bins into individual RSSI values
        for bin in bins {
            if let rssi = bin["rssi"] as? Int,
               let count = bin["count"] as? Int {
                allRssi.append(contentsOf: Array(repeating: rssi, count: count))
            }
        }
        
        guard !allRssi.isEmpty else {
            return (median: -70, mad: 5, p10: -80, p90: -60, count: 0)
        }
        
        allRssi.sort()
        let count = allRssi.count
        
        let median = allRssi[count / 2]
        let p10Index = Int(Double(count) * 0.1)
        let p90Index = Int(Double(count) * 0.9)
        let p10 = allRssi[p10Index]
        let p90 = allRssi[p90Index]
        
        // Calculate MAD (median absolute deviation)
        let deviations = allRssi.map { abs($0 - median) }.sorted()
        let mad = deviations[deviations.count / 2]
        
        return (median: median, mad: mad, p10: p10, p90: p90, count: count)
    }
    
    /// Build histogram structure from bins
    private func buildHistogramFromBins(_ bins: [[String: Any]]) -> (binMin: Int, binMax: Int, binSize: Int, counts: [Int]) {
        guard !bins.isEmpty else {
            return (binMin: -100, binMax: -40, binSize: 1, counts: [])
        }
        
        // Extract RSSI values and counts
        var rssiToCounts: [(rssi: Int, count: Int)] = []
        for bin in bins {
            if let rssi = bin["rssi"] as? Int,
               let count = bin["count"] as? Int {
                rssiToCounts.append((rssi: rssi, count: count))
            }
        }
        
        rssiToCounts.sort { $0.rssi < $1.rssi }
        
        let binMin = rssiToCounts.first?.rssi ?? -100
        let binMax = rssiToCounts.last?.rssi ?? -40
        let binSize = 1  // Old format used 1 dB bins
        let counts = rssiToCounts.map { $0.count }
        
        return (binMin: binMin, binMax: binMax, binSize: binSize, counts: counts)
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
    }

    private func save() {
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
            sessions: $0.sessions
        )}
        ctx.write(pointsKey, value: dto)
        if let activeID = activePointID {
            ctx.write(activePointKey, value: activeID)
        }
        
        print("ðŸ’¾ Saved Map Points to UserDefaults:")
        print("   Location: \(ctx.locationID)")
        print("   Points: \(points.count)")
        for point in points {
            print("   â€¢ \(String(point.id.uuidString.prefix(8)))... @ (\(Int(point.mapPoint.x)),\(Int(point.mapPoint.y))) - \(point.sessions.count) sessions")
        }
    }

    private func load() {
        print("\nðŸ”„ MapPointStore.load() CALLED")
        print("   Instance ID: \(String(instanceID.prefix(8)))...")
        print("   Current locationID: \(ctx.locationID)")
        
        if let dto: [MapPointDTO] = ctx.read(pointsKey, as: [MapPointDTO].self) {
            
            // DIAGNOSTIC: Print raw museum data if this is museum location
            if ctx.locationID == "museum" {
                print("\n" + String(repeating: "=", count: 80))
                print("🔍 MUSEUM LOCATION DATA DIAGNOSTIC")
                print(String(repeating: "=", count: 80))
                print("Full key: locations.museum.MapPoints_v1")
                print("Raw DTO count: \(dto.count)")
                
                // Check for orphaned session files on disk
                let scansDir = ctx.locationDir.appendingPathComponent("Scans", isDirectory: true)
                let fileManager = FileManager.default
                
                if fileManager.fileExists(atPath: scansDir.path) {
                    do {
                        let files = try fileManager.contentsOfDirectory(atPath: scansDir.path)
                        let jsonFiles = files.filter { $0.hasSuffix(".json") }
                        
                        print("\n📁 Session Files in Scans Directory:")
                        print("   Path: \(scansDir.path)")
                        print("   Total JSON files: \(jsonFiles.count)")
                        
                        if !jsonFiles.isEmpty {
                            print("\n   Session Files Found:")
                            for (index, file) in jsonFiles.enumerated() {
                                let fileURL = scansDir.appendingPathComponent(file)
                                if let data = try? Data(contentsOf: fileURL),
                                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                                    let sessionID = json["sessionID"] as? String ?? "unknown"
                                    let pointID = json["pointID"] as? String ?? "unknown"
                                    let beaconCount = (json["beacons"] as? [[String: Any]])?.count ?? 0
                                    let duration = json["duration_s"] as? Double ?? 0
                                    
                                    print("      [\(index + 1)] \(file)")
                                    print("          Session ID: \(sessionID)")
                                    print("          Point ID: \(String(pointID.prefix(8)))...")
                                    print("          Beacons: \(beaconCount)")
                                    print("          Duration: \(duration)s")
                                }
                            }
                            
                            // DIAGNOSTIC: Read the raw content of the first file
                            if let firstFile = jsonFiles.first {
                                let firstFileURL = scansDir.appendingPathComponent(firstFile)
                                print("\n🔍 RAW CONTENT OF FIRST FILE: \(firstFile)")
                                
                                if let data = try? Data(contentsOf: firstFileURL) {
                                    print("   File size: \(data.count) bytes")
                                    
                                    // Try to read as string
                                    if let jsonString = String(data: data, encoding: .utf8) {
                                        let preview = String(jsonString.prefix(500))
                                        print("   Content preview (first 500 chars):")
                                        print("   ---")
                                        print(preview)
                                        print("   ---")
                                        
                                        // Try to parse as JSON
                                        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                                            print("\n   ✅ Valid JSON structure")
                                            print("   Top-level keys: \(json.keys.sorted())")
                                            
                                            // Check for scan data structure
                                            if let beacons = json["beacons"] as? [[String: Any]] {
                                                print("   Beacons array: \(beacons.count) items")
                                                if let first = beacons.first {
                                                    print("   First beacon keys: \(first.keys.sorted())")
                                                }
                                            }
                                        } else {
                                            print("   ❌ Failed to parse as JSON")
                                        }
                                    } else {
                                        print("   ❌ Failed to decode as UTF-8 string")
                                    }
                                } else {
                                    print("   ❌ Failed to read file data")
                                }
                            }
                            
                            if dto.isEmpty {
                                print("\n   ⚠️ ORPHANED DATA DETECTED!")
                                print("   UserDefaults shows 0 map points, but \(jsonFiles.count) session files exist on disk")
                                print("   This data may be recoverable!")
                            }
                        }
                    } catch {
                        print("   ❌ Error reading Scans directory: \(error)")
                    }
                } else {
                    print("\n📁 No Scans directory found at: \(scansDir.path)")
                }
                
                if dto.isEmpty {
                    print("\n⚠️ Museum location has EMPTY array stored in UserDefaults")
                } else {
                    print("\n📍 Museum Map Points in UserDefaults:")
                    for (index, point) in dto.enumerated() {
                        print("   [\(index + 1)] Point ID: \(point.id.uuidString)")
                        print("       Position: (\(Int(point.x)), \(Int(point.y)))")
                        print("       Created: \(point.createdDate)")
                        print("       Sessions: \(point.sessions.count)")
                        if !point.sessions.isEmpty {
                            for (sIndex, session) in point.sessions.enumerated() {
                                print("          Session \(sIndex + 1): \(session.sessionID)")
                                print("             Beacons: \(session.beacons.count)")
                                print("             Duration: \(session.duration_s)s")
                            }
                        }
                    }
                }
                print(String(repeating: "=", count: 80) + "\n")
            }
            
            self.points = dto.map { dtoItem in
                MapPoint(
                    id: dtoItem.id,
                    mapPoint: CGPoint(x: dtoItem.x, y: dtoItem.y),
                    createdDate: dtoItem.createdDate,
                    sessions: dtoItem.sessions
                )
            }
            // Only log if there are points loaded
            if !points.isEmpty {
                print("ðŸ“‚ Loaded \(points.count) Map Point(s) with \(points.reduce(0) { $0 + $1.sessions.count }) sessions")
            }
        } else {
            self.points = []
        }
        
        // REMOVED: No longer load activePointID from UserDefaults
        // User must explicitly select a MapPoint each session
        
        print("   âœ… Load complete: \(points.count) points")
        print("   Total sessions: \(points.reduce(0) { $0 + $1.sessions.count })")
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
    
    deinit {
        print("ðŸ’¥ MapPointStore \(String(instanceID.prefix(8)))... deinitialized")
    }
    
}
