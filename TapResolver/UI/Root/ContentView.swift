import SwiftUI
import CoreGraphics

// MARK: - Notifications
extension Notification.Name {
    static let resetMapTransform = Notification.Name("ResetMapTransform")
    static let rssiStateChanged  = Notification.Name("RSSIStateChanged")
}

// Timestamp helper - uses app launch time if available
private func cvLog(_ message: String) {
    let now = Date()
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss.SSS"
    print("⏱️ [\(formatter.string(from: now))] \(message)")
}

struct ContentView: View {
    // Use app-level instances (injected from TapResolverApp)
    @EnvironmentObject private var beaconDotStore: BeaconDotStore  // Changed from @StateObject
    @EnvironmentObject private var mapTransform: MapTransformStore
    @EnvironmentObject private var squareMetrics: SquareMetrics
    @EnvironmentObject private var metricSquares: MetricSquareStore
    @EnvironmentObject private var beaconLists: BeaconListsStore
    @EnvironmentObject private var btScanner: BluetoothScanner
    @EnvironmentObject private var hudPanels: HUDPanelsState       // Changed from @StateObject
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var mapPointStore: MapPointStore  // ✅ USE APP-LEVEL INSTANCE
    @EnvironmentObject private var transformProcessor: TransformProcessor
    @EnvironmentObject private var trianglePatchStore: TrianglePatchStore
    @EnvironmentObject private var arViewLaunchContext: ARViewLaunchContext
    @EnvironmentObject private var surveySelectionCoordinator: SurveySelectionCoordinator

    var body: some View {
        Group {
            if locationManager.showLocationMenu {
                LocationMenuView()
            } else {
                MapNavigationView()
            }
        }
        .onAppear {
            cvLog("[CONTENT_VIEW] onAppear STARTED")
            transformProcessor.bind(to: mapTransform)
            transformProcessor.passThrough = true   // keep UX identical for now
            cvLog("[CONTENT_VIEW] onAppear COMPLETE")
        }
        // Unified AR View presentation (single location)
        .fullScreenCover(isPresented: Binding(
            get: { arViewLaunchContext.isPresented },
            set: { newValue in
                if !newValue {
                    arViewLaunchContext.dismiss()
                    surveySelectionCoordinator.reset()
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
            .environmentObject(arViewLaunchContext)
        }
        // Provide mapPointStore (locationManager and transformProcessor now come from app level)
        .environmentObject(mapPointStore)
        // trianglePatchStore and arViewLaunchContext are already injected from TapResolverApp
    }
}

#Preview {
    ContentView()
}
