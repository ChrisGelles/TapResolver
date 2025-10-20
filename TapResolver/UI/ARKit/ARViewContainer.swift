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

struct ARViewContainer: UIViewRepresentable {
    
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
        
        // MARK: - Plane Detection
        
        func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
            
            let planeNode = createPlaneNode(for: planeAnchor)
            node.addChildNode(planeNode)
            
            print("✅ Detected \(planeAnchor.alignment == .horizontal ? "horizontal" : "vertical") plane")
        }
        
        func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
            guard let planeAnchor = anchor as? ARPlaneAnchor,
                  let planeNode = node.childNodes.first,
                  let plane = planeNode.geometry as? SCNPlane else { return }
            
            // Update plane size as ARKit refines the detection
            plane.width = CGFloat(planeAnchor.planeExtent.width)
            plane.height = CGFloat(planeAnchor.planeExtent.height)
            
            // Update position
            planeNode.simdPosition = planeAnchor.center
        }
        
        private func createPlaneNode(for planeAnchor: ARPlaneAnchor) -> SCNNode {
            let plane = SCNPlane(
                width: CGFloat(planeAnchor.planeExtent.width),
                height: CGFloat(planeAnchor.planeExtent.height)
            )
            
            // Different colors for horizontal vs vertical planes
            let material = SCNMaterial()
            if planeAnchor.alignment == .horizontal {
                material.diffuse.contents = UIColor.blue.withAlphaComponent(0.3)
            } else {
                material.diffuse.contents = UIColor.green.withAlphaComponent(0.3)
            }
            plane.materials = [material]
            
            let planeNode = SCNNode(geometry: plane)
            planeNode.simdPosition = planeAnchor.center
            
            // Rotate plane to match surface orientation
            planeNode.eulerAngles.x = -.pi / 2
            
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

