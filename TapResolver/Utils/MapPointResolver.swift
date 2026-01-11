//
//  MapPointResolver.swift
//  TapResolver
//
//  Resolves raw coordinates to MapPoints with batch deduplication.
//  Used during SVG import to avoid creating duplicate points at shared corners.
//

import Foundation
import CoreGraphics

/// Resolves raw pixel coordinates to MapPoint IDs, handling deduplication
/// within a batch and matching to existing MapPoints.
public class MapPointResolver {
    
    // MARK: - Dependencies
    
    private let mapPointStore: MapPointStore
    private let thresholdPixels: CGFloat
    
    // MARK: - Batch State
    
    /// Points resolved during this batch, keyed by quantized position
    /// Using quantized keys to handle floating-point comparison
    private var batchResolved: [String: UUID] = [:]
    
    /// New MapPoints created during this batch (not yet saved)
    private var pendingPoints: [MapPointStore.MapPoint] = []
    
    // MARK: - Initialization
    
    /// Initialize resolver with dependencies
    /// - Parameters:
    ///   - mapPointStore: The store to query for existing points and create new ones
    ///   - thresholdPixels: Distance threshold in pixels for considering points identical
    public init(mapPointStore: MapPointStore, thresholdPixels: CGFloat) {
        self.mapPointStore = mapPointStore
        self.thresholdPixels = thresholdPixels
    }
    
    /// Convenience initializer with threshold in meters
    /// - Parameters:
    ///   - mapPointStore: The store to query for existing points
    ///   - thresholdMeters: Distance threshold in meters
    ///   - pixelsPerMeter: Conversion factor from the location's MetricSquare
    public convenience init(mapPointStore: MapPointStore, thresholdMeters: Float, pixelsPerMeter: CGFloat) {
        let thresholdPixels = CGFloat(thresholdMeters) * pixelsPerMeter
        self.init(mapPointStore: mapPointStore, thresholdPixels: thresholdPixels)
    }
    
    // MARK: - Resolution
    
    /// Resolve a single coordinate to a MapPoint ID
    /// - Parameters:
    ///   - position: Raw pixel coordinate
    ///   - roles: Roles to assign if creating a new point or add to existing
    /// - Returns: The UUID of the resolved (existing or new) MapPoint
    public func resolve(_ position: CGPoint, roles: Set<MapPointRole> = [.zoneCorner]) -> UUID {
        let positionKey = quantizedKey(for: position)
        
        // 1. Check if we already resolved this position in the current batch
        if let existingID = batchResolved[positionKey] {
            print("🔄 [MapPointResolver] Batch hit for (\(Int(position.x)), \(Int(position.y)))")
            return existingID
        }
        
        // 2. Check for nearby point in batch (within threshold but different quantized key)
        for (_, pointID) in batchResolved {
            if let point = pendingPoints.first(where: { $0.id == pointID }) ?? 
                          mapPointStore.points.first(where: { $0.id == pointID }) {
                let distance = distanceBetween(position, point.position)
                if distance < thresholdPixels {
                    batchResolved[positionKey] = pointID
                    print("🔄 [MapPointResolver] Batch proximity match for (\(Int(position.x)), \(Int(position.y))) → \(String(pointID.uuidString.prefix(8)))")
                    return pointID
                }
            }
        }
        
        // 3. Check existing MapPoints in store
        if let existingPoint = mapPointStore.findNear(position: position, thresholdPixels: thresholdPixels) {
            // Add role if not already present
            for role in roles {
                mapPointStore.addRole(role, to: existingPoint.id)
            }
            batchResolved[positionKey] = existingPoint.id
            print("✅ [MapPointResolver] Matched existing point \(String(existingPoint.id.uuidString.prefix(8))) for (\(Int(position.x)), \(Int(position.y)))")
            return existingPoint.id
        }
        
        // 4. Create new MapPoint
        let newPoint = MapPointStore.MapPoint(
            mapPoint: position,
            roles: roles,
            isLocked: true
        )
        pendingPoints.append(newPoint)
        batchResolved[positionKey] = newPoint.id
        print("🆕 [MapPointResolver] Created new point \(String(newPoint.id.uuidString.prefix(8))) at (\(Int(position.x)), \(Int(position.y)))")
        return newPoint.id
    }
    
    /// Resolve multiple coordinates at once
    /// - Parameters:
    ///   - positions: Array of raw pixel coordinates
    ///   - roles: Roles to assign to all resolved points
    /// - Returns: Array of MapPoint UUIDs in the same order as input
    public func resolve(_ positions: [CGPoint], roles: Set<MapPointRole> = [.zoneCorner]) -> [UUID] {
        return positions.map { resolve($0, roles: roles) }
    }
    
    // MARK: - Commit
    
    /// Commit all pending points to the MapPointStore
    /// Call this after all coordinates have been resolved
    /// - Returns: Number of new points created
    @discardableResult
    public func commit() -> Int {
        guard !pendingPoints.isEmpty else {
            print("📦 [MapPointResolver] No pending points to commit")
            return 0
        }
        
        let count = pendingPoints.count
        
        for point in pendingPoints {
            mapPointStore.points.append(point)
        }
        mapPointStore.save()
        
        print("📦 [MapPointResolver] Committed \(count) new MapPoint(s)")
        
        // Clear batch state
        pendingPoints.removeAll()
        
        return count
    }
    
    /// Discard pending points without saving (rollback)
    public func rollback() {
        let count = pendingPoints.count
        pendingPoints.removeAll()
        batchResolved.removeAll()
        print("⏪ [MapPointResolver] Rolled back \(count) pending point(s)")
    }
    
    /// Reset batch state for a new import
    public func reset() {
        pendingPoints.removeAll()
        batchResolved.removeAll()
        print("🔄 [MapPointResolver] Reset for new batch")
    }
    
    // MARK: - Statistics
    
    /// Number of points pending commit
    public var pendingCount: Int {
        pendingPoints.count
    }
    
    /// Number of points resolved in current batch (including reused)
    public var resolvedCount: Int {
        batchResolved.count
    }
    
    // MARK: - Private Helpers
    
    /// Create a quantized position key for dictionary lookup
    /// Quantizes to 1-pixel resolution to handle floating point comparison
    private func quantizedKey(for position: CGPoint) -> String {
        let x = Int(round(position.x))
        let y = Int(round(position.y))
        return "\(x),\(y)"
    }
    
    /// Calculate Euclidean distance between two points
    private func distanceBetween(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let dx = a.x - b.x
        let dy = a.y - b.y
        return sqrt(dx * dx + dy * dy)
    }
}
