//
//  MetricSquareDrawer.swift
//  TapResolver
//
//  Drawer + storage + overlay for metric squares.
//

import SwiftUI
import CoreGraphics
import UIKit

// MARK: - HUD panel state (unchanged except for isMorgueOpen you added)
final class HUDPanelsState: ObservableObject {
    @Published var isBeaconOpen: Bool = false
    @Published var isSquareOpen: Bool = false
    @Published var isMorgueOpen: Bool = false

    func openBeacon() { isBeaconOpen = true; isSquareOpen = false; isMorgueOpen = false }
    func openSquares() { isSquareOpen = true; isBeaconOpen = false; isMorgueOpen = false }
    func openMorgue() { isMorgueOpen = true; isBeaconOpen = false; isSquareOpen = false }
    func closeAll() { isBeaconOpen = false; isSquareOpen = false; isMorgueOpen = false }
}

// MARK: - Squares Store (map-local positions) + Lock + Persistence
final class MetricSquareStore: ObservableObject {
    @Published var isInteracting: Bool = false

    struct Square: Identifiable, Equatable {
        let id = UUID()
        var color: Color
        var center: CGPoint          // map-local center
        var side: CGFloat            // map-local side length
        var isLocked: Bool = false   // 🔒
    }

    @Published private(set) var squares: [Square] = []
    let maxSquares = 4

    // persistence
    private let squaresKey = "MetricSquares_v1"

    init() {
        load()
    }

    func add(at mapPoint: CGPoint, color: Color) {
        guard squares.count < maxSquares else { return }
        squares.append(Square(color: color, center: mapPoint, side: 80, isLocked: false))
        save()
    }

    func remove(id: UUID) {
        if let i = squares.firstIndex(where: { $0.id == id }) {
            squares.remove(at: i)
            save()
        }
    }

    func reset(id: UUID) {
        if let i = squares.firstIndex(where: { $0.id == id }) {
            squares[i].side = 80
            save()
        }
    }

    func updateCenter(id: UUID, to newCenter: CGPoint) {
        if let i = squares.firstIndex(where: { $0.id == id }) {
            squares[i].center = newCenter
            save()
        }
    }

    func updateSideAndCenter(id: UUID, side: CGFloat, center: CGPoint) {
        if let i = squares.firstIndex(where: { $0.id == id }) {
            squares[i].side = max(10, side)
            squares[i].center = center
            save()
        }
    }

    func toggleLock(id: UUID) {
        if let i = squares.firstIndex(where: { $0.id == id }) {
            squares[i].isLocked.toggle()
            save()
        }
    }

    // MARK: persistence helpers
    private struct ColorHSBA: Codable {
        var h: CGFloat; var s: CGFloat; var b: CGFloat; var a: CGFloat
    }
    private struct SquareDTO: Codable {
        let id: UUID
        let color: ColorHSBA
        let cx: CGFloat
        let cy: CGFloat
        let side: CGFloat
        let locked: Bool
    }

    private func save() {
        let dto = squares.map { sq -> SquareDTO in
            let ui = UIColor(sq.color)
            var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            ui.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
            return SquareDTO(id: sq.id,
                             color: ColorHSBA(h: h, s: s, b: b, a: a),
                             cx: sq.center.x, cy: sq.center.y,
                             side: sq.side,
                             locked: sq.isLocked)
        }
        if let data = try? JSONEncoder().encode(dto) {
            UserDefaults.standard.set(data, forKey: squaresKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: squaresKey),
              let dto = try? JSONDecoder().decode([SquareDTO].self, from: data) else { return }
        self.squares = dto.map { d in
            let color = Color(hue: d.color.h, saturation: d.color.s, brightness: d.color.b, opacity: d.color.a)
            return Square(color: color,
                          center: CGPoint(x: d.cx, y: d.cy),
                          side: d.side,
                          isLocked: d.locked)
        }
    }
}

// MARK: - Square metrics (unchanged)
final class SquareMetrics: ObservableObject {
    struct Entry: Identifiable {
        let id: UUID
        var pixelSide: CGFloat
        var meters: Double?
    }
    @Published private(set) var entries: [UUID: Entry] = [:]
    func updatePixelSide(for id: UUID, side: CGFloat) {
        if var e = entries[id] { e.pixelSide = side; entries[id] = e }
        else { entries[id] = Entry(id: id, pixelSide: side, meters: nil) }
    }
    func setMeters(for id: UUID, meters: Double) {
        if var e = entries[id] { e.meters = meters; entries[id] = e }
        else { entries[id] = Entry(id: id, pixelSide: 0, meters: meters) }
    }
    func entry(for id: UUID) -> Entry? { entries[id] }
}

// MARK: - Drawer
struct MetricSquareDrawer: View {
    @EnvironmentObject private var hud: HUDPanelsState
    @EnvironmentObject private var squares: MetricSquareStore
    @EnvironmentObject private var mapTransform: MapTransformStore

