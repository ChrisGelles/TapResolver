//
//  TapResolverApp.swift
//  TapResolver
//
//  Created by Chris Gelles on 9/14/25.
//

import SwiftUI

@main
struct TapResolverApp: App {
    // Global app state objects used across views
    @StateObject private var mapTransform = MapTransformStore()
    @StateObject private var beaconDotStore = BeaconDotStore()   // dots (map-local)
    @StateObject private var hudPanels = HUDPanelsState()       // drawer exclusivity
    @StateObject private var metricSquares = MetricSquareStore() // squares (map-local)
    @StateObject private var squareMetrics = SquareMetrics()
    @StateObject private var beaconLists = BeaconListsStore()   // beacon lists
    @StateObject private var btScanner = BluetoothScanner()     // Bluetooth scanner
    @StateObject private var mapPointStore = MapPointStore()    // map points (log points)
    @StateObject private var scanUtility = MapPointScanUtility(
        isExcluded: { beaconID, name in
            // We'll implement this properly after the stores are created
            return false
        },
        resolveBeaconMeta: { beaconID in
            // We'll implement this properly after the stores are created
            return nil
        }
    )

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Inject all environment objects at the app level
                .environmentObject(mapTransform)
                .environmentObject(beaconDotStore)
                .environmentObject(hudPanels)
                .environmentObject(metricSquares)
                .environmentObject(squareMetrics)
                .environmentObject(beaconLists)
                .environmentObject(btScanner)
                .environmentObject(mapPointStore)
                .environmentObject(scanUtility)
                .onAppear {
                    // Set up scanUtility with proper closures after all stores are created
                    setupScanUtility()
                }
        }
    }
    
    private func setupScanUtility() {
        // Set up the exclusion closure to only scan beacons that have dots in BeaconDotStore
        // This is a simplified approach - we'll only scan beacons that are actively tracked
        // The actual filtering will be done in the BluetoothScanner callback
        
        // Connect the scan utility to the Bluetooth scanner
        btScanner.scanUtility = scanUtility
    }
}


