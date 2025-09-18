//
//  ContentView.swift
//  TapResolver
//
//  Created by Chris Gelles on 9/14/25.
//

import SwiftUI
import CoreGraphics

// MARK: - Map reset notification
extension Notification.Name {
    static let resetMapTransform = Notification.Name("ResetMapTransform")
}

struct ContentView: View {

    // Dots + transform stores
    @StateObject private var beaconDotStore = BeaconDotStore()
    @StateObject private var mapTransform  = MapTransformStore()

    // HUD state + metric squares store
    @StateObject private var hudPanels = HUDPanelsState()
    @StateObject private var metricSquares = MetricSquareStore()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Map stack (centered)
                MapContainer()
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    // Keep screen center up to date for conversions
                    .onAppear {
                        mapTransform.screenCenter = CGPoint(x: geo.size.width / 2,
                                                            y: geo.size.height / 2)
                    }
                    .onChange(of: geo.size) { newSize in
                        mapTransform.screenCenter = CGPoint(x: newSize.width / 2,
                                                            y: newSize.height / 2)
                    }

                // HUD overlay (full-screen, non-blocking outside drawers)
                HUDContainer()
            }
            .ignoresSafeArea()
            // Environment for overlays + drawers
            .environmentObject(beaconDotStore)
            .environmentObject(mapTransform)
            .environmentObject(hudPanels)
            .environmentObject(metricSquares)
        }
    }
}

struct MapContainer: View {
    // Gesture/state controller
    @StateObject private var gestures = MapGestureHandler(
        minScale: 0.5,
        maxScale: 4.0,
        zoomStep: 1.25
    )

    @EnvironmentObject private var mapTransform: MapTransformStore

    // MARK: - Image
    private var uiImage: UIImage? {
        UIImage(named: "myFirstFloor_v03-metric")
    }

    var body: some View {
        Group {
            if let uiImage {
                let mapSize = CGSize(width: uiImage.size.width, height: uiImage.size.height)

                // keep transform store in sync with the map
                updateTransformBindings(mapSize: mapSize)

                ZStack {
                    // LAYERS
                    MapImage(uiImage: uiImage)                                   // z = 10
                        .zIndex(10)

                    MeasureLines()
                        .frame(width: mapSize.width, height: mapSize.height)       // z = 20
                        .zIndex(20)

                    // DOTS: draw in map-local coords so they transform with the map
                    BeaconOverlayDots()
                        .frame(width: mapSize.width, height: mapSize.height)       // z = 28
                        .zIndex(28)

                    // SQUARES: between dots and BeaconOverlay
                    MetricSquaresOverlay()
                        .frame(width: mapSize.width, height: mapSize.height)       // z = 29
                        .zIndex(29)

                    BeaconOverlay()
                        .frame(width: mapSize.width, height: mapSize.height)       // z = 30
                        .zIndex(30)

                    UserNavigation()
                        .frame(width: mapSize.width, height: mapSize.height)       // z = 35
                        .zIndex(35)

                    MeterLabels()
                        .frame(width: mapSize.width, height: mapSize.height)       // z = 40
                        .zIndex(40)
                }
                .frame(width: mapSize.width, height: mapSize.height)
                // Apply transforms (scale -> rotate -> translate)
                .scaleEffect(gestures.totalScale, anchor: .center)
                .rotationEffect(gestures.totalRotation)
                .offset(
                    x: gestures.totalOffset.width,
                    y: gestures.totalOffset.height
                )
                // Attach combined gestures
                .gesture(gestures.combinedGesture)
                // Double-tap to zoom in
                .onTapGesture(count: 2) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        gestures.doubleTapZoom()
                    }
                }
                // Reset listener (from HUD)
                .onReceive(NotificationCenter.default.publisher(for: .resetMapTransform)) { _ in
                    gestures.resetTransform()
                }
                // Tap logger (local coords)
                .contentShape(Rectangle())
                .onTapGesture(coordinateSpace: .local) { location in
                    print("Tapped MapContainer at X:\(location.x), Y:\(location.y) (map size: \(Int(mapSize.width))x\(Int(mapSize.height)))")
                }
            } else {
                Color.red // fallback
            }
        }
        .drawingGroup() // optional: offload compositing
        .allowsHitTesting(true) // Map must be interactive
    }

    // Keep MapTransformStore synchronized with current transform + size
    @ViewBuilder
    private func updateTransformBindings(mapSize: CGSize) -> some View {
        Color.clear
            .onAppear {
                mapTransform.mapSize = mapSize
                pushTransform()
            }
            .onChange(of: gestures.totalScale) { _ in pushTransform() }
            .onChange(of: gestures.totalRotation) { _ in pushTransform() }
            .onChange(of: gestures.totalOffset) { _ in pushTransform() }
            .onChange(of: mapSize) { new in
                mapTransform.mapSize = new
                pushTransform()
            }
    }

    private func pushTransform() {
        mapTransform.totalScale = gestures.totalScale
        mapTransform.totalRotationRadians = CGFloat(gestures.totalRotation.radians)
        mapTransform.totalOffset = gestures.totalOffset
    }
}

// Basic layers (placeholders for now)
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

// HUD with drawers and a reset button
struct HUDContainer: View {
    var body: some View {
        ZStack {
            Color.clear.ignoresSafeArea().allowsHitTesting(false)
            VStack(spacing: 8) {
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 8) {
                        // Metric Squares drawer
                        MetricSquareDrawer()
                            .padding(.top, 60)
                            .padding(.trailing, 0)

                        // Beacons drawer
                        BeaconDrawer()

                        // Reset View button
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
                    }
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .allowsHitTesting(true) // the HUD’s interactive bits
        }
        .zIndex(100)
    }
}

#Preview {
    ContentView()
}
