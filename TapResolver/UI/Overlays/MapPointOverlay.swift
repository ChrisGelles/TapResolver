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
                ForEach(mapPointStore.points) { point in
                    let isActive = mapPointStore.isActive(point.id)
                    
                    // Determine point color based on interpolation state
                    let pointColor: Color = {
                        if mapPointStore.interpolationFirstPointID == point.id {
                            return .orange  // First point in interpolation
                        } else if mapPointStore.interpolationSecondPointID == point.id {
                            return .green   // Second point in interpolation
                        } else if isActive {
                            return Color(hex: 0x10fff1)  // Normal selection (cyan)
                        } else {
                            return .blue    // Unselected
                        }
                    }()
                    
                    Circle()
                        .fill(pointColor.opacity(0.9))
                        .overlay(
                            Circle()
                                .stroke(Color.black, lineWidth: isActive || mapPointStore.interpolationFirstPointID == point.id || mapPointStore.interpolationSecondPointID == point.id ? 2 : 0)
                        )
                        .frame(width: 12, height: 12)
                        .position(point.mapPoint) // Use map-local coordinates directly
                        .allowsHitTesting(true)
                        .onTapGesture {
                            print("MapPoint tapped: \(point.id)")
                            
                            // Handle selection based on mode
                            if mapPointStore.isInterpolationMode && mapPointStore.interpolationSecondPointID == nil {
                                // Selecting second point for interpolation
                                mapPointStore.selectSecondPoint(secondPointID: point.id)
                            } else {
                                // Normal selection
                                mapPointStore.selectPoint(id: point.id)
                            }
                        }
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: hud.isMapPointOpen)
    }
}
