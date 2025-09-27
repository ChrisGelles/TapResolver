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

    // Global app state objects used across views
    @StateObject private var beaconDotStore = BeaconDotStore()   // dots (map-local)
    @EnvironmentObject private var mapTransform: MapTransformStore
    @StateObject private var hudPanels     = HUDPanelsState()     // drawer exclusivity
    @StateObject private var metricSquares = MetricSquareStore()  // squares (map-local)
    @StateObject private var squareMetrics = SquareMetrics()
    @StateObject private var beaconLists   = BeaconListsStore()   // ← added
    @StateObject private var btScanner     = BluetoothScanner()       // ← Bluetooth scanner

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
            // Inject environment objects once at the root so all children can use them
            .environmentObject(beaconDotStore)
            .environmentObject(hudPanels)
            .environmentObject(metricSquares)
            .environmentObject(squareMetrics)
            .environmentObject(beaconLists)    // ← added
            .environmentObject(btScanner)
            .appBootstrap(
                scanner: btScanner,
                beaconDots: beaconDotStore,
                squares: metricSquares,
                lists: beaconLists,
                scanUtility: MapPointScanUtility(
                    isExcluded: { _, _ in true },
                    resolveBeaconMeta: { _ in MapPointScanUtility.BeaconMeta(beaconID: "", name: "", posX_m: nil, posY_m: nil, posZ_m: nil, txPowerSettingDbm: nil) }
                )
            )
        }
    }
}

#Preview {
    ContentView()
}
