//
//  ARViewWithOverlays.swift
//  TapResolver
//
//  Unified AR view wrapper that includes ARViewContainer with UI overlays
//  This is the ONLY way to present AR - no separate calibration views
//

import SwiftUI
import UIKit
import Combine
import simd
import CoreHaptics
import QuartzCore

struct ARViewWithOverlays: View {
    @Binding var isPresented: Bool
    @State private var currentMode: ARMode = .idle
    
    // Calibration mode properties
    var isCalibrationMode: Bool = false
    var selectedTriangle: TrianglePatch? = nil
    
    // Plane visualization toggle
    @State private var showPlaneVisualization: Bool = true
    
    // Survey marker spacing
    @State private var surveySpacing: Float = 1.0
    
    // Track last printed vertex ID to prevent spam
    @State private var lastPrintedPhotoRefVertexID: UUID? = nil
    
    // Track last logged PIP_MAP state to prevent spam
    @State private var lastLoggedPipMapState: CalibrationState? = nil
    
    // MILESTONE 3: Blocked placement warning state
    @State private var showPlacementWarning: Bool = false
    @State private var warningDistance: Float = 0
    @State private var warningMapPointID: UUID? = nil
    
    // Track which calibrated triangle the user is currently standing in
    @State private var userContainingTriangleID: UUID? = nil
    
    // Track which triangles have survey markers for Clear Triangle button
    @State private var trianglesWithSurveyMarkers: Set<UUID> = []
    
    // Track if zone has been flooded (Zone Mode)
    @State private var zoneHasBeenFlooded: Bool = false
    
    // Debounce state to prevent accidental double-taps on Place Marker
    @State private var isPlaceMarkerCoolingDown = false
    
    // Haptic engine for custom patterns
    @State private var hapticEngine: CHHapticEngine?
    
    // Continuous haptic player for sphere interior buzz
    @State private var continuousPlayer: CHHapticAdvancedPatternPlayer?
    @State private var isInsideSphere: Bool = false
    
    // Survey marker dwell timer
    @State private var dwellTimerValue: Double = -3.0
    @State private var dwellTimer: Timer?
    @State private var dwellStartTime: Date?
    @State private var showDwellTimer: Bool = false
    @State private var didFireThresholdHaptic: Bool = false
    
    // SVG Export state
    @State private var showShareSheet = false
    @State private var svgFileURL: URL? = nil
    
    // Wavefront V2: "Plot Next Zone" button visibility
    @State private var showNextZoneButton: Bool = false
    
    @EnvironmentObject private var mapPointStore: MapPointStore
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var arCalibrationCoordinator: ARCalibrationCoordinator
    @EnvironmentObject private var arWorldMapStore: ARWorldMapStore
    @EnvironmentObject private var metricSquares: MetricSquareStore
    @EnvironmentObject private var surveyPointStore: SurveyPointStore
    @EnvironmentObject private var surveySessionCollector: SurveySessionCollector
    @EnvironmentObject private var arViewLaunchContext: ARViewLaunchContext
    @EnvironmentObject private var btScanner: BluetoothScanner
    @EnvironmentObject private var zoneStore: ZoneStore
    @EnvironmentObject private var zoneGroupStore: ZoneGroupStore
    
    // Relocalization coordinator for strategy selection (developer UI)
    @StateObject private var relocalizationCoordinator: RelocalizationCoordinator
    
