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
    var isSurveyMarker: Bool = false  // Survey markers get gradient inner sphere; others get solid
    var isOriginMarker: Bool = false  // Origin marker: 2m tall, large sphere, RGB cycling
    var isZoneCorner: Bool = false  // Diamond-cube head for zone corner markers
}

class ARMarkerRenderer {
    static func createNode(at position: simd_float3, options: MarkerOptions) -> SCNNode {
        let markerNode = SCNNode()
        markerNode.simdPosition = position
        markerNode.name = "arMarker_\(options.markerID.uuidString)"
        
        // Disable occlusion so markers render even if below ground plane
        markerNode.renderingOrder = 100
        markerNode.castsShadow = false
        
        // Origin marker overrides: taller rod, larger sphere
        let effectiveHeight: Float = options.isOriginMarker ? 2.0 : options.userDeviceHeight
        let effectiveRadius: CGFloat = options.isOriginMarker ? 0.06 : options.radius
        let rodRadius: CGFloat = options.isOriginMarker ? 0.003 : 0.00125  // Thicker rod for origin
        
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
        // Rod ends at bottom of sphere + 2mm overlap for visual connection
        let rodHeight = CGFloat(effectiveHeight) - effectiveRadius + 0.002
        let line = SCNCylinder(radius: rodRadius, height: rodHeight)
        line.firstMaterial?.diffuse.contents = UIColor.ARPalette.markerLine
        let lineNode = SCNNode(geometry: line)
        // Set pivot at bottom so rod grows upward from ground
        lineNode.pivot = SCNMatrix4MakeTranslation(0, -Float(rodHeight) / 2.0, 0)
        // Position at ground level (pivot is at bottom, so node position is at ground)
        lineNode.position = SCNVector3(0, 0, 0)
        markerNode.addChildNode(lineNode)
        
        // Head geometry - sphere or diamond-cube depending on marker type
        let headNode: SCNNode
        let headNodeName: String
        
        if options.isZoneCorner {
            // === ZONE CORNER: Composite marker (sphere + floating diamond cube) ===
            
            // 1. Create sphere (state indicator: orange for ghost, blue for confirmed)
            let sphere = SCNSphere(radius: effectiveRadius)
            sphere.firstMaterial?.diffuse.contents = options.color
            sphere.firstMaterial?.specular.contents = UIColor.white
            sphere.firstMaterial?.shininess = 0.8
            
            let sphereNode = SCNNode(geometry: sphere)
            sphereNode.position = SCNVector3(0, effectiveHeight, 0)
            sphereNode.name = "arMarkerSphere_\(options.markerID.uuidString)"
            markerNode.addChildNode(sphereNode)
            
            // Inner sphere for visibility from inside
            let innerSphere = SCNSphere(radius: effectiveRadius - 0.002)
            innerSphere.firstMaterial?.diffuse.contents = options.color
            innerSphere.firstMaterial?.cullMode = .front
            innerSphere.firstMaterial?.isDoubleSided = false
            innerSphere.firstMaterial?.lightingModel = .constant
            let innerSphereNode = SCNNode(geometry: innerSphere)
            innerSphereNode.position = SCNVector3(0, effectiveHeight, 0)
            innerSphereNode.name = "arMarkerInnerSphere_\(options.markerID.uuidString)"
            markerNode.addChildNode(innerSphereNode)
            
            // 2. Create diamond cube (type indicator: always multicolored)
            let cubeSize = effectiveRadius * 2.5
            let cornerOffset = Float(cubeSize) * sqrt(3.0) / 2.0
            let sphereTopY = effectiveHeight + Float(effectiveRadius)
            let cubeGap: Float = 0.03  // 3cm gap between sphere top and cube bottom corner
            let cubePositionY = sphereTopY + cubeGap + cornerOffset
            
            let cubeNode = createDiamondCubeHead(size: cubeSize, markerID: options.markerID)
            cubeNode.position = SCNVector3(0, cubePositionY, 0)
            markerNode.addChildNode(cubeNode)
            
            // headNode = sphere (for badge attachment and animation compatibility)
            headNode = sphereNode
            headNodeName = "arMarkerSphere_\(options.markerID.uuidString)"
            
            // Ghost marker styling
            if options.isGhost {
                markerNode.opacity = 0.5
            }
            
            print("🔷 [MARKER] Created composite zone corner: sphere at \(effectiveHeight)m, cube at \(cubePositionY)m")
        } else {
            // Standard markers: Sphere head
            let sphere = SCNSphere(radius: effectiveRadius)
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
            sphereNode.position = SCNVector3(0, effectiveHeight, 0)
            sphereNode.name = "arMarkerSphere_\(options.markerID.uuidString)"
            markerNode.addChildNode(sphereNode)
            headNode = sphereNode
            headNodeName = "arMarkerSphere_\(options.markerID.uuidString)"
            
            // Inner sphere - visible from inside (flipped normals) - ONLY for sphere heads
            let innerSphere = SCNSphere(radius: effectiveRadius - 0.002)
            
            if options.isSurveyMarker {
                // Survey markers: gradient texture for visibility when inside
                let poleColor = UIColor(red: 0.05, green: 0.08, blue: 0.2, alpha: 1.0)      // Dark blue-black
                let equatorColor = UIColor(red: 0.8, green: 0.4, blue: 0.1, alpha: 1.0)    // Orange equator band
                let gradientTexture = createEquatorGradientTexture(
                    poleColor: poleColor,
                    equatorColor: equatorColor,
                    falloff: 0.5  // Slightly sharper than linear - nice visible band
                )
                innerSphere.firstMaterial?.diffuse.contents = gradientTexture
            } else {
                // All other markers: solid color matching exterior
                innerSphere.firstMaterial?.diffuse.contents = options.color
            }
            
            innerSphere.firstMaterial?.cullMode = .front  // Flip normals - visible from inside
            innerSphere.firstMaterial?.isDoubleSided = false
            innerSphere.firstMaterial?.lightingModel = .constant  // Ignore scene lighting for consistent color
            let innerSphereNode = SCNNode(geometry: innerSphere)
            innerSphereNode.position = SCNVector3(0, effectiveHeight, 0)
            innerSphereNode.name = "arMarkerInnerSphere_\(options.markerID.uuidString)"
            markerNode.addChildNode(innerSphereNode)
        }
        
        // Badge (optional)
        if let badgeColor = options.badgeColor {
            let badgeSphere = SCNSphere(radius: 0.05)
            badgeSphere.firstMaterial?.diffuse.contents = badgeColor
            // Badge opacity is controlled by parent node's opacity animation
            let badgeNode = SCNNode(geometry: badgeSphere)
            badgeNode.position = SCNVector3(0, 0.5, 0)
            badgeNode.name = "badge_\(options.markerID.uuidString)"
            headNode.addChildNode(badgeNode)
        }
        
        // Apply animation if requested
        if options.animateOnAppearance {
            animateMarkerPlacement(
                ringNode: ringNode,
                lineNode: lineNode,
                sphereNode: headNode,
                finalHeight: effectiveHeight,
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
        
        // Origin marker RGB cycling animation (only for sphere markers)
        if options.isOriginMarker && !options.isZoneCorner {
            // Animate sphere color through RGB cycle
            if let sphereGeometry = headNode.geometry as? SCNSphere {
                let sphereMaterial = sphereGeometry.firstMaterial
                
                let colorCycle = SCNAction.customAction(duration: 3.0) { node, elapsedTime in
                    let phase = elapsedTime / 3.0  // 0.0 to 1.0 over 3 seconds
                    let hue = CGFloat(phase)
                    let color = UIColor(hue: hue, saturation: 1.0, brightness: 1.0, alpha: 1.0)
                    sphereMaterial?.diffuse.contents = color
                    sphereMaterial?.emission.contents = color.withAlphaComponent(0.3)  // Slight glow
                }
                let cycleForever = SCNAction.repeatForever(colorCycle)
                headNode.runAction(cycleForever)
            }
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
    
    // MARK: - Diamond-Cube Head (Zone Corner Markers)
    
    /// Creates a diamond-cube head for zone corner markers
    /// - Parameters:
    ///   - size: Width/height/length of the cube
    ///   - markerID: UUID for node naming
    /// - Returns: SCNNode containing the rotated cube with 6-color faces
    private static func createDiamondCubeHead(size: CGFloat, markerID: UUID) -> SCNNode {
        let cube = SCNBox(width: size, height: size, length: size, chamferRadius: 0)
        
        // Helper to create a material with the given color
        func makeFaceMaterial(_ color: UIColor) -> SCNMaterial {
            let material = SCNMaterial()
            material.diffuse.contents = color
            material.specular.contents = UIColor.white
            material.shininess = 0.6
            return material
        }
        
        // 6 materials for 6 faces (SCNBox order: +X, -X, +Y, -Y, +Z, -Z)
        // Using complementary pairs on opposite faces
        cube.materials = [
            makeFaceMaterial(.red),      // +X
            makeFaceMaterial(.cyan),     // -X (opposite of red)
            makeFaceMaterial(.green),    // +Y
            makeFaceMaterial(.magenta),  // -Y (opposite of green)
            makeFaceMaterial(.blue),     // +Z
            makeFaceMaterial(.yellow)    // -Z (opposite of blue)
        ]
        
        let cubeNode = SCNNode(geometry: cube)
        cubeNode.name = "arMarkerDiamond_\(markerID.uuidString)"
        
        // Rotate so opposing corners are vertical (space diagonal along Y axis)
        // This aligns the cube's (1,1,1) direction with the vertical (0,1,0)
        // Rotation axis: (-1, 0, 1) normalized — perpendicular to both vectors
        // Rotation angle: arccos(1/√3) ≈ 54.74° — angle between space diagonal and Y axis
        let angle = Float(acos(1.0 / sqrt(3.0)))  // ~0.9553 radians
        cubeNode.rotation = SCNVector4(
            -1.0 / sqrt(2.0),  // axis X component
            0,                  // axis Y component
            1.0 / sqrt(2.0),   // axis Z component
            angle               // rotation angle
        )
        
        return cubeNode
    }
    
    /// Transitions a zone corner marker to confirmed state
    /// - Sphere changes to blue (state indicator)
    /// - Diamond cube stays multicolored (type indicator)
    static func transitionDiamondToConfirmed(node: SCNNode, markerID: UUID) {
        let confirmedColor = UIColor.ARPalette.markerBase
        
        // Update sphere to blue
        let sphereName = "arMarkerSphere_\(markerID.uuidString)"
        if let sphereNode = node.childNode(withName: sphereName, recursively: true),
           let sphere = sphereNode.geometry as? SCNSphere {
            sphere.firstMaterial?.diffuse.contents = confirmedColor
            sphere.firstMaterial?.specular.contents = UIColor.white
            sphere.firstMaterial?.shininess = 0.8
            print("🔵 [ARMarkerRenderer] Sphere transitioned to confirmed (blue)")
        } else {
            print("⚠️ [ARMarkerRenderer] Could not find sphere node: \(sphereName)")
        }
        
        // Update inner sphere to blue
        let innerSphereName = "arMarkerInnerSphere_\(markerID.uuidString)"
        if let innerSphereNode = node.childNode(withName: innerSphereName, recursively: true),
           let innerSphere = innerSphereNode.geometry as? SCNSphere {
            innerSphere.firstMaterial?.diffuse.contents = confirmedColor
        }
        
        // Diamond cube stays multicolored
        print("🔷 [ARMarkerRenderer] Diamond cube remains multicolored")
    }
    
    // MARK: - Texture Generation
    
    /// Creates a vertical gradient texture for inner sphere
    /// Poles are dark, equator is bright - simulates interior lighting
    /// - Parameters:
    ///   - poleColor: Color at top and bottom of sphere
    ///   - equatorColor: Color at middle band
    ///   - falloff: Controls gradient sharpness (1.0 = linear, >1 = sharper equator band, <1 = softer)
    /// - Returns: UIImage texture for sphere diffuse map
    private static func createEquatorGradientTexture(
        poleColor: UIColor,
        equatorColor: UIColor,
        falloff: CGFloat = 2.0,
        height: Int = 256
    ) -> UIImage {
        let width = 1
        let size = CGSize(width: width, height: height)
        
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            for y in 0..<height {
                // Normalize y to 0...1 (pole to pole)
                let normalizedY = CGFloat(y) / CGFloat(height - 1)
                
                // Distance from equator (0 at equator, 1 at poles)
                // Equator is at normalizedY = 0.5
                let distanceFromEquator = abs(normalizedY - 0.5) * 2.0  // 0 at equator, 1 at poles
                
                // Apply falloff curve
                let blendFactor = pow(distanceFromEquator, falloff)
                
                // Interpolate between equator color (center) and pole color (edges)
                let color = interpolateColor(from: equatorColor, to: poleColor, factor: blendFactor)
                
                context.cgContext.setFillColor(color.cgColor)
                context.cgContext.fill(CGRect(x: 0, y: y, width: width, height: 1))
            }
        }
    }
    
    /// Linear color interpolation
    private static func interpolateColor(from: UIColor, to: UIColor, factor: CGFloat) -> UIColor {
        var fromR: CGFloat = 0, fromG: CGFloat = 0, fromB: CGFloat = 0, fromA: CGFloat = 0
        var toR: CGFloat = 0, toG: CGFloat = 0, toB: CGFloat = 0, toA: CGFloat = 0
        
        from.getRed(&fromR, green: &fromG, blue: &fromB, alpha: &fromA)
        to.getRed(&toR, green: &toG, blue: &toB, alpha: &toA)
        
        let clampedFactor = max(0, min(1, factor))
        
        return UIColor(
            red: fromR + (toR - fromR) * clampedFactor,
            green: fromG + (toG - fromG) * clampedFactor,
            blue: fromB + (toB - fromB) * clampedFactor,
            alpha: fromA + (toA - fromA) * clampedFactor
        )
    }
}

