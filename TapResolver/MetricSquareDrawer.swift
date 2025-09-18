//
//  MetricSquareDrawer.swift
//  TapResolver
//
//  Drawer + storage + overlay for metric squares.
//

import SwiftUI
import CoreGraphics

// MARK: - HUD panel state for mutual exclusivity (shared)
final class HUDPanelsState: ObservableObject {
    @Published var isBeaconOpen: Bool = false
    @Published var isSquareOpen: Bool = false

    func openBeacon() {
        isBeaconOpen = true
        isSquareOpen = false
    }

    func openSquares() {
        isSquareOpen = true
        isBeaconOpen = false
    }

    func closeAll() {
        isBeaconOpen = false
        isSquareOpen = false
    }
}

// MARK: - Squares Store (map-local positions)
final class MetricSquareStore: ObservableObject {
    @Published var isInteracting: Bool = false
    struct Square: Identifiable, Equatable {
        let id = UUID()
        var color: Color
        var center: CGPoint          // map-local center
        var side: CGFloat            // map-local side length
    }

    @Published private(set) var squares: [Square] = []
    let maxSquares = 4

    func add(at mapPoint: CGPoint, color: Color) {
        guard squares.count < maxSquares else { return }
        squares.append(Square(color: color, center: mapPoint, side: 80))
    }

    func remove(id: UUID) {
        if let i = squares.firstIndex(where: { $0.id == id }) {
            squares.remove(at: i)
        }
    }

    func reset(id: UUID) {
        if let i = squares.firstIndex(where: { $0.id == id }) {
            squares[i].side = 80
        }
    }

    func updateCenter(id: UUID, to newCenter: CGPoint) {
        if let i = squares.firstIndex(where: { $0.id == id }) {
            squares[i].center = newCenter
        }
    }

    func updateSideAndCenter(id: UUID, side: CGFloat, center: CGPoint) {
        if let i = squares.firstIndex(where: { $0.id == id }) {
            squares[i].side = max(10, side)
            squares[i].center = center
        }
    }
}

// MARK: - Drawer

struct MetricSquareDrawer: View {
    @EnvironmentObject private var hud: HUDPanelsState
    @EnvironmentObject private var squares: MetricSquareStore
    @EnvironmentObject private var mapTransform: MapTransformStore

    // Layout
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

