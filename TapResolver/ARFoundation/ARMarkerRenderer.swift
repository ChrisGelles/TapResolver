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
    var userHeight: Float = 1.6
    var badgeColor: UIColor? = nil
    var radius: CGFloat = 0.03
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
        
        // Vertical line
        let line = SCNCylinder(radius: 0.00125, height: CGFloat(options.userHeight))
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
        sphereNode.position = SCNVector3(0, Float(line.height), 0)
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
        
        return markerNode
    }
}

