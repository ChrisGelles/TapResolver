//
//  TrianglePatchStore.swift
//  TapResolver
//
//  Manages triangular calibration patches
//

import SwiftUI
import Combine
import CoreGraphics

class TrianglePatchStore: ObservableObject {
    @Published var triangles: [TrianglePatch] = []
    @Published var selectedTriangleID: UUID?
    
    // Triangle creation state
    @Published var isCreatingTriangle: Bool = false
    @Published var creationVertices: [UUID] = []  // 0-3 selected vertices
    
    private let persistenceKey = "triangles_v1"
    private let ctx = PersistenceContext.shared
    
    init() {
        load()
    }
    
    // MARK: - Triangle Creation
    
    func startCreatingTriangle() {
        isCreatingTriangle = true
        creationVertices = []
    }
    
    func cancelCreatingTriangle() {
        isCreatingTriangle = false
        creationVertices = []
    }
    
    /// Add vertex to creation list. Returns error if invalid.
    func addCreationVertex(_ pointID: UUID, mapPointStore: MapPointStore) -> String? {
        // Validate point has triangle-edge role
        guard let point = mapPointStore.points.first(where: { $0.id == pointID }) else {
            return "Point not found"
        }
        
        guard point.roles.contains(.triangleEdge) else {
            return "Point must have Triangle Edge role"
        }
        
        // Check not already selected
        guard !creationVertices.contains(pointID) else {
            return "Point already selected"
        }
        
        // Add to list
        creationVertices.append(pointID)
        
        // Auto-complete if 3 vertices selected
        if creationVertices.count == 3 {
            return finishCreatingTriangle(mapPointStore: mapPointStore)
        }
        
        return nil
    }
    
    /// Complete triangle creation with validation
    private func finishCreatingTriangle(mapPointStore: MapPointStore) -> String? {
        guard creationVertices.count == 3 else {
            return "Need exactly 3 vertices"
        }
        
        print("🔍 Attempting to create triangle with vertices: \(creationVertices.map { String($0.uuidString.prefix(8)) })")
        
        // Get vertex positions
        guard let positions = getVertexPositions(creationVertices, mapPointStore: mapPointStore) else {
            return "Cannot find vertex positions"
        }
        
        // Validate not collinear
        if areCollinear(positions[0], positions[1], positions[2]) {
            cancelCreatingTriangle()
            return "Points are collinear (form a line, not a triangle)"
        }
        
        // Validate no overlap with existing triangles
        if hasInteriorOverlap(with: creationVertices, mapPointStore: mapPointStore) {
            cancelCreatingTriangle()
            return "Triangle interiors overlap (edge-sharing is OK)"
        }
        
        // Create triangle
        let triangle = TrianglePatch(vertexIDs: creationVertices)
        triangles.append(triangle)
        
        print("✅ Created triangle \(String(triangle.id.uuidString.prefix(8))) with vertices: \(triangle.vertexIDs.map { String($0.uuidString.prefix(8)) })")
        
        // Update MapPoint memberships
        for vertexID in creationVertices {
            if let index = mapPointStore.points.firstIndex(where: { $0.id == vertexID }) {
                mapPointStore.points[index].triangleMemberships.append(triangle.id)
            }
        }
        
        mapPointStore.save()
        save()
        
        cancelCreatingTriangle()
        
        return nil
    }
    
    // MARK: - Triangle Management
    
    func deleteTriangle(_ triangleID: UUID, mapPointStore: MapPointStore) {
        guard let index = triangles.firstIndex(where: { $0.id == triangleID }) else { return }
        
        let triangle = triangles[index]
        
        // Remove from MapPoint memberships
        for vertexID in triangle.vertexIDs {
            if let pointIndex = mapPointStore.points.firstIndex(where: { $0.id == vertexID }) {
                mapPointStore.points[pointIndex].triangleMemberships.removeAll { $0 == triangleID }
            }
        }
        
        triangles.remove(at: index)
        
        mapPointStore.save()
        save()
        
        print("🗑️ Deleted triangle \(triangleID)")
    }
    
    // MARK: - Validation Helpers
    
    private func getVertexPositions(_ vertexIDs: [UUID], mapPointStore: MapPointStore) -> [CGPoint]? {
        var positions: [CGPoint] = []
        for id in vertexIDs {
            guard let point = mapPointStore.points.first(where: { $0.id == id }) else {
                return nil
            }
            positions.append(point.mapPoint)
        }
        return positions
    }
    
    private func areCollinear(_ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint, tolerance: CGFloat = 1.0) -> Bool {
        // Calculate area of triangle using cross product
        // If area is near zero, points are collinear
        let area = abs((p2.x - p1.x) * (p3.y - p1.y) - (p3.x - p1.x) * (p2.y - p1.y)) / 2
        return area < tolerance
    }
    
    // MARK: - Geometric Overlap Detection
    