    private let collapsedWidth: CGFloat = 56
    private let expandedWidth: CGFloat = 180
    private let topBarHeight: CGFloat = 48
    private let rowHeight: CGFloat = 44
    private let drawerMaxHeight: CGFloat = 320
    private let bottomMargin: CGFloat = 8

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.4))

            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 8) {
                    addRow
                        .frame(height: rowHeight)
                        .padding(.leading, 8)

                    ForEach(squares.squares) { sq in
                        squareRow(sq)
                            .frame(height: rowHeight)
                            .padding(.leading, 8)
                    }
                }
                .padding(.top, topBarHeight + 6)
                .padding(.bottom, bottomMargin)
                .padding(.trailing, 6)
            }
            .scrollIndicators(.hidden)

            topBar
                .frame(height: topBarHeight)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(
            width: hud.isSquareOpen ? expandedWidth : collapsedWidth,
            height: hud.isSquareOpen ? min(drawerMaxHeight, idealOpenHeight) : topBarHeight
        )
        .clipped()
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.25), value: hud.isSquareOpen)
    }

    private var topBar: some View {
        HStack(spacing: 2) {
            if hud.isSquareOpen {
                Text("Metric Squares")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer(minLength: 0)
            }
            Button {
                if hud.isSquareOpen { hud.closeAll() } else { hud.openSquares() }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.black.opacity(0.4)))
                    .rotationEffect(.degrees(hud.isSquareOpen ? 180 : 0))
                    .contentShape(Circle())
            }
            .accessibilityLabel(hud.isSquareOpen ? "Close squares drawer" : "Open squares drawer")
        }
        .padding(.horizontal, 12)
    }

    private var addRow: some View {
        Button {
            guard squares.squares.count < squares.maxSquares else { return }
            guard mapTransform.mapSize != .zero else {
                print("⚠️ Square add ignored: mapTransform not ready (mapSize == .zero)")
                return
            }
            let targetScreen = mapTransform.screenCenter
            let centerOnMap  = mapTransform.screenToMap(targetScreen)
            let color = nextColor(for: squares.squares.count)
            squares.add(at: centerOnMap, color: color)
            print("▢ Square added @ map \(Int(centerOnMap.x)),\(Int(centerOnMap.y)) from screen center")
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                }
                Text("Add square")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.primary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 4)
            .contentShape(Rectangle())
        }
    }

    private func squareRow(_ sq: MetricSquareStore.Square) -> some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(sq.color.opacity(0.9))
                .frame(width: 20, height: 20)
                .cornerRadius(3)

            Text("Square")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.primary)

            Spacer()

            // 🔒 Lock toggle
            Button {
                squares.toggleLock(id: sq.id)
            } label: {
                Image(systemName: sq.isLocked ? "lock.fill" : "lock.open")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(sq.isLocked ? .yellow : .primary)
                    .frame(width: 24, height: 24)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(sq.isLocked ? "Unlock square" : "Lock square")

            // Reset
            Button {
                squares.reset(id: sq.id)
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 24, height: 24)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Reset square")

            // Delete (red X)
            Button {
                squares.remove(id: sq.id)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.red)
                    .frame(width: 24, height: 24)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete square")
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .contentShape(Rectangle())
    }

    private var idealOpenHeight: CGFloat {
        let rows = CGFloat(squares.squares.count + 1)
        let rowsHeight = rows * rowHeight + (rows - 1) * 8 + 6 + bottomMargin
        let total = max(topBarHeight, min(drawerMaxHeight, topBarHeight + rowsHeight))
        return total
    }

    private func nextColor(for index: Int) -> Color {
        let hues: [Double] = [0.02, 0.10, 0.58, 0.78, 0.85, 0.42]
        let h = hues[index % hues.count]
        return Color(hue: h, saturation: 0.75, brightness: 0.9)
    }
}

// MARK: - Overlay renderer
struct MetricSquaresOverlay: View {
    @EnvironmentObject private var hud: HUDPanelsState
    @EnvironmentObject private var squares: MetricSquareStore
    @EnvironmentObject private var mapTransform: MapTransformStore
    @EnvironmentObject private var squareMetrics: SquareMetrics

    var body: some View {
        ZStack {
            ForEach(squares.squares) { sq in
                DraggableResizableSquare(square: sq, isInteractive: hud.isSquareOpen)
            }
        }
    }

    private struct DraggableResizableSquare: View {
        let square: MetricSquareStore.Square
        let isInteractive: Bool

        @EnvironmentObject private var squares: MetricSquareStore
        @EnvironmentObject private var mapTransform: MapTransformStore
        @EnvironmentObject private var squareMetrics: SquareMetrics
        @EnvironmentObject private var hud: HUDPanelsState

        @State private var startCenter: CGPoint? = nil
        @State private var startSide: CGFloat? = nil
        @State private var startCorner0: CGPoint? = nil
        @State private var anchorCorner0: CGPoint? = nil

        private let handleHitRadius: CGFloat = 10

