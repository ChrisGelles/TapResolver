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

struct HUDContainer: View {
    var body: some View {
        ZStack {
            Color.clear.ignoresSafeArea().allowsHitTesting(false)
            VStack {
                HStack {
                    Spacer()
                    BeaconDrawer()
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

struct BeaconDrawer: View {
    @EnvironmentObject private var beaconDotStore: BeaconDotStore
    @EnvironmentObject private var mapTransform: MapTransformStore

    @State private var isOpen = false
    @State private var phaseOneDone = false

    private let collapsedWidth: CGFloat = 56
    private let expandedWidth: CGFloat = 160

    private let mockBeacons = [
        "12-rowdySquirrel","15-frostyIbis","08-bouncyPenguin","23-sparklyDolphin","31-gigglyGiraffe"
    ]

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            topBar
                .frame(width: max(44, isOpen ? expandedWidth : collapsedWidth)) // expand tap area when collapsed
            beaconList
                .frame(height: isOpen && phaseOneDone ? nil : 0)
                .clipped()
                .opacity(isOpen && phaseOneDone ? 1 : 0)
        }
        .frame(width: isOpen ? expandedWidth : collapsedWidth)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.4))
        )
        .contentShape(Rectangle())
    }

    private var topBar: some View {
        HStack(spacing: 2) {
            if isOpen {
                Text("Beacons")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer(minLength: 0)
            }

            Button(action: toggleDrawer) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.black.opacity(0.4)))
                    .rotationEffect(.degrees(isOpen ? 180 : 0))
                    .contentShape(Circle())
            }
            .accessibilityLabel(isOpen ? "Close beacon drawer" : "Open beacon drawer")
        }
        .padding(.horizontal, 12)
        .frame(height: 48)
    }

    private var beaconList: some View {
        let sorted = mockBeacons.sorted()
        return ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(sorted, id: \.self) { name in
                    BeaconListItem(beaconName: name) { globalTapPoint, color in
                        // 1) 20 px left of tap (in GLOBAL coords)
                        let shifted = CGPoint(x: globalTapPoint.x - 20, y: globalTapPoint.y)
                        // 2) Convert to MAP-LOCAL coords using current transform
                        let mapPoint = mapTransform.screenToMap(shifted)
                        // 3) Toggle the dot for this beacon
                        beaconDotStore.toggleDot(for: name, mapPoint: mapPoint, color: color)
                        // 4) Close the drawer
                        closeDrawer()
                    }
                    .frame(height: 44)
                }
            }
            .padding(.bottom, 8)
        }
        .frame(maxHeight: 300) // cap if list is long
        .fixedSize(horizontal: false, vertical: true)
        .transition(.opacity)
    }

    private func toggleDrawer() { isOpen ? closeDrawer() : openDrawer() }

    private func openDrawer() {
        withAnimation(.easeInOut(duration: 0.25)) { isOpen = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeInOut(duration: 0.25)) { phaseOneDone = true }
        }
    }

    private func closeDrawer() {
        withAnimation(.easeInOut(duration: 0.25)) { phaseOneDone = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeInOut(duration: 0.25)) { isOpen = false }
        }
    }
}

struct BeaconListItem: View {
    let beaconName: String
    var onSelect: ((CGPoint, Color) -> Void)? = nil

    private var beaconColor: Color {
        let hash = beaconName.hash
        let hue = Double(abs(hash % 360)) / 360.0
        return Color(hue: hue, saturation: 0.7, brightness: 0.8)
    }

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(beaconColor)
                .frame(width: 12, height: 12)

            Text(beaconName)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(beaconColor.opacity(0.2))
        )
        .contentShape(Rectangle())
        // capture tap in GLOBAL space and pass to callback
        .onTapGesture(coordinateSpace: .global) { globalPoint in
            onSelect?(globalPoint, beaconColor)
        }
    }
}

#Preview {
    ContentView()
}
