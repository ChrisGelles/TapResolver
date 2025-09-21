//
//  ContentView.swift
//  TapResolver
//
//  Created by Chris Gelles on 9/14/25.
//

import SwiftUI
import CoreGraphics

// MARK: - Map reset notification (used by the HUD reset button)
extension Notification.Name {
    static let resetMapTransform = Notification.Name("ResetMapTransform")
}

struct ContentView: View {

    // Global app state objects used across views
    @StateObject private var beaconDotStore = BeaconDotStore()   // dots (map-local)
    @EnvironmentObject private var mapTransform: MapTransformStore
    @StateObject private var hudPanels     = HUDPanelsState()     // drawer exclusivity
    @StateObject private var metricSquares = MetricSquareStore()  // squares (map-local)
    @StateObject private var squareMetrics = SquareMetrics()
    @StateObject private var beaconLists   = BeaconListsStore()   // ← added
    @StateObject private var btScanner     = BluetoothScanner()       // ← Bluetooth scanner

    // One-shot scan window (seconds) used on app open
    private let INITIAL_SCAN_WINDOW_SEC: TimeInterval = 2.0

    /// Kick off a brief BLE scan, then stop, dump table, and ingest discovered devices.
    private func runInitialScan() {
        // Start immediately (safe if not powered on; we'll re-try shortly)
        btScanner.start()

        // Re-try shortly in case the central wasn't powered on yet
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.btScanner.start()
        }

        // Stop after the window, print a snapshot table, and ingest into lists
        DispatchQueue.main.asyncAfter(deadline: .now() + INITIAL_SCAN_WINDOW_SEC) {
            self.btScanner.dumpSummaryTable()
            self.btScanner.stop()

            // Clear unlocked beacons and morgue before ingesting new devices
            self.refreshBeaconLists()
            
            // Ingest each unique device by (name, id)
            for d in self.btScanner.devices {
                self.beaconLists.ingest(deviceName: d.name, id: d.id)
            }
        }
    }
    
    /// Refresh beacon lists by clearing unlocked beacons and morgue
    private func refreshBeaconLists() {
        // Get locked beacon names from beaconDotStore
        let lockedBeaconNames = beaconDotStore.locked.keys.filter { beaconDotStore.isLocked($0) }
        
        // Clear unlocked beacons and morgue
        beaconLists.clearUnlockedBeacons(lockedBeaconNames: lockedBeaconNames)
        beaconLists.morgue.removeAll()
    }
    
    /// Load locked items on app launch (beacons and squares)
    private func loadLockedItems() {
        // Restore locked beacon dots and their positions
        beaconDotStore.restoreLockedDots()
        
        // Squares are already loaded by their respective stores in init()
        // No additional action needed for squares
    }

    

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Map stack (centered on the device screen)
                MapContainer()
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    // Keep the "screen center" in sync so screen<->map conversions are correct
                    .onAppear {
                        mapTransform.screenCenter = CGPoint(x: geo.size.width  / 2,
                                                            y: geo.size.height / 2)
                    }
                    .onChange(of: geo.size) { newSize in
                        mapTransform.screenCenter = CGPoint(x: newSize.width  / 2,
                                                            y: newSize.height / 2)
                    }

                // HUD overlay (drawers + reset) — non-blocking outside its own controls
                HUDContainer()
            }
            .ignoresSafeArea()
            // Inject environment objects once at the root so all children can use them
            .environmentObject(beaconDotStore)
            .environmentObject(hudPanels)
            .environmentObject(metricSquares)
            .environmentObject(squareMetrics)
            .environmentObject(beaconLists)    // ← added
            .environmentObject(btScanner)
            .onAppear {
                // App Launch Sequence: Load locked items first
                loadLockedItems()
                
                // Then run initial scan to discover new devices
                runInitialScan()
            }
        }
    }
}

// MARK: - The host view for the map image + overlays + gesture transforms
struct MapContainer: View {
    private var uiImage: UIImage? { UIImage(named: "myFirstFloor_v03-metric") }

