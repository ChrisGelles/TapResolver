//
//  MapContainer.swift
//  TapResolver
//
//  Created by restructuring on 9/19/25.
//

import SwiftUI
import CoreGraphics

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
            
            // Map Point overlay (z = 29)
            MapPointOverlay()
                .frame(width: mapSize.width, height: mapSize.height)
                .zIndex(29)

            // Your other overlays on top (z >= 30)
            BeaconOverlay()
                .frame(width: mapSize.width, height: mapSize.height)
                .zIndex(30)

            UserNavigation()
                .frame(width: mapSize.width, height: mapSize.height)
                .zIndex(35)

            RSSILabelsOverlay()
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
