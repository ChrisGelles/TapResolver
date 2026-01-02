//
//  ZoneStore.swift
//  TapResolver
//
//  State management for Zone entities with persistence and triangle membership computation.
//

import Foundation
import Combine
import CoreGraphics

/// Manages Zone entities with persistence and triangle membership computation
public class ZoneStore: ObservableObject {
    @Published public var zones: [Zone] = []
    
    /// Counter for auto-generating zone names
    private var zoneNameCounter: Int = 1
    
    /// Dependencies for triangle membership computation
    private weak var mapPointStore: MapPointStore?
    private weak var triangleStore: TrianglePatchStore?
    
    /// Location-scoped UserDefaults key
    private var userDefaultsKey: String {
        let locationID = PersistenceContext.shared.locationID
        return "zones_\(locationID)"
    }
    
    // MARK: - Initialization
    
    public init() {
        // Dependencies injected later via configure()
    }
    
    /// Configure store with dependencies needed for triangle membership computation
    /// Call this after MapPointStore and TrianglePatchStore are initialized
    func configure(mapPointStore: MapPointStore, triangleStore: TrianglePatchStore) {
        self.mapPointStore = mapPointStore
        self.triangleStore = triangleStore
        print("✅ [ZoneStore] Configured with MapPointStore and TriangleStore dependencies")
    }
    
    // MARK: - CRUD Operations
    
    /// Create a new zone with the given corners
    /// - Parameters:
    ///   - name: Optional name (auto-generates "Zone N" if nil)
    ///   - cornerIDs: Array of 4 MapPoint UUIDs in CCW order
    /// - Returns: The created Zone
    @discardableResult
    public func createZone(name: String? = nil, cornerIDs: [UUID]) -> Zone {
        let zoneName = name ?? "Zone \(zoneNameCounter)"
        zoneNameCounter += 1
        
        var zone = Zone(
            name: zoneName,
            cornerIDs: cornerIDs
        )
        
        // Compute initial triangle membership
        zone.triangleIDs = computeTriangleMembership(for: zone)
        
        zones.append(zone)
        save()
        
        print("✅ [ZoneStore] Created zone '\(zoneName)' with \(cornerIDs.count) corners, \(zone.triangleIDs.count) triangles")
        return zone
    }
    
    /// Delete a zone by ID
    public func deleteZone(_ id: UUID) {
        guard let index = zones.firstIndex(where: { $0.id == id }) else {
            print("⚠️ [ZoneStore] Cannot delete: zone \(String(id.uuidString.prefix(8))) not found")
            return
        }
        let name = zones[index].name
        zones.remove(at: index)
        save()
        print("🗑️ [ZoneStore] Deleted zone '\(name)'")
    }
    
    /// Update an existing zone
    public func updateZone(_ zone: Zone) {
        guard let index = zones.firstIndex(where: { $0.id == zone.id }) else {
            print("⚠️ [ZoneStore] Cannot update: zone \(String(zone.id.uuidString.prefix(8))) not found")
            return
        }
        
        var updatedZone = zone
        updatedZone.modifiedAt = Date()
        
        // Recompute triangle membership if corners changed
        if zones[index].cornerIDs != zone.cornerIDs {
            updatedZone.triangleIDs = computeTriangleMembership(for: updatedZone)
            print("🔄 [ZoneStore] Recomputed triangle membership: \(updatedZone.triangleIDs.count) triangles")
        }
        
        zones[index] = updatedZone
        save()
        print("✅ [ZoneStore] Updated zone '\(updatedZone.name)'")
    }
    
    /// Update only the lastStartingCornerIndex for a zone
    public func updateLastStartingCornerIndex(zoneID: UUID, index: Int) {
        guard let zoneIndex = zones.firstIndex(where: { $0.id == zoneID }) else {
            print("⚠️ [ZoneStore] Cannot update starting index: zone \(String(zoneID.uuidString.prefix(8))) not found")
            return
        }
        
        zones[zoneIndex].lastStartingCornerIndex = index
        zones[zoneIndex].modifiedAt = Date()
        save()
        print("🔄 [ZoneStore] Updated lastStartingCornerIndex to \(index) for zone '\(zones[zoneIndex].name)'")
    }
    