    private func hasInteriorOverlap(with newVertices: [UUID], mapPointStore: MapPointStore) -> Bool {
        guard let newPositions = getVertexPositions(newVertices, mapPointStore: mapPointStore),
              newPositions.count == 3 else {
            print("❌ Cannot get positions for new vertices")
            return false
        }
        
        print("🔍 Checking new triangle with vertices: \(newVertices.map { String($0.uuidString.prefix(8)) })")
        
        for triangle in triangles {
            guard let existingPositions = getVertexPositions(triangle.vertexIDs, mapPointStore: mapPointStore),
                  existingPositions.count == 3 else {
                print("⚠️ Cannot get positions for existing triangle \(String(triangle.id.uuidString.prefix(8)))")
                continue
            }
            
            // Count shared vertices
            let sharedVertices = Set(triangle.vertexIDs).intersection(Set(newVertices))
            let sharedCount = sharedVertices.count
            
            print("   vs existing triangle \(String(triangle.id.uuidString.prefix(8)))")
            print("      Existing vertices: \(triangle.vertexIDs.map { String($0.uuidString.prefix(8)) })")
            print("      Shared vertices: \(sharedCount) - \(sharedVertices.map { String($0.uuidString.prefix(8)) })")
            
            // Duplicate triangle (all 3 vertices shared)
            if sharedCount == 3 {
                print("      ❌ REJECT: Duplicate triangle")
                return true
            }
            
            // Edge sharing (2 vertices shared) is OK - proper tessellation
            if sharedCount == 2 {
                print("      ✅ ALLOW: Edge sharing (2 vertices)")
                continue
            }
            
            // 0 or 1 shared vertices - check for geometric intersection
            print("      🔍 Checking geometric intersection (\(sharedCount) shared)")
            // ✅ Build set of shared vertex positions
            var sharedPositions = Set<CGPoint>()
            for sharedID in sharedVertices {
                if let pos = getVertexPositions([sharedID], mapPointStore: mapPointStore)?.first {
                    sharedPositions.insert(pos)
                }
            }
            if trianglesIntersect(newPositions, existingPositions, sharedVertexPositions: sharedPositions) {
                print("      ❌ REJECT: Geometric overlap detected")
                return true
            }
            
            print("      ✅ No overlap")
        }
        
        print("✅ No overlap with any existing triangles")
        return false
    }
    
    /// Check if two triangles have overlapping interiors
    private func trianglesIntersect(_ tri1: [CGPoint], _ tri2: [CGPoint], sharedVertexPositions: Set<CGPoint> = []) -> Bool {
        guard tri1.count == 3, tri2.count == 3 else { return false }
        
        // Check if any vertex of tri1 (excluding shared vertices) is inside tri2
        for point in tri1 {
            if !sharedVertexPositions.contains(point) && pointInTriangle(point, tri2) {
                return true
            }
        }
        
        // Check if any vertex of tri2 (excluding shared vertices) is inside tri1
        for point in tri2 {
            if !sharedVertexPositions.contains(point) && pointInTriangle(point, tri1) {
                return true
            }
        }
        
        // Check if any edges intersect
        for i in 0..<3 {
            let a1 = tri1[i]
            let a2 = tri1[(i + 1) % 3]
            
            for j in 0..<3 {
                let b1 = tri2[j]
                let b2 = tri2[(j + 1) % 3]
                
                if edgesIntersect(a1, a2, b1, b2) {
                    return true
                }
            }
        }
        
        return false
    }
    
    /// Check if point p is inside triangle defined by vertices
    private func pointInTriangle(_ p: CGPoint, _ vertices: [CGPoint]) -> Bool {
        guard vertices.count == 3 else { return false }
        
        let v0 = vertices[0]
        let v1 = vertices[1]
        let v2 = vertices[2]
        
        // Barycentric coordinate method
        let denom = (v1.y - v2.y) * (v0.x - v2.x) + (v2.x - v1.x) * (v0.y - v2.y)
        guard abs(denom) > 0.0001 else { return false }
        
        let a = ((v1.y - v2.y) * (p.x - v2.x) + (v2.x - v1.x) * (p.y - v2.y)) / denom
        let b = ((v2.y - v0.y) * (p.x - v2.x) + (v0.x - v2.x) * (p.y - v2.y)) / denom
        let c = 1 - a - b
        
        // Point is inside if all barycentric coordinates are positive (with small epsilon)
        let epsilon: CGFloat = -0.0001
        return a >= epsilon && b >= epsilon && c >= epsilon
    }
    
    /// Check if two line segments intersect (not just touch at endpoints)
    private func edgesIntersect(_ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint, _ p4: CGPoint) -> Bool {
        // Check if segments share an endpoint (that's OK for edge-sharing)
        if p1 == p3 || p1 == p4 || p2 == p3 || p2 == p4 {
            return false
        }
        
        // Cross product to determine orientation
        func ccw(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> CGFloat {
            return (c.y - a.y) * (b.x - a.x) - (b.y - a.y) * (c.x - a.x)
        }
        
        let d1 = ccw(p3, p4, p1)
        let d2 = ccw(p3, p4, p2)
        let d3 = ccw(p1, p2, p3)
        let d4 = ccw(p1, p2, p4)
        
        // Segments intersect if they straddle each other
        if ((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
           ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0)) {
            return true
        }
        
        return false
    }
    
    // MARK: - Persistence
    
    func save() {
        ctx.write(persistenceKey, value: triangles)
        print("💾 Saved \(triangles.count) triangle(s)")
    }
    
    func load() {
        guard let decoded: [TrianglePatch] = ctx.read(persistenceKey, as: [TrianglePatch].self) else {
            print("📂 No saved triangles found")
            return
        }
        
        triangles = decoded
        print("📂 Loaded \(triangles.count) triangle(s)")
    }
}

