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
    var isGhost: Bool = false  // Ghost markers are semi-transparent and pulsing
}

class ARMarkerRenderer {
    static func createNode(at position: simd_float3, options: MarkerOptions) -> SCNNode {
        let markerNode = SCNNode()
        markerNode.simdPosition = position
        markerNode.name = "arMarker_\(options.markerID.uuidString)"
        
        // Disable occlusion so markers render even if below ground plane
        markerNode.renderingOrder = 100
        markerNode.castsShadow = false
        
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
        // Set pivot at bottom so rod grows upward from ground
        lineNode.pivot = SCNMatrix4MakeTranslation(0, -Float(line.height) / 2.0, 0)
        // Position at ground level (pivot is at bottom, so node position is at ground)
        lineNode.position = SCNVector3(0, 0, 0)
        markerNode.addChildNode(lineNode)
        
        // Sphere top - positioned at top of rod
        let sphere = SCNSphere(radius: options.radius)
        sphere.firstMaterial?.diffuse.contents = options.color
        sphere.firstMaterial?.specular.contents = UIColor.white
        sphere.firstMaterial?.shininess = 0.8
        
        // Ghost marker styling: semi-transparent and pulsing
        // Note: We'll animate node opacity instead of material transparency for smoother pulsing
        if options.isGhost {
            // Set initial opacity on the node (will be animated)
            markerNode.opacity = 0.5  // Start at 50% opacity
        }
        
        let sphereNode = SCNNode(geometry: sphere)
        // Position sphere at top of rod (resting on top)
        sphereNode.position = SCNVector3(0, options.userDeviceHeight, 0)
        sphereNode.name = "arMarkerSphere_\(options.markerID.uuidString)"
        markerNode.addChildNode(sphereNode)
        
        // Badge (optional)
        if let badgeColor = options.badgeColor {
            let badgeSphere = SCNSphere(radius: 0.05)
            badgeSphere.firstMaterial?.diffuse.contents = badgeColor
            // Badge opacity is controlled by parent node's opacity animation
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
        
        // Ghost marker pulsing animation
        if options.isGhost {
            let pulseAction = SCNAction.sequence([
                SCNAction.fadeOpacity(to: 0.4, duration: 1.0),
                SCNAction.fadeOpacity(to: 0.85, duration: 1.0)
            ])
            let pulseForever = SCNAction.repeatForever(pulseAction)
            markerNode.runAction(pulseForever)
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
        // Pivot is already set at bottom in createNode, so scaling grows upward from ground
        guard let cylinder = lineNode.geometry as? SCNCylinder else { return }
        // Ensure pivot is at bottom (should already be set, but ensure it)
        lineNode.pivot = SCNMatrix4MakeTranslation(0, -Float(cylinder.height) / 2, 0)
        // Start with zero scale on Y-axis (rod starts invisible)
        lineNode.scale = SCNVector3(1, 0, 1)
        // Position at ground level (pivot is at bottom, so node stays at ground)
        lineNode.position = SCNVector3(0, 0, 0)
        
        let rodGrowUp = SCNAction.customAction(duration: 0.20) { node, elapsedTime in
            let progress = Float(elapsedTime / 0.20)
            // Ease out curve: cubic ease out
            let easedProgress = 1.0 - pow(1.0 - progress, 3.0)
            let currentHeight = easedProgress * overshootHeight
            let scaleY = currentHeight / finalHeight
            // Scale only Y-axis to grow upward from pivot (bottom)
            // With pivot at bottom, scaling grows upward from ground
            node.scale = SCNVector3(1, scaleY, 1)
            // Position stays at ground level (pivot handles the growth)
            node.position = SCNVector3(0, 0, 0)
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
            // Scale only Y-axis (pivot at bottom handles growth)
            node.scale = SCNVector3(1, scaleY, 1)
            // Position stays at ground level
            node.position = SCNVector3(0, 0, 0)
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
            // Scale only Y-axis (pivot at bottom handles growth)
            node.scale = SCNVector3(1, scaleY, 1)
            // Position stays at ground level
            node.position = SCNVector3(0, 0, 0)
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
            // Rod position stays at ground (pivot at bottom handles growth)
            lineNode.position = SCNVector3(0, 0, 0)
            // Sphere sits at top of rod
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

