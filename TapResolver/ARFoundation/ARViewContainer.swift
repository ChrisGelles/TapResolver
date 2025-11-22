import SwiftUI
import ARKit
import SceneKit
import simd
import CoreImage

struct ARViewContainer: UIViewRepresentable {
    @Binding var mode: ARMode
    
    // Calibration mode properties
    var isCalibrationMode: Bool = false
    var selectedTriangle: TrianglePatch? = nil
    var onDismiss: (() -> Void)? = nil
    
    // Plane visualization toggle
    @Binding var showPlaneVisualization: Bool
    
    // Metric square store for map scale
    var metricSquareStore: MetricSquareStore?
    
    // Map point store for survey markers
    var mapPointStore: MapPointStore?

        func makeCoordinator() -> ARViewCoordinator {
        let coordinator = ARViewCoordinator()
        coordinator.selectedTriangle = selectedTriangle
        if let triangle = selectedTriangle {
            print("🔍 [SELECTED_TRIANGLE] Set in makeCoordinator: \(String(triangle.id.uuidString.prefix(8)))")
        } else {
            print("🔍 [SELECTED_TRIANGLE] Set in makeCoordinator: nil")
        }
        coordinator.isCalibrationMode = isCalibrationMode
        coordinator.showPlaneVisualization = showPlaneVisualization
        coordinator.metricSquareStore = metricSquareStore
        coordinator.mapPointStore = mapPointStore
        return coordinator
    }

    func makeUIView(context: Context) -> ARSCNView {
        let sceneView = ARSCNView(frame: .zero)
        sceneView.scene = SCNScene()
        
        // Disable automatic occlusion so markers aren't clipped by ground plane
        sceneView.automaticallyUpdatesLighting = false
        sceneView.rendersCameraGrain = false

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]  // Enable both horizontal and vertical plane detection
        sceneView.session.run(config)
        
        // RELOCALIZATION PREP: Start new AR session
        // TODO: Also call this when session is interrupted/reset
        // Hook into session(_:didFailWithError:), sessionWasInterrupted(_:), or session(_:didUpdate:)
        // Note: arWorldMapStore is passed via notification, so we'll call startNewSession() from ARViewWithOverlays
        
        // Set delegate for plane visualization
        sceneView.delegate = context.coordinator
        
        // Enable ARKit debug visuals
        sceneView.debugOptions = [
            .showFeaturePoints,
            .showWorldOrigin
        ]

        context.coordinator.sceneView = sceneView
        context.coordinator.setMode(mode)
        context.coordinator.setupTapGesture()
        context.coordinator.setupScene()

        return sceneView
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {
        context.coordinator.setMode(mode)
        
        // Debug: Track when selectedTriangle changes
        let oldTriangleID = context.coordinator.selectedTriangle?.id
        context.coordinator.selectedTriangle = selectedTriangle
        let newTriangleID = selectedTriangle?.id
        if oldTriangleID != newTriangleID {
            if let oldID = oldTriangleID {
                print("🔍 [SELECTED_TRIANGLE] Changed in updateUIView: \(String(oldID.uuidString.prefix(8))) → ", terminator: "")
            } else {
                print("🔍 [SELECTED_TRIANGLE] Changed in updateUIView: nil → ", terminator: "")
            }
            if let newID = newTriangleID {
                print("\(String(newID.uuidString.prefix(8)))")
            } else {
                print("nil")
            }
        }
        
        context.coordinator.isCalibrationMode = isCalibrationMode
        context.coordinator.showPlaneVisualization = showPlaneVisualization
        context.coordinator.metricSquareStore = metricSquareStore
        context.coordinator.mapPointStore = mapPointStore
        
        // Store coordinator reference for world map access
        ARViewContainer.Coordinator.current = context.coordinator
    }

    class ARViewCoordinator: NSObject {
        static var current: ARViewCoordinator?
        
        var sceneView: ARSCNView?
        var currentMode: ARMode = .idle
        var placedMarkers: [UUID: SCNNode] = [:] // Track placed markers by ID
        var ghostMarkers: [UUID: SCNNode] = [:] // Track ghost markers by MapPoint ID
        var surveyMarkers: [UUID: SCNNode] = [:]  // markerID -> node
        weak var metricSquareStore: MetricSquareStore?
        weak var mapPointStore: MapPointStore?
        private var crosshairNode: GroundCrosshairNode?
        var currentCursorPosition: simd_float3?
        
        // Calibration mode state
        var isCalibrationMode: Bool = false
        var selectedTriangle: TrianglePatch? = nil
        
        // Plane visualization toggle
        var showPlaneVisualization: Bool = true  // Default to enabled
        
        // User device height (centralized constant)
        var userDeviceHeight: Float = ARVisualDefaults.userDeviceHeight
        
        // Survey marker collision tracking
        private var lastHapticTriggerTime: [UUID: TimeInterval] = [:]  // Debounce haptics per marker
        private let hapticCooldown: TimeInterval = 0.5  // 500ms between haptics for same marker
        private let collisionRadius: Float = 0.03  // Match sphere radius from ARMarkerRenderer
        
        // Timer for updating crosshair
        private var crosshairUpdateTimer: Timer?

        func setMode(_ mode: ARMode) {
            guard mode != currentMode else { return }
            currentMode = mode
            handleModeChange(mode)
        }

        func handleModeChange(_ mode: ARMode) {
            switch mode {
            case .idle:
                print("🚦 AR Mode: idle")
                // Do nothing or reset

            case .calibration(let pointID):
                print("📍 Entering calibration mode for point: \(pointID)")
                // Start calibration logic

            case .triangleCalibration(let triangleID):
                print("🔺 Entering triangle calibration mode for triangle: \(triangleID)")
                // Triangle calibration logic handled via isCalibrationMode and selectedTriangle

            case .interpolation(let first, let second):
                print("📐 Interpolation between \(first) and \(second)")
                // Handle interpolator logic

            case .anchor(let mapPointID):
                print("⚓ Anchoring at map point: \(mapPointID)")
                // Re-anchor based on saved data

            case .metricSquare(let squareID, let sideLength):
                print("📏 Metric square: \(squareID), side: \(sideLength)m")
                // Currently removed; do nothing
                break
            }
        }

