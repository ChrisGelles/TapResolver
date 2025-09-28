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
    @StateObject private var hudPanels     = HUDPanelsState()
    @StateObject private var metricSquares = MetricSquareStore()
    @StateObject private var squareMetrics = SquareMetrics()
    @StateObject private var beaconLists   = BeaconListsStore()
    @StateObject private var btScanner     = BluetoothScanner()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var mapPointStore = MapPointStore()

    var body: some View {
        Group {
            if locationManager.showLocationMenu {
                LocationMenuView()
            } else {
                MapNavigationView()
            }
        }
        // Provide environments exactly as before + new locationManager
        .environmentObject(beaconDotStore)
        .environmentObject(hudPanels)
        .environmentObject(metricSquares)
        .environmentObject(squareMetrics)
        .environmentObject(beaconLists)
        .environmentObject(btScanner)
        .environmentObject(locationManager)
        .environmentObject(mapPointStore)
    }
}

#Preview {
    ContentView()
}
