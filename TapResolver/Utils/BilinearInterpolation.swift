//
//  BilinearInterpolation.swift
//  TapResolver
//
//  Created for Calibration Mesh system
//  Provides bilinear interpolation utilities for projecting 2D map positions to 3D AR space
//

import Foundation
import simd
import CoreGraphics

// MARK: - Corner Sorting

/// Sorts 4 corner points into counter-clockwise order starting from bottom-left.
/// Uses the geometric centroid to determine angular position of each corner.
///
/// - Parameter corners: Array of exactly 4 CGPoints (2D map coordinates)
/// - Returns: Array of 4 CGPoints sorted CCW: [bottomLeft, bottomRight, topRight, topLeft]
///            Returns nil if input doesn't have exactly 4 points
func sortCornersCounterClockwise(_ corners: [CGPoint]) -> [CGPoint]? {
    guard corners.count == 4 else {
        print("⚠️ [BILINEAR] sortCornersCounterClockwise requires exactly 4 corners, got \(corners.count)")
        return nil
    }
    
    // Compute centroid (geometric center)
    let centroid = CGPoint(
        x: corners.reduce(0) { $0 + $1.x } / 4.0,
        y: corners.reduce(0) { $0 + $1.y } / 4.0
    )
    
    // Compute angle from centroid for each corner
    // atan2 returns angle in radians, -π to π
    let cornersWithAngles = corners.map { corner -> (point: CGPoint, angle: CGFloat) in
        let angle = atan2(corner.y - centroid.y, corner.x - centroid.x)
        return (corner, angle)
    }
    
    // Sort by angle (ascending = counter-clockwise)
    let sorted = cornersWithAngles.sorted { $0.angle < $1.angle }
    
    // Find the bottom-left corner (smallest x + y, or most negative angle in lower half)
    // We want to start from the corner closest to "bottom-left" in map coordinates
    // Map coordinates typically have Y increasing downward, so "bottom" = larger Y
    // Adjust: find corner with smallest x among the two with largest y (bottom two)
    let sortedPoints = sorted.map { $0.point }
    
    // Find index of bottom-left to rotate the array
    // Bottom-left = min x among points with max y, OR we can use angle-based approach
    // For robustness, find the point in the "third quadrant" relative to centroid
    // (negative x, negative y from centroid in standard coords, but map Y is inverted)
    
    // Simpler approach: bottom-left has the smallest (x - y) value in screen coordinates
    // where Y increases downward. Actually, let's find min x among the lower two points.
    
    // Sort by Y descending (larger Y = lower on screen = "bottom")
    let byY = sortedPoints.sorted { $0.y > $1.y }
    let bottomTwo = [byY[0], byY[1]]
    let bottomLeft = bottomTwo.min { $0.x < $1.x }!
    
    // Find index of bottomLeft in our CCW-sorted array
    guard let startIndex = sortedPoints.firstIndex(where: { $0 == bottomLeft }) else {
        print("⚠️ [BILINEAR] Could not find bottom-left corner in sorted array")
        return sortedPoints // Return as-is rather than fail
    }
    
    // Rotate array so bottomLeft is first
    let rotated = Array(sortedPoints[startIndex...]) + Array(sortedPoints[..<startIndex])
    
    print("📐 [BILINEAR] Sorted corners CCW from bottom-left:")
    print("   A (0,0): \(rotated[0])")
    print("   B (1,0): \(rotated[1])")
    print("   C (1,1): \(rotated[2])")
    print("   D (0,1): \(rotated[3])")
    
    return rotated
}

/// Overload that accepts UUIDs paired with positions, returning sorted UUIDs
/// Useful when you need to track which MapPoint corresponds to which corner
func sortCornersCounterClockwise(_ corners: [(id: UUID, position: CGPoint)]) -> [(id: UUID, position: CGPoint)]? {
    guard corners.count == 4 else {
        print("⚠️ [BILINEAR] sortCornersCounterClockwise requires exactly 4 corners, got \(corners.count)")
        return nil
    }
    
    let centroid = CGPoint(
        x: corners.reduce(0) { $0 + $1.position.x } / 4.0,
        y: corners.reduce(0) { $0 + $1.position.y } / 4.0
    )
    
    let cornersWithAngles = corners.map { corner -> (id: UUID, position: CGPoint, angle: CGFloat) in
        let angle = atan2(corner.position.y - centroid.y, corner.position.x - centroid.x)
        return (corner.id, corner.position, angle)
    }
    
    let sorted = cornersWithAngles.sorted { $0.angle < $1.angle }
    let sortedPairs = sorted.map { (id: $0.id, position: $0.position) }
    
    // Find bottom-left
    let byY = sortedPairs.sorted { $0.position.y > $1.position.y }
    let bottomTwo = [byY[0], byY[1]]
    let bottomLeft = bottomTwo.min { $0.position.x < $1.position.x }!
    
    guard let startIndex = sortedPairs.firstIndex(where: { $0.id == bottomLeft.id }) else {
        print("⚠️ [BILINEAR] Could not find bottom-left corner in sorted array")
        return sortedPairs
    }
    
    let rotated = Array(sortedPairs[startIndex...]) + Array(sortedPairs[..<startIndex])
    
    print("📐 [BILINEAR] Sorted corners CCW from bottom-left:")
    for (i, corner) in rotated.enumerated() {
        let label = ["A (0,0)", "B (1,0)", "C (1,1)", "D (0,1)"][i]
        print("   \(label): \(String(corner.id.uuidString.prefix(8))) at \(corner.position)")
    }
    
    return rotated
}


