//
//  CompassCalibrationOverlay.swift
//  TapResolver
//

import SwiftUI

/// Full-screen HUD for North calibration.
/// Drag to rotate; lift finger to keep the angle. No buttons.
/// Show/hide is controlled by the parent (HUDContainer) via a boolean state.
struct CompassCalibrationOverlay: View {
    @State private var angleDeg: CGFloat = 0          // 0° = pointing up
    @GestureState private var isDragging: Bool = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.opacity(0.25).ignoresSafeArea()

                CompassGraphic()
                    .frame(width: min(geo.size.width, geo.size.height) * 0.55,
                           height: min(geo.size.width, geo.size.height) * 0.55)
                    .rotationEffect(.degrees(angleDeg))
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 8)   // tap alone won’t update angle
                    .updating($isDragging) { _, s, _ in s = true }
                    .onChanged { value in
                        let c = CGPoint(x: geo.size.width/2, y: geo.size.height/2)
                        let dx = value.location.x - c.x
                        let dy = value.location.y - c.y
                        guard dx != 0 || dy != 0 else { return }
                        var deg = atan2(dy, dx) * 180 / .pi + 90 // 0° is up
                        if deg < 0 { deg += 360 }
                        if deg >= 360 { deg -= 360 }
                        angleDeg = deg
                    }
                    .onEnded { _ in
                        // keep angleDeg as final – parent will dismiss separately
                    }
            )
        }
        .ignoresSafeArea()
        .allowsHitTesting(true)
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
