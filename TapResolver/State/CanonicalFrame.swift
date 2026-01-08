//
//  CanonicalFrame.swift
//  TapResolver
//
//  Defines the map-centered canonical coordinate frame for baked position data.
//  All baked positions are stored relative to this frame, enabling cross-session
//  consistency and fast ghost marker placement.
//

import Foundation
import simd
import CoreGraphics

/// Defines a stable, map-centered 3D coordinate frame for storing baked AR positions.
///
/// The canonical frame is anchored to the 2D map:
/// - Origin: Center of the map image
/// - X-axis: Map's positive X direction (right)
/// - Z-axis: Map's positive Y direction (down in image, forward in AR)
/// - Y-axis: Height (negative = below origin, matching AR convention)
/// - Scale: Derived from MetricSquare calibration
///
/// This frame is stable across sessions, enabling baked positions to be
/// transformed to any new AR session with a single rigid body transform.
struct CanonicalFrame {
    
    /// Map coordinate of the canonical origin (typically map center)
    let originMapCoordinate: CGPoint
    
    /// Scale factor: how many map pixels equal one meter
    let pixelsPerMeter: Float
    
    /// Reference floor height in canonical frame (average Y from calibration sessions)
    /// Typically a small negative value (e.g., -1.1 meters below AR origin)
    var referenceFloorHeight: Float
    
    /// Creates a canonical frame centered on a map
    /// - Parameters:
    ///   - mapSize: Size of the map image in pixels
    ///   - pixelsPerMeter: Scale factor from MetricSquare calibration
    ///   - referenceFloorHeight: Average floor Y coordinate (default -1.1m)
    init(mapSize: CGSize, pixelsPerMeter: Float, referenceFloorHeight: Float = -1.1) {
        self.originMapCoordinate = CGPoint(x: mapSize.width / 2, y: mapSize.height / 2)
        self.pixelsPerMeter = pixelsPerMeter
        self.referenceFloorHeight = referenceFloorHeight
    }
    
    /// Creates a canonical frame with explicit origin
    /// - Parameters:
    ///   - originMapCoordinate: Map pixel coordinate for canonical origin
    ///   - pixelsPerMeter: Scale factor from MetricSquare calibration
    ///   - referenceFloorHeight: Average floor Y coordinate
    init(originMapCoordinate: CGPoint, pixelsPerMeter: Float, referenceFloorHeight: Float = -1.1) {
        self.originMapCoordinate = originMapCoordinate
        self.pixelsPerMeter = pixelsPerMeter
        self.referenceFloorHeight = referenceFloorHeight
    }
    
    // MARK: - Coordinate Transformations
    
    /// Converts a 2D map coordinate to a 3D canonical position (at floor height)
    /// - Parameter mapPoint: Position in map pixel coordinates
    /// - Returns: Position in canonical 3D frame
    func mapToCanonical(_ mapPoint: CGPoint) -> SIMD3<Float> {
        // Offset from map center
        let dx = Float(mapPoint.x - originMapCoordinate.x)
        let dy = Float(mapPoint.y - originMapCoordinate.y)
        
        // Convert to meters
        let xMeters = dx / pixelsPerMeter
        let zMeters = dy / pixelsPerMeter  // Map Y → Canonical Z
        
        return SIMD3<Float>(xMeters, referenceFloorHeight, zMeters)
    }
    
    /// Converts a 3D canonical position back to 2D map coordinates
    /// - Parameter canonicalPosition: Position in canonical 3D frame
    /// - Returns: Position in map pixel coordinates (ignores Y/height)
    func canonicalToMap(_ canonicalPosition: SIMD3<Float>) -> CGPoint {
        // Convert from meters to pixels
        let dxPixels = canonicalPosition.x * pixelsPerMeter
        let dyPixels = canonicalPosition.z * pixelsPerMeter  // Canonical Z → Map Y
        
        // Add origin offset
        return CGPoint(
            x: CGFloat(dxPixels) + originMapCoordinate.x,
            y: CGFloat(dyPixels) + originMapCoordinate.y
        )
    }
    
    // MARK: - Session Transform Integration
    
    /// Transforms a position from an AR session's coordinate frame to canonical frame
    /// - Parameters:
    ///   - sessionPosition: Position in current AR session coordinates
    ///   - sessionToCanonicalRotation: Y-axis rotation (radians) from session to canonical
    ///   - sessionToCanonicalTranslation: Translation from session origin to canonical origin
    /// - Returns: Position in canonical frame
    func transformSessionToCanonical(
        sessionPosition: SIMD3<Float>,
        rotationY: Float,
        translation: SIMD3<Float>
    ) -> SIMD3<Float> {
        let cosR = cos(rotationY)
        let sinR = sin(rotationY)
        
        // Rotate around Y axis
        let rotated = SIMD3<Float>(
            sessionPosition.x * cosR - sessionPosition.z * sinR,
            sessionPosition.y,
            sessionPosition.x * sinR + sessionPosition.z * cosR
        )
        
        // Translate
        return rotated + translation
    }
    
    /// Transforms a position from canonical frame to an AR session's coordinate frame
    /// - Parameters:
    ///   - canonicalPosition: Position in canonical frame
    ///   - canonicalToSessionRotation: Y-axis rotation (radians) from canonical to session
    ///   - canonicalToSessionTranslation: Translation from canonical origin to session origin
    /// - Returns: Position in session's AR coordinate frame
    func transformCanonicalToSession(
        canonicalPosition: SIMD3<Float>,
        rotationY: Float,
        translation: SIMD3<Float>
    ) -> SIMD3<Float> {
        // First translate, then rotate (inverse order of session→canonical)
        let translated = canonicalPosition - translation
        
        // Rotate by negative angle (inverse rotation)
        let cosR = cos(-rotationY)
        let sinR = sin(-rotationY)
        
        return SIMD3<Float>(
            translated.x * cosR - translated.z * sinR,
            translated.y,
            translated.x * sinR + translated.z * cosR
        )
    }
    
    // MARK: - Factory Methods
    
    /// Creates a canonical frame from the current map context
    /// - Parameters:
    ///   - mapSize: Size of the map image in pixels
    ///   - metersPerPixel: Scale factor (meters per pixel) from MetricSquare calibration
    /// - Returns: A canonical frame centered on the map
    static func fromMapContext(mapSize: CGSize, metersPerPixel: Float) -> CanonicalFrame {
        let pixelsPerMeter = 1.0 / metersPerPixel
        return CanonicalFrame(mapSize: mapSize, pixelsPerMeter: pixelsPerMeter)
    }
    
    // MARK: - Debug
    
    var debugDescription: String {
        return """
        CanonicalFrame:
           Origin: (\(Int(originMapCoordinate.x)), \(Int(originMapCoordinate.y))) pixels
           Scale: \(String(format: "%.1f", pixelsPerMeter)) pixels/meter
           Floor height: \(String(format: "%.2f", referenceFloorHeight))m
        """
    }
}
