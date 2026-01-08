//
//  MapPointOverlay.swift
//  TapResolver
//
//  Created by restructuring on 9/24/25.
//

import SwiftUI
import CoreGraphics

// MARK: - Map Point Overlay for displaying semi-transparent blue dots
struct MapPointOverlay: View {
    @EnvironmentObject private var mapPointStore: MapPointStore
    @EnvironmentObject private var mapTransform: MapTransformStore
    @EnvironmentObject private var hud: HUDPanelsState
    @EnvironmentObject private var triangleStore: TrianglePatchStore
    @EnvironmentObject private var zoneStore: ZoneStore

    var body: some View {
        ZStack {
            // Show map points when the drawer is open OR when creating triangles OR when creating zones
            if hud.isMapPointOpen || triangleStore.isCreatingTriangle || zoneStore.isCreatingZone {
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .allowsHitTesting(false)  // Never intercept taps - let points handle everything
                
                ForEach(mapPointStore.points) { point in
                    DraggableMapPoint(point: point)
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: hud.isMapPointOpen)
        .animation(.easeInOut(duration: 0.25), value: triangleStore.isCreatingTriangle)
        .animation(.easeInOut(duration: 0.25), value: zoneStore.isCreatingZone)
    }
    
    // MARK: - Single draggable map point subview
    private struct DraggableMapPoint: View {
        let point: MapPointStore.MapPoint
        @EnvironmentObject private var mapPointStore: MapPointStore
        @EnvironmentObject private var mapTransform: MapTransformStore
        @EnvironmentObject private var triangleStore: TrianglePatchStore
        @EnvironmentObject private var zoneStore: ZoneStore
        
        private let dotSize: CGFloat = 12
        private let hitPadding: CGFloat = 8
        
        @State private var startPoint: CGPoint? = nil
        
        var body: some View {
            let isActive = mapPointStore.isActive(point.id)
            let isSelected = mapPointStore.selectedPointID == point.id
            let isLocked = point.isLocked
            let color = displayColor(for: point, isActive: isActive)
            
            ZStack {
                Circle()
                    .fill(color.opacity(0.9))
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.white : Color.black.opacity(isActive ? 1 : 0), lineWidth: isSelected ? 3 : (isActive ? 2 : 0))
                    )
                    .overlay(alignment: .topTrailing) {
                        if !point.roles.isEmpty {
                            roleBadges(for: point)
                                .offset(x: 14, y: -14)
                        }
                    }
                    .frame(width: dotSize, height: dotSize)
            }
            .frame(width: dotSize + 2 * hitPadding,
                   height: dotSize + 2 * hitPadding,
                   alignment: .center)
            .contentShape(Circle())
            .position(point.mapPoint)
                .gesture(
                    DragGesture(minimumDistance: 6, coordinateSpace: .global)
                        .onChanged { value in
                            guard !mapTransform.isPinching else { return }
                            guard !isLocked else { return }
                            if startPoint == nil {
                                startPoint = point.mapPoint
                                mapTransform.isOverlayDragging = true
                            }
                            let dMap = mapTransform.screenTranslationToMap(value.translation)
                            let base = startPoint ?? point.mapPoint
                            let newPoint = CGPoint(x: base.x + dMap.width, y: base.y + dMap.height)
                            mapPointStore.updatePoint(id: point.id, to: newPoint)
                        }
                        .onEnded { _ in
                            startPoint = nil
                            mapTransform.isOverlayDragging = false
                            // Save position after drag completes
                            mapPointStore.save()
                        }
                )
                .onTapGesture {
                    print("MapPoint tapped: \(point.id)")
                    
                    // UNIFICATION CANDIDATE: These two creation mode checks follow identical patterns.
                    // Consider a unified CreationModeCoordinator that handles both.
                    
                    // Triangle creation handling
                    if triangleStore.isCreatingTriangle {
                        if let error = triangleStore.addCreationVertex(point.id, mapPointStore: mapPointStore) {
                            print("❌ Cannot add vertex: \(error)")
                        }
                        return
                    }
                    
                    // Zone creation handling
                    if zoneStore.isCreatingZone {
                        zoneStore.addCreationCorner(point.id, mapPointStore: mapPointStore)
                        return
                    }
                    
                    // Existing tap handling
                    if mapPointStore.isInterpolationMode && mapPointStore.interpolationSecondPointID == nil {
                        mapPointStore.selectSecondPoint(secondPointID: point.id)
                    } else {
                        // ✅ TOGGLE: If already selected, deselect
                        if mapPointStore.selectedPointID == point.id {
                            mapPointStore.selectedPointID = nil
                            print("🔘 Deselected MapPoint: \(point.id)")
                        } else {
                            mapPointStore.selectedPointID = point.id
                            print("🔘 Selected MapPoint: \(point.id)")
                        }
                    }
                }
        }
        
        private func displayColor(for point: MapPointStore.MapPoint, isActive: Bool) -> Color {
            if mapPointStore.interpolationFirstPointID == point.id {
                return .orange
            }
            if mapPointStore.interpolationSecondPointID == point.id {
                return .green
            }
            if point.roles.contains(.directionalNorth) {
                return MapPointRole.directionalNorth.color
            }
            if point.roles.contains(.directionalSouth) {
                return MapPointRole.directionalSouth.color
            }
            if point.roles.contains(.triangleEdge) {
                return MapPointRole.triangleEdge.color
            }
            if point.roles.contains(.featureMarker) {
                return MapPointRole.featureMarker.color
            }
            if isActive {
                return Color(hex: 0x10fff1)
            }
            return .blue
        }
        
        @ViewBuilder
        private func roleBadges(for point: MapPointStore.MapPoint) -> some View {
            VStack(alignment: .trailing, spacing: 2) {
                ForEach(Array(point.roles).sorted { $0.rawValue < $1.rawValue }, id: \.self) { role in
                    Image(systemName: role.icon)
                        .font(.system(size: 8))
                        .foregroundColor(.white)
                        .padding(4)
                        .background(role.color)
                        .clipShape(Circle())
                }
            }
        }
    }
}
