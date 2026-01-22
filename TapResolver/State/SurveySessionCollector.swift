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
import CoreMotion

// MARK: - Facing Sector Snapshot (for HUD consumption)

/// Lightweight snapshot for FacingRoseHUD - computed on demand, NOT @Published
/// This avoids reactive overhead during time-critical data collection
struct FacingSectorSnapshot {
    let sectorTime_s: [Double]      // 8 elements: accumulated seconds per sector [N, NE, E, SE, S, SW, W, NW]
    let currentSectorIndex: Int     // 0-7, which sector device is currently facing
    let currentHeading: Double      // 0-360°, for smooth rotation
    let isValid: Bool               // false if no pose/session data available
    
    static let empty = FacingSectorSnapshot(
        sectorTime_s: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
        currentSectorIndex: 0,
        currentHeading: 0.0,
        isValid: false
    )
}

// MARK: - Console Timestamp Helper

/// Formats a Date for console output in local time (East Coast US style: HH:mm:ss)
private func localTimeString(from date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    formatter.timeZone = .current  // Uses device's local timezone
    return formatter.string(from: date)
}

/// Converts an ISO8601 string (UTC) to local time for console display
private func localTimeFromISO(_ isoString: String) -> String {
    let isoFormatter = ISO8601DateFormatter()
    guard let date = isoFormatter.date(from: isoString) else {
        return isoString  // Return original if parsing fails
    }
    return localTimeString(from: date)
}

// MARK: - Notifications