    init(isPresented: Binding<Bool>, isCalibrationMode: Bool = false, selectedTriangle: TrianglePatch? = nil) {
        self._isPresented = isPresented
        self.isCalibrationMode = isCalibrationMode
        self.selectedTriangle = selectedTriangle
        
        // Initialize with temporary store, will be updated in onAppear
        let tempStore = ARWorldMapStore()
        _relocalizationCoordinator = StateObject(wrappedValue: RelocalizationCoordinator(arStore: tempStore))
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // AR View Container
            ARViewContainer(
                mode: $currentMode,
                isCalibrationMode: isCalibrationMode,
                selectedTriangle: selectedTriangle,
                onDismiss: {
                    isPresented = false
                },
                showPlaneVisualization: $showPlaneVisualization,
                metricSquareStore: metricSquares,
                mapPointStore: mapPointStore,
                surveyPointStore: surveyPointStore,
                arCalibrationCoordinator: arCalibrationCoordinator,
                bluetoothScanner: btScanner
            )
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                // Prevent screen dimming during AR session
                UIApplication.shared.isIdleTimerDisabled = true

                // RELOCALIZATION PREP: Start new AR session when view appears
                // This ensures each AR session gets a unique session ID for coordinate tracking
                arWorldMapStore.startNewSession()
                
                // Update relocalization coordinator to use actual store
                relocalizationCoordinator.updateARStore(arWorldMapStore)
                
                // Debug: Print instance and mode
                let instanceAddress = Unmanaged.passUnretained(self as AnyObject).toOpaque()
                
                // If in calibration mode with a selected triangle, initialize calibration state
                if isCalibrationMode, let triangle = selectedTriangle {
                    DispatchQueue.main.async {
                        arCalibrationCoordinator.startCalibration(for: triangle.id)
                        arCalibrationCoordinator.setVertices(triangle.vertexIDs)
                        currentMode = .triangleCalibration(triangleID: triangle.id)
                        print("🎯 ARViewWithOverlays: Auto-initialized calibration for triangle \(String(triangle.id.uuidString.prefix(8)))")
                    }
                } else if arViewLaunchContext.launchMode == .swathSurvey {
                    // Swath Survey mode: Initialize anchoring with suggested anchor points
                    DispatchQueue.main.async {
                        let anchorIDs = arViewLaunchContext.suggestedAnchorIDs
                        arCalibrationCoordinator.startSwathAnchoring(anchorIDs: anchorIDs)
                        currentMode = .idle  // Will show calibration UI via calibrationState
                        print("🎯 ARViewWithOverlays: Auto-initialized swath anchoring with \(anchorIDs.count) anchors")
                    }
                } else if arViewLaunchContext.launchMode == .zoneCornerCalibration {
                    // Zone Corner Calibration mode: Initialize with zone corner points
                    DispatchQueue.main.async {
                        let cornerIDs = arViewLaunchContext.zoneCornerIDs
                        arCalibrationCoordinator.startZoneCornerCalibration(
                            zoneCornerIDs: cornerIDs,
                            zoneID: arViewLaunchContext.activeZoneID,
                            startingCornerIndex: arViewLaunchContext.zoneStartingCornerIndex
                        )
                        currentMode = .idle  // Will show calibration UI via calibrationState
                        print("🎯 ARViewWithOverlays: Auto-initialized Zone Corner calibration with \(cornerIDs.count) corners")
                    }
                } else {
                    // Set mode to idle - user will choose Calibrate or Relocalize
                    currentMode = .idle
                }
                
                print("🧪 ARView ID: triangle viewing mode for \(selectedTriangle.map { String($0.id.uuidString.prefix(8)) } ?? "none")")
                print("🧪 ARViewWithOverlays instance: \(instanceAddress)")
                
                // Initialize haptic engine for survey marker feedback
                prepareHaptics()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PlacementBlocked"))) { notification in
                if let distance = notification.userInfo?["distance"] as? Float,
                   let mapPointID = notification.userInfo?["mapPointID"] as? UUID {
                    warningDistance = distance
                    warningMapPointID = mapPointID
                    showPlacementWarning = true
                    print("🚫 [WARNING_UI] Showing placement blocked warning - \(String(format: "%.2f", distance))m from ghost")
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PlacementBlockedDismissed"))) { _ in
                showPlacementWarning = false
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserContainingTriangleChanged"))) { notification in
                let newTriangleID = notification.userInfo?["triangleID"] as? UUID
                if userContainingTriangleID != newTriangleID {
                    userContainingTriangleID = newTriangleID
                }
            }
            // Survey marker ENTERED - knock + start buzz + start timer
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SurveyMarkerEntered"))) { notification in
                if let markerID = notification.userInfo?["markerID"] as? UUID {
                    let intensity = notification.userInfo?["intensity"] as? Float ?? 0.5
                    print("📳 [HAPTIC] ENTER knock for marker \(String(markerID.uuidString.prefix(8))), starting buzz at \(String(format: "%.2f", intensity))")
                    playHardKnock()
                    startContinuousBuzz(initialIntensity: intensity)
                    startDwellTimer()
                }
            }
            // Survey marker EXITED - knock + stop buzz + stop timer
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SurveyMarkerExited"))) { notification in
                if let markerID = notification.userInfo?["markerID"] as? UUID {
                    print("📳 [HAPTIC] EXIT knock for marker \(String(markerID.uuidString.prefix(8)))")
                    playHardKnock()
                    stopContinuousBuzz()
                    stopDwellTimer()
                }
            }
            // Survey marker PROXIMITY - update buzz intensity (no logging - too spammy)
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SurveyMarkerProximity"))) { notification in
                if let intensity = notification.userInfo?["intensity"] as? Float {
                    updateBuzzIntensity(intensity)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UpdateGhostSelection"))) { notification in
                // Decode camera position from array
                var cameraPosition: simd_float3?
                if let posArray = notification.userInfo?["cameraPosition"] as? [Float], posArray.count == 3 {
                    cameraPosition = simd_float3(posArray[0], posArray[1], posArray[2])
                }
                
                // Decode ghost positions from dictionary of arrays
                var ghostPositions: [UUID: simd_float3] = [:]
                if let ghostPosDict = notification.userInfo?["ghostPositions"] as? [String: [Float]] {
                    for (key, posArray) in ghostPosDict {
                        if let uuid = UUID(uuidString: key), posArray.count == 3 {
                            ghostPositions[uuid] = simd_float3(posArray[0], posArray[1], posArray[2])
                        }
                    }
                }
                
                let visibleGhostIDs = notification.userInfo?["visibleGhostIDs"] as? Set<UUID>
                
                if let cameraPos = cameraPosition {
                    arCalibrationCoordinator.updateGhostSelection(
                        cameraPosition: cameraPos,
                        ghostPositions: ghostPositions,
                        visibleGhostIDs: visibleGhostIDs
                    )
                    
                    // Check proximity to "Plot Next Zone" eligible marker
                    let nearNextZone = arCalibrationCoordinator.checkNextZoneEligibleProximity(cameraPosition: cameraPos) != nil
                    
                    // DIAGNOSTIC
                    if arCalibrationCoordinator.nextZoneEligibleMapPointID != nil {
                        print("🔍 [NEXT_ZONE_DIAG] Eligible marker exists, nearNextZone=\(nearNextZone), showNextZoneButton=\(showNextZoneButton)")
                    }
                    
                    if nearNextZone != showNextZoneButton {
                        showNextZoneButton = nearNextZone
                        print("🔍 [NEXT_ZONE_DIAG] showNextZoneButton changed to \(nearNextZone)")
                    }
                }
            }
            .onDisappear {
                // Re-enable screen dimming when leaving AR
                UIApplication.shared.isIdleTimerDisabled = false

                // Clean up on dismiss - defer to avoid view update conflicts
                DispatchQueue.main.async {
                    currentMode = .idle
                    // Record session completion BEFORE reset clears state
                    arCalibrationCoordinator.recordSessionCompletion()
                    arCalibrationCoordinator.reset()
                    lastPrintedPhotoRefVertexID = nil
                    lastLoggedPipMapState = nil
                    print("🧹 ARViewWithOverlays: Cleaned up on disappear")
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ARMarkerPlaced"))) { notification in
                print("🔍 [REGISTER_MARKER_TRACE] ARMarkerPlaced notification received")
                print("   Calibration state: \(arCalibrationCoordinator.stateDescription)")
                print("   Call stack trace:")
                Thread.callStackSymbols.prefix(5).forEach { print("      \($0)") }
                
                // Check if this is a ghost confirmation
                let isGhostConfirm = notification.userInfo?["isGhostConfirm"] as? Bool ?? false
                // Accept either "ghostMapPointID" (crawl mode) or "mapPointID" (Zone Corner mode)
                let ghostMapPointID = notification.userInfo?["ghostMapPointID"] as? UUID ?? notification.userInfo?["mapPointID"] as? UUID
                
                if isGhostConfirm, let ghostID = ghostMapPointID {
                    print("🎯 [REGISTER_MARKER_TRACE] Ghost confirm for MapPoint \(String(ghostID.uuidString.prefix(8)))")
                    // Clear selection state
                    arCalibrationCoordinator.selectedGhostMapPointID = nil
                    arCalibrationCoordinator.selectedGhostEstimatedPosition = nil
                }
                
                // Block marker registration during survey mode
                if case .surveyMode = arCalibrationCoordinator.calibrationState {
                    print("⚠️ [REGISTER_MARKER_TRACE] Blocked - in survey mode (should use placeSurveyMarkerOnly)")
                    return
                }
                
                // SWATH SURVEY MODE: Handle anchor placement separately
                if arViewLaunchContext.launchMode == .swathSurvey,
                   case .placingVertices = arCalibrationCoordinator.calibrationState,
                   let markerID = notification.userInfo?["markerID"] as? UUID,
                   let positionArray = notification.userInfo?["position"] as? [Float],
                   positionArray.count == 3 {
                    
                    print("🎯 [SWATH_ANCHOR_TRACE] Processing swath anchor placement")
                    
                    guard let currentVertexID = arCalibrationCoordinator.getCurrentVertexID() else {
                        print("⚠️ [SWATH_ANCHOR_TRACE] No current vertex ID")
                        return
                    }
                    
                    let arPosition = simd_float3(positionArray[0], positionArray[1], positionArray[2])
                    let mapPoint = mapPointStore.points.first(where: { $0.id == currentVertexID })
                    let mapCoordinates = mapPoint?.mapPoint ?? CGPoint.zero
                    
                    let marker = ARMarker(
                        id: markerID,
                        linkedMapPointID: currentVertexID,
                        arPosition: arPosition,
                        mapCoordinates: mapCoordinates,
                        isAnchor: false
                    )
                    
                    arCalibrationCoordinator.registerSwathAnchor(mapPointID: currentVertexID, marker: marker)
                    print("✅ [SWATH_ANCHOR_TRACE] Registered swath anchor for MapPoint \(String(currentVertexID.uuidString.prefix(8)))")
                    return
                }
                
                // ZONE CORNER CALIBRATION MODE: Handle zone corner placement separately
                // Accept both .placingVertices (initial corners) and .readyToFill (ghost confirmations)
                if arViewLaunchContext.launchMode == .zoneCornerCalibration,
                   let markerID = notification.userInfo?["markerID"] as? UUID,
                   let positionArray = notification.userInfo?["position"] as? [Float],
                   positionArray.count == 3 {
                    
                    // Determine if we're in a valid state for zone corner processing
                    let isPlacingVertices: Bool
                    if case .placingVertices = arCalibrationCoordinator.calibrationState {
                        isPlacingVertices = true
                    } else if case .readyToFill = arCalibrationCoordinator.calibrationState {
                        isPlacingVertices = false
                    } else {
                        // Not in a valid zone corner state, skip this handler
                        print("⚠️ [ZONE_CORNER_TRACE] Skipping - not in placingVertices or readyToFill state")
                        // Don't return here - let it fall through to other handlers
                        return
                    }
                    
                    // Check if this is a ghost confirmation
                    let isZoneCornerGhostConfirm = notification.userInfo?["isGhostConfirm"] as? Bool ?? false
                    // Accept either "mapPointID" (Zone Corner uses this) or "ghostMapPointID" (crawl mode uses this)
                    let zoneCornerGhostMapPointID = notification.userInfo?["mapPointID"] as? UUID ?? notification.userInfo?["ghostMapPointID"] as? UUID
                    
                    if isPlacingVertices {
                        // Original flow: placing initial zone corners
                        print("🎯 [ZONE_CORNER_TRACE] Processing zone corner placement")
                        
                        guard let currentVertexID = arCalibrationCoordinator.getCurrentVertexID() else {
                            print("⚠️ [ZONE_CORNER_TRACE] No current vertex ID")
                            return
                        }
                        
                        let arPosition = simd_float3(positionArray[0], positionArray[1], positionArray[2])
                        let mapPoint = mapPointStore.points.first(where: { $0.id == currentVertexID })
                        let mapCoordinates = mapPoint?.mapPoint ?? CGPoint.zero
                        
                        let marker = ARMarker(
                            id: markerID,
                            linkedMapPointID: currentVertexID,
                            arPosition: arPosition,
                            mapCoordinates: mapCoordinates,
                            isAnchor: false
                        )
                        
                        arCalibrationCoordinator.registerZoneCornerAnchor(mapPointID: currentVertexID, marker: marker)
                        print("✅ [ZONE_CORNER_TRACE] Registered zone corner for MapPoint \(String(currentVertexID.uuidString.prefix(8)))")
                        
                        // Capture photo for Zone Corner (same logic as Triangle Calibration)
                        if let mapPointForPhoto = mapPointStore.points.first(where: { $0.id == currentVertexID }) {
                            if let coordinator = ARViewContainer.Coordinator.current {
                                coordinator.captureARFrame { image in
                                    guard let image = image else {
                                        print("⚠️ [PHOTO_TRACE] Failed to capture AR frame for Zone Corner photo")
                                        return
                                    }
                                    if let imageData = image.jpegData(compressionQuality: 0.8) {
                                        if mapPointStore.savePhotoToDisk(for: currentVertexID, photoData: imageData) {
                                            if let index = mapPointStore.points.firstIndex(where: { $0.id == currentVertexID }) {
                                                mapPointStore.points[index].photoCapturedAtPosition = mapPointForPhoto.mapPoint
                                                mapPointStore.points[index].photoOutdated = false
                                                mapPointStore.save()
                                            }
                                            print("📸 [PHOTO_TRACE] Captured photo for Zone Corner MapPoint \(String(currentVertexID.uuidString.prefix(8)))")
                                        }
                                    }
                                }
                            }
                        }
                        
                        return
                        
                    } else if isZoneCornerGhostConfirm, let ghostID = zoneCornerGhostMapPointID {
                        // Ghost confirmation in readyToFill state
                        print("🎯 [ZONE_CORNER_GHOST] Processing ghost confirmation in Zone Corner mode")
                        print("   MapPoint: \(String(ghostID.uuidString.prefix(8)))")
                        print("   State: \(arCalibrationCoordinator.stateDescription)")
                        
                        let arPosition = simd_float3(positionArray[0], positionArray[1], positionArray[2])
                        let mapPoint = mapPointStore.points.first(where: { $0.id == ghostID })
                        let mapCoordinates = mapPoint?.mapPoint ?? CGPoint.zero
                        
                        let marker = ARMarker(
                            id: markerID,
                            linkedMapPointID: ghostID,
                            arPosition: arPosition,
                            mapCoordinates: mapCoordinates,
                            isAnchor: false
                        )
                        
                        // Check if this is a corner or a fill point
                        if arCalibrationCoordinator.isZoneCorner(mapPointID: ghostID) {
                            // Corner vertex - use full registration flow
                            arCalibrationCoordinator.registerZoneCornerAnchor(mapPointID: ghostID, marker: marker)
                            print("✅ [ZONE_CORNER_GHOST] Registered corner ghost for MapPoint \(String(ghostID.uuidString.prefix(8)))")
                            
                            // Capture photo for Zone Corner ghost (same logic as Triangle Calibration)
                            if let mapPointForPhoto = mapPointStore.points.first(where: { $0.id == ghostID }) {
                                if let coordinator = ARViewContainer.Coordinator.current {
                                    coordinator.captureARFrame { image in
                                        guard let image = image else {
                                            print("⚠️ [PHOTO_TRACE] Failed to capture AR frame for Zone Corner ghost photo")
                                            return
                                        }
                                        if let imageData = image.jpegData(compressionQuality: 0.8) {
                                            if mapPointStore.savePhotoToDisk(for: ghostID, photoData: imageData) {
                                                if let index = mapPointStore.points.firstIndex(where: { $0.id == ghostID }) {
                                                    mapPointStore.points[index].photoCapturedAtPosition = mapPointForPhoto.mapPoint
                                                    mapPointStore.points[index].photoOutdated = false
                                                    mapPointStore.save()
                                                }
                                                print("📸 [PHOTO_TRACE] Captured photo for Zone Corner ghost MapPoint \(String(ghostID.uuidString.prefix(8)))")
                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            // Fill point - register marker→MapPoint mapping directly
                            // Extract original ghost position for distortion vector calculation
                            let originalGhostPosition: simd_float3?
                            if let origPosArray = notification.userInfo?["originalGhostPosition"] as? [Float], origPosArray.count == 3 {
                                originalGhostPosition = simd_float3(origPosArray[0], origPosArray[1], origPosArray[2])
                            } else {
                                originalGhostPosition = nil
                            }
                            
                            arCalibrationCoordinator.registerFillPointMarker(
                                markerID: markerID,
                                mapPointID: ghostID,
                                position: arPosition,
                                originalGhostPosition: originalGhostPosition
                            )
                            print("✅ [ZONE_CORNER_GHOST] Registered fill point ghost for MapPoint \(String(ghostID.uuidString.prefix(8)))")
                        }
                        return
                    }
                }
                
                // Handle marker placement in calibration mode (triangle calibration)
                guard isCalibrationMode,
                      let triangle = selectedTriangle,
                      let markerID = notification.userInfo?["markerID"] as? UUID,
                      let positionArray = notification.userInfo?["position"] as? [Float],
                      positionArray.count == 3 else {
                    print("⚠️ [REGISTER_MARKER_TRACE] Guard failed - isCalibrationMode=\(isCalibrationMode), triangle=\(selectedTriangle != nil), markerID=\(notification.userInfo?["markerID"] != nil)")
                    return
                }
                
                // Determine target MapPoint
                let targetMapPointID: UUID
                if isGhostConfirm, let ghostID = ghostMapPointID {
                    targetMapPointID = ghostID
                } else {
                guard let currentVertexID = arCalibrationCoordinator.getCurrentVertexID() else {
                    print("⚠️ [REGISTER_MARKER_TRACE] No current vertex ID for marker placement")
                    return
                    }
                    targetMapPointID = currentVertexID
                }
                
                print("🔍 [REGISTER_MARKER_TRACE] Processing marker:")
                print("   markerID: \(String(markerID.uuidString.prefix(8)))")
                print("   targetMapPointID: \(String(targetMapPointID.uuidString.prefix(8)))")
                print("   isGhostConfirm: \(isGhostConfirm)")
                
                // CRITICAL SAFETY CHECK: Block if not in valid marker placement state
                // Valid states: placingVertices, ghost confirm, or crawl mode (readyToFill + ghost selected)
                if !isGhostConfirm {
                    let isValidPlacingState = {
                        if case .placingVertices = arCalibrationCoordinator.calibrationState { return true }
                        if case .readyToFill = arCalibrationCoordinator.calibrationState,
                           arCalibrationCoordinator.selectedGhostMapPointID != nil { return true }
                        return false
                    }()
                    
                    guard isValidPlacingState else {
                        print("⚠️ [REGISTER_MARKER_TRACE] CRITICAL: registerMarker called outside valid placement state!")
                        print("   Current state: \(arCalibrationCoordinator.stateDescription)")
                        print("   selectedGhostMapPointID: \(arCalibrationCoordinator.selectedGhostMapPointID?.uuidString.prefix(8) ?? "nil")")
                        print("   This should never happen - investigating caller")
                        return
                    }
                    
                    // Log crawl mode adjustments (not a warning)
                    if case .readyToFill = arCalibrationCoordinator.calibrationState {
                        print("🔗 [REGISTER_MARKER_TRACE] Crawl mode adjustment for ghost \(String(arCalibrationCoordinator.selectedGhostMapPointID!.uuidString.prefix(8)))")
                    }
                }
                
                // Only capture photo when placing vertices (not in survey mode, not ghost confirm)
                if !isGhostConfirm, case .placingVertices = arCalibrationCoordinator.calibrationState {
                    print("🔍 [PHOTO_TRACE] Photo capture requested (placing vertices)")
                    print("   mapPoint.id: \(String(targetMapPointID.uuidString.prefix(8)))")
                    print("   Calibration state: \(arCalibrationCoordinator.stateDescription)")
                    
                    // Capture photo from AR camera feed when marker is placed
                    if let mapPoint = mapPointStore.points.first(where: { $0.id == targetMapPointID }) {
                        // Auto-capture new photo from AR camera feed
                        if let coordinator = ARViewContainer.Coordinator.current {
                            coordinator.captureARFrame { image in
                                guard let image = image else {
                                    print("⚠️ [PHOTO_TRACE] Failed to capture AR frame for photo replacement")
                                    return
                                }
                                
                                // Convert UIImage to Data
                                if let imageData = image.jpegData(compressionQuality: 0.8) {
                                    // Save photo and update metadata
                                    if mapPointStore.savePhotoToDisk(for: targetMapPointID, photoData: imageData) {
                                        // Update capture position to current position
                                        if let index = mapPointStore.points.firstIndex(where: { $0.id == targetMapPointID }) {
                                            mapPointStore.points[index].photoCapturedAtPosition = mapPoint.mapPoint
                                            mapPointStore.points[index].photoOutdated = false
                                            mapPointStore.save()
                                        }
                                        print("📸 [PHOTO_TRACE] Captured photo for MapPoint \(String(targetMapPointID.uuidString.prefix(8)))")
                                    }
                                }
                            }
                        }
                    }
                } else {
                    print("⚠️ [PHOTO_TRACE] Photo capture skipped - not in placingVertices state")
                }
                
                // Create ARMarker
                let arPosition = simd_float3(positionArray[0], positionArray[1], positionArray[2])
                let mapPoint = mapPointStore.points.first(where: { $0.id == targetMapPointID })
                let mapCoordinates = mapPoint?.mapPoint ?? CGPoint.zero
                
                // Log AR position and map position correlation
                print("🔗 AR Marker planted at AR(\(String(format: "%.2f", arPosition.x)), \(String(format: "%.2f", arPosition.y)), \(String(format: "%.2f", arPosition.z))) meters for Map Point (\(String(format: "%.1f", mapCoordinates.x)), \(String(format: "%.1f", mapCoordinates.y))) pixels")
                
                let marker = ARMarker(
                    id: markerID,
                    linkedMapPointID: targetMapPointID,
                    arPosition: arPosition,
                    mapCoordinates: mapCoordinates,
                    isAnchor: false
                )
                
                // Determine source type: ghostConfirm or normal calibration
                // Ghost adjustments (including reposition) go through the same path as normal calibration
                // because they use getCurrentVertexID() which returns the correct MapPoint
                let sourceType: SourceType = isGhostConfirm ? .ghostConfirm : .calibration
                
                // Calculate distortion vector if originalGhostPosition is available
                let distortionVector: simd_float3?
                if let originalGhostPosArray = notification.userInfo?["originalGhostPosition"] as? [Float],
                   originalGhostPosArray.count == 3 {
                    let originalGhostPos = simd_float3(originalGhostPosArray[0], originalGhostPosArray[1], originalGhostPosArray[2])
                    distortionVector = arPosition - originalGhostPos
                    print("📍 [DISTORTION_VECTOR] Calculated: \(distortionVector!) (new: \(arPosition) - original: \(originalGhostPos))")
                } else {
                    distortionVector = nil
                }
                
                // Register with coordinator
                arCalibrationCoordinator.registerMarker(
                    mapPointID: targetMapPointID,
                    marker: marker,
                    sourceType: sourceType,
                    distortionVector: distortionVector
                )
                
                print("✅ Registered marker \(String(markerID.uuidString.prefix(8))) for MapPoint \(String(targetMapPointID.uuidString.prefix(8)))")
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UpdateMapPointPhoto"))) { notification in
                // Handle photo update request
                guard let mapPointID = notification.userInfo?["mapPointID"] as? UUID else {
                    print("⚠️ No mapPointID in UpdateMapPointPhoto notification")
                    return
                }
                
                // Trigger photo capture flow (for now, just log - can be enhanced with camera picker)
                print("📸 Photo update requested for MapPoint \(String(mapPointID.uuidString.prefix(8)))")
                // TODO: Integrate with photo capture UI when available
                // For now, this notification can be handled by external photo capture flow
            }
            
            // Overlay UI elements with precise positioning using GeometryReader
            GeometryReader { geo in
                // Exit button (top-left) - slightly higher
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }
                .position(x: 40, y: 50) // Slightly higher, safely above PiP/Reference UI
                .zIndex(1000)
                
                // Plane Visualization Toggle (top-right, above PiP map)
                VStack {
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            showPlaneVisualization.toggle()
                        }) {
                            Image(systemName: showPlaneVisualization ? "grid.circle.fill" : "grid.circle")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(showPlaneVisualization ? .purple : .gray)
                                .frame(width: 50, height: 50)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 20)
                        .padding(.top, 60)
                    }
                    Spacer()
                }
                .zIndex(4000)
                
                // SVG Export Button (bottom-right corner)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            exportARSessionSVG()
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 16)
                        .padding(.bottom, 20)
                    }
                }
                .zIndex(4000)
                
                // PiP Map View (top-right)
                // focusedPointID is now computed reactively inside ARPiPMapView
                ARPiPMapView(
                    isCalibrationMode: isCalibrationMode,
                    selectedTriangle: selectedTriangle,
                    autoZoomToTriangle: true  // Enable auto-zoom to fit triangle
                )
                    .environmentObject(mapPointStore)
                    .environmentObject(locationManager)
                    .environmentObject(arCalibrationCoordinator)
                    .environmentObject(zoneStore)
                    .environmentObject(zoneGroupStore)
                    .allowsHitTesting(false)  // Prevent PiP map from intercepting gestures
                    .frame(width: 280, height: 220)
                    .onChange(of: arCalibrationCoordinator.calibrationState) { oldState, newState in
                        // Only log on actual state CHANGES, not every recomputation
                        guard oldState != newState else { return }
                        
                        print("🔍 [PIP_MAP] State changed: \(arCalibrationCoordinator.stateDescription)")
                        
                        if case .readyToFill = newState {
                            print("🎯 [PIP_MAP] Triangle complete - should frame entire triangle")
                        }
                    }
                    .cornerRadius(12)
                    .position(x: geo.size.width - 120, y: 130) // Adjusted for larger size
                    .zIndex(998)
                
                // MILESTONE 3: Placement blocked warning overlay
                if showPlacementWarning, arCalibrationCoordinator.blockedPlacement != nil {
                    VStack(spacing: 16) {
                        // Warning icon and message
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.yellow)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Marker Too Far")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("\(String(format: "%.1f", warningDistance))m from expected")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            // Arrow pointing toward ghost
                            Image(systemName: "chevron.right.2")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.orange)
                        }
                        
                        // Action buttons
                        HStack(spacing: 20) {
                            Button(action: {
                                arCalibrationCoordinator.cancelBlockedPlacement()
                                showPlacementWarning = false
                            }) {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                    Text("Re-place")
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                            
                            Button(action: {
                                arCalibrationCoordinator.overrideBlockedPlacement()
                                showPlacementWarning = false
                            }) {
                                HStack {
                                    Image(systemName: "exclamationmark.circle")
                                    Text("Override")
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.red.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(24)
                    .background(Color.black.opacity(0.85))
                    .cornerRadius(16)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    .zIndex(1000)
                }
                
                // Reference Image View (top-left, below xmark) - only when placing vertices
                if case .placingVertices = arCalibrationCoordinator.calibrationState,
                   let currentVertexID = arCalibrationCoordinator.getCurrentVertexID(),
                   let mapPoint = mapPointStore.points.first(where: { $0.id == currentVertexID }) {
                    
                    if let photoData = mapPointStore.loadPhotoFromDisk(for: currentVertexID) ?? mapPoint.locationPhotoData,
                       let uiImage = UIImage(data: photoData) {
                        
                        ARReferenceImageView(
                            image: uiImage,
                            mapPoint: mapPoint,
                            isOutdated: mapPoint.photoOutdated ?? false
                        )
                        .frame(width: 180, height: 180)
                        .cornerRadius(12)
                        .position(x: 100, y: 110) // 100 = half width + margin
                        .zIndex(999)
                        .onAppear {
                            // Only print if vertex ID changed (prevent spam)
                            if lastPrintedPhotoRefVertexID != currentVertexID {
                                print("🔍 [PHOTO_REF] Displaying photo reference for vertex \(String(currentVertexID.uuidString.prefix(8)))")
                                lastPrintedPhotoRefVertexID = currentVertexID
                            }
                        }
                        
                    } else {
                        // ⛔️ No photo available — show fallback placeholder
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.5))
                            .frame(width: 180, height: 180)
                            .overlay(
                                Text("No Photo")
                                    .foregroundColor(.white.opacity(0.6))
                                    .font(.caption)
                            )
                            .position(x: 100, y: 110)
                            .zIndex(999)
                            .onAppear {
                                // Only print if vertex ID changed (prevent spam)
                                if lastPrintedPhotoRefVertexID != currentVertexID {
                                    print("🔍 [PHOTO_REF] Displaying photo reference for vertex \(String(currentVertexID.uuidString.prefix(8)))")
                                    lastPrintedPhotoRefVertexID = currentVertexID
                                }
                            }
                    }
                }
            }
            
            // Tap-to-Place Button (bottom) - during triangle calibration OR swath survey anchoring OR zone corner calibration
            // Swath Survey and Zone Corner use calibrationState.placingVertices with currentMode == .idle
            let showCalibrationUI: Bool = {
                if case .triangleCalibration = currentMode {
                    return true
                }
                // Swath Survey: show UI during vertex placement AND when ready to fill
                if arViewLaunchContext.launchMode == .swathSurvey {
                    if case .placingVertices = arCalibrationCoordinator.calibrationState {
                        return true
                    }
                    if case .readyToFill = arCalibrationCoordinator.calibrationState {
                        return true
                    }
                }
                // Zone Corner Calibration: show UI during vertex placement AND when ready to fill
                if arViewLaunchContext.launchMode == .zoneCornerCalibration {
                    if case .placingVertices = arCalibrationCoordinator.calibrationState {
                        return true
                    }
                    if case .readyToFill = arCalibrationCoordinator.calibrationState {
                        return true
                    }
                }
                return false
            }()
            
            if showCalibrationUI {
                VStack {
                    Spacer()
                    
                    // Outdated photo warning (non-blocking call-to-action)
                    if let currentVertexID = arCalibrationCoordinator.getCurrentVertexID(),
                       let mapPoint = mapPointStore.points.first(where: { $0.id == currentVertexID }),
                       mapPoint.photoOutdated == true,
                       mapPoint.locationPhotoData != nil || mapPoint.photoFilename != nil {
                        VStack(spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.yellow)
                                Text("Reference image is outdated.")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(8)
                            
                            Button(action: {
                                // Trigger photo update flow
                                NotificationCenter.default.post(
                                    name: NSNotification.Name("UpdateMapPointPhoto"),
                                    object: nil,
                                    userInfo: ["mapPointID": currentVertexID]
                                )
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 12))
                                    Text("Retake Photo")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.red.opacity(0.9))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.bottom, 12)
                    }
                    
                    // Progress dots indicator - only show during initial triangle calibration
                    // Hide after first triangle is calibrated (crawl mode uses single ghost confirmations)
                    if arCalibrationCoordinator.sessionCalibratedTriangles.isEmpty {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(arCalibrationCoordinator.progressDots.0 ? Color.green : Color.gray)
                                .frame(width: 12, height: 12)
                            Circle()
                                .fill(arCalibrationCoordinator.progressDots.1 ? Color.green : Color.gray)
                                .frame(width: 12, height: 12)
                            Circle()
                                .fill(arCalibrationCoordinator.progressDots.2 ? Color.green : Color.gray)
                                .frame(width: 12, height: 12)
                        }
                        .padding(.bottom, 8)
                    }
                    
                    // Status text
                    Text(arCalibrationCoordinator.statusText)
                        .font(.footnote)
                        .foregroundColor(.white)
                        .padding(.bottom, 8)
                    
                    // Place Marker / Ghost Interaction buttons
                    // Show during vertex placement OR when in readyToFill with a ghost selected (crawl mode)
                    // BUT NOT when reposition is pending (user tapped "Reposition Marker")
                    // Ghost interaction buttons show whenever a ghost is selected
                    // This ensures ghosts can always be confirmed/adjusted regardless of state
                    let shouldShowGhostButtons: Bool = {
                        // Always show if a ghost is selected (enables interaction in any state)
                        if arCalibrationCoordinator.selectedGhostMapPointID != nil {
                            return true
                        }
                        // Also show during vertex placement for normal workflow
                        if case .placingVertices = arCalibrationCoordinator.calibrationState {
                            return true
                        }
                        return false
                    }()
                    
                    // Show ghost interaction buttons only when:
                    // - A ghost is selected AND
                    // - We're not in reposition mode (waiting for free placement)
                    // "Plot Next Zone" button for wavefront expansion
                    if showNextZoneButton && arCalibrationCoordinator.selectedGhostMapPointID == nil {
                        VStack {
                            Spacer()
                            Button(action: {
                                arCalibrationCoordinator.startNextZoneCalibration()
                                showNextZoneButton = false
                            }) {
                                HStack {
                                    Image(systemName: "arrow.triangle.branch")
                                    Text("Plot Next Zone")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .cornerRadius(10)
                            }
                            .padding(.bottom, 100)
                        }
                    }
                    
                    if shouldShowGhostButtons {
                        GhostInteractionButtons(
                            arCalibrationCoordinator: arCalibrationCoordinator,
                            onConfirmGhost: {
                                print("🎯 [GHOST_UI] Confirm Placement tapped")
                                print("   Current state: \(arCalibrationCoordinator.stateDescription)")
                                
                                guard let ghostMapPointID = arCalibrationCoordinator.selectedGhostMapPointID,
                                      let ghostPosition = arCalibrationCoordinator.selectedGhostEstimatedPosition else {
                                    print("⚠️ [GHOST_UI] No ghost position/ID available for confirmation")
                                    return
                                }
                                
                                // DEMOTE RE-CONFIRM: If this ghost was demoted from an AR marker,
                                // simply re-place the marker at the ghost position (no crawl/adjacent activation)
                                if arCalibrationCoordinator.demotedGhostMapPointIDs.contains(ghostMapPointID) {
                                    print("🔄 [DEMOTE_READJUST] Re-confirming demoted marker at ghost position")
                                    print("   MapPoint: \(String(ghostMapPointID.uuidString.prefix(8)))")
                                    
                                    // Remove ghost from scene
                                    NotificationCenter.default.post(
                                        name: NSNotification.Name("RemoveGhostMarker"),
                                        object: nil,
                                        userInfo: ["mapPointID": ghostMapPointID]
                                    )
                                    
                                    // Place marker at ghost position
                                    NotificationCenter.default.post(
                                        name: NSNotification.Name("ConfirmGhostMarker"),
                                        object: nil,
                                        userInfo: [
                                            "position": [ghostPosition.x, ghostPosition.y, ghostPosition.z],
                                            "mapPointID": ghostMapPointID,
                                            "isGhostConfirm": true,
                                            "isDemoteReconfirm": true
                                        ]
                                    )
                                    
                                    // Clear demote state
                                    arCalibrationCoordinator.demotedGhostMapPointIDs.remove(ghostMapPointID)
                                    arCalibrationCoordinator.selectedGhostMapPointID = nil
                                    arCalibrationCoordinator.selectedGhostEstimatedPosition = nil
                                    
                                    print("✅ [DEMOTE_READJUST] Marker re-placed, demote state cleared")
                                    return
                                }
                                
                                // ZONE CORNER MODE: Confirm ghost without requiring active triangle
                                if arCalibrationCoordinator.isZoneCornerMode {
                                    print("🎯 [ZONE_CORNER_CONFIRM] Confirming ghost at estimated position")
                                    print("   MapPoint: \(String(ghostMapPointID.uuidString.prefix(8)))")
                                    
                                    // Track that this ghost was adjusted (prevents re-planting)
                                    arCalibrationCoordinator.adjustedGhostMapPoints.insert(ghostMapPointID)
                                    
                                    // Remove ghost from scene
                                    NotificationCenter.default.post(
                                        name: NSNotification.Name("RemoveGhostMarker"),
                                        object: nil,
                                        userInfo: ["mapPointID": ghostMapPointID]
                                    )
                                    
                                    // Place real marker at ghost position
                                    NotificationCenter.default.post(
                                        name: NSNotification.Name("ConfirmGhostMarker"),
                                        object: nil,
                                        userInfo: [
                                            "position": [ghostPosition.x, ghostPosition.y, ghostPosition.z],
                                            "mapPointID": ghostMapPointID,
                                            "isGhostConfirm": true,
                                            "isZoneCornerMode": true
                                        ]
                                    )
                                    
                                    // Clear selection
                                    arCalibrationCoordinator.selectedGhostMapPointID = nil
                                    arCalibrationCoordinator.selectedGhostEstimatedPosition = nil
                                    
                                    print("✅ [ZONE_CORNER_CONFIRM] Ghost confirmed as AR marker")
                                    return
                                }
                                
                                // Check if we're in crawl mode (readyToFill or surveyMode + ghost selected)
                                if arCalibrationCoordinator.isCrawlEligibleState,
                                   let currentTriangleID = arCalibrationCoordinator.activeTriangleID {
                                    
                                    print("🔗 [CRAWL_CONFIRM] Confirming ghost at estimated position for crawl")
                                    
                                    // Activate the adjacent triangle (wasAdjusted: false = confirmed at ghost position)
                                    if let newTriangleID = arCalibrationCoordinator.activateAdjacentTriangle(
                                        ghostMapPointID: ghostMapPointID,
                                        ghostPosition: ghostPosition,
                                        currentTriangleID: currentTriangleID,
                                        wasAdjusted: false
                                    ) {
                                        print("✅ [CRAWL_CONFIRM] Successfully activated adjacent triangle \(String(newTriangleID.uuidString.prefix(8)))")
                                        
                                        // Remove the ghost marker and place real marker
                                        NotificationCenter.default.post(
                                            name: NSNotification.Name("RemoveGhostMarker"),
                                            object: nil,
                                            userInfo: ["mapPointID": ghostMapPointID]
                                        )
                                        
                                        NotificationCenter.default.post(
                                            name: NSNotification.Name("ConfirmGhostMarker"),
                                            object: nil,
                                            userInfo: [
                                                "position": [ghostPosition.x, ghostPosition.y, ghostPosition.z],
                                                "mapPointID": ghostMapPointID,
                                                "isGhostConfirm": true,
                                                "isCrawlMode": true
                                            ]
                                        )
                                    } else {
                                        print("⚠️ [CRAWL_CONFIRM] Failed to activate adjacent triangle")
                                    }
                                } else {
                                    // Normal ghost confirmation during placingVertices (3rd vertex)
                                    print("🎯 [GHOST_UI] Confirming ghost at estimated position (normal mode)")
                                    
                                    NotificationCenter.default.post(
                                        name: NSNotification.Name("ConfirmGhostMarker"),
                                        object: nil,
                                        userInfo: [
                                            "position": [ghostPosition.x, ghostPosition.y, ghostPosition.z],
                                            "mapPointID": ghostMapPointID,
                                            "isGhostConfirm": true,
                                            "ghostMapPointID": ghostMapPointID
                                        ]
                                    )
                                }
                            },
                            onPlaceMarker: {
                                print("🔍 [PLACE_MARKER_BTN] Button tapped")
                                print("   Current state: \(arCalibrationCoordinator.stateDescription)")
                                
                                // DEMOTE RE-ADJUST: If this ghost was demoted from an AR marker,
                                // simply place marker at crosshair (no crawl/adjacent activation)
                                if let ghostMapPointID = arCalibrationCoordinator.selectedGhostMapPointID,
                                   arCalibrationCoordinator.demotedGhostMapPointIDs.contains(ghostMapPointID) {
                                    print("🔄 [DEMOTE_READJUST] Adjusting demoted marker to crosshair position")
                                    print("   MapPoint: \(String(ghostMapPointID.uuidString.prefix(8)))")
                                    
                                    // Place marker at crosshair - ghost removal deferred until placement succeeds
                                    NotificationCenter.default.post(
                                        name: NSNotification.Name("PlaceMarkerAtCursor"),
                                        object: nil,
                                        userInfo: [
                                            "ghostMapPointID": ghostMapPointID,
                                            "removeGhostOnSuccess": true,
                                            "isDemoteReadjust": true
                                        ]
                                    )
                                    
                                    // State clearing happens in handlePlaceMarkerAtCursor after successful placement
                                    return
                                }
                                
                                // Check if we're in crawl mode (.readyToFill or .surveyMode + ghost selected)
                                if arCalibrationCoordinator.isCrawlEligibleState,
                                   let ghostMapPointID = arCalibrationCoordinator.selectedGhostMapPointID,
                                   let currentTriangleID = arCalibrationCoordinator.activeTriangleID {
                                    
                                    print("🔗 [CRAWL_ADJUST] Adjusting ghost position via crosshair")
                                    
                                    // Post crosshair placement with crawl mode info
                                    NotificationCenter.default.post(
                                        name: NSNotification.Name("PlaceMarkerAtCursor"),
                                        object: nil,
                                        userInfo: [
                                            "isCrawlMode": true,
                                            "ghostMapPointID": ghostMapPointID,
                                            "currentTriangleID": currentTriangleID
                                        ]
                                    )
                                    
                                    // Clear reposition mode if it was active
                                    arCalibrationCoordinator.repositionModeActive = false
                                } else if case .placingVertices = arCalibrationCoordinator.calibrationState,
                                          let ghostMapPointID = arCalibrationCoordinator.selectedGhostMapPointID {
                                    print("🔗 [3RD_VERTEX_ADJUST] Adjusting vertex ghost position via crosshair")
                                    print("   Ghost MapPoint: \(String(ghostMapPointID.uuidString.prefix(8)))")
                                    
                                    // Place marker at crosshair - ghost removal deferred until placement succeeds
                                    NotificationCenter.default.post(
                                        name: NSNotification.Name("PlaceMarkerAtCursor"),
                                        object: nil,
                                        userInfo: [
                                            "ghostMapPointID": ghostMapPointID,
                                            "removeGhostOnSuccess": true
                                        ]
                                    )
                                    
                                    // Clear reposition mode if it was active
                                    arCalibrationCoordinator.repositionModeActive = false
                                } else if let ghostMapPointID = arCalibrationCoordinator.selectedGhostMapPointID {
                                    // Zone Corner mode: simple adjustment (no crawl/adjacent triangle activation)
                                    if arCalibrationCoordinator.isZoneCornerMode {
                                        print("🎯 [ZONE_CORNER_ADJUST] Adjusting ghost position via crosshair")
                                        print("   Ghost MapPoint: \(String(ghostMapPointID.uuidString.prefix(8)))")
                                        
                                        // Get original ghost position for distortion calculation
                                        var ghostUserInfo: [String: Any] = [
                                            "ghostMapPointID": ghostMapPointID,
                                            "removeGhostOnSuccess": true
                                        ]
                                        
                                        // Include original position if available
                                        if let originalPos = arCalibrationCoordinator.selectedGhostEstimatedPosition {
                                            ghostUserInfo["originalGhostPosition"] = [originalPos.x, originalPos.y, originalPos.z]
                                            print("📍 [GHOST_POS_PASS] Passing originalGhostPosition: (\(String(format: "%.3f", originalPos.x)), \(String(format: "%.3f", originalPos.y)), \(String(format: "%.3f", originalPos.z)))")
                                        } else {
                                            print("⚠️ [GHOST_POS_PASS] selectedGhostEstimatedPosition is nil!")
                                        }
                                        
                                        // Place marker at crosshair - ghost removal deferred until placement succeeds
                                        NotificationCenter.default.post(
                                            name: NSNotification.Name("PlaceMarkerAtCursor"),
                                            object: nil,
                                            userInfo: ghostUserInfo
                                        )
                                        
                                        // Clear ghost selection
                                        arCalibrationCoordinator.selectedGhostMapPointID = nil
                                        arCalibrationCoordinator.selectedGhostEstimatedPosition = nil
                                    } else {
                                        // Crawl mode - adjust ghost and activate adjacent triangle
                                        print("🔗 [CRAWL_ADJUST] Adjusting ghost position via crosshair")
                                        print("   Ghost MapPoint: \(String(ghostMapPointID.uuidString.prefix(8)))")
                                        print("   Active Triangle: \(arCalibrationCoordinator.activeTriangleID.map { String($0.uuidString.prefix(8)) } ?? "nil")")
                                        
                                        // Get original ghost position for distortion vector calculation
                                        let originalGhostPosition = arCalibrationCoordinator.selectedGhostEstimatedPosition
                                        
                                        NotificationCenter.default.post(
                                            name: NSNotification.Name("PlaceMarkerAtCursor"),
                                            object: nil,
                                            userInfo: [
                                                "isCrawlMode": true,
                                                "ghostMapPointID": ghostMapPointID,
                                                "currentTriangleID": arCalibrationCoordinator.activeTriangleID as Any,
                                                "originalGhostPosition": originalGhostPosition.map { [$0.x, $0.y, $0.z] } as Any,
                                                "removeGhostOnSuccess": true
                                            ]
                                        )
                                        
                                        // Clear ghost selection
                                        arCalibrationCoordinator.selectedGhostMapPointID = nil
                                        arCalibrationCoordinator.selectedGhostEstimatedPosition = nil
                                    }
                                    
                                    // Clear reposition mode if it was active
                                    arCalibrationCoordinator.repositionModeActive = false
                                    
                                    // Transition to readyToFill and trigger adjacent triangle discovery
                                    // This ensures the crawl can continue after promoting a ghost in any state
                                    // EXCEPT in Zone Corner mode where all ghosts are already planted
                                    if arCalibrationCoordinator.isZoneCornerMode {
                                        print("🔗 [ZONE_CORNER_ADJUST] Skipping adjacent refresh - ghosts already planted")
                                        // Just stay in readyToFill, don't trigger duplicate ghost creation
                                    } else {
                                        print("🔗 [GENERIC_ADJUST] Triggering adjacent triangle discovery")
                                        arCalibrationCoordinator.transitionToReadyToFillAndRefreshGhosts(placedMapPointID: ghostMapPointID)
                                    }
                                } else {
                                    // Normal crosshair placement (no ghost selected)
                                    NotificationCenter.default.post(
                                        name: NSNotification.Name("PlaceMarkerAtCursor"),
                                        object: nil
                                    )
                                }
                            },
                            onReposition: {
                                guard let ghostID = arCalibrationCoordinator.selectedGhostMapPointID else {
                                    print("⚠️ [GHOST_REPOSITION] No ghost selected for reposition")
                                    return
                                }
                                
                                print("🔄 [GHOST_REPOSITION] Entering reposition mode for MapPoint \(String(ghostID.uuidString.prefix(8)))")
                                print("   Ghost stays in scene, selection stays active")
                                print("   User can walk to correct position and tap 'Place Marker to Adjust'")
                                
                                // Simply enable reposition mode - keep ghost in scene, keep selection
                                // This bypasses the proximity/in-frame requirement in updateGhostSelection()
                                arCalibrationCoordinator.repositionModeActive = true
                            },
                            onResetCanonical: {
                                print("🔄 [GHOST_UI] Reset Position Data tapped")
                                guard let ghostMapPointID = arCalibrationCoordinator.selectedGhostMapPointID else {
                                    print("⚠️ [GHOST_UI] No ghost selected for canonical reset")
                                    return
                                }
                                
                                // Purge canonical data for this specific MapPoint
                                let cleared = mapPointStore.purgeCanonicalPosition(for: ghostMapPointID)
                                
                                if cleared {
                                    print("✅ [GHOST_UI] Canonical data cleared for \(String(ghostMapPointID.uuidString.prefix(8)))")
                                    print("   Ghost will now use barycentric interpolation")
                                    
                                    // Optionally: Could trigger ghost position recalculation here
                                    // For now, user can dismiss and re-approach to see new position
                                }
                            }
                        )
                        .padding(.bottom, 40)
                    } else if shouldShowGhostButtons {
                        // Show standard "Place Marker" button when we should show buttons but ghost interaction buttons are hidden
                        Button(action: {
                            print("🔍 [PLACE_MARKER_BTN] Button tapped")
                            NotificationCenter.default.post(
                                name: NSNotification.Name("PlaceMarkerAtCursor"),
                                object: nil
                            )
                        }) {
                            Text("Place Marker")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                    
                    // Survey Button Bar - show different layout for Zone Mode vs Calibration Crawl
                    // Ghost Confirm/Adjust takes UI priority
                    // Hide during survey marker dwell
                    if arCalibrationCoordinator.selectedGhostMapPointID == nil && !surveySessionCollector.isCollecting {
                        if arCalibrationCoordinator.isZoneCornerMode {
                            // ZONE MODE LAYOUT
                            SurveyButtonBar(
                                userContainingTriangleID: nil,
                                hasAnyCalibratedTriangle: false,
                                fillableKnownCount: 0,
                                fillableBakedCount: 0,
                                canFillCurrentTriangle: false,
                                currentTriangleHasMarkers: false,
                                hasAnySurveyMarkers: false,
                                onFillTriangle: {},
                                onClearTriangle: {},
                                onFillKnown: {},
                                onDefineSwath: {},
                                onFillMap: {},
                                onClearAll: {},
                                isZoneCornerMode: true,
                                hasZoneSurveyMarkers: zoneHasBeenFlooded,
                                onFloodZone: {
                                    print("🌊 [ZONE_FLOOD] Flood Zone triggered")
                                    zoneHasBeenFlooded = true
                                    NotificationCenter.default.post(
                                        name: NSNotification.Name("FloodZoneWithSurveyMarkers"),
                                        object: nil
                                    )
                                },
                                onClearZone: {
                                    print("🧹 [ZONE_CLEAR] Clear Zone triggered")
                                    zoneHasBeenFlooded = false
                                    NotificationCenter.default.post(
                                        name: NSNotification.Name("ClearAllSurveyMarkers"),
                                        object: nil
                                    )
                                    trianglesWithSurveyMarkers.removeAll()
                                },
                                isRovingMode: false,
                                onToggleRovingMode: {
                                    // Placeholder - will be implemented later
                                },
                                onExportSVG: {
                                    // Placeholder - will be implemented later
                                },
                                onManualMarker: {
                                    NotificationCenter.default.post(
                                        name: .placeManualSurveyMarker,
                                        object: nil
                                    )
                                }
                            )
                        } else {
                            // EXISTING CALIBRATION CRAWL LAYOUT
                        SurveyButtonBar(
                        userContainingTriangleID: userContainingTriangleID,
                        hasAnyCalibratedTriangle: !arCalibrationCoordinator.sessionCalibratedTriangles.isEmpty,
                        fillableKnownCount: arCalibrationCoordinator.countFillableTrianglesSessionAndGhost(),
                        fillableBakedCount: arCalibrationCoordinator.countFillableTrianglesBaked(),
                        canFillCurrentTriangle: {
                            guard let triangleID = userContainingTriangleID else { return false }
                            return arCalibrationCoordinator.sessionCalibratedTriangles.contains(triangleID) ||
                                   arCalibrationCoordinator.triangleCanBeFilled(triangleID)
                        }(),
                        currentTriangleHasMarkers: {
                            guard let triangleID = userContainingTriangleID else { return false }
                            return trianglesWithSurveyMarkers.contains(triangleID)
                        }(),
                        hasAnySurveyMarkers: !trianglesWithSurveyMarkers.isEmpty,
                        onFillTriangle: {
                            guard let triangleID = userContainingTriangleID else { return }
                            print("🎯 [FILL_TRIANGLE_BTN] Button tapped for triangle \(String(triangleID.uuidString.prefix(8)))")
                            
                            arCalibrationCoordinator.enterSurveyMode()
                            
                            NotificationCenter.default.post(
                                name: NSNotification.Name("FillTriangleWithSurveyMarkers"),
                                object: nil,
                                userInfo: [
                                    "triangleID": triangleID,
                                    "spacing": surveySpacing,
                                    "arWorldMapStore": arCalibrationCoordinator.arStoreAccess,
                                    "triangleStore": arCalibrationCoordinator.triangleStoreAccess
                                ]
                            )
                            
                            trianglesWithSurveyMarkers.insert(triangleID)
                        },
                        onClearTriangle: {
                            guard let triangleID = userContainingTriangleID else { return }
                            print("🧹 [CLEAR_TRIANGLE_BTN] Button tapped for triangle \(String(triangleID.uuidString.prefix(8)))")
                            
                            NotificationCenter.default.post(
                                name: NSNotification.Name("ClearTriangleMarkers"),
                                object: nil,
                                userInfo: ["triangleID": triangleID]
                            )
                            
                            trianglesWithSurveyMarkers.remove(triangleID)
                        },
                        onFillKnown: {
                            print("🟢 [FILL_KNOWN_BTN] Fill Known button tapped")
                            
                            let fillableTriangleIDs = arCalibrationCoordinator.getFillableTriangleIDsSessionAndGhost()
                            
                            guard !fillableTriangleIDs.isEmpty else {
                                print("⚠️ [FILL_KNOWN_BTN] No fillable triangles (session+ghost)")
                                return
                            }
                            
                            print("🟢 [FILL_KNOWN_BTN] Found \(fillableTriangleIDs.count) fillable triangle(s) with session/ghost markers")
                            
                            arCalibrationCoordinator.enterSurveyMode()
                            
                            NotificationCenter.default.post(
                                name: NSNotification.Name("FillKnownTriangles"),
                                object: nil,
                                userInfo: [
                                    "triangleIDs": fillableTriangleIDs,
                                    "spacing": surveySpacing,
                                    "triangleStore": arCalibrationCoordinator.triangleStoreAccess
                                ]
                            )
                            
                            for triangleID in fillableTriangleIDs {
                                trianglesWithSurveyMarkers.insert(triangleID)
                            }
                        },
                        onDefineSwath: {
                            print("🟣 [DEFINE_SWATH_BTN] Define Swath button tapped")
                            
                            guard let referenceTriangleID = userContainingTriangleID,
                                  let referenceTriangle = arCalibrationCoordinator.triangleStoreAccess.triangle(withID: referenceTriangleID) else {
                                print("⚠️ [DEFINE_SWATH_BTN] No reference triangle available")
                                return
                            }
                            
                            print("🟣 [DEFINE_SWATH_BTN] Reference triangle: \(String(referenceTriangleID.uuidString.prefix(8)))")
                            
                            arCalibrationCoordinator.plantGhostsForScope(
                                scope: .allTriangles,
                                referenceTriangle: referenceTriangle,
                                triangleStore: arCalibrationCoordinator.triangleStoreAccess,
                                mapPointStore: mapPointStore,
                                arWorldMapStore: arWorldMapStore
                            )
                        },
                        onFillMap: {
                            print("🗺️ [FILL_MAP_BTN] Fill Map button tapped")
                            
                            let fillableTriangleIDs = arCalibrationCoordinator.getFillableTriangleIDsBaked()
                            
                            guard !fillableTriangleIDs.isEmpty else {
                                print("⚠️ [FILL_MAP_BTN] No fillable triangles with baked data")
                                return
                            }
                            
                            print("🗺️ [FILL_MAP_BTN] Found \(fillableTriangleIDs.count) fillable triangle(s) with baked data")
                            
                            arCalibrationCoordinator.enterSurveyMode()
                            
                            NotificationCenter.default.post(
                                name: NSNotification.Name("FillMapWithSurveyMarkers"),
                                object: nil,
                                userInfo: [
                                    "triangleIDs": fillableTriangleIDs,
                                    "spacing": surveySpacing,
                                    "triangleStore": arCalibrationCoordinator.triangleStoreAccess,
                                    "clearFirst": true
                                ]
                            )
                            
                            trianglesWithSurveyMarkers.removeAll()
                            for triangleID in fillableTriangleIDs {
                                trianglesWithSurveyMarkers.insert(triangleID)
                            }
                        },
                        onClearAll: {
                            print("🧹 [CLEAR_ALL_BTN] Clear All button tapped")
                            
                            NotificationCenter.default.post(
                                name: NSNotification.Name("ClearAllSurveyMarkers"),
                                object: nil
                            )
                            
                            trianglesWithSurveyMarkers.removeAll()
                        }
                        )
                        }
                    }
                }
                .zIndex(997)
            }

            // Dwell Timer Display - centered on screen when inside ANY survey marker sphere
            // This displays regardless of mode (idle, swath survey, etc.)
            if showDwellTimer {
                VStack(spacing: 4) {
                    Text(String(format: "%.1f", dwellTimerValue))
                        .font(.system(size: 72, weight: .heavy, design: .monospaced))
                        .foregroundColor(dwellTimerColor())
                    Text("sec")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(dwellTimerColor().opacity(0.8))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .zIndex(999)
            }
            
            // Facing Rose HUD - shows sector coverage during dwell
            GeometryReader { geo in
                FacingRoseHUD(isVisible: showDwellTimer)
                    .position(x: 80, y: geo.size.height - 100)
            }
            .zIndex(998)  // Just below dwell timer (999)
            .allowsHitTesting(false)
            
            // Place AR Marker Button + Strategy Picker (bottom) - only in idle mode with no triangle selected
            // Exclude Swath Survey and Zone Corner Calibration modes - they have their own workflows
            if currentMode == .idle && selectedTriangle == nil && arViewLaunchContext.launchMode != .swathSurvey && arViewLaunchContext.launchMode != .zoneCornerCalibration {
                VStack {
                    Spacer()
                    
                    // Test Marker Buttons Row
                    HStack(spacing: 12) {
                        // Place Test Survey Marker button
                        Button(action: {
                            print("🧪 [TEST_SURVEY_BTN] Button tapped")
                            NotificationCenter.default.post(
                                name: NSNotification.Name("PlaceTestSurveyMarker"),
                                object: nil
                            )
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.title2)
                                Text("Survey")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.red.opacity(0.85))
                            .cornerRadius(12)
                        }
                        
                        // Place Test Zone Corner Marker button
                        Button(action: {
                            print("💎 [TEST_CORNER_BTN] Button tapped")
                            NotificationCenter.default.post(
                                name: NSNotification.Name("PlaceTestZoneCornerMarker"),
                                object: nil
                            )
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "cube.fill")
                                    .font(.title2)
                                Text("Corner")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.purple.opacity(0.85))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 60)
                }
                .zIndex(997)
            }
            
            // Calibrate / Relocalize buttons - shown when triangle is selected but NOT calibrated or NOT in calibration mode
            if let triangle = selectedTriangle,
               currentMode != .triangleCalibration(triangleID: triangle.id) {
                VStack {
                    Spacer()
                    
                    HStack(spacing: 40) {
                        // Calibrate Patch button (left)
                        Button(action: {
                            // Enter calibration mode
                            currentMode = .triangleCalibration(triangleID: triangle.id)
                            arCalibrationCoordinator.startCalibration(for: triangle.id)
                            arCalibrationCoordinator.setVertices(triangle.vertexIDs)
                            print("🎯 Entering calibration mode for triangle \(String(triangle.id.uuidString.prefix(8)))")
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: "triangle")
                                    .font(.system(size: 24, weight: .semibold))
                                Text("Calibrate Patch")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .background(Color.orange.opacity(0.9))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                        
                        // Relocalize button (right)
                        Button(action: {
                            print("🔄 Relocalize button tapped for triangle \(String(triangle.id.uuidString.prefix(8)))")
                            // TODO: Implement relocalization logic
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: "location.circle")
                                    .font(.system(size: 24, weight: .semibold))
                                Text("Relocalize")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .background(Color.blue.opacity(0.9))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.bottom, 50)
                }
                .zIndex(990)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = svgFileURL {
                ShareSheet(items: [url])
            }
        }
    }
    
    // MARK: - Haptic Feedback Helpers
    
    /// Initialize the CoreHaptics engine
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            print("⚠️ [HAPTICS] Device does not support haptics")
            return
        }
        
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
            print("✅ [HAPTICS] Engine started")
        } catch {
            print("⚠️ [HAPTICS] Engine failed to start: \(error.localizedDescription)")
        }
    }
    
    /// Hard knock haptic
    private func playHardKnock() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred(intensity: 1.0)
        print("🔨 [HAPTICS] Hard knock")
    }
    
    /// Gentle knock haptic
    private func playGentleKnock() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.prepare()
        generator.impactOccurred(intensity: 0.5)
        print("👆 [HAPTICS] Gentle knock")
    }
    
    /// Double knock haptic (two quick taps to signal threshold reached)
    private func playDoubleKnock() {
        guard let engine = hapticEngine else {
            print("⚠️ [HAPTICS] Engine not available for double knock")
            return
        }
        
        do {
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
            
            // Two quick knocks with 100ms gap
            let knock1 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
            let knock2 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0.1)
            
            let pattern = try CHHapticPattern(events: [knock1, knock2], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
            print("🔔 [HAPTICS] Double knock (threshold reached)")
        } catch {
            print("⚠️ [HAPTICS] Failed to play double knock: \(error.localizedDescription)")
        }
    }
    
    /// Start continuous buzz haptic (called on sphere entry)
    private func startContinuousBuzz(initialIntensity: Float) {
        guard let engine = hapticEngine else {
            print("⚠️ [HAPTICS] Engine not available for continuous buzz")
            return
        }
        
        // Clamp intensity to valid range, with minimum of 0.1 to ensure haptic is audible
        let startIntensity = max(0.1, min(1.0, initialIntensity))
        
        do {
            // Create a continuous haptic event with the initial intensity
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: startIntensity)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
            
            let event = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [intensity, sharpness],
                relativeTime: 0,
                duration: 100  // Long duration, we'll stop it manually
            )
            
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            continuousPlayer = try engine.makeAdvancedPlayer(with: pattern)
            try continuousPlayer?.start(atTime: CHHapticTimeImmediate)
            isInsideSphere = true
            ARViewContainer.Coordinator.current?.crosshairNode?.isHidden = true
            
            let coordinator = ARViewContainer.Coordinator.current
            print("🔬 [DIAG] Entered sphere - active systems:")
            print("   - BLE scanning: \(btScanner.isScanning)")
            print("   - Ghost markers tracked: \(coordinator?.ghostMarkerPositions.count ?? 0)")
            print("   - Survey markers in scene: \(coordinator?.surveyMarkers.count ?? 0)")
            print("   - Dwell timer active: \(dwellTimer != nil)")
            
            print("📳 [HAPTICS] Started continuous buzz at intensity \(String(format: "%.2f", startIntensity))")
        } catch {
            print("⚠️ [HAPTICS] Failed to start continuous buzz: \(error.localizedDescription)")
        }
    }
    
    /// Update continuous buzz intensity (0.0 = silent at center, 1.0 = max at edge)
    private func updateBuzzIntensity(_ intensity: Float) {
        guard let player = continuousPlayer, isInsideSphere else { return }
        
        do {
            let intensityParam = CHHapticDynamicParameter(
                parameterID: .hapticIntensityControl,
                value: intensity,
                relativeTime: 0
            )
            try player.sendParameters([intensityParam], atTime: CHHapticTimeImmediate)
        } catch {
            // Silent fail - this is called frequently
        }
    }
    
    /// Stop continuous buzz haptic (called on sphere exit)
    private func stopContinuousBuzz() {
        guard let player = continuousPlayer else { return }
        
        do {
            try player.stop(atTime: CHHapticTimeImmediate)
            continuousPlayer = nil
            isInsideSphere = false
            ARViewContainer.Coordinator.current?.crosshairNode?.isHidden = false
            print("📳 [HAPTICS] Stopped continuous buzz")
        } catch {
            print("⚠️ [HAPTICS] Failed to stop continuous buzz: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Dwell Timer Helpers
    
    /// Start the dwell timer (called on sphere entry)
    private func startDwellTimer() {
        showDwellTimer = true
        dwellStartTime = Date()
        dwellTimerValue = -3.0
        didFireThresholdHaptic = false
        dwellTimer?.invalidate()
        dwellTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            guard let startTime = self.dwellStartTime else { return }
            
            let wasNegative = self.dwellTimerValue < 0
            // Calculate actual elapsed time, offset by 3 seconds (countdown phase)
            self.dwellTimerValue = Date().timeIntervalSince(startTime) - 3.0
            
            // Fire double-knock when crossing zero threshold
            if wasNegative && self.dwellTimerValue >= 0 && !self.didFireThresholdHaptic {
                self.didFireThresholdHaptic = true
                self.playDoubleKnock()
            }
        }
        print("⏱️ [DWELL] Timer started at -3.0")
    }
    
    /// Stop the dwell timer (called on sphere exit)
    private func stopDwellTimer() {
        showDwellTimer = false
        dwellTimer?.invalidate()
        dwellTimer = nil
        dwellStartTime = nil
        print("⏱️ [DWELL] Timer stopped at \(String(format: "%.1f", dwellTimerValue))")
    }
    
    /// Get color for current dwell timer value
    private func dwellTimerColor() -> Color {
        if dwellTimerValue < 0 {
            return .orange
        } else if dwellTimerValue < 3.0 {
            return .yellow
        } else {
            return .green
        }
    }
    
    /// Buzz haptic (continuous vibration, ~0.3s)
    private func playBuzz() {
        guard let engine = hapticEngine else {
            print("⚠️ [HAPTICS] Engine not available for buzz")
            // Fallback to notification haptic
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            return
        }
        
        do {
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
            
            let event = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [intensity, sharpness],
                relativeTime: 0,
                duration: 0.3
            )
            
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
            print("📳 [HAPTICS] Buzz")
        } catch {
            print("⚠️ [HAPTICS] Buzz failed: \(error.localizedDescription)")
        }
    }
    
    /// Fading buzz haptic (decays over 1 second)
    private func playFadingBuzz() {
        guard let engine = hapticEngine else {
            print("⚠️ [HAPTICS] Engine not available for fading buzz")
            return
        }
        
        do {
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            
            let event = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [intensity, sharpness],
                relativeTime: 0,
                duration: 1.0
            )
            
            // Create intensity curve that fades from 1.0 to 0.0 over 1 second
            let fadeStart = CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: 1.0)
            let fadeEnd = CHHapticParameterCurve.ControlPoint(relativeTime: 1.0, value: 0.0)
            
            let intensityCurve = CHHapticParameterCurve(
                parameterID: .hapticIntensityControl,
                controlPoints: [fadeStart, fadeEnd],
                relativeTime: 0
            )
            
            let pattern = try CHHapticPattern(events: [event], parameterCurves: [intensityCurve])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
            print("📉 [HAPTICS] Fading buzz")
        } catch {
            print("⚠️ [HAPTICS] Fading buzz failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - SVG Export
    
    private func exportARSessionSVG() {
        guard let mapSize = arCalibrationCoordinator.cachedMapSizeAccess,
              let metersPerPixel = arCalibrationCoordinator.cachedMetersPerPixelAccess else {
            print("⚠️ [SVG_EXPORT] Missing required data for export")
            return
        }
        
        let sessionID = arWorldMapStore.currentSessionID
        let pixelsPerMeter = 1.0 / Double(metersPerPixel)
        let canonicalOrigin = CGPoint(x: mapSize.width / 2, y: mapSize.height / 2)
        
        var transformedPositions: [(mapPointID: UUID, pixelPosition: CGPoint)] = []
        
        if let transform = arCalibrationCoordinator.cachedCanonicalToSessionTransformAccess {
            for (mapPointID, arPosition) in arCalibrationCoordinator.mapPointARPositions {
                let inverseRotation = -transform.rotationY
                let inverseScale = 1.0 / transform.scale
                
                let translated = arPosition - transform.translation
                let cosR = cos(inverseRotation)
                let sinR = sin(inverseRotation)
                let rotated = SIMD3<Float>(
                    translated.x * cosR - translated.z * sinR,
                    translated.y,
                    translated.x * sinR + translated.z * cosR
                )
                let canonicalPosition = rotated * inverseScale
                
                let pixelX = CGFloat(canonicalPosition.x * Float(pixelsPerMeter)) + canonicalOrigin.x
                let pixelY = CGFloat(canonicalPosition.z * Float(pixelsPerMeter)) + canonicalOrigin.y
                
                transformedPositions.append((mapPointID: mapPointID, pixelPosition: CGPoint(x: pixelX, y: pixelY)))
            }
        }
        
        guard !transformedPositions.isEmpty else {
            print("⚠️ [SVG_EXPORT] No markers to export")
            return
        }
        
        let svgContent = SVGExporter.generateARSessionSVG(
            sessionMarkers: transformedPositions,
            mapWidth: Int(mapSize.width),
            mapHeight: Int(mapSize.height),
            sessionID: sessionID
        )
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd-HHmm"
        let timestamp = dateFormatter.string(from: Date())
        let sessionShort = String(sessionID.uuidString.prefix(8))
        let filename = "ARpoints-\(sessionShort)-\(timestamp).svg"
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try svgContent.write(to: tempURL, atomically: true, encoding: .utf8)
            print("✅ [SVG_EXPORT] Exported \(transformedPositions.count) markers to \(filename)")
            svgFileURL = tempURL
            showShareSheet = true
        } catch {
            print("❌ [SVG_EXPORT] Failed to write file: \(error)")
        }
    }
}

