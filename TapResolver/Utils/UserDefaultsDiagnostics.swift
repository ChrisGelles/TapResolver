//
//  UserDefaultsDiagnostics.swift
//  TapResolver
//
//  Diagnostic tools for UserDefaults inspection and cleanup
//

import Foundation
import SwiftUI

struct UserDefaultsDiagnostics {
    
    /// Print total UserDefaults size at app launch
    static func printTotalSize() {
        let defaults = UserDefaults.standard
        var totalBytes = 0
        var keyCount = 0
        
        for (key, value) in defaults.dictionaryRepresentation() {
            keyCount += 1
            if let data = value as? Data {
                totalBytes += data.count
            } else if let archived = try? NSKeyedArchiver.archivedData(withRootObject: value, requiringSecureCoding: false) {
                totalBytes += archived.count
            }
        }
        
        let totalMB = Double(totalBytes) / 1_048_576
        let emoji: String
        let status: String
        if totalMB >= 4.0 {
            emoji = "🔴"
            status = "OVER LIMIT"
        } else if totalMB >= 3.0 {
            emoji = "🟠"
            status = "DANGER"
        } else if totalMB >= 2.0 {
            emoji = "🟡"
            status = "WARNING"
        } else {
            emoji = "🟢"
            status = "OK"
        }
        
        print("\(emoji) [USERDEFAULTS] Total: \(String(format: "%.2f MB", totalMB)) (\(keyCount) keys) - \(status)")
    }
    
    /// Print inventory of all UserDefaults data with sizes
    static func printInventory() {
        print("\n" + String(repeating: "=", count: 80))
        print("📊 USER DEFAULTS INVENTORY")
        print(String(repeating: "=", count: 80))
        
        let defaults = UserDefaults.standard
        let allKeys = defaults.dictionaryRepresentation().keys.sorted()
        var totalBytes = 0
        var entries: [(key: String, size: Int)] = []
        
        for key in allKeys {
            guard let data = defaults.object(forKey: key) else { continue }
            
            let sizeBytes: Int
            if let data = data as? Data {
                sizeBytes = data.count
            } else {
                // Estimate size by archiving
                if let archived = try? NSKeyedArchiver.archivedData(withRootObject: data, requiringSecureCoding: false) {
                    sizeBytes = archived.count
                } else if let jsonData = try? JSONSerialization.data(withJSONObject: data) {
                    sizeBytes = jsonData.count
                } else {
                    sizeBytes = String(describing: data).count
                }
            }
            
            totalBytes += sizeBytes
            entries.append((key: key, size: sizeBytes))
        }
        
        // Sort by size (largest first)
        entries.sort { $0.size > $1.size }
        
        // Print entries
        for (index, entry) in entries.enumerated() {
            let sizeMB = Double(entry.size) / 1_048_576
            let sizeKB = Double(entry.size) / 1024
            
            let sizeString: String
            if sizeMB >= 1.0 {
                sizeString = String(format: "%.2f MB", sizeMB)
            } else if sizeKB >= 1.0 {
                sizeString = String(format: "%.2f KB", sizeKB)
            } else {
                sizeString = "\(entry.size) bytes"
            }
            
            let emoji: String
            if sizeMB >= 4.0 {
                emoji = "🔴"  // Over limit
            } else if sizeMB >= 2.0 {
                emoji = "🟠"  // Warning
            } else if sizeKB >= 100 {
                emoji = "🟡"  // Medium
            } else {
                emoji = "🟢"  // Small
            }
            
            print("\(emoji) [\(index + 1)] \(entry.key)")
            print("      Size: \(sizeString) (\(entry.size) bytes)")
        }
        
        print(String(repeating: "-", count: 80))
        let totalMB = Double(totalBytes) / 1_048_576
        print("📊 TOTAL: \(String(format: "%.2f MB", totalMB)) (\(totalBytes) bytes)")
        print("📏 Apple Limit: ~4 MB per app")
        
        if totalMB > 4.0 {
            print("🔴 WARNING: Total exceeds Apple's recommended limit!")
            print("   This will cause data corruption and crashes.")
        } else if totalMB > 2.0 {
            print("🟠 WARNING: Approaching Apple's limit.")
        } else {
            print("🟢 Total is within safe limits.")
        }
        
        print(String(repeating: "=", count: 80) + "\n")
    }
    
    // MARK: - Comprehensive Storage Audit Export
    
