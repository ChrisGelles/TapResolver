//
//  SimpleBeaconLogger.swift
//  TapResolver
//
//  Created by restructuring on 9/25/25.
//

import Foundation
import Combine
import UIKit

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
    let packetsPerSecond: Double
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
    
    // Device/app context
    let deviceModel: String
    let osVersion: String
    let appVersion: String
    let userHeight_m: Double?
    let mode: String?   // "walking" | "reading" | nil
    
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
    
    // Device/app context
    private var _deviceModel = ""
    private var _osVersion = ""
    private var _appVersion = ""
    private var _userHeightM: Double?
    private var _mode: String?
    
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
        beaconDotStore: BeaconDotStore,
        scanUtility: MapPointScanUtility
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
        
        // Capture device/app context
        let deviceModel = UIDevice.current.model + " " + UIDevice.current.systemName
        let osVersion = UIDevice.current.systemVersion
        let appVersion = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0") +
                        " (" + (Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?") + ")"
        self._deviceModel = deviceModel
        self._osVersion = osVersion
        self._appVersion = appVersion
        self._userHeightM = 1.05 // Default user height assumption
        self._mode = nil // Optional mode
        
        scanUtility.startScan(
            pointID: mapPointID,
            mapX_m: coordinates.x,
            mapY_m: coordinates.y,
            userHeight_m: _userHeightM ?? 1.05,
            sessionID: sessionID,
            durationSeconds: duration
        )
        
        print("🔍 Started beacon logging session: \(sessionID)")
        print("   Map Point: \(mapPointID) at (\(Int(coordinates.x)), \(Int(coordinates.y)))")
        print("   Duration: \(Int(duration))s, Interval: \(Int(intervalMs))ms")
        
        // Start continuous BLE scanning if not already running
        if !btScanner.isScanning {
            btScanner.start()
        }
        
        // Start countdown timer
        startCountdownTimer()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.05) { [weak self] in
            guard let self = self, let record = scanUtility.lastScanRecord else { return }
            // Build BeaconLogSession compatible payload from ScanUtility aggregates:
            let startTime = ISO8601DateFormatter().date(from: record.timingStartISO) ?? Date()
            let endTime   = ISO8601DateFormatter().date(from: record.timingEndISO) ?? Date()

            var obinArrays: [String: [Int]] = [:]
            var stats: [String: BeaconStats] = [:]

            for agg in record.beacons {
                let name = agg.beacon.name ?? agg.beacon.beaconID
                obinArrays[name] = agg.obin.counts
                let samples = agg.samples
                let dur = max(record.duration_s, 0.001)
                let pps = Double(samples) / dur
                let s = BeaconStats(
                    samples: samples,
                    packetsPerSecond: pps,
                    medianDbm: agg.medianDbm,
                    p10Dbm: agg.p10Dbm,
                    p90Dbm: agg.p90Dbm,
                    madDb: agg.madDb
                )
                stats[name] = s
            }

            let session = BeaconLogSession(
                sessionID: self.sessionID,
                duration: record.duration_s,
                mapPointID: record.point.pointID,
                coordinatesX: record.point.mapX_m,
                coordinatesY: record.point.mapY_m,
                interval: self.interval * 1000.0,
                startTime: startTime,
                endTime: endTime,
                obinsPerBeacon: obinArrays,
                statsPerBeacon: stats,
                deviceModel: self._deviceModel,
                osVersion: self._osVersion,
                appVersion: self._appVersion,
                userHeight_m: self._userHeightM,
                mode: self._mode
            )
            self.lastSession = session
            ScanPersistence.saveSession(session)
            self.isLogging = false
        }
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
        let durationSec = endTime.timeIntervalSince(startTime)
        let minSamples = 10  // tweak later if you want

        for (beaconID, o) in obins {
            obinArrays[beaconID] = o.counts
            let pps = durationSec > 0 ? Double(o.total) / durationSec : 0.0

            // Guard: if too few samples, don't trust dispersion stats yet
            let med = (o.total >= minSamples) ? o.medianDbm : nil
            let p10 = (o.total >= minSamples) ? o.p10Dbm : nil
            let p90 = (o.total >= minSamples) ? o.p90Dbm : nil
            let mad = (o.total >= minSamples) ? o.madDb(relativeTo: med) : nil

            let s = BeaconStats(
                samples: o.total,
                packetsPerSecond: pps,
                medianDbm: med,
                p10Dbm: p10,
                p90Dbm: p90,
                madDb: mad
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
            statsPerBeacon: stats,
            deviceModel: _deviceModel,
            osVersion: _osVersion,
            appVersion: _appVersion,
            userHeight_m: _userHeightM,
            mode: _mode
        )
        lastSession = session
        
        // Save session to JSON
        ScanPersistence.saveSession(session)
        
        // Cleanup
        obins.removeAll()
        btScanner?.simpleLogger = nil
        
        print("✅ Completed beacon logging session: \(sessionID)")
        print("   Collected data for \(obinArrays.count) beacons")
        for (beaconName, s) in stats.sorted(by: { $0.key < $1.key }) {
            if s.samples < 10 {
                print("   • \(beaconName): \(s.samples) samples — insufficient data (<10)")
            } else {
                print("   • \(beaconName): \(s.samples) samples, median: \(s.medianDbm ?? -999) dBm, \(String(format: "%.2f", s.packetsPerSecond)) pkt/s")
            }
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
    
}