extension Notification.Name {
    /// Posted after a survey session is persisted to store
    /// userInfo: ["mapCoordinate": CGPoint]
    static let surveySessionPersisted = Notification.Name("SurveySessionPersisted")
}

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
    private weak var orientationManager: CompassOrientationManager?
    private weak var mapPointStore: MapPointStore?
    private weak var arCalibrationCoordinator: ARCalibrationCoordinator?
    private var bleSubscription: AnyCancellable?
    
    /// Motion manager for magnetometer sampling
    private let motionManager = CMMotionManager()
    
    // MARK: - Session State
    
    /// Currently active dwell session (nil when not dwelling)
    private var activeSession: ActiveDwellSession?
    
    /// Published for UI feedback
    @Published private(set) var isCollecting: Bool = false
    @Published private(set) var activeMarkerID: UUID?
    @Published private(set) var currentDwellTime: Double = 0.0
    
    /// Throttle tracking: beaconID -> last sample timestamp
    private var lastSampleTime: [String: TimeInterval] = [:]
    
    /// Throttle tracking for pose sampling (4 Hz, independent of beacon samples)
    private var lastPoseSampleTime: TimeInterval = 0
    
    /// Throttle tracking for facing diagnostic (reduce log spam)
    private var lastFacingDiagnosticTime: TimeInterval = 0
    
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
        
        /// Magnetometer track (sampled at same timestamps as pose)
        var magnetometerTrack: [MagnetometerSample] = []
        
        /// Per-beacon sample buffers (beaconID → lean RSSI samples)
        var beaconSamples: [String: [RssiSample]] = [:]
        
        /// Accumulated time per facing sector during this session (for live HUD feedback)
        /// Index 0 = N, 1 = NE, 2 = E, etc.
        var sectorTime_s: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        
        /// Tracking for time-based sector accumulation
        var lastSectorIndex: Int? = nil
        var lastSectorUpdateTime: TimeInterval = 0
        
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
    func configure(
        surveyPointStore: SurveyPointStore,
        bluetoothScanner: BluetoothScanner,
        beaconLists: BeaconListsStore,
        orientationManager: CompassOrientationManager,
        mapPointStore: MapPointStore,
        arCalibrationCoordinator: ARCalibrationCoordinator
    ) {
        self.surveyPointStore = surveyPointStore
        self.bluetoothScanner = bluetoothScanner
        self.beaconLists = beaconLists
        self.orientationManager = orientationManager
        self.mapPointStore = mapPointStore
        self.arCalibrationCoordinator = arCalibrationCoordinator
        
        // Set up reverse reference for direct BLE injection during dwell
        bluetoothScanner.surveyCollector = self
        
        // DIAGNOSTIC: Verify coordinator reference was stored (weak reference)
        print("📊 [SurveySessionCollector] ARCalibrationCoordinator connected: \(ObjectIdentifier(arCalibrationCoordinator))")
        
        print("📊 [SurveySessionCollector] Configured with SurveyPointStore, BluetoothScanner, BeaconListsStore (\(beaconLists.beacons.count) beacons), CompassOrientationManager, MapPointStore, and ARCalibrationCoordinator")
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
        
        // Milestone 4: Get actual pose from ARKit
        let currentPose: SurveyDevicePose
        if let arPose = ARViewContainer.ARViewCoordinator.current?.getCurrentPose() {
            currentPose = arPose
            print("📊 [SurveySessionCollector] Captured start pose: (\(String(format: "%.2f", arPose.x)), \(String(format: "%.2f", arPose.y)), \(String(format: "%.2f", arPose.z)))")
        } else {
            currentPose = SurveyDevicePose.identity
            print("⚠️ [SurveySessionCollector] ARKit pose unavailable - using identity")
        }
        
        // Milestone 5: Get actual compass heading (magnetic, for distortion mapping)
        let compassHeading: Float
        if let magneticHeading = orientationManager?.magneticHeadingDegrees {
            compassHeading = Float(magneticHeading)
            print("📊 [SurveySessionCollector] Captured magnetic heading: \(String(format: "%.1f", compassHeading))°")
        } else {
            compassHeading = -1.0  // Sentinel for "unavailable"
            print("⚠️ [SurveySessionCollector] Compass heading unavailable")
        }
        
        activeSession = ActiveDwellSession(
            markerID: markerID,
            mapCoordinate: mapCoordinate,
            startTime: now,
            startPose: currentPose,
            compassHeading: compassHeading
        )
        
        // Load historical angular coverage from existing SurveyPoint (if any)
        if let coord = mapCoordinate,
           let store = surveyPointStore {
            let (nearestPoint, distance) = store.findNearestPoint(to: coord)
            if let existingPoint = nearestPoint, distance < 3.0 {
                // Seed sector times from historical data
                let historicalTimes = existingPoint.quality.angularCoverage.sectorTime_s
                activeSession?.sectorTime_s = historicalTimes
                print("📊 [SurveySessionCollector] Loaded historical angular coverage from point \(String(existingPoint.id.prefix(8))): \(historicalTimes.map { String(format: "%.1f", $0) })")
            } else {
                print("📊 [SurveySessionCollector] No historical angular coverage found for this location")
            }
        }
        
        // Reset throttle state for new session
        lastSampleTime.removeAll()
        lastPoseSampleTime = 0
        
        // Insert boundary markers for all known beacons
        // TODO: Milestone 3 - Get beacon list from BeaconListsStore
        insertBoundaryMarkers(atMs: 0)
        
        // Start listening for BLE updates
        startBLESubscription()
        surveyTrace("bleSubscribed")
        
        // Start magnetometer for magnetic field sampling
        startMagnetometer()
        
        // Update published state
        self.isCollecting = true
        self.activeMarkerID = markerID
        self.currentDwellTime = 0.0
        
        let coordString = mapCoordinate.map { "(\(String(format: "%.1f", $0.x)), \(String(format: "%.1f", $0.y)))" } ?? "nil"
        let localTime = localTimeString(from: now)
        print("📊 [SurveySessionCollector] Session STARTED at \(localTime) for marker \(String(markerID.uuidString.prefix(8))) at map coord \(coordString)")
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
        
        // Milestone 4: Get actual end pose from ARKit
        let endPose: SurveyDevicePose
        if let arPose = ARViewContainer.ARViewCoordinator.current?.getCurrentPose() {
            endPose = arPose
        } else {
            endPose = SurveyDevicePose.identity
        }
        
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
        stopMagnetometer()
        
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
    
    // MARK: - Magnetometer
    
    /// Start magnetometer updates for magnetic field sampling
    private func startMagnetometer() {
        guard motionManager.isMagnetometerAvailable else {
            print("⚠️ [SurveySessionCollector] Magnetometer not available")
            return
        }
        
        // We don't use the update interval here - we sample on demand
        // when pose is sampled to keep timestamps synchronized
        motionManager.startMagnetometerUpdates()
        print("📊 [SurveySessionCollector] Magnetometer started")
    }
    
    /// Stop magnetometer updates
    private func stopMagnetometer() {
        motionManager.stopMagnetometerUpdates()
        print("📊 [SurveySessionCollector] Magnetometer stopped")
    }
    
    /// Sample current magnetometer reading and add to active session
    /// Call this at same time as pose sampling for timestamp correlation
    private func sampleMagnetometer(atMs ms: Int64) {
        guard var session = activeSession,
              let data = motionManager.magnetometerData else {
            return
        }
        
        let sample = MagnetometerSample(
            ms: ms,
            x: Float(data.magneticField.x),
            y: Float(data.magneticField.y),
            z: Float(data.magneticField.z)
        )
        
        session.magnetometerTrack.append(sample)
        activeSession = session
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
        
        // Milestone 4: Capture pose for poseTrack (sampled at 4 Hz, independent of beacon readings)
        guard var session = activeSession else { return }
        if now - lastPoseSampleTime >= sampleIntervalSeconds {
            let ms = session.elapsedMs()
            if let arPose = ARViewContainer.ARViewCoordinator.current?.getCurrentPose() {
                let poseSample = PoseSample(ms: ms, pose: arPose)
                session.poseTrack.append(poseSample)
                lastPoseSampleTime = now
            }
            activeSession = session
            
            // Sample magnetometer at same timestamp for correlation
            sampleMagnetometer(atMs: ms)
        }
        
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
        
        // Accumulate time in facing sector for HUD feedback
        let now = CACurrentMediaTime()
        if let currentSector = currentFacingSectorIndex() {
            if let lastSector = session.lastSectorIndex {
                // Accumulate time since last update into the PREVIOUS sector
                let delta = now - session.lastSectorUpdateTime
                if delta > 0 && delta < 1.0 {  // Sanity check: ignore gaps > 1 second
                    session.sectorTime_s[lastSector] += delta
                }
            }
            // Update tracking for next iteration
            session.lastSectorIndex = currentSector
            session.lastSectorUpdateTime = now
        }
        
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
            magnetometerTrack: session.magnetometerTrack,
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
            magnetometerTrack: session.magnetometerTrack,
            beacons: beaconMeasurements
        )
        
        // Persist sector time data for angular coverage
        // Convert sector times to heading-based calls for AngularCoverage
        // Note: This approach converts sector index → center heading → back to sector index inside addTime().
        //       We may opt to use a more direct, more efficient method in the near future.
        let sectorCenterHeadings = [0.0, 45.0, 90.0, 135.0, 180.0, 225.0, 270.0, 315.0]
        var sectorTimeData: [(heading: Double, time: Double)] = []
        for i in 0..<8 {
            if session.sectorTime_s[i] > 0.001 {  // Skip negligible values
                sectorTimeData.append((heading: sectorCenterHeadings[i], time: session.sectorTime_s[i]))
            }
        }
        
        surveyTrace("finalizeSessionAsync", context: "sector times: \(sectorTimeData.map { "(\(Int($0.heading))°: \(String(format: "%.2f", $0.time))s)" }.joined(separator: ", "))")
        
        surveyTrace("finalizeSessionAsync", context: "computation complete, hopping to MainActor for store write")
        
        // Hop to MainActor ONLY for the store write, then notify
        await MainActor.run {
            surveyTrace("storeWrite", context: "on MainActor, writing to store")
            store.addSession(surveySession, atMapCoordinate: mapCoordinate)
            
            // Apply sector time to angular coverage on the persisted point
            let (nearestPoint, _) = store.findNearestPoint(to: mapCoordinate)
            if let point = nearestPoint {
                for (heading, time) in sectorTimeData {
                    store.addAngularCoverageTime(time, atHeading: heading, toPointID: point.id)
                }
            }
            
            // Notify AR view to update marker colors (still on MainActor)
            NotificationCenter.default.post(
                name: .surveySessionPersisted,
                object: nil,
                userInfo: ["mapCoordinate": mapCoordinate]
            )
        }
        
        surveyTrace("finalizeSessionAsync", context: "complete, session saved")
        let localStart = localTimeString(from: session.startTime)
        let localEnd = localTimeString(from: Date())
        print("📊 [SurveySessionCollector] ✅ Session saved: \(beaconMeasurements.count) beacons, \(String(format: "%.1f", duration))s duration (\(localStart) → \(localEnd) local)")
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
    
    // MARK: - Facing Sector Data (for HUD)
    
    /// Compute the north direction angle in AR space by projecting north/south MapPoints
    /// through bilinear interpolation and extracting the yaw of the resulting vector.
    /// Returns nil if north/south MapPoints don't exist or bilinear projection unavailable.
    private func computeARNorthAngleDegrees() -> Double? {
        guard let store = mapPointStore,
              let coordinator = arCalibrationCoordinator else {
            return nil
        }
        
        // Find MapPoints with directional roles
        let northMapPoint = store.points.first { $0.roles.contains(.directionalNorth) }
        let southMapPoint = store.points.first { $0.roles.contains(.directionalSouth) }
        
        guard let north = northMapPoint, let south = southMapPoint else {
            print("⚠️ [AR_NORTH] Missing north or south MapPoint")
            return nil
        }
        
        // Check if bilinear projection is available (Zone Corner Calibration completed)
        if !coordinator.hasBilinearCorners {
            // Fallback: Try using cached session transform from Triangle Patch calibration
            if let rotationRadians = coordinator.sessionToCanonicalRotationRadians,
               let northCanonical = north.canonicalPosition,
               let southCanonical = south.canonicalPosition {
                
                // Compute north direction in canonical space
                let canonicalNorthDir = simd_normalize(SIMD3<Float>(
                    northCanonical.x - southCanonical.x,
                    0,  // Ignore Y for direction calculation
                    northCanonical.z - southCanonical.z
                ))
                
                // Transform direction to session space (inverse rotation only needed for direction)
                // Session→Canonical uses +rotationY, so Canonical→Session uses -rotationY
                let inverseRotation = -rotationRadians
                let cosR = cos(inverseRotation)
                let sinR = sin(inverseRotation)
                let sessionNorthDir = SIMD3<Float>(
                    canonicalNorthDir.x * cosR - canonicalNorthDir.z * sinR,
                    0,
                    canonicalNorthDir.x * sinR + canonicalNorthDir.z * cosR
                )
                
                // Compute angle from +X axis in XZ plane
                let northAngleRadians = atan2(Double(sessionNorthDir.z), Double(sessionNorthDir.x))
                let northAngleDegrees = northAngleRadians * 180.0 / .pi
                
                print("🧭 [AR_NORTH] Using session transform fallback:")
                print("   Canonical north dir: (\(String(format: "%.3f", canonicalNorthDir.x)), \(String(format: "%.3f", canonicalNorthDir.z)))")
                print("   Session north dir: (\(String(format: "%.3f", sessionNorthDir.x)), \(String(format: "%.3f", sessionNorthDir.z)))")
                print("   AR north angle: \(String(format: "%.1f", northAngleDegrees))°")
                
                return northAngleDegrees
            }
            
            print("⚠️ [AR_NORTH] Bilinear corners not available and session transform fallback unavailable")
            return nil
        }
        
        // Project both points into AR space via bilinear interpolation
        guard let northResult = coordinator.projectPointViaBilinear(mapPoint: north.position),
              let southResult = coordinator.projectPointViaBilinear(mapPoint: south.position) else {
            print("⚠️ [AR_NORTH] Failed to project north/south MapPoints via bilinear")
            return nil
        }
        let northAR = northResult.position
        let southAR = southResult.position
        
        // Compute vector from south to north in AR space (XZ plane, Y is up)
        let dx = northAR.x - southAR.x
        let dz = northAR.z - southAR.z
        
        // Extract yaw angle (rotation around Y axis)
        // atan2(z, x) gives angle from +X axis in XZ plane
        let northAngleRadians = atan2(Double(dz), Double(dx))
        let northAngleDegrees = northAngleRadians * 180.0 / .pi
        
        // DIAGNOSTIC
        print("🧭 [AR_NORTH] South=(\(String(format: "%.2f", southAR.x)), \(String(format: "%.2f", southAR.z))) North=(\(String(format: "%.2f", northAR.x)), \(String(format: "%.2f", northAR.z))) → AR north angle=\(String(format: "%.1f", northAngleDegrees))°")
        
        return northAngleDegrees
    }
    
    /// Compute current facing sector index using AR north vector from projected MapPoints.
    /// AR session yaw - AR north angle → map-relative heading → sector
    /// Returns nil if required data unavailable.
    private func currentFacingSectorIndex() -> Int? {
        guard let session = activeSession,
              let latestPose = session.poseTrack.last else {
            return nil
        }
        
        // Step 1: Extract yaw from AR pose quaternion
        let deviceYawRadians = yawFromQuaternion(
            qx: latestPose.qx, qy: latestPose.qy,
            qz: latestPose.qz, qw: latestPose.qw
        )
        let deviceYawDegrees = Double(deviceYawRadians) * 180.0 / .pi
        
        // Step 2: Get AR north angle from projected north/south MapPoints
        guard let arNorthAngle = computeARNorthAngleDegrees() else {
            // Cannot compute without bilinear projection and north/south MapPoints
            return nil
        }
        
        // Step 3: Compute map-relative heading
        // The quaternion yaw and atan2 angle use different reference conventions
        // Quaternion yaw: 0° = facing -Z, increases counterclockwise
        // atan2(dz, dx): 0° = +X direction, increases counterclockwise
        // The correct relationship requires inverting the subtraction and adding 180°
        var mapRelativeHeading = 180.0 - arNorthAngle - deviceYawDegrees
        
        // Normalize to 0-360
        while mapRelativeHeading < 0 { mapRelativeHeading += 360 }
        while mapRelativeHeading >= 360 { mapRelativeHeading -= 360 }
        
        let sectorIndex = sectorIndexFromHeading(mapRelativeHeading)
        
        // DIAGNOSTIC: Log at ~1 Hz
        let now = CACurrentMediaTime()
        if now - lastFacingDiagnosticTime >= 1.0 {
            lastFacingDiagnosticTime = now
            let sectorNames = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
            print("🧭 [FACING] deviceYaw=\(String(format: "%.1f", deviceYawDegrees))° - arNorth=\(String(format: "%.1f", arNorthAngle))° → mapHeading=\(String(format: "%.1f", mapRelativeHeading))° → sector \(sectorIndex) (\(sectorNames[sectorIndex]))")
        }
        
        return sectorIndex
    }
    
    /// Compute facing sector snapshot for HUD consumption
    /// Called at ~8 Hz by FacingRoseHUD timer - intentionally NOT reactive
    func getFacingSectorData() -> FacingSectorSnapshot {
        guard let session = activeSession else {
            return .empty
        }
        
        guard let latestPose = session.poseTrack.last,
              let arNorthAngle = computeARNorthAngleDegrees() else {
            // No pose or north data available
            return FacingSectorSnapshot(
                sectorTime_s: session.sectorTime_s,
                currentSectorIndex: 0,
                currentHeading: 0.0,
                isValid: false
            )
        }
        
        // Compute heading (same logic as currentFacingSectorIndex but returns heading)
        let deviceYawRadians = yawFromQuaternion(
            qx: latestPose.qx, qy: latestPose.qy,
            qz: latestPose.qz, qw: latestPose.qw
        )
        let deviceYawDegrees = Double(deviceYawRadians) * 180.0 / .pi
        
        var mapRelativeHeading = 180.0 - arNorthAngle - deviceYawDegrees
        
        // Normalize to 0-360
        while mapRelativeHeading < 0 { mapRelativeHeading += 360 }
        while mapRelativeHeading >= 360 { mapRelativeHeading -= 360 }
        
        let sectorIndex = sectorIndexFromHeading(mapRelativeHeading)
        
        return FacingSectorSnapshot(
            sectorTime_s: session.sectorTime_s,
            currentSectorIndex: sectorIndex,
            currentHeading: mapRelativeHeading,
            isValid: true
        )
    }
    
    /// Extract yaw (rotation around Y axis) from quaternion
    /// ARKit uses Y-up coordinate system: +Y up, +Z toward viewer, +X right
    private func yawFromQuaternion(qx: Float, qy: Float, qz: Float, qw: Float) -> Float {
        // Correct formula for Y-axis rotation in Y-up coordinate system
        // Yaw = atan2(2(qw*qy - qx*qz), 1 - 2(qy² + qz²))
        let siny_cosp = 2.0 * (qw * qy - qx * qz)  // MINUS, not plus
        let cosy_cosp = 1.0 - 2.0 * (qy * qy + qz * qz)  // qy² + qz², not qx² + qy²
        return atan2(siny_cosp, cosy_cosp)
    }
    
    /// Map heading (0-360°) to sector index (0-7)
    /// Sector 0 = N (337.5° - 22.5°), Sector 1 = NE (22.5° - 67.5°), etc.
    private func sectorIndexFromHeading(_ heading: Double) -> Int {
        // Offset by 22.5° so that 0° (north) falls in center of sector 0
        let adjusted = heading + 22.5
        let normalized = adjusted.truncatingRemainder(dividingBy: 360.0)
        let index = Int(normalized / 45.0) % 8
        return index
    }
    
}
