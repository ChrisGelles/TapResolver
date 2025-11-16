// PersistenceContext.swift

import Foundation

final class PersistenceContext {
    static let shared = PersistenceContext()
    var locationID: String = "home" // router keeps this up to date

    // Namespaced key => "locations.<id>.<base>"
    func key(_ base: String) -> String { "locations.\(locationID).\(base)" }

    // MARK: UserDefaults (namespaced-only)
    func write<T: Encodable>(_ base: String, value: T) {
        let ud = UserDefaults.standard
        do {
            let data = try JSONEncoder().encode(value)
            ud.set(data, forKey: key(base))
        } catch {
            print("⚠️ Persist write failed for \(key(base)): \(error)")
        }
    }

    func read<T: Decodable>(_ base: String, as type: T.Type) -> T? {
        // ========================================================================
        // LINE-BY-LINE DATA LOADING TRACE
        // ========================================================================
        let ud = UserDefaults.standard
        let fullKey = key(base)
        
        // STEP 1: Log the read request
        if base.contains("MapPoints") {
            print("\n" + "=".repeating(80))
            print("📖 DATA LOAD TRACE: PersistenceContext.read()")
            print("=".repeating(80))
            print("   [1] Base key requested: '\(base)'")
            print("   [2] Current PersistenceContext.locationID: '\(locationID)'")
            print("   [3] Generated full key via key('\(base)'): '\(fullKey)'")
            print("   [4] Querying UserDefaults.standard.data(forKey: '\(fullKey)')")
        }
        
        // STEP 2: Attempt to read from UserDefaults
        guard let data = ud.data(forKey: fullKey) else {
            if base.contains("MapPoints") {
                print("   [5] ❌ UserDefaults returned nil - key '\(fullKey)' does not exist")
                print("   [6] Returning nil from PersistenceContext.read()")
                print("=".repeating(80) + "\n")
            }
            return nil
        }
        
        // STEP 3: Data found - log details
        if base.contains("MapPoints") {
            print("   [5] ✅ UserDefaults returned data")
            print("   [6] Data size: \(data.count) bytes (\(String(format: "%.2f", Double(data.count) / 1024.0)) KB)")
            
            // STEP 4: Decode and inspect first few points
            print("   [7] Attempting JSONDecoder().decode([MapPointDTO].self, from: data)")
            if let jsonString = String(data: data, encoding: .utf8) {
                let preview = String(jsonString.prefix(500))
                print("   [8] Raw JSON preview (first 500 chars): \(preview)...")
            }
        }
        
        // STEP 5: Decode the data
        guard let decoded = try? JSONDecoder().decode(T.self, from: data) else {
            if base.contains("MapPoints") {
                print("   [9] ❌ JSONDecoder failed to decode data")
                print("=".repeating(80) + "\n")
            }
            return nil
        }
        
        // STEP 6: Successfully decoded - log sample data
        if base.contains("MapPoints"), let points = decoded as? [Any] {
            print("   [9] ✅ JSONDecoder successfully decoded data")
            print("   [10] Decoded \(points.count) items")
            
            // Log first 3 point IDs and positions if available
            if let pointArray = decoded as? [[String: Any]] {
                print("   [11] Sample data (first 3 points):")
                for (index, pointDict) in pointArray.prefix(3).enumerated() {
                    if let id = pointDict["id"] as? String,
                       let x = pointDict["x"] as? CGFloat,
                       let y = pointDict["y"] as? CGFloat {
                        print("       Point[\(index+1)]: ID=\(String(id.prefix(8)))... Pos=(\(Int(x)), \(Int(y)))")
                    }
                }
            }
        }
        
        if base.contains("MapPoints") {
            print("   [12] Returning decoded data from PersistenceContext.read()")
            print("=".repeating(80) + "\n")
        }
        
        return decoded
    }
    
    /// Read raw data from UserDefaults for diagnostic purposes
    /// Does NOT use namespacing - requires full key (e.g., "locations.home.MapPoints_v1")
    func readRaw(key: String) -> Data? {
        let ud = UserDefaults.standard
        return ud.data(forKey: key)
    }

    // MARK: File paths (namespaced)
    var docs: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    var locationDir: URL { docs.appendingPathComponent("locations/\(locationID)", isDirectory: true) }
    var assetsDir: URL   { locationDir.appendingPathComponent("assets", isDirectory: true) }
    var scansDir: URL {
        // Scans directory: Documents/locations/{id}/Scans/
        // Individual scans organized into year-month subdirectories via PathProvider.scanURL()
        // e.g., Documents/locations/museum/Scans/2025-10/scan_xxx.json
        return locationDir.appendingPathComponent("Scans", isDirectory: true)
    }
}
