//
//  TapResolverApp.swift
//  TapResolver
//
//  Created by Chris Gelles on 9/14/25.
//

import SwiftUI
import Combine


@main
struct TapResolverApp: App {
    // Static flag to ensure launch timestamp prints only once
    private static var hasLoggedLaunchTime = false
    
    // Global app state objects used across views
    @StateObject private var mapTransform = MapTransformStore()
    @StateObject private var beaconDotStore = BeaconDotStore()   // dots (map-local)
    @StateObject private var hudPanels = HUDPanelsState()       // drawer exclusivity
    @StateObject private var metricSquares = MetricSquareStore() // squares (map-local)
    @StateObject private var squareMetrics = SquareMetrics()
    @StateObject private var beaconLists = BeaconListsStore()   // beacon lists
    @StateObject private var btScanner = BluetoothScanner()     // Bluetooth scanner
    @StateObject private var mapPointStore = MapPointStore()    // map points (log points)
    @StateObject private var orientationManager = CompassOrientationManager()
    @StateObject private var scanUtility = MapPointScanUtility(
        isExcluded: { beaconID, name in
            // We'll implement this properly after the stores are created
            return false
        },
        resolveBeaconMeta: { beaconID in
            // We'll implement this properly after the stores are created
            return nil
        },
        getPixelsPerMeter: {
            // We'll implement this properly after the stores are created
            return nil
        }
    )
    // ARCHITECTURAL ADDITION: Single source of truth for live beacon state
    // Consolidates polling logic previously duplicated in RSSILabelsOverlay and ScanQualityViewModel
    @StateObject private var beaconState = BeaconStateManager()
    @StateObject private var arWorldMapStore = ARWorldMapStore()
    @StateObject private var trianglePatchStore = TrianglePatchStore()
    @StateObject private var arViewLaunchContext = ARViewLaunchContext()
    @StateObject private var arCalibrationCoordinator: ARCalibrationCoordinator
    
    @State private var showAuthorNamePrompt = AppSettings.needsAuthorName
    
    init() {
        // Print app launch timestamp (once per app launch)
        if !Self.hasLoggedLaunchTime {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .medium
            let launchTime = formatter.string(from: Date())
            print("\n" + String(repeating: "=", count: 80))
            print("🚀 TapResolver App Launch")
            print("   Date & Time: \(launchTime)")
            print(String(repeating: "=", count: 80) + "\n")
            Self.hasLoggedLaunchTime = true
        }
        
        // Initialize coordinator with temporary stores
        // These will be updated to reference the actual @StateObject instances in onAppear
        // Note: triangleStore will be set to the shared trianglePatchStore instance in onAppear
        let tempARStore = ARWorldMapStore()
        let tempMapStore = MapPointStore()
        let tempTriangleStore = TrianglePatchStore()  // Temporary - replaced in onAppear
        let tempMetricStore = MetricSquareStore()
        
        _arCalibrationCoordinator = StateObject(wrappedValue: ARCalibrationCoordinator(
            arStore: tempARStore,
            mapStore: tempMapStore,
            triangleStore: tempTriangleStore,
            metricSquareStore: tempMetricStore
        ))
    }

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
                .environmentObject(orientationManager)
                .environmentObject(scanUtility)
                .environmentObject(beaconState)  // Inject BeaconStateManager into view hierarchy
                .environmentObject(arWorldMapStore)
                .environmentObject(trianglePatchStore)  // Shared TrianglePatchStore instance
                .environmentObject(arViewLaunchContext)  // Unified AR view launch context
                .environmentObject(arCalibrationCoordinator)
                .onAppear {
                    // Update coordinator to use the actual store instances
                    arCalibrationCoordinator.arStore = arWorldMapStore
                    arCalibrationCoordinator.mapStore = mapPointStore
                    arCalibrationCoordinator.triangleStore = trianglePatchStore
                    arCalibrationCoordinator.metricSquareStore = metricSquares
                    
                    LocationMigration.runIfNeeded()
                    squareMetrics.setMetricSquareStore(metricSquares)
                    orientationManager.start()
                    
                    // METADATA MIGRATION: Add new fields to existing locations
                    migrateLegacyLocations()
                }
                .appBootstrap(
                    scanner: btScanner,
                    beaconDots: beaconDotStore,
                    squares: metricSquares,
                    lists: beaconLists,
                    scanUtility: scanUtility,
                    orientationManager: orientationManager,
                    squareMetrics: squareMetrics,
                    beaconState: beaconState,  // Pass BeaconStateManager for initialization
                    mapPointStore: mapPointStore
                )
                .sheet(isPresented: $showAuthorNamePrompt) {
                    AuthorNamePromptView(isPresented: $showAuthorNamePrompt)
                        .interactiveDismissDisabled()
                }
        }
    }
    
    // MARK: - Migration Helpers
    
    private func migrateLegacyLocations() {
        // Only run migration if author name is set (after onboarding)
        guard !AppSettings.needsAuthorName else { return }
        
        let locationIDs = ["home", "museum", "default"]
        
        print("\n🔄 Checking for location metadata migration...")
        var migratedCount = 0
        
        for locationID in locationIDs {
            if LocationImportUtils.migrateLocationMetadata(locationID: locationID) {
                migratedCount += 1
            }
        }
        
        if migratedCount > 0 {
            print("✅ Migrated \(migratedCount) location(s)\n")
        } else {
            print("✅ All locations up-to-date\n")
        }
    }
}


