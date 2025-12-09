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
    @Published public private(set) var gridPoints_m: [CGPoint] = []
    @Published public private(set) var anchorMapPointIDs: [UUID] = []
    
    public var gridSpacing_m: Double = 1.0
    
    private weak var triangleStore: TrianglePatchStore?
    private weak var metricSquareStore: MetricSquareStore?
    private weak var mapPointStore: MapPointStore?
    
    public init() {
        print("📐 [SurveySelectionCoordinator] Initialized")
    }
    
    func configure(
        triangleStore: TrianglePatchStore,
        metricSquareStore: MetricSquareStore,
        mapPointStore: MapPointStore
    ) {
        self.triangleStore = triangleStore
        self.metricSquareStore = metricSquareStore
        self.mapPointStore = mapPointStore
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
        gridPoints_m.removeAll()
        anchorMapPointIDs.removeAll()
        state = .idle
    }
    
    public func confirmSelectionAndBeginAnchoring() {
        guard state == .selectingTriangles, !selectedTriangleIDs.isEmpty else { return }
        generateGridPoints()
        state = .selectingAnchors
        print("📐 [SurveySelectionCoordinator] Grid: \(gridPoints_m.count) points")
    }
    
    public func reset() {
        selectedTriangleIDs.removeAll()
        gridPoints_m.removeAll()
        anchorMapPointIDs.removeAll()
        state = .idle
    }
    
    private func generateGridPoints() {
        guard let triStore = triangleStore,
              let mapStore = mapPointStore,
              let ppm = getPixelsPerMeter() else { return }
        
        let selected = triStore.triangles.filter { selectedTriangleIDs.contains($0.id) }
        guard !selected.isEmpty else { gridPoints_m = []; return }
        
        var verts: [CGPoint] = []
        for tri in selected {
            for vid in tri.vertexIDs {
                if let pt = mapStore.points.first(where: { $0.id == vid }) {
                    verts.append(CGPoint(x: pt.position.x, y: pt.position.y))
                }
            }
        }
        guard !verts.isEmpty else { gridPoints_m = []; return }
        
        let minX = verts.map { $0.x }.min()! / ppm
        let maxX = verts.map { $0.x }.max()! / ppm
        let minY = verts.map { $0.y }.min()! / ppm
        let maxY = verts.map { $0.y }.max()! / ppm
        
        var pts: [CGPoint] = []
        var y = minY
        while y <= maxY {
            var x = minX
            while x <= maxX {
                let px = CGPoint(x: x * ppm, y: y * ppm)
                if isInsideAny(px, tris: selected, mapStore: mapStore) {
                    pts.append(CGPoint(x: x, y: y))
                }
                x += gridSpacing_m
            }
            y += gridSpacing_m
        }
        gridPoints_m = pts
    }
    
    private func isInsideAny(_ p: CGPoint, tris: [TrianglePatch], mapStore: MapPointStore) -> Bool {
        for tri in tris {
            guard tri.vertexIDs.count == 3 else { continue }
            var v: [CGPoint] = []
            for vid in tri.vertexIDs {
                if let pt = mapStore.points.first(where: { $0.id == vid }) {
                    v.append(CGPoint(x: pt.position.x, y: pt.position.y))
                }
            }
            guard v.count == 3 else { continue }
            if pointInTri(p, v[0], v[1], v[2]) { return true }
        }
        return false
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
}
