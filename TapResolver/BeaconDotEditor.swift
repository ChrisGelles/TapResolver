//
//  BeaconDotEditor.swift
//  TapResolver
//
//  Dots are stored in MAP-LOCAL coordinates (untransformed map space).
//  They render inside the map stack, so they pan/zoom/rotate with the map.
//  - One-dot-per-beacon toggle
//  - Draggable dots with small hit target
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

// MARK: - Map transform publisher (for screen <-> map conversions)
public final class MapTransformStore: ObservableObject {
    @Published public var screenCenter: CGPoint = .zero
    @Published public var totalScale: CGFloat = 1.0
    @Published public var totalRotationRadians: CGFloat = 0.0
    @Published public var totalOffset: CGSize = .zero
    @Published public var mapSize: CGSize = .zero

    public init() {}

    /// Convert GLOBAL (screen) point to MAP-LOCAL point
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

    /// Convert GLOBAL (screen) translation ΔG into MAP-LOCAL ΔL
    public func screenTranslationToMap(_ dG: CGSize) -> CGPoint {
        let s = max(totalScale, 0.0001)
        let theta = -totalRotationRadians
        let c = cos(theta), ss = sin(theta)
        let v = CGPoint(x: dG.width, y: dG.height)
        let vUnrot = CGPoint(x: c * v.x - ss * v.y,
                             y: ss * v.x + c * v.y)
        return CGPoint(x: vUnrot.x / s, y: vUnrot.y / s)
    }
}

// MARK: - Store of dots (map-local positions) + Locks + Persistence
public final class BeaconDotStore: ObservableObject {
    public struct Dot: Identifiable {
        public let id = UUID()
        public let beaconID: String     // one dot per beacon
        public let color: Color
        public var mapPoint: CGPoint    // map-local (untransformed) coords
    }

    @Published public private(set) var dots: [Dot] = []
    // beaconID -> locked?
    @Published private(set) var locked: [String: Bool] = [:]

    // MARK: persistence keys
    private let dotsKey   = "BeaconDots_v1"
    private let locksKey  = "BeaconLocks_v1"

    public init() {
        load()
    }

    public func dot(for beaconID: String) -> Dot? {
        dots.first { $0.beaconID == beaconID }
    }

    /// Toggle a dot for a beacon:
    /// - If it exists, remove it.
    /// - If not, add at `mapPoint` with `color`.
    public func toggleDot(for beaconID: String, mapPoint: CGPoint, color: Color) {
        if let idx = dots.firstIndex(where: { $0.beaconID == beaconID }) {
            dots.remove(at: idx)
            save()
            print("Removed dot for \(beaconID)")
        } else {
            dots.append(Dot(beaconID: beaconID, color: color, mapPoint: mapPoint))
            save()
            print("Added dot for \(beaconID) @ map (\(Int(mapPoint.x)), \(Int(mapPoint.y)))")
        }
    }

    /// Update a dot's map-local position (used while dragging).
    public func updateDot(id: UUID, to newPoint: CGPoint) {
        if let idx = dots.firstIndex(where: { $0.id == id }) {
            dots[idx].mapPoint = newPoint
            save()
        }
    }

    public func clear() {
        dots.removeAll()
        save()
    }

    // MARK: - Lock API

    public func isLocked(_ beaconID: String) -> Bool {
        locked[beaconID] ?? false
    }

    public func toggleLock(_ beaconID: String) {
        let newVal = !(locked[beaconID] ?? false)
        locked[beaconID] = newVal
        saveLocks()
    }

    // MARK: - Persistence

    private struct DotDTO: Codable {
        let beaconID: String
        let x: CGFloat
        let y: CGFloat
    }

    private struct LocksDTO: Codable {
        let locks: [String: Bool]
    }

    private func save() {
        let dto = dots.map { DotDTO(beaconID: $0.beaconID, x: $0.mapPoint.x, y: $0.mapPoint.y) }
        if let data = try? JSONEncoder().encode(dto) {
            UserDefaults.standard.set(data, forKey: dotsKey)
        }
        saveLocks()
    }

    private func saveLocks() {
        if let data = try? JSONEncoder().encode(LocksDTO(locks: locked)) {
            UserDefaults.standard.set(data, forKey: locksKey)
        }
    }

    private func load() {
        // Dots
        if let data = UserDefaults.standard.data(forKey: dotsKey),
           let dto = try? JSONDecoder().decode([DotDTO].self, from: data) {
            self.dots = dto.map { Dot(beaconID: $0.beaconID,
                                      color: beaconColor(for: $0.beaconID),
                                      mapPoint: CGPoint(x: $0.x, y: $0.y)) }
        }

        // Locks
        if let data = UserDefaults.standard.data(forKey: locksKey),
           let dto = try? JSONDecoder().decode(LocksDTO.self, from: data) {
            self.locked = dto.locks
        }
    }

    private func beaconColor(for beaconID: String) -> Color {
        let hash = beaconID.hash
        let hue = Double(abs(hash % 360)) / 360.0
        return Color(hue: hue, saturation: 0.7, brightness: 0.8)
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