// MARK: - PiP Map Transform

/// Simple transform struct for PiP Map zoom and pan
struct PiPMapTransform {
    var scale: CGFloat
    var offset: CGSize
    
    static let identity = PiPMapTransform(scale: 1.0, offset: .zero)
    
    /// Create a transform that centers the map image in the frame
    static func centered(on imageSize: CGSize, in frameSize: CGSize) -> PiPMapTransform {
        // .scaledToFit() already handles fitting, so scale should be 4.0 (zoomed in)
        return PiPMapTransform(scale: 16.0, offset: .zero)
    }
    
    /// Create a transform that zooms to a specific point
    /// Uses EXACTLY the same logic as MapTransformStore.centerOnPoint()
    static func focused(on point: CGPoint, 
                       imageSize: CGSize, 
                       frameSize: CGSize, 
                       targetZoom: CGFloat = 16.0) -> PiPMapTransform {
        // EXACT COPY of centerOnPoint() logic (lines 42-54):
        let Cmap = CGPoint(x: imageSize.width / 2, y: imageSize.height / 2)
        let v = CGPoint(x: point.x - Cmap.x, y: point.y - Cmap.y)
        
        // For PiP: totalScale = baseScale * targetZoom (since .scaledToFit() then .scaleEffect())
        // This is equivalent to the main map's totalScale when centering
        let baseScale = min(frameSize.width / imageSize.width, frameSize.height / imageSize.height)
        let totalScale = baseScale * targetZoom
        
        // Line 45: vScaled = v * totalScale
        let vScaled = CGPoint(x: v.x * totalScale, y: v.y * totalScale)
        
        // Lines 47-52: Rotation (theta = 0 for PiP, so vRot = vScaled)
        let theta: CGFloat = 0.0  // No rotation for PiP Map
        let c = cos(theta)
        let ss = sin(theta)
        let vRot = CGPoint(
            x: c * vScaled.x - ss * vScaled.y,
            y: ss * vScaled.x + c * vScaled.y
        )
        
        // Line 54: newOffset = -vRot
        let newOffset = CGSize(width: -vRot.x, height: -vRot.y)
        
        print("🎯 PiP focused() calculation:")
        print("   point: (\(Int(point.x)), \(Int(point.y)))")
        print("   Cmap: (\(Int(Cmap.x)), \(Int(Cmap.y)))")
        print("   v: (\(Int(v.x)), \(Int(v.y)))")
        print("   baseScale: \(String(format: "%.6f", baseScale))")
        print("   targetZoom: \(String(format: "%.3f", targetZoom))")
        print("   totalScale: \(String(format: "%.6f", totalScale))")
        print("   vScaled: (\(String(format: "%.1f", vScaled.x)), \(String(format: "%.1f", vScaled.y)))")
        print("   vRot: (\(String(format: "%.1f", vRot.x)), \(String(format: "%.1f", vRot.y)))")
        print("   newOffset: (\(String(format: "%.1f", newOffset.width)), \(String(format: "%.1f", newOffset.height)))")
        
        return PiPMapTransform(
            scale: targetZoom,
            offset: newOffset
        )
    }
}