            // Scrollable content
            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 8) {

                    // "+" Row
                    addRow
                        .frame(height: rowHeight)
                        .padding(.leading, 8)

                    // Existing squares
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

            // Header
            topBar
                .frame(height: topBarHeight)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(
            width: hud.isSquareOpen ? expandedWidth : collapsedWidth,
            height: hud.isSquareOpen
                ? min(drawerMaxHeight, idealOpenHeight)
                : topBarHeight
        )
        .clipped()
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.25), value: hud.isSquareOpen)
    }

    // MARK: Header

    private var topBar: some View {
        HStack(spacing: 2) {
            if hud.isSquareOpen {
                Text("Metric Squares")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer(minLength: 0)
            }
            Button {
                if hud.isSquareOpen {
                    hud.closeAll()
                } else {
                    hud.openSquares()
                }
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

    // MARK: Rows

    private var addRow: some View {
        Button {
            guard squares.squares.count < squares.maxSquares else { return }
            guard mapTransform.mapSize != .zero else {
                print("⚠️ Square add ignored: mapTransform not ready (mapSize == .zero)")
                return
            }
            let center = CGPoint(x: mapTransform.mapSize.width / 2,
                                 y: mapTransform.mapSize.height / 2)
            let color = nextColor(for: squares.squares.count)
            squares.add(at: center, color: color)
            print("▢ Square added @ map \(Int(center.x)),\(Int(center.y)))")
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
            // 20pt color swatch
            Rectangle()
                .fill(sq.color.opacity(0.9))
                .frame(width: 20, height: 20)
                .cornerRadius(3)

            Text("Square")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.primary)

            Spacer()

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

    // Ideal open height (header + rows)
    private var idealOpenHeight: CGFloat {
        let rows = CGFloat(squares.squares.count + 1) // +1 for the add row
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

// MARK: - Overlay renderer (between BeaconOverlayDots and BeaconOverlay)

struct MetricSquaresOverlay: View {
    @EnvironmentObject private var hud: HUDPanelsState
    @EnvironmentObject private var squares: MetricSquareStore
    @EnvironmentObject private var mapTransform: MapTransformStore

    var body: some View {
        ZStack {
            ForEach(squares.squares) { sq in
                DraggableResizableSquare(square: sq, isInteractive: hud.isSquareOpen)
            }
        }
        // REMOVED: container-level allowsHitTesting to avoid swallowing map gestures.
        // Each square body/handle already gates its own hit-testing via isInteractive.
    }

    // A single square with center-drag & corner-resize
    private struct DraggableResizableSquare: View {
        let square: MetricSquareStore.Square
        let isInteractive: Bool

        @EnvironmentObject private var squares: MetricSquareStore
        @EnvironmentObject private var mapTransform: MapTransformStore

        // Drag state
        @State private var startCenter: CGPoint? = nil
        @State private var startSide: CGFloat? = nil
        
        private let handleHitRadius: CGFloat = 16 // > 12pt visual to ease grabbing

        var body: some View {
            ZStack {
                // Body (transparent fill + stroke)
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: square.side, height: square.side)
                    .overlay(
                        Rectangle()
                            .stroke(square.color, lineWidth: 2)
                    )
                    .position(x: square.center.x, y: square.center.y)
                    .contentShape(Rectangle())
                    .allowsHitTesting(isInteractive)
                    .gesture(centerDragGesture())

                // Corner handles (visible only if interactive)
                if isInteractive {
                    ForEach(Corner.allCases, id: \.self) { corner in
                        let cornerPoint = point(for: corner, center: square.center, side: square.side)
                        Circle()
                            .fill(Color.white)
                            .overlay(Circle().stroke(square.color, lineWidth: 2))
                            .frame(width: 12, height: 12)
                            .position(x: cornerPoint.x, y: cornerPoint.y)
                            .contentShape(Circle())
                            .gesture(cornerResizeGesture(corner: corner))
                    }
                }
            }
        }

        // MARK: gestures
        private func centerDragGesture() -> some Gesture {
            DragGesture(minimumDistance: 4)
                .onChanged { value in
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

        private func cornerResizeGesture(corner: Corner) -> some Gesture {
            DragGesture(minimumDistance: 6)
                .onChanged { value in
                    if startCenter == nil || startSide == nil {
                        startCenter = square.center
                        startSide = square.side
                        squares.isInteracting = true
                    }
                    let center0 = startCenter ?? square.center
                    let side0 = startSide ?? square.side

                    let startCorner = point(for: corner, center: center0, side: side0)
                    let anchorCorner = point(for: corner.opposite, center: center0, side: side0)

                    let dMap = mapTransform.screenTranslationToMap(value.translation)
                    let newCorner = CGPoint(x: startCorner.x + dMap.x, y: startCorner.y + dMap.y)

                    let moveMagnitude = max(abs(value.translation.width), abs(value.translation.height))
                    guard moveMagnitude > 2 else { return }

                    let dx = abs(newCorner.x - anchorCorner.x)
                    let dy = abs(newCorner.y - anchorCorner.y)
                    let sideNew = max(10, max(dx, dy))

                    let newCenter = CGPoint(
                        x: (anchorCorner.x + newCorner.x) / 2,
                        y: (anchorCorner.y + newCorner.y) / 2
                    )

                    squares.updateSideAndCenter(id: square.id, side: sideNew, center: newCenter)
                }
                .onEnded { _ in
                    startCenter = nil
                    startSide = nil
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

        private func emptyGesture() -> some Gesture {
            DragGesture(minimumDistance: .infinity)
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
