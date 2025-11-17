//
//  TrianglePatchStore.swift
//  TapResolver
//
//  Manages triangular calibration patches
//

import SwiftUI
import Combine
import CoreGraphics
import simd

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
    
    // MARK: - Adjacent Triangle Discovery
    
    /// Find triangles that share an edge (2 vertices) with the given triangle
    func findAdjacentTriangles(_ triangleID: UUID) -> [TrianglePatch] {
        guard let sourceTriangle = triangles.first(where: { $0.id == triangleID }) else {
            return []
        }
        
        let sourceVertexSet = Set(sourceTriangle.vertexIDs)
        
        return triangles.filter { candidate in
            guard candidate.id != triangleID else { return false }
            
            let candidateVertexSet = Set(candidate.vertexIDs)
            let sharedCount = sourceVertexSet.intersection(candidateVertexSet).count
            
            // Adjacent triangles share exactly 2 vertices (an edge)
            return sharedCount == 2
        }
    }
    
    /// Get the "far vertex" of an adjacent triangle (the vertex not shared with source triangle)
    func getFarVertex(adjacentTriangle: TrianglePatch, sourceTriangle: TrianglePatch) -> UUID? {
        let sourceVertexSet = Set(sourceTriangle.vertexIDs)
        let uniqueVertices = adjacentTriangle.vertexIDs.filter { !sourceVertexSet.contains($0) }
        return uniqueVertices.first
    }
    
    // MARK: - Map Point Population
    
    /// Project ALL map points into AR space using calibrated triangle
    // TODO: Re-enable after Phase 4 coordinator integration
    func populateAllMapPointMarkers(
        calibratedTriangle: TrianglePatch,
        mapPointStore: MapPointStore,
        arCoordinator: Any // ARViewContainer.Coordinator - temporarily Any until Phase 4
    ) {
        // TODO: Re-implement after Phase 4 coordinator is integrated
        print("⚠️ populateAllMapPointMarkers temporarily disabled during refactor")
        return
        
        /* Original implementation - will be restored in Phase 4
        guard calibratedTriangle.isCalibrated else {
            print("⚠️ Triangle not calibrated")
            return
        }
        
        guard calibratedTriangle.arMarkerIDs.count == 3 else {
            print("⚠️ Need 3 AR marker IDs")
            return
        }
        
        print("🔴 Populating AR markers for ALL map points...")
        
        // Get the 3 calibration point positions (2D map + 3D AR)
        var calibrationPairs: [(mapPoint: CGPoint, arPosition: simd_float3)] = []
        
        for (index, vertexID) in calibratedTriangle.vertexIDs.enumerated() {
            guard let mapPoint = mapPointStore.points.first(where: { $0.id == vertexID }),
                  let markerIDString = calibratedTriangle.arMarkerIDs[safe: index],
                  let markerUUID = UUID(uuidString: markerIDString),
                  let markerNode = arCoordinator.calibrationMarkerNodes[markerUUID] else {
                print("⚠️ Cannot get calibration data for vertex \(index)")
                return
            }
            
            let arPosition = markerNode.simdPosition
            calibrationPairs.append((mapPoint: mapPoint.mapPoint, arPosition: arPosition))
        }
        
        guard calibrationPairs.count == 3 else {
            print("⚠️ Need 3 calibration pairs")
            return
        }
        
        print("✅ Got 3 calibration pairs")
        print("   Pair 1: Map(\(Int(calibrationPairs[0].mapPoint.x)),\(Int(calibrationPairs[0].mapPoint.y))) → AR\(calibrationPairs[0].arPosition)")
        print("   Pair 2: Map(\(Int(calibrationPairs[1].mapPoint.x)),\(Int(calibrationPairs[1].mapPoint.y))) → AR\(calibrationPairs[1].arPosition)")
        print("   Pair 3: Map(\(Int(calibrationPairs[2].mapPoint.x)),\(Int(calibrationPairs[2].mapPoint.y))) → AR\(calibrationPairs[2].arPosition)")
        
        // Project ALL map points
        var createdCount = 0
        let calibratedVertexIDs = Set(calibratedTriangle.vertexIDs)
        
        for mapPoint in mapPointStore.points {
            // Skip calibration markers (they're already orange)
            if calibratedVertexIDs.contains(mapPoint.id) {
                continue
            }
            
            // Project this map point into AR space using barycentric coordinates
            let projectedPosition = projectMapPointToAR(
                mapPoint: mapPoint.mapPoint,
                calibrationPairs: calibrationPairs
            )
            
            // Create AR marker with RED sphere
            let virtualMarkerID = UUID()
            let virtualNode = arCoordinator.createARMarkerNode(
                at: projectedPosition,
                sphereColor: .systemRed,  // Red for all projected markers
                markerID: virtualMarkerID,
                userHeight: arCoordinator.userHeight,
                badgeColor: nil
            )
            
            virtualNode.opacity = 1.0  // Full opacity
            
            // Add to scene
            arCoordinator.arView?.scene.rootNode.addChildNode(virtualNode)
            
            // Store in ghost markers (session-temporary)
            arCoordinator.ghostMarkerNodes[virtualMarkerID] = virtualNode
            
            createdCount += 1
        }
        
        print("✅ Created \(createdCount) AR markers (red spheres) for all map points")
        */
    }
    
    /// Project a 2D map point into 3D AR space using barycentric interpolation
    private func projectMapPointToAR(
        mapPoint: CGPoint,
        calibrationPairs: [(mapPoint: CGPoint, arPosition: simd_float3)]
    ) -> simd_float3 {
        let p0 = calibrationPairs[0].mapPoint
        let p1 = calibrationPairs[1].mapPoint
        let p2 = calibrationPairs[2].mapPoint
        
        // Calculate barycentric coordinates
        let denom = (p1.y - p2.y) * (p0.x - p2.x) + (p2.x - p1.x) * (p0.y - p2.y)
        
        guard abs(denom) > 0.0001 else {
            // Degenerate triangle - return average
            let avg = (calibrationPairs[0].arPosition + 
                       calibrationPairs[1].arPosition + 
                       calibrationPairs[2].arPosition) / 3
            return avg
        }
        
        let w0 = ((p1.y - p2.y) * (mapPoint.x - p2.x) + (p2.x - p1.x) * (mapPoint.y - p2.y)) / denom
        let w1 = ((p2.y - p0.y) * (mapPoint.x - p2.x) + (p0.x - p2.x) * (mapPoint.y - p2.y)) / denom
        let w2 = 1 - w0 - w1
        
        // Apply same weights to AR positions
        let ar0 = calibrationPairs[0].arPosition
        let ar1 = calibrationPairs[1].arPosition
        let ar2 = calibrationPairs[2].arPosition
        
        let projected = Float(w0) * ar0 + Float(w1) * ar1 + Float(w2) * ar2
        
        return projected
    }
    
    // MARK: - Phase 4 Coordinator Helpers
    
    /// Find a triangle by its ID
    func triangle(withID id: UUID) -> TrianglePatch? {
        triangles.first(where: { $0.id == id })
    }
    
    /// Add an AR marker ID to a triangle's vertex
    func addMarker(mapPointID: UUID, markerID: UUID) {
        print("🔍 [ADD_MARKER_TRACE] Called with:")
        print("   mapPointID: \(String(mapPointID.uuidString.prefix(8)))")
        print("   markerID: \(String(markerID.uuidString.prefix(8)))")
        
        guard let index = triangles.firstIndex(where: { $0.vertexIDs.contains(mapPointID) }) else {
            print("⚠️ [ADD_MARKER_TRACE] Cannot add marker: No triangle found with vertex \(String(mapPointID.uuidString.prefix(8)))")
            return
        }
        
        print("🔍 [ADD_MARKER_TRACE] Triangle found at index \(index):")
        print("   Triangle ID: \(String(triangles[index].id.uuidString.prefix(8)))")
        print("   Current arMarkerIDs: \(triangles[index].arMarkerIDs)")
        print("   Current arMarkerIDs.count: \(triangles[index].arMarkerIDs.count)")
        
        let markerIDString = markerID.uuidString
        if !triangles[index].arMarkerIDs.contains(markerIDString) {
            // Find the index of the vertex in the triangle
            if let vertexIndex = triangles[index].vertexIDs.firstIndex(of: mapPointID) {
                print("🔍 [ADD_MARKER_TRACE] Found vertex at index \(vertexIndex)")
                
                // Ensure arMarkerIDs array has enough elements
                while triangles[index].arMarkerIDs.count <= vertexIndex {
                    triangles[index].arMarkerIDs.append("")
                    print("🔍 [ADD_MARKER_TRACE] Expanded arMarkerIDs array to \(triangles[index].arMarkerIDs.count) slots")
                }
                
                let oldValue = triangles[index].arMarkerIDs[vertexIndex]
                triangles[index].arMarkerIDs[vertexIndex] = markerIDString
                print("🔍 [ADD_MARKER_TRACE] Set arMarkerIDs[\(vertexIndex)]:")
                print("   Old value: '\(oldValue)'")
                print("   New value: '\(markerIDString)'")
                print("   Updated arMarkerIDs: \(triangles[index].arMarkerIDs)")
                
                save()
                print("✅ [ADD_MARKER_TRACE] Saved triangles to storage")
                print("✅ Added marker \(String(markerIDString.prefix(8))) to triangle vertex \(vertexIndex)")
            } else {
                print("⚠️ [ADD_MARKER_TRACE] Could not find vertex index for mapPointID \(String(mapPointID.uuidString.prefix(8)))")
            }
        } else {
            print("⚠️ [ADD_MARKER_TRACE] Marker \(String(markerIDString.prefix(8))) already exists in triangle")
        }
    }
    
    /// Mark a triangle as calibrated with quality score
    func markCalibrated(_ id: UUID, quality: Float) {
        guard let index = triangles.firstIndex(where: { $0.id == id }) else {
            print("⚠️ Cannot mark calibrated: Triangle \(String(id.uuidString.prefix(8))) not found")
            return
        }
        
        triangles[index].isCalibrated = true
        triangles[index].calibrationQuality = quality
        triangles[index].lastCalibratedAt = Date()
        save()
        
        print("✅ Marked triangle \(String(id.uuidString.prefix(8))) as calibrated (quality: \(Int(quality * 100))%)")
    }
    
    /// Set leg measurements for a triangle
    func setLegMeasurements(for triangleID: UUID, measurements: [TriangleLegMeasurement]) {
        guard let index = triangles.firstIndex(where: { $0.id == triangleID }) else {
            print("⚠️ Cannot set leg measurements: Triangle \(String(triangleID.uuidString.prefix(8))) not found")
            return
        }
        
        triangles[index].legMeasurements = measurements
        save()
        
        print("✅ Set \(measurements.count) leg measurements for triangle \(String(triangleID.uuidString.prefix(8)))")
    }
    
    func setWorldMapFilename(for triangleID: UUID, filename: String) {
        guard let index = triangles.firstIndex(where: { $0.id == triangleID }) else {
            print("⚠️ Cannot set world map filename: Triangle \(String(triangleID.uuidString.prefix(8))) not found")
            return
        }
        
        triangles[index].worldMapFilename = filename
        save()
        
        print("✅ Set world map filename '\(filename)' for triangle \(String(triangleID.uuidString.prefix(8)))")
    }
    
    /// Set world map filename for a specific strategy (multi-strategy support)
    func setWorldMapFilename(for triangleID: UUID, strategyName: String, filename: String) {
        guard let index = triangles.firstIndex(where: { $0.id == triangleID }) else {
            print("⚠️ Cannot set world map filename: Triangle \(String(triangleID.uuidString.prefix(8))) not found")
            return
        }
        
        triangles[index].worldMapFilesByStrategy[strategyName] = filename
        save()
        
        print("✅ Set world map filename '\(filename)' for strategy '\(strategyName)' on triangle \(String(triangleID.uuidString.prefix(8)))")
    }
    
    // MARK: - Persistence
    
    func save() {
        ctx.write(persistenceKey, value: triangles)
        print("💾 Saved \(triangles.count) triangle(s)")
        
        // Log detailed triangle data
        for triangle in triangles {
            print("💾 Saving Triangle \(String(triangle.id.uuidString.prefix(8))):")
            print("   Vertices: \(triangle.vertexIDs.map { String($0.uuidString.prefix(8)) })")
            print("   AR Markers: \(triangle.arMarkerIDs.map { String($0.prefix(8)) })")
            print("   Calibrated: \(triangle.isCalibrated)")
            print("   Quality: \(Int(triangle.calibrationQuality * 100))%")
        }
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

