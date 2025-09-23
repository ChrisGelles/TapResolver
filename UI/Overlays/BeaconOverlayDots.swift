//
//  BeaconOverlayDots.swift
//  TapResolver
//
//  Created by restructuring on 9/19/25.
//

import SwiftUI
import CoreGraphics

// MARK: - A single dot view (with white ring)
public struct BeaconDot: View {
    public let color: Color
    public var size: CGFloat = 20

    public init(color: Color, size: CGFloat = 20) {
        self.color = color
        self.size = size
    }

    public var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .overlay(
                Circle().stroke(Color.white, lineWidth: 2)
            )
            .accessibilityHidden(true)
    }
}

// MARK: - Renderer: draw all dots in map-local space (draggable with small hit target)
public struct BeaconOverlayDots: View {
    @EnvironmentObject private var store: BeaconDotStore

    public init() {}

    public var body: some View {
        ZStack {
            ForEach(store.dots) { dot in
                DraggableDot(dot: dot)
            }
        }
        .allowsHitTesting(true)
    }

    // MARK: - Single draggable dot subview
    private struct DraggableDot: View {
        let dot: BeaconDotStore.Dot
        @EnvironmentObject private var store: BeaconDotStore
        @EnvironmentObject private var mapTransform: MapTransformStore

        private let dotSize: CGFloat = 20
        private let hitPadding: CGFloat = 5

        @State private var startPoint: CGPoint? = nil

        var body: some View {
            let locked = store.isLocked(dot.beaconID)

            ZStack {
                BeaconDot(color: dot.color, size: dotSize)
            }
            .frame(width: dotSize + 2 * hitPadding,
                   height: dotSize + 2 * hitPadding,
                   alignment: .center)
            .contentShape(Circle())
            .position(x: dot.mapPoint.x, y: dot.mapPoint.y)
            // 🚫 Disable dragging when locked
            .allowsHitTesting(!locked)
            .gesture(
                DragGesture(minimumDistance: 6)
                    .onChanged { value in
                        guard !locked else { return }
                        if startPoint == nil { startPoint = dot.mapPoint }
                        let dMap = mapTransform.screenTranslationToMap(value.translation)
                        let base = startPoint ?? dot.mapPoint
                        let newPoint = CGPoint(x: base.x + dMap.x, y: base.y + dMap.y)
                        store.updateDot(id: dot.id, to: newPoint)
                    }
                    .onEnded { _ in
                        startPoint = nil
                    }
            )
        }
    }
}