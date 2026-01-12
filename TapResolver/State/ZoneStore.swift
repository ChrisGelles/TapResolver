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
    
    /// Currently selected zone for calibration (nil = none selected)
    @Published public var selectedZoneID: String?
    
    /// Visibility toggle for zone overlays
    @Published public var zonesVisible: Bool = true
    
    // MARK: - Zone Creation State
    // UNIFICATION CANDIDATE: These properties mirror TrianglePatchStore.isCreatingTriangle 
    // and TrianglePatchStore.creationVertices. Consider extracting a shared CreationModeCoordinator.
    
    /// Flag indicating zone creation mode is active
    @Published public var isCreatingZone: Bool = false
    
    /// Corners selected so far during zone creation (0-4 MapPoint ID strings)
    @Published public var creationCorners: [String] = []
    
    /// Counter for auto-generating zone names
    private var zoneNameCounter: Int = 1
    
    /// Dependencies for triangle membership computation
    private weak var mapPointStore: MapPointStore?
    private weak var triangleStore: TrianglePatchStore?
    
    /// Location-scoped UserDefaults key (v2 format)
    private var userDefaultsKey: String {
        let locationID = PersistenceContext.shared.locationID
        return "Zones_v2_\(locationID)"
    }
    
    /// Legacy v1 key for migration check
    private var legacyUserDefaultsKey: String {
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
    ///   - id: Optional ID (auto-generates UUID string if nil)
    ///   - displayName: Optional name (auto-generates "Zone N" if nil)
    ///   - cornerMapPointIDs: Array of 4 MapPoint ID strings in CCW order
    ///   - groupID: Optional group membership
    /// - Returns: The created Zone
    @discardableResult
    public func createZone(
        id: String? = nil,
        displayName: String? = nil,
        cornerMapPointIDs: [String],
        groupID: String? = nil
    ) -> Zone {
        let zoneID = id ?? UUID().uuidString
        let zoneName = displayName ?? "Zone \(zoneNameCounter)"
        zoneNameCounter += 1
        
        var zone = Zone(
            id: zoneID,
            displayName: zoneName,
            cornerMapPointIDs: cornerMapPointIDs,
            groupID: groupID
        )
        
        // Compute initial triangle membership
        zone.memberTriangleIDs = computeTriangleMembership(for: zone)
        
        zones.append(zone)
        save()
        
        print("✅ [ZoneStore] Created zone '\(zoneName)' with \(cornerMapPointIDs.count) corners, \(zone.memberTriangleIDs.count) triangles")
        return zone
    }
    
    /// Delete a zone by ID
    public func deleteZone(_ id: String) {
        guard let index = zones.firstIndex(where: { $0.id == id }) else {
            print("⚠️ [ZoneStore] Cannot delete: zone \(String(id.prefix(8))) not found")
            return
        }
        let name = zones[index].displayName
        zones.remove(at: index)
        save()
        print("🗑️ [ZoneStore] Deleted zone '\(name)'")
    }
    
    /// Update an existing zone
    public func updateZone(_ zone: Zone) {
        guard let index = zones.firstIndex(where: { $0.id == zone.id }) else {
            print("⚠️ [ZoneStore] Cannot update: zone \(String(zone.id.prefix(8))) not found")
            return
        }
        
        var updatedZone = zone
        updatedZone.modifiedAt = Date()
        
        // Recompute triangle membership if corners changed
        if zones[index].cornerMapPointIDs != zone.cornerMapPointIDs {
            updatedZone.memberTriangleIDs = computeTriangleMembership(for: updatedZone)
            print("🔄 [ZoneStore] Recomputed triangle membership: \(updatedZone.memberTriangleIDs.count) triangles")
        }
        
        zones[index] = updatedZone
        save()
        print("✅ [ZoneStore] Updated zone '\(updatedZone.displayName)'")
    }
    
    /// Update only the lastStartingCornerIndex for a zone
    public func updateLastStartingCornerIndex(zoneID: String, index: Int) {
        guard let zoneIndex = zones.firstIndex(where: { $0.id == zoneID }) else {
            print("⚠️ [ZoneStore] Cannot update starting index: zone \(String(zoneID.prefix(8))) not found")
            return
        }
        
        zones[zoneIndex].lastStartingCornerIndex = index
        zones[zoneIndex].modifiedAt = Date()
        save()
        print("🔄 [ZoneStore] Updated lastStartingCornerIndex to \(index) for zone '\(zones[zoneIndex].displayName)'")
    }
    
    /// Select a zone for calibration
    func selectZone(_ zoneID: String?) {
        selectedZoneID = zoneID
        if let id = zoneID, let zone = zone(withID: id) {
            print("🔷 [ZoneStore] Selected zone: '\(zone.displayName)'")
        } else {
            print("🔷 [ZoneStore] Deselected zone")
        }
    }
    
    /// Toggle the lock state of a zone
    func toggleLock(zoneID: String) {
        guard let index = zones.firstIndex(where: { $0.id == zoneID }) else {
            print("⚠️ [ZoneStore] Cannot toggle lock: zone not found")
            return
        }
        
        zones[index].isLocked.toggle()
        zones[index].modifiedAt = Date()
        save()
        print("🔒 [ZoneStore] Zone '\(zones[index].displayName)' \(zones[index].isLocked ? "locked" : "unlocked")")
    }
    
    /// Rename a zone
    func renameZone(zoneID: String, newName: String) {
        guard let index = zones.firstIndex(where: { $0.id == zoneID }) else {
            print("⚠️ [ZoneStore] Cannot rename: zone not found")
            return
        }
        
        let oldName = zones[index].displayName
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            print("⚠️ [ZoneStore] Cannot rename: new name is empty")
            return
        }
        
        zones[index].displayName = trimmedName
        zones[index].modifiedAt = Date()
        save()
        print("✏️ [ZoneStore] Renamed zone '\(oldName)' → '\(trimmedName)'")
    }
    
    // MARK: - Queries
    
    /// Find zone by ID
    public func zone(withID id: String) -> Zone? {
        zones.first { $0.id == id }
    }
    
    /// Find all zones containing a specific corner MapPoint
    public func zones(containingCorner mapPointID: String) -> [Zone] {
        zones.filter { $0.cornerMapPointIDs.contains(mapPointID) }
    }
    
    /// Find all zones containing a specific triangle
    public func zones(containingTriangle triangleID: String) -> [Zone] {
        zones.filter { $0.memberTriangleIDs.contains(triangleID) }
    }
    
    // MARK: - Triangle Membership
    
    /// Recompute triangle membership for a specific zone
    public func recomputeTriangleMembership(for zoneID: String) {
        guard let index = zones.firstIndex(where: { $0.id == zoneID }) else {
            print("⚠️ [ZoneStore] Cannot recompute: zone \(String(zoneID.prefix(8))) not found")
            return
        }
        
        zones[index].memberTriangleIDs = computeTriangleMembership(for: zones[index])
        zones[index].modifiedAt = Date()
        save()
        print("🔄 [ZoneStore] Recomputed membership for '\(zones[index].displayName)': \(zones[index].memberTriangleIDs.count) triangles")
    }
    
    /// Recompute triangle membership for all zones
    /// Call this when triangles are added/removed/modified
    public func recomputeAllTriangleMembership() {
        print("🔄 [ZoneStore] Recomputing triangle membership for all \(zones.count) zones...")
        
        for index in zones.indices {
            zones[index].memberTriangleIDs = computeTriangleMembership(for: zones[index])
            zones[index].modifiedAt = Date()
        }
        
        save()
        print("✅ [ZoneStore] Recomputed membership for all zones")
    }
    
    /// Compute which triangles have any area inside the zone
    /// Algorithm: Triangle is member if any vertex inside zone, any zone corner inside triangle,
    /// or any edge intersection occurs
    private func computeTriangleMembership(for zone: Zone) -> [String] {
        guard let mapPointStore = mapPointStore,
              let triangleStore = triangleStore else {
            print("⚠️ [ZoneStore] Cannot compute membership: missing dependencies")
            return []
        }
        
        guard zone.cornerMapPointIDs.count == 4 else {
            print("⚠️ [ZoneStore] Cannot compute membership: zone has \(zone.cornerMapPointIDs.count) corners, need 4")
            return []
        }
        
        // Get zone corner positions in 2D
        let zoneCorners: [CGPoint] = zone.cornerMapPointIDs.compactMap { cornerIDString in
            guard let cornerID = UUID(uuidString: cornerIDString) else { return nil }
            return mapPointStore.points.first { $0.id == cornerID }?.mapPoint
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
        
        return memberTriangleIDs.map { $0.uuidString }
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
        // Check for and remove legacy v1 data
        if UserDefaults.standard.data(forKey: legacyUserDefaultsKey) != nil {
            UserDefaults.standard.removeObject(forKey: legacyUserDefaultsKey)
            print("🗑️ [ZoneStore] Deleted legacy v1 zones (fresh start for v2)")
        }
        
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            print("📂 [ZoneStore] No saved zones found for key '\(userDefaultsKey)'")
            zones = []
            updateNameCounter()
            return
        }
        
        do {
            let dtos = try JSONDecoder().decode([ZoneDTO].self, from: data)
            zones = dtos.map { $0.toZone() }
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
            if let match = zone.displayName.firstMatch(of: pattern),
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
    
    /// Purge all zones from memory AND UserDefaults (destructive)
    public func purgeAll() {
        let count = zones.count
        zones = []
        zoneNameCounter = 1
        selectedZoneID = nil
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        print("🗑️ [ZoneStore] Purged \(count) zones from memory and UserDefaults")
    }
    
    /// Reload for active location (call when location changes)
    public func reloadForActiveLocation() {
        load()
    }
    
    // MARK: - Zone Creation Methods
    // UNIFICATION CANDIDATE: These methods mirror TrianglePatchStore's triangle creation methods.
    // Consider extracting shared logic into a CreationModeCoordinator protocol or base class.
    
    /// Begin zone creation mode
    /// UNIFICATION CANDIDATE: Mirrors TrianglePatchStore.startCreatingTriangle()
    func startCreatingZone() {
        isCreatingZone = true
        creationCorners = []
        print("🔷 [ZoneStore] Started zone creation mode")
    }
    
    /// Cancel zone creation mode without creating a zone
    /// UNIFICATION CANDIDATE: Mirrors TrianglePatchStore.cancelCreatingTriangle()
    func cancelCreatingZone() {
        isCreatingZone = false
        creationCorners = []
        print("🔷 [ZoneStore] Cancelled zone creation")
    }
    
    /// Add a corner during zone creation
    /// - Parameters:
    ///   - pointID: The MapPoint UUID to add as a corner
    ///   - mapPointStore: Reference to MapPointStore for validation
    /// - Returns: Bool indicating success
    /// UNIFICATION CANDIDATE: Mirrors TrianglePatchStore.addCreationVertex(_:mapPointStore:)
    @discardableResult
    func addCreationCorner(_ pointID: UUID, mapPointStore: MapPointStore) -> Bool {
        let pointIDString = pointID.uuidString
        
        // Validate point exists
        guard let point = mapPointStore.points.first(where: { $0.id == pointID }) else {
            print("⚠️ [ZoneStore] Cannot add corner: MapPoint \(String(pointIDString.prefix(8))) not found")
            return false
        }
        
        // Validate role (must be zoneCorner)
        guard point.roles.contains(.zoneCorner) else {
            print("⚠️ [ZoneStore] Cannot add corner: MapPoint \(String(pointIDString.prefix(8))) is not a Zone Corner")
            return false
        }
        
        // Validate not already selected
        guard !creationCorners.contains(pointIDString) else {
            print("⚠️ [ZoneStore] Cannot add corner: MapPoint \(String(pointIDString.prefix(8))) already selected")
            return false
        }
        
        // Add corner
        creationCorners.append(pointIDString)
        print("🔷 [ZoneStore] Added corner \(creationCorners.count)/4: \(String(pointIDString.prefix(8)))")
        
        // Auto-finish when 4 corners selected
        if creationCorners.count == 4 {
            finishCreatingZone(mapPointStore: mapPointStore)
        }
        
        return true
    }
    
    /// Complete zone creation with the 4 selected corners
    /// - Parameter mapPointStore: Reference to MapPointStore for position lookups
    /// UNIFICATION CANDIDATE: Mirrors TrianglePatchStore.finishCreatingTriangle(mapPointStore:)
    private func finishCreatingZone(mapPointStore: MapPointStore) {
        guard creationCorners.count == 4 else {
            print("⚠️ [ZoneStore] Cannot finish: need 4 corners, have \(creationCorners.count)")
            cancelCreatingZone()
            return
        }
        
        // Get corner positions for validation
        let cornerPositions: [CGPoint] = creationCorners.compactMap { cornerIDString in
            guard let cornerID = UUID(uuidString: cornerIDString) else { return nil }
            return mapPointStore.points.first { $0.id == cornerID }?.mapPoint
        }
        
        guard cornerPositions.count == 4 else {
            print("⚠️ [ZoneStore] Cannot finish: could not find all corner positions")
            cancelCreatingZone()
            return
        }
        
        // Validate quad is not self-intersecting
        if isQuadSelfIntersecting(cornerPositions) {
            print("⚠️ [ZoneStore] Cannot finish: quad is self-intersecting. Select corners in CCW order.")
            // Don't cancel - let user try again by removing last corner (future improvement)
            // For now, cancel and they can restart
            cancelCreatingZone()
            return
        }
        
        // Create the zone
        let zone = createZone(cornerMapPointIDs: creationCorners)
        print("✅ [ZoneStore] Created zone '\(zone.displayName)' with \(zone.memberTriangleIDs.count) member triangles")
        
        // Reset creation state
        isCreatingZone = false
        creationCorners = []
    }
    
    /// Check if a quadrilateral is self-intersecting
    /// - Parameter corners: 4 corner positions in order
    /// - Returns: true if any non-adjacent edges cross
    private func isQuadSelfIntersecting(_ corners: [CGPoint]) -> Bool {
        guard corners.count == 4 else { return true }
        
        // Check if edge 0-1 intersects edge 2-3
        if edgesIntersect(corners[0], corners[1], corners[2], corners[3]) {
            return true
        }
        
        // Check if edge 1-2 intersects edge 3-0
        if edgesIntersect(corners[1], corners[2], corners[3], corners[0]) {
            return true
        }
        
        return false
    }
}

