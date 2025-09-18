//
//  ContentView.swift
//  TapResolver
//
//  Created by Chris Gelles on 9/14/25.
//

import SwiftUI

struct ContentView: View {

    @StateObject private var beaconDotStore = BeaconDotStore()
    @StateObject private var mapTransform  = MapTransformStore()

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
            .environmentObject(beaconDotStore)
            .environmentObject(mapTransform)
        }
    }
}

struct MapContainer: View {
    // Gesture/state controller (your existing handler)
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

// HUDContainer remains here; BeaconDrawer is now in its own file
struct HUDContainer: View {
    var body: some View {
        ZStack {
            Color.clear.ignoresSafeArea().allowsHitTesting(false)
            VStack {
                HStack {
                    Spacer()
                    BeaconDrawer() // lives in BeaconDrawer.swift
                        .padding(.top, 60)     // below status bar / black bar
                        .padding(.trailing, 0) // closer to right edge
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .allowsHitTesting(true) // the only interactive thing in the HUD
        }
        .zIndex(100)
    }
}

#Preview {
    ContentView()
}
