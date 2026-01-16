//
//  TapResolverApp.swift
//  TapResolver
//
//  Created by Chris Gelles on 9/14/25.
//

import SwiftUI
import Combine


// Global timestamp for startup diagnostics
private let appLaunchTime = CFAbsoluteTimeGetCurrent()
private func tsLog(_ message: String) {
    let elapsed = (CFAbsoluteTimeGetCurrent() - appLaunchTime) * 1000
    print("⏱️ [\(String(format: "%8.0f", elapsed))ms] \(message)")
}

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
    @StateObject private var locationManager = LocationManager()
    @StateObject private var transformProcessor = TransformProcessor()
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
    @StateObject private var surveyPointStore = SurveyPointStore()
    @StateObject private var surveySessionCollector = SurveySessionCollector()
    @StateObject private var surveySelectionCoordinator = SurveySelectionCoordinator()
    @StateObject private var arViewLaunchContext = ARViewLaunchContext()
    @StateObject private var arCalibrationCoordinator: ARCalibrationCoordinator
    @StateObject private var zoneStore = ZoneStore()
    @StateObject private var zoneGroupStore = ZoneGroupStore()
    @StateObject private var svgExportOptions = SVGExportOptions()
    @StateObject private var backupExportOptions = BackupExportOptions()
    @StateObject private var surveyExportOptions = SurveyExportOptions()
    
    @State private var showAuthorNamePrompt = AppSettings.needsAuthorName
    
    init() {
        tsLog("[APP_INIT] TapResolverApp.init() STARTED")
        
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
        
        // Print total UserDefaults size at launch
        UserDefaultsDiagnostics.printTotalSize()
        
        // Initialize coordinator without stores - configure() called in onAppear
        _arCalibrationCoordinator = StateObject(wrappedValue: ARCalibrationCoordinator())
        
        tsLog("[APP_INIT] TapResolverApp.init() COMPLETE")
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
                .environmentObject(surveyPointStore)
                .environmentObject(surveySessionCollector)
                .environmentObject(surveySelectionCoordinator)
                .environmentObject(arViewLaunchContext)  // Unified AR view launch context
                .environmentObject(arCalibrationCoordinator)
                .environmentObject(zoneStore)
                .environmentObject(zoneGroupStore)
                .environmentObject(svgExportOptions)
                .environmentObject(backupExportOptions)
                .environmentObject(surveyExportOptions)
                .environmentObject(locationManager)
                .environmentObject(transformProcessor)
                .onAppear {
                    tsLog("[APP_CONFIG] onAppear configure block STARTED")
                    
                    // Configure coordinator with actual store instances
                    arCalibrationCoordinator.configure(
                        arStore: arWorldMapStore,
                        mapStore: mapPointStore,
                        triangleStore: trianglePatchStore,
                        metricSquareStore: metricSquares,
                        zoneStore: zoneStore
                    )
                    
                    surveySelectionCoordinator.configure(
                        triangleStore: trianglePatchStore,
                        metricSquareStore: metricSquares,
                        mapPointStore: mapPointStore,
                        mapTransformStore: mapTransform
                    )
                    
                    // Configure survey session collector
                    surveySessionCollector.configure(
                        surveyPointStore: surveyPointStore,
                        bluetoothScanner: btScanner,
                        beaconLists: beaconLists,
                        orientationManager: orientationManager,
                        mapPointStore: mapPointStore,
                        arCalibrationCoordinator: arCalibrationCoordinator
                    )
                    
                    // Configure ZoneStore with dependencies and load zones
                    zoneStore.configure(mapPointStore: mapPointStore, triangleStore: trianglePatchStore, zoneGroupStore: zoneGroupStore)
                    zoneStore.load()
                    
                    LocationMigration.runIfNeeded()
                    squareMetrics.setMetricSquareStore(metricSquares)
                    orientationManager.start()
                    
                    // METADATA MIGRATION: Add new fields to existing locations
                    migrateLegacyLocations()
                    
                    tsLog("[APP_CONFIG] onAppear configure block COMPLETE")
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


