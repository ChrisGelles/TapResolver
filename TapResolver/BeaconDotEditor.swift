//
//  BeaconDotEditor.swift
//  TapResolver
//
//  Dots stored in MAP-LOCAL coordinates (untransformed map space).
//  They render inside the map stack, so they pan/zoom/rotate with the map.
//

import SwiftUI
import CoreGraphics

// MARK: - A single dot
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
            .accessibilityHidden(true)
    }
}

// MARK: - Store of dots (map-local positions)
public final class BeaconDotStore: ObservableObject {
    public struct Dot: Identifiable {
        public let id = UUID()
        public let color: Color
        public let mapPoint: CGPoint  // map-local (untransformed) coords
    }

    @Published public private(set) var dots: [Dot] = []

    public init() {}

    public func addDot(mapPoint: CGPoint, color: Color) {
        dots.append(Dot(color: color, mapPoint: mapPoint))
        print("Added dot @ map-local (\(Int(mapPoint.x)), \(Int(mapPoint.y)))")
    }

    public func clear() { dots.removeAll() }
}

// MARK: - Helper: publish the current map transform + converter
/// Keep this in sync from MapContainer so other views (e.g., the drawer)
/// can convert GLOBAL (screen) points into MAP-LOCAL coordinates.
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

        // v = G - Cscreen - O
        let v = CGPoint(x: G.x - Cscreen.x - O.x,
                        y: G.y - Cscreen.y - O.y)

        // R^{-1} is rotation by -theta
        let theta = -totalRotationRadians
        let c = cos(theta), sgn = sin(theta)
        let vUnrot = CGPoint(x: c * v.x - sgn * v.y,
                             y: sgn * v.x + c * v.y)

        // (1/s) * vUnrot
        let vUnscale = CGPoint(x: vUnrot.x / s, y: vUnrot.y / s)

        // L = Cmap + vUnscale
        return CGPoint(x: Cmap.x + vUnscale.x, y: Cmap.y + vUnscale.y)
    }
}

// MARK: - Renderer: draw all dots in map-local space
public struct BeaconOverlayDots: View {
    @EnvironmentObject private var store: BeaconDotStore

    public init() {}

    public var body: some View {
        ZStack {
            ForEach(store.dots) { dot in
                BeaconDot(color: dot.color)
                    .position(x: dot.mapPoint.x, y: dot.mapPoint.y)
            }
        }
        .allowsHitTesting(false) // drawing only
    }
}
