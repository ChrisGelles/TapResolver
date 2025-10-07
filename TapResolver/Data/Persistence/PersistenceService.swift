import Foundation

enum PersistenceService {

    // LOCATION
    static func writeLocation(_ dto: LocationConfigV1) throws {
        let url = try PathProvider.locationConfigURL(dto.location.id)
        let data = try JSONKit.encoder().encode(dto)
        try data.write(to: url, options: .atomic)
    }
    static func readLocation(_ id: String) throws -> LocationConfigV1 {
        let url = try PathProvider.locationConfigURL(id)
        let data = try Data(contentsOf: url)
        return try JSONKit.decoder.decode(LocationConfigV1.self, from: data)
    }

    // SCAN
    static func writeScan(_ dto: ScanRecordV1, at date: Date) throws -> URL {
        let url = try PathProvider.scanURL(dto.locationID, date: date, scanID: dto.scanID)
        let data = try JSONKit.encoder().encode(dto)
        try data.write(to: url, options: .atomic)
        return url
    }

    // LIST scans for a location (optionally filter by pointID later)
    static func listScans(locationID: String) throws -> [URL] {
        let root = try PathProvider.locationDir(locationID).appendingPathComponent("Scans", isDirectory: true)
        guard let e = FileManager.default.enumerator(at: root, includingPropertiesForKeys: [.isRegularFileKey]) else { return [] }
        return e.compactMap { $0 as? URL }.filter { $0.pathExtension.lowercased() == "json" }
    }

    static func readScan(_ url: URL) throws -> ScanRecordV1 {
        let data = try Data(contentsOf: url)
        return try JSONKit.decoder.decode(ScanRecordV1.self, from: data)
    }
}