    // MARK: - Queries
    
    /// Find zone by ID
    public func zone(withID id: UUID) -> Zone? {
        zones.first { $0.id == id }
    }
    
    /// Find all zones containing a specific corner MapPoint
    public func zones(containingCorner mapPointID: UUID) -> [Zone] {
        zones.filter { $0.cornerIDs.contains(mapPointID) }
    }
    
    /// Find all zones containing a specific triangle
    public func zones(containingTriangle triangleID: UUID) -> [Zone] {
        zones.filter { $0.triangleIDs.contains(triangleID) }
    }
    
    // MARK: - Triangle Membership
    
    /// Recompute triangle membership for a specific zone
    public func recomputeTriangleMembership(for zoneID: UUID) {
        guard let index = zones.firstIndex(where: { $0.id == zoneID }) else {
            print("⚠️ [ZoneStore] Cannot recompute: zone \(String(zoneID.uuidString.prefix(8))) not found")
            return
        }
        
        zones[index].triangleIDs = computeTriangleMembership(for: zones[index])
        zones[index].modifiedAt = Date()
        save()
        print("🔄 [ZoneStore] Recomputed membership for '\(zones[index].name)': \(zones[index].triangleIDs.count) triangles")
    }
    
    /// Recompute triangle membership for all zones
    /// Call this when triangles are added/removed/modified
    public func recomputeAllTriangleMembership() {
        print("🔄 [ZoneStore] Recomputing triangle membership for all \(zones.count) zones...")
        
        for index in zones.indices {
            zones[index].triangleIDs = computeTriangleMembership(for: zones[index])
            zones[index].modifiedAt = Date()
        }
        
        save()
        print("✅ [ZoneStore] Recomputed membership for all zones")
    }
    
    /// Compute which triangles have any area inside the zone
    /// Algorithm: Triangle is member if any vertex inside zone, any zone corner inside triangle,
    /// or any edge intersection occurs
    private func computeTriangleMembership(for zone: Zone) -> [UUID] {
        guard let mapPointStore = mapPointStore,
              let triangleStore = triangleStore else {
            print("⚠️ [ZoneStore] Cannot compute membership: missing dependencies")
            return []
        }
        
        guard zone.cornerIDs.count == 4 else {
            print("⚠️ [ZoneStore] Cannot compute membership: zone has \(zone.cornerIDs.count) corners, need 4")
            return []
        }
        
        // Get zone corner positions in 2D
        let zoneCorners: [CGPoint] = zone.cornerIDs.compactMap { cornerID in
            mapPointStore.points.first { $0.id == cornerID }?.mapPoint
        }
        
        guard zoneCorners.count == 4 else {
            print("⚠️ [ZoneStore] Cannot compute membership: only found \(zoneCorners.count) corner positions")
            return []
        }
        
        var memberTriangleIDs: [UUID] = []
        
        for triangle in triangleStore.triangles {
            // Get triangle vertex positions in 2D
            let triangleVertices: [CGPoint] = triangle.vertexIDs.compactMap { vertexID in
                mapPointStore.points.first { $0.id == vertexID }?.mapPoint
            }
            
            guard triangleVertices.count == 3 else { continue }
            
            if polygonsIntersect(polygon1: zoneCorners, polygon2: triangleVertices) {
                memberTriangleIDs.append(triangle.id)
            }
        }
        
        return memberTriangleIDs
    }
    
    // MARK: - Geometry Helpers
    
    /// Check if two convex polygons intersect (share any area)
    /// Uses separating axis theorem combined with point-in-polygon tests
    private func polygonsIntersect(polygon1: [CGPoint], polygon2: [CGPoint]) -> Bool {
        // Test 1: Any vertex of polygon2 inside polygon1
        for vertex in polygon2 {
            if pointInPolygon(point: vertex, polygon: polygon1) {
                return true
            }
        }
        
        // Test 2: Any vertex of polygon1 inside polygon2
        for vertex in polygon1 {
            if pointInPolygon(point: vertex, polygon: polygon2) {
                return true
            }
        }
        
        // Test 3: Any edge intersection
        let edges1 = polygonEdges(polygon1)
        let edges2 = polygonEdges(polygon2)
        
        for edge1 in edges1 {
            for edge2 in edges2 {
                if edgesIntersect(edge1.0, edge1.1, edge2.0, edge2.1) {
                    return true
                }
            }
        }
        
        return false
    }
    
