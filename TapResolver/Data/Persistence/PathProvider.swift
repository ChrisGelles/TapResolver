import Foundation

enum PathProvider {
    static func baseDir() throws -> URL {
        guard let u = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "PathProvider", code: 1)
        }
        // Use Documents/locations/ structure (consistent with PersistenceContext)
        let locationsDir = u.appendingPathComponent("locations")
        try FileManager.default.createDirectory(at: locationsDir, withIntermediateDirectories: true)
        return locationsDir
    }
    static func locationDir(_ id: String) throws -> URL {
        // baseDir is now Documents/locations/, so just append the locationID
        let dir = try baseDir().appendingPathComponent(id, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    static func locationConfigURL(_ id: String) throws -> URL {
        try locationDir(id).appendingPathComponent("location.json", conformingTo: .json)
    }
    static func scansMonthDir(_ id: String, year: Int, month: Int) throws -> URL {
        let m = String(format: "%04d-%02d", year, month)
        let u = try locationDir(id).appendingPathComponent("Scans", isDirectory: true)
            .appendingPathComponent(m, isDirectory: true)
        try FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
        return u
    }
    static func scanURL(_ id: String, date: Date, scanID: String) throws -> URL {
        let comps = Calendar.current.dateComponents(in: .current, from: date)
        let y = comps.year!, mo = comps.month!
        let dir = try scansMonthDir(id, year: y, month: mo)
        let url = dir.appendingPathComponent("\(scanID).json", conformingTo: .json)
        
        // DEBUG: Log where we're saving
        print("💾 PathProvider.scanURL() generated path:")
        print("   Full path: \(url.path)")
        print("   In Documents: \(url.path.contains("/Documents/"))")
        
        return url
    }
}