    /// Generates a comprehensive JSON audit of all UserDefaults storage for a location
    /// Returns the file URL if successful, nil on failure
    static func exportStorageAudit(locationID: String, mapPointStore: MapPointStore) -> URL? {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd-HHmmss"
        let filename = "storage-audit-\(locationID)-\(dateFormatter.string(from: Date())).json"
        
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let outputURL = documentsDir.appendingPathComponent(filename)
        
        var audit: [String: Any] = [:]
        let defaults = UserDefaults.standard
        let prefix = "locations.\(locationID)."
        
        // ===== METADATA =====
        var totalBytes = 0
        let allKeys = defaults.dictionaryRepresentation().keys.filter { $0.hasPrefix(prefix) }.sorted()
        
        for key in allKeys {
            if let data = defaults.data(forKey: key) {
                totalBytes += data.count
            } else if let obj = defaults.object(forKey: key) {
                if let archived = try? NSKeyedArchiver.archivedData(withRootObject: obj, requiringSecureCoding: false) {
                    totalBytes += archived.count
                }
            }
        }
        
        let totalMB = Double(totalBytes) / 1_048_576
        let status: String
        if totalMB >= 4.0 {
            status = "CRITICAL: Over 4MB limit"
        } else if totalMB >= 2.0 {
            status = "WARNING: Approaching limit"
        } else {
            status = "OK: Within safe limits"
        }
        
        audit["metadata"] = [
            "generatedAt": timestamp,
            "locationID": locationID,
            "totalBytes": totalBytes,
            "totalMB": String(format: "%.2f", totalMB),
            "appleLimit": "4 MB",
            "status": status,
            "keyCount": allKeys.count
        ]
        
        // ===== MAP POINTS DEEP INSPECTION =====
        let mapPointsKey = prefix + "MapPoints_v1"
        var mapPointsAudit: [[String: Any]] = []
        var orphanedTriangleVertices: [[String: Any]] = []
        var allSessionIDsInHistory: Set<String> = []
        
        if let data = defaults.data(forKey: mapPointsKey) {
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                if let array = json as? [[String: Any]] {
                    for pointDict in array {
                        var pointAudit: [String: Any] = [:]
                        
                        // Basic properties
                        let id = (pointDict["id"] as? String) ?? "unknown"
                        let idShort = String(id.prefix(8))
                        pointAudit["id"] = id
                        pointAudit["idShort"] = idShort
                        pointAudit["name"] = pointDict["name"] ?? NSNull()
                        pointAudit["x"] = pointDict["x"]
                        pointAudit["y"] = pointDict["y"]
                        pointAudit["createdDate"] = pointDict["createdDate"]
                        pointAudit["isLocked"] = pointDict["isLocked"] ?? true
                        pointAudit["roles"] = pointDict["roles"] ?? []
                        pointAudit["linkedARMarkerID"] = pointDict["linkedARMarkerID"] ?? NSNull()
                        pointAudit["arMarkerID"] = pointDict["arMarkerID"] ?? NSNull()
                        
                        // Triangle memberships
                        let triangleMemberships = (pointDict["triangleMemberships"] as? [String]) ?? []
                        pointAudit["triangleMemberships"] = triangleMemberships
                        pointAudit["triangleMembershipCount"] = triangleMemberships.count
                        
                        // Photo analysis
                        var photoAudit: [String: Any] = [:]
                        let legacyPhotoData = pointDict["locationPhotoData"] as? String
                        let photoFilename = pointDict["photoFilename"] as? String
                        photoAudit["hasLegacyData"] = legacyPhotoData != nil && !(legacyPhotoData?.isEmpty ?? true)
                        photoAudit["legacyDataBytes"] = legacyPhotoData?.utf8.count ?? 0
                        photoAudit["hasFilename"] = photoFilename != nil
                        photoAudit["filename"] = photoFilename ?? NSNull()
                        photoAudit["photoOutdated"] = pointDict["photoOutdated"] ?? NSNull()
                        photoAudit["photoCapturedAtPositionX"] = pointDict["photoCapturedAtPositionX"] ?? NSNull()
                        photoAudit["photoCapturedAtPositionY"] = pointDict["photoCapturedAtPositionY"] ?? NSNull()
                        pointAudit["photo"] = photoAudit
                        
                        // Baked position analysis
                        var bakedAudit: [String: Any] = [:]
                        let bakedArray = pointDict["bakedCanonicalPositionArray"] as? [Double]
                        bakedAudit["exists"] = bakedArray != nil
                        bakedAudit["position"] = bakedArray ?? NSNull()
                        bakedAudit["confidence"] = pointDict["bakedConfidence"] ?? NSNull()
                        bakedAudit["sampleCount"] = pointDict["bakedSampleCount"] ?? 0
                        pointAudit["bakedPosition"] = bakedAudit
                        
                        // Sessions (BLE survey sessions) analysis
                        var sessionsAudit: [String: Any] = [:]
                        let sessions = (pointDict["sessions"] as? [[String: Any]]) ?? []
                        sessionsAudit["count"] = sessions.count
                        
                        var sessionDetails: [[String: Any]] = []
                        var sessionsBytes = 0
                        for session in sessions {
                            if let sessionData = try? JSONSerialization.data(withJSONObject: session) {
                                sessionsBytes += sessionData.count
                            }
                            
                            var sessionDetail: [String: Any] = [:]
                            sessionDetail["sessionID"] = session["sessionID"] ?? "unknown"
                            sessionDetail["duration_s"] = session["duration_s"] ?? 0
                            sessionDetail["facing_deg"] = session["facing_deg"] ?? NSNull()
                            sessionDetail["timingStartISO"] = session["timingStartISO"] ?? NSNull()
                            
                            // Beacon data summary
                            let beacons = (session["beacons"] as? [[String: Any]]) ?? []
                            sessionDetail["beaconCount"] = beacons.count
                            
                            var beaconSummaries: [[String: Any]] = []
                            for beacon in beacons {
                                var beaconSummary: [String: Any] = [:]
                                beaconSummary["uuid"] = beacon["uuid"] ?? "unknown"
                                beaconSummary["major"] = beacon["major"]
                                beaconSummary["minor"] = beacon["minor"]
                                let readings = (beacon["readings"] as? [Any]) ?? []
                                beaconSummary["readingCount"] = readings.count
                                beaconSummaries.append(beaconSummary)
                            }
                            sessionDetail["beacons"] = beaconSummaries
                            
                            sessionDetails.append(sessionDetail)
                        }
                        sessionsAudit["totalBytes"] = sessionsBytes
                        sessionsAudit["details"] = sessionDetails
                        pointAudit["sessions"] = sessionsAudit
                        
                        // AR Position History analysis
                        var historyAudit: [String: Any] = [:]
                        let history = (pointDict["arPositionHistory"] as? [[String: Any]]) ?? []
                        historyAudit["count"] = history.count
                        
                        var historySessionIDs: Set<String> = []
                        var historyDetails: [[String: Any]] = []
                        for record in history {
                            var recordDetail: [String: Any] = [:]
                            let sessionID = (record["sessionID"] as? String) ?? "unknown"
                            recordDetail["sessionID"] = sessionID
                            recordDetail["timestamp"] = record["timestamp"]
                            recordDetail["source"] = record["source"] ?? "unknown"
                            recordDetail["confidenceScore"] = record["confidenceScore"] ?? 0
                            
                            // Position as array
                            if let posDict = record["position"] as? [String: Any] {
                                recordDetail["position"] = [
                                    posDict["x"] ?? 0,
                                    posDict["y"] ?? 0,
                                    posDict["z"] ?? 0
                                ]
                            } else {
                                recordDetail["position"] = NSNull()
                            }
                            
                            historySessionIDs.insert(sessionID)
                            allSessionIDsInHistory.insert(sessionID)
                            historyDetails.append(recordDetail)
                        }
                        historyAudit["uniqueSessionCount"] = historySessionIDs.count
                        historyAudit["sessionIDs"] = Array(historySessionIDs).sorted()
                        historyAudit["records"] = historyDetails
                        pointAudit["positionHistory"] = historyAudit
                        
                        // Calculate total size for this point
                        if let pointData = try? JSONSerialization.data(withJSONObject: pointDict) {
                            pointAudit["totalBytes"] = pointData.count
                        }
                        
                        mapPointsAudit.append(pointAudit)
                    }
                }
            } catch {
                audit["mapPointsError"] = error.localizedDescription
            }
        }
        
