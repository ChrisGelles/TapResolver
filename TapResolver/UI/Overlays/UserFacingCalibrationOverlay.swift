//
//  UserFacingCalibrationOverlay.swift
//  TapResolver
//

import SwiftUI

@inline(__always)
private func radiansCCW_to_degreesCW(_ r: Double) -> Double {
    // Map transform is +CCW (math). SwiftUI rotationEffect uses +CW on screen.
    return -(r * 180.0 / .pi)
}

/// Full-screen HUD for Facing fine-tune calibration (tools layer).
/// Drag to rotate; lift finger to keep the angle.
/// The current angle is bound to SquareMetrics.facingFineTuneDeg (per-location).
struct UserFacingCalibrationOverlay: View {
    @Binding var facingFineTuneDeg: Double      // +CW / -CCW, 0° = no adjustment
    @GestureState private var isDragging: Bool = false

    @EnvironmentObject private var mapTransform: MapTransformStore
    @EnvironmentObject private var squareMetrics: SquareMetrics

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Slightly different tint so you can tell it's the tools layer
                Color.black.opacity(0.18).ignoresSafeArea()

                // Display-only: keep this glyph visually aligned as map rotates
                let mapRotationDegCW = radiansCCW_to_degreesCW(mapTransform.totalRotationRadians)
                let displayDeg = facingFineTuneDeg - mapRotationDegCW

                // Reuse the same graphic — it's a "user facing" direction arrow
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.35))
                        .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                    
                    // North arrow
                    VStack {
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: 4, height: 20)
                        Spacer()
                    }
                }
                .frame(width: min(geo.size.width, geo.size.height) * 0.45,
                       height: min(geo.size.width, geo.size.height) * 0.45)
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
                        facingFineTuneDeg = deg

                        // Console diagnostic: North, Facing, and UF-North delta
                        let north = squareMetrics.northOffsetDeg
                        let facing = squareMetrics.facingFineTuneDeg
                        let delta = facing   // UF relative to North reduces to fine-tune
                        print(String(format: "🧭 North Offset: %.2f°, 🛠️ Facing Offset: %.2f°, UF–North Δ: %.2f°",
                                     north, facing, delta))
                    }
            )
        }
        .ignoresSafeArea()
        .allowsHitTesting(true) // When this is visible, it should own the gestures.
    }
}
