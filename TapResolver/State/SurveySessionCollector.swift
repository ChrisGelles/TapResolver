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

// MARK: - Thread Tracing

/// Logs survey thread trace information when enabled
/// - Parameters:
///   - event: Description of what's happening
///   - context: Additional context (markerID, counts, etc.)
///   - function: Auto-captured function name
///   - isViolation: If true, marks this as a threading violation
func surveyTrace(
    _ event: String,
    context: String = "",
    function: String = #function,
    isViolation: Bool = false
) {
    // Check if tracing is enabled via UserDefaults (avoids dependency on HUDPanelsState)
    guard UserDefaults.standard.bool(forKey: "debug.surveyThreadTrace") else { return }
    
    let timestamp = Date()
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss.SSS"
    let timeStr = formatter.string(from: timestamp)
    
    let threadName: String
    if Thread.isMainThread {
        threadName = "Main"
    } else {
        let qos = DispatchQoS.QoSClass(rawValue: qos_class_self()) ?? .default
        switch qos {
        case .utility:
            threadName = "BG-Utility"
        case .background:
            threadName = "BG-Background"
        case .userInitiated:
            threadName = "BG-UserInit"
        case .userInteractive:
            threadName = "BG-UserInt"
        default:
            threadName = "BG-Default"
        }
    }
    
    let violationMarker = isViolation ? " ⚠️ VIOLATION" : ""
    let contextStr = context.isEmpty ? "" : " | \(context)"
    
    print("[SURVEY] \(timeStr) | \(threadName.padding(toLength: 11, withPad: " ", startingAt: 0)) | \(function.padding(toLength: 35, withPad: " ", startingAt: 0)) | \(event)\(contextStr)\(violationMarker)")
}

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
        let mapCoordinate: CGPoint?
        let startTime: Date
        let startPose: SurveyDevicePose
        let compassHeading: Float
        
        /// Pose track (sampled at 4 Hz, independent of beacon readings)
        var poseTrack: [PoseSample] = []
        
        /// Per-beacon sample buffers (beaconID → lean RSSI samples)
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
        
        // Set up reverse reference for direct BLE injection during dwell
        bluetoothScanner.surveyCollector = self
        
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
        
        surveyTrace("markerEntered", context: "id=\(markerID.uuidString.prefix(8))")
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
        
        surveyTrace("markerExited", context: "id=\(markerID.uuidString.prefix(8))")
        endSession()
    }
    
    // MARK: - Session Lifecycle
    
    private func startSession(markerID: UUID, mapCoordinate: CGPoint?) {
        surveyTrace("sessionStarting", context: "marker=\(markerID.uuidString.prefix(8))")
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
        
        // Reset throttle state for new session
        lastSampleTime.removeAll()
        
        // Insert boundary markers for all known beacons
        // TODO: Milestone 3 - Get beacon list from BeaconListsStore
        insertBoundaryMarkers(atMs: 0)
        
        // Start listening for BLE updates
        startBLESubscription()
        surveyTrace("bleSubscribed")
        
        // Update published state
        self.isCollecting = true
        self.activeMarkerID = markerID
        self.currentDwellTime = 0.0
        
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
        insertBoundaryMarkers(atMs: session.elapsedMs())
        
        // TODO: Milestone 4 - Get actual end pose from ARKit
        let endPose = SurveyDevicePose.identity
        
        // Capture session data for async processing
        let sessionCopy = session
        let storeCopy = surveyPointStore
        
        // Clear session immediately so main thread is unblocked
        clearSession()
        
        // Log completion on main thread before async work
        print("📊 [SurveySessionCollector] Session COMPLETED for marker \(markerIDShort) - duration \(String(format: "%.1f", duration))s")
        
        surveyTrace("endSession", context: "duration=\(String(format: "%.1f", duration))s, dispatching to background")
        
        // Dispatch finalization to background queue
        Task.detached(priority: .utility) { [sessionCopy, storeCopy] in
            await self.finalizeSessionAsync(sessionCopy, duration: duration, endPose: endPose, store: storeCopy)
        }
    }
    
    private func clearSession() {
        activeSession = nil
        stopBLESubscription()
        
        self.isCollecting = false
        self.activeMarkerID = nil
        self.currentDwellTime = 0.0
    }
    
    // MARK: - BLE Subscription
    
    /// Start listening to BLE updates during dwell
    /// Note: With direct injection, this is now a no-op. BLE data flows via ingestBLEData().
    private func startBLESubscription() {
        // Direct injection path: BluetoothScanner calls ingestBLEData() directly
        // No Combine subscription needed - eliminates publisher overhead during dwell
        print("📊 [SurveySessionCollector] BLE subscription started (direct injection mode)")
    }
    
    /// Stop listening to BLE updates
    /// Note: With direct injection, this is now a no-op.
    private func stopBLESubscription() {
        // Direct injection path: No subscription to cancel
        print("📊 [SurveySessionCollector] BLE subscription stopped")
    }
    
    /// Handle incoming BLE device updates
    private func handleBLEUpdate(devices: [BluetoothScanner.DiscoveredDevice]) {
        let bleStart = CACurrentMediaTime()
        
        guard activeSession != nil else { return }
        surveyTrace("bleUpdate", context: "devices=\(devices.count)")
        
        // Get whitelist for filtering
        let whitelist = beaconLists?.beacons ?? []
        
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
            
            // Record the sample (pose is captured separately in poseTrack)
            ingestSample(beaconID: beaconName, rssi: rssi)
        }
        
        let bleDuration = (CACurrentMediaTime() - bleStart) * 1000
        if bleDuration > 5.0 {
            print("⚠️ [PERF] BLE update took \(String(format: "%.1f", bleDuration))ms for \(devices.count) devices")
        }
    }
    
    // MARK: - Boundary Markers
    
    /// Insert rssi=0 boundary markers for all tracked beacons
    private func insertBoundaryMarkers(atMs ms: Int64) {
        guard var session = activeSession else { return }
        
        // Insert boundary marker for each beacon currently being tracked
        for beaconID in session.beaconSamples.keys {
            let boundaryMarker = RssiSample.boundaryMarker(ms: ms)
            session.beaconSamples[beaconID]?.append(boundaryMarker)
        }
        
        activeSession = session
    }
    
    // MARK: - Direct BLE Injection
    
    /// Direct injection point for BLE data during active dwell
    /// Called by BluetoothScanner, bypassing Combine entirely
    /// - Parameters:
    ///   - beaconID: Device name (beacon identifier)
    ///   - rssi: Signal strength in dBm
    func ingestBLEData(beaconID: String, rssi: Int) {
        // Only process during active session
        guard activeSession != nil else { return }
        
        // Skip empty names
        guard !beaconID.isEmpty else { return }
        
        // Whitelist filter: only record beacons we care about
        let whitelist = beaconLists?.beacons ?? []
        guard whitelist.contains(beaconID) else { return }
        
        // Skip invalid RSSI values
        guard rssi < 0 else { return }
        
        // 4Hz throttle: only sample every 250ms per beacon
        let now = CACurrentMediaTime()
        if let lastTime = lastSampleTime[beaconID], now - lastTime < sampleIntervalSeconds {
            return
        }
        lastSampleTime[beaconID] = now
        
        // Record the sample (pose is captured separately in poseTrack)
        ingestSample(beaconID: beaconID, rssi: rssi)
    }
    
    // MARK: - BLE Sample Ingestion (Milestone 3)
    
    /// Called when a BLE advertisement is received during dwell
    /// - Parameters:
    ///   - beaconID: Identifier for the beacon
    ///   - rssi: Signal strength in dBm
    func ingestSample(beaconID: String, rssi: Int) {
        guard var session = activeSession else {
            // Not currently dwelling - ignore
            return
        }
        
        // Only trace every 10th sample to avoid log flooding
        if Int.random(in: 0..<10) == 0 {
            surveyTrace("ingestSample", context: "beacon=\(beaconID) rssi=\(rssi)")
        }
        
        let ms = session.elapsedMs()
        let sample = RssiSample(ms: ms, rssi: rssi)
        
        // Initialize buffer for this beacon if needed
        if session.beaconSamples[beaconID] == nil {
            // Insert opening boundary marker first
            let boundaryMarker = RssiSample.boundaryMarker(ms: 0)
            session.beaconSamples[beaconID] = [boundaryMarker]
        }
        
        session.beaconSamples[beaconID]?.append(sample)
        activeSession = session
        
        // Log periodically (every 10th sample per beacon to reduce spam)
        let sampleCount = activeSession?.beaconSamples[beaconID]?.count ?? 0
        if sampleCount % 10 == 1 {
            print("📊 [BLE_SAMPLE] Beacon \(String(beaconID.prefix(8))): \(sampleCount) samples, RSSI=\(rssi)")
        }
    }
    
    // MARK: - Session Finalization
    
    private func finalizeSession(_ session: ActiveDwellSession, duration: Double, endPose: SurveyDevicePose, store: SurveyPointStore? = nil) {
        surveyTrace("finalizeSession", context: "starting on background thread")
        
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
        surveyTrace("storeWrite", context: "calling @MainActor store from background", isViolation: true)
        store.addSession(surveySession, atMapCoordinate: mapCoordinate)
        
        print("📊 [SurveySessionCollector] Persisted session with \(beaconMeasurements.count) beacon(s), \(beaconMeasurements.reduce(0) { $0 + $1.samples.count }) total samples")
    }
    
    /// Async version of finalizeSession that properly handles @MainActor store access
    nonisolated private func finalizeSessionAsync(_ session: ActiveDwellSession, duration: Double, endPose: SurveyDevicePose, store: SurveyPointStore?) async {
        surveyTrace("finalizeSessionAsync", context: "starting on background")
        
        guard let mapCoordinate = session.mapCoordinate else {
            surveyTrace("finalizeSessionAsync", context: "no mapCoordinate, aborting")
            print("⚠️ [SurveySessionCollector] No map coordinate for session, cannot save")
            return
        }
        
        guard let store = store else {
            surveyTrace("finalizeSessionAsync", context: "no store, aborting")
            print("⚠️ [SurveySessionCollector] No store available, cannot save")
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
        let surveySession = await SurveySession(
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
        
        surveyTrace("finalizeSessionAsync", context: "computation complete, hopping to MainActor for store write")
        
        // Hop to MainActor ONLY for the store write
        await MainActor.run {
            surveyTrace("storeWrite", context: "on MainActor, writing to store")
            store.addSession(surveySession, atMapCoordinate: mapCoordinate)
        }
        
        surveyTrace("finalizeSessionAsync", context: "complete, session saved")
        print("📊 [SurveySessionCollector] ✅ Session saved: \(beaconMeasurements.count) beacons, \(String(format: "%.1f", duration))s duration")
    }
    
    // MARK: - Statistics Computation (Milestone 7 placeholder)
    
    nonisolated private func computeStats(from samples: [RssiSample]) -> SurveyStats {
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
    
    nonisolated private func computeHistogram(from samples: [RssiSample]) -> SurveyHistogram {
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
