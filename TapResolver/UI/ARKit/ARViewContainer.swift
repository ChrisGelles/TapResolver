//
//  ARViewContainer.swift
//  TapResolver
//
//  Created by Chris Gelles on 10/20/25.
//


//
//  ARViewContainer.swift
//  TapResolver
//
//  Role: UIKit ARSCNView wrapper for SwiftUI
//

import SwiftUI
import ARKit
import SceneKit

// MARK: - AR Marker Data

struct ARMarkerData {
    let position: simd_float3
    let userHeight: Float
}

// MARK: - Square Placement State

enum SquarePlacementState {
    case idle
    case corner1Placed(position: simd_float3)
    case corner2Placed(corner1: simd_float3, corner2: simd_float3)
    case completed
}

struct ARViewContainer: UIViewRepresentable {
    
    let mapPointID: UUID
    let userHeight: Float  // From MapPoint's latest session
    @Binding var markerPlaced: Bool
    
    // Metric Square mode (optional)
    let metricSquareID: UUID?
    let squareColor: UIColor?
    let squareSideMeters: Double?
    
    let worldMapStore: ARWorldMapStore
    @Binding var relocalizationStatus: String
    let mapPointStore: MapPointStore
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView()
        
        // Set the delegate
        arView.delegate = context.coordinator
        arView.session.delegate = context.coordinator
        
        // Create and set an empty scene
        arView.scene = SCNScene()
        
