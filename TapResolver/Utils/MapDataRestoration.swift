//
//  MapDataRestoration.swift
//  TapResolver
//
//  Data recovery utilities for map points and sessions
//  Created: 2025-10-22
//
//  CONTEXT: Location switching bug caused map point data loss in UserDefaults
//  while session JSON files remained intact on disk. These utilities recover
//  and reconnect orphaned data.
//
//  NOTE: This file contains recovery code that can be temporarily enabled by
//  adding UI buttons or console commands. After successful recovery, these
//  functions can remain dormant in the codebase for future use if needed.
//

import Foundation
import CoreGraphics

extension MapPointStore {
    
    /// RECOVERY STEP 1: Rebuild map points from orphaned session files
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
                    sessions: []  // Empty for now - sessions reconnected in step 2
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
            print("\n⚠️  NOTE: Map points recovered, but sessions not yet reconnected")
            print("   Run reconnectSessionFiles() to attach session data")
            
            // Step 5: Save to UserDefaults
            self.points = mergedPoints
            
            // Temporarily disable protection for this save
            let wasReloading = isReloading
            isReloading = false
            save()
            isReloading = wasReloading
            
            print("\n✅ RECOVERY COMPLETE")
            print("   Map points have been rebuilt and saved to UserDefaults")
            print("   Run Step 2 to reconnect sessions")
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
                let txPower = json["txPower_\(beaconID)"] as? Int
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
}