// MARK: - PiP Map View (migrated from ARCalibrationView)

struct ARPiPMapView: View {
    @EnvironmentObject private var mapPointStore: MapPointStore
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var arCalibrationCoordinator: ARCalibrationCoordinator
    @EnvironmentObject private var metricSquares: MetricSquareStore
    @EnvironmentObject private var arViewLaunchContext: ARViewLaunchContext
    @EnvironmentObject private var zoneStore: ZoneStore
    @EnvironmentObject private var zoneGroupStore: ZoneGroupStore
    
    // Focused point ID for zoom/center (nil = show full map or frame triangle)
    // Computed reactively from arCalibrationCoordinator to respond to currentVertexIndex changes
    private var focusedPointID: UUID? {
        // SWATH SURVEY MODE: Focus on current anchor vertex during placement
        if arViewLaunchContext.launchMode == .swathSurvey {
            // During vertex placement, focus on current anchor (same as Calibration Crawl)
            if case .placingVertices = arCalibrationCoordinator.calibrationState {
                return arCalibrationCoordinator.getCurrentVertexID()
            }
            return nil
        }
        
        // ZONE CORNER CALIBRATION MODE: Focus on current zone corner vertex during placement or adjustment
        if arViewLaunchContext.launchMode == .zoneCornerCalibration {
            // During vertex placement, focus on current zone corner
            if case .placingVertices = arCalibrationCoordinator.calibrationState {
                return arCalibrationCoordinator.getCurrentVertexID()
            }
            // During ghost adjustment (readyToFill), focus on selected ghost
            if case .readyToFill = arCalibrationCoordinator.calibrationState,
               let selectedGhostID = arCalibrationCoordinator.selectedGhostMapPointID {
                return selectedGhostID
            }
            return nil
        }
        
        // CALIBRATION MODE: Original behavior
        guard isCalibrationMode else { return nil }
        
        // When calibration is complete (readyToFill state), return nil to trigger triangle framing
        if case .readyToFill = arCalibrationCoordinator.calibrationState {
            return nil
        }
        
        // During vertex placement, focus on current vertex
        if case .placingVertices = arCalibrationCoordinator.calibrationState {
            return arCalibrationCoordinator.getCurrentVertexID()
        }
        
        return nil
    }
    
