//
//  ContentView.swift
//  TapResolver
//
//  Created by Chris Gelles on 9/14/25.
//

import SwiftUI

// MARK: - Map reset notification
extension Notification.Name {
    static let resetMapTransform = Notification.Name("ResetMapTransform")
}

struct ContentView: View {

    @StateObject private var beaconDotStore = BeaconDotStore()
    @StateObject private var mapTransform  = MapTransformStore()
    @StateObject private var transformProcessor = TransformProcessor() // bound on appear

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Map stack (centered)
                MapContainer()
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    .onAppear {
                        // Hook up processor to the shared transform store
                        transformProcessor.bind(to: mapTransform)
                        // Keep screen center up to date for conversions
                        transformProcessor.setScreenCenter(CGPoint(x: geo.size.width / 2,
                                                                   y: geo.size.height / 2))
                    }
                    .onChange(of: geo.size) { newSize in
                        transformProcessor.setScreenCenter(CGPoint(x: newSize.width / 2,
                                                                   y: newSize.height / 2))
                    }

                // HUD overlay (full-screen, non-blocking outside drawers)
                HUDContainer()
            }
            .ignoresSafeArea()
            .environmentObject(beaconDotStore)
            .environmentObject(mapTransform)
            .environmentObject(transformProcessor)
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

    @EnvironmentObject private var transformProcessor: TransformProcessor

    // MARK: - Image
    private var uiImage: UIImage? {
        UIImage(named: "myFirstFloor_v03-metric")
    }

    var body: some View {
        Group {
            if let uiImage {
                let mapSize = CGSize(width: uiImage.size.width, height: uiImage.size.height)

                // One-time/lightweight wiring & map metadata
                setupTransformProcessing(mapSize: mapSize)

                ZStack {
                    // LAYERS
                    MapImage(uiImage: uiImage).zIndex(10)
                    MeasureLines().frame(width: mapSize.width, height: mapSize.height).zIndex(20)

                    // DOTS: draw in map-local coords so they transform with the map
                    BeaconOverlayDots()
                        .frame(width: mapSize.width, height: mapSize.height)
                        .zIndex(30)

                    BeaconOverlay().frame(width: mapSize.width, height: mapSize.height).zIndex(30)
                    UserNavigation().frame(width: mapSize.width, height: mapSize.height).zIndex(35)
                    MeterLabels().frame(width: mapSize.width, height: mapSize.height).zIndex(40)
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
                // Tap logger (local coords)
                .contentShape(Rectangle())
                .onTapGesture(coordinateSpace: .local) { location in
                    print("Tapped MapContainer at X:\(location.x), Y:\(location.y) (map size: \(Int(mapSize.width))x\(Int(mapSize.height)))")
                }
                
                // inside MapContainer.body chain, after your gestures and tap handlers:
                .onReceive(NotificationCenter.default.publisher(for: .resetMapTransform)) { _ in
                    gestures.resetTransform()
                }

                
            } else {
                Color.red // fallback
            }
        }
        .drawingGroup() // optional: offload compositing
        .allowsHitTesting(true) // Map must be interactive
    }

    // MARK: - Wiring & metadata
    @ViewBuilder
    private func setupTransformProcessing(mapSize: CGSize) -> some View {
        Color.clear
            .onAppear {
                // Tell the processor the map’s intrinsic size
                transformProcessor.setMapSize(mapSize)
                // Wire gesture totals into the processor
                gestures.onTotalsChanged = { scale, rotationRadians, offset in
                    transformProcessor.enqueueCandidate(scale: scale,
                                                        rotationRadians: rotationRadians,
                                                        offset: offset)
                }
            }
            .onChange(of: mapSize) { new in
                transformProcessor.setMapSize(new)
            }
    }
}

// The rest of your small views are unchanged
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

// HUDContainer remains here; BeaconDrawer is in its own file
struct HUDContainer: View {
    var body: some View {
        ZStack {
            Color.clear.ignoresSafeArea().allowsHitTesting(false)

            VStack(spacing: 8) {
                HStack {
                    Spacer()
                    // Right-side vertical stack: Drawer + Reset
                    VStack(alignment: .trailing, spacing: 8) {
                        BeaconDrawer()
                            .padding(.top, 60)
                            .padding(.trailing, 0)

                        // Reset View button
                        Button {
                            NotificationCenter.default.post(name: .resetMapTransform, object: nil)
                        } label: {
                            Image(systemName: "arrow.counterclockwise.circle") // pick from the list above
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