        func setupTapGesture() {
            guard let sceneView = sceneView else { return }
            
            // Remove any existing tap gesture recognizers
            sceneView.gestureRecognizers?.forEach { sceneView.removeGestureRecognizer($0) }
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
            sceneView.addGestureRecognizer(tapGesture)
            print("👆 Tap gesture configured")
            
            // Listen for PlaceMarkerAtCursor notification
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handlePlaceMarkerAtCursor),
                name: NSNotification.Name("PlaceMarkerAtCursor"),
                object: nil
            )
            
            // Listen for FillTriangleWithSurveyMarkers notification
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleFillTriangleWithSurveyMarkers),
                name: NSNotification.Name("FillTriangleWithSurveyMarkers"),
                object: nil
            )
            
            // Listen for triangle calibration complete
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("TriangleCalibrationComplete"),
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let self = self,
                      let triangleID = notification.userInfo?["triangleID"] as? UUID else { return }
                print("📐 Triangle calibration complete - drawing lines for \(String(triangleID.uuidString.prefix(8)))")
                self.drawTriangleLines(triangleID: triangleID)
            }
        }
        
        @objc func handlePlaceMarkerAtCursor() {
            print("🔍 [PLACE_MARKER_CROSSHAIR] Called")
            
            // Note: Calibration state check should be done before posting notification
            // This is a fallback guard in case notification is posted incorrectly
            guard let position = currentCursorPosition else {
                print("⚠️ [PLACE_MARKER_CROSSHAIR] No cursor position available for marker placement")
                return
            }
            placeMarker(at: position)
        }
        
        @objc func handleFillTriangleWithSurveyMarkers(notification: Notification) {
            guard let triangleID = notification.userInfo?["triangleID"] as? UUID,
                  let spacing = notification.userInfo?["spacing"] as? Float,
                  let triangleStore = notification.userInfo?["triangleStore"] as? TrianglePatchStore,
                  let arWorldMapStore = notification.userInfo?["arWorldMapStore"] as? ARWorldMapStore else {
                print("⚠️ [FILL_TRIANGLE] Invalid notification data:")
                print("   triangleID: \(notification.userInfo?["triangleID"] != nil)")
                print("   spacing: \(notification.userInfo?["spacing"] != nil)")
                print("   triangleStore: \(notification.userInfo?["triangleStore"] != nil)")
                print("   arWorldMapStore: \(notification.userInfo?["arWorldMapStore"] != nil)")
                return
            }
            
            // CRITICAL: Look up triangle by ID from triangleStore, don't rely on selectedTriangle
            // selectedTriangle might be stale or point to wrong triangle
            guard let triangle = triangleStore.triangle(withID: triangleID) else {
                print("❌ [FILL_TRIANGLE] Triangle \(String(triangleID.uuidString.prefix(8))) not found in triangleStore")
                print("   Available triangles: \(triangleStore.triangles.map { String($0.id.uuidString.prefix(8)) })")
                if let selected = selectedTriangle {
                    print("   selectedTriangle ID: \(String(selected.id.uuidString.prefix(8)))")
                } else {
                    print("   selectedTriangle: nil")
                }
                return
            }
            
            print("✅ [FILL_TRIANGLE] Found triangle \(String(triangleID.uuidString.prefix(8)))")
            print("   arMarkerIDs: \(triangle.arMarkerIDs)")
            print("   vertexIDs: \(triangle.vertexIDs.map { String($0.uuidString.prefix(8)) })")
            
            generateSurveyMarkers(for: triangle, spacing: spacing, arWorldMapStore: arWorldMapStore)
        }

        @objc func handleTapGesture(_ sender: UITapGestureRecognizer) {
            print("🔍 [TAP_TRACE] Tap detected")
            print("   Current mode: \(currentMode)")
            
            // Disable tap-to-place in idle mode - use Place AR Marker button instead
            guard currentMode != .idle else {
                print("👆 [TAP_TRACE] Tap ignored in idle mode — use Place AR Marker button")
                return
            }
            
            // Disable tap-to-place in triangle calibration mode - use Place Marker button instead
            if case .triangleCalibration = currentMode {
                print("👆 [TAP_TRACE] Tap ignored in triangle calibration mode — use Place Marker button")
                return
            }
            
            guard let sceneView = sceneView else { return }
            
            let location = sender.location(in: sceneView)
            
            // Perform hit test to find world position
            let hitTestResults = sceneView.hitTest(location, types: [.featurePoint, .estimatedHorizontalPlane])
            
            guard let result = hitTestResults.first else {
                print("⚠️ No hit test result at tap location")
                return
            }
            
            // Extract world position from transform matrix
            let worldTransform = result.worldTransform
            let position = simd_float3(
                worldTransform.columns.3.x,
                worldTransform.columns.3.y,
                worldTransform.columns.3.z
            )
            
            print("👆 Tap detected at screen: \(location), world: \(position)")
            placeMarker(at: position)
        }

        @discardableResult
        func placeMarker(at position: simd_float3) -> UUID {
            guard let sceneView = sceneView else { return UUID() }
            
            let markerID = UUID()
            
            // Determine color based on current mode
            let markerColor: UIColor
            let shouldAnimate: Bool
            switch currentMode {
            case .calibration:
                markerColor = UIColor.ARPalette.calibration
                shouldAnimate = false
            case .triangleCalibration(_):
                markerColor = UIColor.ARPalette.calibration  // Orange for triangle calibration
                shouldAnimate = true
            case .anchor:
                markerColor = UIColor.ARPalette.anchor
                shouldAnimate = false
            default:
                markerColor = UIColor.ARPalette.markerBase
                shouldAnimate = false
            }
            
            // Create marker using centralized renderer
            let options = MarkerOptions(
                color: markerColor,
                markerID: markerID,
                userDeviceHeight: userDeviceHeight,
                animateOnAppearance: shouldAnimate
            )
            let markerNode = ARMarkerRenderer.createNode(at: position, options: options)
            
            sceneView.scene.rootNode.addChildNode(markerNode)
            
            // Track the marker
            placedMarkers[markerID] = markerNode
            
            print("📍 Placed marker \(String(markerID.uuidString.prefix(8))) at AR(\(String(format: "%.2f", position.x)), \(String(format: "%.2f", position.y)), \(String(format: "%.2f", position.z))) meters")
            
            // Post notification for marker placement
            NotificationCenter.default.post(
                name: NSNotification.Name("ARMarkerPlaced"),
                object: nil,
                userInfo: [
                    "markerID": markerID,
                    "position": [position.x, position.y, position.z] // Convert simd_float3 to array
                ]
            )
            
            return markerID
        }

        func setupScene() {
            guard let sceneView = sceneView else { return }
            
            // Setup modular crosshair
            crosshairNode = GroundCrosshairNode()
            if let node = crosshairNode {
                sceneView.scene.rootNode.addChildNode(node)
            }
            
            // Start updating crosshair position
            crosshairUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                self?.updateCrosshair()
            }
            
            print("➕ Ground crosshair configured")
        }
        
        func updateCrosshair() {
            guard let sceneView = sceneView,
                  let crosshair = crosshairNode else { return }
            
            let screenCenter = CGPoint(x: sceneView.bounds.midX, y: sceneView.bounds.midY)
            
            guard let query = sceneView.raycastQuery(from: screenCenter, allowing: .estimatedPlane, alignment: .horizontal) else {
                crosshair.hide()
                currentCursorPosition = nil
                return
            }
            
            let results = sceneView.session.raycast(query)
            
            if let result = results.first {
                let rawPosition = simd_float3(
                    result.worldTransform.columns.3.x,
                    result.worldTransform.columns.3.y,
                    result.worldTransform.columns.3.z
                )
                
                // Check for corner snapping (optional - can be enhanced later)
                let snappedPosition = findNearbyCorner(from: rawPosition) ?? rawPosition
                let isSnapped = snappedPosition != rawPosition
                let isConfident = isPlaneConfident(result)
                
                crosshair.update(position: snappedPosition, snapped: isSnapped, confident: isConfident)
                currentCursorPosition = snappedPosition
                
                if isSnapped {
                    print("📍 Crosshair snapped to corner")
                }
            } else {
                crosshair.hide()
                currentCursorPosition = nil
            }
            
            // Check for survey marker collisions
            checkSurveyMarkerCollisions()
        }
        
        private func isPlaneConfident(_ result: ARRaycastResult) -> Bool {
            guard let planeAnchor = result.anchor as? ARPlaneAnchor else { return false }
            let extent = planeAnchor.planeExtent
            return (extent.width * extent.height) > 0.5
        }
        
        private func findNearbyCorner(from position: simd_float3) -> simd_float3? {
            // TODO: Implement corner detection logic if needed
            // For now, return nil to disable snapping
            return nil
        }

        /// Get the current ARWorldMap from the session (async)
        func getCurrentWorldMap(completion: @escaping (ARWorldMap?, Error?) -> Void) {
            guard let session = sceneView?.session else {
                completion(nil, NSError(domain: "ARViewContainer", code: -1, userInfo: [NSLocalizedDescriptionKey: "No AR session available"]))
                return
            }
            
            session.getCurrentWorldMap { map, error in
                completion(map, error)
            }
        }
        
        /// Capture current AR camera frame as UIImage
        func captureARFrame(completion: @escaping (UIImage?) -> Void) {
            guard let sceneView = sceneView else {
                completion(nil)
                return
            }
            
            // Get current ARFrame from session
            guard let frame = sceneView.session.currentFrame else {
                print("⚠️ No current ARFrame available")
                completion(nil)
                return
            }
            
            // Convert ARFrame's capturedImage (CVPixelBuffer) to UIImage
            let pixelBuffer = frame.capturedImage
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext()
            
            guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
                print("⚠️ Failed to create CGImage from ARFrame")
                completion(nil)
                return
            }
            
            // Convert to UIImage, accounting for camera orientation
            let image = UIImage(cgImage: cgImage, scale: 1.0, orientation: .right)
            completion(image)
        }
        
        /// Get current AR camera world position
        func getCurrentCameraPosition() -> simd_float3? {
            guard let sceneView = sceneView,
                  let frame = sceneView.session.currentFrame else {
                return nil
            }
            
            let cameraTransform = frame.camera.transform
            let position = simd_float3(
                cameraTransform.columns.3.x,
                cameraTransform.columns.3.y,
                cameraTransform.columns.3.z
            )
            return position
        }
        
        // MARK: - DEPRECATED
        /// DO NOT USE - Legacy function with incorrect interpolation.
        /// Use plantGhostMarkers(calibratedTriangle:, triangleStore:, filter:) instead.
        func estimateWorldPosition(for mapPoint: CGPoint, using triangle: TrianglePatch?) -> simd_float3? {
            print("⚠️ [DEPRECATED] Function \(#function) was called. Refactor needed.")
            if let symbol = Thread.callStackSymbols.dropFirst(1).first {
                print("🔍 Called by: \(symbol)")
            }
            return nil
            
            /* OLD LOGIC COMMENTED OUT
            guard let sceneView = sceneView,
                  let frame = sceneView.session.currentFrame else {
                return nil
            }
            
            // If triangle has a transform, use it to project map coordinates to AR space
            if let triangle = triangle,
               let transform = triangle.transform {
                // Convert map point to AR space using Similarity2D transform
                let mapPointFloat = simd_float2(Float(mapPoint.x), Float(mapPoint.y))
                let transformed = transform.rotation * (mapPointFloat * transform.scale) + transform.translation
                // Use device height to place on ground
                let groundY = userDeviceHeight > 0 ? -userDeviceHeight : -1.0
                return simd_float3(transformed.x, groundY, transformed.y)
            }
            
            // Fallback: Place in front of camera on ground plane
            let cameraTransform = frame.camera.transform
            let cameraPosition = simd_float3(
                cameraTransform.columns.3.x,
                cameraTransform.columns.3.y,
                cameraTransform.columns.3.z
            )
            
            // Forward vector (negative Z in camera space)
            let forward = simd_float3(
                -cameraTransform.columns.2.x,
                -cameraTransform.columns.2.y,
                -cameraTransform.columns.2.z
            )
            
            // Place 1 meter in front of camera, on ground plane
            let estimatedPosition = cameraPosition + forward * 1.0
            let groundY = userDeviceHeight > 0 ? -userDeviceHeight : -1.0
            return simd_float3(estimatedPosition.x, groundY, estimatedPosition.z)
            */ // END OLD LOGIC
        }
        
        // MARK: - DEPRECATED
        /// DO NOT USE - Calls deprecated estimateWorldPosition().
        /// Use plantGhostMarkers(calibratedTriangle:, triangleStore:, filter:) instead.
        func addGhostMarker(mapPointID: UUID, mapPoint: CGPoint, using triangle: TrianglePatch?) {
            print("⚠️ [DEPRECATED] Function \(#function) was called. Refactor needed.")
            if let symbol = Thread.callStackSymbols.dropFirst(1).first {
                print("🔍 Called by: \(symbol)")
            }
            return
            
            /* OLD LOGIC COMMENTED OUT
            guard let sceneView = sceneView else { return }
            
            // Don't add if already has a real marker
            if placedMarkers.values.contains(where: { $0.name?.contains(mapPointID.uuidString) ?? false }) {
                return
            }
            
            // Don't add if already has a ghost marker
            if ghostMarkers[mapPointID] != nil {
                return
            }
            
            guard let estimatedPosition = estimateWorldPosition(for: mapPoint, using: triangle) else {
                print("⚠️ Could not estimate world position for ghost marker")
                return
            }
            
            let ghostMarkerID = UUID()
            let options = MarkerOptions(
                color: UIColor.systemGray.withAlphaComponent(0.6),
                markerID: ghostMarkerID,
                userDeviceHeight: userDeviceHeight,
                radius: 0.025,  // Slightly smaller than regular markers
                animateOnAppearance: false,
                isGhost: true
            )
            
            let ghostNode = ARMarkerRenderer.createNode(at: estimatedPosition, options: options)
            ghostNode.name = "ghostMarker_\(mapPointID.uuidString)"
            
            sceneView.scene.rootNode.addChildNode(ghostNode)
            ghostMarkers[mapPointID] = ghostNode
            
            print("👻 Planted ghost marker for MapPoint \(String(mapPointID.uuidString.prefix(8))) at \(estimatedPosition)")
            */ // END OLD LOGIC
        }
        
        func teardownSession() {
            crosshairUpdateTimer?.invalidate()
            crosshairUpdateTimer = nil
            NotificationCenter.default.removeObserver(self)
            sceneView?.session.pause()
            print("🔧 AR session paused and torn down.")
        }
        
        // MARK: - Survey Marker Generation
        
        /// Generate survey markers inside a calibrated triangle
        private func generateSurveyMarkers(for triangle: TrianglePatch, spacing: Float, arWorldMapStore: ARWorldMapStore) {
            // Clear existing survey markers
            clearSurveyMarkers()
            
            // CRITICAL: Survey markers require all 3 vertices to be from the CURRENT AR session
            // Mixing coordinates from different sessions produces incorrect results because each
            // session has a different origin point (0,0,0) where the user started.
            //
            // RELOCALIZATION TODO: When lightweight relocalization is implemented, this check
            // can be removed. Instead, we'll transform markers from previous sessions into the
            // current session's coordinate system using the transformation matrix calculated from
            // re-placed known markers.
            
            print("🔍 [SURVEY_VALIDATION] Checking triangle vertices for session compatibility")
            print("   Current session ID: \(arWorldMapStore.currentSessionID)")
            print("   Triangle ID: \(triangle.id)")
            
            // Get triangle vertices from MapPointStore
            guard let mapPointStore = mapPointStore else {
                print("⚠️ MapPointStore not available")
                return
            }
            
            let vertexPoints = triangle.vertexIDs.compactMap { vertexID in
                mapPointStore.points.first(where: { $0.id == vertexID })
            }
            
            guard vertexPoints.count == 3 else {
                print("⚠️ Triangle does not have 3 valid vertices")
                return
            }
            
            // Check if all 3 vertices have markers from the current session
            // CRITICAL: Check session ID, not just presence in placedMarkers
            // Markers might be in ARWorldMapStore but still from current session
            var markersFromCurrentSession: [(vertexID: UUID, markerID: UUID, position: simd_float3, source: String)] = []
            var markersFromOtherSessions: [(vertexID: UUID, sessionID: UUID, markerID: String)] = []
            print("🔍 [SURVEY_VALIDATION] Current session ID: \(arWorldMapStore.currentSessionID)")
            print("🔍 [SURVEY_VALIDATION] Triangle arMarkerIDs count: \(triangle.arMarkerIDs.count)")
            print("🔍 [SURVEY_VALIDATION] Triangle arMarkerIDs contents: \(triangle.arMarkerIDs)")
            print("🔍 [SURVEY_VALIDATION] Triangle vertexIDs: \(triangle.vertexIDs.map { String($0.uuidString.prefix(8)) })")
            for (index, vertexID) in triangle.vertexIDs.enumerated() {
                var foundMarker = false
                
                // Get marker ID from triangle
                print("🔍 [SURVEY_VALIDATION] Checking vertex[\(index)] \(String(vertexID.uuidString.prefix(8)))")
                print("   arMarkerIDs.count: \(triangle.arMarkerIDs.count)")
                if index < triangle.arMarkerIDs.count {
                    print("   arMarkerIDs[\(index)]: '\(triangle.arMarkerIDs[index])' (isEmpty: \(triangle.arMarkerIDs[index].isEmpty))")
                } else {
                    print("   ⚠️ Index \(index) is out of bounds for arMarkerIDs array")
                }
                
                guard index < triangle.arMarkerIDs.count,
                      let markerIDString = triangle.arMarkerIDs[index].isEmpty ? nil : triangle.arMarkerIDs[index],
                      let markerUUID = UUID(uuidString: markerIDString) else {
                    print("❌ [SURVEY_VALIDATION] Vertex[\(index)] \(String(vertexID.uuidString.prefix(8))): No marker ID in triangle")
                    if index >= triangle.arMarkerIDs.count {
                        print("   Reason: Index \(index) >= arMarkerIDs.count (\(triangle.arMarkerIDs.count))")
                    } else if triangle.arMarkerIDs[index].isEmpty {
                        print("   Reason: arMarkerIDs[\(index)] is empty string")
                    } else {
                        print("   Reason: arMarkerIDs[\(index)] = '\(triangle.arMarkerIDs[index])' is not a valid UUID")
                    }
                    continue
                }
                
                // PRIORITY 1: Check placedMarkers (runtime dictionary)
                if let markerNode = placedMarkers[markerUUID] {
                    markersFromCurrentSession.append((vertexID, markerUUID, markerNode.simdPosition, "placedMarkers"))
                    print("✅ [SURVEY_VALIDATION] Vertex[\(index)] \(String(vertexID.uuidString.prefix(8))): Found in placedMarkers (current session)")
                    foundMarker = true
                }
                
                // PRIORITY 2: Check ARWorldMapStore and verify session ID
                else if let storedMarker = arWorldMapStore.markers.first(where: { UUID(uuidString: $0.id) == markerUUID }) {
                    // Check if marker is from current session
                    if storedMarker.sessionID == arWorldMapStore.currentSessionID {
                        // Marker is from current session, just not in runtime dictionary
                        let position = storedMarker.positionInSession
                        markersFromCurrentSession.append((vertexID, markerUUID, position, "ARWorldMapStore"))
                        print("✅ [SURVEY_VALIDATION] Vertex[\(index)] \(String(vertexID.uuidString.prefix(8))): Found in storage (current session)")
                        foundMarker = true
                    } else {
                        // Marker is from a different session
                        markersFromOtherSessions.append((vertexID, storedMarker.sessionID, storedMarker.id))
                        print("⚠️ [SURVEY_VALIDATION] Vertex[\(index)] \(String(vertexID.uuidString.prefix(8))): From different session")
                        print("   Marker session: \(String(storedMarker.sessionID.uuidString.prefix(8)))")
                        print("   Current session: \(String(arWorldMapStore.currentSessionID.uuidString.prefix(8)))")
                        foundMarker = true
                    }
                }
                
                if !foundMarker {
                    print("❌ [SURVEY_VALIDATION] Vertex[\(index)] \(String(vertexID.uuidString.prefix(8))): No marker found anywhere")
                }
            }
            print("📊 [SURVEY_VALIDATION] Summary:")
            print("   Current session markers: \(markersFromCurrentSession.count)/3")
            print("   Other session markers: \(markersFromOtherSessions.count)")
            for marker in markersFromCurrentSession {
                print("   ✅ \(String(marker.vertexID.uuidString.prefix(8))) via \(marker.source)")
            }
            for marker in markersFromOtherSessions {
                print("   ⚠️ \(String(marker.vertexID.uuidString.prefix(8))) from session \(String(marker.sessionID.uuidString.prefix(8)))")
            }
            
            // VALIDATION: All 3 markers must be from current session
            if markersFromCurrentSession.count < 3 {
                print("❌ [SURVEY_VALIDATION] Cannot place survey markers - coordinate system mismatch")
                print("   Markers from current session: \(markersFromCurrentSession.count)/3")
                print("   Markers from other sessions: \(markersFromOtherSessions.count)")
                print("")
                print("🔧 SOLUTION: Re-calibrate all 3 vertices in the current AR session")
                print("   This ensures all markers use the same coordinate origin.")
                print("")
                print("💡 FUTURE: When relocalization is implemented, you'll be able to:")
                print("   1. Place 2+ known markers to establish coordinate transformation")
                print("   2. System automatically transforms stored markers to current session")
                print("   3. Survey markers work across sessions")
                
                // Show user-friendly error in HUD
                // TODO: Add UI notification that calibration is needed
                return
            }
            
            print("✅ [SURVEY_VALIDATION] All 3 vertices from current session - proceeding")
            
            // Get 2D map coordinates
            let triangle2D = vertexPoints.map { $0.mapPoint }
            
            print("📍 Plotting points within triangle A(\(String(format: "%.1f", triangle2D[0].x)), \(String(format: "%.1f", triangle2D[0].y))) B(\(String(format: "%.1f", triangle2D[1].x)), \(String(format: "%.1f", triangle2D[1].y))) C(\(String(format: "%.1f", triangle2D[2].x)), \(String(format: "%.1f", triangle2D[2].y)))")
            
            // Get 3D AR positions - CRITICAL: Use current AR session coordinates ONLY
            // Mixing coordinates from different sessions produces incorrect interpolation because
            // each session has a different origin point where the user started.
            //
            // RELOCALIZATION TODO: When implemented, this section will:
            // 1. Check if markers are from current session
            // 2. If not, look up the session transformation matrix
            // 3. Apply transformation: old_position * transform = new_position
            // 4. Use transformed positions for interpolation
            var triangle3D: [simd_float3] = []
            print("🔍 [SURVEY_3D] Getting AR positions for triangle vertices")
            print("   Current session: \(arWorldMapStore.currentSessionID)")
            print("   Triangle has \(triangle.arMarkerIDs.count) marker IDs")
            
            for (index, vertexID) in triangle.vertexIDs.enumerated() {
                var foundPosition: simd_float3?
                var foundSource: String = "none"
                var markerSessionID: UUID?
                
                // Get marker ID from triangle
                guard index < triangle.arMarkerIDs.count,
                      let markerIDString = triangle.arMarkerIDs[index].isEmpty ? nil : triangle.arMarkerIDs[index],
                      let markerUUID = UUID(uuidString: markerIDString) else {
                    print("❌ [SURVEY_3D] Vertex[\(index)] \(String(vertexID.uuidString.prefix(8))): No marker ID")
                    continue
                }
                
                // PRIORITY 1: Check placedMarkers (current AR session runtime dictionary)
                if let markerNode = placedMarkers[markerUUID] {
                    foundPosition = markerNode.simdPosition
                    foundSource = "current session (placedMarkers)"
                    markerSessionID = arWorldMapStore.currentSessionID
                    print("✅ [SURVEY_3D] Vertex[\(index)] \(String(vertexID.uuidString.prefix(8))): \(foundSource) at \(markerNode.simdPosition)")
                }
                
                // PRIORITY 2: Check ARWorldMapStore and validate session ID
                else if let storedMarker = arWorldMapStore.markers.first(where: { UUID(uuidString: $0.id) == markerUUID }) {
                    markerSessionID = storedMarker.sessionID
                    foundPosition = storedMarker.positionInSession
                    
                    if storedMarker.sessionID == arWorldMapStore.currentSessionID {
                        foundSource = "current session (ARWorldMapStore)"
                        print("✅ [SURVEY_3D] Vertex[\(index)] \(String(vertexID.uuidString.prefix(8))): \(foundSource)")
                    } else {
                        foundSource = "DIFFERENT session (ARWorldMapStore)"
                        print("⚠️ [SURVEY_3D] Vertex[\(index)] \(String(vertexID.uuidString.prefix(8))): \(foundSource)")
                        print("   Marker session: \(String(storedMarker.sessionID.uuidString.prefix(8)))")
                        print("   Current session: \(String(arWorldMapStore.currentSessionID.uuidString.prefix(8)))")
                        print("   ⚠️ COORDINATE SYSTEM MISMATCH!")
                    }
                }
                
                if let position = foundPosition, let sessionID = markerSessionID {
                    triangle3D.append(position)
                    print("   Session: \(String(sessionID.uuidString.prefix(8)))")
                    print("   Source: \(foundSource)")
                } else {
                    print("❌ [SURVEY_3D] Vertex[\(index)] \(String(vertexID.uuidString.prefix(8))): No AR marker found!")
                }
            }
            
            print("🔍 [SURVEY_3D] Collected \(triangle3D.count)/3 AR positions")
            // Validate that we have 3 positions
            guard triangle3D.count == 3 else {
                print("❌ [SURVEY_3D] Could not retrieve 3 AR positions for triangle vertices (got \(triangle3D.count)/3)")
                print("   This usually means markers haven't been placed in the current AR session")
                return
            }
            
            // CRITICAL: Count markers from current session (checking session ID, not just placedMarkers)
            var markersFromCurrentSessionCount = 0
            for (index, vertexID) in triangle.vertexIDs.enumerated() {
                guard index < triangle.arMarkerIDs.count,
                      let markerIDString = triangle.arMarkerIDs[index].isEmpty ? nil : triangle.arMarkerIDs[index],
                      let markerUUID = UUID(uuidString: markerIDString) else {
                    continue
                }
                
                // Check placedMarkers first
                if placedMarkers[markerUUID] != nil {
                    markersFromCurrentSessionCount += 1
                }
                // Check ARWorldMapStore with session ID validation
                else if let storedMarker = arWorldMapStore.markers.first(where: { UUID(uuidString: $0.id) == markerUUID }),
                        storedMarker.sessionID == arWorldMapStore.currentSessionID {
                    markersFromCurrentSessionCount += 1
                }
            }
            
            if markersFromCurrentSessionCount < 3 {
                print("❌ [SURVEY_3D] FATAL: Mixed coordinate systems detected")
                print("   Markers from current session: \(markersFromCurrentSessionCount)/3")
                print("   Cannot place survey markers - would produce incorrect positions")
                print("")
                print("   RELOCALIZATION TODO: Calculate transformation and proceed")
                return
            }
            
            print("✅ [SURVEY_3D] All markers from current session - safe to proceed")
            
            print("🌍 Planting Survey Markers within triangle A(\(String(format: "%.2f", triangle3D[0].x)), \(String(format: "%.2f", triangle3D[0].y)), \(String(format: "%.2f", triangle3D[0].z))) B(\(String(format: "%.2f", triangle3D[1].x)), \(String(format: "%.2f", triangle3D[1].y)), \(String(format: "%.2f", triangle3D[1].z))) C(\(String(format: "%.2f", triangle3D[2].x)), \(String(format: "%.2f", triangle3D[2].y)), \(String(format: "%.2f", triangle3D[2].z)))")
            
            // Get map scale (pixels per meter)
            guard let pxPerMeter = getPixelsPerMeter() else {
                print("⚠️ No map scale available (pxPerMeter)")
                return
            }
            
            // Generate 2D fill points
            let fillPoints2D = generateTriangleFillPoints(
                triangle: triangle2D,
                spacingMeters: spacing,
                pxPerMeter: pxPerMeter
            )
            
            print("📍 Generated \(fillPoints2D.count) survey points at \(spacing)m spacing")
            
            // Log first few 2D points
            let pointsToShow = min(fillPoints2D.count, 20)
            var pointsList = ""
            for i in 0..<pointsToShow {
                let p = fillPoints2D[i]
                pointsList += "s\(i+1)(\(String(format: "%.1f", p.x)), \(String(format: "%.1f", p.y))) "
            }
            if fillPoints2D.count > 20 {
                pointsList += "... (\(fillPoints2D.count - 20) more)"
            }
            print("📊 2D Survey Points: \(pointsList)")
            
            // Interpolate to 3D AR positions and place markers
            // Use the AVERAGE Y of the three calibration markers as ground level
            // This ensures survey markers are on the same plane as calibration markers
            let groundY = (triangle3D[0].y + triangle3D[1].y + triangle3D[2].y) / 3.0
            
            for (index, point2D) in fillPoints2D.enumerated() {
                // Round 2D coordinates to 1 decimal place for future data export
                let roundedX = round(point2D.x * 10) / 10
                let roundedY = round(point2D.y * 10) / 10
                let roundedPoint2D = CGPoint(x: roundedX, y: roundedY)
                
                guard let position3D = interpolateARPosition(
                    fromMapPoint: roundedPoint2D,
                    triangle2D: triangle2D,
                    triangle3D: triangle3D
                ) else {
                    print("⚠️ Could not interpolate AR position for point \(index)")
                    continue
                }
                
                // Create position with interpolated X/Z but consistent ground Y
                let groundPosition = simd_float3(position3D.x, groundY, position3D.z)
                
                // Log position BEFORE placing marker
                print("📍 Survey Marker placed at (\(String(format: "%.2f", groundPosition.x)), \(String(format: "%.2f", groundPosition.y)), \(String(format: "%.2f", groundPosition.z)))")
                
                // Use placeSurveyMarkerOnly() to create survey marker without MapPoint updates
                if let markerID = placeSurveyMarkerOnly(at: groundPosition, mapPoint: vertexPoints.first(where: { $0.mapPoint == roundedPoint2D }) ?? vertexPoints[0]) {
                    // Survey marker placed - no photo capture, no MapPoint updates
                    print("📍 Survey marker placed at map(\(roundedX), \(roundedY)) → AR(\(String(format: "%.2f", groundPosition.x)), \(String(format: "%.2f", groundPosition.y)), \(String(format: "%.2f", groundPosition.z)))")
                }
            }
            
            // Log first few 3D positions
            var markers3D = ""
            var markerCount = 0
            for (_, node) in surveyMarkers.prefix(20) {
                markerCount += 1
                let pos = node.simdPosition
                markers3D += "s\(markerCount)(\(String(format: "%.2f", pos.x)), \(String(format: "%.2f", pos.y)), \(String(format: "%.2f", pos.z))) "
            }
            if surveyMarkers.count > 20 {
                markers3D += "... (\(surveyMarkers.count - 20) more)"
            }
            print("📊 3D Survey Markers: \(markers3D)")
            
            print("✅ Placed \(surveyMarkers.count) survey markers")
        }
        
        /// Clear all survey markers from scene
        func clearSurveyMarkers() {
            for (_, node) in surveyMarkers {
                node.removeFromParentNode()
            }
            surveyMarkers.removeAll()
            lastHapticTriggerTime.removeAll()  // Clear collision tracking state
            print("🧹 Cleared survey markers")
        }
        
        /// Places a survey marker WITHOUT calling registerMarker (no photo, no MapPoint updates)
        func placeSurveyMarkerOnly(at position: simd_float3, mapPoint: MapPointStore.MapPoint) -> UUID? {
            guard let sceneView = sceneView else {
                print("⚠️ ARView not available for survey marker placement")
                return nil
            }
            
            let markerID = UUID()
            
            print("📍 Survey Marker placed at \(String(format: "(%.2f, %.2f, %.2f)", position.x, position.y, position.z))")
            
            // Create marker using centralized renderer with red color for survey
            let options = MarkerOptions(
                color: UIColor.red,
                markerID: markerID,
                userDeviceHeight: userDeviceHeight,
                radius: 0.035,  // Larger radius for survey markers
                animateOnAppearance: false
            )
            let markerNode = ARMarkerRenderer.createNode(at: position, options: options)
            markerNode.name = "surveyMarker_\(markerID.uuidString)"
            
            sceneView.scene.rootNode.addChildNode(markerNode)
            
            // Store in surveyMarkers, NOT in placedMarkers (to avoid MapPoint updates)
            surveyMarkers[markerID] = markerNode
            
            print("📍 Placed survey marker at map(\(String(format: "%.1f, %.1f", mapPoint.mapPoint.x, mapPoint.mapPoint.y))) → AR\(String(format: "(%.2f, %.2f, %.2f)", position.x, position.y, position.z))")
            
            return markerID
        }
        
        /// Clear all calibration AR markers from scene
        func clearCalibrationMarkers() {
            guard let sceneView = sceneView else { return }
            
            // Remove all calibration markers (orange markers used during triangle calibration)
            var markersToRemove: [UUID] = []
            for (markerID, node) in placedMarkers {
                // Check if this is a calibration marker by checking its color
                if let sphereNode = node.childNode(withName: "arMarkerSphere_\(markerID.uuidString)", recursively: true),
                   let sphere = sphereNode.geometry as? SCNSphere,
                   let material = sphere.firstMaterial,
                   let color = material.diffuse.contents as? UIColor {
                    // Check if it's calibration orange color (ARPalette.calibration)
                    if color == UIColor.ARPalette.calibration {
                        node.removeFromParentNode()
                        markersToRemove.append(markerID)
                    }
                }
            }
            
            // Remove from dictionary
            for markerID in markersToRemove {
                placedMarkers.removeValue(forKey: markerID)
            }
            
            if !markersToRemove.isEmpty {
                print("🧹 Cleared \(markersToRemove.count) calibration marker(s) from scene")
            }
        }
        
        /// Draw yellow lines connecting triangle vertices
        func drawTriangleLines(triangleID: UUID) {
            guard let sceneView = sceneView else { return }
            
            // Remove existing triangle lines
            sceneView.scene.rootNode.enumerateChildNodes { node, _ in
                if node.name?.hasPrefix("triangleLine_") == true {
                    node.removeFromParentNode()
                }
            }
            
            // Get triangle from selectedTriangle or use triangleID to look it up
            // We'll use the selectedTriangle if it matches, otherwise we need to access via coordinator
            guard let triangle = selectedTriangle, triangle.id == triangleID else {
                print("⚠️ Triangle \(String(triangleID.uuidString.prefix(8))) not found in selectedTriangle")
                return
            }
            
            // Get AR marker positions
            guard triangle.arMarkerIDs.count == 3 else {
                print("⚠️ Triangle doesn't have 3 AR markers yet")
                return
            }
            
            var vertices: [simd_float3] = []
            for markerIDString in triangle.arMarkerIDs {
                guard let markerUUID = UUID(uuidString: markerIDString),
                      let markerNode = placedMarkers[markerUUID] else {
                    print("⚠️ Could not find marker node for \(markerIDString)")
                    return
                }
                vertices.append(markerNode.simdPosition)
            }
            
            guard vertices.count == 3 else { return }
            
            // Create lines for each edge
            let edges = [
                (vertices[0], vertices[1], "triangleLine_01"),
                (vertices[1], vertices[2], "triangleLine_12"),
                (vertices[2], vertices[0], "triangleLine_20")
            ]
            
            for (start, end, name) in edges {
                let vector = end - start
                let distance = simd_length(vector)
                
                let cylinder = SCNCylinder(radius: 0.01, height: CGFloat(distance))
                cylinder.firstMaterial?.diffuse.contents = UIColor.yellow.withAlphaComponent(0.8)
                
                let lineNode = SCNNode(geometry: cylinder)
                lineNode.name = name
                
                // Position and orient
                let midpoint = (start + end) / 2
                lineNode.simdPosition = midpoint
                
                // Orient cylinder along edge
                let direction = simd_normalize(vector)
                let defaultUp = simd_float3(0, 1, 0)
                
                let angle = acos(simd_dot(defaultUp, direction))
                let axis = simd_cross(defaultUp, direction)
                
                if simd_length(axis) > 0.001 {
                    lineNode.simdOrientation = simd_quatf(angle: angle, axis: simd_normalize(axis))
                }
                
                sceneView.scene.rootNode.addChildNode(lineNode)
            }
            
            print("📐 Drew triangle lines connecting 3 vertices")
        }
        
        /// Check for camera collisions with survey marker spheres
        private func checkSurveyMarkerCollisions() {
            guard !surveyMarkers.isEmpty else { return }
            
            // Get current camera position
            guard let cameraPosition = getCurrentCameraPosition() else { return }
            
            let currentTime = CACurrentMediaTime()
            
            // Check distance to each survey marker
            for (markerID, markerNode) in surveyMarkers {
                let markerPosition = markerNode.simdPosition
                let distance = simd_distance(cameraPosition, markerPosition)
                
                // Check if camera is inside sphere volume
                if distance < collisionRadius {
                    // Check cooldown
                    let lastTrigger = lastHapticTriggerTime[markerID] ?? 0
                    let timeSinceLastTrigger = currentTime - lastTrigger
                    
                    if timeSinceLastTrigger >= hapticCooldown {
                        // Trigger haptic feedback
                        triggerCollisionHaptic()
                        lastHapticTriggerTime[markerID] = currentTime
                        
                        print("💥 Camera collision with survey marker \(String(markerID.uuidString.prefix(8))) at distance \(String(format: "%.3f", distance))m")
                    }
                }
            }
        }
        
        /// Trigger haptic feedback for survey marker collision
        private func triggerCollisionHaptic() {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
        }
        
        /// Draw lines connecting triangle vertices on the ground
        func drawTriangleLines(vertices: [simd_float3]) {
            guard vertices.count == 3 else { return }
            
            // Remove any existing triangle lines
            sceneView?.scene.rootNode.enumerateChildNodes { node, _ in
                if node.name?.hasPrefix("triangleLine_") == true {
                    node.removeFromParentNode()
                }
            }
            
            // Create lines for each edge
            let edges = [
                (vertices[0], vertices[1], "triangleLine_01"),
                (vertices[1], vertices[2], "triangleLine_12"),
                (vertices[2], vertices[0], "triangleLine_20")
            ]
            
            for (start, end, name) in edges {
                // Create cylinder to represent line
                let vector = end - start
                let distance = simd_length(vector)
                
                let cylinder = SCNCylinder(radius: 0.005, height: CGFloat(distance))
                cylinder.firstMaterial?.diffuse.contents = UIColor.yellow.withAlphaComponent(0.7)
                
                let lineNode = SCNNode(geometry: cylinder)
                lineNode.name = name
                
                // Position at midpoint
                let midpoint = (start + end) / 2
                lineNode.simdPosition = midpoint
                
                // Orient cylinder along the edge (cylinder default axis is Y, we want it along the edge)
                let direction = simd_normalize(vector)
                let up = simd_float3(0, 1, 0) // Default cylinder axis
                
                // Calculate rotation to align Y-axis with edge direction
                let rotation = rotationBetweenVectors(from: up, to: direction)
                lineNode.simdOrientation = rotation
                
                // Lower the line slightly below ground level for visibility
                lineNode.simdPosition.y = midpoint.y - 0.01
                
                sceneView?.scene.rootNode.addChildNode(lineNode)
            }
            
            print("📐 Drew triangle lines connecting vertices")
        }
        
        /// Helper: Calculate rotation between two vectors
        private func rotationBetweenVectors(from: simd_float3, to: simd_float3) -> simd_quatf {
            let normalizedFrom = simd_normalize(from)
            let normalizedTo = simd_normalize(to)
            
            let dot = simd_dot(normalizedFrom, normalizedTo)
            let clampedDot = max(-1.0, min(1.0, dot)) // Clamp to avoid NaN from acos
            
            // If vectors are parallel or anti-parallel
            if abs(clampedDot - 1.0) < 0.001 {
                return simd_quatf(angle: 0, axis: simd_float3(0, 1, 0))
            }
            
            let axis = simd_cross(normalizedFrom, normalizedTo)
            let axisLength = simd_length(axis)
            
            if axisLength < 0.001 {
                // Vectors are parallel
                return simd_quatf(angle: 0, axis: simd_float3(0, 1, 0))
            }
            
            let angle = acos(clampedDot)
            return simd_quatf(angle: angle, axis: simd_normalize(axis))
        }
        
        /// Get pixels per meter from MetricSquareStore (same logic as ARCalibrationCoordinator)
        private func getPixelsPerMeter() -> Float? {
            guard let squareStore = metricSquareStore else { return nil }
            
            // Use first locked square, or any square if none are locked
            let lockedSquares = squareStore.squares.filter { $0.isLocked }
            let squaresToUse = lockedSquares.isEmpty ? squareStore.squares : lockedSquares
            
            guard let square = squaresToUse.first, square.meters > 0 else { return nil }
            
            // pixels per meter = side_pixels / side_meters
            let pixelsPerMeter = Float(square.side) / Float(square.meters)
            if pixelsPerMeter > 0 {
                print("📏 Map scale set: \(pixelsPerMeter) pixels per meter (1 meter = \(pixelsPerMeter) pixels)")
            }
            return pixelsPerMeter > 0 ? pixelsPerMeter : nil
        }

        deinit {
            clearSurveyMarkers()
            lastHapticTriggerTime.removeAll()
            crosshairUpdateTimer?.invalidate()
            NotificationCenter.default.removeObserver(self)
        }
    }
}

