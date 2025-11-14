//
//  UserDefaultsDiagnostics.swift
//  TapResolver
//
//  Diagnostic tools for UserDefaults inspection and cleanup
//

import Foundation
import SwiftUI

struct UserDefaultsDiagnostics {
    
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