    var body: some View {
        if let uiImage {
            MapCanvas(uiImage: uiImage)
        } else {
            Color.red
        }
    }
}

private struct MapCanvas: View {
    @StateObject private var gestures = MapGestureHandler(
        minScale: 0.5,
        maxScale: 4.0,
        zoomStep: 1.25
    )

    @EnvironmentObject private var mapTransform: MapTransformStore
    @EnvironmentObject private var metricSquares: MetricSquareStore

    let uiImage: UIImage

    var body: some View {
        let mapSize = CGSize(width: uiImage.size.width, height: uiImage.size.height)

        syncTransformStore(mapSize: mapSize)

        return ZStack {
            // Base map image (z = 10)
            MapImage(uiImage: uiImage)
                .zIndex(10)

            // Optional measurement layer (z = 20)
            MeasureLines()
                .frame(width: mapSize.width, height: mapSize.height)
                .zIndex(20)
            // Shield map gestures while a square is being dragged/resized,
            // but keep the squares themselves interactive (they render above this).
            if metricSquares.isInteracting {
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: .infinity))
                    .zIndex(25) // below dots(28) and squares(29), above map(10)/measure(20)
            }

            // >>> INSERTED: MetricSquaresOverlay between dots (z=28) and BeaconOverlay (z=30)
            MetricSquaresOverlay()
                .frame(width: mapSize.width, height: mapSize.height)
                .zIndex(25)
            
            // Dots rendered in map-local coords (z = 28)
            BeaconOverlayDots()
                .frame(width: mapSize.width, height: mapSize.height)
                .zIndex(28)

            // Your other overlays on top (z >= 30)
            BeaconOverlay()
                .frame(width: mapSize.width, height: mapSize.height)
                .zIndex(30)

            UserNavigation()
                .frame(width: mapSize.width, height: mapSize.height)
                .zIndex(35)

            MeterLabels()
                .frame(width: mapSize.width, height: mapSize.height)
                .zIndex(40)
        }
        .frame(width: mapSize.width, height: mapSize.height)

        .onAppear {
            // Eagerly initialize the transform store so drawers can convert immediately.
            mapTransform.mapSize = mapSize
            mapTransform.totalScale = gestures.totalScale
            mapTransform.totalRotationRadians = CGFloat(gestures.totalRotation.radians)
            mapTransform.totalOffset = gestures.totalOffset

            // 🔧 Wire live updates from gestures -> transform store every frame
            gestures.onTotalsChanged = { scale, rotationRadians, offset in
                mapTransform.totalScale = scale
                mapTransform.totalRotationRadians = rotationRadians
                mapTransform.totalOffset = offset
            }
            
            print("MapCanvas mapTransform:", ObjectIdentifier(mapTransform),
                  "mapSize:", mapTransform.mapSize)
        }

        // Apply transforms (scale → rotate → translate)
        .scaleEffect(gestures.totalScale, anchor: .center)
        .rotationEffect(gestures.totalRotation)
        .offset(x: gestures.totalOffset.width, y: gestures.totalOffset.height)

        // Gestures; disable while a square is interacting
        .gesture(gestures.combinedGesture)
        //.disabled(metricSquares.isInteracting)

        .onTapGesture(count: 2) {
            withAnimation(.easeInOut(duration: 0.2)) {
                gestures.doubleTapZoom()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .resetMapTransform)) { _ in
            gestures.resetTransform()
        }
        .contentShape(Rectangle())
        .onTapGesture(coordinateSpace: .local) { location in
            print("Tapped MapContainer @ X:\(Int(location.x)) Y:\(Int(location.y))  " +
                  "(map size: \(Int(mapSize.width))x\(Int(mapSize.height)))")
        }
        .drawingGroup()
        .allowsHitTesting(true)
    }

    // MARK: - Keep MapTransformStore in sync (size + current composite transform)
    @ViewBuilder
    private func syncTransformStore(mapSize: CGSize) -> some View {
        Color.clear
            .onAppear {
                mapTransform.mapSize = mapSize
                pushTransformTotals()
            }
            .onChange(of: gestures.totalScale)   { _ in pushTransformTotals() }
            .onChange(of: gestures.totalRotation){ _ in pushTransformTotals() }
            .onChange(of: gestures.totalOffset)  { _ in pushTransformTotals() }
            .onChange(of: mapSize)               { _ in
                mapTransform.mapSize = mapSize
                pushTransformTotals()
            }
    }

    private func pushTransformTotals() {
        mapTransform.totalScale = gestures.totalScale
        mapTransform.totalRotationRadians = CGFloat(gestures.totalRotation.radians)
        mapTransform.totalOffset = gestures.totalOffset
    }
}

