//
//  MetricSquaresOverlay.swift
//  TapResolver
//
//  Created by restructuring on 9/19/25.
//

import SwiftUI
import CoreGraphics

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