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
    let mapImage: UIImage?

    var body: some View {
        if let mapImage {
            MapCanvas(uiImage: mapImage)
        } else {
            // Fallback when no map image is available
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .overlay(
                    Text("No map image")
                        .foregroundColor(.white.opacity(0.7))
                )
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
    @EnvironmentObject private var transformProcessor: TransformProcessor
    @EnvironmentObject private var metricSquares: MetricSquareStore
    @EnvironmentObject private var hud: HUDPanelsState

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
                .zIndex(hud.isSquareOpen ? 32 : 25)
            
            // Dots rendered in map-local coords (z = 28)
            BeaconOverlayDots()
                .frame(width: mapSize.width, height: mapSize.height)
                .zIndex(28)
            
            // Triangle overlay (z = 27)
            TriangleOverlay()
                .frame(width: mapSize.width, height: mapSize.height)
                .zIndex(27)
            
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
            transformProcessor.setMapSize(mapSize)
            // REPLACE the three direct assignments with a single push:
            pushTransformTotals()

            // 🔧 Wire live updates from gestures -> transform processor every frame
            gestures.onTotalsChanged = { scale, rotationRadians, offset in
                transformProcessor.enqueueCandidate(
                    scale: scale,
                    rotationRadians: rotationRadians,
                    offset: offset
                )
            }
            
        }
        .onReceive(Timer.publish(every: 5.0, on: .main, in: .common).autoconnect()) { _ in
            if !mapTransform.isTransformValid {
                print("🚨 [TRANSFORM] Invalid state detected!")
                mapTransform.printDiagnostics(label: "INVALID")
            }
        }

        // Apply transforms (scale → rotate → translate)
        .scaleEffect(mapTransform.totalScale, anchor: .center)
        .rotationEffect(.radians(mapTransform.totalRotationRadians))
        .offset(mapTransform.totalOffset)

        .overlay(
            PinchRotateCentroidBridge { update in
                switch update.phase {
                case .began:
                    mapTransform.beginPinch(atCentroidScreen: update.centroidInScreen)
                    
                case .changed:
                    mapTransform.updatePinch(
                        pinchScale: update.scale,
                        pinchRotation: update.rotationRadians,
                        centroidScreen: update.centroidInScreen
                    )
                    
                case .ended, .cancelled:
                    mapTransform.endPinch()
                    // Sync GestureHandler's steady state to match final transform
                    // This prevents a jump when the next gesture starts
                    gestures.syncToExternalTransform(
                        scale: mapTransform.totalScale,
                        rotation: Angle(radians: Double(mapTransform.totalRotationRadians)),
                        offset: mapTransform.totalOffset
                    )
                    // Explicitly sync TransformProcessor's cache to prevent stale comparisons
                    transformProcessor.enqueueCandidate(
                        scale: mapTransform.totalScale,
                        rotationRadians: mapTransform.totalRotationRadians,
                        offset: mapTransform.totalOffset
                    )
                    
                default:
                    break
                }
            }
            .ignoresSafeArea()
        )
        // Gestures: pan only — pinch/rotate handled by PinchRotateCentroidBridge
        .gesture(gestures.panOnlyGesture)
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
       // .drawingGroup()
        // REMOVE this .drawingGroup() for now; it conflicts with the UIViewRepresentable overlay.

        .allowsHitTesting(true)
    }

    // MARK: - Keep MapTransformStore in sync (size + current composite transform)
    @ViewBuilder
    private func syncTransformStore(mapSize: CGSize) -> some View {
        Color.clear
            .onAppear {
                transformProcessor.setMapSize(mapSize)
                pushTransformTotals()
            }
            .onChange(of: gestures.totalScale)   {  pushTransformTotals() }
            .onChange(of: gestures.totalRotation){  pushTransformTotals() }
            .onChange(of: gestures.totalOffset)  {  pushTransformTotals() }
            .onChange(of: mapSize)               {
                transformProcessor.setMapSize(mapSize)
                pushTransformTotals()
                
                // Only print when we have a valid size
                if mapSize.width > 0 && mapSize.height > 0 {
                    print("MapCanvas mapTransform:", ObjectIdentifier(mapTransform),
                          "mapSize:", mapTransform.mapSize)
                }
            }
    }

    private func pushTransformTotals() {
        transformProcessor.enqueueCandidate(
            scale: gestures.totalScale,
            rotationRadians: gestures.totalRotation.radians,
            offset: gestures.totalOffset
        )
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
struct BeaconOverlay: View { var body: some View { Color.clear } }
struct UserNavigation: View { var body: some View { Color.clear } }