        // Get set of valid MapPoint IDs
        let validMapPointIDs = Set(mapPointsAudit.compactMap { $0["id"] as? String })
        
        audit["mapPoints"] = [
            "key": mapPointsKey,
            "count": mapPointsAudit.count,
            "points": mapPointsAudit
        ]
        
        // ===== TRIANGLES DEEP INSPECTION =====
        let trianglesKey = prefix + "triangles_v1"
        var trianglesAudit: [[String: Any]] = []
        
        if let data = defaults.data(forKey: trianglesKey) {
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                if let array = json as? [[String: Any]] {
                    for triDict in array {
                        var triAudit: [String: Any] = [:]
                        
                        let id = (triDict["id"] as? String) ?? "unknown"
                        triAudit["id"] = id
                        triAudit["idShort"] = String(id.prefix(8))
                        
                        let vertexIDs = (triDict["vertexIDs"] as? [String]) ?? []
                        triAudit["vertexIDs"] = vertexIDs
                        triAudit["vertexIDsShort"] = vertexIDs.map { String($0.prefix(8)) }
                        
                        // Validate vertices against existing MapPoints
                        var missingVertices: [String] = []
                        for vertexID in vertexIDs {
                            if !validMapPointIDs.contains(vertexID) {
                                missingVertices.append(String(vertexID.prefix(8)))
                            }
                        }
                        triAudit["vertexValidation"] = [
                            "allValid": missingVertices.isEmpty,
                            "missingVertices": missingVertices
                        ]
                        
                        if !missingVertices.isEmpty {
                            orphanedTriangleVertices.append([
                                "triangleID": id,
                                "triangleIDShort": String(id.prefix(8)),
                                "missingVertexIDs": missingVertices
                            ])
                        }
                        
                        triAudit["isCalibrated"] = triDict["isCalibrated"] ?? false
                        triAudit["calibrationQuality"] = triDict["calibrationQuality"] ?? 0
                        triAudit["lastCalibratedAt"] = triDict["lastCalibratedAt"] ?? NSNull()
                        triAudit["createdAt"] = triDict["createdAt"] ?? NSNull()
                        
                        // AR marker IDs for vertices
                        triAudit["arMarkerIDs"] = triDict["arMarkerIDs"] ?? []
                        
                        // Vertex AR positions
                        triAudit["vertexARPositions"] = triDict["vertexARPositions"] ?? NSNull()
                        
                        trianglesAudit.append(triAudit)
                    }
                }
            } catch {
                audit["trianglesError"] = error.localizedDescription
            }
        }
        
        audit["triangles"] = [
            "key": trianglesKey,
            "count": trianglesAudit.count,
            "triangles": trianglesAudit
        ]
        
        // ===== BEACON LISTS INSPECTION =====
        let beaconListsKey = prefix + "BeaconLists_v1"
        var beaconListsAudit: [[String: Any]] = []
        
        if let data = defaults.data(forKey: beaconListsKey) {
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                if let array = json as? [[String: Any]] {
                    for listDict in array {
                        var listAudit: [String: Any] = [:]
                        listAudit["id"] = listDict["id"]
                        listAudit["name"] = listDict["name"]
                        listAudit["createdAt"] = listDict["createdAt"]
                        
                        let beacons = (listDict["beacons"] as? [[String: Any]]) ?? []
                        listAudit["beaconCount"] = beacons.count
                        
                        var beaconDetails: [[String: Any]] = []
                        for beacon in beacons {
                            beaconDetails.append([
                                "uuid": beacon["uuid"] ?? "unknown",
                                "major": beacon["major"] ?? 0,
                                "minor": beacon["minor"] ?? 0,
                                "name": beacon["name"] ?? NSNull()
                            ])
                        }
                        listAudit["beacons"] = beaconDetails
                        
                        beaconListsAudit.append(listAudit)
                    }
                }
            } catch {
                audit["beaconListsError"] = error.localizedDescription
            }
        }
        
        audit["beaconLists"] = [
            "key": beaconListsKey,
            "count": beaconListsAudit.count,
            "lists": beaconListsAudit
        ]
        
        // ===== OTHER KEYS IN THIS LOCATION =====
        var otherKeys: [[String: Any]] = []
        let knownKeys = [mapPointsKey, trianglesKey, beaconListsKey]
        
        for key in allKeys where !knownKeys.contains(key) {
            var keyAudit: [String: Any] = [:]
            keyAudit["key"] = key
            keyAudit["keyShort"] = String(key.replacingOccurrences(of: prefix, with: ""))
            
            if let data = defaults.data(forKey: key) {
                keyAudit["sizeBytes"] = data.count
                keyAudit["type"] = "Data"
                
                // Try to peek at structure
                if let json = try? JSONSerialization.jsonObject(with: data, options: []) {
                    if let array = json as? [Any] {
                        keyAudit["structure"] = "Array[\(array.count)]"
                    } else if let dict = json as? [String: Any] {
                        keyAudit["structure"] = "Object with keys: \(dict.keys.sorted().joined(separator: ", "))"
                    }
                }
            } else if let obj = defaults.object(forKey: key) {
                keyAudit["type"] = String(describing: type(of: obj))
                keyAudit["value"] = String(describing: obj).prefix(200)
            }
            
            otherKeys.append(keyAudit)
        }
        
        audit["otherKeys"] = otherKeys
        
        // ===== ORPHAN ANALYSIS =====
        var orphanAnalysis: [String: Any] = [:]
        
        orphanAnalysis["trianglesWithMissingVertices"] = [
            "count": orphanedTriangleVertices.count,
            "details": orphanedTriangleVertices
        ]
        
        // Summary
        let totalMapPoints = mapPointsAudit.count
        let pointsWithHistory = mapPointsAudit.filter { 
            (($0["positionHistory"] as? [String: Any])?["count"] as? Int ?? 0) > 0 
        }.count
        let totalPositionRecords = mapPointsAudit.reduce(0) { 
            $0 + (($1["positionHistory"] as? [String: Any])?["count"] as? Int ?? 0) 
        }
        let totalSessions = mapPointsAudit.reduce(0) { 
            $0 + (($1["sessions"] as? [String: Any])?["count"] as? Int ?? 0) 
        }
        let legacyPhotoCount = mapPointsAudit.filter {
            (($0["photo"] as? [String: Any])?["hasLegacyData"] as? Bool) == true
        }.count
        let legacyPhotoBytes = mapPointsAudit.reduce(0) {
            $0 + (($1["photo"] as? [String: Any])?["legacyDataBytes"] as? Int ?? 0)
        }
        
        audit["summary"] = [
            "mapPoints": [
                "total": totalMapPoints,
                "withPositionHistory": pointsWithHistory,
                "totalPositionRecords": totalPositionRecords,
                "uniqueSessionsInHistory": allSessionIDsInHistory.count,
                "totalBLESessions": totalSessions,
                "legacyPhotos": legacyPhotoCount,
                "legacyPhotoBytes": legacyPhotoBytes,
                "legacyPhotoMB": String(format: "%.2f", Double(legacyPhotoBytes) / 1_048_576)
            ],
            "triangles": [
                "total": trianglesAudit.count,
                "withMissingVertices": orphanedTriangleVertices.count
            ],
            "beaconLists": [
                "total": beaconListsAudit.count
            ]
        ]
        
        orphanAnalysis["summary"] = [
            "orphanedTriangleCount": orphanedTriangleVertices.count,
            "recommendation": orphanedTriangleVertices.isEmpty ? 
                "No orphaned triangles found" : 
                "Found \(orphanedTriangleVertices.count) triangle(s) with missing vertices - consider deletion"
        ]
        
        audit["orphanAnalysis"] = orphanAnalysis
        
        // ===== WRITE TO FILE =====
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: audit, options: [.prettyPrinted, .sortedKeys])
            try jsonData.write(to: outputURL, options: .atomic)
            
            print("✅ Storage audit exported to: \(outputURL.path)")
            print("   Size: \(String(format: "%.2f KB", Double(jsonData.count) / 1024))")
            
            return outputURL
        } catch {
            print("❌ Failed to export storage audit: \(error)")
            return nil
        }
    }
    
    /// Export complete raw UserDefaults dump - no interpretation, just the data as-is
    /// Returns the file URL if successful, nil on failure
    static func exportRawUserDefaults() -> URL? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd-HHmmss"
        let filename = "userdefaults-raw-\(dateFormatter.string(from: Date())).json"
        
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let outputURL = documentsDir.appendingPathComponent(filename)
        
        let defaults = UserDefaults.standard
        let allData = defaults.dictionaryRepresentation()
        
        var output: [String: Any] = [:]
        var totalBytes = 0
        var keyDetails: [[String: Any]] = []
        
        // Sort keys for consistent output
        let sortedKeys = allData.keys.sorted()
        
        for key in sortedKeys {
            guard let value = allData[key] else { continue }
            
            var keyInfo: [String: Any] = [
                "key": key
            ]
            
            // Determine size
            let sizeBytes: Int
            if let data = value as? Data {
                sizeBytes = data.count
            } else if let archived = try? NSKeyedArchiver.archivedData(withRootObject: value, requiringSecureCoding: false) {
                sizeBytes = archived.count
            } else {
                sizeBytes = String(describing: value).utf8.count
            }
            totalBytes += sizeBytes
            keyInfo["sizeBytes"] = sizeBytes
            keyInfo["type"] = String(describing: type(of: value))
            
            // Extract the actual value
            if let data = value as? Data {
                // Try to decode as JSON
                if let json = try? JSONSerialization.jsonObject(with: data, options: []) {
                    keyInfo["value"] = json
                    keyInfo["encoding"] = "json"
                } else {
                    // Store as base64 for binary data
                    keyInfo["value"] = data.base64EncodedString()
                    keyInfo["encoding"] = "base64"
                }
            } else if let string = value as? String {
                keyInfo["value"] = string
            } else if let number = value as? NSNumber {
                keyInfo["value"] = number
            } else if let bool = value as? Bool {
                keyInfo["value"] = bool
            } else if let date = value as? Date {
                keyInfo["value"] = ISO8601DateFormatter().string(from: date)
                keyInfo["encoding"] = "iso8601"
            } else if let array = value as? [Any] {
                // Try to make it JSON-serializable
                if JSONSerialization.isValidJSONObject(array) {
                    keyInfo["value"] = array
                } else {
                    keyInfo["value"] = String(describing: array)
                    keyInfo["encoding"] = "description"
                }
            } else if let dict = value as? [String: Any] {
                if JSONSerialization.isValidJSONObject(dict) {
                    keyInfo["value"] = dict
                } else {
                    keyInfo["value"] = String(describing: dict)
                    keyInfo["encoding"] = "description"
                }
            } else {
                // Fallback: string description
                keyInfo["value"] = String(describing: value)
                keyInfo["encoding"] = "description"
            }
            
            keyDetails.append(keyInfo)
        }
        
        // Build output
        let totalMB = Double(totalBytes) / 1_048_576
        output["metadata"] = [
            "generatedAt": ISO8601DateFormatter().string(from: Date()),
            "totalBytes": totalBytes,
            "totalMB": String(format: "%.2f", totalMB),
            "keyCount": keyDetails.count,
            "appleLimit": "4 MB",
            "status": totalMB >= 4.0 ? "OVER LIMIT" : (totalMB >= 2.0 ? "WARNING" : "OK")
        ]
        
        // Group by prefix for easier reading
        var byPrefix: [String: [[String: Any]]] = [:]
        for detail in keyDetails {
            let key = detail["key"] as? String ?? ""
            let prefix: String
            if key.hasPrefix("locations.") {
                // Extract location ID: locations.home.xxx -> locations.home
                let parts = key.split(separator: ".")
                if parts.count >= 2 {
                    prefix = "locations.\(parts[1])"
                } else {
                    prefix = "locations"
                }
            } else if key.contains(".") {
                prefix = String(key.split(separator: ".").first ?? Substring(key))
            } else {
                prefix = "_root"
            }
            byPrefix[prefix, default: []].append(detail)
        }
        
        output["byPrefix"] = byPrefix
        output["allKeys"] = keyDetails
        
        // Write to file
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: output, options: [.prettyPrinted, .sortedKeys])
            try jsonData.write(to: outputURL, options: .atomic)
            
            print("✅ Raw UserDefaults exported to: \(outputURL.path)")
            print("   Size: \(String(format: "%.2f KB", Double(jsonData.count) / 1024))")
            print("   Total UserDefaults: \(String(format: "%.2f MB", totalMB)) (\(keyDetails.count) keys)")
            
            return outputURL
        } catch {
            print("❌ Failed to export raw UserDefaults: \(error)")
            return nil
        }
    }
    
    /// Identify keys that contain heavy data (images, ARWorldMaps, etc.)
    static func identifyHeavyData() -> [String: Int] {
        print("\n" + String(repeating: "=", count: 80))
        print("🔍 IDENTIFYING HEAVY DATA IN USER DEFAULTS")
        print(String(repeating: "=", count: 80))
        
        let defaults = UserDefaults.standard
        var heavyKeys: [String: Int] = [:]
        let threshold = 100_000  // 100 KB threshold
        
        for key in defaults.dictionaryRepresentation().keys {
            guard let data = defaults.object(forKey: key) else { continue }
            
            let sizeBytes: Int
            if let data = data as? Data {
                sizeBytes = data.count
            } else if let archived = try? NSKeyedArchiver.archivedData(withRootObject: data, requiringSecureCoding: false) {
                sizeBytes = archived.count
            } else if let jsonData = try? JSONSerialization.data(withJSONObject: data) {
                sizeBytes = jsonData.count
            } else {
                continue
            }
            
            if sizeBytes > threshold {
                heavyKeys[key] = sizeBytes
                let sizeMB = Double(sizeBytes) / 1_048_576
                print("🔴 \(key): \(String(format: "%.2f MB", sizeMB))")
                
                // Try to identify what type of data this is
                if key.contains("MapPoints") {
                    print("   → Likely contains: Map point coordinates, sessions, photos")
                } else if key.contains("ARWorldMap") || key.contains("worldMap") {
                    print("   → Likely contains: ARWorldMap binary data")
                } else if key.contains("image") || key.contains("photo") {
                    print("   → Likely contains: Image data")
                } else if key.contains("anchor") {
                    print("   → Likely contains: AR anchor data")
                }
            }
        }
        
        if heavyKeys.isEmpty {
            print("✅ No heavy data found (all keys < 100 KB)")
        }
        
        print(String(repeating: "=", count: 80) + "\n")
        return heavyKeys
    }
    
    /// Inspect the actual structure of MapPoints data without making assumptions
    static func inspectMapPointStructure(locationID: String) {
        print("\n" + String(repeating: "=", count: 80))
        print("🔍 MAPPOINT STRUCTURE INSPECTION: '\(locationID)'")
        print(String(repeating: "=", count: 80))
        
        let key = "locations.\(locationID).MapPoints_v1"
        let defaults = UserDefaults.standard
        
        guard let data = defaults.data(forKey: key) else {
            print("❌ No MapPoints data found for key: \(key)")
            print(String(repeating: "=", count: 80) + "\n")
            return
        }
        
        let totalBytes = data.count
        let totalMB = Double(totalBytes) / 1_048_576
        print("📊 Total data: \(String(format: "%.2f MB", totalMB)) (\(totalBytes) bytes)")
        print("")
        
        // Parse as generic JSON to see actual structure
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            
            guard let array = json as? [[String: Any]] else {
                print("❌ Data is not an array of objects, type: \(type(of: json))")
                print(String(repeating: "=", count: 80) + "\n")
                return
            }
            
            print("✅ Data is an array of \(array.count) objects")
            print("")
            
            // Get ALL unique keys across all points
            var allKeys = Set<String>()
            for point in array {
                allKeys.formUnion(point.keys)
            }
            let sortedKeys = allKeys.sorted()
            
            print("📋 ALL FIELDS FOUND:")
            print("   \(sortedKeys.joined(separator: ", "))")
            print("")
            
            // Now analyze each field's SIZE across all points
            print("📊 FIELD SIZE ANALYSIS:")
            print("")
            
            var fieldSizes: [String: Int] = [:]
            for key in sortedKeys {
                var totalSize = 0
                var nonEmptyCount = 0
                
                for point in array {
                    guard let value = point[key] else { continue }
                    
                    // Estimate size of this field's value
                    let valueSize: Int
                    if let dataValue = value as? Data {
                        valueSize = dataValue.count
                    } else if let stringValue = value as? String {
                        valueSize = stringValue.utf8.count
                    } else if let arrayValue = value as? [Any] {
                        // Estimate array size
                        if let jsonData = try? JSONSerialization.data(withJSONObject: arrayValue) {
                            valueSize = jsonData.count
                        } else {
                            valueSize = 100 * arrayValue.count // rough estimate
                        }
                    } else if let dictValue = value as? [String: Any] {
                        // Estimate dict size
                        if let jsonData = try? JSONSerialization.data(withJSONObject: dictValue) {
                            valueSize = jsonData.count
                        } else {
                            valueSize = 100 * dictValue.keys.count // rough estimate
                        }
                    } else {
                        valueSize = String(describing: value).utf8.count
                    }
                    
                    totalSize += valueSize
                    if valueSize > 0 {
                        nonEmptyCount += 1
                    }
                }
                
                fieldSizes[key] = totalSize
                
                let sizeMB = Double(totalSize) / 1_048_576
                let sizeKB = Double(totalSize) / 1024
                let sizeStr = sizeMB >= 1.0 ? String(format: "%.2f MB", sizeMB) : String(format: "%.2f KB", sizeKB)
                let percent = (Double(totalSize) / Double(totalBytes)) * 100
                
                let emoji = sizeMB >= 1.0 ? "🔴" : (sizeKB >= 100 ? "🟡" : "🟢")
                
                print("  \(emoji) \(key): \(sizeStr) (\(String(format: "%.1f%%", percent))) - \(nonEmptyCount) points")
            }
            
            // Find the biggest offender
            if let biggestField = fieldSizes.max(by: { $0.value < $1.value }) {
                print("")
                print("🔥 BIGGEST FIELD: '\(biggestField.key)' = \(String(format: "%.2f MB", Double(biggestField.value) / 1_048_576))")
                print("")
                
                // Show details of this field for first 10 points
                print("📸 EXAMINING '\(biggestField.key)' IN DETAIL:")
                print("")
                
                for (index, point) in array.enumerated() {
                    guard let value = point[biggestField.key] else {
                        print("  [\(index + 1)] (nil)")
                        continue
                    }
                    
                    let name = (point["name"] as? String) ?? "Unnamed"
                    let id = (point["id"] as? String) ?? "unknown"
                    let idShort = String(id.prefix(8))
                    
                    if let dataValue = value as? Data {
                        let sizeMB = Double(dataValue.count) / 1_048_576
                        let sizeKB = Double(dataValue.count) / 1024
                        let sizeStr = sizeMB >= 1.0 ? String(format: "%.2f MB", sizeMB) : String(format: "%.2f KB", sizeKB)
                        print("  [\(index + 1)] 📷 \(name) (\(idShort)): \(sizeStr)")
                    } else if let stringValue = value as? String {
                        let sizeKB = Double(stringValue.utf8.count) / 1024
                        let preview = stringValue.count > 50 ? String(stringValue.prefix(50)) + "..." : stringValue
                        print("  [\(index + 1)] 📝 \(name) (\(idShort)): \(String(format: "%.2f KB", sizeKB)) - \"\(preview)\"")
                    } else if let arrayValue = value as? [Any] {
                        if let jsonData = try? JSONSerialization.data(withJSONObject: arrayValue) {
                            let sizeKB = Double(jsonData.count) / 1024
                            print("  [\(index + 1)] 📦 \(name) (\(idShort)): \(arrayValue.count) items, \(String(format: "%.2f KB", sizeKB))")
                        } else {
                            print("  [\(index + 1)] 📦 \(name) (\(idShort)): \(arrayValue.count) items")
                        }
                    } else {
                        print("  [\(index + 1)] ❓ \(name) (\(idShort)): \(type(of: value))")
                    }
                }
            }
            
        } catch {
            print("❌ Failed to parse as JSON: \(error)")
        }
        
        print("")
        print(String(repeating: "=", count: 80) + "\n")
    }
    
    /// Extract all photos from MapPoints with metadata
    static func extractPhotos(locationID: String) -> [(index: Int, id: String, base64: String, sizeKB: Double)] {
        let key = "locations.\(locationID).MapPoints_v1"
        let defaults = UserDefaults.standard
        
        guard let data = defaults.data(forKey: key) else { return [] }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            guard let array = json as? [[String: Any]] else { return [] }
            
            var photos: [(index: Int, id: String, base64: String, sizeKB: Double)] = []
            
            for (index, point) in array.enumerated() {
                guard let photoData = point["locationPhotoData"] as? String,
                      !photoData.isEmpty,
                      let id = point["id"] as? String else {
                    continue
                }
                
                let sizeKB = Double(photoData.utf8.count) / 1024
                photos.append((index: index, id: id, base64: photoData, sizeKB: sizeKB))
            }
            
            return photos
            
        } catch {
            print("❌ Failed to extract photos: \(error)")
            return []
        }
    }
    
    /// Launch photo management interface
    static func launchPhotoManager(locationID: String) {
        NotificationCenter.default.post(
            name: NSNotification.Name("LaunchPhotoManager"),
            object: nil,
            userInfo: ["locationID": locationID]
        )
    }
    
    /// Purge photos from UserDefaults after they've been saved to disk
    static func purgePhotosFromUserDefaults(locationID: String, confirmedFilesSaved: [String]) {
        print("\n" + String(repeating: "=", count: 80))
        print("🗑️ PURGING PHOTOS FROM USER DEFAULTS")
        print(String(repeating: "=", count: 80))
        
        let key = "locations.\(locationID).MapPoints_v1"
        let defaults = UserDefaults.standard
        
        guard let data = defaults.data(forKey: key) else {
            print("❌ No MapPoints data found")
            print(String(repeating: "=", count: 80) + "\n")
            return
        }
        
        let originalSize = Double(data.count) / 1_048_576
        print("📊 Original size: \(String(format: "%.2f MB", originalSize))")
        print("📸 Confirmed files saved: \(confirmedFilesSaved.count)")
        print("")
        
        do {
            var json = try JSONSerialization.jsonObject(with: data, options: [])
            guard var array = json as? [[String: Any]] else {
                print("❌ Invalid data format")
                return
            }
            
            var purgedCount = 0
            var totalPurgedBytes = 0
            
            for index in array.indices {
                var point = array[index]
                guard let id = point["id"] as? String else { continue }
                let idShort = String(id.prefix(8))
                
                // Check if this photo was saved to disk
                if confirmedFilesSaved.contains(idShort) {
                    if let photoData = point["locationPhotoData"] as? String, !photoData.isEmpty {
                        let photoBytes = photoData.utf8.count
                        totalPurgedBytes += photoBytes
                        
                        // Remove the photo data, set filename
                        point["locationPhotoData"] = nil
                        point["photoFilename"] = "\(idShort).jpg"
                        array[index] = point
                        
                        let photoKB = Double(photoBytes) / 1024
                        print("  🗑️ Purged photo from \(idShort): \(String(format: "%.2f KB", photoKB))")
                        purgedCount += 1
                    }
                }
            }
            
            // Save back to UserDefaults
            let newData = try JSONSerialization.data(withJSONObject: array)
            defaults.set(newData, forKey: key)
            defaults.synchronize()
            
            let newSize = Double(newData.count) / 1_048_576
            let savedMB = originalSize - newSize
            
            print("")
            print(String(repeating: "-", count: 80))
            print("✅ Purge complete!")
            print("   Photos purged: \(purgedCount)")
            print("   Original: \(String(format: "%.2f MB", originalSize))")
            print("   New size: \(String(format: "%.2f MB", newSize))")
            print("   Saved: \(String(format: "%.2f MB", savedMB)) (\(String(format: "%.1f%%", (savedMB/originalSize)*100)))")
            
        } catch {
            print("❌ Failed to purge photos: \(error)")
        }
        
        print(String(repeating: "=", count: 80) + "\n")
    }
    
    /// Generate migration plan for moving photos to disk
    static func generatePhotoMigrationPlan() {
        print("\n" + String(repeating: "=", count: 80))
        print("📋 PHOTO MIGRATION PLAN")
        print(String(repeating: "=", count: 80))
        print("")
        print("GOAL: Move embedded photo data from UserDefaults to disk")
        print("")
        print("CURRENT STATE:")
        print("  • Photos stored as Data? in MapPoint.locationPhotoData")
        print("  • Embedded directly in UserDefaults (causing 12MB+ bloat)")
        print("")
        print("TARGET STATE:")
        print("  • Photos stored in: /Documents/locations/{locationID}/map-points/{uuid}.jpg")
        print("  • MapPoint has: photoFilename: String? (just the filename)")
        print("  • UserDefaults contains only small references")
        print("")
        print("MIGRATION STEPS:")
        print("  1️⃣ Create disk storage directory structure")
        print("  2️⃣ For each MapPoint with locationPhotoData:")
        print("     - Write photo to disk as {uuid}.jpg")
        print("     - Replace locationPhotoData with photoFilename")
        print("  3️⃣ Update MapPointStore to load/save from disk")
        print("  4️⃣ Update all photo access code to use file paths")
        print("")
        print("ESTIMATED IMPACT:")
        print("  • UserDefaults: 13MB → ~500KB (96% reduction)")
        print("  • Disk usage: +12MB in Documents (backed up to iCloud)")
        print("  • Photo access: Slightly slower (disk read vs memory)")
        print("")
        print("SAFETY:")
        print("  • Keep original data until migration confirmed")
        print("  • Add schema version to detect migration state")
        print("  • Implement lazy migration (migrate on first load)")
        print("")
        print(String(repeating: "=", count: 80) + "\n")
    }
    
    /// Dangerous: Remove specific keys from UserDefaults
    static func removeKeys(_ keys: [String], dryRun: Bool = true) {
        print("\n" + String(repeating: "=", count: 80))
        if dryRun {
            print("🔍 DRY RUN: Keys that WOULD be deleted:")
        } else {
            print("🗑️ DELETING KEYS FROM USER DEFAULTS")
        }
        print(String(repeating: "=", count: 80))
        
        let defaults = UserDefaults.standard
        var totalFreed = 0
        
        for key in keys {
            guard let data = defaults.object(forKey: key) else {
                print("⚠️ Key not found: \(key)")
                continue
            }
            
            let sizeBytes: Int
            if let data = data as? Data {
                sizeBytes = data.count
            } else if let archived = try? NSKeyedArchiver.archivedData(withRootObject: data, requiringSecureCoding: false) {
                sizeBytes = archived.count
            } else {
                sizeBytes = 0
            }
            
            totalFreed += sizeBytes
            let sizeMB = Double(sizeBytes) / 1_048_576
            
            if dryRun {
                print("  Would delete: \(key) (\(String(format: "%.2f MB", sizeMB)))")
            } else {
                defaults.removeObject(forKey: key)
                defaults.synchronize()
                print("  ✅ Deleted: \(key) (\(String(format: "%.2f MB", sizeMB)))")
            }
        }
        
        let totalMB = Double(totalFreed) / 1_048_576
        if dryRun {
            print("\n📊 Would free: \(String(format: "%.2f MB", totalMB))")
            print("ℹ️ This is a DRY RUN. No data was actually deleted.")
            print("ℹ️ Call removeKeys(_:dryRun: false) to actually delete.")
        } else {
            print("\n📊 Freed: \(String(format: "%.2f MB", totalMB))")
            print("✅ Deletion complete.")
        }
        
        print(String(repeating: "=", count: 80) + "\n")
    }
    
    /// Inspect triangle patch persistence for a given location
    static func inspectTriangles(locationID: String) {
        print("\n" + String(repeating: "=", count: 80))
        print("🔺 TRIANGLE PATCH INSPECTION: '\(locationID)'")
        print(String(repeating: "=", count: 80))
        
        let key = "locations.\(locationID).triangles_v1"
        let defaults = UserDefaults.standard
        
        guard let data = defaults.data(forKey: key) else {
            print("❌ No triangles found for key: \(key)")
            print("   Current locationID: \(PersistenceContext.shared.locationID)")
            print(String(repeating: "=", count: 80) + "\n")
            return
        }
        
        let sizeKB = Double(data.count) / 1024
        print("✅ Found triangles data: \(String(format: "%.2f KB", sizeKB)) (\(data.count) bytes)")
        print("")
        
        // Try to decode
        do {
            // Use default decoder (TrianglePatch has custom decoder that handles both ISO8601 and timestamp)
            let decoder = JSONDecoder()
            // Don't set dateDecodingStrategy - TrianglePatch custom decoder handles both formats
            
            let triangles = try decoder.decode([TrianglePatch].self, from: data)
            print("✅ Successfully decoded \(triangles.count) triangle(s)")
            print("")
            
            for (idx, tri) in triangles.enumerated() {
                let triID = String(tri.id.uuidString.prefix(8))
                let vertexIDs = tri.vertexIDs.map { String($0.uuidString.prefix(8)) }
                
                print("  [\(idx+1)] Triangle \(triID)")
                print("      Vertices: \(vertexIDs.joined(separator: ", "))")
                print("      Calibrated: \(tri.isCalibrated ? "✅" : "❌")")
                
                if let calibratedAt = tri.lastCalibratedAt {
                    print("      Last calibrated: \(calibratedAt)")
                }
                
                // calibrationQuality is non-optional, so print it directly
                print("      Quality: \(String(format: "%.2f", tri.calibrationQuality))")
                
                print("")
            }
            
            print(String(repeating: "-", count: 80))
            print("📊 SUMMARY:")
            print("   Total triangles: \(triangles.count)")
            print("   Calibrated: \(triangles.filter { $0.isCalibrated }.count)")
            print("   Uncalibrated: \(triangles.filter { !$0.isCalibrated }.count)")
            
        } catch {
            print("❌ Failed to decode triangles: \(error)")
            print("   Error details: \(error.localizedDescription)")
            
            // Try to see raw structure
            if let json = try? JSONSerialization.jsonObject(with: data) {
                print("   Raw JSON type: \(type(of: json))")
                if let array = json as? [Any] {
                    print("   Array count: \(array.count)")
                    if let first = array.first {
                        print("   First item type: \(type(of: first))")
                        if let dict = first as? [String: Any] {
                            print("   First item keys: \(dict.keys.sorted().joined(separator: ", "))")
                        }
                    }
                }
            }
        }
        
        print(String(repeating: "=", count: 80) + "\n")
    }
    
    /// Check if triangle vertex IDs match existing MapPoints
    static func validateTriangleVertices(locationID: String, mapPointStore: MapPointStore) {
        print("\n" + String(repeating: "=", count: 80))
        print("🔍 TRIANGLE VERTEX VALIDATION: '\(locationID)'")
        print(String(repeating: "=", count: 80))
        
        let key = "locations.\(locationID).triangles_v1"
        let defaults = UserDefaults.standard
        
        guard let data = defaults.data(forKey: key) else {
            print("❌ No triangles found")
            print(String(repeating: "=", count: 80) + "\n")
            return
        }
        
        do {
            // Use default decoder (TrianglePatch has custom decoder that handles both ISO8601 and timestamp)
            let decoder = JSONDecoder()
            // Don't set dateDecodingStrategy - TrianglePatch custom decoder handles both formats
            let triangles = try decoder.decode([TrianglePatch].self, from: data)
            
            print("📊 Validating \(triangles.count) triangle(s) against \(mapPointStore.points.count) MapPoint(s)")
            print("")
            
            var validCount = 0
            var invalidCount = 0
            
            for (idx, tri) in triangles.enumerated() {
                let triID = String(tri.id.uuidString.prefix(8))
                var allValid = true
                var missingVertices: [String] = []
                
                for vertexID in tri.vertexIDs {
                    if mapPointStore.points.first(where: { $0.id == vertexID }) == nil {
                        allValid = false
                        missingVertices.append(String(vertexID.uuidString.prefix(8)))
                    }
                }
                
                if allValid {
                    validCount += 1
                    print("  ✅ [\(idx+1)] Triangle \(triID): All vertices valid")
                } else {
                    invalidCount += 1
                    print("  ❌ [\(idx+1)] Triangle \(triID): Missing vertices \(missingVertices.joined(separator: ", "))")
                }
            }
            
            print("")
            print(String(repeating: "-", count: 80))
            print("📊 VALIDATION RESULTS:")
            print("   Valid triangles: \(validCount)")
            print("   Invalid triangles: \(invalidCount)")
            
            if invalidCount > 0 {
                print("")
                print("⚠️ WARNING: Some triangles reference MapPoints that don't exist")
                print("   These triangles won't render until MapPoints are created")
            }
            
        } catch {
            print("❌ Failed to decode triangles: \(error)")
        }
        
        print(String(repeating: "=", count: 80) + "\n")
    }
    
    /// Delete triangles with invalid vertex IDs (malformed triangles)
    /// Returns: (deletedCount: Int, remainingCount: Int)
    static func deleteMalformedTriangles(locationID: String, mapPointStore: MapPointStore) -> (deletedCount: Int, remainingCount: Int) {
        print("\n" + String(repeating: "=", count: 80))
        print("🗑️ DELETING MALFORMED TRIANGLES: '\(locationID)'")
        print(String(repeating: "=", count: 80))
        
        let key = "locations.\(locationID).triangles_v1"
        let defaults = UserDefaults.standard
        
        guard let data = defaults.data(forKey: key) else {
            print("❌ No triangles found")
            print(String(repeating: "=", count: 80) + "\n")
            return (deletedCount: 0, remainingCount: 0)
        }
        
        do {
            // Use default decoder (TrianglePatch has custom decoder that handles both ISO8601 and timestamp)
            let decoder = JSONDecoder()
            // Don't set dateDecodingStrategy - TrianglePatch custom decoder handles both formats
            var triangles = try decoder.decode([TrianglePatch].self, from: data)
            
            let originalCount = triangles.count
            print("📊 Starting with \(originalCount) triangle(s)")
            print("   Validating against \(mapPointStore.points.count) MapPoint(s)")
            print("")
            
            // Identify malformed triangles (those with invalid vertex IDs)
            var malformedTriangles: [TrianglePatch] = []
            var validTriangles: [TrianglePatch] = []
            
            for tri in triangles {
                var isMalformed = false
                var missingVertices: [String] = []
                
                // Check all three vertices
                for vertexID in tri.vertexIDs {
                    if mapPointStore.points.first(where: { $0.id == vertexID }) == nil {
                        isMalformed = true
                        missingVertices.append(String(vertexID.uuidString.prefix(8)))
                    }
                }
                
                if isMalformed {
                    malformedTriangles.append(tri)
                    let triID = String(tri.id.uuidString.prefix(8))
                    print("  ❌ [DELETE] Triangle \(triID): Missing vertices \(missingVertices.joined(separator: ", "))")
                } else {
                    validTriangles.append(tri)
                }
            }
            
            if malformedTriangles.isEmpty {
                print("")
                print("✅ No malformed triangles found — all triangles are valid")
                print(String(repeating: "=", count: 80) + "\n")
                return (deletedCount: 0, remainingCount: originalCount)
            }
            
            // Save only valid triangles back to UserDefaults
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let validData = try encoder.encode(validTriangles)
            defaults.set(validData, forKey: key)
            defaults.synchronize()
            
            print("")
            print(String(repeating: "-", count: 80))
            print("📊 DELETION RESULTS:")
            print("   Deleted: \(malformedTriangles.count) malformed triangle(s)")
            print("   Remaining: \(validTriangles.count) valid triangle(s)")
            print("")
            print("✅ Updated triangles saved to UserDefaults")
            print(String(repeating: "=", count: 80) + "\n")
            
            return (deletedCount: malformedTriangles.count, remainingCount: validTriangles.count)
            
        } catch {
            print("❌ Failed to process triangles: \(error)")
            print(String(repeating: "=", count: 80) + "\n")
            return (deletedCount: 0, remainingCount: 0)
        }
    }
    
    static func nukeAllData(confirmation: String) {
        guard confirmation == "I understand this will delete everything" else {
            print("❌ Confirmation string incorrect. No data deleted.")
            print("   Use: nukeAllData(confirmation: \"I understand this will delete everything\")")
            return
        }
        
        print("\n" + String(repeating: "=", count: 80))
        print("☢️ NUCLEAR OPTION: DELETING ALL USER DEFAULTS")
        print(String(repeating: "=", count: 80))
        
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
        
        for key in dictionary.keys {
            defaults.removeObject(forKey: key)
        }
        
        defaults.synchronize()
        
        print("☢️ All UserDefaults data has been deleted.")
        print("   App will need to be restarted.")
        print(String(repeating: "=", count: 80) + "\n")
    }
}

