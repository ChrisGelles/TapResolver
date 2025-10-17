//
//  StorageDiagnostics.swift
//  TapResolver
//
//  Diagnostic utility for investigating UserDefaults storage issues
//

import Foundation
import CoreGraphics

struct StorageDiagnostics {
    
    // Local DTO struct that matches MapPointStore's private MapPointDTO structure
    private struct MapPointDTO: Codable {
        let id: UUID
        let x: CGFloat
        let y: CGFloat
        let createdDate: Date
        let sessions: [ScanSession]
        
        struct ScanSession: Codable {
            let scanID: String
            let sessionID: String
            let pointID: String
            let locationID: String
            let timingStartISO: String
            let timingEndISO: String
            let duration_s: Double
            let deviceHeight_m: Double
            let facing_deg: Double?
            let beacons: [BeaconData]
            
            struct BeaconData: Codable {
                let beaconID: String
                let stats: Stats
                let hist: Histogram
                let meta: Metadata
                
                struct Stats: Codable {
                    let median_dbm: Int
                    let mad_db: Int
                    let p10_dbm: Int
                    let p90_dbm: Int
                    let samples: Int
                }
                
                struct Histogram: Codable {
                    let binMin_dbm: Int
                    let binMax_dbm: Int
                    let binSize_db: Int
                    let counts: [Int]
                }
                
                struct Metadata: Codable {
                    let name: String
                    let model: String?
                }
            }
        }
    }
    
    /// Print all possible storage locations for map points
    static func printAllMapPointStorageLocations() {
        print("\n" + String(repeating: "=", count: 80))
        print("🗄️  ALL POSSIBLE MAP POINT STORAGE LOCATIONS")
        print(String(repeating: "=", count: 80))
        
        let locationIDs = ["home", "museum", "default"]
        let keyPatterns = [
            "MapPoints_v1",
            "locations.{LOC}.mapPoints.v1",
            "locations.{LOC}.MapPoints_v1"
        ]
        
        for locID in locationIDs {
            print("\n📍 Location: \(locID)")
            for pattern in keyPatterns {
                let key = pattern.replacingOccurrences(of: "{LOC}", with: locID)
                
                if let data = UserDefaults.standard.data(forKey: key) {
                    print("   ✅ \(key): \(data.count) bytes")
                    
                    // Try to decode and count
                    do {
                        let decoder = JSONDecoder()
                        let decoded = try decoder.decode([MapPointDTO].self, from: data)
                        let totalSessions = decoded.reduce(0) { $0 + $1.sessions.count }
                        print("      → \(decoded.count) points, \(totalSessions) sessions")
                    } catch {
                        print("      → Failed to decode: \(error.localizedDescription)")
                    }
                } else {
                    print("   ❌ \(key): not found")
                }
            }
        }
        
        // Also check for raw keys without location prefix
        print("\n📦 NON-PREFIXED KEYS:")
        let rawKeys = ["MapPoints_v1", "mapPoints.v1", "MapPoints"]
        for key in rawKeys {
            if let data = UserDefaults.standard.data(forKey: key) {
                print("   ✅ \(key): \(data.count) bytes")
                do {
                    let decoder = JSONDecoder()
                    let decoded = try decoder.decode([MapPointDTO].self, from: data)
                    let totalSessions = decoded.reduce(0) { $0 + $1.sessions.count }
                    print("      → \(decoded.count) points, \(totalSessions) sessions")
                } catch {
                    print("      → Failed to decode: \(error.localizedDescription)")
                }
            } else {
                print("   ❌ \(key): not found")
            }
        }
        
        print(String(repeating: "=", count: 80) + "\n")
    }
    
    /// Scan ALL UserDefaults keys and report on data sizes
    static func scanAllUserDefaultsKeys() {
        print("\n" + String(repeating: "=", count: 80))
        print("🔍 COMPLETE USERDEFAULTS SCAN")
        print(String(repeating: "=", count: 80))
        
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys.sorted()
        var totalBytes = 0
        var mapPointRelatedKeys: [(String, Int)] = []
        
        for key in allKeys {
            if let data = UserDefaults.standard.data(forKey: key) {
                totalBytes += data.count
                
                if key.lowercased().contains("map") || key.lowercased().contains("point") {
                    mapPointRelatedKeys.append((key, data.count))
                }
            }
        }
        
        print("Total keys: \(allKeys.count)")
        print("Total data: \(String(format: "%.2f", Double(totalBytes) / 1024.0 / 1024.0)) MB")
        
        print("\n📍 MAP POINT RELATED KEYS:")
        if mapPointRelatedKeys.isEmpty {
            print("   (none found)")
        } else {
            for (key, bytes) in mapPointRelatedKeys.sorted(by: { $0.1 > $1.1 }) {
                print("   \(key): \(String(format: "%.2f", Double(bytes) / 1024.0)) KB")
            }
        }
        
        print(String(repeating: "=", count: 80) + "\n")
    }
}
