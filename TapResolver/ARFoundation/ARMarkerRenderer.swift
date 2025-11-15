//
//  ARMarkerRenderer.swift
//  TapResolver
//
//  Centralized AR marker rendering logic
//

import SceneKit
import UIKit
import simd

struct MarkerOptions {
    var color: UIColor = UIColor.ARPalette.markerBase
    var markerID: UUID = UUID()
    var userDeviceHeight: Float = ARVisualDefaults.userDeviceHeight
    var badgeColor: UIColor? = nil
    var radius: CGFloat = 0.03
    var animateOnAppearance: Bool = false
    var animationOvershoot: Float = 0.04  // Overshoot in meters (default 4cm)
}

class ARMarkerRenderer {
    static func createNode(at position: simd_float3, options: MarkerOptions) -> SCNNode {
        let markerNode = SCNNode()
        markerNode.simdPosition = position
        markerNode.name = "arMarker_\(options.markerID.uuidString)"
        
        // Floor ring
        let ring = SCNTorus(ringRadius: 0.1, pipeRadius: 0.002)
        ring.firstMaterial?.diffuse.contents = UIColor.ARPalette.markerRing
        let ringNode = SCNNode(geometry: ring)
        markerNode.addChildNode(ringNode)
        
        // Fill
        let fill = SCNCylinder(radius: 0.1, height: 0.001)
        fill.firstMaterial?.diffuse.contents = UIColor.ARPalette.markerFill
        let fillNode = SCNNode(geometry: fill)
        fillNode.eulerAngles.x = .pi
        markerNode.addChildNode(fillNode)
        
        // Vertical line (rod)
        let line = SCNCylinder(radius: 0.00125, height: CGFloat(options.userDeviceHeight))
        line.firstMaterial?.diffuse.contents = UIColor.ARPalette.markerLine
        let lineNode = SCNNode(geometry: line)
        lineNode.position = SCNVector3(0, Float(line.height/2), 0)
        markerNode.addChildNode(lineNode)
        
        // Sphere top
        let sphere = SCNSphere(radius: options.radius)
        sphere.firstMaterial?.diffuse.contents = options.color
        sphere.firstMaterial?.specular.contents = UIColor.white
        sphere.firstMaterial?.shininess = 0.8
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.position = SCNVector3(0, options.userDeviceHeight, 0)
        sphereNode.name = "arMarkerSphere_\(options.markerID.uuidString)"
        markerNode.addChildNode(sphereNode)
        
        // Badge (optional)
        if let badgeColor = options.badgeColor {
            let badgeSphere = SCNSphere(radius: 0.05)
            badgeSphere.firstMaterial?.diffuse.contents = badgeColor
            let badgeNode = SCNNode(geometry: badgeSphere)
            badgeNode.position = SCNVector3(0, 0.5, 0)
            badgeNode.name = "badge_\(options.markerID.uuidString)"
            sphereNode.addChildNode(badgeNode)
        }
        
        // Apply animation if requested
        if options.animateOnAppearance {
            animateMarkerPlacement(
                ringNode: ringNode,
                lineNode: lineNode,
                sphereNode: sphereNode,
                finalHeight: options.userDeviceHeight,
                overshoot: options.animationOvershoot
            )
        }
        
        return markerNode
    }
    
    // MARK: - Animation
    
