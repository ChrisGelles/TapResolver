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
    
    /// Backup selected locations to a ZIP file
    /// - Parameters:
    ///   - locationIDs: Array of location IDs to backup
    ///   - includeAssets: Whether to include map images (large files)
    /// - Returns: URL to the created ZIP file in temp directory
    static func backupLocations(locationIDs: [String], includeAssets: Bool) throws -> URL {
        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: "T", with: "_")
            .prefix(19) // YYYY-MM-DD_HHmmss
        
        let zipFileName = "TapResolver_Backup_\(timestamp).zip"
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
        
        try archive.extract(to: tempDir)
        
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
            try archive.addEntry(with: "\(locationID)/dots.json", relativeTo: locationDir)
            print("   ✓ dots.json")
        }
        
        // 3. Backup location.json
        let locationFile = locationDir.appendingPathComponent("location.json")
        if FileManager.default.fileExists(atPath: locationFile.path) {
            try archive.addEntry(with: "\(locationID)/location.json", relativeTo: locationDir)
            print("   ✓ location.json")
        }
        
        // 4. Backup assets (optional)
        if includeAssets {
            let assetsDir = locationDir.appendingPathComponent("assets", isDirectory: true)
            if FileManager.default.fileExists(atPath: assetsDir.path) {
                let assetFiles = try FileManager.default.contentsOfDirectory(at: assetsDir, includingPropertiesForKeys: nil)
                for assetFile in assetFiles {
                    try archive.addEntry(with: "\(locationID)/assets/\(assetFile.lastPathComponent)", relativeTo: locationDir)
                    print("   ✓ assets/\(assetFile.lastPathComponent)")
                }
            }
        }
    }
    
    private static func backupUserDefaults(locationID: String) throws -> [String: Any] {
        let ud = UserDefaults.standard
        let prefix = "locations.\(locationID)."
        
        var data: [String: Any] = [:]
        
        // Keys to backup
        let keys = [
            "MapPoints_v1",
            "BeaconLocks_v1",
            "BeaconElevations_v1",
            "BeaconTxPower_v1",
            "advertisingIntervals",
            "ActivePointID",
            "MetricSquares_v1",
            "BeaconLists_v1"
        ]
        
        for key in keys {
            let fullKey = prefix + key
            if let value = ud.object(forKey: fullKey) {
                data[key] = value
            }
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
                ud.set(value, forKey: prefix + key)
            }
            
            print("   ✓ UserDefaults: \(dict.count) keys restored")
        }
        
        // 2. Restore dots.json
        let dotsFile = extractedDir.appendingPathComponent("dots.json")
        if FileManager.default.fileExists(atPath: dotsFile.path) {
            try FileManager.default.createDirectory(at: targetLocationDir, withIntermediateDirectories: true)
            try FileManager.default.copyItem(at: dotsFile, to: targetLocationDir.appendingPathComponent("dots.json"))
            print("   ✓ dots.json")
        }
        
        // 3. Restore location.json
        let locationFile = extractedDir.appendingPathComponent("location.json")
        if FileManager.default.fileExists(atPath: locationFile.path) {
            try FileManager.default.copyItem(at: locationFile, to: targetLocationDir.appendingPathComponent("location.json"))
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
    
    enum BackupError: Error {
        case archiveCreationFailed
        case archiveReadFailed
    }
}