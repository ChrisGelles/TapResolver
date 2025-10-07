import Foundation

struct MapPointHistory {
    let locationID: String
    let pointID: String
    let scans: [ScanRecordV1]  // sorted by start time ascending
}

enum MapPointHistoryBuilder {
    static func loadAll(locationID: String, pointID: String) throws -> MapPointHistory {
        let urls = try PersistenceService.listScans(locationID: locationID)
        // Read and filter
        var records: [ScanRecordV1] = []
        for u in urls {
            let s = try PersistenceService.readScan(u)
            if s.pointID == pointID { records.append(s) }
        }
        // Sort by start time (parse ISO)
        let sorted = records.sorted {
            (JSONKit.iso8601.date(from: $0.timing.startISO) ?? .distantPast) <
            (JSONKit.iso8601.date(from: $1.timing.startISO) ?? .distantPast)
        }
        return MapPointHistory(locationID: locationID, pointID: pointID, scans: sorted)
    }
}