    /// Point-in-polygon test using ray casting
    private func pointInPolygon(point: CGPoint, polygon: [CGPoint]) -> Bool {
        var inside = false
        var j = polygon.count - 1
        
        for i in 0..<polygon.count {
            let xi = polygon[i].x, yi = polygon[i].y
            let xj = polygon[j].x, yj = polygon[j].y
            
            if ((yi > point.y) != (yj > point.y)) &&
                (point.x < (xj - xi) * (point.y - yi) / (yj - yi) + xi) {
                inside = !inside
            }
            j = i
        }
        
        return inside
    }
    
    /// Get edges of a polygon as array of point pairs
    private func polygonEdges(_ polygon: [CGPoint]) -> [(CGPoint, CGPoint)] {
        var edges: [(CGPoint, CGPoint)] = []
        for i in 0..<polygon.count {
            let j = (i + 1) % polygon.count
            edges.append((polygon[i], polygon[j]))
        }
        return edges
    }
    
    /// Check if two line segments intersect
    private func edgesIntersect(_ a1: CGPoint, _ a2: CGPoint, _ b1: CGPoint, _ b2: CGPoint) -> Bool {
        let d1 = direction(b1, b2, a1)
        let d2 = direction(b1, b2, a2)
        let d3 = direction(a1, a2, b1)
        let d4 = direction(a1, a2, b2)
        
        if ((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
           ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0)) {
            return true
        }
        
        if d1 == 0 && onSegment(b1, b2, a1) { return true }
        if d2 == 0 && onSegment(b1, b2, a2) { return true }
        if d3 == 0 && onSegment(a1, a2, b1) { return true }
        if d4 == 0 && onSegment(a1, a2, b2) { return true }
        
        return false
    }
    
    /// Cross product for line segment intersection
    private func direction(_ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint) -> CGFloat {
        return (p3.x - p1.x) * (p2.y - p1.y) - (p2.x - p1.x) * (p3.y - p1.y)
    }
    
    /// Check if point is on segment
    private func onSegment(_ p1: CGPoint, _ p2: CGPoint, _ p: CGPoint) -> Bool {
        return min(p1.x, p2.x) <= p.x && p.x <= max(p1.x, p2.x) &&
               min(p1.y, p2.y) <= p.y && p.y <= max(p1.y, p2.y)
    }
    
    // MARK: - Persistence
    
    /// Save zones to UserDefaults
    public func save() {
        let dtos = zones.map { ZoneDTO(from: $0) }
        
        do {
            let data = try JSONEncoder().encode(dtos)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
            print("💾 [ZoneStore] Saved \(zones.count) zones to UserDefaults")
        } catch {
            print("❌ [ZoneStore] Failed to save: \(error)")
        }
    }
    
    /// Load zones from UserDefaults
    public func load() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            print("📂 [ZoneStore] No saved zones found for key '\(userDefaultsKey)'")
            zones = []
            updateNameCounter()
            return
        }
        
        do {
            let dtos = try JSONDecoder().decode([ZoneDTO].self, from: data)
            zones = dtos.compactMap { $0.toZone() }
            updateNameCounter()
            print("📂 [ZoneStore] Loaded \(zones.count) zones from UserDefaults")
        } catch {
            print("❌ [ZoneStore] Failed to load: \(error)")
            zones = []
        }
    }
    
    /// Update the name counter based on existing zones
    private func updateNameCounter() {
        // Find highest "Zone N" number and set counter to N+1
        let pattern = /^Zone (\d+)$/
        var maxNumber = 0
        
        for zone in zones {
            if let match = zone.name.firstMatch(of: pattern),
               let number = Int(match.1) {
                maxNumber = max(maxNumber, number)
            }
        }
        
        zoneNameCounter = maxNumber + 1
    }
    
    /// Clear all zones (for location switching)
    public func clearAll() {
        zones = []
        zoneNameCounter = 1
        print("🗑️ [ZoneStore] Cleared all zones")
    }
    
    /// Reload for active location (call when location changes)
    public func reloadForActiveLocation() {
        load()
    }
}