    // Calibration mode properties for user position tracking
    let isCalibrationMode: Bool
    let selectedTriangle: TrianglePatch?
    let autoZoomToTriangle: Bool
    
    // Separate transform stores for PiP (independent from main map)
    @StateObject private var pipTransform = MapTransformStore()
    @StateObject private var pipProcessor = TransformProcessor()
    
    // Track last logged focused point to prevent spam
    @State private var lastLoggedFocusedPointID: UUID?
    
    // Track last logged transform calculation to prevent spam
    @State private var lastLoggedTransformState: CalibrationState?
    
    // Track last logged calibration state for PIP_ONCHANGE debouncing
    @State private var lastLoggedCalibrationState: CalibrationState? = nil
    
    // Track last state and focused point for FOCUSED_POINT logging
    @State private var lastState: CalibrationState? = nil
    @State private var lastFocusedPointID: UUID? = nil
    
    // Track last debug info string for PiP Map spam prevention
    @State private var lastDebugInfo: String? = nil
    
    @State private var mapImage: UIImage?
    @State private var currentScale: CGFloat = 1.0
    @State private var currentOffset: CGSize = .zero
    
    // User position tracking
    @State private var userMapPosition: CGPoint? = nil
    @State private var positionUpdateTimer: Timer? = nil
    @State private var positionSamples: [simd_float3] = [] // Ring buffer for smoothing
    @State private var lastContainingTriangleID: UUID? = nil // Track last containing triangle to detect changes
    
