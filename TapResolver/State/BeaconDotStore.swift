//
//  BeaconDotStore.swift
//  TapResolver
//
//  Created by restructuring on 9/19/25.
//

import SwiftUI
import CoreGraphics

// A lightweight, optional hook other stores can call to read locked beacon IDs
// without tight coupling to instances (wired in App bootstrap).
enum BeaconDotRegistry {
    static var sharedLockedIDs: (() -> [String])?
}

// MARK: - Elevation editing state
public struct ActiveElevationEdit: Identifiable {
    public let id = UUID()
    public let beaconID: String
    public var text: String
}

// MARK: - Store of dots (map-local positions) + Locks + Persistence
public final class BeaconDotStore: ObservableObject {
    private let ctx = PersistenceContext.shared
    public struct Dot: Identifiable {
        public let id = UUID()
        public let beaconID: String     // one dot per beacon
        public let color: Color
        public var mapPoint: CGPoint    // map-local (untransformed) coords
        public var elevation: Double = 0.75  // elevation in meters, default 0.75
    }

    @Published public private(set) var dots: [Dot] = []
    // beaconID -> locked?
    @Published private(set) var locked: [String: Bool] = [:]
    // beaconID -> elevation
    @Published private(set) var elevations: [String: Double] = [:]
    // beaconID -> txPower dBm
    @Published var txPowerByID: [String: Int] = [:]
    // beaconID -> advertising interval in milliseconds
    @Published private(set) var advertisingIntervalByID: [String: Double] = [:]
    private let defaultAdvertisingInterval: Double = 100.0  // BC04P default
    // Active elevation editing state
    @Published public var activeElevationEdit: ActiveElevationEdit? = nil

    // MARK: persistence keys
    private let dotsKey        = "BeaconDots_v1"       // UserDefaults fallback for tiny payloads (optional)
    private let locksKey       = "BeaconLocks_v1"
    private let elevationsKey  = "BeaconElevations_v1"
    private let txPowerKey     = "BeaconTxPower_v1"
    private let dotsFileName   = "dots.json"           // file with coordinates

    public init() {
        // Do not load from any legacy/global path
        loadLocks()
        loadElevations()
        loadTxPower()
        loadDotsFromDisk()
    }

    public func dot(for beaconID: String) -> Dot? {
        dots.first { $0.beaconID == beaconID }
    }

    /// Toggle a dot for a beacon:
    /// - If it exists, remove it.
    /// - If not, add at `mapPoint` with `color`.
    public func toggleDot(for beaconID: String, mapPoint: CGPoint, color: Color) {
        if let idx = dots.firstIndex(where: { $0.beaconID == beaconID }) {
            dots.remove(at: idx)
            saveDotsToDisk()
            print("Removed dot for \(beaconID)")
        } else {
            dots.append(Dot(beaconID: beaconID, color: color, mapPoint: mapPoint))
            saveDotsToDisk()
            print("Added dot for \(beaconID) @ map (\(Int(mapPoint.x)), \(Int(mapPoint.y)))")
        }
    }

    /// Update a dot's map-local position (used while dragging).
    public func updateDot(id: UUID, to newPoint: CGPoint) {
        if let idx = dots.firstIndex(where: { $0.id == id }) {
            dots[idx].mapPoint = newPoint
            saveDotsToDisk()
        }
    }

    public func clear() {
        dots.removeAll()
        saveDotsToDisk()
    }
    
    /// Clear dots for unlocked beacons only (preserves locked beacons)
    public func clearUnlockedDots() {
        dots.removeAll { !isLocked($0.beaconID) }
        saveDotsToDisk()
    }
    
    /// Get only the locked beacon dots
    public func lockedDots() -> [Dot] {
        return dots.filter { isLocked($0.beaconID) }
    }
    
    
    // MARK: - Elevation API
    
    public func setElevation(for beaconID: String, elevation: Double) {
        elevations[beaconID] = elevation
        saveElevations()
    }
    
    public func getElevation(for beaconID: String) -> Double {
        return elevations[beaconID] ?? 0.75
    }
    
    public func startElevationEdit(for beaconID: String) {
        let current = getElevation(for: beaconID)
        let seed = String(format: "%g", current)
        activeElevationEdit = ActiveElevationEdit(beaconID: beaconID, text: seed)
    }
    
    public func commitElevationText(_ text: String, for beaconID: String) {
        if let elevation = Double(text) {
            setElevation(for: beaconID, elevation: elevation)
        }
    }
    
    public func displayElevationText(for beaconID: String) -> String {
        let elevation = getElevation(for: beaconID)
        let formatted = String(format: "%g", elevation)
        return "\(formatted)m"
    }
    
    // MARK: - Tx Power API
    
    public func setTxPower(for beaconID: String, dbm: Int?) {
        if let v = dbm {
            txPowerByID[beaconID] = v
        } else {
            txPowerByID.removeValue(forKey: beaconID)
        }
        saveTxPower()
    }
    
    public func getTxPower(for beaconID: String) -> Int? {
        return txPowerByID[beaconID]
    }
    
    // MARK: - Advertising Interval API
    
    public func setAdvertisingInterval(for beaconID: String, ms: Double?) {
        if let v = ms {
            advertisingIntervalByID[beaconID] = v
        } else {
            advertisingIntervalByID.removeValue(forKey: beaconID)
        }
        saveAdvertisingIntervals()
    }
    
