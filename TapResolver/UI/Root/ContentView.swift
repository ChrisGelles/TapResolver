import SwiftUI
import CoreGraphics

// MARK: - Notifications
extension Notification.Name {
    static let resetMapTransform = Notification.Name("ResetMapTransform")
    static let rssiStateChanged  = Notification.Name("RSSIStateChanged")
}

struct ContentView: View {
    // State ownership unchanged:
    @StateObject private var beaconDotStore = BeaconDotStore()
    @EnvironmentObject private var mapTransform: MapTransformStore
    @EnvironmentObject private var squareMetrics: SquareMetrics
    @EnvironmentObject private var metricSquares: MetricSquareStore
    @EnvironmentObject private var beaconLists: BeaconListsStore
    @EnvironmentObject private var btScanner: BluetoothScanner
    @StateObject private var hudPanels     = HUDPanelsState()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var mapPointStore = MapPointStore()
    @StateObject private var transformProcessor = TransformProcessor()

    var body: some View {
        Group {
            if locationManager.showLocationMenu {
                LocationMenuView()
            } else {
                MapNavigationView()
            }
        }
        .onAppear {
            transformProcessor.bind(to: mapTransform)
            transformProcessor.passThrough = true   // keep UX identical for now
        }
        // Provide environments exactly as before + new locationManager
        .environmentObject(beaconDotStore)
        .environmentObject(hudPanels)
        .environmentObject(locationManager)
        .environmentObject(mapPointStore)
        .environmentObject(transformProcessor)
    }
}

#Preview {
    ContentView()
}
