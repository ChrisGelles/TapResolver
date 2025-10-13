//
//  MapPointStore.swift
//  TapResolver
//
//  Created by restructuring on 9/24/25.
//

import SwiftUI
import CoreGraphics
import Combine

// Notification for when map points reload
extension Notification.Name {
    static let mapPointsDidReload = Notification.Name("mapPointsDidReload")
    static let scanSessionSaved = Notification.Name("scanSessionSaved")
}

// MARK: - Store of Map Points (log points) with map-local positions
public final class MapPointStore: ObservableObject {
    private let ctx = PersistenceContext.shared
    private var scanSessionCancellable: AnyCancellable?
    
    public struct MapPoint: Identifiable {
        public let id = UUID()
        public var mapPoint: CGPoint    // map-local (untransformed) coords
        public let createdDate: Date = Date()
        public var sessionFilePaths: [String] = []  // Array of file URLs for this point's scan sessions
    }

    @Published public private(set) var points: [MapPoint] = []
    @Published public private(set) var activePointID: UUID? = nil
    
    /// Get the currently active map point
    public var activePoint: MapPoint? {
        guard let activeID = activePointID else { return nil }
        return points.first { $0.id == activeID }
    }
    
    /// Reload data for the active location
    public func reloadForActiveLocation() {
        clearAndReloadForActiveLocation()
    }
    
    public func clearAndReloadForActiveLocation() {
        points.removeAll()
        activePointID = nil
        load()
        objectWillChange.send()
        
        // Notify that map points have reloaded - trigger session index rebuild
        NotificationCenter.default.post(name: .mapPointsDidReload, object: nil)
    }
    
    func flush() {
        points.removeAll()
        activePointID = nil
        objectWillChange.send()
    }

    // MARK: persistence keys
    private let pointsKey = "MapPoints_v1"
    private let activePointKey = "MapPointsActive_v1"

    public init() {
        load()
        
        // Listen for scan session saves
        scanSessionCancellable = NotificationCenter.default.publisher(for: .scanSessionSaved)
            .sink { [weak self] notification in
                guard let userInfo = notification.userInfo,
                      let pointID = userInfo["pointID"] as? UUID,
                      let filePath = userInfo["filePath"] as? String else {
                    return
                }
                
                self?.addSessionFilePath(pointID: pointID, filePath: filePath)
            }
    }

    /// Add a new map point at the specified coordinates
    /// Returns false if a point already exists at those coordinates
    public func addPoint(at mapPoint: CGPoint) -> Bool {
        // Check if a point already exists at these coordinates (within 1 pixel tolerance)
        let tolerance: CGFloat = 1.0
        let existsAtLocation = points.contains { point in
            abs(point.mapPoint.x - mapPoint.x) < tolerance &&
            abs(point.mapPoint.y - mapPoint.y) < tolerance
        }
        
        if existsAtLocation {
            return false // Cannot add duplicate coordinates
        }
        
        let newPoint = MapPoint(mapPoint: mapPoint)
        points.append(newPoint)
        // Set the new point as active (deactivating any previous active point)
        activePointID = newPoint.id
        save()
        print("Added map point @ map (\(Int(mapPoint.x)), \(Int(mapPoint.y)))")
        return true
    }

    /// Remove a map point by its ID
    public func removePoint(id: UUID) {
        if let idx = points.firstIndex(where: { $0.id == id }) {
            points.remove(at: idx)
            // If the removed point was active, clear the active state
            if activePointID == id {
                activePointID = nil
            }
            save()
            print("Removed map point with ID \(id)")
        }
    }

    /// Update a map point's position (used while dragging)
    public func updatePoint(id: UUID, to newPoint: CGPoint) {
        if let idx = points.firstIndex(where: { $0.id == id }) {
            points[idx].mapPoint = newPoint
            save()
        }
    }

    public func clear() {
        points.removeAll()
        activePointID = nil
        save()
    }

    /// Toggle the active state of a map point (only one can be active at a time)
    public func toggleActive(id: UUID) {
        if activePointID == id {
            // Deactivate if currently active
            activePointID = nil
        } else {
            // Activate this point (deactivating any other active point)
            activePointID = id
        }
        save()
    }

    /// Deactivate all map points (called when drawer closes)
    public func deactivateAll() {
        activePointID = nil
        save()
    }

    /// Select a point by ID (used when tapping on map dots)
    public func selectPoint(id: UUID) {
        activePointID = id
        save()
    }

    /// Check if a point is currently active
    public func isActive(_ id: UUID) -> Bool {
        return activePointID == id
    }

    /// Get coordinate string for display in drawer
    public func coordinateString(for point: MapPoint) -> String {
        return "(\(Int(point.mapPoint.x)),\(Int(point.mapPoint.y)))"
    }

    // MARK: - Persistence

    private struct MapPointDTO: Codable {
        let id: UUID
        let x: CGFloat
        let y: CGFloat
        let createdDate: Date
        let sessionFilePaths: [String]
    }

    private func save() {
        let dto = points.map { MapPointDTO(
            id: $0.id, 
            x: $0.mapPoint.x, 
            y: $0.mapPoint.y, 
            createdDate: $0.createdDate,
            sessionFilePaths: $0.sessionFilePaths
        )}
        ctx.write(pointsKey, value: dto)
        if let activeID = activePointID {
            ctx.write(activePointKey, value: activeID)
        }
    }

    private func load() {
        if let dto: [MapPointDTO] = ctx.read(pointsKey, as: [MapPointDTO].self) {
            self.points = dto.map { dtoItem in
                var point = MapPoint(mapPoint: CGPoint(x: dtoItem.x, y: dtoItem.y))
                point.sessionFilePaths = dtoItem.sessionFilePaths
                return point
            }
        }
        if let activeID: UUID = ctx.read(activePointKey, as: UUID.self) {
            self.activePointID = points.contains(where: { $0.id == activeID }) ? activeID : nil
        }
    }
    
    // MARK: - Session Management
    
    /// Add a session file path to a map point
    public func addSessionFilePath(pointID: UUID, filePath: String) {
        if let idx = points.firstIndex(where: { $0.id == pointID }) {
            if !points[idx].sessionFilePaths.contains(filePath) {
                points[idx].sessionFilePaths.append(filePath)
                save()
                print("📎 Added session file to point \(pointID): \(URL(fileURLWithPath: filePath).lastPathComponent)")
            }
        }
    }
    
    /// Get all session file paths for a map point
    public func getSessionFilePaths(pointID: UUID) -> [String] {
        return points.first(where: { $0.id == pointID })?.sessionFilePaths ?? []
    }
}
