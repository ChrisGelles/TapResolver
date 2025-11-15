import SwiftUI
import ARKit
import SceneKit
import simd

struct ARViewContainer: UIViewRepresentable {
    @Binding var mode: ARMode
    
    // Calibration mode properties
    var isCalibrationMode: Bool = false
    var selectedTriangle: TrianglePatch? = nil
    var onDismiss: (() -> Void)? = nil

    func makeCoordinator() -> ARViewCoordinator {
        let coordinator = ARViewCoordinator()
        coordinator.selectedTriangle = selectedTriangle
        coordinator.isCalibrationMode = isCalibrationMode
        return coordinator
    }

    func makeUIView(context: Context) -> ARSCNView {
        let sceneView = ARSCNView(frame: .zero)
        sceneView.scene = SCNScene()

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        sceneView.session.run(config)
        
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
        
        // Store coordinator reference for world map access
        ARViewContainer.Coordinator.current = context.coordinator
    }

    class ARViewCoordinator: NSObject {
        static var current: ARViewCoordinator?
        
        var sceneView: ARSCNView?
        var currentMode: ARMode = .idle
        var placedMarkers: [UUID: SCNNode] = [:] // Track placed markers by ID
        private var crosshairNode: GroundCrosshairNode?
        var currentCursorPosition: simd_float3?
        
        // Calibration mode state
        var isCalibrationMode: Bool = false
        var selectedTriangle: TrianglePatch? = nil
        
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
        
        func teardownSession() {
            crosshairUpdateTimer?.invalidate()
            crosshairUpdateTimer = nil
            NotificationCenter.default.removeObserver(self)
            sceneView?.session.pause()
            print("🔧 AR session paused and torn down.")
        }

        deinit {
            teardownSession()
        }
    }
}
