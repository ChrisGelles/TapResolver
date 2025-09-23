//
//  ContentView.swift
//  TapResolver
//
//  Created by restructuring on 9/19/25.
//

import SwiftUI
import CoreGraphics

// MARK: - Notifications
extension Notification.Name {
    static let resetMapTransform = Notification.Name("ResetMapTransform")
    static let rssiStateChanged = Notification.Name("RSSIStateChanged")
}

struct ContentView: View {
    // All state objects are now injected at the app level
    @EnvironmentObject private var mapTransform: MapTransformStore
    @EnvironmentObject private var beaconDotStore: BeaconDotStore
    @EnvironmentObject private var hudPanels: HUDPanelsState
    @EnvironmentObject private var metricSquares: MetricSquareStore
    @EnvironmentObject private var squareMetrics: SquareMetrics
    @EnvironmentObject private var beaconLists: BeaconListsStore
    @EnvironmentObject private var btScanner: BluetoothScanner

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Map stack (centered on the device screen)
                MapContainer()
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    // Keep the "screen center" in sync so screen<->map conversions are correct
                    .onAppear {
                        mapTransform.screenCenter = CGPoint(x: geo.size.width  / 2,
                                                            y: geo.size.height / 2)
                    }
                    .onChange(of: geo.size) { newSize in
                        mapTransform.screenCenter = CGPoint(x: newSize.width  / 2,
                                                            y: newSize.height / 2)
                    }

                // HUD overlay (drawers + reset) — non-blocking outside its own controls
                HUDContainer()
            }
            .ignoresSafeArea()
            .appBootstrap()
        }
    }
}

#Preview {
    ContentView()
}