    // Timed transition after calibration completes
    @State private var calibrationJustCompleted: Bool = false
    
    // Debug toggle: Center PiP on user position during crawl mode (.readyToFill)
    // Uses AppSettings.followUserInPiP instead of local state
    private var followUserInPiPMap: Bool {
        AppSettings.followUserInPiP
    }
    
    var body: some View {
        Group {
            if let mapImage = mapImage {
                GeometryReader { geo in
                    pipMapContent(mapImage: mapImage, frameSize: geo.size)
                }
            } else {
                loadingMapView()
            }
        }
        .onAppear {
            loadMapImage()
            if isCalibrationMode {
                startUserPositionTracking()
            }
        }
        .onDisappear {
            stopUserPositionTracking()
        }
        .onChange(of: locationManager.currentLocationID) { _ in
            loadMapImage()
        }
        .onChange(of: mapImage) { newImage in
            guard let img = newImage else { return }
            // MILESTONE 5: Cache map parameters when image loads
            let lockedSquares = metricSquares.squares.filter { $0.isLocked }
            let squaresToUse = lockedSquares.isEmpty ? metricSquares.squares : lockedSquares
            if let firstSquare = squaresToUse.first, firstSquare.side > 0, firstSquare.meters > 0 {
                let metersPerPixel = Float(firstSquare.meters) / Float(firstSquare.side)
                arCalibrationCoordinator.setMapParametersForBakedData(mapSize: img.size, metersPerPixel: metersPerPixel)
            }
        }
        .onChange(of: isCalibrationMode) { newValue in
            if newValue {
                startUserPositionTracking()
            } else {
                stopUserPositionTracking()
            }
        }
    }
    
