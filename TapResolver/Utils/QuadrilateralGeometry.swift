//
//  QuadrilateralGeometry.swift
//  TapResolver
//
//  Geometry utilities for quadrilateral intersection testing.
//  Used to determine zone neighbor relationships.
//

import CoreGraphics

struct QuadrilateralGeometry {
    
    // MARK: - Public Interface
    
    /// Determines if two quadrilaterals overlap (share any area)
    /// - Parameters:
    ///   - quadA: 4 corner points of first quadrilateral (in order, clockwise or counter-clockwise)
    ///   - quadB: 4 corner points of second quadrilateral (in order, clockwise or counter-clockwise)
    /// - Returns: True if the quadrilaterals overlap or share an edge
    static func quadrilateralsIntersect(_ quadA: [CGPoint], _ quadB: [CGPoint]) -> Bool {
        guard quadA.count == 4, quadB.count == 4 else {
            print("⚠️ [QuadGeometry] Invalid quad: A has \(quadA.count), B has \(quadB.count) points")
            return false
        }
        
        // Check 1: Any vertex of A inside B?
        for vertex in quadA {
            if pointInQuadrilateral(vertex, quadB) {
                return true
            }
        }
        
        // Check 2: Any vertex of B inside A?
        for vertex in quadB {
            if pointInQuadrilateral(vertex, quadA) {
                return true
            }
        }
        
        // Check 3: Any edge of A intersects any edge of B?
        let edgesA = edges(of: quadA)
        let edgesB = edges(of: quadB)
        
        for edgeA in edgesA {
            for edgeB in edgesB {
                if segmentsIntersect(edgeA.0, edgeA.1, edgeB.0, edgeB.1) {
                    return true
                }
            }
        }
        
        return false
    }
    
    // MARK: - Point in Polygon
    
    /// Tests if a point is inside a quadrilateral using winding number
    /// - Parameters:
    ///   - point: The point to test
    ///   - quad: 4 corner points of the quadrilateral
    /// - Returns: True if point is inside or on the boundary
    static func pointInQuadrilateral(_ point: CGPoint, _ quad: [CGPoint]) -> Bool {
        guard quad.count == 4 else { return false }
        
        // Use ray casting algorithm
        var inside = false
        var j = 3  // Start with last vertex
        
        for i in 0..<4 {
            let vi = quad[i]
            let vj = quad[j]
            
            // Check if ray from point going right crosses this edge
            if ((vi.y > point.y) != (vj.y > point.y)) {
                let intersectX = (vj.x - vi.x) * (point.y - vi.y) / (vj.y - vi.y) + vi.x
                if point.x < intersectX {
                    inside.toggle()
                }
            }
            j = i
        }
        
        return inside
    }
    
    // MARK: - Line Segment Intersection
    
    /// Tests if two line segments intersect
    /// - Parameters:
    ///   - p1, p2: Endpoints of first segment
    ///   - p3, p4: Endpoints of second segment
    /// - Returns: True if segments intersect
    static func segmentsIntersect(_ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint, _ p4: CGPoint) -> Bool {
        let d1 = direction(p3, p4, p1)
        let d2 = direction(p3, p4, p2)
        let d3 = direction(p1, p2, p3)
        let d4 = direction(p1, p2, p4)
        
        if ((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
           ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0)) {
            return true
        }
        
        // Check collinear cases
        if d1 == 0 && onSegment(p3, p4, p1) { return true }
        if d2 == 0 && onSegment(p3, p4, p2) { return true }
        if d3 == 0 && onSegment(p1, p2, p3) { return true }
        if d4 == 0 && onSegment(p1, p2, p4) { return true }
        
        return false
    }
    
    // MARK: - Helper Functions
    
    /// Returns the 4 edges of a quadrilateral as pairs of points
    private static func edges(of quad: [CGPoint]) -> [(CGPoint, CGPoint)] {
        guard quad.count == 4 else { return [] }
        return [
            (quad[0], quad[1]),
            (quad[1], quad[2]),
            (quad[2], quad[3]),
            (quad[3], quad[0])
        ]
    }
    
    /// Cross product direction: > 0 counter-clockwise, < 0 clockwise, = 0 collinear
    private static func direction(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> CGFloat {
        return (c.x - a.x) * (b.y - a.y) - (c.y - a.y) * (b.x - a.x)
    }
    
    /// Tests if point p is on segment (a, b), assuming they are collinear
    private static func onSegment(_ a: CGPoint, _ b: CGPoint, _ p: CGPoint) -> Bool {
        return min(a.x, b.x) <= p.x && p.x <= max(a.x, b.x) &&
               min(a.y, b.y) <= p.y && p.y <= max(a.y, b.y)
    }
}
