//
//  UserDefaultsCleanup.swift
//  TapResolver
//
//  One-time cleanup utility for purging orphaned/legacy UserDefaults keys.
//  Run via Debug Settings panel, then comment out the button.
//

import Foundation

struct UserDefaultsCleanup {
    
    /// Results from a cleanup operation
    struct CleanupResult {
        let keysRemoved: [String]
        let bytesFreed: Int
        let errors: [String]
        
        var summary: String {
            let mb = Double(bytesFreed) / 1_048_576
            return "Removed \(keysRemoved.count) keys, freed \(String(format: "%.2f MB", mb))"
        }
    }
    
    /// Preview what would be deleted (dry run)
    static func preview() -> CleanupResult {
        return performCleanup(dryRun: true)
    }
    
    /// Actually delete the orphaned keys
    static func execute() -> CleanupResult {
        return performCleanup(dryRun: false)
    }
    
    private static func performCleanup(dryRun: Bool) -> CleanupResult {
        let defaults = UserDefaults.standard
        var keysToRemove: [String] = []
        var totalBytes = 0
        var errors: [String] = []
        
        let allKeys = defaults.dictionaryRepresentation().keys
        
        // === CATEGORY 1: Orphaned location UUIDs ===
        // These are locations that were deleted but their data remains
        let orphanedLocationPrefixes = [
            "locations.25ca3fdc-61b4-471e-bcdb-6a1524bb1e23",
            "locations.2CA48CFE-1198-4364-90E9-0BCC01ACFA04",
            "locations.3fca36be-98cc-48f7-9f27-eef404e29c72",
            "locations.7cb98376-e31c-4245-b068-687f05630fb8"
        ]
        
        for key in allKeys {
            for prefix in orphanedLocationPrefixes {
                if key.hasPrefix(prefix) {
                    keysToRemove.append(key)
                }
            }
        }
        
        // === CATEGORY 2: Legacy AR Markers (not loaded anymore) ===
        for key in allKeys {
            if key.contains(".ARMarkers_v1") {
                keysToRemove.append(key)
            }
        }
        
        // === CATEGORY 3: Root-level beacon data (pre-location-scoping orphans) ===
        let rootLevelLegacyKeys = [
            "BeaconDots_v1",
            "BeaconLocks_v1",
            "BeaconElevations_v1",
            "BeaconTxPower_v1",
            "BeaconLists_beacons_v1",
            "BeaconLists_morgue_v1",
            "LockedBeaconDots_v1",
            "MapPoints_v1",
            "MetricSquares_v1",
            "BeaconDots_txPowerByID_v1"
        ]
        
        for key in rootLevelLegacyKeys {
            if allKeys.contains(key) {
                keysToRemove.append(key)
            }
        }
        
        // === CATEGORY 3b: Root-level survey points (should be location-scoped) ===
        for key in allKeys {
            if key.hasPrefix("surveyPoints_") && !key.hasPrefix("locations.") {
                keysToRemove.append(key)
            }
        }
        
        // === CATEGORY 4: Retired features ===
        for key in allKeys {
            if key.contains("mapPointLog.sessionIndex") {
                keysToRemove.append(key)
            }
        }
        
        // === CATEGORY 5: MapPointLog locked sessions (per-point, accumulates) ===
        for key in allKeys {
            if key.hasPrefix("MapPointLog.LockedSessions.") {
                keysToRemove.append(key)
            }
        }
        
        // === Calculate sizes and deduplicate ===
        let uniqueKeys = Array(Set(keysToRemove)).sorted()
        
        for key in uniqueKeys {
            if let value = defaults.object(forKey: key) {
                let size: Int
                if let data = value as? Data {
                    size = data.count
                } else if let archived = try? NSKeyedArchiver.archivedData(withRootObject: value, requiringSecureCoding: false) {
                    size = archived.count
                } else {
                    size = 100 // Estimate for small values
                }
                totalBytes += size
            }
        }
        
        // === Execute or preview ===
        if dryRun {
            print("\n" + String(repeating: "=", count: 80))
            print("🔍 CLEANUP PREVIEW (DRY RUN)")
            print(String(repeating: "=", count: 80))
            print("Keys that WOULD be removed (\(uniqueKeys.count) total):\n")
            
            for key in uniqueKeys {
                let size = getSizeForKey(key)
                print("  🗑️ \(key) (\(formatSize(size)))")
            }
            
            let mb = Double(totalBytes) / 1_048_576
            print("\n" + String(repeating: "-", count: 80))
            print("📊 Would free: \(String(format: "%.2f MB", mb)) (\(totalBytes) bytes)")
            print("ℹ️  This is a DRY RUN. No data was deleted.")
            print(String(repeating: "=", count: 80) + "\n")
        } else {
            print("\n" + String(repeating: "=", count: 80))
            print("🗑️ EXECUTING CLEANUP")
            print(String(repeating: "=", count: 80))
            
            for key in uniqueKeys {
                let size = getSizeForKey(key)
                defaults.removeObject(forKey: key)
                print("  ✅ Removed: \(key) (\(formatSize(size)))")
            }
            
            defaults.synchronize()
            
            let mb = Double(totalBytes) / 1_048_576
            print("\n" + String(repeating: "-", count: 80))
            print("📊 Freed: \(String(format: "%.2f MB", mb)) (\(totalBytes) bytes)")
            print("✅ Cleanup complete!")
            print(String(repeating: "=", count: 80) + "\n")
        }
        
        return CleanupResult(
            keysRemoved: uniqueKeys,
            bytesFreed: totalBytes,
            errors: errors
        )
    }
    
    private static func getSizeForKey(_ key: String) -> Int {
        guard let value = UserDefaults.standard.object(forKey: key) else { return 0 }
        if let data = value as? Data {
            return data.count
        } else if let archived = try? NSKeyedArchiver.archivedData(withRootObject: value, requiringSecureCoding: false) {
            return archived.count
        }
        return 100
    }
    
    private static func formatSize(_ bytes: Int) -> String {
        let kb = Double(bytes) / 1024
        let mb = Double(bytes) / 1_048_576
        if mb >= 1.0 {
            return String(format: "%.2f MB", mb)
        } else if kb >= 1.0 {
            return String(format: "%.1f KB", kb)
        } else {
            return "\(bytes) bytes"
        }
    }
    
    // MARK: - Future: Add lowercase morgue purge after investigation
    
    /// Purge the massive BT device ignore lists (lowercase morgue)
    /// DISABLED until we understand what's writing to these keys
    /*
    static func purgeLowercaseMorgue() -> CleanupResult {
        let defaults = UserDefaults.standard
        var keysToRemove: [String] = []
        var totalBytes = 0
        
        for key in defaults.dictionaryRepresentation().keys {
            // Match: locations.*.beaconLists.morgue.v1 (lowercase, dots)
            // But NOT: locations.*.BeaconLists_morgue_v1 (capital, underscore)
            if key.contains(".beaconLists.morgue.v1") {
                keysToRemove.append(key)
                totalBytes += getSizeForKey(key)
            }
        }
        
        for key in keysToRemove {
            defaults.removeObject(forKey: key)
            print("  ✅ Purged lowercase morgue: \(key)")
        }
        defaults.synchronize()
        
        return CleanupResult(keysRemoved: keysToRemove, bytesFreed: totalBytes, errors: [])
    }
    */
}
