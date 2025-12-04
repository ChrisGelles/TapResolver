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
    
    
    @EnvironmentObject private var mapPointStore: MapPointStore
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var arCalibrationCoordinator: ARCalibrationCoordinator
    @EnvironmentObject private var arWorldMapStore: ARWorldMapStore
    @EnvironmentObject private var metricSquares: MetricSquareStore
    
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
                arCalibrationCoordinator: arCalibrationCoordinator
            )
            .edgesIgnoringSafeArea(.all)
            .onAppear {
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
                } else {
                    // Set mode to idle - user will choose Calibrate or Relocalize
                    currentMode = .idle
                }
                
                print("🧪 ARView ID: triangle viewing mode for \(selectedTriangle.map { String($0.id.uuidString.prefix(8)) } ?? "none")")
                print("🧪 ARViewWithOverlays instance: \(instanceAddress)")
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
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UpdateGhostSelection"))) { notification in
                if let cameraPosition = notification.userInfo?["cameraPosition"] as? simd_float3,
                   let ghostPositions = notification.userInfo?["ghostPositions"] as? [UUID: simd_float3] {
                    let visibleGhostIDs = notification.userInfo?["visibleGhostIDs"] as? Set<UUID>
                    arCalibrationCoordinator.updateGhostSelection(
                        cameraPosition: cameraPosition,
                        ghostPositions: ghostPositions,
                        visibleGhostIDs: visibleGhostIDs
                    )
                }
            }
            .onDisappear {
                // Clean up on dismiss - defer to avoid view update conflicts
                DispatchQueue.main.async {
                currentMode = .idle
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
                let ghostMapPointID = notification.userInfo?["ghostMapPointID"] as? UUID
                
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
                
                // Handle marker placement in calibration mode
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
                
                // CRITICAL SAFETY CHECK: Block if not in placing vertices state (unless ghost confirm)
                if !isGhostConfirm {
                guard case .placingVertices = arCalibrationCoordinator.calibrationState else {
                    print("⚠️ [REGISTER_MARKER_TRACE] CRITICAL: registerMarker called outside placingVertices state!")
                    print("   Current state: \(arCalibrationCoordinator.stateDescription)")
                    print("   This should never happen - investigating caller")
                    return
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
                
                // Register with coordinator
                arCalibrationCoordinator.registerMarker(
                    mapPointID: targetMapPointID,
                    marker: marker,
                    sourceType: sourceType,
                    distortionVector: nil
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
                
                // Survey Marker Controls (below PiP map) - only when triangle is calibrated
                if let triangle = selectedTriangle,
                   triangle.isCalibrated {
                    VStack(spacing: 12) {
                        // Spacing slider
                        VStack(spacing: 4) {
                            Text("Survey Spacing")
                                .font(.caption)
                                .foregroundColor(.white)
                            
                            HStack(spacing: 8) {
                                Text("0.5m")
                                    .font(.caption2)
                                    .foregroundColor(surveySpacing == 0.5 ? .green : .gray)
                                    .onTapGesture { surveySpacing = 0.5 }
                                
                                Text("0.75m")
                                    .font(.caption2)
                                    .foregroundColor(surveySpacing == 0.75 ? .green : .gray)
                                    .onTapGesture { surveySpacing = 0.75 }
                                
                                Text("1.0m")
                                    .font(.caption2)
                                    .foregroundColor(surveySpacing == 1.0 ? .green : .gray)
                                    .onTapGesture { surveySpacing = 1.0 }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                        
                        // Fill Triangle button
                        Button(action: {
                            print("🎯 [FILL_TRIANGLE_BTN] Button tapped")
                            print("   Current state: \(arCalibrationCoordinator.stateDescription)")
                            
                            arCalibrationCoordinator.enterSurveyMode()
                            
                            print("🎯 [FILL_TRIANGLE_BTN] Entering survey mode")
                            print("   New state: \(arCalibrationCoordinator.stateDescription)")
                            
                            NotificationCenter.default.post(
                                name: NSNotification.Name("FillTriangleWithSurveyMarkers"),
                                object: nil,
                                userInfo: [
                                    "triangleID": triangle.id,
                                    "spacing": surveySpacing,
                                    "arWorldMapStore": arCalibrationCoordinator.arStore
                                ]
                            )
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "grid.circle.fill")
                                    .font(.system(size: 14))
                                Text("Fill Triangle")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                    .position(x: geo.size.width - 120, y: 270) // Below PiP map
                    .zIndex(997)
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
            
            // Tap-to-Place Button (bottom) - only in ACTIVE triangle calibration mode
            if case .triangleCalibration = currentMode {
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
                    
                    // Progress dots indicator
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
                    
                    // Status text
                    Text(arCalibrationCoordinator.statusText)
                        .font(.footnote)
                        .foregroundColor(.white)
                        .padding(.bottom, 8)
                    
                    // Place Marker / Ghost Interaction buttons
                    // Show during vertex placement OR when in readyToFill with a ghost selected (crawl mode)
                    // BUT NOT when reposition is pending (user tapped "Reposition Marker")
                    let shouldShowGhostButtons: Bool = {
                    if case .placingVertices = arCalibrationCoordinator.calibrationState {
                            return true
                        }
                        if arCalibrationCoordinator.calibrationState == .readyToFill && arCalibrationCoordinator.selectedGhostMapPointID != nil {
                            return true
                        }
                        return false
                    }()
                    
                    // Show ghost interaction buttons only when:
                    // - A ghost is selected AND
                    // - We're not in reposition mode (waiting for free placement)
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
                                
                                // Check if we're in crawl mode (readyToFill + ghost selected)
                                if case .readyToFill = arCalibrationCoordinator.calibrationState,
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
                                
                                // Check if we're in crawl mode (.readyToFill + ghost selected)
                                if case .readyToFill = arCalibrationCoordinator.calibrationState,
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
                                    // 3rd vertex ghost adjustment - if ANY ghost is selected during vertex placement, remove it
                                    print("🔗 [3RD_VERTEX_ADJUST] Adjusting vertex ghost position via crosshair")
                                    print("   Ghost MapPoint: \(String(ghostMapPointID.uuidString.prefix(8)))")
                                    
                                    // Remove the ghost marker first
                                    NotificationCenter.default.post(
                                        name: NSNotification.Name("RemoveGhostMarker"),
                                        object: nil,
                                        userInfo: ["mapPointID": ghostMapPointID]
                                    )
                                    
                                    // Clear ghost selection
                                    arCalibrationCoordinator.selectedGhostMapPointID = nil
                                    
                                    // Then place marker at crosshair (normal placement, not crawl mode)
                                    NotificationCenter.default.post(
                                        name: NSNotification.Name("PlaceMarkerAtCursor"),
                                        object: nil
                                    )
                                    
                                    // Clear reposition mode if it was active
                                    arCalibrationCoordinator.repositionModeActive = false
                                } else {
                                    // Normal crosshair placement (not crawl mode, not 3rd vertex adjust)
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
                    
                    // Survey Marker Generation Button
                    if let currentTriangleID = arCalibrationCoordinator.activeTriangleID,
                       let triangle = selectedTriangle,
                       triangle.id == currentTriangleID,
                       arCalibrationCoordinator.isTriangleComplete(currentTriangleID) {
                        
                        Button(action: {
                            print("🎯 [FILL_TRIANGLE_BTN] Button tapped")
                            print("   Current state: \(arCalibrationCoordinator.stateDescription)")
                            
                            arCalibrationCoordinator.enterSurveyMode()
                            
                            print("🎯 [FILL_TRIANGLE_BTN] Entering survey mode")
                            print("   New state: \(arCalibrationCoordinator.stateDescription)")
                            
                            // Post notification to trigger survey marker generation
                            // CRITICAL: Pass triangleStore so we can look up triangle by ID
                            // Don't rely on selectedTriangle which might be stale
                            NotificationCenter.default.post(
                                name: NSNotification.Name("FillTriangleWithSurveyMarkers"),
                                object: nil,
                                userInfo: [
                                    "triangleID": currentTriangleID,
                                    "spacing": surveySpacing,
                                    "arWorldMapStore": arCalibrationCoordinator.arStore,
                                    "triangleStore": arCalibrationCoordinator.triangleStore
                                ]
                            )
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "circle.grid.3x3.fill")
                                    .font(.system(size: 22, weight: .semibold))
                                Text("Fill Triangle")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 60)
                    } else {
                        // Spacer to maintain layout when button is hidden
                        Spacer()
                            .frame(height: 60)
                            .padding(.bottom, 60)
                    }
                }
                .zIndex(997)
            }
            
            // Place AR Marker Button + Strategy Picker (bottom) - only in idle mode with no triangle selected
            if currentMode == .idle && selectedTriangle == nil {
                VStack {
                    Spacer()
                    
                    // Strategy Picker (developer UI)
                    VStack(spacing: 8) {
                        Text("Relocalization Strategy")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Picker("Strategy", selection: Binding(
                            get: { relocalizationCoordinator.selectedStrategyName },
                            set: { newName in
                                relocalizationCoordinator.selectedStrategyName = newName
                                // Update selectedStrategyID to match
                                if let strategy = relocalizationCoordinator.availableStrategies.first(where: { $0.displayName == newName }) {
                                    relocalizationCoordinator.selectedStrategyID = strategy.id
                                }
                            }
                        )) {
                            ForEach(relocalizationCoordinator.availableStrategies, id: \.id) { strategy in
                                Text(strategy.displayName).tag(strategy.displayName)
                            }
                        }
                        .pickerStyle(.segmented)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 12)
                    
                    // Place AR Marker button - only in idle mode (not during calibration)
                    if case .idle = arCalibrationCoordinator.calibrationState {
                        Button(action: {
                            print("🔍 [PLACE_AR_MARKER_BTN] Button tapped (idle mode)")
                            NotificationCenter.default.post(
                                name: NSNotification.Name("PlaceMarkerAtCursor"),
                                object: nil
                            )
                        }) {
                            Text("Place AR Marker")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(.ultraThickMaterial)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 60)
                    }
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
    
    // Focused point ID for zoom/center (nil = show full map or frame triangle)
    // Computed reactively from arCalibrationCoordinator to respond to currentVertexIndex changes
    private var focusedPointID: UUID? {
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
    @State private var isAnimating: Bool = false
    @State private var positionSamples: [simd_float3] = [] // Ring buffer for smoothing
    
    // Debug toggle: Center PiP on user position during crawl mode (.readyToFill)
    // TODO: Move to DebugSettingsManager once validated
    @State private var followUserInPiPMap: Bool = true
    
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
            // Triangle complete - either follow user or frame triangle
            if followUserInPiPMap, let userPos = userMapPosition {
                // Follow user position during crawl mode
                print("📍 [PIP_TRANSFORM] Following user at (\(String(format: "%.0f", userPos.x)), \(String(format: "%.0f", userPos.y)))")
                let focused = PiPMapTransform.focused(on: userPos, imageSize: imageSize, frameSize: frameSize, targetZoom: 12.0)
                return (focused.scale, focused.offset)
            } else if let triangle = selectedTriangle,
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
              let triangle = arCalibrationCoordinator.triangleStore.triangle(withID: triangleID) else {
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
            // Use MapContainer (same as main map view)
            MapContainer(mapImage: mapImage)
                .environmentObject(pipTransform)
                .environmentObject(pipProcessor)
                .frame(width: mapImage.size.width, height: mapImage.size.height)
                .allowsHitTesting(false) // Disable gestures in PiP
            
            // User position dot overlay (only in calibration mode)
            if isCalibrationMode, let userPos = userMapPosition {
                userPositionDot(userPos: userPos)
            }
            
            // Focused point indicator (if any) - must be after MapContainer to render on top
            if let pointID = focusedPointID,
               let point = mapPointStore.points.first(where: { $0.id == pointID }) {
                focusedPointIndicator(pointID: pointID, point: point)
            }
        }
    }
    
    @ViewBuilder
    private func userPositionDot(userPos: CGPoint) -> some View {
        ZStack {
            // Base dot
            Circle()
                .fill(Color(red: 103/255, green: 31/255, blue: 121/255))
                .frame(width: 15, height: 15)
            
            // Pulse animation ring
            Circle()
                .stroke(Color(red: 73/255, green: 206/255, blue: 248/255), lineWidth: 2)
                .frame(width: 15, height: 15)
                .scaleEffect(isAnimating ? 22.0/15.0 : 1.0) // Grow from 15px to 22px
                .opacity(isAnimating ? 0.0 : 0.5) // Fade from 0.5 to 0
                .onAppear {
                    // Start repeating animation
                    withAnimation(Animation.easeOut(duration: 1.0).repeatForever(autoreverses: false)) {
                        isAnimating = true
                    }
                }
        }
        .position(userPos)
    }
    
    @ViewBuilder
    private func focusedPointIndicator(pointID: UUID, point: MapPointStore.MapPoint) -> some View {
        ZStack {
            // Outer ring for visibility
            Circle()
                .fill(Color.cyan.opacity(0.3))
                .frame(width: 20, height: 20)
            
            // Inner circle
            Circle()
                .fill(Color.cyan)
                .frame(width: 12, height: 12)
            
            // White border
            Circle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: 12, height: 12)
        }
        .position(point.mapPoint)
        .onAppear {
            print("📍 PiP Map: Displaying focused point \(String(pointID.uuidString.prefix(8))) at (\(Int(point.mapPoint.x)), \(Int(point.mapPoint.y)))")
        }
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
        
        // Start pulse animation
        isAnimating = true
        
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
        isAnimating = false
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
        
        // Project AR world position to 2D map coordinates
        if let projectedPosition = projectARPositionToMap(arPosition: smoothedPosition) {
            userMapPosition = projectedPosition
            // Share position with coordinator for proximity-based triangle selection
            arCalibrationCoordinator.updateUserPosition(projectedPosition)
        }
    }
    
    /// Project AR world position to 2D map coordinates using placed markers
    private func projectARPositionToMap(arPosition: simd_float3) -> CGPoint? {
        guard let triangle = selectedTriangle else {
            return nil
        }
        
        let arStore = arCalibrationCoordinator.arStore
        
        // Get placed markers for this triangle
        let placedMarkerMapPointIDs = arCalibrationCoordinator.placedMarkers
        guard placedMarkerMapPointIDs.count >= 2 else {
            // Need at least 2 markers for projection
            return nil
        }
        
        // Collect AR world positions and corresponding 2D map positions
        var arPositions: [simd_float3] = []
        var mapPositions: [CGPoint] = []
        
        for mapPointID in placedMarkerMapPointIDs {
            // Find AR marker linked to this mapPointID
            // Look through triangle's arMarkerIDs to find the marker
            for markerIDString in triangle.arMarkerIDs {
                guard let markerUUID = UUID(uuidString: markerIDString),
                      let arMarker = arStore.marker(withID: markerUUID),
                      arMarker.mapPointID == mapPointID.uuidString,
                      let mapPoint = mapPointStore.points.first(where: { $0.id == mapPointID }) else {
                    continue
                }
                
                // Extract AR position from transform
                let transform = arMarker.worldTransform.toSimd()
                let arPos = simd_float3(
                    transform.columns.3.x,
                    transform.columns.3.y,
                    transform.columns.3.z
                )
                arPositions.append(arPos)
                mapPositions.append(mapPoint.mapPoint)
                break // Found marker for this mapPointID
            }
        }
        
        guard arPositions.count >= 2 else {
            return nil
        }
        
        // Use barycentric interpolation for 3 points, or linear interpolation for 2 points
        if arPositions.count == 3 {
            return projectUsingBarycentric(
                userARPos: arPosition,
                arPositions: arPositions,
                mapPositions: mapPositions
            )
        } else {
            // Linear interpolation using 2 points
            return projectUsingLinear(
                userARPos: arPosition,
                arPositions: Array(arPositions.prefix(2)),
                mapPositions: Array(mapPositions.prefix(2))
            )
        }
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
}

