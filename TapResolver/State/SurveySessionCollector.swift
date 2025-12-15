//
//  SurveySessionCollector.swift
//  TapResolver
//
//  Manages Survey Marker dwell session lifecycle.
//  Captures BLE RSSI data synchronized with device pose during dwell.
//

import Foundation
import Combine
import simd
import QuartzCore

/// Manages data collection during Survey Marker dwell sessions
@MainActor
class SurveySessionCollector: ObservableObject {
    
    // MARK: - Dependencies
    
    private weak var surveyPointStore: SurveyPointStore?
    private weak var bluetoothScanner: BluetoothScanner?
    private weak var beaconLists: BeaconListsStore?
    private var bleSubscription: AnyCancellable?
    
    // MARK: - Session State
    
    /// Currently active dwell session (nil when not dwelling)
    private var activeSession: ActiveDwellSession?
    
    /// Published for UI feedback
    @Published private(set) var isCollecting: Bool = false
    @Published private(set) var activeMarkerID: UUID?
    @Published private(set) var currentDwellTime: Double = 0.0
    
    /// Throttle tracking: beaconID -> last sample timestamp
    private var lastSampleTime: [String: TimeInterval] = [:]
    
    // MARK: - Configuration
    
    /// Minimum session duration to persist (seconds)
    static let minimumSessionDuration: Double = 3.0
    
    /// BLE sample interval: 4 Hz sampling rate (250ms)
    private let sampleIntervalSeconds: TimeInterval = 0.250
    
    // MARK: - Internal Types
    
    /// Tracks state during an active dwell session
    private struct ActiveDwellSession {
        let markerID: UUID
        let startTime: Date
        let startPose: SurveyDevicePose
        let mapCoordinate: CGPoint?
        var compassHeading: Float = 0.0
        
        // Separate tracks for pose and RSSI
        var poseTrack: [PoseSample] = []
        var beaconSamples: [String: [RssiSample]] = [:]
        
        /// Elapsed milliseconds since session start
        func elapsedMs() -> Int64 {
            Int64(Date().timeIntervalSince(startTime) * 1000)
        }
        
        /// Elapsed seconds since session start
        func elapsedSeconds() -> Double {
            Date().timeIntervalSince(startTime)
        }
    }
    
    // MARK: - Initialization
    
    init() {
        setupNotificationObservers()
        print("📊 [SurveySessionCollector] Initialized")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        print("📊 [SurveySessionCollector] Deinitialized")
    }
    
    // MARK: - Configuration
    
    /// Configure with required dependencies
    func configure(surveyPointStore: SurveyPointStore, bluetoothScanner: BluetoothScanner, beaconLists: BeaconListsStore) {
        self.surveyPointStore = surveyPointStore
        self.bluetoothScanner = bluetoothScanner
        self.beaconLists = beaconLists
        print("📊 [SurveySessionCollector] Configured with SurveyPointStore, BluetoothScanner, and BeaconListsStore (\(beaconLists.beacons.count) beacons)")
    }
    
