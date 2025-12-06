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
        @State private var interactionMode: InteractionMode? = nil
        @State private var forceDragMode: Bool = false
        
        private enum InteractionMode {
            case resize
            case drag
        }

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
                    .allowsHitTesting(false)

                if isInteractive && !locked && hud.isSquareOpen {
                    ForEach(Corner.allCases, id: \.self) { corner in
                        let cornerPoint = point(for: corner, center: square.center, side: square.side)
                        Circle()
                            .fill(Color.white)
                            .overlay(Circle().stroke(square.color, lineWidth: 2))
                            .frame(width: 12, height: 12)
                            .position(x: cornerPoint.x, y: cornerPoint.y)
                    }
                    
                    // Transparent overlay for unified gesture detection (resize + drag)
                    Color.clear
                        .contentShape(Rectangle())
                        .frame(width: square.side * 1.4, height: square.side * 1.4)
                        .position(x: square.center.x, y: square.center.y)
                        .simultaneousGesture(
                            LongPressGesture(minimumDuration: 0.5)
                                .onEnded { _ in
                                    guard !locked else { return }
                                    forceDragMode = true
                                    print("🟦 LONG PRESS — force drag mode activated")
                                }
                        )
                        .highPriorityGesture(unifiedCornerGesture(locked: locked))
                }
            }
        }

        // MARK: gestures
        private func unifiedCornerGesture(locked: Bool) -> some Gesture {
            DragGesture(minimumDistance: 6, coordinateSpace: .global)
                .onChanged { value in
                    guard !mapTransform.isPinching else { return }
                    guard !locked else { return }
                    
                    // Determine mode on first frame
                    if interactionMode == nil {
                        // Long-press override: force drag mode regardless of position
                        if forceDragMode {
                            interactionMode = .drag
                            print("🟦 UNIFIED GESTURE — mode: DRAG (long-press override)")
                        } else {
                            let (corner, distance) = nearestCorner(to: value.startLocation)
                            
                            // Corner threshold: 35% of side, minimum 60pt screen
                            let minCornerThresholdMap: CGFloat = 60 / mapTransform.totalScale
                            let proportionalThreshold = square.side * 0.35
                            let cornerThresholdMap = max(minCornerThresholdMap, proportionalThreshold)
                            
                            if distance < cornerThresholdMap {
                                interactionMode = .resize
                                activeCorner = corner
                                print("🟦 UNIFIED GESTURE — mode: RESIZE, corner: \(corner)")
                            } else {
                                interactionMode = .drag
                                print("🟦 UNIFIED GESTURE — mode: DRAG")
                            }
                        }
                    }
                    
                    switch interactionMode {
                    case .resize:
                        handleResize(value: value)
                    case .drag:
                        handleDrag(value: value)
                    case .none:
                        break
                    }
                }
                .onEnded { _ in
                    if interactionMode == .resize {
                        if let final = squares.squares.first(where: { $0.id == square.id }) {
                            squareMetrics.updatePixelSide(for: final.id, side: final.side)
                            print("▢ Square \(final.id) — side (map px): \(Int(final.side))")
                        }
                    }
                    
                    // Reset all state
                    interactionMode = nil
                    activeCorner = nil
                    startCenter = nil
                    startSide = nil
                    startCorner0 = nil
                    anchorCorner0 = nil
                    forceDragMode = false
                    squares.isInteracting = false
                }
        }
        
        private func handleResize(value: DragGesture.Value) {
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
        
        private func handleDrag(value: DragGesture.Value) {
            if startCenter == nil {
                startCenter = square.center
                squares.isInteracting = true
                print("🟦 CENTER DRAG START — center: \(square.center)")
            }
            
            let dMap = mapTransform.screenTranslationToMap(value.translation)
            let base = startCenter ?? square.center
            let newCenter = CGPoint(x: base.x + dMap.width, y: base.y + dMap.height)
            squares.updateCenter(id: square.id, to: newCenter)
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
        
        private func nearestCorner(to screenPoint: CGPoint) -> (corner: Corner, distance: CGFloat) {
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
            return (closest, closestDist)
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
