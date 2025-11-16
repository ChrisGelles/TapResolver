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

    func makeCoordinator() -> ARViewCoordinator {
        let coordinator = ARViewCoordinator()
        coordinator.selectedTriangle = selectedTriangle
        coordinator.isCalibrationMode = isCalibrationMode
        coordinator.showPlaneVisualization = showPlaneVisualization
        coordinator.metricSquareStore = metricSquareStore
        return coordinator
    }

    func makeUIView(context: Context) -> ARSCNView {
        let sceneView = ARSCNView(frame: .zero)
        sceneView.scene = SCNScene()

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]  // Enable both horizontal and vertical plane detection
        sceneView.session.run(config)
        
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
        context.coordinator.selectedTriangle = selectedTriangle
        context.coordinator.isCalibrationMode = isCalibrationMode
        context.coordinator.showPlaneVisualization = showPlaneVisualization
        
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
        private var crosshairNode: GroundCrosshairNode?
        var currentCursorPosition: simd_float3?
        
        // Calibration mode state
        var isCalibrationMode: Bool = false
        var selectedTriangle: TrianglePatch? = nil
        
        // Plane visualization toggle
        var showPlaneVisualization: Bool = true  // Default to enabled
        
        // User device height (centralized constant)
        var userDeviceHeight: Float = ARVisualDefaults.userDeviceHeight
        
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
        }
        
        @objc func handlePlaceMarkerAtCursor() {
            guard let position = currentCursorPosition else {
                print("⚠️ No cursor position available for marker placement")
                return
            }
            placeMarker(at: position)
        }

        @objc func handleTapGesture(_ sender: UITapGestureRecognizer) {
            // Disable tap-to-place in idle mode - use Place AR Marker button instead
            guard currentMode != .idle else {
                print("👆 Tap ignored in idle mode — use Place AR Marker button")
                return
            }
            
            // Disable tap-to-place in triangle calibration mode - use Place Marker button instead
            if case .triangleCalibration = currentMode {
                print("👆 Tap ignored in triangle calibration mode — use Place Marker button")
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

        func placeMarker(at position: simd_float3) {
            guard let sceneView = sceneView else { return }
            
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
            
            print("📍 Placed marker \(String(markerID.uuidString.prefix(8))) at \(position)")
            
            // Post notification for marker placement
            NotificationCenter.default.post(
                name: NSNotification.Name("ARMarkerPlaced"),
                object: nil,
                userInfo: [
                    "markerID": markerID,
                    "position": [position.x, position.y, position.z] // Convert simd_float3 to array
                ]
            )
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
        
        /// Estimate world position for a map point using calibrated triangle transform or heuristic
        func estimateWorldPosition(for mapPoint: CGPoint, using triangle: TrianglePatch?) -> simd_float3? {
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
                // Assume ground plane (y = 0) for now
                return simd_float3(transformed.x, 0.0, transformed.y)
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
            return simd_float3(estimatedPosition.x, 0.0, estimatedPosition.z)
        }
        
        /// Add a ghost marker for a map point
        func addGhostMarker(mapPointID: UUID, mapPoint: CGPoint, using triangle: TrianglePatch?) {
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
        }
        
        func teardownSession() {
            crosshairUpdateTimer?.invalidate()
            crosshairUpdateTimer = nil
            NotificationCenter.default.removeObserver(self)
            clearSurveyMarkers()
            sceneView?.session.pause()
            print("🔧 AR session paused and torn down.")
        }
        
        // MARK: - Survey Marker Generation
        
        /// Generate temporary survey markers across calibrated triangle
        func generateSurveyMarkers(
            calibrationCoordinator: ARCalibrationCoordinator,
            mapPointStore: MapPointStore,
            arWorldMapStore: ARWorldMapStore,
            spacingMeters: Float = 1.0
        ) {
            // Clear existing survey markers
            clearSurveyMarkers()
            
            // Get current triangle from calibration coordinator
            guard let currentTriangleID = calibrationCoordinator.activeTriangleID,
                  let currentTriangle = calibrationCoordinator.triangleStore.triangle(withID: currentTriangleID),
                  calibrationCoordinator.isTriangleComplete(currentTriangleID) else {
                print("⚠️ Cannot generate survey markers: no calibrated triangle")
                return
            }
            
            // Get triangle vertices from map point store
            guard let pointA = mapPointStore.points.first(where: { $0.id == currentTriangle.vertexIDs[0] }),
                  let pointB = mapPointStore.points.first(where: { $0.id == currentTriangle.vertexIDs[1] }),
                  let pointC = mapPointStore.points.first(where: { $0.id == currentTriangle.vertexIDs[2] }) else {
                print("⚠️ Cannot find triangle vertices in map point store")
                return
            }
            
            // Get AR marker positions from ARWorldMapStore
            guard let markerA = arWorldMapStore.markers.first(where: { $0.mapPointID == currentTriangle.vertexIDs[0].uuidString }),
                  let markerB = arWorldMapStore.markers.first(where: { $0.mapPointID == currentTriangle.vertexIDs[1].uuidString }),
                  let markerC = arWorldMapStore.markers.first(where: { $0.mapPointID == currentTriangle.vertexIDs[2].uuidString }) else {
                print("⚠️ AR markers not found for triangle vertices")
                return
            }
            
            // Extract positions from transforms
            let transformA = markerA.worldTransform.toSimd()
            let transformB = markerB.worldTransform.toSimd()
            let transformC = markerC.worldTransform.toSimd()
            
            let triangle2D = [
                pointA.mapPoint,
                pointB.mapPoint,
                pointC.mapPoint
            ]
            
            let triangle3D = [
                simd_float3(transformA.columns.3.x, transformA.columns.3.y, transformA.columns.3.z),
                simd_float3(transformB.columns.3.x, transformB.columns.3.y, transformB.columns.3.z),
                simd_float3(transformC.columns.3.x, transformC.columns.3.y, transformC.columns.3.z)
            ]
            
            // Get REAL map scale from MetricSquareStore
            guard let pxPerMeter = getPixelsPerMeter() else {
                print("⚠️ Cannot generate survey markers: no metric square calibrated")
                print("   Please create and lock a metric square first")
                return
            }
            
            print("📐 Using map scale: \(pxPerMeter) pixels per meter")
            
            // Generate 2D fill points
            let fillPoints = generateTriangleFillPoints(
                triangle: triangle2D,
                spacingMeters: spacingMeters,
                pxPerMeter: pxPerMeter
            )
            
            print("📍 Generating \(fillPoints.count) survey markers with \(spacingMeters)m spacing")
            
            // Interpolate to 3D and create AR markers
            for mapPoint in fillPoints {
                guard let arPosition = interpolateARPosition(
                    fromMapPoint: mapPoint,
                    triangle2D: triangle2D,
                    triangle3D: triangle3D
                ) else {
                    continue
                }
                
                // Create survey marker (red sphere)
                let markerID = UUID()
                let markerNode = createSurveyMarkerNode(at: arPosition)
                markerNode.name = "surveyMarker_\(markerID.uuidString)"
                
                sceneView?.scene.rootNode.addChildNode(markerNode)
                surveyMarkers[markerID] = markerNode
            }
            
            print("✅ Placed \(surveyMarkers.count) survey markers")
        }
        
        /// Create visual node for survey marker (red sphere)
        private func createSurveyMarkerNode(at position: simd_float3) -> SCNNode {
            // Small red sphere
            let sphere = SCNSphere(radius: 0.05)  // 5cm radius
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.red.withAlphaComponent(0.8)
            sphere.materials = [material]
            
            let node = SCNNode(geometry: sphere)
            node.position = SCNVector3(position.x, position.y, position.z)
            
            return node
        }
        
        /// Clear all survey markers from scene
        func clearSurveyMarkers() {
            for (_, node) in surveyMarkers {
                node.removeFromParentNode()
            }
            surveyMarkers.removeAll()
            print("🧹 Cleared survey markers")
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
            return pixelsPerMeter > 0 ? pixelsPerMeter : nil
        }

        deinit {
            teardownSession()
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
            planeNode.eulerAngles.x = 0
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
