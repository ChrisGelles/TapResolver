//
//  MapPointStore.swift
//  TapResolver
//
//  Created by restructuring on 9/24/25.
//

import SwiftUI
import CoreGraphics

// MARK: - Store of Map Points (log points) with map-local positions
public final class MapPointStore: ObservableObject {
    public struct MapPoint: Identifiable {
        public let id = UUID()
        public var mapPoint: CGPoint    // map-local (untransformed) coords
        public let createdDate: Date = Date()
    }

    @Published public private(set) var points: [MapPoint] = []

    // MARK: persistence keys
    private let pointsKey = "MapPoints_v1"

    public init() {
        load()
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
        
        points.append(MapPoint(mapPoint: mapPoint))
        save()
        print("Added map point @ map (\(Int(mapPoint.x)), \(Int(mapPoint.y)))")
        return true
    }

    /// Remove a map point by its ID
    public func removePoint(id: UUID) {
        if let idx = points.firstIndex(where: { $0.id == id }) {
            points.remove(at: idx)
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
        save()
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
    }

    private func save() {
        let dto = points.map { MapPointDTO(id: $0.id, x: $0.mapPoint.x, y: $0.mapPoint.y, createdDate: $0.createdDate) }
        if let data = try? JSONEncoder().encode(dto) {
            UserDefaults.standard.set(data, forKey: pointsKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: pointsKey),
           let dto = try? JSONDecoder().decode([MapPointDTO].self, from: data) {
            self.points = dto.map { MapPointDTO in
                MapPoint(mapPoint: CGPoint(x: MapPointDTO.x, y: MapPointDTO.y))
            }
        }
    }
}