    public func getAdvertisingInterval(for beaconID: String) -> Double {
        return advertisingIntervalByID[beaconID] ?? defaultAdvertisingInterval
    }
    
    public func displayAdvertisingInterval(for beaconID: String) -> String {
        let interval = getAdvertisingInterval(for: beaconID)
        // Format with up to 2 decimal places, removing trailing zeros
        let formatted = String(format: "%.2f", interval)
        if let lastNonZero = formatted.lastIndex(where: { $0 != "0" && $0 != "." }) {
            return String(formatted[...lastNonZero]) + " ms"
        }
        return formatted + " ms"
    }
    
    /// Reload data for the active location
    public func reloadForActiveLocation() {
        clearAndReloadForActiveLocation()
    }
    
    /// Public flush+reload for location switching
    public func clearAndReloadForActiveLocation() {
        // Hard flush (no save) to avoid bleed
        dots.removeAll()
        locked.removeAll()
        elevations.removeAll()
        txPowerByID.removeAll()
        advertisingIntervalByID.removeAll()

        // Pure load for the active namespace and file
        loadLocks()
        loadElevations()
        loadTxPower()
        loadAdvertisingIntervals()
        loadDotsFromDisk()
        objectWillChange.send()
    }
    
    /// Get the beacon IDs that are currently locked
    public func lockedBeaconIDs() -> [String] {
        locked.keys.filter { locked[$0] == true }
    }

    // MARK: - Lock API

    public func isLocked(_ beaconID: String) -> Bool {
        locked[beaconID] ?? false
    }

    public func toggleLock(_ beaconID: String) {
        let newVal = !(locked[beaconID] ?? false)
        locked[beaconID] = newVal
        saveLocks()
        saveDotsToDisk() // Also save dot data when locking/unlocking
    }

    // MARK: - Persistence

    private struct DotDTO: Codable {
        let beaconID: String
        let x: Double
        let y: Double
        let elevation: Double
        let txPower: Int?
    }

    private struct LocksDTO: Codable { let locks: [String: Bool] }

    private func save() {
        // Save dots to file (authoritative for coordinates)
        saveDotsToDisk()
        saveLocks()
    }

    private func saveLocks() {
        let payload = LocksDTO(locks: locked)
        ctx.write(locksKey, value: payload)
    }

    private func load() {
        loadLocks()
        loadElevations()
        loadTxPower()
        loadDotsFromDisk()
    }
    
    private func loadLocks() {
        if let dto: LocksDTO = ctx.read(locksKey, as: LocksDTO.self) {
            locked = dto.locks
        } else {
            locked = [:]
        }
    }
    
    private func saveElevations() {
        ctx.write(elevationsKey, value: elevations)
    }
    
    private func loadElevations() {
        elevations = ctx.read(elevationsKey, as: [String: Double].self) ?? [:]
    }
    
    private func loadTxPower() {
        txPowerByID = ctx.read(txPowerKey, as: [String: Int].self) ?? [:]
    }
    
    private func saveTxPower() {
        ctx.write(txPowerKey, value: txPowerByID)
    }
    
    private func saveAdvertisingIntervals() {
        ctx.write("advertisingIntervals", value: advertisingIntervalByID)
    }
    
    private func loadAdvertisingIntervals() {
        advertisingIntervalByID = ctx.read("advertisingIntervals", as: [String: Double].self) ?? [:]
    }
    
    // MARK: - File persistence for dot coordinates
    private func dotsFileURL(_ ctx: PersistenceContext = .shared) -> URL {
        ctx.locationDir.appendingPathComponent(dotsFileName, isDirectory: false)
    }

    private func saveDotsToDisk() {
        let ctx = PersistenceContext.shared
        try? FileManager.default.createDirectory(at: ctx.locationDir, withIntermediateDirectories: true)
        let dtos: [DotDTO] = dots.map { d in
            DotDTO(beaconID: d.beaconID,
                   x: d.mapPoint.x,
                   y: d.mapPoint.y,
                   elevation: elevations[d.beaconID] ?? d.elevation,
                   txPower: txPowerByID[d.beaconID])
        }
        do {
            let data = try JSONEncoder().encode(dtos)
            try data.write(to: dotsFileURL(ctx), options: .atomic)
        } catch {
            print("⚠️ saveDotsToDisk failed: \(error)")
        }
    }

    private func loadDotsFromDisk() {
        let url = dotsFileURL()
        guard let data = try? Data(contentsOf: url) else { dots = []; return }
        do {
            let dtos = try JSONDecoder().decode([DotDTO].self, from: data)
            dots = dtos.map {
                var dot = Dot(beaconID: $0.beaconID,
                              color: beaconColor(for: $0.beaconID),
                              mapPoint: CGPoint(x: $0.x, y: $0.y))
                dot.elevation = $0.elevation
                // Rehydrate side tables too
                elevations[$0.beaconID] = $0.elevation
                if let p = $0.txPower { txPowerByID[$0.beaconID] = p }
                return dot
            }
        } catch {
            print("⚠️ loadDotsFromDisk failed: \(error)")
            dots = []
        }
    }

    private func beaconColor(for beaconID: String) -> Color {
        let hash = beaconID.hash
        let hue = Double(abs(hash % 360)) / 360.0
        return Color(hue: hue, saturation: 0.7, brightness: 0.8)
    }
}
