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

/// Manages data collection during Survey Marker dwell sessions
@MainActor
class SurveySessionCollector: ObservableObject {
    
    // MARK: - Dependencies
    
    private weak var surveyPointStore: SurveyPointStore?
    private weak var bluetoothScanner: BluetoothScanner?
    private var bleSubscription: AnyCancellable?
    
    // MARK: - Session State
    
    /// Currently active dwell session (nil when not dwelling)
    private var activeSession: ActiveDwellSession?
    
    /// Published for UI feedback
    @Published private(set) var isCollecting: Bool = false
    @Published private(set) var activeMarkerID: UUID?
    @Published private(set) var currentDwellTime: Double = 0.0
    
    // MARK: - Configuration
    
    /// Minimum session duration to persist (seconds)
    static let minimumSessionDuration: Double = 3.0
    
    // MARK: - Internal Types
    
    /// Tracks state during an active dwell session
    private struct ActiveDwellSession {
        let markerID: UUID
        let mapCoordinate: CGPoint?
        let startTime: Date
        let startPose: SurveyDevicePose
        let compassHeading: Float
        
        /// Per-beacon sample buffers (beaconID → samples)
        var beaconSamples: [String: [RssiPoseSample]] = [:]
        
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
    func configure(surveyPointStore: SurveyPointStore, bluetoothScanner: BluetoothScanner) {
        self.surveyPointStore = surveyPointStore
        self.bluetoothScanner = bluetoothScanner
        print("📊 [SurveySessionCollector] Configured with SurveyPointStore and BluetoothScanner")
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
            mapCoordinate: mapCoordinate,
            startTime: now,
            startPose: currentPose,
            compassHeading: compassHeading
        )
        
        // Insert boundary markers for all known beacons
        // TODO: Milestone 3 - Get beacon list from BeaconListsStore
        insertBoundaryMarkers(atMs: 0, pose: currentPose)
        
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
        
        // Insert ending boundary markers
        // TODO: Milestone 4 - Get actual pose from ARKit
        let endPose = SurveyDevicePose.identity
        insertBoundaryMarkers(atMs: session.elapsedMs(), pose: endPose)
        
        // Finalize and persist
        finalizeSession(session, duration: duration, endPose: endPose)
        
        print("📊 [SurveySessionCollector] Session COMPLETED for marker \(markerIDShort) - duration \(String(format: "%.1f", duration))s")
        
        clearSession()
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
        guard activeSession != nil else { return }
        
        // TODO: Milestone 4 - Get actual pose from ARKit
        let currentPose = SurveyDevicePose.identity
        
        for device in devices {
            // Use device identifier as beacon ID
            let beaconID = device.id.uuidString
            let rssi = device.rssi
            
            // Skip invalid RSSI values
            guard rssi < 0 else { continue }
            
            ingestSample(beaconID: beaconID, rssi: rssi, pose: currentPose)
        }
    }
    
    // MARK: - Boundary Markers
    
    /// Insert rssi=0 boundary markers for all tracked beacons
    private func insertBoundaryMarkers(atMs ms: Int64, pose: SurveyDevicePose) {
        guard var session = activeSession else { return }
        
        // For now, we have no beacons being tracked
        // Milestone 3 will populate beaconSamples with real beacon IDs
        // When that happens, this method will insert boundary markers for each
        
        // Placeholder: If beaconSamples is empty, nothing to do yet
        // Once BLE wiring is in place, beacons will be added dynamically
        
        for beaconID in session.beaconSamples.keys {
            let boundaryMarker = RssiPoseSample.boundaryMarker(ms: ms, pose: pose)
            session.beaconSamples[beaconID]?.append(boundaryMarker)
        }
        
        activeSession = session
    }
    
    // MARK: - BLE Sample Ingestion (Milestone 3)
    
    /// Called when a BLE advertisement is received during dwell
    /// - Parameters:
    ///   - beaconID: Identifier for the beacon
    ///   - rssi: Signal strength in dBm
    ///   - pose: Device pose at moment of reception
    func ingestSample(beaconID: String, rssi: Int, pose: SurveyDevicePose) {
        guard var session = activeSession else {
            // Not currently dwelling - ignore
            return
        }
        
        let ms = session.elapsedMs()
        
        let sample = RssiPoseSample(
            ms: ms,
            rssi: rssi,
            x: pose.x,
            y: pose.y,
            z: pose.z,
            qx: pose.qx,
            qy: pose.qy,
            qz: pose.qz,
            qw: pose.qw
        )
        
        // Initialize buffer for this beacon if needed
        if session.beaconSamples[beaconID] == nil {
            // Insert opening boundary marker first
            let boundaryMarker = RssiPoseSample.boundaryMarker(ms: 0, pose: session.startPose)
            session.beaconSamples[beaconID] = [boundaryMarker]
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
    
    private func finalizeSession(_ session: ActiveDwellSession, duration: Double, endPose: SurveyDevicePose) {
        guard let mapCoordinate = session.mapCoordinate else {
            print("⚠️ [SurveySessionCollector] Cannot finalize - no map coordinate (test marker?)")
            return
        }
        
        guard let store = surveyPointStore else {
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
            beacons: beaconMeasurements
        )
        
        // Persist to store
        store.addSession(surveySession, atMapCoordinate: mapCoordinate)
        
        print("📊 [SurveySessionCollector] Persisted session with \(beaconMeasurements.count) beacon(s), \(beaconMeasurements.reduce(0) { $0 + $1.samples.count }) total samples")
    }
    
    // MARK: - Statistics Computation (Milestone 7 placeholder)
    
    private func computeStats(from samples: [RssiPoseSample]) -> SurveyStats {
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
    
    private func computeHistogram(from samples: [RssiPoseSample]) -> SurveyHistogram {
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