    // MARK: - Notification Setup
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMarkerEntered(_:)),
            name: NSNotification.Name("SurveyMarkerEntered"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMarkerExited(_:)),
            name: NSNotification.Name("SurveyMarkerExited"),
            object: nil
        )
        
        print("📊 [SurveySessionCollector] Notification observers registered")
    }
    
    // MARK: - Marker Enter/Exit Handling
    
    @objc private func handleMarkerEntered(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let markerID = userInfo["markerID"] as? UUID else {
            print("⚠️ [SurveySessionCollector] Invalid enter notification - missing markerID")
            return
        }
        
        // Extract optional map coordinate
        let mapCoordinate = userInfo["mapCoordinate"] as? CGPoint
        
        // Don't start a new session if one is already active
        if activeSession != nil {
            print("⚠️ [SurveySessionCollector] Ignoring enter - session already active")
            return
        }
        
        startSession(markerID: markerID, mapCoordinate: mapCoordinate)
    }
    
    @objc private func handleMarkerExited(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let markerID = userInfo["markerID"] as? UUID else {
            print("⚠️ [SurveySessionCollector] Invalid exit notification - missing markerID")
            return
        }
        
        // Only end if this is the active session's marker
        guard let session = activeSession, session.markerID == markerID else {
            print("⚠️ [SurveySessionCollector] Ignoring exit - not the active marker")
            return
        }
        
        endSession()
    }
    
    // MARK: - Session Lifecycle
    
    private func startSession(markerID: UUID, mapCoordinate: CGPoint?) {
        let now = Date()
        
        // TODO: Milestone 4 - Get actual pose from ARKit
        let currentPose = SurveyDevicePose.identity
        
        // TODO: Milestone 5 - Get actual compass heading
        let compassHeading: Float = -1.0  // Sentinel for "unavailable"
        
        activeSession = ActiveDwellSession(
            markerID: markerID,
            startTime: now,
            startPose: currentPose,
            mapCoordinate: mapCoordinate,
            compassHeading: compassHeading
        )
        
        // Reset throttle state for new session
        lastSampleTime.removeAll()
        
        // Start listening for BLE updates
        startBLESubscription()
        
        // Update published state
        DispatchQueue.main.async {
            self.isCollecting = true
            self.activeMarkerID = markerID
            self.currentDwellTime = 0.0
        }
        
        let coordString = mapCoordinate.map { "(\(String(format: "%.1f", $0.x)), \(String(format: "%.1f", $0.y)))" } ?? "nil"
        print("📊 [SurveySessionCollector] Session STARTED for marker \(String(markerID.uuidString.prefix(8))) at map coord \(coordString)")
    }
    
    private func endSession() {
        guard let session = activeSession else {
            print("⚠️ [SurveySessionCollector] Cannot end session - no active session")
            return
        }
        
        let duration = session.elapsedSeconds()
        let markerIDShort = String(session.markerID.uuidString.prefix(8))
        
        // Check minimum duration
        if duration < Self.minimumSessionDuration {
            print("📊 [SurveySessionCollector] Session DISCARDED for marker \(markerIDShort) - duration \(String(format: "%.1f", duration))s < \(Self.minimumSessionDuration)s minimum")
            clearSession()
            return
        }
        
        // Capture session data for async processing
        let sessionCopy = session
        let storeCopy = surveyPointStore
        
        // Clear session immediately so main thread is unblocked
        clearSession()
        
        // Log completion on main thread before async work
        print("📊 [SurveySessionCollector] Session COMPLETED for marker \(markerIDShort) - duration \(String(format: "%.1f", duration))s")
        
        // Dispatch finalization to background queue
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.finalizeSession(sessionCopy, duration: duration, store: storeCopy)
        }
    }
    
    private func clearSession() {
        activeSession = nil
        stopBLESubscription()
        
        DispatchQueue.main.async {
            self.isCollecting = false
            self.activeMarkerID = nil
            self.currentDwellTime = 0.0
        }
    }
    
    // MARK: - BLE Subscription
    
    /// Start listening to BLE updates during dwell
    private func startBLESubscription() {
        guard let scanner = bluetoothScanner else {
            print("⚠️ [SurveySessionCollector] Cannot start BLE subscription - no BluetoothScanner")
            return
        }
        
        // Subscribe to device updates
        bleSubscription = scanner.$devices
            .receive(on: DispatchQueue.main)
            .sink { [weak self] devices in
                self?.handleBLEUpdate(devices: devices)
            }
        
        print("📊 [SurveySessionCollector] BLE subscription started")
    }
    
    /// Stop listening to BLE updates
    private func stopBLESubscription() {
        bleSubscription?.cancel()
        bleSubscription = nil
        print("📊 [SurveySessionCollector] BLE subscription stopped")
    }
    
    /// Handle incoming BLE device updates
    private func handleBLEUpdate(devices: [BluetoothScanner.DiscoveredDevice]) {
        let bleStart = CACurrentMediaTime()
        
        guard var session = activeSession else { return }
        
        // Get whitelist for filtering
        let whitelist = beaconLists?.beacons ?? []
        
        // Get current pose from ARKit (Milestone 4)
        // TODO: Get actual pose from ARKit via notification or shared reference
        let currentPose = SurveyDevicePose.identity
        let currentMs = session.elapsedMs()
        
        // Sample pose at same throttle rate as RSSI (4 Hz)
        // Only add pose if we're going to add at least one RSSI sample this cycle
        var willAddSamples = false
        
        let now = CACurrentMediaTime()
        
        for device in devices {
            // Use device name as beacon ID (matches BeaconListsStore convention)
            let beaconName = device.name
            
            // Skip devices without names
            guard !beaconName.isEmpty else { continue }
            
            // Skip devices not in whitelist
            guard whitelist.contains(beaconName) else { continue }
            
            let rssi = device.rssi
            
            // Skip invalid RSSI values
            guard rssi < 0 else { continue }
            
            // Throttle check: only sample at 4 Hz per beacon
            if let lastTime = lastSampleTime[beaconName], now - lastTime < sampleIntervalSeconds {
                continue  // Skip this sample, too soon
            }
            lastSampleTime[beaconName] = now
            
            ingestSample(beaconID: beaconName, rssi: rssi, ms: currentMs)
            willAddSamples = true
        }
        
        // Add pose sample if we recorded any RSSI this cycle
        if willAddSamples {
            guard var updatedSession = activeSession else { return }
            let poseSample = PoseSample(ms: currentMs, pose: currentPose)
            updatedSession.poseTrack.append(poseSample)
            activeSession = updatedSession
        }
        
        let bleDuration = (CACurrentMediaTime() - bleStart) * 1000
        if bleDuration > 5.0 {
            print("⚠️ [PERF] BLE update took \(String(format: "%.1f", bleDuration))ms for \(devices.count) devices")
        }
    }
    
    // MARK: - BLE Sample Ingestion (Milestone 3)
    
    /// Called when a BLE advertisement is received during dwell
    /// - Parameters:
    ///   - beaconID: Identifier for the beacon
    ///   - rssi: Signal strength in dBm
    ///   - ms: Milliseconds since session start
    func ingestSample(beaconID: String, rssi: Int, ms: Int64) {
        guard var session = activeSession else {
            // Not currently dwelling - ignore
            return
        }
        
        let sample = RssiSample(ms: ms, rssi: rssi)
        
        // Initialize array for this beacon if needed
        if session.beaconSamples[beaconID] == nil {
            session.beaconSamples[beaconID] = []
        }
        
        session.beaconSamples[beaconID]?.append(sample)
        activeSession = session
        
        // Update dwell time for UI
        DispatchQueue.main.async {
            self.currentDwellTime = session.elapsedSeconds()
        }
        
        // Log periodically (every 10th sample per beacon to reduce spam)
        let sampleCount = activeSession?.beaconSamples[beaconID]?.count ?? 0
        if sampleCount % 10 == 1 {
            print("📊 [BLE_SAMPLE] Beacon \(String(beaconID.prefix(8))): \(sampleCount) samples, RSSI=\(rssi)")
        }
    }
    
    // MARK: - Session Finalization
    
    private func finalizeSession(_ session: ActiveDwellSession, duration: Double, store: SurveyPointStore? = nil) {
        guard let mapCoordinate = session.mapCoordinate else {
            print("⚠️ [SurveySessionCollector] Cannot finalize - no map coordinate (test marker?)")
            return
        }
        
        guard let store = store ?? surveyPointStore else {
            print("⚠️ [SurveySessionCollector] Cannot finalize - no SurveyPointStore configured")
            return
        }
        
        // Build beacon measurements
        var beaconMeasurements: [SurveyBeaconMeasurement] = []
        
        for (beaconID, samples) in session.beaconSamples {
            // Skip beacons with only boundary markers (no actual readings)
            let validSamples = samples.filter { $0.rssi != 0 }
            if validSamples.isEmpty {
                continue
            }
            
            // Compute statistics
            let stats = computeStats(from: validSamples)
            let histogram = computeHistogram(from: validSamples)
            
            // TODO: Get actual beacon metadata from BeaconListsStore
            let meta = SurveyBeaconMeta(
                name: beaconID,
                model: "Unknown",
                txPower: nil,
                advertisingInterval_ms: nil
            )
            
            let measurement = SurveyBeaconMeasurement(
                beaconID: beaconID,
                stats: stats,
                histogram: histogram,
                samples: samples,
                meta: meta
            )
            
            beaconMeasurements.append(measurement)
        }
        
        // Create session record
        let iso8601Formatter = ISO8601DateFormatter()
        let surveySession = SurveySession(
            id: UUID().uuidString,
            locationID: store.locationID,
            startISO: iso8601Formatter.string(from: session.startTime),
            endISO: iso8601Formatter.string(from: Date()),
            duration_s: duration,
            devicePose: session.startPose,
            compassHeading_deg: session.compassHeading,
            poseTrack: session.poseTrack,
            beacons: beaconMeasurements
        )
        
        // Persist to store
        store.addSession(surveySession, atMapCoordinate: mapCoordinate)
        
        let totalRssiSamples = beaconMeasurements.reduce(0) { $0 + $1.samples.count }
        let poseCount = session.poseTrack.count
        print("📊 [SurveySessionCollector] Persisted session with \(beaconMeasurements.count) beacon(s), \(totalRssiSamples) RSSI samples, \(poseCount) pose samples")
    }
    
    // MARK: - Statistics Computation (Milestone 7 placeholder)
    
    private func computeStats(from samples: [RssiSample]) -> SurveyStats {
        let rssiValues = samples.map { $0.rssi }.sorted()
        
        guard !rssiValues.isEmpty else {
            return SurveyStats(median_dbm: 0, mad_db: 0, p10_dbm: 0, p90_dbm: 0, sampleCount: 0)
        }
        
        let count = rssiValues.count
        
        // Median
        let median: Int
        if count % 2 == 0 {
            median = (rssiValues[count/2 - 1] + rssiValues[count/2]) / 2
        } else {
            median = rssiValues[count/2]
        }
        
        // MAD (Median Absolute Deviation)
        let deviations = rssiValues.map { abs($0 - median) }.sorted()
        let mad: Int
        if count % 2 == 0 {
            mad = (deviations[count/2 - 1] + deviations[count/2]) / 2
        } else {
            mad = deviations[count/2]
        }
        
        // Percentiles (using nearest-rank method)
        let p10Index = max(0, Int(Double(count) * 0.1) - 1)
        let p90Index = min(count - 1, Int(Double(count) * 0.9))
        
        return SurveyStats(
            median_dbm: median,
            mad_db: mad,
            p10_dbm: rssiValues[p10Index],
            p90_dbm: rssiValues[p90Index],
            sampleCount: count
        )
    }
    
    private func computeHistogram(from samples: [RssiSample]) -> SurveyHistogram {
        let binMin = -100
        let binMax = -30
        let binSize = 1
        let binCount = (binMax - binMin) / binSize + 1
        
        var counts = Array(repeating: 0, count: binCount)
        
        for sample in samples {
            let rssi = sample.rssi
            if rssi >= binMin && rssi <= binMax {
                let binIndex = rssi - binMin
                counts[binIndex] += 1
            }
        }
        
        return SurveyHistogram(
            binMin_dbm: binMin,
            binMax_dbm: binMax,
            binSize_db: binSize,
            counts: counts
        )
    }
}
