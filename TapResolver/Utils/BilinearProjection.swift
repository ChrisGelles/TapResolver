//
//  BilinearProjection.swift
//  TapResolver
//
//  Bilinear interpolation for projecting 2D map coordinates to 3D AR space
//  using a quadrilateral defined by 4 corner correspondences.
//

import Foundation
import simd
import CoreGraphics

struct BilinearProjection {
    
    /// Corner correspondences: map position → AR position
    /// Order: [topLeft, topRight, bottomRight, bottomLeft] or consistent winding
    let mapCorners: [CGPoint]
    let arCorners: [simd_float3]
    
    /// Initialize with 4 map-to-AR corner correspondences
    /// - Parameters:
    ///   - mapCorners: 4 corner positions in map pixel coordinates
    ///   - arCorners: 4 corresponding positions in AR world coordinates
    init?(mapCorners: [CGPoint], arCorners: [simd_float3]) {
        guard mapCorners.count == 4, arCorners.count == 4 else {
            print("⚠️ [BilinearProjection] Invalid corner count: map=\(mapCorners.count), ar=\(arCorners.count)")
            return nil
        }
        self.mapCorners = mapCorners
        self.arCorners = arCorners
    }
    
    /// Project a 2D map coordinate to 3D AR space using bilinear interpolation
    /// - Parameter mapPoint: The map coordinate to project
    /// - Returns: The projected AR position
    func project(_ mapPoint: CGPoint) -> simd_float3 {
        // Compute bilinear coordinates (u, v) for the point relative to the quad
        let (u, v) = computeBilinearCoordinates(mapPoint)
        
        // Bilinear interpolation of AR positions
        // P = (1-u)(1-v)P00 + u(1-v)P10 + (1-u)v*P01 + uv*P11
        let p00 = arCorners[0]  // topLeft
        let p10 = arCorners[1]  // topRight
        let p11 = arCorners[2]  // bottomRight
        let p01 = arCorners[3]  // bottomLeft
        
        let oneMinusU = 1.0 - u
        let oneMinusV = 1.0 - v
        
        let result = oneMinusU * oneMinusV * p00 +
                     u * oneMinusV * p10 +
                     oneMinusU * v * p01 +
                     u * v * p11
        
        return result
    }
    
    /// Compute bilinear (u, v) coordinates for a point relative to the quadrilateral
    /// Uses iterative Newton-Raphson to invert the bilinear mapping
    private func computeBilinearCoordinates(_ point: CGPoint) -> (Float, Float) {
        let m00 = mapCorners[0]
        let m10 = mapCorners[1]
        let m11 = mapCorners[2]
        let m01 = mapCorners[3]
        
        // Convert to Float for computation
        let px = Float(point.x)
        let py = Float(point.y)
        
        let x00 = Float(m00.x), y00 = Float(m00.y)
        let x10 = Float(m10.x), y10 = Float(m10.y)
        let x11 = Float(m11.x), y11 = Float(m11.y)
        let x01 = Float(m01.x), y01 = Float(m01.y)
        
        // Bilinear basis coefficients
        // x(u,v) = a0 + a1*u + a2*v + a3*u*v
        // y(u,v) = b0 + b1*u + b2*v + b3*u*v
        let a0 = x00
        let a1 = x10 - x00
        let a2 = x01 - x00
        let a3 = x00 - x10 + x11 - x01
        
        let b0 = y00
        let b1 = y10 - y00
        let b2 = y01 - y00
        let b3 = y00 - y10 + y11 - y01
        
        // Newton-Raphson iteration to solve for (u, v)
        var u: Float = 0.5
        var v: Float = 0.5
        
        for _ in 0..<10 {
            let fx = a0 + a1 * u + a2 * v + a3 * u * v - px
            let fy = b0 + b1 * u + b2 * v + b3 * u * v - py
            
            // Jacobian
            let dfxdu = a1 + a3 * v
            let dfxdv = a2 + a3 * u
            let dfydu = b1 + b3 * v
            let dfydv = b2 + b3 * u
            
            // Determinant
            let det = dfxdu * dfydv - dfxdv * dfydu
            guard abs(det) > 1e-10 else { break }
            
            // Newton step
            let du = (dfydv * fx - dfxdv * fy) / det
            let dv = (dfxdu * fy - dfydu * fx) / det
            
            u -= du
            v -= dv
            
            // Convergence check
            if abs(du) < 1e-6 && abs(dv) < 1e-6 { break }
        }
        
        return (u, v)
    }
}