        // Configure AR session
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        
        // Enable LiDAR if available
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
        }
        
        // Load saved world map if it exists
        if let worldMap = worldMapStore.loadWorldMap() {
            configuration.initialWorldMap = worldMap
            context.coordinator.isRelocalizing = true
            context.coordinator.relocalizationStartTime = Date()
            print("🗺️ Loading saved AR World Map for marker placement")
        } else {
            print("⚠️ No saved AR World Map - starting fresh tracking")
            context.coordinator.isRelocalized = true  // No relocalization needed
        }
        
        // Run the session with proper initialization
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        // Show feature points for debugging
        arView.debugOptions = [.showFeaturePoints]
        
        // Add crosshair reticle
        let crosshair = context.coordinator.createCrosshair()
        arView.scene.rootNode.addChildNode(crosshair)
        context.coordinator.crosshairNode = crosshair
        
        // Add tap gesture for placing markers
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        context.coordinator.arView = arView
        context.coordinator.userHeight = userHeight
        context.coordinator.markerPlaced = markerPlaced
        context.coordinator.metricSquareID = metricSquareID
        context.coordinator.squareColor = squareColor
        context.coordinator.squareSideMeters = squareSideMeters
        context.coordinator.mapPointStore = mapPointStore
        context.coordinator.mapPointID = mapPointID
        
        print("📷 AR Camera session started")
        
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        // No updates needed for now
    }
    
    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator()
        coordinator.relocalizationStatus = $relocalizationStatus
        return coordinator
    }
    
    class Coordinator: NSObject, ARSCNViewDelegate, ARSessionDelegate {
        
        weak var arView: ARSCNView?
        var crosshairNode: SCNNode?
        var userHeight: Float = 1.05
        var markerPlaced: Bool = false
        var markerNode: SCNNode?
        
        private var detectedPlanes: [UUID: SCNNode] = [:]
        
        // Metric Square placement
        var metricSquareID: UUID?
        var squareColor: UIColor?
        var squareSideMeters: Double?
        var squarePlacementState: SquarePlacementState = .idle
        var squareNodes: [SCNNode] = []
        
        // Relocalization tracking
        var isRelocalizing: Bool = false
        var relocalizationStatus: Binding<String>?
        private var lastTrackingState: ARCamera.TrackingState?
        var isRelocalized: Bool = false
        var relocalizationStartTime: Date?
        
        // MapPointStore reference
        var mapPointStore: MapPointStore?
        var mapPointID: UUID = UUID()
        
        // MARK: - Crosshair Creation
        
        func createCrosshair() -> SCNNode {
            let crosshairNode = SCNNode()
            
            // Create circle
            let circle = SCNTorus(ringRadius: 0.1, pipeRadius: 0.002)
            let circleMaterial = SCNMaterial()
            circleMaterial.diffuse.contents = UIColor.white.withAlphaComponent(0.8)
            circle.materials = [circleMaterial]
            
            let circleNode = SCNNode(geometry: circle)
            //circleNode.eulerAngles.x = .pi / 2
            crosshairNode.addChildNode(circleNode)
            
            // Outer confidence ring (hidden by default, shown when surface is stable)
            let outerCircle = SCNTorus(ringRadius: 0.18, pipeRadius: 0.002) // 15cm radius (30cm diameter)
            let outerMaterial = SCNMaterial()
            outerMaterial.diffuse.contents = UIColor.white.withAlphaComponent(0.5)
            outerCircle.materials = [outerMaterial]
            
            let outerCircleNode = SCNNode(geometry: outerCircle)
            //outerCircleNode.eulerAngles.x = .pi / 2
            outerCircleNode.isHidden = true
            outerCircleNode.name = "outerConfidenceRing"
            crosshairNode.addChildNode(outerCircleNode)
            
            // Create crosshair lines
            let lineLength: CGFloat = 0.1
            let lineThickness: CGFloat = 0.001
            
            // Horizontal line
            let hLine = SCNBox(width: lineLength, height: lineThickness, length: lineThickness, chamferRadius: 0)
            hLine.materials = [circleMaterial]
            let hLineNode = SCNNode(geometry: hLine)
            crosshairNode.addChildNode(hLineNode)
            
            // Perpendicular horizontal line (rotated 90° on Y-axis)
            let hLine2Node = SCNNode(geometry: hLine)
            hLine2Node.eulerAngles.y = .pi / 2
            crosshairNode.addChildNode(hLine2Node)
            
            // Vertical line
            let vLine = SCNBox(width: lineThickness, height: lineLength, length: lineThickness, chamferRadius: 0)
            vLine.materials = [circleMaterial]
            let vLineNode = SCNNode(geometry: vLine)
            crosshairNode.addChildNode(vLineNode)
            
            crosshairNode.isHidden = true
            return crosshairNode
        }
        
        // MARK: - Raycast Update
        
        func updateCrosshair() {
            guard let arView = arView,
                  let crosshair = crosshairNode else { return }
            
            let screenCenter = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)
            
            guard let query = arView.raycastQuery(from: screenCenter, allowing: .estimatedPlane, alignment: .horizontal) else {
                crosshair.isHidden = true
                return
            }
            
            let results = arView.session.raycast(query)
            
            if let result = results.first {
                // Only update position, force horizontal orientation
                crosshair.simdPosition = simd_make_float3(result.worldTransform.columns.3)
                //crosshair.simdWorldOrientation = simd_quatf(angle: 0, axis: simd_float3(0, 1, 0))
                crosshair.isHidden = false
                
                // Check surface confidence
                updateSurfaceConfidence(for: result, crosshair: crosshair)
                
                // Check for corner snapping
                if let snappedPosition = findNearbyCorner(from: result.worldTransform.columns.3) {
                    crosshair.simdPosition = snappedPosition
                    // Change color to indicate snap
                    if let circle = crosshair.childNodes.first?.geometry as? SCNTorus {
                        circle.materials.first?.diffuse.contents = UIColor.green.withAlphaComponent(0.9)
                    }
                } else {
                    // Normal white color
                    if let circle = crosshair.childNodes.first?.geometry as? SCNTorus {
                        circle.materials.first?.diffuse.contents = UIColor.white.withAlphaComponent(0.8)
                    }
                }
            } else {
                crosshair.isHidden = true
            }
        }
        
        private func updateSurfaceConfidence(for result: ARRaycastResult, crosshair: SCNNode) {
            guard let arView = arView,
                  let outerRing = crosshair.childNode(withName: "outerConfidenceRing", recursively: false) else { return }
            
            // Get the plane anchor if available
            if let planeAnchor = result.anchor as? ARPlaneAnchor,
               planeAnchor.alignment == .horizontal {
                let planeExtent = planeAnchor.planeExtent
                let planeArea = planeExtent.width * planeExtent.height
                
                // Consider plane "confident" if it's larger than 0.5 square meters
                let isConfident = planeArea > 0.5
                
                outerRing.isHidden = !isConfident
                
                // Optionally pulse the outer ring when confident
                if isConfident && outerRing.opacity == 1.0 {
                    let pulse = SCNAction.sequence([
                        SCNAction.fadeOpacity(to: 0.3, duration: 0.8),
                        SCNAction.fadeOpacity(to: 1.0, duration: 0.8)
                    ])
                    outerRing.runAction(SCNAction.repeatForever(pulse))
                }
            } else {
                outerRing.isHidden = true
            }
        }
        
        // MARK: - Corner Detection
        
        private func findNearbyCorner(from position: simd_float4) -> simd_float3? {
            let testPosition = simd_float3(position.x, position.y, position.z)
            let snapDistance: Float = 0.08 // 4cm
            let angleThreshold: Float = 25.0 * .pi / 180.0 // 25 degrees in radians
            
            // Check all plane combinations for corners
            let planeArray = Array(detectedPlanes.values)
            
            for i in 0..<planeArray.count {
                for j in (i+1)..<planeArray.count {
                    if let corner = findCornerBetweenPlanes(planeArray[i], planeArray[j], angleThreshold: angleThreshold) {
                        let distance = simd_distance(testPosition, corner)
                        if distance < snapDistance {
                            return corner
                        }
                    }
                }
            }
            
            return nil
        }
        
        private func findCornerBetweenPlanes(_ plane1: SCNNode, _ plane2: SCNNode, angleThreshold: Float) -> simd_float3? {
            // Get plane normals
            let normal1 = plane1.simdWorldTransform.columns.1
            let normal2 = plane2.simdWorldTransform.columns.1
            
            // Calculate angle between planes
            let dotProduct = simd_dot(simd_normalize(simd_float3(normal1.x, normal1.y, normal1.z)),
                                       simd_normalize(simd_float3(normal2.x, normal2.y, normal2.z)))
            let angle = acos(dotProduct)
            
            // Check if planes are roughly perpendicular
            if abs(angle - .pi / 2) < angleThreshold {
                
                // Find intersection point (simplified - use plane centers for now)
                let pos1 = simd_float3(plane1.simdWorldPosition)
                let pos2 = simd_float3(plane2.simdWorldPosition)
                return (pos1 + pos2) / 2
            }
            
            return nil
        }
        
        // MARK: - Marker Placement
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let crosshair = crosshairNode,
                  !crosshair.isHidden else { return }
            
            // Block placement until relocalized
            guard isRelocalized else {
                print("⚠️ Cannot place marker - waiting for relocalization")
                return
            }
            
            let position = crosshair.simdPosition
            
            // Metric Square mode
            if metricSquareID != nil {
                handleSquarePlacement(at: position)
                return
            }
            
            // MapPoint marker mode
            guard !markerPlaced else { return }
            placeMarker(at: position)
            markerPlaced = true
        }
        
        private func placeMarker(at position: simd_float3) {
            guard let arView = arView else { return }
            
            let markerNode = SCNNode()
            markerNode.simdPosition = position
            // Force world-aligned orientation (identity rotation) so floor circle lays flat
            //markerNode.simdWorldOrientation = simd_quatf(angle: 0, axis: simd_float3(0, 1, 0))
            
            // Floor circle (10cm diameter)
            let circleRadius: CGFloat = 0.1 // 5cm radius = 10cm diameter
            let circle = SCNTorus(ringRadius: circleRadius, pipeRadius: 0.002)
            
            let circleMaterial = SCNMaterial()
            circleMaterial.diffuse.contents = UIColor(red: 71/255, green: 199/255, blue: 239/255, alpha: 0.7)
            circle.materials = [circleMaterial]
            
            let circleNode = SCNNode(geometry: circle)
            circleNode.eulerAngles = SCNVector3Zero
//            circleNode.eulerAngles.x = .pi
            markerNode.addChildNode(circleNode)
            
            // Circle fill
            let circleFill = SCNCylinder(radius: circleRadius, height: 0.001)
            let fillMaterial = SCNMaterial()
            fillMaterial.diffuse.contents = UIColor.white.withAlphaComponent(0.15)
            circleFill.materials = [fillMaterial]
            
            let fillNode = SCNNode(geometry: circleFill)
            fillNode.eulerAngles.x = .pi
            markerNode.addChildNode(fillNode)
            
            // Vertical line (to user height)
            let lineHeight = CGFloat(userHeight)
            let line = SCNCylinder(radius: 0.00125, height: lineHeight) // 0.25cm = 2.5mm
            let lineMaterial = SCNMaterial()
            lineMaterial.diffuse.contents = UIColor(red: 0/255, green: 50/255, blue: 98/255, alpha: 0.95)
            line.materials = [lineMaterial]
            
            let lineNode = SCNNode(geometry: line)
            lineNode.position = SCNVector3(0, Float(lineHeight / 2), 0)
            markerNode.addChildNode(lineNode)
            
            // Sphere at top (3cm diameter)
            let sphere = SCNSphere(radius: 0.015) // 1.5cm radius = 3cm diameter
            let sphereMaterial = SCNMaterial()
            sphereMaterial.diffuse.contents = UIColor(red: 0/255, green: 125/255, blue: 184/255, alpha: 0.98)
            sphereMaterial.specular.contents = UIColor.white
            sphereMaterial.shininess = 0.8
            sphere.materials = [sphereMaterial]
            
            let sphereNode = SCNNode(geometry: sphere)
            sphereNode.position = SCNVector3(0, Float(lineHeight), 0)
            markerNode.addChildNode(sphereNode)
            
            arView.scene.rootNode.addChildNode(markerNode)
            self.markerNode = markerNode
            
            // Hide crosshair after placement
            crosshairNode?.isHidden = true
            
            print("✅ Marker placed at height: \(userHeight)m")
            
            // Save AR Marker
            if let mapPointStore = mapPointStore,
               let mapPoint = mapPointStore.points.first(where: { $0.id == mapPointID }) {
                mapPointStore.createARMarker(
                    linkedMapPointID: mapPointID,
                    arPosition: position,
                    mapCoordinates: mapPoint.mapPoint
                )
            }
        }
        
        // MARK: - Metric Square Placement
        
        private func handleSquarePlacement(at position: simd_float3) {
            switch squarePlacementState {
            case .idle:
                placeCorner1(at: position)
            case .corner1Placed(let corner1):
                placeCorner2(at: position, corner1: corner1)
            case .corner2Placed(let corner1, let corner2):
                completeSquare(corner1: corner1, corner2: corner2, directionPoint: position)
            case .completed:
                break // Already completed
            }
        }
        
        private func placeCorner1(at position: simd_float3) {
            let cornerNode = createCornerMarker(at: position)
            squareNodes.append(cornerNode)
            arView?.scene.rootNode.addChildNode(cornerNode)
            
            squarePlacementState = .corner1Placed(position: position)
            print("📍 Corner 1 placed at: \(position)")
        }
        
        private func placeCorner2(at position: simd_float3, corner1: simd_float3) {
            let cornerNode = createCornerMarker(at: position)
            squareNodes.append(cornerNode)
            arView?.scene.rootNode.addChildNode(cornerNode)
            
            // Create line between corners
            let lineNode = createLine(from: corner1, to: position)
            squareNodes.append(lineNode)
            arView?.scene.rootNode.addChildNode(lineNode)
            
            squarePlacementState = .corner2Placed(corner1: corner1, corner2: position)
            
            let distance = simd_distance(corner1, position)
            print("📍 Corner 2 placed at: \(position)")
            print("📏 Edge length: \(String(format: "%.3f", distance))m")
        }
        
        private func completeSquare(corner1: simd_float3, corner2: simd_float3, directionPoint: simd_float3) {
            // Calculate edge vector
            let edge = corner2 - corner1
            let edgeLength = simd_length(edge)
            let edgeDir = simd_normalize(edge)
            
            // Calculate perpendicular direction
            let up = simd_float3(0, 1, 0)
            let perpDir = simd_normalize(simd_cross(edgeDir, up))
            
            // Determine which side of the edge the direction point is on
            let toPoint = directionPoint - corner1
            let side = simd_dot(toPoint, perpDir)
            let squareDir = side > 0 ? perpDir : -perpDir
            
            // Calculate other two corners
            let corner3 = corner2 + squareDir * edgeLength
            let corner4 = corner1 + squareDir * edgeLength
            
            // Create square outline
            createSquareOutline(corner1: corner1, corner2: corner2, corner3: corner3, corner4: corner4)
            
            squarePlacementState = .completed
            crosshairNode?.isHidden = true
            
            print("✅ Metric Square completed")
            print("   Edge length (AR): \(String(format: "%.3f", edgeLength))m")
            if let configured = squareSideMeters {
                let diff = abs(Double(edgeLength) - configured)
                let percentDiff = (diff / configured) * 100
                print("   Configured: \(String(format: "%.3f", configured))m")
                print("   Difference: \(String(format: "%.3f", diff))m (\(String(format: "%.1f", percentDiff))%)")
            }
        }
        
        private func createCornerMarker(at position: simd_float3) -> SCNNode {
            let sphere = SCNSphere(radius: 0.01) // 1cm diameter
            let material = SCNMaterial()
            material.diffuse.contents = squareColor ?? UIColor.red
            sphere.materials = [material]
            
            let node = SCNNode(geometry: sphere)
            node.simdPosition = position
            return node
        }
        
        private func createLine(from start: simd_float3, to end: simd_float3) -> SCNNode {
            let vector = end - start
            let length = simd_length(vector)
            let direction = simd_normalize(vector)
            
            let cylinder = SCNCylinder(radius: 0.002, height: CGFloat(length)) // 2mm thick
            let material = SCNMaterial()
            material.diffuse.contents = (squareColor ?? UIColor.red).withAlphaComponent(0.6)
            cylinder.materials = [material]
            
            let node = SCNNode(geometry: cylinder)
            
            // Position at midpoint
            let midpoint = (start + end) / 2
            node.simdPosition = midpoint
            
            // Orient along the vector
            let up = simd_float3(0, 1, 0)
            let rotationAxis = simd_normalize(simd_cross(up, direction))
            let angle = acos(simd_dot(up, direction))
            node.simdRotation = simd_float4(rotationAxis.x, rotationAxis.y, rotationAxis.z, angle)
            
            return node
        }
        
        private func createSquareOutline(corner1: simd_float3, corner2: simd_float3, corner3: simd_float3, corner4: simd_float3) {
            // Create four edges
            let edge1 = createLine(from: corner1, to: corner2)
            let edge2 = createLine(from: corner2, to: corner3)
            let edge3 = createLine(from: corner3, to: corner4)
            let edge4 = createLine(from: corner4, to: corner1)
            
            squareNodes.append(contentsOf: [edge1, edge2, edge3, edge4])
            
            arView?.scene.rootNode.addChildNode(edge1)
            arView?.scene.rootNode.addChildNode(edge2)
            arView?.scene.rootNode.addChildNode(edge3)
            arView?.scene.rootNode.addChildNode(edge4)
            
            // Create fill plane
            let edgeLength = simd_distance(corner1, corner2)
            let plane = SCNPlane(width: CGFloat(edgeLength), height: CGFloat(edgeLength))
            let material = SCNMaterial()
            material.diffuse.contents = (squareColor ?? UIColor.red).withAlphaComponent(0.15)
            material.isDoubleSided = false
            plane.materials = [material]
            
            let fillNode = SCNNode(geometry: plane)
            
            // Position at center of square
            let center = (corner1 + corner2 + corner3 + corner4) / 4
            fillNode.simdPosition = center
            
            // Orient parallel to ground (horizontal plane)
            fillNode.eulerAngles.x = .pi / 2
            
            squareNodes.append(fillNode)
            arView?.scene.rootNode.addChildNode(fillNode)
        }
        
        // MARK: - Plane Detection
        
        func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
            
            let planeNode = createPlaneNode(for: planeAnchor)
            node.addChildNode(planeNode)
            detectedPlanes[planeAnchor.identifier] = planeNode
            
            print("✅ Detected \(planeAnchor.alignment == .horizontal ? "horizontal" : "vertical") plane")
        }
        
        func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
            guard let planeAnchor = anchor as? ARPlaneAnchor,
                  let planeNode = detectedPlanes[planeAnchor.identifier],
                  let plane = planeNode.geometry as? SCNPlane else { return }
            
            plane.width = CGFloat(planeAnchor.planeExtent.width)
            plane.height = CGFloat(planeAnchor.planeExtent.height)
            planeNode.simdPosition = planeAnchor.center
        }
        
        func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
            guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
            detectedPlanes.removeValue(forKey: planeAnchor.identifier)
        }
        
        func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
            DispatchQueue.main.async { [weak self] in
                self?.updateCrosshair()
            }
        }
        
        private func createPlaneNode(for planeAnchor: ARPlaneAnchor) -> SCNNode {
            let plane = SCNPlane(
                width: CGFloat(planeAnchor.planeExtent.width),
                height: CGFloat(planeAnchor.planeExtent.height)
            )
            
            let material = SCNMaterial()
            if planeAnchor.alignment == .horizontal {
                material.diffuse.contents = UIColor.blue.withAlphaComponent(0.3)
            } else {
                material.diffuse.contents = UIColor.green.withAlphaComponent(0.3)
            }
            plane.materials = [material]
            
            let planeNode = SCNNode(geometry: plane)
            planeNode.simdPosition = planeAnchor.center
            planeNode.eulerAngles.x = -.pi/2
            
            return planeNode
        }
        
        func session(_ session: ARSession, didFailWithError error: Error) {
            print("❌ AR Session failed: \(error.localizedDescription)")
        }
        
        func sessionWasInterrupted(_ session: ARSession) {
            print("⚠️ AR Session interrupted")
        }
        
        func sessionInterruptionEnded(_ session: ARSession) {
            print("✅ AR Session interruption ended")
        }
        
        // MARK: - ARSessionDelegate
        
        func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
            guard isRelocalizing else { return }
            
            // Check for relocalization timeout (15 seconds)
            if let startTime = relocalizationStartTime,
               Date().timeIntervalSince(startTime) > 15.0,
               !isRelocalized {
                relocalizationStatus?.wrappedValue = "⚠️ Relocalization failed"
                print("⚠️ Relocalization timeout - unable to match saved map")
                return
            }
            
            if lastTrackingState != camera.trackingState {
                lastTrackingState = camera.trackingState
                
                switch camera.trackingState {
                case .notAvailable:
                    relocalizationStatus?.wrappedValue = "Relocalization: Camera not available"
                case .limited(let reason):
                    let reasonText: String
                    switch reason {
                    case .initializing:
                        relocalizationStatus?.wrappedValue = "Relocalization: Initializing..."
                    case .relocalizing:
                        relocalizationStatus?.wrappedValue = "Relocalization: Matching saved map..."
                    case .excessiveMotion:
                        relocalizationStatus?.wrappedValue = "Relocalization: Move slower"
                    case .insufficientFeatures:
                        relocalizationStatus?.wrappedValue = "Relocalization: Look around slowly"
                    @unknown default:
                        relocalizationStatus?.wrappedValue = "Relocalization: Limited"
                    }
                case .normal:
                    relocalizationStatus?.wrappedValue = "✅ Tracking locked"
                    print("✅ Relocalization successful - tracking locked to saved map")
                    
                    // Mark as relocalized and load markers
                    isRelocalized = true
                    loadAllARMarkers()
                    
                    // Stop showing relocalization status after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.isRelocalizing = false
                        self.relocalizationStatus?.wrappedValue = ""
                    }
                @unknown default:
                    relocalizationStatus?.wrappedValue = "Relocalization: Unknown"
                }
            }
        }
        
        // MARK: - AR Marker Management
        
        private func loadAllARMarkers() {
            guard let mapPointStore = mapPointStore,
                  let arView = arView else {
                return
            }
            
            print("📍 Loading AR Markers into scene...")
            
            let allMarkers = mapPointStore.arMarkers
            guard !allMarkers.isEmpty else {
                print("   No AR Markers to load")
                return
            }
            
            for marker in allMarkers {
                let isActiveMarker = marker.linkedMapPointID == mapPointID
                let markerNode = createMarkerNode(
                    at: marker.arPosition,
                    isActive: isActiveMarker
                )
                markerNode.name = "arMarker_\(marker.id.uuidString)"
                arView.scene.rootNode.addChildNode(markerNode)
                
                print("   ✅ Loaded AR Marker for MapPoint \(marker.linkedMapPointID)")
            }
            
            print("📍 Loaded \(allMarkers.count) AR Marker(s)")
        }
        
        private func createMarkerNode(at position: simd_float3, isActive: Bool) -> SCNNode {
            let markerNode = SCNNode()
            markerNode.simdPosition = position
            
            // Vertical line (post)
            let lineHeight = Double(userHeight) - 0.03
            let line = SCNCylinder(radius: 0.001, height: lineHeight)
            let lineMaterial = SCNMaterial()
            lineMaterial.diffuse.contents = UIColor(red: 0/255, green: 125/255, blue: 184/255, alpha: isActive ? 0.95 : 0.85)
            line.materials = [lineMaterial]
            
            let lineNode = SCNNode(geometry: line)
            lineNode.position = SCNVector3(0, Float(lineHeight / 2), 0)
            markerNode.addChildNode(lineNode)
            
            // Sphere at top
            let sphere = SCNSphere(radius: 0.015)
            let sphereMaterial = SCNMaterial()
            sphereMaterial.diffuse.contents = UIColor(red: 0/255, green: 125/255, blue: 184/255, alpha: isActive ? 0.98 : 0.88)
            sphereMaterial.specular.contents = UIColor.white
            sphereMaterial.shininess = 0.8
            sphere.materials = [sphereMaterial]
            
            let sphereNode = SCNNode(geometry: sphere)
            sphereNode.position = SCNVector3(0, Float(lineHeight), 0)
            markerNode.addChildNode(sphereNode)
            
            return markerNode
        }
    }
    
    static func dismantleUIView(_ uiView: ARSCNView, coordinator: Coordinator) {
        uiView.session.pause()
        print("⏸️ AR Camera session paused")
    }
}

