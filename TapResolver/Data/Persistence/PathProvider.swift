import Foundation

enum PathProvider {
    static func baseDir() throws -> URL {
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("TapResolver", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
    static func locationDir(_ id: String) throws -> URL {
        let u = try baseDir().appendingPathComponent("Locations", isDirectory: true)
            .appendingPathComponent(id, isDirectory: true)
        try FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
        return u
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
        return dir.appendingPathComponent("\(scanID).json", conformingTo: .json)
    }
}
