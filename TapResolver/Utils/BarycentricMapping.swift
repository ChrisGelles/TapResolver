//
//  BarycentricMapping.swift
//  TapResolver
//
//  Utility functions for barycentric coordinate interpolation
//

import Foundation
import CoreGraphics
import simd

// MARK: - Survey Marker Interpolation

/// Interpolate 3D AR position from 2D map point using barycentric coordinates
/// Returns nil if triangle is degenerate or point is outside triangle
@inline(__always)
func interpolateARPosition(
    fromMapPoint p: CGPoint,
    triangle2D: [CGPoint],
    triangle3D: [simd_float3]
) -> simd_float3? {
    guard triangle2D.count == 3, triangle3D.count == 3 else { 
        print("⚠️ Invalid triangle: expected 3 vertices")
        return nil 
    }
    
    let (a, b, c) = (triangle2D[0], triangle2D[1], triangle2D[2])
    let (pa, pb, pc) = (triangle3D[0], triangle3D[1], triangle3D[2])
    
    // Compute barycentric coordinates
    let denom = ((b.y - c.y) * (a.x - c.x) + (c.x - b.x) * (a.y - c.y))
    guard abs(denom) > 1e-6 else { 
        print("⚠️ Degenerate triangle: cannot interpolate")
        return nil 
    }
    
    let w1 = ((b.y - c.y) * (p.x - c.x) + (c.x - b.x) * (p.y - c.y)) / denom
    let w2 = ((c.y - a.y) * (p.x - c.x) + (a.x - c.x) * (p.y - c.y)) / denom
    let w3 = 1.0 - w1 - w2
    
    // Interpolate 3D position
    let result = Float(w1) * pa + Float(w2) * pb + Float(w3) * pc
    return result
}

/// Generate evenly-spaced 2D points inside a triangle
/// - Parameters:
///   - triangle: Array of 3 CGPoints defining triangle vertices
///   - spacingMeters: Desired spacing in meters
///   - pxPerMeter: Map scale (pixels per meter)
/// - Returns: Array of CGPoints inside the triangle
func generateTriangleFillPoints(
    triangle: [CGPoint],
    spacingMeters: Float,
    pxPerMeter: Float
) -> [CGPoint] {
    guard triangle.count == 3 else { return [] }
    
    let (a, b, c) = (triangle[0], triangle[1], triangle[2])
    
    // Convert spacing to map pixels
    let spacingPixels = CGFloat(spacingMeters * pxPerMeter)
    
    var result: [CGPoint] = []
    
    // Barycentric grid scan - generate points evenly spaced in barycentric space
    // Calculate step size based on triangle size and desired spacing
    let triangleArea = abs((b.x - a.x) * (c.y - a.y) - (c.x - a.x) * (b.y - a.y)) / 2.0
    let estimatedPointsPerSide = sqrt(triangleArea / (spacingPixels * spacingPixels))
    let steps = max(Int(estimatedPointsPerSide), 5) // Minimum 5 steps
    let step = 1.0 / Double(steps)
    
    for i in stride(from: 0.0, through: 1.0, by: step) {
        for j in stride(from: 0.0, through: 1.0 - i, by: step) {
            let k = 1.0 - i - j
            // Only add point if all barycentric coordinates are non-negative
            if k >= 0 {
                let x = i * a.x + j * b.x + k * c.x
                let y = i * a.y + j * b.y + k * c.y
                result.append(CGPoint(x: x, y: y))
            }
        }
    }
    
    return result
}

