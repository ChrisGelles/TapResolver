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
                    Circle()
                        .fill(isActive ? Color(hex: 0x10fff1).opacity(0.9) : Color.blue.opacity(0.6))
                        .overlay(
                            Circle()
                                .stroke(Color.black, lineWidth: isActive ? 2 : 0)
                        )
                        .frame(width: 12, height: 12)
                        .position(point.mapPoint) // Use map-local coordinates directly
                        .allowsHitTesting(true)
                        .onTapGesture {
                            print("MapPoint tapped: \(point.id)")
                            mapPointStore.selectPoint(id: point.id)
                        }
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: hud.isMapPointOpen)
    }
}