        var body: some View {
            let locked = square.isLocked

            ZStack {
                Rectangle()
                    .fill(square.color.opacity(0.3))
                    .frame(width: square.side, height: square.side)
                    .overlay(
                        Rectangle()
                            .stroke(square.color, lineWidth: 2)
                    )
                    .position(x: square.center.x, y: square.center.y)
                    .contentShape(Rectangle())
                    // Move enabled only when drawer CLOSED and not locked
                    .allowsHitTesting(isInteractive && !hud.isSquareOpen == true ? true : false) // remain explicit
                    .allowsHitTesting(isInteractive && !locked && !hud.isSquareOpen)
                    .gesture(centerDragGesture(locked: locked))

                if isInteractive && !locked && hud.isSquareOpen {
                    ForEach(Corner.allCases, id: \.self) { corner in
                        let cornerPoint = point(for: corner, center: square.center, side: square.side)
                        Circle()
                            .fill(Color.white)
                            .overlay(Circle().stroke(square.color, lineWidth: 2))
                            .frame(width: 12, height: 12)
                            .position(x: cornerPoint.x, y: cornerPoint.y)
                            .contentShape(Circle())
                            .highPriorityGesture(cornerResizeGesture(corner: corner, locked: locked))
                    }
                }
            }
        }

        // MARK: gestures
        private func centerDragGesture(locked: Bool) -> some Gesture {
            DragGesture(minimumDistance: 4, coordinateSpace: .global)
                .onChanged { value in
                    guard !locked else { return }
                    // If user started at a handle, ignore move
                    let start = value.startLocation
                    let corners = Corner.allCases.map { point(for: $0, center: square.center, side: square.side) }
                    let nearAHandle = corners.contains { hypot($0.x - start.x, $0.y - start.y) <= handleHitRadius }
                    if nearAHandle { return }

                    if startCenter == nil {
                        startCenter = square.center
                        squares.isInteracting = true
                    }
                    let dMap = mapTransform.screenTranslationToMap(value.translation)
                    let base = startCenter ?? square.center
                    let newCenter = CGPoint(x: base.x + dMap.x, y: base.y + dMap.y)
                    squares.updateCenter(id: square.id, to: newCenter)
                }
                .onEnded { _ in
                    startCenter = nil
                    squares.isInteracting = false
                }
        }

        private func cornerResizeGesture(corner: Corner, locked: Bool) -> some Gesture {
            DragGesture(minimumDistance: 6, coordinateSpace: .global)
                .onChanged { value in
                    guard !locked else { return }
                    if startCenter == nil || startSide == nil || startCorner0 == nil || anchorCorner0 == nil {
                        startCenter = square.center
                        startSide   = square.side
                        startCorner0 = point(for: corner, center: square.center, side: square.side)
                        anchorCorner0 = point(for: corner.opposite, center: square.center, side: square.side)
                        squares.isInteracting = true
                    }

                    guard
                        let sc0 = startCorner0,
                        let ac0 = anchorCorner0
                    else { return }

                    let dMap = mapTransform.screenTranslationToMap(value.translation)
                    let newCorner = CGPoint(x: sc0.x + dMap.x, y: sc0.y + dMap.y)
                    let moveMagnitude = max(abs(value.translation.width), abs(value.translation.height))
                    guard moveMagnitude > 2 else { return }

                    let dx = abs(newCorner.x - ac0.x)
                    let dy = abs(newCorner.y - ac0.y)
                    let sideNew = max(10, max(dx, dy))

                    let newCenter = CGPoint(
                        x: (ac0.x + newCorner.x) / 2,
                        y: (ac0.y + newCorner.y) / 2
                    )

                    squares.updateSideAndCenter(id: square.id, side: sideNew, center: newCenter)
                }
                .onEnded { _ in
                    if let final = squares.squares.first(where: { $0.id == square.id }) {
                        squareMetrics.updatePixelSide(for: final.id, side: final.side)
                        print("▢ Square \(final.id) — side (map px): \(Int(final.side))")
                    }
                    startCenter = nil
                    startSide = nil
                    startCorner0 = nil
                    anchorCorner0 = nil
                    squares.isInteracting = false
                }
        }

        private func point(for corner: Corner, center: CGPoint, side: CGFloat) -> CGPoint {
            let h = side / 2
            switch corner {
            case .topLeft:     return CGPoint(x: center.x - h, y: center.y - h)
            case .topRight:    return CGPoint(x: center.x + h, y: center.y - h)
            case .bottomLeft:  return CGPoint(x: center.x - h, y: center.y + h)
            case .bottomRight: return CGPoint(x: center.x + h, y: center.y + h)
            }
        }

        enum Corner: CaseIterable {
            case topLeft, topRight, bottomLeft, bottomRight
            var opposite: Corner {
                switch self {
                case .topLeft: return .bottomRight
                case .topRight: return .bottomLeft
                case .bottomLeft: return .topRight
                case .bottomRight: return .topLeft
                }
            }
        }
    }
}
