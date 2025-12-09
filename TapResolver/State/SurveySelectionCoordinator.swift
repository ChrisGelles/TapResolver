//
//  SurveySelectionCoordinator.swift
//  TapResolver
//
//  Orchestrates survey workflows: triangle selection, grid generation.
//  Separate from ARSurveyCoordinator which handles AR session management.
//

import Foundation
import SwiftUI
import Combine
import simd

public enum SurveySelectionState: Equatable {
    case idle
    case selectingTriangles
    case selectingAnchors
    case anchorsPlaced
    case surveying
    case recording
}

@MainActor
public class SurveySelectionCoordinator: ObservableObject {
    
    @Published public private(set) var state: SurveySelectionState = .idle
    @Published public private(set) var selectedTriangleIDs: Set<UUID> = []
    @Published public private(set) var anchorMapPointIDs: [UUID] = []
    
    public var gridSpacing_m: Double = 1.0
    
    private weak var triangleStore: TrianglePatchStore?
    private weak var metricSquareStore: MetricSquareStore?
    private weak var mapPointStore: MapPointStore?
    private weak var mapTransformStore: MapTransformStore?
    
    public init() {
        print("📐 [SurveySelectionCoordinator] Initialized")
    }
    
    func configure(
        triangleStore: TrianglePatchStore,
        metricSquareStore: MetricSquareStore,
        mapPointStore: MapPointStore,
        mapTransformStore: MapTransformStore
    ) {
        self.triangleStore = triangleStore
        self.metricSquareStore = metricSquareStore
        self.mapPointStore = mapPointStore
        self.mapTransformStore = mapTransformStore
        print("📐 [SurveySelectionCoordinator] Configured")
    }
    
    private func getPixelsPerMeter() -> Double? {
        guard let store = metricSquareStore else { return nil }
        let locked = store.squares.filter { $0.isLocked }
        let source = locked.isEmpty ? store.squares : locked
        guard let sq = source.first, sq.meters > 0 else { return nil }
        let ppm = Double(sq.side) / sq.meters
        return ppm > 0 ? ppm : nil
    }
    
    public func beginTriangleSelection() {
        guard state == .idle else { return }
        if let store = triangleStore {
            selectedTriangleIDs = Set(store.triangles.map { $0.id })
        }
        state = .selectingTriangles
        print("📐 [SurveySelectionCoordinator] Selection mode, \(selectedTriangleIDs.count) triangles")
        
        // Frame to show all triangles
        frameAllTriangles()
    }
    
    private func frameAllTriangles() {
        guard let triStore = triangleStore,
              let mapStore = mapPointStore,
              let transform = mapTransformStore else { return }
        
        var allVertices: [CGPoint] = []
        for triangle in triStore.triangles {
            for vertexID in triangle.vertexIDs {
                if let point = mapStore.points.first(where: { $0.id == vertexID }) {
                    allVertices.append(CGPoint(x: point.position.x, y: point.position.y))
                }
            }
        }
        
        guard !allVertices.isEmpty else { return }
        transform.frameToFitPoints(allVertices, padding: 80, animated: true)
    }
    
    public func toggleTriangleSelection(_ id: UUID) {
        guard state == .selectingTriangles else { return }
        if selectedTriangleIDs.contains(id) {
            selectedTriangleIDs.remove(id)
        } else {
            selectedTriangleIDs.insert(id)
        }
    }
    
    public func cancelSelection() {
        selectedTriangleIDs.removeAll()
        anchorMapPointIDs.removeAll()
        state = .idle
    }
    
