//
//  SimpleBeaconLogger.swift
//  TapResolver
//
//  Created by restructuring on 9/25/25.
//

import Foundation
import Combine

// MARK: - Data Structures

struct BeaconLogSession: Codable {
    let sessionID: String
    let duration: TimeInterval
    let mapPointID: String
    let coordinatesX: Double
    let coordinatesY: Double
    let interval: TimeInterval // milliseconds between snapshots
    let rssiPerBeacon: [String: [Int]] // beaconName: [rssi1, rssi2, ...]
    let startTime: Date
    let endTime: Date
    
    // Convenience computed property for coordinates
    var coordinates: (x: Double, y: Double) {
        return (x: coordinatesX, y: coordinatesY)
    }
}

// MARK: - Simple Beacon Logger

@MainActor
final class SimpleBeaconLogger: ObservableObject {
    
    // MARK: - Published State
    @Published var isLogging: Bool = false
    @Published var secondsRemaining: Double = 0
    @Published var lastSession: BeaconLogSession?
    
    // MARK: - Private State
    private var sessionID: String = ""
    private var mapPointID: String = ""
    private var coordinates: (x: Double, y: Double) = (0, 0)
    private var duration: TimeInterval = 0
    private var interval: TimeInterval = 0 // milliseconds
    private var startTime: Date = Date()
    private var rssiData: [String: [Int]] = [:]
    private var timer: Timer?
    private var countdownTimer: Timer?
    
    // MARK: - Dependencies (will be injected)
    private var btScanner: BluetoothScanner?
    private var beaconLists: BeaconListsStore?
    private var beaconDotStore: BeaconDotStore?
    
    // MARK: - Public Interface
    
    /// Start logging beacon data for a map point
    func startLogging(
        mapPointID: String,
        coordinates: (x: Double, y: Double),
        duration: TimeInterval,
        intervalMs: TimeInterval,
        btScanner: BluetoothScanner,
        beaconLists: BeaconListsStore,
        beaconDotStore: BeaconDotStore
    ) {
        guard !isLogging else { return }
        
        // Store dependencies
        self.btScanner = btScanner
        self.beaconLists = beaconLists
        self.beaconDotStore = beaconDotStore
        
        // Initialize session
        self.sessionID = UUID().uuidString
        self.mapPointID = mapPointID
        self.coordinates = coordinates
        self.duration = duration
        self.interval = intervalMs / 1000.0 // Convert ms to seconds
        self.startTime = Date()
        self.rssiData = [:]
        self.secondsRemaining = duration
        self.isLogging = true
        
        print("🔍 Started beacon logging session: \(sessionID)")
        print("   Map Point: \(mapPointID) at (\(Int(coordinates.x)), \(Int(coordinates.y)))")
        print("   Duration: \(Int(duration))s, Interval: \(Int(intervalMs))ms")
        
        // Start continuous BLE scanning if not already running
        if !btScanner.isScanning {
            btScanner.start()
        }
        
        // Start countdown timer
        startCountdownTimer()
        
        // Start RSSI collection timer
        startRSSICollectionTimer()
    }
    
    /// Stop logging and return the session data
    func stopLogging() -> BeaconLogSession? {
        guard isLogging else { return nil }
        
        // Stop timers
        timer?.invalidate()
        timer = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
        
        let endTime = Date()
        isLogging = false
        
        // Create session data
        let session = BeaconLogSession(
            sessionID: sessionID,
            duration: duration,
            mapPointID: mapPointID,
            coordinatesX: coordinates.x,
            coordinatesY: coordinates.y,
            interval: interval * 1000.0, // Convert back to milliseconds
            rssiPerBeacon: rssiData,
            startTime: startTime,
            endTime: endTime
        )
        
        lastSession = session
        
        print("✅ Completed beacon logging session: \(sessionID)")
        print("   Collected data for \(rssiData.count) beacons")
        for (beaconName, rssiValues) in rssiData {
            print("   • \(beaconName): \(rssiValues.count) samples")
        }
        
        return session
    }
    
    // MARK: - Private Methods
    
    private func startCountdownTimer() {
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                let elapsed = Date().timeIntervalSince(self.startTime)
                self.secondsRemaining = max(0, self.duration - elapsed)
                
                if self.secondsRemaining <= 0 {
                    _ = self.stopLogging()
                }
            }
        }
    }
    
    private func startRSSICollectionTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.collectRSSIData()
            }
        }
        
        // Collect first sample immediately
        collectRSSIData()
    }
    
    private func collectRSSIData() {
        guard let btScanner = btScanner,
              let beaconLists = beaconLists,
              let beaconDotStore = beaconDotStore else { return }
        
        // Get beacons that are both listed and have dots on the map (same logic as RSSI labels)
        let activeBeacons = beaconLists.beacons.filter { beaconName in
            beaconDotStore.dots.contains { $0.beaconID == beaconName }
        }
        
        // Collect RSSI data for each active beacon
        for beaconName in activeBeacons {
            if let device = btScanner.devices.first(where: { $0.name == beaconName }) {
                // Initialize array if needed
                if rssiData[beaconName] == nil {
                    rssiData[beaconName] = []
                }
                
                // Add RSSI value
                rssiData[beaconName]?.append(device.rssi)
                
                // Debug output for first few samples
                if let count = rssiData[beaconName]?.count, count <= 3 {
                    print("📡 Collected RSSI: \(beaconName) = \(device.rssi) dBm (sample \(count))")
                }
            }
        }
    }
}
