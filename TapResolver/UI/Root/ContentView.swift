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
    @EnvironmentObject private var mapPointStore: MapPointStore  // ✅ USE APP-LEVEL INSTANCE
    @StateObject private var transformProcessor = TransformProcessor()
    @EnvironmentObject private var trianglePatchStore: TrianglePatchStore
    @EnvironmentObject private var arViewLaunchContext: ARViewLaunchContext

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
        // Unified AR View presentation (single location)
        .fullScreenCover(isPresented: Binding(
            get: { arViewLaunchContext.isPresented },
            set: { newValue in
                if !newValue {
                    arViewLaunchContext.dismiss()
                }
            }
        )) {
            ARViewWithOverlays(
                isPresented: Binding(
                    get: { arViewLaunchContext.isPresented },
                    set: { if !$0 { arViewLaunchContext.dismiss() } }
                ),
                isCalibrationMode: arViewLaunchContext.isCalibrationMode,
                selectedTriangle: arViewLaunchContext.selectedTriangle
            )
        }
        // Provide environments exactly as before + new locationManager
        .environmentObject(beaconDotStore)
        .environmentObject(hudPanels)
        .environmentObject(locationManager)
        .environmentObject(mapPointStore)
        .environmentObject(transformProcessor)
        // trianglePatchStore and arViewLaunchContext are already injected from TapResolverApp
    }
}

#Preview {
    ContentView()
}