// MARK: - Quad Validation

/// Checks if 4 corners form a valid (non-self-intersecting) quadrilateral.
/// Corners must be in CCW order: [A, B, C, D] where edges are A-B, B-C, C-D, D-A.
///
/// - Parameter corners: Array of exactly 4 CGPoints in CCW order
/// - Returns: true if valid convex or simple concave quad, false if edges cross
func isValidQuad(corners: [CGPoint]) -> Bool {
    guard corners.count == 4 else {
        print("⚠️ [BILINEAR] isValidQuad requires exactly 4 corners")
        return false
    }
    
    // Check if opposite edges intersect (would make a "bowtie" shape)
    // Edge AB (0-1) vs Edge CD (2-3)
    // Edge BC (1-2) vs Edge DA (3-0)
    
    let a = corners[0]
    let b = corners[1]
    let c = corners[2]
    let d = corners[3]
    
    if segmentsIntersect(a, b, c, d) {
        print("⚠️ [BILINEAR] Invalid quad: edges AB and CD intersect")
        return false
    }
    
    if segmentsIntersect(b, c, d, a) {
        print("⚠️ [BILINEAR] Invalid quad: edges BC and DA intersect")
        return false
    }
    
    print("✅ [BILINEAR] Quad is valid (non-self-intersecting)")
    return true
}

/// Helper: Check if two line segments intersect
private func segmentsIntersect(_ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint, _ p4: CGPoint) -> Bool {
    let d1 = direction(p3, p4, p1)
    let d2 = direction(p3, p4, p2)
    let d3 = direction(p1, p2, p3)
    let d4 = direction(p1, p2, p4)
    
    if ((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
       ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0)) {
        return true
    }
    
    // Collinear cases
    if d1 == 0 && onSegment(p3, p4, p1) { return true }
    if d2 == 0 && onSegment(p3, p4, p2) { return true }
    if d3 == 0 && onSegment(p1, p2, p3) { return true }
    if d4 == 0 && onSegment(p1, p2, p4) { return true }
    
    return false
}

