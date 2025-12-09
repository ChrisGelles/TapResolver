//
//  BarycentricMapping.swift
//  TapResolver
//
//  Utility functions for barycentric coordinate interpolation
//

import Foundation
import CoreGraphics
import simd

// MARK: - Surveyable Region

/// Abstraction for an area that can be filled with survey markers.
/// Can represent a single triangle or a multi-triangle Swath.
struct SurveyableRegion {
    /// The triangles that make up this region
    let triangles: [TrianglePatch]
    
    /// All unique vertex IDs across all triangles
    var allVertexIDs: Set<UUID> {
        var ids = Set<UUID>()
        for tri in triangles {
            for vid in tri.vertexIDs {
                ids.insert(vid)
            }
        }
        return ids
    }
    
    /// Create a region from a single triangle
    static func single(_ triangle: TrianglePatch) -> SurveyableRegion {
        return SurveyableRegion(triangles: [triangle])
    }
    
    /// Create a region from multiple triangles (Swath)
    static func swath(_ triangles: [TrianglePatch]) -> SurveyableRegion {
        return SurveyableRegion(triangles: triangles)
    }
    
    /// Number of triangles in this region
    var triangleCount: Int { triangles.count }
    
    /// Is this a single triangle or a multi-triangle swath?
    var isSingleTriangle: Bool { triangles.count == 1 }
}

/// A fill point with its coordinate key and containing triangle
struct RegionFillPoint: Equatable, Hashable {
    /// Coordinate key for SurveyPoint identity: "X.XX,Y.YY" (map position in meters)
    let coordinateKey: String
    
    /// Position in map pixels (for interpolation)
    let mapPosition_px: CGPoint
    
    /// Position in map meters (for display/storage)
    let mapPosition_m: CGPoint
    
    /// ID of the triangle containing this point (for interpolation lookup)
    let containingTriangleID: UUID
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(coordinateKey)
    }
    
    static func == (lhs: RegionFillPoint, rhs: RegionFillPoint) -> Bool {
        lhs.coordinateKey == rhs.coordinateKey
    }
}

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

/// Generate fill points for an entire region (single triangle or multi-triangle Swath)
/// Deduplicates points on shared edges using coordinate keys
/// - Parameters:
///   - region: The surveyable region
///   - spacingMeters: Desired spacing in meters
///   - pxPerMeter: Map scale (pixels per meter)
///   - triangleVertices: Dictionary mapping triangle ID to its 3 vertices as CGPoints (pixels)
/// - Returns: Array of deduplicated RegionFillPoints
func generateFillPointsForRegion(
    region: SurveyableRegion,
    spacingMeters: Float,
    pxPerMeter: Float,
    triangleVertices: [UUID: [CGPoint]]
) -> [RegionFillPoint] {
    var seenKeys = Set<String>()
    var result: [RegionFillPoint] = []
    
    for triangle in region.triangles {
        guard let vertices_px = triangleVertices[triangle.id],
              vertices_px.count == 3 else {
            print("⚠️ [RegionFill] Triangle \(triangle.id) missing vertices, skipping")
            continue
        }
        
        // Generate fill points for this triangle
        let fillPoints = generateTriangleFillPoints(
            triangle: vertices_px,
            spacingMeters: spacingMeters,
            pxPerMeter: pxPerMeter
        )
        
        for point_px in fillPoints {
            // Convert to meters for coordinate key
            let point_m = CGPoint(
                x: point_px.x / CGFloat(pxPerMeter),
                y: point_px.y / CGFloat(pxPerMeter)
            )
            
            // Round to 2 decimal places for consistent keying
            let roundedX = (point_m.x * 100).rounded() / 100
            let roundedY = (point_m.y * 100).rounded() / 100
            let coordKey = String(format: "%.2f,%.2f", roundedX, roundedY)
            
            // Deduplicate by coordinate key (handles shared edges)
            if !seenKeys.contains(coordKey) {
                seenKeys.insert(coordKey)
                
                let fillPoint = RegionFillPoint(
                    coordinateKey: coordKey,
                    mapPosition_px: point_px,
                    mapPosition_m: CGPoint(x: roundedX, y: roundedY),
                    containingTriangleID: triangle.id
                )
                result.append(fillPoint)
            }
        }
    }
    
    print("📐 [RegionFill] Generated \(result.count) unique fill points from \(region.triangleCount) triangle(s)")
    return result
}

