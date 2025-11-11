//
//  TriangleOverlay.swift
//  TapResolver
//
//  Renders triangular patches on map
//

import SwiftUI
import CoreGraphics

struct TriangleOverlay: View {
    @EnvironmentObject private var triangleStore: TrianglePatchStore
    @EnvironmentObject private var mapPointStore: MapPointStore
    
    var body: some View {
        ZStack {
            // Completed triangles
            ForEach(triangleStore.triangles) { triangle in
                if let positions = getVertexPositions(triangle.vertexIDs) {
                    TriangleShape(vertices: positions)
                        .fill(triangle.statusColor.opacity(0.15))
                        .overlay(
                            TriangleShape(vertices: positions)
                                .stroke(
                                    triangleStore.selectedTriangleID == triangle.id ? Color.white : triangle.statusColor,
                                    lineWidth: triangleStore.selectedTriangleID == triangle.id ? 3 : 1.5
                                )
                        )
                        .contentShape(TriangleShape(vertices: positions))
                        .onTapGesture {
                            triangleStore.selectedTriangleID = triangle.id
                            print("📐 Selected triangle: \(triangle.id)")
                        }
                }
            }
            
            // Triangle being created (preview)
            if triangleStore.isCreatingTriangle,
               let positions = getVertexPositions(triangleStore.creationVertices) {
                
                if positions.count == 2 {
                    // Draw line between first two points
                    Path { path in
                        path.move(to: positions[0])
                        path.addLine(to: positions[1])
                    }
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                    
                } else if positions.count == 3 {
                    // Draw dashed triangle
                    TriangleShape(vertices: positions)
                        .fill(Color.blue.opacity(0.1))
                        .overlay(
                            TriangleShape(vertices: positions)
                                .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                        )
                }
            }
        }
    }
    
    private func getVertexPositions(_ vertexIDs: [UUID]) -> [CGPoint]? {
        var positions: [CGPoint] = []
        for id in vertexIDs {
            guard let point = mapPointStore.points.first(where: { $0.id == id }) else {
                return nil
            }
            positions.append(point.mapPoint)
        }
        return positions.isEmpty ? nil : positions
    }
}

// MARK: - Triangle Shape
struct TriangleShape: Shape {
    let vertices: [CGPoint]
    
    func path(in rect: CGRect) -> Path {
        guard vertices.count >= 3 else { return Path() }
        
        var path = Path()
        path.move(to: vertices[0])
        path.addLine(to: vertices[1])
        path.addLine(to: vertices[2])
        path.closeSubpath()
        
        return path
    }
}

