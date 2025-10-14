//
//  BeaconStateManager.swift
//  TapResolver
//
//  Created for beacon state consolidation
//
//  ARCHITECTURAL PURPOSE:
//  This store acts as the SINGLE SOURCE OF TRUTH for live Bluetooth beacon state.
//  It replaces the previous pattern where multiple UI components independently
//  polled BluetoothScanner.devices at different rates with different staleness logic.
//
//  RESPONSIBILITIES:
//  - Monitors BluetoothScanner.devices on a fixed 0.5s interval
//  - Applies consistent 3-second staleness window to all beacons
//  - Publishes unified beacon state that all UI components observe
//  - Eliminates duplicate timer logic across RSSILabelsOverlay and ScanQualityViewModel
//

import SwiftUI
import Combine

@MainActor
final class BeaconStateManager: ObservableObject {
    
    // MARK: - Live Beacon Model
    
    /// Represents a Bluetooth beacon with consistent staleness tracking.
    /// This is the canonical representation of beacon state used throughout the app.
    /// Equatable conformance required for SwiftUI .onChange() observation.
    struct LiveBeacon: Identifiable, Equatable {
        let id = UUID()
        let beaconID: String        // Device name (e.g., "05-bouncyLynx")
        let name: String            // Same as beaconID for now
        var rssi: Int               // Signal strength in dBm
        var txPower: Int?           // Advertised transmission power
        var lastSeen: Date          // Timestamp of last BLE advertisement
        var isActive: Bool          // True if seen within staleness window
    }
    
    // MARK: - Published State
    
    /// Dictionary of all known beacons, keyed by beaconID.
    /// UI components should observe this for beacon state changes.
    @Published private(set) var liveBeacons: [String: LiveBeacon] = [:]
    
    /// Set of beaconIDs that are currently active (within staleness window).
    /// Useful for quick membership checks without iterating liveBeacons.
    @Published private(set) var activeBeaconIDs: Set<String> = []
    
    // MARK: - Configuration
    
    /// How long before a beacon is considered "stale" (not actively detected).
    /// Consistent 3-second window used across all consumers.
    private let stalenessWindow: TimeInterval = 3.0
    
    /// Update interval for polling BluetoothScanner.
    /// 0.5s matches the previous RSSILabelsOverlay polling rate.
    private let updateInterval: TimeInterval = 0.5
    
    // MARK: - Private State
    
    private var updateTimer: Timer?
    private weak var scanner: BluetoothScanner?
    
    // MARK: - Lifecycle
    
    /// Starts monitoring the BluetoothScanner and updating beacon state.
    /// Called once during app bootstrap (AppBootstrap.swift).
    ///
    /// - Parameter scanner: The BluetoothScanner instance to monitor
    func startMonitoring(scanner: BluetoothScanner) {
        self.scanner = scanner
        
        // Perform initial update immediately
        updateLiveBeacons()
        
        // Schedule periodic updates
        updateTimer = Timer.scheduledTimer(
            withTimeInterval: updateInterval,
            repeats: true
        ) { [weak self] _ in
            self?.updateLiveBeacons()
        }
    }
    
    deinit {
        updateTimer?.invalidate()
    }
    
    // MARK: - State Updates
    
    /// Core update loop: rebuilds beacon state from BluetoothScanner.devices.
    /// Called every 0.5s by the timer.
    ///
    /// ARCHITECTURAL NOTE:
    /// This method is the ONLY place where beacon active/inactive state is determined.
    /// All UI components get consistent state by observing @Published properties.
    private func updateLiveBeacons() {
        guard let scanner = scanner else { return }
        
        let now = Date()
        var newLive: [String: LiveBeacon] = [:]
        var newActive: Set<String> = []
        
        // Rebuild state from scanner's current device list
        for device in scanner.devices {
            let timeSinceLastSeen = now.timeIntervalSince(device.lastSeen)
            let isActive = timeSinceLastSeen < stalenessWindow
            
            let beacon = LiveBeacon(
                beaconID: device.name,
                name: device.name,
                rssi: device.rssi,
                txPower: device.txPower,
                lastSeen: device.lastSeen,
                isActive: isActive
            )
            
            newLive[device.name] = beacon
            
            if isActive {
                newActive.insert(device.name)
            }
        }
        
        // Publish updated state
        // SwiftUI views observing these properties will automatically update
        liveBeacons = newLive
        activeBeaconIDs = newActive
    }
    
    // MARK: - Public Query API
    
    /// Retrieves a specific beacon by ID.
    ///
    /// - Parameter beaconID: The beacon identifier (device name)
    /// - Returns: LiveBeacon if known, nil otherwise
    func beacon(named beaconID: String) -> LiveBeacon? {
        return liveBeacons[beaconID]
    }
    
    /// Checks if a beacon is currently active (within staleness window).
    ///
    /// - Parameter beaconID: The beacon identifier to check
    /// - Returns: True if beacon is active, false otherwise
    func isActive(_ beaconID: String) -> Bool {
        return activeBeaconIDs.contains(beaconID)
    }
    
    /// Returns all currently active beacons.
    ///
    /// - Returns: Array of LiveBeacon instances that are active
    func activeBeacons() -> [LiveBeacon] {
        return liveBeacons.values.filter { $0.isActive }
    }
}

