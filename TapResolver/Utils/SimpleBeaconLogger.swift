//
//  SimpleBeaconLogger.swift
//  TapResolver
//
//  Created by restructuring on 9/25/25.
//

import Foundation
import Combine

// MARK: - Data Structures

// Compact histogram of RSSI (−100...−30 dBm, 1 dB bins)
fileprivate struct Obin: Codable {
    static let minDbm = -100, maxDbm = -30, step = 1
    var counts = Array(repeating: 0, count: 71) // inclusive range: -100...-30

    mutating func add(_ rssi: Int) {
        guard rssi >= Self.minDbm, rssi <= Self.maxDbm else { return }
        let idx = (rssi - Self.minDbm) / Self.step
        counts[idx] &+= 1
    }
    var total: Int { counts.reduce(0, +) }

    // Quantile (0...1) using cumulative counts
    func quantileDbm(_ q: Double) -> Int? {
        let n = total; guard n > 0 else { return nil }
        let target = Int(Double(n - 1) * q)
        var cum = 0
        for (i, c) in counts.enumerated() {
            cum += c
            if cum > target { return Self.minDbm + i * Self.step }
        }
        return nil
    }
    var medianDbm: Int? { quantileDbm(0.5) }
    var p10Dbm:   Int? { quantileDbm(0.10) }
    var p90Dbm:   Int? { quantileDbm(0.90) }

    func madDb(relativeTo median: Int?) -> Double? {
        guard let m = median, total > 0 else { return nil }
        // Build deviation histogram
        var devs: [Int:Int] = [:]
        for (i, c) in counts.enumerated() where c > 0 {
            let v = Self.minDbm + i * Self.step
            let d = abs(v - m)
            devs[d, default: 0] &+= c
        }
        // Median of deviations
        let target = (total - 1) / 2
        var cum = 0
        for d in devs.keys.sorted() {
            cum += devs[d]!
            if cum > target { return Double(d) }
        }
        return nil
    }
}

struct BeaconStats: Codable {
    let samples: Int
    let medianDbm: Int?
    let p10Dbm: Int?
    let p90Dbm: Int?
    let madDb: Double?
}

struct BeaconLogSession: Codable {
    let sessionID: String
    let duration: TimeInterval
    let mapPointID: String
    let coordinatesX: Double
    let coordinatesY: Double
    let interval: TimeInterval // ms between snapshots (kept for compatibility)
    let startTime: Date
    let endTime: Date

    // NEW: compact data
    let obinsPerBeacon: [String: [Int]]   // beaconID -> 71 counts
    let statsPerBeacon: [String: BeaconStats]
    
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
    private var obins: [String: Obin] = [:]
    private var timer: Timer?
    private var countdownTimer: Timer?
    
    // MARK: - Dependencies (will be injected)
    private var btScanner: BluetoothScanner?
    private var beaconLists: BeaconListsStore?
    private var beaconDotStore: BeaconDotStore?
    
    // MARK: - Public Interface
    
    func ingest(beaconID: String, rssiDbm: Int, txPowerDbm: Int?, timestamp: TimeInterval) {
        guard isLogging else { return }
        // Only collect for beacons that are "active" (same rule as before)
        // If you want to filter here via BeaconLists/BeaconDots, you can—right now
        // BluetoothScanner already filters by name you care about.
        var b = obins[beaconID] ?? Obin()
        b.add(rssiDbm)
        obins[beaconID] = b
    }
    
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
        self.obins = [:]
        self.secondsRemaining = duration
        self.isLogging = true
        
        // Attach per-ad ingest
        btScanner.simpleLogger = self
        
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
        
        // Build obins payload
        var obinArrays: [String: [Int]] = [:]
        var stats: [String: BeaconStats] = [:]
        for (beaconID, o) in obins {
            obinArrays[beaconID] = o.counts
            let med = o.medianDbm
            let s = BeaconStats(
                samples: o.total,
                medianDbm: med,
                p10Dbm: o.p10Dbm,
                p90Dbm: o.p90Dbm,
                madDb: o.madDb(relativeTo: med)
            )
            stats[beaconID] = s
        }
        
        let session = BeaconLogSession(
            sessionID: sessionID,
            duration: duration,
            mapPointID: mapPointID,
            coordinatesX: coordinates.x,
            coordinatesY: coordinates.y,
            interval: interval * 1000.0,
            startTime: startTime,
            endTime: endTime,
            obinsPerBeacon: obinArrays,
            statsPerBeacon: stats
        )
        lastSession = session
        
        // Cleanup
        obins.removeAll()
        btScanner?.simpleLogger = nil
        
        print("✅ Completed beacon logging session: \(sessionID)")
        print("   Collected data for \(obinArrays.count) beacons")
        for (beaconName, stats) in stats {
            print("   • \(beaconName): \(stats.samples) samples, median: \(stats.medianDbm ?? -999) dBm")
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
                // Add RSSI value to obin
                var b = obins[beaconName] ?? Obin()
                b.add(device.rssi)
                obins[beaconName] = b
                
                // Debug output for first few samples
                if let count = obins[beaconName]?.total, count <= 3 {
                    print("📡 Collected RSSI: \(beaconName) = \(device.rssi) dBm (sample \(count))")
                }
            }
        }
    }
}
