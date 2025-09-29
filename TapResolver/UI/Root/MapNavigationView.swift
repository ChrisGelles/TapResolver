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
    @EnvironmentObject private var scanUtility: MapPointScanUtility
    
    @State private var mapUIImage: UIImage?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                MapContainer(mapImage: mapUIImage)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    .onAppear {
                        mapTransform.screenCenter = CGPoint(x: geo.size.width/2, y: geo.size.height/2)
                        loadAssetMapImage(for: locationManager.currentLocationID)
                        reloadAllStores()
                    }
                    .onChange(of: geo.size) { newSize in
                        mapTransform.screenCenter = CGPoint(x: newSize.width/2, y: newSize.height/2)
                    }

                HUDContainer()
            }
            .ignoresSafeArea()
            // Keep the same bootstrap wiring as before (moved here verbatim).
            .appBootstrap(
                scanner: btScanner,
                beaconDots: beaconDotStore,
                squares: metricSquares,
                lists: beaconLists,
                scanUtility: scanUtility
            )
            .onChange(of: locationManager.currentLocationID) { newID in
                loadAssetMapImage(for: newID)
                reloadAllStores()
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
    
    /// Keep your existing per-location reload hooks; these just re-read namespaced state.
    private func reloadAllStores() {
        beaconDotStore.reloadForActiveLocation()
        beaconLists.reloadForActiveLocation()
        metricSquares.reloadForActiveLocation()
        mapPointStore.reloadForActiveLocation()
    }
}
