//
//  BeaconDotEditor.swift
//  TapResolver
//
//  Dots stored in MAP-LOCAL coordinates (untransformed map space).
//  They render inside the map stack, so they pan/zoom/rotate with the map.
//  Now supports dragging dots to reposition them.
//

import SwiftUI
import CoreGraphics

// MARK: - A single dot
public struct BeaconDot: View {
    public let color: Color
    public var size: CGFloat = 12

    public init(color: Color, size: CGFloat = 12) {
        self.color = color
        self.size = size
    }

    public var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

// MARK: - Store of dots (map-local positions)
public final class BeaconDotStore: ObservableObject {
    public struct Dot: Identifiable {
        public let id = UUID()
        public let color: Color
        public var mapPoint: CGPoint  // map-local (untransformed) coords
    }

    @Published public private(set) var dots: [Dot] = []

    public init() {}

    public func addDot(mapPoint: CGPoint, color: Color) {
        dots.append(Dot(color: color, mapPoint: mapPoint))
        print("Added dot @ map-local (\(Int(mapPoint.x)), \(Int(mapPoint.y)))")
    }

    /// Update a dot's map-local position (used while dragging).
    public func updateDot(id: UUID, to newPoint: CGPoint) {
        if let idx = dots.firstIndex(where: { $0.id == id }) {
            dots[idx].mapPoint = newPoint
        }
    }

    public func clear() { dots.removeAll() }
}

// MARK: - Helper: publish the current map transform + converter
/// Keep this in sync from MapContainer so we can convert screen deltas → map-local deltas.
public final class MapTransformStore: ObservableObject {
    // Inputs (publish from MapContainer)
    @Published public var screenCenter: CGPoint = .zero   // center of the map on screen
    @Published public var totalScale: CGFloat = 1.0
    @Published public var totalRotationRadians: CGFloat = 0.0
    @Published public var totalOffset: CGSize = .zero     // applied after scale+rotation
    @Published public var mapSize: CGSize = .zero         // intrinsic map size (points)

    public init() {}

    /// Convert a GLOBAL (screen) point `G` into MAP-LOCAL point `L`.
    /// Model:
    ///   G = Cscreen + O + R * (s * (L - Cmap))
    /// => L = Cmap + (1/s) * R^{-1} * (G - Cscreen - O)
    public func screenToMap(_ G: CGPoint) -> CGPoint {
        let s = max(totalScale, 0.0001)
        let O = CGPoint(x: totalOffset.width, y: totalOffset.height)
        let Cscreen = screenCenter
        let Cmap = CGPoint(x: mapSize.width / 2, y: mapSize.height / 2)

        let v = CGPoint(x: G.x - Cscreen.x - O.x,
                        y: G.y - Cscreen.y - O.y)

        let theta = -totalRotationRadians
        let c = cos(theta), ss = sin(theta)
        let vUnrot = CGPoint(x: c * v.x - ss * v.y,
                             y: ss * v.x + c * v.y)

        let vUnscale = CGPoint(x: vUnrot.x / s, y: vUnrot.y / s)

        return CGPoint(x: Cmap.x + vUnscale.x, y: Cmap.y + vUnscale.y)
    }

    /// Convert a GLOBAL (screen) translation ΔG into MAP-LOCAL ΔL.
    /// ΔL = (1/s) * R^{-1} * ΔG
    public func screenTranslationToMap(_ dG: CGSize) -> CGPoint {
        let s = max(totalScale, 0.0001)
        let theta = -totalRotationRadians
        let c = cos(theta), ss = sin(theta)
        // treat dG as a vector in screen coords
        let v = CGPoint(x: dG.width, y: dG.height)
        let vUnrot = CGPoint(x: c * v.x - ss * v.y,
                             y: ss * v.x + c * v.y)
        return CGPoint(x: vUnrot.x / s, y: vUnrot.y / s)
    }
}

// MARK: - Renderer: draw all dots in map-local space (now draggable)
public struct BeaconOverlayDots: View {
    @EnvironmentObject private var store: BeaconDotStore
    // You can keep MapTransformStore for screen→map conversion when adding dots,
    // but we do NOT need it for dragging.
    // @EnvironmentObject private var mapTransform: MapTransformStore

    public init() {}

    public var body: some View {
        ZStack {
            ForEach(store.dots) { dot in
                DraggableDot(dot: dot)
            }
        }
        // IMPORTANT: do NOT set a large contentShape here.
        // We want only dots to be hit-testable so map pan/zoom/rotate still work elsewhere.
        .allowsHitTesting(true)
    }

    // MARK: - Single draggable dot subview (tiny hit area)
    private struct DraggableDot: View {
        let dot: BeaconDotStore.Dot
        @EnvironmentObject private var store: BeaconDotStore

        // Match your BeaconDot default size; change if you use a different size.
        private let dotSize: CGFloat = 12
        private let hitPadding: CGFloat = 5   // exact: 5 px larger than contents

        @State private var startPoint: CGPoint? = nil

        var body: some View {
            // Build a tiny, centered hit target = dot size + 10 (5px each side)
            ZStack {
                BeaconDot(color: dot.color, size: dotSize)
            }
            .frame(width: dotSize + 2 * hitPadding,
                   height: dotSize + 2 * hitPadding,
                   alignment: .center)
            .contentShape(Circle()) // hit shape just around the dot (+5px)
            .position(x: dot.mapPoint.x, y: dot.mapPoint.y)
            // Attach a normal gesture (not highPriority) so only touches on the dot start it.
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if startPoint == nil { startPoint = dot.mapPoint }
                        // In this overlay, translation is effectively in map-local units,
                        // so we can add it directly.
                        let base = startPoint ?? dot.mapPoint
                        let newPoint = CGPoint(x: base.x + value.translation.width,
                                               y: base.y + value.translation.height)
                        store.updateDot(id: dot.id, to: newPoint)
                    }
                    .onEnded { _ in
                        startPoint = nil
                    }
            )
        }
    }
}
