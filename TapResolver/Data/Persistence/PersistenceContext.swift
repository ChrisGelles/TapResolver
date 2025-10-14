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
        let ud = UserDefaults.standard
        guard let data = ud.data(forKey: key(base)) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
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
