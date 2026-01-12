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
    // MARK: - V2 Persistence Model (Single Source of Truth)

    /// Tracks when beacon radio settings were last changed in the app
    public struct ConfigChangeInfo: Codable, Equatable {
        public let timestamp: Double    // Unix timestamp (seconds since 1970)
        public let changed: String      // "txPower", "interval", or "both"
        
        public init(timestamp: Double, changed: String) {
            self.timestamp = timestamp
            self.changed = changed
        }
    }

    /// Consolidated beacon dot storage - single source of truth
    public struct BeaconDotV2: Codable, Identifiable {
        public var id: String { beaconID }  // Identifiable conformance
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
        public var lastConfigChange: ConfigChangeInfo?
        
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
        
        /// Computed map point for UI compatibility
        public var mapPoint: CGPoint {
            get { CGPoint(x: x, y: y) }
            set { x = newValue.x; y = newValue.y }
        }
        
        /// Computed color based on beaconID hash
        public var color: Color {
            let hash = beaconID.hash
            let hue = Double(abs(hash % 360)) / 360.0
            return Color(hue: hue, saturation: 0.7, brightness: 0.8)
        }
    }

    /// Single source of truth - all beacon data lives here
    @Published public private(set) var dots: [BeaconDotV2] = []

    private let defaultAdvertisingInterval: Double = 100.0  // BC04P default
    
    // Current session number (incremented on each app launch)
    private static let sessionNumberKey = "BeaconConfigSessionNumber"
    @Published private(set) var currentSessionNumber: Int = 0
    // Active elevation editing state
    @Published public var activeElevationEdit: ActiveElevationEdit? = nil

    // MARK: persistence key
    private let dotsV2Key = "BeaconDots_v2"  // Single source of truth

    public init() {
        let locationID = ctx.locationID
        print("🏗️ [BeaconDotStore] INIT")
        print("   📍 Initial location: \(locationID)")
        
        incrementSessionNumber()
        
        if load() {
            print("📊 [BeaconDotStore] Loaded from V2 storage")
        } else {
            print("📊 [BeaconDotStore] No V2 data found - starting fresh")
        }
    }

    public func dot(for beaconID: String) -> BeaconDotV2? {
        dots.first { $0.beaconID == beaconID }
    }

    /// Toggle a dot for a beacon:
    /// - If it exists, remove it.
    /// - If not, add at `mapPoint` with `color`.
    public func toggleDot(for beaconID: String, mapPoint: CGPoint, color: Color) {
        if let idx = dots.firstIndex(where: { $0.beaconID == beaconID }) {
            // Remove existing dot
            dots.remove(at: idx)
        } else {
            // Add new dot
            let dot = BeaconDotV2(beaconID: beaconID, x: mapPoint.x, y: mapPoint.y)
            dots.append(dot)
        }
        save()
    }

    /// Update a dot's map-local position (used while dragging).
    public func updateDot(for beaconID: String, newMapPoint: CGPoint) {
        if let idx = dots.firstIndex(where: { $0.beaconID == beaconID }) {
            dots[idx].x = newMapPoint.x
            dots[idx].y = newMapPoint.y
            save()
        }
    }

    public func clear() {
        dots.removeAll()
        save()
    }
    
    /// Clear dots for unlocked beacons only (preserves locked beacons)
    public func clearUnlockedDots() {
        dots.removeAll { !$0.isLocked }
        save()
    }
    
    /// Get only the locked beacon dots
    public func lockedDots() -> [BeaconDotV2] {
        return dots.filter { $0.isLocked }
    }
    
    
    // MARK: - Elevation API
    
    public func setElevation(for beaconID: String, elevation: Double) {
        if let idx = dots.firstIndex(where: { $0.beaconID == beaconID }) {
            dots[idx].elevation = elevation
            save()
        }
    }
    
    public func getElevation(for beaconID: String) -> Double {
        return dots.first { $0.beaconID == beaconID }?.elevation ?? 0.75
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
        if let idx = dots.firstIndex(where: { $0.beaconID == beaconID }) {
            let oldValue = dots[idx].txPower
            dots[idx].txPower = dbm
            
            // Record change if value actually changed
            if oldValue != dbm {
                recordConfigChange(at: idx, field: "txPower")
            }
            
            save()
        }
    }
    
    public func getTxPower(for beaconID: String) -> Int? {
        return dots.first { $0.beaconID == beaconID }?.txPower
    }
    
    // MARK: - Advertising Interval API
    
    public func setAdvertisingInterval(for beaconID: String, ms: Double?) {
        if let idx = dots.firstIndex(where: { $0.beaconID == beaconID }) {
            let oldValue = dots[idx].advertisingInterval
            dots[idx].advertisingInterval = ms
            
            // Record change if value actually changed
            if oldValue != ms {
                recordConfigChange(at: idx, field: "interval")
            }
            
            save()
        }
    }
    
    public func getAdvertisingInterval(for beaconID: String) -> Double {
        return dots.first { $0.beaconID == beaconID }?.advertisingInterval ?? defaultAdvertisingInterval
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
    
    // MARK: - Config Change Tracking
    
    /// Records when a radio setting (txPower or interval) was changed
    /// If both fields change in rapid succession, updates to "both"
    private func recordConfigChange(at idx: Int, field: String) {
        let now = Date().timeIntervalSince1970
        
        // Check if there's a recent change (within 5 seconds) - might be updating both
        if let existing = dots[idx].lastConfigChange {
            let elapsed = now - existing.timestamp
            if elapsed < 5.0 && existing.changed != field && existing.changed != "both" {
                // Recent change to the OTHER field - mark as "both"
                dots[idx].lastConfigChange = ConfigChangeInfo(timestamp: now, changed: "both")
                return
            }
        }
        
        dots[idx].lastConfigChange = ConfigChangeInfo(timestamp: now, changed: field)
    }
    
    /// Reload data for the active location
    public func reloadForActiveLocation() {
        clearAndReloadForActiveLocation()
    }
    
    /// Public flush+reload for location switching
    public func clearAndReloadForActiveLocation() {
        let locationID = ctx.locationID
        print("🔄 [BeaconDotStore] clearAndReloadForActiveLocation() called")
        print("   📍 Target location: \(locationID)")
        print("   📊 Dots before clear: \(dots.count)")
        
        // Clear in-memory state
        dots.removeAll()
        
        // Load from V2
        if load() {
            print("📊 [BeaconDotStore] Reloaded from V2 storage")
        } else {
            print("📊 [BeaconDotStore] No V2 data for this location")
        }
        
        print("   📊 Dots after reload: \(dots.count)")
        objectWillChange.send()
    }
    
    /// Get the beacon IDs that are currently locked
    public func lockedBeaconIDs() -> [String] {
        dots.filter { $0.isLocked }.map(\.beaconID)
    }
    
    /// Remove dots that don't have a corresponding beacon in the active beacon list
    public func removeOrphanedDots() {
        guard let beaconNames = BeaconDotRegistry.sharedBeaconNames?() else {
            print("⚠️ [BeaconDotStore] Cannot reconcile - no beacon names available")
            return
        }
        
        let validSet = Set(beaconNames)
        let orphaned = dots.filter { !validSet.contains($0.beaconID) }
        
        guard !orphaned.isEmpty else { return }
        
        print("🧹 [BeaconDotStore] Found \(orphaned.count) orphaned dot(s):")
        for dot in orphaned {
            print("   - \(dot.beaconID) @ (\(Int(dot.x)), \(Int(dot.y)))")
        }
        
        dots.removeAll { !validSet.contains($0.beaconID) }
        save()
        
        print("🧹 [BeaconDotStore] Removed \(orphaned.count) orphaned dot(s)")
    }

    // MARK: - Lock API

    public func isLocked(_ beaconID: String) -> Bool {
        dots.first { $0.beaconID == beaconID }?.isLocked ?? false
    }

    public func toggleLock(_ beaconID: String) {
        if let idx = dots.firstIndex(where: { $0.beaconID == beaconID }) {
            dots[idx].isLocked.toggle()
            save()
        }
    }
    
    public func lock(_ beaconID: String) {
        if let idx = dots.firstIndex(where: { $0.beaconID == beaconID }) {
            dots[idx].isLocked = true
            save()
        }
    }

    // MARK: - V2 Consolidated Persistence

    private func save() {
        let locationID = ctx.locationID
        let fullKey = "locations.\(locationID).\(dotsV2Key)"
        
        // Diagnostic: Log what we're about to save
        print("💾 [BeaconDotStore] SAVE to '\(fullKey)'")
        print("   📍 Location: \(locationID)")
        print("   📊 Dot count: \(dots.count)")
        if !dots.isEmpty {
            let sample = dots.prefix(3).map { "\($0.beaconID): elev=\($0.elevation)" }.joined(separator: ", ")
            print("   📋 Sample: \(sample)\(dots.count > 3 ? "..." : "")")
        }
        
        ctx.write(dotsV2Key, value: dots)
    }

    private func load() -> Bool {
        let locationID = ctx.locationID
        let fullKey = "locations.\(locationID).\(dotsV2Key)"
        
        print("📂 [BeaconDotStore] LOAD from '\(fullKey)'")
        print("   📍 Location: \(locationID)")
        
        guard let loaded: [BeaconDotV2] = ctx.read(dotsV2Key, as: [BeaconDotV2].self), !loaded.isEmpty else {
            print("   ❌ No data found or empty")
            return false
        }
        
        dots = loaded
        
        // Diagnostic: Log what we loaded
        print("   ✅ Loaded \(dots.count) dots")
        for dot in dots {
            print("      - \(dot.beaconID): pos=(\(Int(dot.x)),\(Int(dot.y))) elev=\(dot.elevation) tx=\(dot.txPower ?? -999) interval=\(dot.advertisingInterval ?? -1)")
        }
        
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
        guard let idx = dots.firstIndex(where: { $0.beaconID == beaconName }) else {
            print("⚠️ [BeaconDotStore] Cannot update config for unknown beacon: \(beaconName)")
            return
        }
        
        let oldTx = dots[idx].txPower
        let oldInterval = dots[idx].advertisingInterval
        
        dots[idx].txPower = txPower
        dots[idx].advertisingInterval = Double(intervalMs)
        
        // Record config change timestamp
        let txChanged = oldTx != txPower
        let intervalChanged = oldInterval != Double(intervalMs)
        if txChanged || intervalChanged {
            let changed: String
            if txChanged && intervalChanged {
                changed = "both"
            } else if txChanged {
                changed = "txPower"
            } else {
                changed = "interval"
            }
            dots[idx].lastConfigChange = ConfigChangeInfo(
                timestamp: Date().timeIntervalSince1970,
                changed: changed
            )
        }
        
        if let mac = mac, !mac.isEmpty {
            dots[idx].macAddress = mac
        }
        if let model = model {
            dots[idx].model = model
        }
        if let firmware = firmware {
            dots[idx].firmware = firmware
        }
        
        dots[idx].lastConfigReadSession = currentSessionNumber
        
        save()
        
        print("✅ [BeaconDotStore] Updated config for \(beaconName): tx=\(txPower)dBm, interval=\(intervalMs)ms")
    }
    
    // MARK: - Freshness API
    
    /// Returns how many sessions ago this beacon's config was read
    /// Returns nil if never read from device
    public func sessionsSinceLastRead(for beaconID: String) -> Int? {
        guard let dot = dots.first(where: { $0.beaconID == beaconID }),
              let lastSession = dot.lastConfigReadSession else { return nil }
        return currentSessionNumber - lastSession
    }
    
    /// Returns a color indicating freshness of beacon config data
    /// Green = just read, Yellow = 1 session ago, Orange = 2, Red = 3+
    public func freshnessColor(for beaconID: String) -> Color {
        guard let dot = dots.first(where: { $0.beaconID == beaconID }),
              let readSession = dot.lastConfigReadSession else {
            return .gray  // Never read
        }
        
        let age = currentSessionNumber - readSession
        switch age {
        case 0:
            return .green   // Read this session
        case 1:
            return .yellow  // Read last session
        case 2:
            return .orange  // Read 2 sessions ago
        default:
            return .red     // Read 3+ sessions ago
        }
    }
}
