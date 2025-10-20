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

struct ARViewContainer: UIViewRepresentable {
    
    let mapPointID: UUID
    let userHeight: Float  // From MapPoint's latest session
    @Binding var markerPlaced: Bool
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView()
        
        // Set the delegate
        arView.delegate = context.coordinator
        
        // Create and set an empty scene
        arView.scene = SCNScene()
        
        // Configure AR session
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical] // Detect both plane types
        
        // Run the session
        arView.session.run(configuration)
        
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
        
        print("📷 AR Camera session started")
        
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        // No updates needed for now
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, ARSCNViewDelegate {
        
        weak var arView: ARSCNView?
        var crosshairNode: SCNNode?
        var userHeight: Float = 1.05
        var markerPlaced: Bool = false
        var markerNode: SCNNode?
        
        private var detectedPlanes: [UUID: SCNNode] = [:]
        
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
            //circleNode.eulerAngles = SCNVector3Zero
            //circleNode.eulerAngles.x = .pi //.pi / 2
            crosshairNode.addChildNode(circleNode)
            
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
            guard !markerPlaced,
                  let crosshair = crosshairNode,
                  !crosshair.isHidden else { return }
            
            let markerPosition = crosshair.simdPosition
            placeMarker(at: markerPosition)
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
            lineMaterial.diffuse.contents = UIColor(red: 0/255, green: 50/255, blue: 98/255, alpha: 0.8)
            line.materials = [lineMaterial]
            
            let lineNode = SCNNode(geometry: line)
            lineNode.position = SCNVector3(0, Float(lineHeight / 2), 0)
            markerNode.addChildNode(lineNode)
            
            // Sphere at top (3cm diameter)
            let sphere = SCNSphere(radius: 0.015) // 1.5cm radius = 3cm diameter
            let sphereMaterial = SCNMaterial()
            sphereMaterial.diffuse.contents = UIColor(red: 0/255, green: 125/255, blue: 184/255, alpha: 0.8)
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
            planeNode.eulerAngles.x = .pi
            
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
    }
    
    static func dismantleUIView(_ uiView: ARSCNView, coordinator: Coordinator) {
        uiView.session.pause()
        print("⏸️ AR Camera session paused")
    }
}

