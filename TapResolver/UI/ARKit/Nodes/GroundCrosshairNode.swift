//
//  GroundCrosshairNode.swift
//  TapResolver
//
//  Modular, reusable ground plane crosshair for AR calibration
//

import SceneKit
import ARKit
import simd

final class GroundCrosshairNode: SCNNode {
    
    private let outerRingNode = SCNNode()
    private let circleNode = SCNNode()
    private let hLineNode = SCNNode()
    private let hLine2Node = SCNNode()
    private let vLineNode = SCNNode()
    
    var snapHighlightColor: UIColor = .green.withAlphaComponent(0.9)
    var defaultRingColor: UIColor = .white.withAlphaComponent(0.8)
    var confidenceRingColor: UIColor = .white.withAlphaComponent(0.5)
    
    override init() {
        super.init()
        self.name = "groundCrosshair"
        self.isHidden = true
        
        // Render on top of AR planes (higher = later in render pass)
        self.renderingOrder = 200
        
        // Inner ring
        let circle = SCNTorus(ringRadius: 0.1, pipeRadius: 0.002)
        circle.firstMaterial?.diffuse.contents = defaultRingColor
        makeOcclusionProof(circle.firstMaterial)
        circleNode.geometry = circle
        addChildNode(circleNode)
        
        // Confidence ring
        let outer = SCNTorus(ringRadius: 0.18, pipeRadius: 0.002)
        outer.firstMaterial?.diffuse.contents = confidenceRingColor
        makeOcclusionProof(outer.firstMaterial)
        outerRingNode.geometry = outer
        outerRingNode.name = "outerConfidenceRing"
        outerRingNode.isHidden = true
        addChildNode(outerRingNode)
        
        // Cross lines
        let len: CGFloat = 0.1
        let thick: CGFloat = 0.001
        
        hLineNode.geometry = SCNBox(width: len, height: thick, length: thick, chamferRadius: 0)
        hLineNode.geometry?.firstMaterial?.diffuse.contents = defaultRingColor
        makeOcclusionProof(hLineNode.geometry?.firstMaterial)
        addChildNode(hLineNode)
        
        hLine2Node.geometry = SCNBox(width: len, height: thick, length: thick, chamferRadius: 0)
        hLine2Node.geometry?.firstMaterial?.diffuse.contents = defaultRingColor
        makeOcclusionProof(hLine2Node.geometry?.firstMaterial)
        hLine2Node.eulerAngles.y = .pi / 2
        addChildNode(hLine2Node)
        
        vLineNode.geometry = SCNBox(width: thick, height: len, length: thick, chamferRadius: 0)
        vLineNode.geometry?.firstMaterial?.diffuse.contents = defaultRingColor
        makeOcclusionProof(vLineNode.geometry?.firstMaterial)
        addChildNode(vLineNode)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Configures material to render on top of AR planes regardless of depth
    private func makeOcclusionProof(_ material: SCNMaterial?) {
        material?.readsFromDepthBuffer = false
        material?.writesToDepthBuffer = false
    }
    
    func update(position: simd_float3, snapped: Bool = false, confident: Bool = false) {
        simdPosition = position
        isHidden = false
        
        if let torus = circleNode.geometry as? SCNTorus {
            torus.firstMaterial?.diffuse.contents = snapped ? snapHighlightColor : defaultRingColor
        }
        
        updateConfidenceRing(isVisible: confident)
    }
    
    func hide() {
        isHidden = true
    }
    
    private func updateConfidenceRing(isVisible: Bool) {
        outerRingNode.isHidden = !isVisible
        
        if isVisible && outerRingNode.opacity == 1.0 {
            let pulse = SCNAction.sequence([
                .fadeOpacity(to: 0.3, duration: 0.8),
                .fadeOpacity(to: 1.0, duration: 0.8)
            ])
            outerRingNode.runAction(.repeatForever(pulse), forKey: "pulse")
        } else {
            outerRingNode.removeAction(forKey: "pulse")
        }
    }
}

