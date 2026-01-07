//
//  UserDataBackup.swift
//  TapResolver
//
//  Created by Chris Gelles on 10/23/25.
//


//
//  UserDataBackup.swift
//  TapResolver
//
//  Backup and restore UserDefaults + location files to/from ZIP archives
//

import Foundation
import ZIPFoundation

enum UserDataBackup {
    
    /// Backup selected locations to a .tapmap file
    /// - Parameters:
    ///   - locationIDs: Array of location IDs to backup
    ///   - includeAssets: Whether to include map images (large files)
    /// - Returns: URL to the created .tapmap file in temp directory
    static func backupLocations(locationIDs: [String], includeAssets: Bool) throws -> URL {
        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: "T", with: "_")
            .prefix(19) // YYYY-MM-DD_HHmmss
        
        let zipFileName = "TapResolver_Backup_\(timestamp).tapmap"  // Temp name, final name set by user
        let tempDir = FileManager.default.temporaryDirectory
        let zipURL = tempDir.appendingPathComponent(zipFileName)
        
        // Remove existing file if present
        try? FileManager.default.removeItem(at: zipURL)
        
        // Create ZIP archive
        guard let archive = Archive(url: zipURL, accessMode: .create) else {
            throw BackupError.archiveCreationFailed
        }
        
        print("\n" + String(repeating: "=", count: 80))
        print("💾 BACKUP: Creating backup archive")
        print(String(repeating: "=", count: 80))
        print("Locations: \(locationIDs.joined(separator: ", "))")
        print("Include assets: \(includeAssets)")
        
        for locationID in locationIDs {
            try backupLocation(locationID: locationID, includeAssets: includeAssets, to: archive)
        }
        
        // Add metadata.json at root of archive
        try addBackupMetadata(locationIDs: locationIDs, includeAssets: includeAssets, to: archive)
        
        print("\n✅ BACKUP COMPLETE")
        print("   File: \(zipFileName)")
        print("   Size: \(formattedFileSize(zipURL))")
        print(String(repeating: "=", count: 80) + "\n")
        
