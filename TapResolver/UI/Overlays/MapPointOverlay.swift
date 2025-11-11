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

    var body: some View {
        ZStack {
            // Only show map points when the drawer is open
            if hud.isMapPointOpen {
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .allowsHitTesting(mapPointStore.selectedPointID != nil)
                    .gesture(
                        TapGesture().onEnded {
                            mapPointStore.selectedPointID = nil
                        }
                    )
                
                ForEach(mapPointStore.points) { point in
                    let isActive = mapPointStore.isActive(point.id)
                    
                    mapPointDot(for: point, isActive: isActive)
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: hud.isMapPointOpen)
    }
    
    @ViewBuilder
    private func mapPointDot(for point: MapPointStore.MapPoint, isActive: Bool) -> some View {
        let isSelected = mapPointStore.selectedPointID == point.id
        let color = displayColor(for: point, isActive: isActive)
        
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
            .frame(width: 12, height: 12)
            .position(point.mapPoint)
            .allowsHitTesting(true)
            .onTapGesture {
                print("MapPoint tapped: \(point.id)")
                
                if mapPointStore.isInterpolationMode && mapPointStore.interpolationSecondPointID == nil {
                    mapPointStore.selectSecondPoint(secondPointID: point.id)
                } else {
                    mapPointStore.selectPoint(id: point.id)
                }
                mapPointStore.selectedPointID = point.id
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
