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
        // Set up the exclusion closure to only scan beacons that are in the active beacon list
        // (not in morgue) and have dots in BeaconDotStore
        
        // Connect the scan utility to the Bluetooth scanner
        btScanner.scanUtility = scanUtility
        
        // Configure the scan utility closures after all stores are created
        configureScanUtilityClosures()
    }
    
    private func configureScanUtilityClosures() {
        // Configure isExcluded: ONLY include beacons that are in the Beacon Drawer list AND have dots on the map
        // This mirrors exactly what RSSILabelsOverlay does
        scanUtility.isExcluded = { [weak beaconLists, weak beaconDotStore] beaconID, name in
            guard let beaconLists = beaconLists, let beaconDotStore = beaconDotStore else { return true }
            
            // If no name provided, exclude it
            guard let name = name, !name.isEmpty else { return true }
            
            // ONLY include beacons that are in the active beacon list (Beacon Drawer)
            guard beaconLists.beacons.contains(name) else { return true }
            
            // ONLY include beacons that have dots on the map
            guard beaconDotStore.dots.contains(where: { $0.beaconID == name }) else { return true }
            
            // Include this beacon - it's in the Beacon Drawer and has a map dot
            return false
        }
        
        // Configure resolveBeaconMeta: provide metadata for our tracked beacons
        // This uses the same data that RSSI labels use
        scanUtility.resolveBeaconMeta = { [weak beaconDotStore] beaconID in
            guard let beaconDotStore = beaconDotStore else { 
                return MapPointScanUtility.BeaconMeta(
                    beaconID: beaconID,
                    name: beaconID,
                    posX_m: nil,
                    posY_m: nil,
                    posZ_m: nil,
                    txPowerSettingDbm: nil
                )
            }
            
            // Find the beacon dot (same logic as RSSILabelsOverlay)
            guard let dot = beaconDotStore.dots.first(where: { $0.beaconID == beaconID }) else { 
                return MapPointScanUtility.BeaconMeta(
                    beaconID: beaconID,
                    name: beaconID,
                    posX_m: nil,
                    posY_m: nil,
                    posZ_m: nil,
                    txPowerSettingDbm: nil
                )
            }
            
            // Return beacon metadata using the same data as RSSI labels
            return MapPointScanUtility.BeaconMeta(
                beaconID: beaconID,
                name: beaconID,
                posX_m: Double(dot.mapPoint.x),
                posY_m: Double(dot.mapPoint.y),
                posZ_m: beaconDotStore.getElevation(for: beaconID),
                txPowerSettingDbm: nil // We don't store this, but could add it later
            )
        }
    }
}


