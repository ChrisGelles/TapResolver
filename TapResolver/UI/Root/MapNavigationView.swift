import SwiftUI
import CoreGraphics

struct MapNavigationView: View {
    // Use env objects; ownership is in ContentView.
    @EnvironmentObject private var beaconDotStore: BeaconDotStore
    @EnvironmentObject private var mapTransform: MapTransformStore
    @EnvironmentObject private var hudPanels: HUDPanelsState
    @EnvironmentObject private var metricSquares: MetricSquareStore
    @EnvironmentObject private var squareMetrics: SquareMetrics
    @EnvironmentObject private var beaconLists: BeaconListsStore
    @EnvironmentObject private var btScanner: BluetoothScanner
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var mapPointStore: MapPointStore
    @EnvironmentObject private var mapPointLogManager: MapPointLogManager
    @EnvironmentObject private var scanUtility: MapPointScanUtility
    @EnvironmentObject private var transformProcessor: TransformProcessor
    @EnvironmentObject private var orientationManager: CompassOrientationManager
    @EnvironmentObject private var beaconState: BeaconStateManager  // Added for consolidated beacon state
    
    @State private var mapUIImage: UIImage?
    @State private var overlaysReady = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                MapContainer(mapImage: mapUIImage)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    .onAppear {
                        let bounds = UIScreen.main.bounds
                        transformProcessor.setScreenCenter(CGPoint(x: bounds.midX, y: bounds.midY))
                        switchToLocation(locationManager.currentLocationID)
                    }
                    .onChange(of: geo.size) { _ in
                        // Re-read full-screen bounds to keep center in visual middle (not safe-area middle)
                        let bounds = UIScreen.main.bounds
                        transformProcessor.setScreenCenter(CGPoint(x: bounds.midX, y: bounds.midY))
                    }

                HUDContainer()
                    .opacity(overlaysReady ? 1 : 0)
            }
            .ignoresSafeArea()
            // Keep the same bootstrap wiring as before (moved here verbatim).
            .appBootstrap(
                scanner: btScanner,
                beaconDots: beaconDotStore,
                squares: metricSquares,
                lists: beaconLists,
                scanUtility: scanUtility,
                orientationManager: orientationManager,
                squareMetrics: squareMetrics,
                beaconState: beaconState,  // Pass BeaconStateManager for initialization
                mapPointStore: mapPointStore,
                mapPointLogManager: mapPointLogManager
            )
            .onChange(of: locationManager.currentLocationID) { newID in
                switchToLocation(newID)
            }
        }
    }
    
    /// Hard-wired asset routing (no sandbox, no importer)
    private func loadAssetMapImage(for locationID: String) {
        let assetName: String
        switch locationID {
        case "home":    // Chris's House
            assetName = "myFirstFloor_v03-metric"
        case "museum":  // Museum Map
            assetName = "MuseumMap-8k"
        default:
            // Fallback to Chris's House if unknown id
            assetName = "myFirstFloor_v03-metric"
        }
        mapUIImage = UIImage(named: assetName)
        if mapUIImage == nil {
            print("⚠️ Map asset '\(assetName)' not found. Check Assets.xcassets.")
        }
    }
    
    private func switchToLocation(_ id: String) {
        // 1) Namespace first
        PersistenceContext.shared.locationID = id

        // 2) Load map image (no overlays yet)
        overlaysReady = false
        loadAssetMapImage(for: id)

        // 3) Flush all overlays so nothing from the previous location shows
        beaconDotStore.clearAndReloadForActiveLocation()   // loads locks/elev/txp + dots.json
        beaconLists.flush()
        metricSquares.flush()
        mapPointStore.flush()

        // 4) Sequential loads in order (beacons/dots -> metric square -> map points)
        // We want "load-only" then reconcile for the lists; and dots already come from disk.
        beaconDotStore.clearAndReloadForActiveLocation()   // loads locks/elev/txp + dots.json
        beaconLists.loadOnly()
        beaconLists.reconcileWithLockedDots(beaconDotStore.lockedBeaconIDs())
        metricSquares.reloadForActiveLocation()
        mapPointStore.reloadForActiveLocation()

        // 5) Overlays can render now
        overlaysReady = true
    }
    
    /// Keep your existing per-location reload hooks; these just re-read namespaced state.
    private func reloadAllStores() {
        beaconDotStore.clearAndReloadForActiveLocation()
        beaconLists.clearAndReloadForActiveLocation()
        metricSquares.clearAndReloadForActiveLocation()
        mapPointStore.clearAndReloadForActiveLocation()
        // Keep list & dots aligned
        beaconLists.reconcileWithLockedDots(beaconDotStore.lockedBeaconIDs())
    }
}
