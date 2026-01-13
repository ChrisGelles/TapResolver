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
    @EnvironmentObject private var surveySelectionCoordinator: SurveySelectionCoordinator
    @EnvironmentObject private var zoneStore: ZoneStore
    
    private let surveySelectionColor = Color(red: 0.05, green: 0.1, blue: 0.78)
    
    var body: some View {
        let triangles: [TrianglePatch] = triangleStore.triangles
        
        return ZStack {
            // Unselected triangles (rendered first, below)
            ForEach(triangles, id: \.id) { (triangle: TrianglePatch) in
                // Skip if this triangle is selected via normal selection (render it separately on top)
                if triangleStore.selectedTriangleID != triangle.id,
                   let positions = getVertexPositions(triangle.vertexIDs) {
                    
                    let appearance = triangleAppearance(for: triangle)
                    
                    TriangleShape(vertices: positions)
                        .fill(appearance.fill)
                        .overlay(
                            TriangleShape(vertices: positions)
                                .stroke(appearance.stroke, lineWidth: appearance.strokeWidth)
                        )
                        .contentShape(TriangleShape(vertices: positions))
                        .onTapGesture {
                            if zoneStore.isEditingTriangleMembership {
                                // Zone membership edit mode: toggle membership
                                zoneStore.togglePendingMembership(triangleID: triangle.id.uuidString)
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } else if surveySelectionCoordinator.state == .selectingTriangles {
                                // Survey mode: toggle selection
                                surveySelectionCoordinator.toggleTriangleSelection(triangle.id)
                                print("📐 Toggled survey selection: \(triangle.id)")
                            } else {
                                // Normal mode: single selection
                                triangleStore.selectedTriangleID = triangle.id
                                print("🔺 Selected triangle: \(triangle.id)")
                            }
                        }
                        .onLongPressGesture(minimumDuration: 0.5) {
                            // Only allow long-press calibration when NOT in survey mode
                            guard surveySelectionCoordinator.state == .idle else { return }
                            
                            triangleStore.selectedTriangleID = triangle.id
                            print("🔵 Selected triangle via long-press: \(triangle.id)")
                            
                            NotificationCenter.default.post(
                                name: NSNotification.Name("StartTriangleCalibration"),
                                object: nil,
                                userInfo: ["triangleID": triangle.id]
                            )
                            print("🎯 Long-press detected - starting calibration for triangle: \(triangle.id)")
                        }
                }
            }
            
            // Selected triangle (rendered on top with higher zIndex)
            if let selectedID = triangleStore.selectedTriangleID,
               let selectedTriangle = triangleStore.triangles.first(where: { $0.id == selectedID }),
               let positions = getVertexPositions(selectedTriangle.vertexIDs) {
                TriangleShape(vertices: positions)
                    .fill(selectedTriangle.statusColor.opacity(0.15))
                    .overlay(
                        TriangleShape(vertices: positions)
                            .stroke(Color(red: 0.29, green: 0.8, blue: 0.97), lineWidth: 3)
                    )
                    .contentShape(TriangleShape(vertices: positions))
                    .onTapGesture {
                        triangleStore.selectedTriangleID = nil
                        print("🔵 Deselected triangle: \(selectedID)")
                    }
                    .onLongPressGesture(minimumDuration: 0.5) {
                        // Long-press on selected triangle also triggers calibration
                        NotificationCenter.default.post(
                            name: NSNotification.Name("StartTriangleCalibration"),
                            object: nil,
                            userInfo: ["triangleID": selectedTriangle.id]
                        )
                        print("🎯 Long-press on selected triangle - starting calibration for: \(selectedTriangle.id)")
                    }
                    .zIndex(100)  // ✅ Render on top of all other triangles
            }
            
            // Triangle being created (preview) - always on top
            if triangleStore.isCreatingTriangle,
               let positions = getVertexPositions(triangleStore.creationVertices) {
                
                if positions.count == 2 {
                    // Draw line between first two points
                    Path { path in
                        path.move(to: positions[0])
                        path.addLine(to: positions[1])
                    }
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                    .zIndex(200)
                    
                } else if positions.count == 3 {
                    // Draw dashed triangle
                    TriangleShape(vertices: positions)
                        .fill(Color.blue.opacity(0.1))
                        .overlay(
                            TriangleShape(vertices: positions)
                                .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                        )
                        .zIndex(200)
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
    
    private func triangleAppearance(for triangle: TrianglePatch) -> (fill: Color, stroke: Color, strokeWidth: CGFloat) {
        if zoneStore.isEditingTriangleMembership {
            let isMember = zoneStore.pendingMemberTriangleIDs.contains(triangle.id.uuidString)
            if isMember {
                let zoneColor = zoneStore.editingZoneColor ?? .blue
                return (zoneColor.opacity(0.4), zoneColor, 2.5)
            } else {
                return (Color.gray.opacity(0.1), Color.gray.opacity(0.5), 1.0)
            }
        } else {
            let isSurveySelected = surveySelectionCoordinator.isTriangleSelected(triangle.id)
            let inSurveyMode = surveySelectionCoordinator.state == .selectingTriangles
            
            if inSurveyMode && isSurveySelected {
                return (surveySelectionColor.opacity(0.5), surveySelectionColor, 2.5)
            } else {
                return (triangle.statusColor.opacity(0.15), triangle.statusColor, 1.5)
            }
        }
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

