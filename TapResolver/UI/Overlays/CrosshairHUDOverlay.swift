//
//  CrosshairHUDOverlay.swift
//  TapResolver
//
//  Created by restructuring on 9/19/25.
//

import SwiftUI

// One shared screen-space tweak for crosshair and dot-drop alignment
enum CrosshairConfig {
    static var screenOffset = CGPoint(x: 100, y: 100)
}

// MARK: - Crosshair overlay unchanged
struct CrosshairHUDOverlay: View {
    @EnvironmentObject private var hud: HUDPanelsState
    @EnvironmentObject private var mapTransform: MapTransformStore

    var body: some View {
        GeometryReader { _ in
            let p = mapTransform.screenCenter
            let r: CGFloat = 12
            ZStack {
                Circle().stroke(Color.black, lineWidth: 1)
                    .frame(width: r * 2, height: r * 2)
                    .position(x: p.x, y: p.y)
                Path { path in
                    path.move(to: CGPoint(x: p.x - r * 1.6, y: p.y))
                    path.addLine(to: CGPoint(x: p.x + r * 1.6, y: p.y))
                }
                .stroke(Color.black, lineWidth: 1)
                Path { path in
                    path.move(to: CGPoint(x: p.x, y: p.y - r * 1.6))
                    path.addLine(to: CGPoint(x: p.x, y: p.y + r * 1.6))
                }
                .stroke(Color.black, lineWidth: 1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .opacity(hud.isBeaconOpen || hud.isMapPointOpen ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 0.15), value: hud.isBeaconOpen || hud.isMapPointOpen)
    }
}
