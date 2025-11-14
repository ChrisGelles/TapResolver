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
    @EnvironmentObject private var transformProcessor: TransformProcessor
    @EnvironmentObject private var orientationManager: CompassOrientationManager
    @EnvironmentObject private var beaconState: BeaconStateManager  // Added for consolidated beacon state
    @EnvironmentObject private var trianglePatchStore: TrianglePatchStore
    @EnvironmentObject private var arCalibrationCoordinator: ARCalibrationCoordinator
    
    @State private var mapUIImage: UIImage?
    @State private var overlaysReady = false
    @State private var showARCalibration = false
    @State private var showPhotoManager = false
    @State private var photoManagerLocationID = ""

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
                mapPointStore: mapPointStore
            )
            .onChange(of: locationManager.currentLocationID) { newID in
                switchToLocation(newID)
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PresentARCalibration"))) { notification in
                guard let triangleID = notification.userInfo?["triangleID"] as? UUID else { return }
                
                // Get triangle vertices
                if let triangle = trianglePatchStore.triangles.first(where: { $0.id == triangleID }) {
                    arCalibrationCoordinator.setVertices(triangle.vertexIDs)
                    
                    // Set first vertex as target
                    if let firstVertexID = triangle.vertexIDs.first,
                       let mapPoint = mapPointStore.points.first(where: { $0.id == firstVertexID }) {
                        
                        // Try to load from disk first, fall back to memory if needed
                        var photoData: Data? = nil
                        if let diskData = mapPointStore.loadPhotoFromDisk(for: firstVertexID) {
                            photoData = diskData
                        } else if let memoryData = mapPoint.locationPhotoData {
                            // Legacy: photo still in memory
                            photoData = memoryData
                        }
                        
                        arCalibrationCoordinator.setReferencePhoto(photoData)
                        
                        // Present AR view
                        print("📱 Presenting AR view for calibration")
                        showARCalibration = true
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TriangleCalibrationComplete"))) { notification in
                guard let triangleID = notification.userInfo?["triangleID"] as? UUID,
                      let vertices = notification.userInfo?["vertices"] as? [UUID],
                      let triangleIndex = trianglePatchStore.triangles.firstIndex(where: { $0.id == triangleID }) else {
                    return
                }
                
                // Collect AR marker IDs from the 3 vertices
                var markerIDs: [String] = []
                for vertexID in vertices {
                    if let mapPoint = mapPointStore.points.first(where: { $0.id == vertexID }),
                       let markerID = mapPoint.arMarkerID {
                        markerIDs.append(markerID)
                    }
                }
                
                guard markerIDs.count == 3 else {
                    print("⚠️ Expected 3 AR marker IDs, got \(markerIDs.count)")
                    return
                }
                
                // Update triangle with calibration data
                trianglePatchStore.triangles[triangleIndex].isCalibrated = true
                trianglePatchStore.triangles[triangleIndex].arMarkerIDs = markerIDs
                trianglePatchStore.triangles[triangleIndex].lastCalibratedAt = Date()
                trianglePatchStore.triangles[triangleIndex].calibrationQuality = 1.0  // Full quality for now
                
                trianglePatchStore.save()
                
                print("✅ Marked triangle \(String(triangleID.uuidString.prefix(8))) as calibrated")
                print("   AR Marker IDs: \(markerIDs.map { String($0.prefix(8)) })")
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LaunchPhotoManager"))) { notification in
                guard let locationID = notification.userInfo?["locationID"] as? String else { return }
                photoManagerLocationID = locationID
                showPhotoManager = true
            }
            .sheet(isPresented: $showARCalibration) {
                ARCalibrationView(
                    isPresented: $showARCalibration,
                    mapPointID: arCalibrationCoordinator.getCurrentVertexID(),
                    interpolationFirstPointID: nil,
                    interpolationSecondPointID: nil
                )
            }
            .sheet(isPresented: $showPhotoManager) {
                PhotoManagementView(
                    isPresented: $showPhotoManager,
                    locationID: photoManagerLocationID
                )
            }
        }
    }
    
    private func loadAssetMapImage(for locationID: String) {
        // Try loading from Documents (for user-created locations)
        if let image = LocationImportUtils.loadDisplayImage(locationID: locationID) {
            mapUIImage = image
            print("✅ Loaded map image for '\(locationID)' from Documents")
            return
        }
        
        // Fallback to bundled assets for hardcoded locations
        let assetName: String
        switch locationID {
        case "home":
            assetName = "myFirstFloor_v03-metric"
        case "museum":
            assetName = "MuseumMap-8k"
        default:
            print("⚠️ No map image found for locationID: '\(locationID)'")
            mapUIImage = nil
            return
        }
        
        mapUIImage = UIImage(named: assetName)
        if mapUIImage == nil {
            print("⚠️ Map asset '\(assetName)' not found in bundle")
        } else {
            print("✅ Loaded bundled asset '\(assetName)'")
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
        trianglePatchStore.load()  // Reload triangles for new location

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