/// Helper: Cross product direction
private func direction(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> CGFloat {
    return (c.x - a.x) * (b.y - a.y) - (b.x - a.x) * (c.y - a.y)
}

/// Helper: Check if point c lies on segment a-b (when collinear)
private func onSegment(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> Bool {
    return min(a.x, b.x) <= c.x && c.x <= max(a.x, b.x) &&
           min(a.y, b.y) <= c.y && c.y <= max(a.y, b.y)
}


// MARK: - Inverse Bilinear (2D Point → UV)

/// Computes UV coordinates for a point within a quadrilateral.
/// Uses iterative Newton-Raphson method for general quads.
///
/// - Parameters:
///   - point: The 2D point to find UV for
///   - corners: Array of exactly 4 CGPoints in CCW order [A, B, C, D]
///              where A=(0,0), B=(1,0), C=(1,1), D=(0,1) in UV space
/// - Returns: (u, v) coordinates where both are in [0,1] if inside quad, or nil if outside/invalid
func inverseBilinear(point: CGPoint, corners: [CGPoint]) -> (u: Float, v: Float)? {
    guard corners.count == 4 else {
        print("⚠️ [BILINEAR] inverseBilinear requires exactly 4 corners")
        return nil
    }
    
    let p = simd_float2(Float(point.x), Float(point.y))
    let a = simd_float2(Float(corners[0].x), Float(corners[0].y))  // (0,0)
    let b = simd_float2(Float(corners[1].x), Float(corners[1].y))  // (1,0)
    let c = simd_float2(Float(corners[2].x), Float(corners[2].y))  // (1,1)
    let d = simd_float2(Float(corners[3].x), Float(corners[3].y))  // (0,1)
    
    // Bilinear equation: P = (1-u)(1-v)A + u(1-v)B + uvC + (1-u)vD
    // Rearranged: P = A + u(B-A) + v(D-A) + uv(A-B+C-D)
    
    let e = b - a  // B - A
    let f = d - a  // D - A
    let g = a - b + c - d  // A - B + C - D
    let h = p - a  // P - A
    
    // Solve: h = u*e + v*f + uv*g
    // This is a quadratic in u and v
    
    // Cross product for 2D: a × b = a.x * b.y - a.y * b.x
    func cross(_ v1: simd_float2, _ v2: simd_float2) -> Float {
        return v1.x * v2.y - v1.y * v2.x
    }
    
    let k2 = cross(g, f)
    let k1 = cross(e, f) + cross(h, g)
    let k0 = cross(h, e)
    
    var u: Float = 0
    var v: Float = 0
    
    // Handle near-parallel cases (k2 ≈ 0 means nearly rectangular)
    if abs(k2) < 1e-6 {
        // Linear case
        if abs(k1) < 1e-6 {
            print("⚠️ [BILINEAR] Degenerate quad (parallel edges)")
            return nil
        }
        v = -k0 / k1
        
        let denom = e.x + g.x * v
        if abs(denom) > 1e-6 {
            u = (h.x - f.x * v) / denom
        } else {
            let denomY = e.y + g.y * v
            if abs(denomY) < 1e-6 {
                return nil
            }
            u = (h.y - f.y * v) / denomY
        }
    } else {
        // Quadratic case: k2*v² + k1*v + k0 = 0
        let discriminant = k1 * k1 - 4 * k2 * k0
        if discriminant < 0 {
            // No real solution - point is outside quad
            return nil
        }
        
        let sqrtDisc = sqrt(discriminant)
        let v1 = (-k1 + sqrtDisc) / (2 * k2)
        let v2 = (-k1 - sqrtDisc) / (2 * k2)
        
        // Choose v that gives u in [0,1]
        var validSolution = false
        for vCandidate in [v1, v2] {
            let denom = e.x + g.x * vCandidate
            var uCandidate: Float
            if abs(denom) > 1e-6 {
                uCandidate = (h.x - f.x * vCandidate) / denom
            } else {
                let denomY = e.y + g.y * vCandidate
                if abs(denomY) < 1e-6 {
                    continue
                }
                uCandidate = (h.y - f.y * vCandidate) / denomY
            }
            
            // Check if both u and v are in valid range (with small epsilon for boundary)
            let epsilon: Float = 0.001
            if uCandidate >= -epsilon && uCandidate <= 1 + epsilon &&
               vCandidate >= -epsilon && vCandidate <= 1 + epsilon {
                u = max(0, min(1, uCandidate))
                v = max(0, min(1, vCandidate))
                validSolution = true
                break
            }
        }
        
        if !validSolution {
            // Point is outside quad
            return nil
        }
    }
    
    // Clamp to [0,1]
    u = max(0, min(1, u))
    v = max(0, min(1, v))
    
    return (u, v)
}


// MARK: - Forward Bilinear (UV → 3D Position)

/// Projects UV coordinates to a 3D position using bilinear interpolation from 4 corner positions.
///
/// - Parameters:
///   - u: Horizontal parameter [0,1], 0 = left edge, 1 = right edge
///   - v: Vertical parameter [0,1], 0 = bottom edge, 1 = top edge
///   - corners: Array of exactly 4 simd_float3 positions in CCW order [A, B, C, D]
///              where A=(0,0), B=(1,0), C=(1,1), D=(0,1) in UV space
/// - Returns: Interpolated 3D position
func bilinearInterpolate(u: Float, v: Float, corners: [simd_float3]) -> simd_float3? {
    guard corners.count == 4 else {
        print("⚠️ [BILINEAR] bilinearInterpolate requires exactly 4 corners")
        return nil
    }
    
    let a = corners[0]  // (0,0) bottom-left
    let b = corners[1]  // (1,0) bottom-right
    let c = corners[2]  // (1,1) top-right
    let d = corners[3]  // (0,1) top-left
    
    // P = (1-u)(1-v)A + u(1-v)B + uvC + (1-u)vD
    let result = (1 - u) * (1 - v) * a
              + u * (1 - v) * b
              + u * v * c
              + (1 - u) * v * d
    
    return result
}

/// Convenience function: Given a 2D point and quad corners, project directly to 3D.
/// Combines inverseBilinear and bilinearInterpolate.
///
/// - Parameters:
///   - point: 2D map position to project
///   - corners2D: 4 corner positions in 2D map space (CGPoint), CCW order
///   - corners3D: 4 corner positions in 3D AR space (simd_float3), same order as corners2D
/// - Returns: Projected 3D position, or nil if point is outside quad
func projectPointBilinear(
    point: CGPoint,
    corners2D: [CGPoint],
    corners3D: [simd_float3]
) -> simd_float3? {
    guard corners2D.count == 4, corners3D.count == 4 else {
        print("⚠️ [BILINEAR] projectPointBilinear requires exactly 4 corners in each array")
        return nil
    }
    
    guard let uv = inverseBilinear(point: point, corners: corners2D) else {
        print("⚠️ [BILINEAR] Point \(point) is outside quad")
        return nil
    }
    
    guard let position = bilinearInterpolate(u: uv.u, v: uv.v, corners: corners3D) else {
        return nil
    }
    
    print("📐 [BILINEAR] Projected point \(point) → UV(\(String(format: "%.3f", uv.u)), \(String(format: "%.3f", uv.v))) → AR(\(String(format: "%.2f", position.x)), \(String(format: "%.2f", position.y)), \(String(format: "%.2f", position.z)))")
    
    return position
}