// Basic layers kept intact
struct MapImage: View {
    let uiImage: UIImage
    var body: some View {
        Image(uiImage: uiImage)
            .resizable()
            .frame(width: uiImage.size.width, height: uiImage.size.height)
    }
}
struct MeasureLines: View { var body: some View { Color.clear } }
struct BeaconOverlay: View { var body: some View { Color.clear } }
struct UserNavigation: View { var body: some View { Color.clear } }
struct MeterLabels: View { var body: some View { Color.clear } }

// HUD container unchanged except for including both drawers (as you already have)
struct HUDContainer: View {
    var body: some View {
        ZStack {
            Color.clear.ignoresSafeArea().allowsHitTesting(false)
            CrosshairHUDOverlay() // shows crosshairs at screen center when beacons drawer is open
            VStack(spacing: 8) {
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 8) {
                        MetricSquareDrawer()
                            .padding(.top, 60)
                            .padding(.trailing, 0)
                        BeaconDrawer()
                        MorgueDrawer()                  // ← added, sits next to Beacon drawer
                        Button {
                            NotificationCenter.default.post(name: .resetMapTransform, object: nil)
                        } label: {
                            Image(systemName: "arrow.counterclockwise.circle")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.primary)
                                .padding(10)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                        .accessibilityLabel("Reset map view")
                        .buttonStyle(.plain)
                        .allowsHitTesting(true)
                        
                        // Radio waves button: start scan + dump snapshot to console
                        BluetoothScanButton()

                    }
                    
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .allowsHitTesting(true)
            
            // Numeric keypad for square meters (only visible when editing)
            NumericKeypadOverlay()
                .zIndex(200)                  // above everything in the HUD
                .allowsHitTesting(true)       // it must receive touches when shown
        }
        .zIndex(100)
    }
}

private struct BluetoothScanButton: View {
    @EnvironmentObject private var btScanner: BluetoothScanner
    @EnvironmentObject private var beaconLists: BeaconListsStore
    @EnvironmentObject private var beaconDotStore: BeaconDotStore

    var body: some View {
        Button {
            // 1) Run a clean snapshot scan for N seconds (see BluetoothScanner.defaultSnapshotSeconds)
            btScanner.snapshotScan { [weak btScanner, weak beaconLists, weak beaconDotStore] in
                guard let scanner = btScanner, let lists = beaconLists, let dotStore = beaconDotStore else { return }

                // 2) Clear unlocked beacons and morgue before ingesting new devices
                let lockedBeaconNames = dotStore.locked.keys.filter { dotStore.isLocked($0) }
                lists.clearUnlockedBeacons(lockedBeaconNames: lockedBeaconNames)
                lists.morgue.removeAll()

                // 3) After snapshot completes, (re)build lists from what we saw
                for d in scanner.devices {
                    lists.ingest(deviceName: d.name, id: d.id)
                }

                // 4) Optional: print a neat table once per snapshot
                scanner.dumpSummaryTable()
            }
        } label: {
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.primary)
                .padding(10)
                .background(.ultraThinMaterial, in: Circle())
        }
        .accessibilityLabel("Scan Bluetooth (2-second snapshot) & update lists")
        .buttonStyle(.plain)
        .allowsHitTesting(true)
    }
}

#Preview {
    ContentView()
}
