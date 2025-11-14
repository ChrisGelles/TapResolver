import SwiftUI
import ARKit
import SceneKit
import simd

struct ARViewContainer: UIViewRepresentable {
    @Binding var mode: ARMode

    func makeCoordinator() -> ARViewCoordinator {
        ARViewCoordinator()
    }

    func makeUIView(context: Context) -> ARSCNView {
        let sceneView = ARSCNView(frame: .zero)
        sceneView.scene = SCNScene()

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        sceneView.session.run(config)

        context.coordinator.sceneView = sceneView
        context.coordinator.setMode(mode)
        context.coordinator.setupTapGesture()

        return sceneView
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {
        context.coordinator.setMode(mode)
    }

    class ARViewCoordinator: NSObject {
        var sceneView: ARSCNView?
        var currentMode: ARMode = .idle
        var placedMarkers: [UUID: SCNNode] = [:] // Track placed markers by ID
        
        // Default user height (will be configurable later)
        var userHeight: Float = 1.7

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
            switch currentMode {
            case .calibration:
                markerColor = UIColor.ARPalette.calibration
            case .anchor:
                markerColor = UIColor.ARPalette.anchor
            default:
                markerColor = UIColor.ARPalette.markerBase
            }
            
            // Create marker with standardized options
            let options = MarkerOptions(
                color: markerColor,
                markerID: markerID,
                userHeight: userHeight
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

        func teardownSession() {
            sceneView?.session.pause()
            print("🔧 AR session paused and torn down.")
        }

        deinit {
            teardownSession()
        }
    }
}
