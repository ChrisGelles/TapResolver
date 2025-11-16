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
        coordinator.isCalibrationMode = isCalibrationMode
        coordinator.showPlaneVisualization = showPlaneVisualization
        coordinator.metricSquareStore = metricSquareStore
        coordinator.mapPointStore = mapPointStore
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
        }
        
        @objc func handlePlaceMarkerAtCursor() {
            guard let position = currentCursorPosition else {
                print("⚠️ No cursor position available for marker placement")
                return
            }
            placeMarker(at: position)
        }
        
        @objc func handleFillTriangleWithSurveyMarkers(notification: Notification) {
            guard let triangleID = notification.userInfo?["triangleID"] as? UUID,
                  let spacing = notification.userInfo?["spacing"] as? Float,
                  let triangle = selectedTriangle,
                  triangle.id == triangleID else {
                print("⚠️ Invalid triangle or spacing for survey marker generation")
                return
            }
            
            generateSurveyMarkers(for: triangle, spacing: spacing)
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
            sceneView?.session.pause()
            print("🔧 AR session paused and torn down.")
        }
        
        // MARK: - Survey Marker Generation
        
        /// Generate survey markers inside a calibrated triangle
        private func generateSurveyMarkers(for triangle: TrianglePatch, spacing: Float) {
            // Clear existing survey markers
            clearSurveyMarkers()
            
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
            
            // Get 2D map coordinates
            let triangle2D = vertexPoints.map { $0.mapPoint }
            
            print("📍 Plotting points within triangle A(\(String(format: "%.1f", triangle2D[0].x)), \(String(format: "%.1f", triangle2D[0].y))) B(\(String(format: "%.1f", triangle2D[1].x)), \(String(format: "%.1f", triangle2D[1].y))) C(\(String(format: "%.1f", triangle2D[2].x)), \(String(format: "%.1f", triangle2D[2].y)))")
            
            // Get 3D AR positions from placed markers using index matching
            // triangle.arMarkerIDs[i] corresponds to triangle.vertexIDs[i]
            var triangle3D: [simd_float3] = []
            
            guard triangle.arMarkerIDs.count == 3 else {
                print("⚠️ Triangle does not have 3 AR markers (has \(triangle.arMarkerIDs.count))")
                return
            }
            
            for (index, markerIDString) in triangle.arMarkerIDs.enumerated() {
                guard let markerUUID = UUID(uuidString: markerIDString) else {
                    print("⚠️ Invalid marker ID string: \(markerIDString)")
                    continue
                }
                
                // Look up marker node in placedMarkers dictionary
                if let markerNode = placedMarkers[markerUUID] {
                    triangle3D.append(markerNode.simdPosition)
                    let vertexID = triangle.vertexIDs[index]
                    print("✅ Found AR marker \(String(markerUUID.uuidString.prefix(8))) for vertex \(String(vertexID.uuidString.prefix(8))) at \(markerNode.simdPosition)")
                } else {
                    let vertexID = triangle.vertexIDs[index]
                    print("⚠️ Marker \(String(markerUUID.uuidString.prefix(8))) not found in placedMarkers dictionary for vertex \(String(vertexID.uuidString.prefix(8)))")
                    print("📋 Available markers: \(placedMarkers.keys.map { String($0.uuidString.prefix(8)) })")
                }
            }
            
            guard triangle3D.count == 3 else {
                print("⚠️ Could not retrieve 3 AR positions for triangle vertices (got \(triangle3D.count)/3)")
                return
            }
            
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
                
                // Create survey marker using existing renderer
                let markerID = UUID()
                let options = MarkerOptions(
                    color: UIColor.red,  // RED sphere for survey markers
                    markerID: markerID,
                    userDeviceHeight: userDeviceHeight,
                    animateOnAppearance: false  // No animation for survey markers
                )
                
                let markerNode = ARMarkerRenderer.createNode(at: position3D, options: options)
                markerNode.name = "surveyMarker_\(markerID.uuidString)"
                
                // Add to scene
                sceneView?.scene.rootNode.addChildNode(markerNode)
                
                // Track marker
                surveyMarkers[markerID] = markerNode
                
                print("📍 Placed survey marker at map(\(roundedX), \(roundedY)) → AR\(position3D)")
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
        
        /// Generate temporary survey markers across calibrated triangle (legacy - kept for compatibility)
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
            lastHapticTriggerTime.removeAll()  // Clear collision tracking state
            print("🧹 Cleared survey markers")
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
