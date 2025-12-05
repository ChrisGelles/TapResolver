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
        @State private var activeCorner: Corner? = nil

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
                    }
                    
                    // Transparent overlay for unified corner hit detection
                    Color.clear
                        .contentShape(Rectangle())
                        .frame(width: square.side + 40, height: square.side + 40)
                        .position(x: square.center.x, y: square.center.y)
                        .highPriorityGesture(unifiedCornerGesture(locked: locked))
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
                    let newCenter = CGPoint(x: base.x + dMap.width, y: base.y + dMap.height)
                    squares.updateCenter(id: square.id, to: newCenter)
                }
                .onEnded { _ in
                    startCenter = nil
                    squares.isInteracting = false
                }
        }

        private func unifiedCornerGesture(locked: Bool) -> some Gesture {
            DragGesture(minimumDistance: 6, coordinateSpace: .global)
                .onChanged { value in
                    guard !mapTransform.isPinching else { return }
                    guard !locked else { return }
                    
                    // Determine corner on first frame
                    if activeCorner == nil {
                        activeCorner = nearestCorner(to: value.startLocation)
                        print("🟦 UNIFIED CORNER — detected: \(activeCorner!) at screen: \(value.startLocation)")
                    }
                    
                    guard let corner = activeCorner else { return }
                    
                    // Initialize drag state
                    if startCenter == nil || startSide == nil || startCorner0 == nil || anchorCorner0 == nil {
                        startCenter = square.center
                        startSide = square.side
                        startCorner0 = point(for: corner, center: square.center, side: square.side)
                        anchorCorner0 = point(for: corner.opposite, center: square.center, side: square.side)
                        squares.isInteracting = true
                        print("🟦 CORNER RESIZE START — corner: \(corner)")
                        print("   square.center (map): \(square.center)")
                        print("   square.side: \(square.side)")
                    }
                    
                    guard
                        let sc0 = startCorner0,
                        let ac0 = anchorCorner0
                    else { return }
                    
                    let dMap = mapTransform.screenTranslationToMap(value.translation)
                    let newCorner = CGPoint(x: sc0.x + dMap.width, y: sc0.y + dMap.height)
                    let moveMagnitude = max(abs(value.translation.width), abs(value.translation.height))
                    guard moveMagnitude > 2 else { return }
                    
                    let dx = abs(newCorner.x - ac0.x)
                    let dy = abs(newCorner.y - ac0.y)
                    
                    // Minimum 60pt screen size, converted to map space
                    let minScreenSize: CGFloat = 60
                    let minMapSize = minScreenSize / mapTransform.totalScale
                    let sideNew = max(minMapSize, max(dx, dy))
                    
                    // Use fixed signs based on corner (prevents flipping)
                    let (signX, signY) = signs(for: corner)
                    let constrainedCorner = CGPoint(
                        x: ac0.x + signX * sideNew,
                        y: ac0.y + signY * sideNew
                    )
                    
                    let newCenter = CGPoint(
                        x: (ac0.x + constrainedCorner.x) / 2,
                        y: (ac0.y + constrainedCorner.y) / 2
                    )
                    
                    squares.updateSideAndCenter(id: square.id, side: sideNew, center: newCenter)
                }
                .onEnded { _ in
                    if let final = squares.squares.first(where: { $0.id == square.id }) {
                        squareMetrics.updatePixelSide(for: final.id, side: final.side)
                        print("▢ Square \(final.id) — side (map px): \(Int(final.side))")
                    }
                    activeCorner = nil
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
        
        private func nearestCorner(to screenPoint: CGPoint) -> Corner {
            let mapPoint = mapTransform.screenToMap(screenPoint)
            var closest: Corner = .bottomRight
            var closestDist: CGFloat = .greatestFiniteMagnitude
            
            for corner in Corner.allCases {
                let cornerPos = point(for: corner, center: square.center, side: square.side)
                let dist = hypot(mapPoint.x - cornerPos.x, mapPoint.y - cornerPos.y)
                if dist < closestDist {
                    closestDist = dist
                    closest = corner
                }
            }
            return closest
        }
        
        private func signs(for corner: Corner) -> (x: CGFloat, y: CGFloat) {
            switch corner {
            case .topLeft:     return (-1, -1)
            case .topRight:    return ( 1, -1)
            case .bottomLeft:  return (-1,  1)
            case .bottomRight: return ( 1,  1)
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
