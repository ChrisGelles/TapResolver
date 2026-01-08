//
//  SurveyMarker.swift
//  TapResolver
//
//  Centralized survey marker configuration and management
//

import SceneKit
import UIKit
import simd

// MARK: - Configuration

/// Single source of truth for survey marker dimensions and behavior
struct SurveyMarkerConfig {
    // Geometry
    static let sphereRadius: Float = 0.035
    static let innerSphereInset: Float = 0.002   // Inner sphere 2mm smaller
    static let rodOverlap: Float = 0.002          // Rod extends 2mm into sphere bottom
    
    // Collision zones
    static let deadZoneRadius: Float = 0.010     // 1cm silent zone at center
    
    // Proximity influence
    static let influenceRadiusMeters: Float = 1.25  // Markers within this radius share quality data
    
    // Colors
    static let exteriorColor = UIColor.red
}

// MARK: - Survey Marker Instance

/// Represents a single survey marker in the AR scene
/// Wraps the SceneKit node with metadata for collision detection and data collection
class SurveyMarker {
    let id: UUID
    let node: SCNNode
    let userDeviceHeight: Float
    
    /// Map coordinates for this survey point (nil for test markers)
    let mapCoordinate: CGPoint?
    
    /// Triangle this marker belongs to (nil for test markers)
    /// Mutable to allow reassignment when adjacent triangles are cleared
    var triangleID: UUID?
    
    /// Computed sphere center position for collision detection
    var sphereCenter: simd_float3 {
        simd_float3(
            node.simdPosition.x,
            node.simdPosition.y + userDeviceHeight,
            node.simdPosition.z
        )
    }
    
    /// Create a survey marker at the given AR position
    /// - Parameters:
    ///   - position: AR world position (floor level)
    ///   - userDeviceHeight: Height from floor to device (sphere top)
    ///   - mapCoordinate: Optional map XY for data collection
    ///   - triangleID: Optional triangle ID this marker belongs to
    ///   - animated: Whether to animate marker appearance
    init(at position: simd_float3, userDeviceHeight: Float, mapCoordinate: CGPoint? = nil, triangleID: UUID? = nil, animated: Bool = false) {
        self.id = UUID()
        self.userDeviceHeight = userDeviceHeight
        self.mapCoordinate = mapCoordinate
        self.triangleID = triangleID
        
        let options = MarkerOptions(
            color: SurveyMarkerConfig.exteriorColor,
            markerID: id,
            userDeviceHeight: userDeviceHeight,
            radius: CGFloat(SurveyMarkerConfig.sphereRadius),
            animateOnAppearance: animated,
            isSurveyMarker: true  // Survey markers get gradient inner sphere
        )
        self.node = ARMarkerRenderer.createNode(at: position, options: options)
        node.name = "surveyMarker_\(id.uuidString)"
    }
    
    /// Remove this marker from the scene
    func removeFromScene() {
        node.removeFromParentNode()
    }
    
    // MARK: - Color Management

    /// Calculate sphere color based on weighted dwell time
    /// - Parameter seconds: Weighted dwell time in seconds
    /// - Returns: Interpolated color: Red (0s) → Yellow (6s) → Green (12s+)
    static func colorForDwellTime(_ seconds: Double) -> UIColor {
        let t = min(max(seconds, 0.0), 12.0)
        
        if t <= 6.0 {
            // Red to Yellow: increase green channel
            let progress = t / 6.0
            return UIColor(red: 1.0, green: CGFloat(progress), blue: 0.0, alpha: 1.0)
        } else {
            // Yellow to Green: decrease red channel
            let progress = (t - 6.0) / 6.0
            return UIColor(red: CGFloat(1.0 - progress), green: 1.0, blue: 0.0, alpha: 1.0)
        }
    }

    /// Update the outer sphere color (does not affect inner gradient sphere)
    func updateSphereColor(_ color: UIColor) {
        let sphereNodeName = "arMarkerSphere_\(id.uuidString)"
        guard let sphereNode = node.childNode(withName: sphereNodeName, recursively: true),
              let sphere = sphereNode.geometry as? SCNSphere,
              let material = sphere.firstMaterial else {
            print("⚠️ [SurveyMarker] Could not find sphere node: \(sphereNodeName)")
            return
        }
        material.diffuse.contents = color
    }
}

// MARK: - Notifications for Data Gathering

extension Notification.Name {
    /// Posted when camera enters a survey marker sphere
    /// userInfo: ["markerID": UUID, "mapCoordinate": CGPoint?]
    static let surveyMarkerDwellBegan = Notification.Name("SurveyMarkerDwellBegan")
    
    /// Posted when camera exits a survey marker sphere
    /// userInfo: ["markerID": UUID, "mapCoordinate": CGPoint?, "dwellTime": Double]
    static let surveyMarkerDwellEnded = Notification.Name("SurveyMarkerDwellEnded")
    
    /// Posted when dwell timer crosses from negative to positive (0.0 threshold)
    /// userInfo: ["markerID": UUID, "mapCoordinate": CGPoint?]
    static let surveyMarkerDwellReachedZero = Notification.Name("SurveyMarkerDwellReachedZero")
    
    /// Posted when dwell timer reaches ready threshold (3.0 seconds)
    /// userInfo: ["markerID": UUID, "mapCoordinate": CGPoint?]
    static let surveyMarkerDwellReady = Notification.Name("SurveyMarkerDwellReady")
    
    /// Posted when user wants to manually place a survey marker at crosshair
    static let placeManualSurveyMarker = Notification.Name("PlaceManualSurveyMarker")
}