    @ViewBuilder
    private func pipMapContent(mapImage: UIImage, frameSize: CGSize) -> some View {
        // Calculate target transform based on focused point
        let targets = calculateTargetTransform(image: mapImage, frameSize: frameSize)
        
        pipMapZStack(mapImage: mapImage)
                    .scaleEffect(currentScale)
                    .offset(currentOffset)
            .frame(width: frameSize.width, height: frameSize.height)
                    .clipped()
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    )
                    .onAppear {
                setupPiPTransform(image: mapImage, frameSize: frameSize)
                        currentScale = targets.scale
                        currentOffset = targets.offset
                    }
            .onChange(of: focusedPointID) { newFocusedID in
                handleFocusedPointChange(newFocusedID: newFocusedID, mapImage: mapImage, frameSize: frameSize)
                    }
                    .onChange(of: arCalibrationCoordinator.currentVertexIndex) { _ in
                handleVertexIndexChange(mapImage: mapImage, frameSize: frameSize)
                    }
                    .onChange(of: arCalibrationCoordinator.calibrationState) { oldState, newState in
                handleCalibrationStateChange(oldState: oldState, newState: newState, mapImage: mapImage, frameSize: frameSize)
                        
                        // Timed transition: show triangle frame for 1.5 sec after calibration completes
                        if case .readyToFill = newState, oldState != .readyToFill {
                            calibrationJustCompleted = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                calibrationJustCompleted = false
                            }
                        }
                    }
                    .onChange(of: arCalibrationCoordinator.placedMarkers.count) { _ in
                handlePlacedMarkersChange(mapImage: mapImage, frameSize: frameSize)
                    }
                    .onChange(of: selectedTriangle?.id) { _ in
                handleSelectedTriangleChange(mapImage: mapImage, frameSize: frameSize)
                    }
                    .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CenterPiPOnTriangle"))) { notification in
                handleCenterPiPNotification(notification: notification, mapImage: mapImage)
                    }
                    .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CenterPiPOnMapPoint"))) { notification in
                handleCenterPiPOnMapPoint(notification: notification, mapImage: mapImage, frameSize: frameSize)
                    }
                    .onChange(of: userMapPosition) { oldPos, newPos in
                        // Only update during readyToFill state when following user
                        guard followUserInPiPMap,
                              case .readyToFill = arCalibrationCoordinator.calibrationState,
                              newPos != nil else { return }
                        
                        let frameSize = CGSize(width: 280, height: 220)
                        let (scale, offset) = calculateTargetTransform(image: mapImage, frameSize: frameSize)
                        
                        withAnimation(.easeOut(duration: 0.3)) {
                            currentScale = scale
                            currentOffset = offset
            }
        }
    }
    
    private func loadMapImage() {
        let locationID = locationManager.currentLocationID
        
        // Try loading from Documents first
        if let image = LocationImportUtils.loadDisplayImage(locationID: locationID) {
            mapImage = image
            return
        }
        
        // Fallback to bundled assets
        let assetName: String
        switch locationID {
        case "home":
            assetName = "myFirstFloor_v03-metric"
        case "museum":
            assetName = "MuseumMap-8k"
        default:
            mapImage = nil
            return
        }
        
        mapImage = UIImage(named: assetName)
    }
    
    /// Setup PiP transform stores
    private func setupPiPTransform(image: UIImage, frameSize: CGSize) {
        pipProcessor.bind(to: pipTransform)
        pipProcessor.setMapSize(CGSize(width: image.size.width, height: image.size.height))
        pipProcessor.setScreenCenter(CGPoint(x: frameSize.width / 2, y: frameSize.height / 2))
    }
    
    /// Calculate target transform based on focused point (or full map)
    private func calculateTargetTransform(image: UIImage, frameSize: CGSize) -> (scale: CGFloat, offset: CGSize) {
        let imageSize = image.size
        
        // CASE 1: Focus on single point (vertex during calibration) - PRIORITY: check this FIRST
        // During calibration, we want to zoom in on the current vertex, not the whole triangle
        if let pointID = focusedPointID,
           let point = mapPointStore.points.first(where: { $0.id == pointID }) {
            // Single point mode - create region around point with calibration zoom
            // Reduced regionSize for tighter zoom (was 400, now 250 for closer view)
            let regionSize: CGFloat = 250
            let cornerA = CGPoint(x: point.mapPoint.x - regionSize/2, y: point.mapPoint.y - regionSize/2)
            let cornerB = CGPoint(x: point.mapPoint.x + regionSize/2, y: point.mapPoint.y + regionSize/2)
            
            let scale = calculateScale(pointA: cornerA, pointB: cornerB, frameSize: frameSize, imageSize: imageSize)
            let offset = calculateOffset(pointA: cornerA, pointB: cornerB, frameSize: frameSize, imageSize: imageSize)
            return (scale, offset)
        }
        
        // CASE 2: Frame entire triangle when calibration complete (readyToFill state)
        if case .readyToFill = arCalibrationCoordinator.calibrationState {
            // PRIORITY 1: Show triangle frame briefly after calibration completes
            if calibrationJustCompleted, let triangle = selectedTriangle,
               triangle.vertexIDs.count == 3 {
                // Frame the entire triangle (existing triangle framing code)
                let currentState = arCalibrationCoordinator.calibrationState
                let shouldLog = lastLoggedTransformState != currentState
                if shouldLog {
                    print("🎯 [PIP_TRANSFORM] readyToFill state - showing triangle frame (calibration just completed)")
                    lastLoggedTransformState = currentState
                }
                
                let vertexPoints = triangle.vertexIDs.compactMap { vertexID in
                    mapPointStore.points.first(where: { $0.id == vertexID })?.mapPoint
                }
                
                guard vertexPoints.count == 3 else {
                    print("⚠️ [PIP_TRANSFORM] Could not find all 3 vertices")
                    // Fall through to full map view
                    return calculateFullMapTransform(frameSize: frameSize, imageSize: imageSize)
                }
                
                let minX = vertexPoints.map { $0.x }.min()!
                let maxX = vertexPoints.map { $0.x }.max()!
                let minY = vertexPoints.map { $0.y }.min()!
                let maxY = vertexPoints.map { $0.y }.max()!
                
                let padding: CGFloat = 100 // Padding around triangle
                let cornerA = CGPoint(x: minX - padding, y: minY - padding)
                let cornerB = CGPoint(x: maxX + padding, y: maxY + padding)
                
                if shouldLog {
                    print("📐 [PIP_TRANSFORM] Triangle bounds: A(\(Int(cornerA.x)), \(Int(cornerA.y))) B(\(Int(cornerB.x)), \(Int(cornerB.y)))")
                }
                
                let scale = calculateScale(pointA: cornerA, pointB: cornerB, frameSize: frameSize, imageSize: imageSize)
                let offset = calculateOffset(pointA: cornerA, pointB: cornerB, frameSize: frameSize, imageSize: imageSize)
                
                if shouldLog {
                    print("✅ [PIP_TRANSFORM] Calculated triangle frame - scale: \(String(format: "%.3f", scale)), offset: (\(String(format: "%.1f", offset.width)), \(String(format: "%.1f", offset.height)))")
                }
                return (scale, offset)
            }
            
            // PRIORITY 2: Follow user position during crawl mode (after delay)
            if followUserInPiPMap, let userPos = userMapPosition {
                // Follow user position during crawl mode
                // Use regionSize approach (same as ghost marker focus) instead of broken targetZoom
                let regionSize: CGFloat = 400  // Same framing as ghost marker proximity
                let cornerA = CGPoint(x: userPos.x - regionSize/2, y: userPos.y - regionSize/2)
                let cornerB = CGPoint(x: userPos.x + regionSize/2, y: userPos.y + regionSize/2)
                
                let scale = calculateScale(pointA: cornerA, pointB: cornerB, frameSize: frameSize, imageSize: imageSize)
                let offset = calculateOffset(pointA: cornerA, pointB: cornerB, frameSize: frameSize, imageSize: imageSize)
                return (scale, offset)
            }
            
            // PRIORITY 3: Fallback - frame the entire triangle
            if let triangle = selectedTriangle,
           triangle.vertexIDs.count == 3 {
                // Fallback: frame the entire triangle
                // Only log on state change
                let currentState = arCalibrationCoordinator.calibrationState
                let shouldLog = lastLoggedTransformState != currentState
                if shouldLog {
            print("🎯 [PIP_TRANSFORM] readyToFill state - calculating triangle bounds")
                    lastLoggedTransformState = currentState
                }
            
            let vertexPoints = triangle.vertexIDs.compactMap { vertexID in
                mapPointStore.points.first(where: { $0.id == vertexID })?.mapPoint
            }
            
            guard vertexPoints.count == 3 else {
                print("⚠️ [PIP_TRANSFORM] Could not find all 3 vertices")
                // Fall through to full map view
                return calculateFullMapTransform(frameSize: frameSize, imageSize: imageSize)
            }
            
            let minX = vertexPoints.map { $0.x }.min()!
            let maxX = vertexPoints.map { $0.x }.max()!
            let minY = vertexPoints.map { $0.y }.min()!
            let maxY = vertexPoints.map { $0.y }.max()!
            
            let padding: CGFloat = 100 // Padding around triangle
            let cornerA = CGPoint(x: minX - padding, y: minY - padding)
            let cornerB = CGPoint(x: maxX + padding, y: maxY + padding)
            
                // Only log bounds on first calculation
                if shouldLog {
                    print("📐 [PIP_TRANSFORM] Triangle bounds: A(\(Int(cornerA.x)), \(Int(cornerA.y))) B(\(Int(cornerB.x)), \(Int(cornerB.y)))")
                }
            
            let scale = calculateScale(pointA: cornerA, pointB: cornerB, frameSize: frameSize, imageSize: imageSize)
            let offset = calculateOffset(pointA: cornerA, pointB: cornerB, frameSize: frameSize, imageSize: imageSize)
            
                // Only log result on first calculation
                if shouldLog {
            print("✅ [PIP_TRANSFORM] Calculated triangle frame - scale: \(String(format: "%.3f", scale)), offset: (\(String(format: "%.1f", offset.width)), \(String(format: "%.1f", offset.height)))")
                }
            return (scale, offset)
            }
        }
        
        // CASE 0: Auto-zoom to triangle if enabled and triangle is selected
        // Only use this when NOT in calibration mode (no focused point)
        if autoZoomToTriangle, let triangle = selectedTriangle {
            let vertexPoints = triangle.vertexIDs.compactMap { vertexID in
                mapPointStore.points.first(where: { $0.id == vertexID })?.mapPoint
            }
            
            if vertexPoints.count == 3 {
                // Use existing fitting transform logic with padding
                return calculateFittingTransform(points: vertexPoints, frameSize: frameSize, imageSize: imageSize, padding: frameSize.width * 0.1) // 10% padding
            }
        }
        
        // CASE 2: Focus on full triangle (all 3 points) when calibration complete
        if let triangle = selectedTriangle,
           arCalibrationCoordinator.placedMarkers.count == 3 {
            let vertices = triangle.vertexIDs.compactMap { id in
                mapPointStore.points.first(where: { $0.id == id })?.mapPoint
            }
            guard vertices.count == 3 else {
                // Fallback to full map if we can't get all vertices
                return calculateFullMapTransform(frameSize: frameSize, imageSize: imageSize)
            }
            
            return calculateFittingTransform(points: vertices, frameSize: frameSize, imageSize: imageSize)
        }
        
        // CASE 3: Default → zoom out to full map
        return calculateFullMapTransform(frameSize: frameSize, imageSize: imageSize)
    }
    
    /// Calculate transform for full map view
    private func calculateFullMapTransform(frameSize: CGSize, imageSize: CGSize) -> (scale: CGFloat, offset: CGSize) {
        let cornerA = CGPoint(x: 0, y: 0)
        let cornerB = CGPoint(x: imageSize.width, y: imageSize.height)
        
        let scale = calculateScale(pointA: cornerA, pointB: cornerB, frameSize: frameSize, imageSize: imageSize)
        let offset = calculateOffset(pointA: cornerA, pointB: cornerB, frameSize: frameSize, imageSize: imageSize)
        return (scale, offset)
    }
    
    // MARK: - Helper Methods for onChange Handlers
    
    private func handleFocusedPointChange(newFocusedID: UUID?, mapImage: UIImage, frameSize: CGSize) {
        DispatchQueue.main.async {
            let newTargets = calculateTargetTransform(image: mapImage, frameSize: frameSize)
            withAnimation(.easeInOut(duration: 0.5)) {
                currentScale = newTargets.scale
                currentOffset = newTargets.offset
            }
            
            // Debug: Log when focused point should be shown but isn't (gated behind change detection)
            if isCalibrationMode && newFocusedID == nil {
                let debugString = "⚠️ PiP Map: isCalibrationMode=\(isCalibrationMode), focusedPointID=nil, currentVertexIndex=\(arCalibrationCoordinator.currentVertexIndex)"
                if debugString != lastDebugInfo {
                    print(debugString)
                    lastDebugInfo = debugString
                }
            } else {
                // Clear debug info when focused point exists
                lastDebugInfo = nil
            }
        }
    }
    
    private func handleVertexIndexChange(mapImage: UIImage, frameSize: CGSize) {
        DispatchQueue.main.async {
            let newTargets = calculateTargetTransform(image: mapImage, frameSize: frameSize)
            withAnimation(.easeInOut(duration: 0.5)) {
                currentScale = newTargets.scale
                currentOffset = newTargets.offset
            }
            
            // Update debug info when vertex index changes
            if isCalibrationMode && focusedPointID == nil {
                let debugString = "⚠️ PiP Map: isCalibrationMode=\(isCalibrationMode), focusedPointID=nil, currentVertexIndex=\(arCalibrationCoordinator.currentVertexIndex)"
                if debugString != lastDebugInfo {
                    print(debugString)
                    lastDebugInfo = debugString
                }
            }
        }
    }
    
    private func handlePlacedMarkersChange(mapImage: UIImage, frameSize: CGSize) {
        DispatchQueue.main.async {
            if let triangle = selectedTriangle,
               arCalibrationCoordinator.isTriangleComplete(triangle.id) {
                print("🎯 PiP Map: Triangle complete - fitting all 3 vertices")
                
                // Draw triangle lines on ground
                if let coordinator = ARViewContainer.Coordinator.current {
                    var vertices: [simd_float3] = []
                    for markerIDString in triangle.arMarkerIDs {
                        if let markerUUID = UUID(uuidString: markerIDString),
                           let markerNode = coordinator.placedMarkers[markerUUID] {
                            vertices.append(markerNode.simdPosition)
                        }
                    }
                    if vertices.count == 3 {
                        coordinator.drawTriangleLines(vertices: vertices)
                    }
                }
            }
            let newTargets = calculateTargetTransform(image: mapImage, frameSize: frameSize)
            withAnimation(.easeInOut(duration: 0.5)) {
                currentScale = newTargets.scale
                currentOffset = newTargets.offset
            }
        }
    }
    
    private func handleSelectedTriangleChange(mapImage: UIImage, frameSize: CGSize) {
        if autoZoomToTriangle {
            DispatchQueue.main.async {
                let newTargets = calculateTargetTransform(image: mapImage, frameSize: frameSize)
                withAnimation(.easeInOut(duration: 0.6)) {
                    currentScale = newTargets.scale
                    currentOffset = newTargets.offset
                }
            }
        }
    }
    
    private func handleCalibrationStateChange(oldState: CalibrationState, newState: CalibrationState, mapImage: UIImage, frameSize: CGSize) {
        // FOCUSED_POINT logging - only on state transitions
        DispatchQueue.main.async {
            let currentFocusedID = focusedPointID
            
            let wasPlacingVertices: Bool = {
                if case .placingVertices = lastState { return true }
                return false
            }()
            
            let isPlacingVertices: Bool = {
                if case .placingVertices = newState { return true }
                return false
            }()
            
            if isPlacingVertices && !wasPlacingVertices {
                // Entering placingVertices state
                print("🔍 [FOCUSED_POINT] entered placingVertices state - focusing on \(currentFocusedID.map { String($0.uuidString.prefix(8)) } ?? "nil")")
            } else if !isPlacingVertices && wasPlacingVertices {
                // Exiting placingVertices state
                print("🔍 [FOCUSED_POINT] exited placingVertices state - was focusing on \(lastFocusedPointID.map { String($0.uuidString.prefix(8)) } ?? "nil")")
            } else if case .readyToFill = newState, lastState != .readyToFill {
                // Entering readyToFill state
                print("🔍 [FOCUSED_POINT] readyToFill state - returning nil to frame triangle")
            }
            
            lastState = newState
            lastFocusedPointID = currentFocusedID
        }
        
        // PIP_ONCHANGE logging - only on state TRANSITIONS, not every frame
        if newState != lastLoggedCalibrationState {
            switch newState {
            case .placingVertices(let index):
                print("🔍 [PIP_ONCHANGE] State → placingVertices(index: \(index))")
            case .readyToFill:
                print("🔍 [PIP_ONCHANGE] State → readyToFill")
                print("🎯 [PIP_ONCHANGE] Triggering triangle frame calculation")
            case .idle:
                print("🔍 [PIP_ONCHANGE] State → idle")
            default:
                print("🔍 [PIP_ONCHANGE] State → \(newState)")
            }
            lastLoggedCalibrationState = newState
        }
        
        if case .readyToFill = newState {
            // Recalculate transform to frame the entire triangle
            DispatchQueue.main.async {
                let newTargets = calculateTargetTransform(image: mapImage, frameSize: frameSize)
                withAnimation(.easeInOut(duration: 0.5)) {
                    currentScale = newTargets.scale
                    currentOffset = newTargets.offset
                }
                print("✅ [PIP_ONCHANGE] Applied triangle framing transform")
            }
        }
    }
    
    private func handleCenterPiPOnMapPoint(notification: Notification, mapImage: UIImage, frameSize: CGSize) {
        guard let mapPointID = notification.userInfo?["mapPointID"] as? UUID,
              let mapPoint = mapPointStore.points.first(where: { $0.id == mapPointID }) else {
            print("⚠️ [PIP_CENTER] Invalid MapPoint ID in notification")
            return
        }
        
        print("📍 [PIP_CENTER] Centering on ghost MapPoint \(String(mapPointID.uuidString.prefix(8))) at (\(Int(mapPoint.mapPoint.x)), \(Int(mapPoint.mapPoint.y)))")
        
        // Center the map on this point using the same logic as focusedPointID
        let regionSize: CGFloat = 250
        let cornerA = CGPoint(x: mapPoint.mapPoint.x - regionSize/2, y: mapPoint.mapPoint.y - regionSize/2)
        let cornerB = CGPoint(x: mapPoint.mapPoint.x + regionSize/2, y: mapPoint.mapPoint.y + regionSize/2)
        
        let imageSize = mapImage.size
        let scale = calculateScale(pointA: cornerA, pointB: cornerB, frameSize: frameSize, imageSize: imageSize)
        let offset = calculateOffset(pointA: cornerA, pointB: cornerB, frameSize: frameSize, imageSize: imageSize)
        
        // Animate to the new transform
        withAnimation(.easeInOut(duration: 0.3)) {
            currentScale = scale
            currentOffset = offset
        }
    }
    
    private func handleCenterPiPNotification(notification: Notification, mapImage: UIImage) {
        guard let triangleID = notification.userInfo?["triangleID"] as? UUID,
              let triangle = arCalibrationCoordinator.triangleStoreAccess.triangle(withID: triangleID) else {
            return
        }
        
        // Get triangle vertices' map positions
        let vertexPositions = triangle.vertexIDs.compactMap { vertexID -> CGPoint? in
            mapPointStore.points.first(where: { $0.id == vertexID })?.mapPoint
        }
        
        guard vertexPositions.count == 3 else { return }
        
        let frameSize = CGSize(width: 180, height: 180)
        let newTransform = calculateFittingTransform(
            points: vertexPositions,
            frameSize: frameSize,
            imageSize: mapImage.size,
            padding: 40
        )
        
        withAnimation(.easeInOut(duration: 0.6)) {
            currentScale = newTransform.scale
            currentOffset = newTransform.offset
        }
        
        print("🎯 PiP centered on triangle \(String(triangleID.uuidString.prefix(8)))")
    }
    
    @ViewBuilder
    private func pipMapZStack(mapImage: UIImage) -> some View {
        ZStack {
            // MARK: - TECH DEBT: PiP gestures disabled via parameter
            // gesturesEnabled: false prevents the UIKit gesture bridge from being created.
            // .allowsHitTesting(false) is kept for belt-and-suspenders but doesn't block UIKit gestures.
            // See MapContainer.swift for notes on the proper fix (moving focusedPointIndicator inside).
            MapContainer(mapImage: mapImage, gesturesEnabled: false)
                .environmentObject(pipTransform)
                .environmentObject(pipProcessor)
                .frame(width: mapImage.size.width, height: mapImage.size.height)
                .allowsHitTesting(false)
            
            // User position dot overlay (only in calibration mode)
            UserPositionOverlay(
                userPosition: userMapPosition,
                isEnabled: isCalibrationMode && AppSettings.followUserInPiP
            )
            
            // Focused point indicator (if any) - must be after MapContainer to render on top
            if let pointID = focusedPointID,
               let point = mapPointStore.points.first(where: { $0.id == pointID }) {
                focusedPointIndicator(pointID: pointID, point: point)
            }
        }
    }
    
    @ViewBuilder
    private func focusedPointIndicator(pointID: UUID, point: MapPointStore.MapPoint) -> some View {
        let isZoneCorner = point.roles.contains(.zoneCorner)
        let indicatorColor = zoneCornerColor(for: point) ?? Color.cyan
        
        return ZStack {
            if isZoneCorner {
                // Diamond shape for zone corners (rotated square)
                // Outer glow
                Rectangle()
                    .fill(indicatorColor.opacity(0.3))
                    .frame(width: 18, height: 18)
                    .rotationEffect(.degrees(45))
                
                // Inner diamond
                Rectangle()
                    .fill(indicatorColor)
                    .frame(width: 12, height: 12)
                    .rotationEffect(.degrees(45))
                
                // White border
                Rectangle()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: 12, height: 12)
                    .rotationEffect(.degrees(45))
            } else {
                // Circle for non-zone-corner points
                // Outer ring for visibility
                Circle()
                    .fill(indicatorColor.opacity(0.3))
                    .frame(width: 20, height: 20)
                
                // Inner circle
                Circle()
                    .fill(indicatorColor)
                    .frame(width: 12, height: 12)
                
                // White border
                Circle()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: 12, height: 12)
            }
        }
        .position(point.mapPoint)
        .onAppear {
            let shapeType = isZoneCorner ? "diamond" : "circle"
            print("📍 PiP Map: Displaying focused point \(String(pointID.uuidString.prefix(8))) as \(shapeType) at (\(Int(point.mapPoint.x)), \(Int(point.mapPoint.y)))")
        }
    }
    
    /// Returns the zone group color for a zone corner MapPoint, or nil if not a zone corner or ungrouped
    private func zoneCornerColor(for point: MapPointStore.MapPoint) -> Color? {
        guard point.roles.contains(.zoneCorner) else { return nil }
        
        // Find zone(s) that have this MapPoint as a corner
        let pointIDString = point.id.uuidString
        for zone in zoneStore.zones {
            if zone.cornerMapPointIDs.contains(pointIDString) {
                // Found a zone with this corner - get its group color
                if let groupID = zone.groupID,
                   let group = zoneGroupStore.group(withID: groupID) {
                    return Color(hex: group.colorHex)
                }
            }
        }
        
        // Zone corner but ungrouped - use default purple (matches MapPointRole.zoneCorner.color)
        return Color.purple
    }
    
    @ViewBuilder
    private func loadingMapView() -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.gray.opacity(0.3))
            .overlay(
                Text("Loading Map...")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.caption)
            )
    }
    
    /// Calculate transform to fit multiple points (for triangle view)
    private func calculateFittingTransform(points: [CGPoint], frameSize: CGSize, imageSize: CGSize, padding: CGFloat = 40) -> (scale: CGFloat, offset: CGSize) {
        guard points.count >= 2 else {
            return calculateFullMapTransform(frameSize: frameSize, imageSize: imageSize)
        }
        
        // Compute bounding box of all points
        let minX = points.map(\.x).min()!
        let maxX = points.map(\.x).max()!
        let minY = points.map(\.y).min()!
        let maxY = points.map(\.y).max()!
        
        let boxWidth = maxX - minX
        let boxHeight = maxY - minY
        
        // Scale calculation to fit bounding box with padding
        let scaleX = (frameSize.width - padding * 2) / boxWidth
        let scaleY = (frameSize.height - padding * 2) / boxHeight
        let scale = min(scaleX, scaleY)
        
        // Box center
        let centerX = (minX + maxX) / 2
        let centerY = (minY + maxY) / 2
        
        // Calculate offset using same logic as calculateOffset
        let imageCenterX = imageSize.width / 2
        let imageCenterY = imageSize.height / 2
        
        let offsetFromImageCenter_X = imageCenterX - centerX
        let offsetFromImageCenter_Y = imageCenterY - centerY
        
        let offsetX = offsetFromImageCenter_X * scale
        let offsetY = offsetFromImageCenter_Y * scale
        
        return (scale, CGSize(width: offsetX, height: offsetY))
    }
    
    /// Calculate scale to fit region between two points
    private func calculateScale(pointA: CGPoint, pointB: CGPoint, frameSize: CGSize, imageSize: CGSize) -> CGFloat {
        // Calculate center point between A and B
        let centerX = (pointA.x + pointB.x) / 2
        let centerY = (pointA.y + pointB.y) / 2
        
        // Calculate max distances from center to either point
        let maxXDistance = max(abs(pointA.x - centerX), abs(pointB.x - centerX))
        let maxYDistance = max(abs(pointA.y - centerY), abs(pointB.y - centerY))
        
        // Add padding (10% extra space around points)
        let paddingFactor: CGFloat = 1.1
        let paddedXDistance = maxXDistance * 2 * paddingFactor
        let paddedYDistance = maxYDistance * 2 * paddingFactor
        
        // Calculate scale factors for each dimension
        let scaleX = frameSize.width / paddedXDistance
        let scaleY = frameSize.height / paddedYDistance
        
        // Use the smaller scale to ensure both points fit
        return min(scaleX, scaleY)
    }
    
    /// Calculate offset to center region between two points
    private func calculateOffset(pointA: CGPoint, pointB: CGPoint, frameSize: CGSize, imageSize: CGSize) -> CGSize {
        let scale = calculateScale(pointA: pointA, pointB: pointB, frameSize: frameSize, imageSize: imageSize)
        
        // Calculate average of the two points (center between them)
        let Xavg = (pointA.x + pointB.x) / 2
        let Yavg = (pointA.y + pointB.y) / 2
        
        // Image center
        let imageCenterX = imageSize.width / 2
        let imageCenterY = imageSize.height / 2
        
        // Offset from image center to average point
        let offsetFromImageCenter_X = imageCenterX - Xavg
        let offsetFromImageCenter_Y = imageCenterY - Yavg
        
        // Apply scale factor
        let offsetX = offsetFromImageCenter_X * scale
        let offsetY = offsetFromImageCenter_Y * scale
        
        return CGSize(width: offsetX, height: offsetY)
    }
    
    // MARK: - User Position Tracking
    
    private func startUserPositionTracking() {
        guard isCalibrationMode else { return }
        
        // Start position update timer (every 1 second)
        // Note: Using Timer with struct - timer will be invalidated on deinit
        positionUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateUserPosition()
        }
        
        // Initial update
        updateUserPosition()
    }
    
    private func stopUserPositionTracking() {
        positionUpdateTimer?.invalidate()
        positionUpdateTimer = nil
        userMapPosition = nil
        positionSamples.removeAll()
        lastContainingTriangleID = nil
    }
    
    private func updateUserPosition() {
        guard isCalibrationMode,
              let coordinator = ARViewContainer.Coordinator.current,
              let cameraPosition = coordinator.getCurrentCameraPosition() else {
            userMapPosition = nil
            return
        }
        
        // Add to ring buffer for smoothing (keep last 5 samples)
        positionSamples.append(cameraPosition)
        if positionSamples.count > 5 {
            positionSamples.removeFirst()
        }
        
        // Average the samples for smoothing
        let smoothedPosition = positionSamples.reduce(simd_float3(0, 0, 0), +) / Float(positionSamples.count)
        
        // Check which calibrated triangle contains the user (AR-space, no projection needed)
        let containingTriangle = findContainingTriangleInARSpace(cameraPosition: smoothedPosition)
        if lastContainingTriangleID != containingTriangle {
            lastContainingTriangleID = containingTriangle
            // Post notification to update userContainingTriangleID in ARViewWithOverlays
            NotificationCenter.default.post(
                name: NSNotification.Name("UserContainingTriangleChanged"),
                object: nil,
                userInfo: ["triangleID": containingTriangle as Any]
            )
            if let triangleID = containingTriangle {
                print("📍 [USER_TRIANGLE] User entered Triangle \(String(triangleID.uuidString.prefix(8)))")
            } else {
                print("📍 [USER_TRIANGLE] User exited calibrated triangle area")
            }
        }
        
        // Project AR world position to 2D map coordinates (for PiP map display)
        if let projectedPosition = projectARPositionToMap(arPosition: smoothedPosition) {
            userMapPosition = projectedPosition
            // Share position with coordinator for proximity-based ghost selection
            arCalibrationCoordinator.updateUserPosition(projectedPosition)
        } else {
            userMapPosition = nil
        }
    }
    
    /// Project AR world position to 2D map coordinates using session-calibrated triangle data
    private func projectARPositionToMap(arPosition: simd_float3) -> CGPoint? {
        let sessionTriangles = arCalibrationCoordinator.sessionCalibratedTriangles
        let mapPointPositions = arCalibrationCoordinator.mapPointARPositions
        let triangleStore = arCalibrationCoordinator.triangleStoreAccess
        
        // Need at least one calibrated triangle with position data
        guard !sessionTriangles.isEmpty, !mapPointPositions.isEmpty else {
            return nil
        }
        
        // Find a triangle where we have AR positions for all 3 vertices
        for triangleID in sessionTriangles {
            guard let triangle = triangleStore.triangle(withID: triangleID),
                  triangle.vertexIDs.count == 3 else { continue }
            
            // Collect AR positions and map positions for this triangle's vertices
            var arPositions: [simd_float3] = []
            var mapPositions: [CGPoint] = []
            
            for vertexID in triangle.vertexIDs {
                guard let arPos = mapPointPositions[vertexID],
                      let mapPoint = mapPointStore.points.first(where: { $0.id == vertexID }) else {
                    break
                }
                arPositions.append(arPos)
                mapPositions.append(mapPoint.mapPoint)
            }
            
            // If we have all 3 vertices, use this triangle for projection
            if arPositions.count == 3 && mapPositions.count == 3 {
                return projectUsingBarycentric(
                    userARPos: arPosition,
                    arPositions: arPositions,
                    mapPositions: mapPositions
                )
            }
        }
        
        // Fallback: try to use any 2 vertices we have positions for
        var arPositions: [simd_float3] = []
        var mapPositions: [CGPoint] = []
        
        for (vertexID, arPos) in mapPointPositions {
            guard let mapPoint = mapPointStore.points.first(where: { $0.id == vertexID }) else { continue }
            arPositions.append(arPos)
            mapPositions.append(mapPoint.mapPoint)
            if arPositions.count >= 2 { break }
        }
        
        if arPositions.count >= 2 {
            return projectUsingLinear(
                userARPos: arPosition,
                arPositions: Array(arPositions.prefix(2)),
                mapPositions: Array(mapPositions.prefix(2))
            )
        }
        
        return nil
    }
    
    /// Project using barycentric coordinates (for 3 points)
    private func projectUsingBarycentric(
        userARPos: simd_float3,
        arPositions: [simd_float3],
        mapPositions: [CGPoint]
    ) -> CGPoint? {
        guard arPositions.count == 3, mapPositions.count == 3 else { return nil }
        
        let p0 = arPositions[0]
        let p1 = arPositions[1]
        let p2 = arPositions[2]
        
        // Project to 2D plane (use XZ plane, ignoring Y height)
        let v0 = simd_float2(p1.x - p0.x, p1.z - p0.z)
        let v1 = simd_float2(p2.x - p0.x, p2.z - p0.z)
        let v2 = simd_float2(userARPos.x - p0.x, userARPos.z - p0.z)
        
        let dot00 = simd_dot(v0, v0)
        let dot01 = simd_dot(v0, v1)
        let dot02 = simd_dot(v0, v2)
        let dot11 = simd_dot(v1, v1)
        let dot12 = simd_dot(v1, v2)
        
        let invDenom = 1 / (dot00 * dot11 - dot01 * dot01)
        let u = (dot11 * dot02 - dot01 * dot12) * invDenom
        let v = (dot00 * dot12 - dot01 * dot02) * invDenom
        
        // Check if point is inside triangle
        if u >= 0 && v >= 0 && (u + v) <= 1 {
            // Interpolate map positions
            let map0 = mapPositions[0]
            let map1 = mapPositions[1]
            let map2 = mapPositions[2]
            
            let w = CGFloat(1.0 - u - v)
            let uCGFloat = CGFloat(u)
            let vCGFloat = CGFloat(v)
            
            // Break up complex expressions
            let term0X = w * map0.x
            let term1X = uCGFloat * map1.x
            let term2X = vCGFloat * map2.x
            let mapX = term0X + term1X + term2X
            
            let term0Y = w * map0.y
            let term1Y = uCGFloat * map1.y
            let term2Y = vCGFloat * map2.y
            let mapY = term0Y + term1Y + term2Y
            
            return CGPoint(x: mapX, y: mapY)
        }
        
        return nil
    }
    
    /// Project using linear interpolation (for 2 points)
    private func projectUsingLinear(
        userARPos: simd_float3,
        arPositions: [simd_float3],
        mapPositions: [CGPoint]
    ) -> CGPoint? {
        guard arPositions.count == 2, mapPositions.count == 2 else { return nil }
        
        let p0 = arPositions[0]
        let p1 = arPositions[1]
        
        // Project to 2D plane (use XZ plane)
        let v0 = simd_float2(p1.x - p0.x, p1.z - p0.z)
        let v1 = simd_float2(userARPos.x - p0.x, userARPos.z - p0.z)
        
        let len = simd_length(v0)
        guard len > 0.001 else { return nil } // Avoid division by zero
        
        let t = simd_dot(v1, v0) / (len * len)
        let tCGFloat = CGFloat(t)
        
        // Interpolate map positions
        let map0 = mapPositions[0]
        let map1 = mapPositions[1]
        
        let deltaX = map1.x - map0.x
        let deltaY = map1.y - map0.y
        let mapX = map0.x + tCGFloat * deltaX
        let mapY = map0.y + tCGFloat * deltaY
        
        return CGPoint(x: mapX, y: mapY)
    }
    
    /// Find which triangle contains the camera position in AR space
    /// Checks both session-calibrated triangles AND triangles with baked vertex data
    /// Returns nil if position is outside all known triangles
    private func findContainingTriangleInARSpace(cameraPosition: simd_float3) -> UUID? {
        let triangleStore = arCalibrationCoordinator.triangleStoreAccess
        
        // First check session-calibrated triangles (highest confidence)
        let sessionTriangles = arCalibrationCoordinator.sessionCalibratedTriangles
        let arPositions = arCalibrationCoordinator.mapPointARPositions
        
        for triangleID in sessionTriangles {
            guard let triangle = triangleStore.triangle(withID: triangleID),
                  triangle.vertexIDs.count == 3 else { continue }
            
            let vertexARPositions = triangle.vertexIDs.compactMap { arPositions[$0] }
            guard vertexARPositions.count == 3 else { continue }
            
            if pointInTriangleXZ(cameraPosition, vertices: vertexARPositions) {
                return triangleID
            }
        }
        
        // Then check triangles with baked data (if we have a valid transform)
        guard arCalibrationCoordinator.hasValidSessionTransform else {
            return nil
        }
        
        // Get all triangles and check those with baked vertices
        for triangle in triangleStore.triangles {
            // Skip if already checked in session triangles
            guard !sessionTriangles.contains(triangle.id) else { continue }
            
            // Get positions from baked data
            guard let vertexPositions = arCalibrationCoordinator.getTriangleVertexPositionsFromBaked(triangle.id) else {
                continue
            }
            
            let orderedPositions = triangle.vertexIDs.compactMap { vertexPositions[$0] }
            guard orderedPositions.count == 3 else { continue }
            
            if pointInTriangleXZ(cameraPosition, vertices: orderedPositions) {
                return triangle.id
            }
        }
        
        return nil
    }
    
    /// Check if point p is inside triangle defined by vertices in AR XZ plane
    private func pointInTriangleXZ(_ p: simd_float3, vertices: [simd_float3]) -> Bool {
        guard vertices.count == 3 else { return false }
        
        // Project to XZ plane (horizontal plane, ignoring Y height)
        let v0 = simd_float2(vertices[0].x, vertices[0].z)
        let v1 = simd_float2(vertices[1].x, vertices[1].z)
        let v2 = simd_float2(vertices[2].x, vertices[2].z)
        let pt = simd_float2(p.x, p.z)
        
        // Barycentric coordinate calculation
        let denom = (v1.y - v2.y) * (v0.x - v2.x) + (v2.x - v1.x) * (v0.y - v2.y)
        guard abs(denom) > 0.0001 else { return false }
        
        let a = ((v1.y - v2.y) * (pt.x - v2.x) + (v2.x - v1.x) * (pt.y - v2.y)) / denom
        let b = ((v2.y - v0.y) * (pt.x - v2.x) + (v0.x - v2.x) * (pt.y - v2.y)) / denom
        let c = 1 - a - b
        
        // Point is inside if all barycentric coordinates are non-negative (with small epsilon)
        let epsilon: Float = -0.001
        return a >= epsilon && b >= epsilon && c >= epsilon
    }
    
    /// Find which session-calibrated triangle contains the given map position
    /// Returns nil if position is outside all calibrated triangles
    private func findContainingTriangle(mapPosition: CGPoint) -> UUID? {
        let triangleStore = arCalibrationCoordinator.triangleStoreAccess
        let sessionTriangles = arCalibrationCoordinator.sessionCalibratedTriangles
        
        for triangleID in sessionTriangles {
            guard let triangle = triangleStore.triangle(withID: triangleID) else { continue }
            
            // Get vertex 2D positions
            let vertexPositions = triangle.vertexIDs.compactMap { vertexID -> CGPoint? in
                mapPointStore.points.first { $0.id == vertexID }?.mapPoint
            }
            
            guard vertexPositions.count == 3 else { continue }
            
            // Check if point is inside triangle using barycentric method
            if pointInTriangle(mapPosition, vertices: vertexPositions) {
                return triangleID
            }
        }
        
        return nil
    }
    
    /// Check if point p is inside triangle defined by vertices (barycentric method)
    private func pointInTriangle(_ p: CGPoint, vertices: [CGPoint]) -> Bool {
        guard vertices.count == 3 else { return false }
        
        let v0 = vertices[0]
        let v1 = vertices[1]
        let v2 = vertices[2]
        
        let denom = (v1.y - v2.y) * (v0.x - v2.x) + (v2.x - v1.x) * (v0.y - v2.y)
        guard abs(denom) > 0.0001 else { return false }
        
        let a = ((v1.y - v2.y) * (p.x - v2.x) + (v2.x - v1.x) * (p.y - v2.y)) / denom
        let b = ((v2.y - v0.y) * (p.x - v2.x) + (v0.x - v2.x) * (p.y - v2.y)) / denom
        let c = 1 - a - b
        
        // Point is inside if all barycentric coordinates are non-negative (with small epsilon)
        let epsilon: CGFloat = -0.001
        return a >= epsilon && b >= epsilon && c >= epsilon
    }
}

