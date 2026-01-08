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
    static var sharedBeaconNames: (() -> [String])?
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

    // MARK: - V2 Persistence Model (Single Source of Truth)

    /// Consolidated beacon dot storage - replaces dots.json and all separate metadata keys
    public struct BeaconDotV2: Codable {
        public let beaconID: String
        public var x: Double
        public var y: Double
        public var elevation: Double
        public var txPower: Int?
        public var advertisingInterval: Double?
        public var isLocked: Bool
        public var macAddress: String?
        public var model: String?
        public var firmware: String?
        public var lastConfigReadSession: Int?
        
        public init(beaconID: String, x: Double, y: Double, elevation: Double = 0.75) {
            self.beaconID = beaconID
            self.x = x
            self.y = y
            self.elevation = elevation
            self.txPower = nil
            self.advertisingInterval = nil
            self.isLocked = false
            self.macAddress = nil
            self.model = nil
            self.firmware = nil
            self.lastConfigReadSession = nil
        }
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
    // beaconID -> MAC address
    @Published private(set) var macAddressByID: [String: String] = [:]
    // beaconID -> session number when config was last read from device
    @Published private(set) var lastConfigReadSession: [String: Int] = [:]
    // beaconID -> model string
    @Published private(set) var modelByID: [String: String] = [:]
    // beaconID -> firmware version
    @Published private(set) var firmwareByID: [String: String] = [:]
    
    // Current session number (incremented on each app launch)
    private static let sessionNumberKey = "BeaconConfigSessionNumber"
    @Published private(set) var currentSessionNumber: Int = 0
    // Active elevation editing state
    @Published public var activeElevationEdit: ActiveElevationEdit? = nil

    // MARK: persistence key
    private let dotsV2Key = "BeaconDots_v2"  // Single source of truth

    public init() {
        incrementSessionNumber()
        
        if loadV2() {
            print("📊 [BeaconDotStore] Loaded from V2 storage")
        } else {
            print("📊 [BeaconDotStore] No V2 data found - starting fresh")
        }
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
            saveV2()
            print("Removed dot for \(beaconID)")
        } else {
            dots.append(Dot(beaconID: beaconID, color: color, mapPoint: mapPoint))
            saveV2()
            print("Added dot for \(beaconID) @ map (\(Int(mapPoint.x)), \(Int(mapPoint.y)))")
        }
    }

    /// Update a dot's map-local position (used while dragging).
    public func updateDot(id: UUID, to newPoint: CGPoint) {
        if let idx = dots.firstIndex(where: { $0.id == id }) {
            dots[idx].mapPoint = newPoint
            saveV2()
        }
    }

    public func clear() {
        dots.removeAll()
        saveV2()
    }
    
    /// Clear dots for unlocked beacons only (preserves locked beacons)
    public func clearUnlockedDots() {
        dots.removeAll { !isLocked($0.beaconID) }
        saveV2()
    }
    
    /// Get only the locked beacon dots
    public func lockedDots() -> [Dot] {
        return dots.filter { isLocked($0.beaconID) }
    }
    
    
    // MARK: - Elevation API
    
    public func setElevation(for beaconID: String, elevation: Double) {
        elevations[beaconID] = elevation
        saveV2()
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
        saveV2()
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
        saveV2()
    }
    
    public func getAdvertisingInterval(for beaconID: String) -> Double {
        let result = advertisingIntervalByID[beaconID] ?? defaultAdvertisingInterval
        return result
    }
    
    public func displayAdvertisingInterval(for beaconID: String) -> String {
        let interval = getAdvertisingInterval(for: beaconID)
        
        // Format with up to 2 decimal places
        let formatted = String(format: "%.2f", interval)
        
        // Remove trailing zeros and unnecessary decimal point
        var trimmed = formatted
        while trimmed.hasSuffix("0") {
            trimmed.removeLast()
        }
        if trimmed.hasSuffix(".") {
            trimmed.removeLast()
        }
        
        return trimmed + " ms"
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
        macAddressByID.removeAll()
        lastConfigReadSession.removeAll()
        modelByID.removeAll()
        firmwareByID.removeAll()

        // Load from V2 only
        if loadV2() {
            print("📊 [BeaconDotStore] Reloaded from V2 storage")
        } else {
            print("📊 [BeaconDotStore] No V2 data for this location")
        }
        
        // Remove any dots that don't correspond to active beacons
        removeOrphanedDots()
        
        objectWillChange.send()
    }
    
    /// Get the beacon IDs that are currently locked
    public func lockedBeaconIDs() -> [String] {
        locked.keys.filter { locked[$0] == true }
    }
    
    /// Remove dots that don't have a corresponding beacon in the active beacon list
    /// Also cleans up orphaned metadata (locks, elevations, txPower, advertising intervals)
    /// Returns the count of removed dots
    @discardableResult
    public func removeOrphanedDots(validBeaconNames: [String]? = nil) -> Int {
        let validNames: [String]
        if let names = validBeaconNames {
            validNames = names
        } else {
            validNames = BeaconDotRegistry.sharedBeaconNames?() ?? []
        }
        
        // If we can't get the beacon list, don't remove anything
        guard !validNames.isEmpty else {
            print("⚠️ [BeaconDotStore] Cannot reconcile - no beacon names available")
            return 0
        }
        
        let orphanedDots = dots.filter { !validNames.contains($0.beaconID) }
        
        guard !orphanedDots.isEmpty else { return 0 }
        
        print("🧹 [BeaconDotStore] Found \(orphanedDots.count) orphaned dot(s):")
        for dot in orphanedDots {
            print("   - \(dot.beaconID) @ (\(Int(dot.mapPoint.x)), \(Int(dot.mapPoint.y)))")
        }
        
        // Remove the dots
        let orphanedIDs = Set(orphanedDots.map { $0.beaconID })
        dots.removeAll { orphanedIDs.contains($0.beaconID) }
        
        // Clean up orphaned metadata
        for beaconID in orphanedIDs {
            locked.removeValue(forKey: beaconID)
            elevations.removeValue(forKey: beaconID)
            txPowerByID.removeValue(forKey: beaconID)
            advertisingIntervalByID.removeValue(forKey: beaconID)
            macAddressByID.removeValue(forKey: beaconID)
            lastConfigReadSession.removeValue(forKey: beaconID)
            modelByID.removeValue(forKey: beaconID)
            firmwareByID.removeValue(forKey: beaconID)
        }
        
        // Save changes
        saveV2()
        
        print("🧹 [BeaconDotStore] Removed \(orphanedDots.count) orphaned dot(s) and their metadata")
        
        return orphanedDots.count
    }

    // MARK: - Lock API

    public func isLocked(_ beaconID: String) -> Bool {
        locked[beaconID] ?? false
    }

    public func toggleLock(_ beaconID: String) {
        let newVal = !(locked[beaconID] ?? false)
        locked[beaconID] = newVal
        saveV2()
    }

    // MARK: - V2 Consolidated Persistence

    /// Save all beacon dot data to single UserDefaults key
    private func saveV2() {
        let v2Dots: [BeaconDotV2] = dots.map { dot in
            var v2 = BeaconDotV2(
                beaconID: dot.beaconID,
                x: dot.mapPoint.x,
                y: dot.mapPoint.y,
                elevation: elevations[dot.beaconID] ?? dot.elevation
            )
            v2.txPower = txPowerByID[dot.beaconID]
            v2.advertisingInterval = advertisingIntervalByID[dot.beaconID]
            v2.isLocked = locked[dot.beaconID] ?? false
            v2.macAddress = macAddressByID[dot.beaconID]
            v2.model = modelByID[dot.beaconID]
            v2.firmware = firmwareByID[dot.beaconID]
            v2.lastConfigReadSession = lastConfigReadSession[dot.beaconID]
            return v2
        }
        
        ctx.write(dotsV2Key, value: v2Dots)
        print("💾 [BeaconDotStore] Saved \(v2Dots.count) dots to \(dotsV2Key)")
    }

    /// Load all beacon dot data from single UserDefaults key
    /// Returns true if V2 data was found, false if migration needed
    private func loadV2() -> Bool {
        guard let v2Dots: [BeaconDotV2] = ctx.read(dotsV2Key, as: [BeaconDotV2].self), !v2Dots.isEmpty else {
            return false
        }
        
        // Clear existing in-memory state
        dots.removeAll()
        locked.removeAll()
        elevations.removeAll()
        txPowerByID.removeAll()
        advertisingIntervalByID.removeAll()
        macAddressByID.removeAll()
        lastConfigReadSession.removeAll()
        modelByID.removeAll()
        firmwareByID.removeAll()
        
        // Populate from V2 data
        for v2 in v2Dots {
            var dot = Dot(
                beaconID: v2.beaconID,
                color: beaconColor(for: v2.beaconID),
                mapPoint: CGPoint(x: v2.x, y: v2.y)
            )
            dot.elevation = v2.elevation
            dots.append(dot)
            
            // Populate side tables
            if v2.isLocked {
                locked[v2.beaconID] = true
            }
            elevations[v2.beaconID] = v2.elevation
            if let tx = v2.txPower {
                txPowerByID[v2.beaconID] = tx
            }
            if let interval = v2.advertisingInterval {
                advertisingIntervalByID[v2.beaconID] = interval
            }
            if let mac = v2.macAddress {
                macAddressByID[v2.beaconID] = mac
            }
            if let model = v2.model {
                modelByID[v2.beaconID] = model
            }
            if let firmware = v2.firmware {
                firmwareByID[v2.beaconID] = firmware
            }
            if let session = v2.lastConfigReadSession {
                lastConfigReadSession[v2.beaconID] = session
            }
        }
        
        print("📂 [BeaconDotStore] Loaded \(dots.count) dots from \(dotsV2Key)")
        return true
    }
    
    // MARK: - Session Number Management
    
    private func incrementSessionNumber() {
        // Global session counter (not location-scoped)
        let key = Self.sessionNumberKey
        currentSessionNumber = UserDefaults.standard.integer(forKey: key) + 1
        UserDefaults.standard.set(currentSessionNumber, forKey: key)
        print("📊 [BeaconDotStore] Session #\(currentSessionNumber)")
    }
    
    // MARK: - Bulk Update from Beacon Config
    
    /// Update beacon metadata from a device config read
    /// Called by Beacon Report after successfully reading from device
    public func updateFromDeviceConfig(
        beaconName: String,
        txPower: Int,
        intervalMs: Float,
        mac: String?,
        model: String?,
        firmware: String?
    ) {
        // Update TX Power
        txPowerByID[beaconName] = txPower
        
        // Update Interval
        advertisingIntervalByID[beaconName] = Double(intervalMs)
        
        // Update MAC
        if let mac = mac, !mac.isEmpty {
            macAddressByID[beaconName] = mac
        }
        
        // Update Model
        if let model = model {
            modelByID[beaconName] = model
        }
        
        // Update Firmware
        if let firmware = firmware {
            firmwareByID[beaconName] = firmware
        }
        
        // Mark as read this session
        lastConfigReadSession[beaconName] = currentSessionNumber
        
        // Single save for all updates
        saveV2()
        
        print("📊 [BeaconDotStore] Updated \(beaconName): TX=\(txPower)dBm, Interval=\(Int(intervalMs))ms, Session=\(currentSessionNumber)")
    }
    
    // MARK: - Freshness API
    
    /// Returns how many sessions ago this beacon's config was read
    /// Returns nil if never read from device
    public func sessionsSinceLastRead(for beaconID: String) -> Int? {
        guard let lastSession = lastConfigReadSession[beaconID] else { return nil }
        return currentSessionNumber - lastSession
    }
    
    /// Returns a color indicating freshness of beacon config data
    /// Green = just read, Yellow = 1 session ago, Orange = 2, Red = 3+, Dark Red = 10+
    public func freshnessColor(for beaconID: String) -> Color {
        guard let sessionsDelta = sessionsSinceLastRead(for: beaconID) else {
            return Color.gray.opacity(0.5) // Never read from device
        }
        
        switch sessionsDelta {
        case 0:
            return Color.green
        case 1:
            return Color.yellow
        case 2:
            return Color.orange
        case 3...9:
            return Color.red
        default: // 10+
            return Color(red: 0.5, green: 0, blue: 0) // Dark red
        }
    }
    
    private func beaconColor(for beaconID: String) -> Color {
        let hash = beaconID.hash
        let hue = Double(abs(hash % 360)) / 360.0
        return Color(hue: hue, saturation: 0.7, brightness: 0.8)
    }
}