    private static func animateMarkerPlacement(
        ringNode: SCNNode,
        lineNode: SCNNode,
        sphereNode: SCNNode,
        finalHeight: Float,
        overshoot: Float
    ) {
        let overshootHeight = finalHeight + overshoot
        
        // 1. Floor ring: Scale from 0 → 1.0 (0.0s - 0.15s)
        ringNode.scale = SCNVector3(0, 0, 0)
        let ringScaleUp = SCNAction.scale(to: 1.0, duration: 0.15)
        ringScaleUp.timingMode = .easeOut
        ringNode.runAction(ringScaleUp)
        
        // 2. Rod: Grow from 0 → overshoot height (0.0s - 0.20s)
        // Set pivot at bottom so scaling grows upward
        guard let cylinder = lineNode.geometry as? SCNCylinder else { return }
        lineNode.pivot = SCNMatrix4MakeTranslation(0, -Float(cylinder.height) / 2, 0)
        lineNode.scale = SCNVector3(1, 0, 1)
        
        let rodGrowUp = SCNAction.customAction(duration: 0.20) { node, elapsedTime in
            let progress = Float(elapsedTime / 0.20)
            // Ease out curve: cubic ease out
            let easedProgress = 1.0 - pow(1.0 - progress, 3.0)
            let currentHeight = easedProgress * overshootHeight
            let scaleY = currentHeight / finalHeight
            node.scale = SCNVector3(1, scaleY, 1)
            
            // Update rod position to keep base at origin (pivot is at bottom)
            node.position = SCNVector3(0, currentHeight / 2, 0)
        }
        rodGrowUp.timingMode = .easeOut
        
        // 3. Sphere: Scale from 0 → 1.0 and move up with rod (0.05s - 0.20s)
        sphereNode.scale = SCNVector3(0, 0, 0)
        sphereNode.position = SCNVector3(0, 0, 0)  // Start at base
        
        let sphereDelay = SCNAction.wait(duration: 0.05)
        let sphereGrowAndMove = SCNAction.customAction(duration: 0.15) { node, elapsedTime in
            let progress = Float(elapsedTime / 0.15)
            // Ease out curve
            let easedProgress = 1.0 - pow(1.0 - progress, 3.0)
            
            // Scale from 0 → 1.0
            let scale = CGFloat(easedProgress)
            node.scale = SCNVector3(scale, scale, scale)
            
            // Move up with rod (to overshoot height)
            let currentHeight = easedProgress * overshootHeight
            node.position = SCNVector3(0, currentHeight, 0)
        }
        sphereGrowAndMove.timingMode = .easeOut
        
        // 4. Rod and sphere: Settle down from overshoot → final height (0.20s - 0.35s)
        let rodSettleDown = SCNAction.customAction(duration: 0.15) { node, elapsedTime in
            let progress = Float(elapsedTime / 0.15)
            // Spring-like ease (ease in ease out)
            let easedProgress = progress < 0.5 
                ? 2 * progress * progress 
                : 1 - pow(-2 * progress + 2, 2) / 2
            
            // Rod: Scale from overshoot → final
            let currentHeight = overshootHeight - (easedProgress * (overshootHeight - finalHeight))
            let scaleY = currentHeight / finalHeight
            node.scale = SCNVector3(1, scaleY, 1)
            
            // Update rod position (pivot is at bottom, so position is at half height)
            node.position = SCNVector3(0, currentHeight / 2, 0)
        }
        rodSettleDown.timingMode = .easeInEaseOut
        
        let sphereSettleDown = SCNAction.customAction(duration: 0.15) { node, elapsedTime in
            let progress = Float(elapsedTime / 0.15)
            // Spring-like ease (ease in ease out)
            let easedProgress = progress < 0.5 
                ? 2 * progress * progress 
                : 1 - pow(-2 * progress + 2, 2) / 2
            
            // Move down from overshoot to final height
            let currentHeight = overshootHeight - (easedProgress * (overshootHeight - finalHeight))
            node.position = SCNVector3(0, currentHeight, 0)
        }
        sphereSettleDown.timingMode = .easeInEaseOut
        
        // 5. Final settle (0.35s - 0.40s) - slight bounce
        let rodFinalSettle = SCNAction.customAction(duration: 0.05) { node, elapsedTime in
            // Small bounce effect (damped oscillation)
            let bounce = sin(Float(elapsedTime / 0.05) * .pi) * 0.01 * (1.0 - Float(elapsedTime / 0.05))
            let bounceHeight = finalHeight + bounce
            
            let scaleY = bounceHeight / finalHeight
            node.scale = SCNVector3(1, scaleY, 1)
            node.position = SCNVector3(0, bounceHeight / 2, 0)
        }
        
        let sphereFinalSettle = SCNAction.customAction(duration: 0.05) { node, elapsedTime in
            // Small bounce effect (damped oscillation)
            let bounce = sin(Float(elapsedTime / 0.05) * .pi) * 0.01 * (1.0 - Float(elapsedTime / 0.05))
            let bounceHeight = finalHeight + bounce
            node.position = SCNVector3(0, bounceHeight, 0)
        }
        
        // Ensure final position is exact after animation completes
        let ensureFinalPosition = SCNAction.run { _ in
            lineNode.scale = SCNVector3(1, 1, 1)
            lineNode.position = SCNVector3(0, finalHeight / 2, 0)
            sphereNode.position = SCNVector3(0, finalHeight, 0)
        }
        
        // Run animations
        lineNode.runAction(SCNAction.sequence([rodGrowUp, rodSettleDown, rodFinalSettle, ensureFinalPosition]))
        sphereNode.runAction(SCNAction.sequence([
            sphereDelay, 
            sphereGrowAndMove, 
            sphereSettleDown, 
            sphereFinalSettle, 
            ensureFinalPosition
        ]))
    }
}