        return zipURL
    }
    
    /// Restore selected locations from a ZIP backup
    /// - Parameters:
    ///   - zipURL: URL to the backup ZIP file
    ///   - targetLocationIDs: Location IDs to restore (overwrites these)
    static func restoreLocations(from zipURL: URL, targetLocationIDs: [String]) throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        print("\n" + String(repeating: "=", count: 80))
        print("📂 RESTORE: Extracting backup archive")
        print(String(repeating: "=", count: 80))
        print("Source: \(zipURL.lastPathComponent)")
        print("Target locations: \(targetLocationIDs.joined(separator: ", "))")
        
        // Extract ZIP
        guard let archive = Archive(url: zipURL, accessMode: .read) else {
            throw BackupError.archiveReadFailed
        }
        
        // Extract all entries
        for entry in archive {
            let destinationURL = tempDir.appendingPathComponent(entry.path)
            // Create intermediate directories if needed
            if entry.type == .directory {
                try FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true)
            } else {
                let parentDir = destinationURL.deletingLastPathComponent()
                try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)
                _ = try archive.extract(entry, to: destinationURL)
            }
        }
        
        // Restore each location
        for locationID in targetLocationIDs {
            let extractedLocationDir = tempDir.appendingPathComponent(locationID)
            
            guard FileManager.default.fileExists(atPath: extractedLocationDir.path) else {
                print("⚠️ Location '\(locationID)' not found in backup, skipping")
                continue
            }
            
            try restoreLocation(locationID: locationID, from: extractedLocationDir)
        }
        
        // Trigger reload of all stores
        NotificationCenter.default.post(name: .locationDidChange, object: nil)
        
        print("\n✅ RESTORE COMPLETE")
        print("   Restored \(targetLocationIDs.count) location(s)")
        print("   All stores reloaded")
        print(String(repeating: "=", count: 80) + "\n")
    }
    
    // MARK: - Private Helpers
    
    private static func backupLocation(locationID: String, includeAssets: Bool, to archive: Archive) throws {
        let ctx = PersistenceContext.shared
        let locationDir = ctx.docs.appendingPathComponent("locations/\(locationID)", isDirectory: true)
        
        print("\n📦 Backing up location: \(locationID)")
        
        // 1. Backup UserDefaults
        let userDefaultsData = try backupUserDefaults(locationID: locationID)
        let userDefaultsJSON = try JSONSerialization.data(withJSONObject: userDefaultsData, options: [.prettyPrinted, .sortedKeys])
        try archive.addEntry(with: "\(locationID)/userdefaults.json", type: .file, uncompressedSize: UInt32(userDefaultsJSON.count), provider: { position, size in
            return userDefaultsJSON.subdata(in: position..<position+size)
        })
        print("   ✓ UserDefaults: \(userDefaultsData.count) keys")
        
        // 2. Backup dots.json
        let dotsFile = locationDir.appendingPathComponent("dots.json")
        if FileManager.default.fileExists(atPath: dotsFile.path) {
            let dotsData = try Data(contentsOf: dotsFile)
            try archive.addEntry(with: "\(locationID)/dots.json", type: .file, uncompressedSize: UInt32(dotsData.count), provider: { position, size in
                return dotsData.subdata(in: position..<position+size)
            })
            print("   ✓ dots.json")
        }
        
        // 3. Backup location.json
        let locationFile = locationDir.appendingPathComponent("location.json")
        if FileManager.default.fileExists(atPath: locationFile.path) {
            let locationData = try Data(contentsOf: locationFile)
            try archive.addEntry(with: "\(locationID)/location.json", type: .file, uncompressedSize: UInt32(locationData.count), provider: { position, size in
                return locationData.subdata(in: position..<position+size)
            })
            print("   ✓ location.json")
        }
        
        // 4. Backup assets (optional)
        if includeAssets {
            let assetsDir = locationDir.appendingPathComponent("assets", isDirectory: true)
            if FileManager.default.fileExists(atPath: assetsDir.path) {
                let assetFiles = try FileManager.default.contentsOfDirectory(at: assetsDir, includingPropertiesForKeys: nil)
                print("   📁 Found \(assetFiles.count) file(s) in assets directory:")
                for assetFile in assetFiles {
                    let fileName = assetFile.lastPathComponent
                    let fileSize = (try? FileManager.default.attributesOfItem(atPath: assetFile.path)[.size] as? Int64) ?? 0
                    let fileSizeMB = Double(fileSize) / 1_048_576.0
                    
                    print("      • \(fileName) (\(String(format: "%.2f", fileSizeMB)) MB)")
                    
                    let assetData = try Data(contentsOf: assetFile)
                    try archive.addEntry(with: "\(locationID)/assets/\(fileName)", type: .file, uncompressedSize: UInt32(assetData.count), provider: { position, size in
                        return assetData.subdata(in: position..<position+size)
                    })
                    print("      ✓ Backed up \(fileName)")
                }
            } else {
                print("   ⚠️ No assets directory found at: \(assetsDir.path)")
            }
        } else {
            print("   ⏭️ Skipping assets (user chose not to include)")
        }
        
        // 5. Backup map-points photos (reference photos stored on disk)
        let mapPointsDir = locationDir.appendingPathComponent("map-points", isDirectory: true)
        if FileManager.default.fileExists(atPath: mapPointsDir.path) {
            do {
                let photoFiles = try FileManager.default.contentsOfDirectory(at: mapPointsDir, includingPropertiesForKeys: nil)
                let imageFiles = photoFiles.filter { ["jpg", "jpeg", "png"].contains($0.pathExtension.lowercased()) }
                
                if !imageFiles.isEmpty {
                    print("   📷 Found \(imageFiles.count) reference photo(s) in map-points directory:")
                    for photoFile in imageFiles {
                        let fileName = photoFile.lastPathComponent
                        let fileSize = (try? FileManager.default.attributesOfItem(atPath: photoFile.path)[.size] as? Int64) ?? 0
                        let fileSizeKB = Double(fileSize) / 1024.0
                        
                        print("      • \(fileName) (\(String(format: "%.1f", fileSizeKB)) KB)")
                        
                        let photoData = try Data(contentsOf: photoFile)
                        try archive.addEntry(with: "\(locationID)/map-points/\(fileName)", type: .file, uncompressedSize: UInt32(photoData.count), provider: { position, size in
                            return photoData.subdata(in: position..<position+size)
                        })
                    }
                    print("   ✓ Backed up \(imageFiles.count) reference photo(s)")
                }
            } catch {
                print("   ⚠️ Error backing up map-points: \(error.localizedDescription)")
            }
        }
    }
    
    private static func backupUserDefaults(locationID: String) throws -> [String: Any] {
        let ud = UserDefaults.standard
        let prefix = "locations.\(locationID)."
        
        var data: [String: Any] = [:]
        
        // Keys to backup (standard namespaced keys)
        let keys = [
            // Map data
            "MapPoints_v1",
            "ActivePointID",
            
            // Triangle calibration
            "triangles_v1",
            
            // Beacon configuration
            "BeaconLocks_v1",
            "BeaconElevations_v1",
            "BeaconTxPower_v1",
            "advertisingIntervals",
            
            // Beacon lists (whitelist + morgue)
            "BeaconLists_v1",
            "BeaconLists_beacons_v1",
            "beaconLists.morgue.v1",
            
            // Metric calibration
            "MetricSquares_v1",
            
            // Compass calibration
            "mapMetrics.northOffsetDeg.v1",
            "mapMetrics.facingFineTuneDeg.v1",
            "mapMetrics.mapBaseOrientation.v1"
        ]
        
        for key in keys {
            let fullKey = prefix + key
            if let value = ud.object(forKey: fullKey) {
                // Convert Data objects to Base64 strings for JSON compatibility
                if let dataValue = value as? Data {
                    data[key] = ["__data_base64": dataValue.base64EncodedString()]
                } else {
                    data[key] = value
                }
            }
        }
        
        // SPECIAL CASE: Zones use non-standard key format "zones_<locationID>"
        let zoneKey = "zones_\(locationID)"
        if let zoneData = ud.data(forKey: zoneKey) {
            data["zones_v1"] = ["__data_base64": zoneData.base64EncodedString()]
            print("   ✓ Backed up zones: \(zoneData.count) bytes")
        }
        
        return data
    }
    
    private static func restoreLocation(locationID: String, from extractedDir: URL) throws {
        let ctx = PersistenceContext.shared
        let targetLocationDir = ctx.docs.appendingPathComponent("locations/\(locationID)", isDirectory: true)
        
        print("\n📥 Restoring location: \(locationID)")
        
        // 1. Restore UserDefaults
        let userDefaultsFile = extractedDir.appendingPathComponent("userdefaults.json")
        if FileManager.default.fileExists(atPath: userDefaultsFile.path) {
            let data = try Data(contentsOf: userDefaultsFile)
            let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
            
            let ud = UserDefaults.standard
            let prefix = "locations.\(locationID)."
            
            for (key, value) in dict {
                // Skip zones_v1 here - handle separately below
                if key == "zones_v1" {
                    continue
                }
                
                // Convert Base64 strings back to Data objects
                if let dataDict = value as? [String: String],
                   let base64String = dataDict["__data_base64"],
                   let restoredData = Data(base64Encoded: base64String) {
                    ud.set(restoredData, forKey: prefix + key)
                } else {
                    ud.set(value, forKey: prefix + key)
                }
            }
            
            // SPECIAL CASE: Restore zones to non-standard key format
            if let zoneValue = dict["zones_v1"] {
                let zoneKey = "zones_\(locationID)"
                if let base64Dict = zoneValue as? [String: String],
                   let base64String = base64Dict["__data_base64"],
                   let zoneData = Data(base64Encoded: base64String) {
                    ud.set(zoneData, forKey: zoneKey)
                    print("   ✓ Restored zones: \(zoneData.count) bytes")
                }
            }
            
            print("   ✓ UserDefaults: \(dict.count) keys restored")
        }
        
        // 2. Restore dots.json
        let dotsFile = extractedDir.appendingPathComponent("dots.json")
        if FileManager.default.fileExists(atPath: dotsFile.path) {
            try FileManager.default.createDirectory(at: targetLocationDir, withIntermediateDirectories: true)
            let targetDotsFile = targetLocationDir.appendingPathComponent("dots.json")
            try? FileManager.default.removeItem(at: targetDotsFile) // Remove existing
            try FileManager.default.copyItem(at: dotsFile, to: targetDotsFile)
            print("   ✓ dots.json")
        }
        
        // 3. Restore location.json
        let locationFile = extractedDir.appendingPathComponent("location.json")
        if FileManager.default.fileExists(atPath: locationFile.path) {
            let targetLocationFile = targetLocationDir.appendingPathComponent("location.json")
            try? FileManager.default.removeItem(at: targetLocationFile) // Remove existing
            try FileManager.default.copyItem(at: locationFile, to: targetLocationFile)
            print("   ✓ location.json")
        }
        
        // 4. Restore assets
        let assetsDir = extractedDir.appendingPathComponent("assets")
        if FileManager.default.fileExists(atPath: assetsDir.path) {
            let targetAssetsDir = targetLocationDir.appendingPathComponent("assets", isDirectory: true)
            try? FileManager.default.removeItem(at: targetAssetsDir) // Clear old assets
            try FileManager.default.copyItem(at: assetsDir, to: targetAssetsDir)
            print("   ✓ assets folder")
        }
        
        // 5. Restore map-points photos
        let mapPointsDir = extractedDir.appendingPathComponent("map-points")
        if FileManager.default.fileExists(atPath: mapPointsDir.path) {
            let targetMapPointsDir = targetLocationDir.appendingPathComponent("map-points", isDirectory: true)
            try? FileManager.default.removeItem(at: targetMapPointsDir) // Clear old photos
            try FileManager.default.copyItem(at: mapPointsDir, to: targetMapPointsDir)
            
            // Count restored photos for logging
            let photoCount = (try? FileManager.default.contentsOfDirectory(at: targetMapPointsDir, includingPropertiesForKeys: nil))?.count ?? 0
            print("   ✓ map-points folder (\(photoCount) photo(s))")
        }
    }
    
    private static func formattedFileSize(_ url: URL) -> String {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? Int64 else {
            return "unknown"
        }
        
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    private static func addBackupMetadata(locationIDs: [String], includeAssets: Bool, to archive: Archive) throws {
        // Gather location summaries
        let locationSummaries: [BackupMetadata.LocationSummary] = locationIDs.compactMap { locationID in
            let ctx = PersistenceContext.shared
            let locationDir = ctx.docs.appendingPathComponent("locations/\(locationID)", isDirectory: true)
            let stubURL = locationDir.appendingPathComponent("location.json")
            
            guard let data = try? Data(contentsOf: stubURL),
                  let stub = try? JSONDecoder().decode(LocationStub.self, from: data) else {
                return nil
            }
            
            // Read actual beacon count from dots.json (real-time, not cached)
            let dotsURL = locationDir.appendingPathComponent("dots.json")
            let actualBeaconCount: Int
            if let dotsData = try? Data(contentsOf: dotsURL),
               let dotsArray = try? JSONSerialization.jsonObject(with: dotsData) as? [[String: Any]] {
                actualBeaconCount = dotsArray.count
            } else {
                actualBeaconCount = 0
            }
            
            return BackupMetadata.LocationSummary(
                id: stub.id,
                name: stub.name,
                originalID: stub.originalID,
                sessionCount: stub.sessionCount,
                beaconCount: actualBeaconCount,  // Use real-time count
                mapDimensions: [stub.displayWidth, stub.displayHeight]
            )
        }
        
        let metadata = BackupMetadata(
            format: "tapresolver.backup.v2",
            exportedBy: "TapResolver iOS v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")",
            exportDate: ISO8601DateFormatter().string(from: Date()),
            authorName: AppSettings.authorName,
            locations: locationSummaries,
            totalLocations: locationIDs.count,
            includesAssets: includeAssets
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let metadataData = try encoder.encode(metadata)
        
        try archive.addEntry(with: "metadata.json", type: .file, uncompressedSize: UInt32(metadataData.count), provider: { position, size in
            return metadataData.subdata(in: position..<position+size)
        })
        
        print("   ✓ metadata.json")
    }
    
    enum BackupError: Error {
        case archiveCreationFailed
        case archiveReadFailed
    }
}