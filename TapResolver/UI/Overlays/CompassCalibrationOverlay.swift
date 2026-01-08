//
//  CompassCalibrationOverlay.swift
//  TapResolver
//

import SwiftUI

@inline(__always)

private func radiansCCW_to_degreesCW(_ r: Double) -> Double {
    // Map transform is typically +CCW (math). SwiftUI's rotationEffect uses +CW on screen.
    return -(r * 180.0 / .pi)
}

/// Full-screen HUD for North calibration.
/// Drag to rotate; lift finger to keep the angle.
/// The current angle is bound to the parent (persisted by SquareMetrics).
struct CompassCalibrationOverlay: View {
    @Binding var angleDeg: Double        // +CW / -CCW, 0° = up
    @GestureState private var isDragging: Bool = false
    
    @EnvironmentObject private var mapTransform: MapTransformStore

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.opacity(0.25).ignoresSafeArea()
                
                // Display-only: compensate for the current map rotation so the widget keeps pointing to calibrated north
                let mapRotationDegCW = radiansCCW_to_degreesCW(mapTransform.totalRotationRadians)
                let displayDeg = angleDeg - mapRotationDegCW

                CompassGraphic()
                    .frame(width: min(geo.size.width, geo.size.height) * 0.55,
                           height: min(geo.size.width, geo.size.height) * 0.55)
                    .rotationEffect(.degrees(displayDeg))
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 8)
                    .updating($isDragging) { _, s, _ in s = true }
                    .onChanged { value in
                        let c = CGPoint(x: geo.size.width/2, y: geo.size.height/2)
                        let dx = value.location.x - c.x
                        let dy = value.location.y - c.y
                        guard dx != 0 || dy != 0 else { return }

                        // 0° is "up" → add +90° to atan2, then normalize to [-180, +180]
                        var deg = atan2(dy, dx) * 180 / .pi + 90
                        while deg > 180 { deg -= 360 }
                        while deg <= -180 { deg += 360 }
                        angleDeg = deg
                    }
            )
        }
        .ignoresSafeArea()
        .allowsHitTesting(true)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    mapTransform.isHUDInteracting = true
                }
                .onEnded { _ in
                    mapTransform.isHUDInteracting = false
                }
        )
    }
}

private struct CompassGraphic: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.35))
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
            CrosshairLines()
        }
    }
}

private struct CrosshairLines: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: 200, height: 200)

            VStack(spacing: 0) {
                ArrowHead()
                    .frame(width: 20, height: 30)
                    .foregroundColor(.white)
                    .offset(y: -30)
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2, height: 300)
                    .offset(y: -30)
            }
            .offset(y: -30)

            Rectangle()
                .fill(Color.white)
                .frame(width: 200, height: 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ArrowHead: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            Path { p in
                p.move(to: CGPoint(x: w/2, y: 0))
                p.addLine(to: CGPoint(x: w,   y: h))
                p.addLine(to: CGPoint(x: 0,   y: h))
                p.closeSubpath()
            }
            .fill(Color.white)
            .overlay(
                Path { p in
                    p.move(to: CGPoint(x: w/2, y: 0))
                    p.addLine(to: CGPoint(x: w,   y: h))
                    p.addLine(to: CGPoint(x: 0,   y: h))
                    p.closeSubpath()
                }
                .stroke(Color.black.opacity(0.35), lineWidth: 1)
            )
        }
    }
}
