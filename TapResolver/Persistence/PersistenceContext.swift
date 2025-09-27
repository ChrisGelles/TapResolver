import Foundation

/// Centralized persistence shim to (a) namespace keys by location and
/// (b) support a legacy->namespaced transition with optional double-writes.
final class PersistenceContext: ObservableObject {
    static let shared = PersistenceContext()

    // Single-location for now; will be switched to selected locationID later.
    @Published var locationID: String = "default"

    // One-time migration flag
    private let didInitDirsKey = "locations.v1.initDirs.complete"

    // Namespacing helper
    func key(_ base: String) -> String { "locations.\(locationID).\(base)" }

    // File system paths
    private var docs: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    var scansLegacyDir: URL { docs.appendingPathComponent("scans", isDirectory: true) }
    var locationsRootDir: URL { docs.appendingPathComponent("locations", isDirectory: true) }
    var locationDir: URL { locationsRootDir.appendingPathComponent(locationID, isDirectory: true) }
    var scansNewDir: URL { locationDir.appendingPathComponent("scan_summaries", isDirectory: true) }
    var assetsDir: URL { locationDir.appendingPathComponent("assets", isDirectory: true) }
    var locationJSON: URL { locationDir.appendingPathComponent("location.json", isDirectory: false) }

    // MARK: - Legacy-first read, namespaced-or-legacy
    func read<T: Decodable>(_ baseKey: String, as type: T.Type) -> T? {
        let ud = UserDefaults.standard
        // 1) Namespaced Data -> decode
        if let data = ud.data(forKey: key(baseKey)),
           let v = try? JSONDecoder().decode(T.self, from: data) {
            return v
        }
        // 2) Legacy Data -> decode
        if let data = ud.data(forKey: baseKey),
           let v = try? JSONDecoder().decode(T.self, from: data) {
            return v
        }
        // 3) Legacy property-list object (e.g., [String]) -> cast
        if let obj = ud.object(forKey: baseKey) as? T {
            return obj
        }
        return nil
    }

    // MARK: - Namespaced write + optional legacy mirror
    func write<T: Encodable>(_ baseKey: String, value: T, alsoWriteLegacy: Bool = true) {
        let ud = UserDefaults.standard
        // Always encode for namespaced key.
        if let data = try? JSONEncoder().encode(value) {
            ud.set(data, forKey: key(baseKey))
        }
        // Legacy mirror preserves original storage shape if possible.
        guard alsoWriteLegacy else { return }
        switch value {
        case let v as [String]:
            ud.set(v, forKey: baseKey)    // arrays previously saved as property list
        case let v as String:
            ud.set(v, forKey: baseKey)
        case let v as Int:
            ud.set(v, forKey: baseKey)
        case let v as Double:
            ud.set(v, forKey: baseKey)
        case let v as Bool:
            ud.set(v, forKey: baseKey)
        case let v as [String:Int]:
            ud.set(v, forKey: baseKey)
        default:
            if let data = try? JSONEncoder().encode(value) {
                ud.set(data, forKey: baseKey)
            }
        }
    }

    // MARK: - Directory init (idempotent)
    func ensureLocationDirs() {
        let fm = FileManager.default
        do {
            try fm.createDirectory(at: scansLegacyDir, withIntermediateDirectories: true)
            try fm.createDirectory(at: locationsRootDir, withIntermediateDirectories: true)
            try fm.createDirectory(at: locationDir, withIntermediateDirectories: true)
            try fm.createDirectory(at: scansNewDir, withIntermediateDirectories: true)
            try fm.createDirectory(at: assetsDir, withIntermediateDirectories: true)
            UserDefaults.standard.set(true, forKey: didInitDirsKey)
        } catch {
            print("⚠️ PersistenceContext: ensureLocationDirs failed: \(error)")
        }
    }
}
