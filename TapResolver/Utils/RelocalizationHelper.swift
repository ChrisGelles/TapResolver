//
//  RelocalizationHelper.swift
//  TapResolver
//
//  Lightweight relocalization system for transforming AR markers between sessions
//

import Foundation
import simd

// RELOCALIZATION TODO: Implement these functions for Option B

/// Session transformation metadata
/// Stores the relationship between different AR session coordinate systems
// NOTE: Not Codable because simd_float4x4 doesn't conform
// TODO: When implementing persistence, store matrix as [Float] array
struct SessionTransform {
    let fromSessionID: UUID
    let toSessionID: UUID
    let transformMatrix: simd_float4x4
    let calculatedAt: Date
    let confidence: Float  // 0.0 to 1.0, based on number of markers used
    
    /// Number of known markers used to calculate this transformation
    let knownMarkerCount: Int
}

/// Calculate transformation matrix between two AR sessions
/// Uses known markers that were placed in both sessions to compute rigid body transformation
///
/// - Parameters:
///   - knownMarkersOld: Array of (markerID, position) from the old session
///   - knownMarkersNew: Array of (markerID, position) from the new session (same markers, new positions)
/// - Returns: Transformation matrix to convert old positions to new positions, or nil if insufficient data
///
/// TODO: Implement using Kabsch algorithm or similar for rigid body transformation
/// Requires minimum 2 markers, ideally 3+ for better accuracy
func calculateSessionTransformation(
    knownMarkersOld: [(id: UUID, position: simd_float3)],
    knownMarkersNew: [(id: UUID, position: simd_float3)]
) -> simd_float4x4? {
    // TODO: Implement Kabsch algorithm
    // 1. Compute centroids of both point sets
    // 2. Center both point sets on their centroids
    // 3. Compute cross-covariance matrix
    // 4. Perform SVD to get rotation matrix
    // 5. Compute translation vector
    // 6. Combine into 4x4 transformation matrix
    
    print("TODO: Calculate transformation using \(knownMarkersOld.count) known markers")
    return nil
}

/// Transform an AR position from one session's coordinate system to another
///
/// - Parameters:
///   - position: Original position in the old session
///   - transform: Transformation matrix from calculateSessionTransformation
/// - Returns: Position in the new session's coordinate system
func transformPosition(_ position: simd_float3, using transform: simd_float4x4) -> simd_float3 {
    let position4 = simd_float4(position.x, position.y, position.z, 1.0)
    let transformed = transform * position4
    return simd_float3(transformed.x, transformed.y, transformed.z)
}

/// Detect if a marker being placed matches a known marker from a previous session
///
/// - Parameters:
///   - mapPointID: ID of the map point being marked
///   - newPosition: Position where the marker was just placed
///   - storedMarkers: Array of markers from previous sessions
///   - threshold: Maximum distance (in meters) to consider a match
/// - Returns: The stored marker if a match is found, nil otherwise
func detectKnownMarker(
    mapPointID: String,
    newPosition: simd_float3,
    storedMarkers: [ARWorldMapStore.ARMarker],
    threshold: Float = 0.5
) -> ARWorldMapStore.ARMarker? {
    // TODO: Implement known marker detection
    // 1. Find markers with matching mapPointID
    // 2. Check if positions are within threshold
    // 3. Return best match or nil
    
    return storedMarkers.first(where: { $0.mapPointID == mapPointID })
}

/// Trigger relocalization when 2+ known markers are detected
///
/// - Parameters:
///   - knownMarkers: Array of (stored marker, new position) pairs
///   - currentSessionID: ID of the current AR session
/// - Returns: SessionTransform if successful, nil if insufficient data
func triggerRelocalization(
    knownMarkers: [(stored: ARWorldMapStore.ARMarker, newPosition: simd_float3)],
    currentSessionID: UUID
) -> SessionTransform? {
    guard knownMarkers.count >= 2 else {
        print("⚠️ Need at least 2 known markers for relocalization (have \(knownMarkers.count))")
        return nil
    }
    
    print("🔄 Relocalization triggered with \(knownMarkers.count) known markers")
    
    let oldPositions = knownMarkers.map { (id: UUID(uuidString: $0.stored.id) ?? UUID(), position: $0.stored.positionInSession) }
    let newPositions = knownMarkers.map { (id: UUID(uuidString: $0.stored.id) ?? UUID(), position: $0.newPosition) }
    
    guard let transform = calculateSessionTransformation(
        knownMarkersOld: oldPositions,
        knownMarkersNew: newPositions
    ) else {
        print("❌ Failed to calculate transformation")
        return nil
    }
    
    let sessionTransform = SessionTransform(
        fromSessionID: knownMarkers[0].stored.sessionID,
        toSessionID: currentSessionID,
        transformMatrix: transform,
        calculatedAt: Date(),
        confidence: Float(knownMarkers.count) / 10.0,  // Simple confidence calculation
        knownMarkerCount: knownMarkers.count
    )
    
    print("✅ Relocalization successful!")
    print("   Confidence: \(Int(sessionTransform.confidence * 100))%")
    print("   Known markers: \(sessionTransform.knownMarkerCount)")
    
    return sessionTransform
}