    public func confirmSelectionAndBeginAnchoring() {
        guard state == .selectingTriangles, !selectedTriangleIDs.isEmpty else { return }
        state = .selectingAnchors
        
        guard let region = getSurveyableRegion() else {
            print("⚠️ [SurveySelectionCoordinator] Could not create region")
            return
        }
        
        let vertexCount = region.allVertexIDs.count
        let suggestedAnchors = getSuggestedAnchorPoints()
        
        print("📐 [SurveySelectionCoordinator] Swath confirmed:")
        print("   Triangles: \(selectedTriangleIDs.count)")
        print("   Unique vertices: \(vertexCount)")
        print("   Suggested anchors: \(suggestedAnchors.map { String($0.uuidString.prefix(8)) })")
        
        // Post notification to launch AR in Swath Survey mode
        NotificationCenter.default.post(
            name: NSNotification.Name("LaunchSwathSurveyAR"),
            object: nil,
            userInfo: [
                "selectedTriangleIDs": Array(selectedTriangleIDs),
                "suggestedAnchorIDs": suggestedAnchors
            ]
        )
    }
    
    public func reset() {
        selectedTriangleIDs.removeAll()
        anchorMapPointIDs.removeAll()
        state = .idle
    }
    
    private func pointInTri(_ p: CGPoint, _ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> Bool {
        let dX = p.x - c.x, dY = p.y - c.y
        let dX21 = c.x - b.x, dY12 = b.y - c.y
        let D = dY12 * (a.x - c.x) + dX21 * (a.y - c.y)
        let s = dY12 * dX + dX21 * dY
        let t = (c.y - a.y) * dX + (a.x - c.x) * dY
        if D < 0 { return s <= 0 && t <= 0 && s + t >= D }
        return s >= 0 && t >= 0 && s + t <= D
    }
    
    public var hasSelection: Bool { !selectedTriangleIDs.isEmpty }
    public var selectedCount: Int { selectedTriangleIDs.count }
    public func isTriangleSelected(_ id: UUID) -> Bool { selectedTriangleIDs.contains(id) }
    
    /// Get the SurveyableRegion for the current selection
    /// Returns nil if no triangles are selected
    func getSurveyableRegion() -> SurveyableRegion? {
        guard let triStore = triangleStore else { return nil }
        let selected = triStore.triangles.filter { selectedTriangleIDs.contains($0.id) }
        guard !selected.isEmpty else { return nil }
        return SurveyableRegion.swath(selected)
    }
    
    /// Identify suggested anchor points (vertices that are far apart)
    /// Returns up to 3 vertex IDs that maximize coverage
    func getSuggestedAnchorPoints() -> [UUID] {
        guard let region = getSurveyableRegion(),
              let mapStore = mapPointStore else { return [] }
        
        let vertexIDs = Array(region.allVertexIDs)
        guard vertexIDs.count >= 3 else { return vertexIDs }
        
        // Get positions for all vertices
        var positions: [UUID: CGPoint] = [:]
        for vid in vertexIDs {
            if let pt = mapStore.points.first(where: { $0.id == vid }) {
                positions[vid] = CGPoint(x: pt.position.x, y: pt.position.y)
            }
        }
        
        guard positions.count >= 3 else { return Array(positions.keys) }
        
        // Simple greedy algorithm: pick first point, then farthest from it, then farthest from both
        guard let first = positions.keys.first,
              let firstPos = positions[first] else { return [] }
        var anchors: [UUID] = [first]
        
        // Find farthest from first
        var maxDist: CGFloat = 0
        var second: UUID?
        for (id, pos) in positions where id != first {
            let d = distanceBetween(firstPos, pos)
            if d > maxDist {
                maxDist = d
                second = id
            }
        }
        if let s = second {
            anchors.append(s)
        }
        
        // Find farthest from both (maximize minimum distance)
        guard let secondID = second, let secondPos = positions[secondID] else {
            return anchors
        }
        
        var maxMinDist: CGFloat = 0
        var third: UUID?
        for (id, pos) in positions where !anchors.contains(id) {
            let d1 = distanceBetween(firstPos, pos)
            let d2 = distanceBetween(secondPos, pos)
            let minD = min(d1, d2)
            if minD > maxMinDist {
                maxMinDist = minD
                third = id
            }
        }
        if let t = third {
            anchors.append(t)
        }
        
        print("📐 [SurveySelectionCoordinator] Suggested anchors: \(anchors.map { String($0.uuidString.prefix(8)) })")
        return anchors
    }
    
    private func distanceBetween(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        return hypot(b.x - a.x, b.y - a.y)
    }
}
