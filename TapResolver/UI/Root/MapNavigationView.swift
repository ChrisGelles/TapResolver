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

    var body: some View {
        GeometryReader { geo in
            ZStack {
                MapContainer()
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    .onAppear {
                        mapTransform.screenCenter = CGPoint(x: geo.size.width / 2,
                                                            y: geo.size.height / 2)
                    }
                    .onChange(of: geo.size) { newSize in
                        mapTransform.screenCenter = CGPoint(x: newSize.width  / 2,
                                                            y: newSize.height / 2)
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
                scanUtility: MapPointScanUtility(
                    isExcluded: { _, _ in true },
                    resolveBeaconMeta: { _ in
                        MapPointScanUtility.BeaconMeta(
                            beaconID: "", name: "",
                            posX_m: nil, posY_m: nil, posZ_m: nil,
                            txPowerSettingDbm: nil
                        )
                    }
                )
            )
        }
    }
}