// MARK: - ARSCNViewDelegate for Plane Visualization
extension ARViewContainer.ARViewCoordinator: ARSCNViewDelegate {
    // MARK: - Plane Visualization
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard showPlaneVisualization else { return }
        
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        let plane = SCNPlane(
            width: CGFloat(planeAnchor.planeExtent.width),
            height: CGFloat(planeAnchor.planeExtent.height)
        )
        
        let material = SCNMaterial()
        // Purple for horizontal, Green for vertical
        if planeAnchor.alignment == .horizontal {
            material.diffuse.contents = UIColor.purple.withAlphaComponent(0.3)
        } else {
            material.diffuse.contents = UIColor.green.withAlphaComponent(0.3)
        }
        material.isDoubleSided = true
        plane.materials = [material]
        
        let planeNode = SCNNode(geometry: plane)
        
        // Position and rotate based on plane alignment
        if planeAnchor.alignment == .horizontal {
            // Horizontal planes: position at ground level (y=0), rotate to lie flat
            planeNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
            planeNode.eulerAngles.x = -.pi / 2
        } else {
            // Vertical planes: use actual center position, no rotation needed
            planeNode.position = SCNVector3(planeAnchor.center.x, planeAnchor.center.y, planeAnchor.center.z)
            planeNode.eulerAngles.x = -.pi / 2
        }
        
        planeNode.name = "planeVisualization"  // Tag for easy removal
        
        node.addChildNode(planeNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard showPlaneVisualization else {
            // Remove plane visualization if toggle is off
            node.childNodes.first(where: { $0.name == "planeVisualization" })?.removeFromParentNode()
            return
        }
        
        guard let planeAnchor = anchor as? ARPlaneAnchor,
              let planeNode = node.childNodes.first(where: { $0.name == "planeVisualization" }),
              let plane = planeNode.geometry as? SCNPlane else { return }
        
        plane.width = CGFloat(planeAnchor.planeExtent.width)
        plane.height = CGFloat(planeAnchor.planeExtent.height)
        
        // Update position based on plane alignment
        if planeAnchor.alignment == .horizontal {
            planeNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
        } else {
            planeNode.position = SCNVector3(planeAnchor.center.x, planeAnchor.center.y, planeAnchor.center.z)
        }
    }
}
