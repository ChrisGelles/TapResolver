//
//  BeaconDrawer.swift
//  TapResolver
//

import SwiftUI
import CoreGraphics

struct BeaconDrawer: View {
    @EnvironmentObject private var beaconDotStore: BeaconDotStore
    @EnvironmentObject private var mapTransform: MapTransformStore
    @EnvironmentObject private var hud: HUDPanelsState

    private let collapsedWidth: CGFloat = 56
    private let expandedWidth: CGFloat = 160
    private let topBarHeight: CGFloat = 48

    private let mockBeacons = [
        "12-rowdySquirrel","15-frostyIbis","08-bouncyPenguin","23-sparklyDolphin","31-gigglyGiraffe"
    ]

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.4))

            // List
            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(mockBeacons.sorted(), id: \.self) { name in
                        BeaconListItem(beaconName: name) { globalTapPoint, color in
                            let shifted = CGPoint(x: globalTapPoint.x - 20, y: globalTapPoint.y)
                            let mapPoint = mapTransform.screenToMap(shifted)
                            beaconDotStore.toggleDot(for: name, mapPoint: mapPoint, color: color)
                            hud.isBeaconOpen = false // close after selection
                        }
                        .frame(height: 44)
                        .padding(.leading, 8)
                    }
                }
                .padding(.top, topBarHeight + 6)
                .padding(.bottom, 8)
                .padding(.trailing, 6)
            }

            // Header
            HStack(spacing: 2) {
                if hud.isBeaconOpen {
                    Text("Beacons")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer(minLength: 0)
                }
                Button {
                    if hud.isBeaconOpen {
                        hud.closeAll()
                    } else {
                        hud.openBeacon()  // <- closes squares drawer
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color.black.opacity(0.4)))
                        .rotationEffect(.degrees(hud.isBeaconOpen ? 180 : 0))
                        .contentShape(Circle())
                }
                .accessibilityLabel(hud.isBeaconOpen ? "Close beacon drawer" : "Open beacon drawer")
            }
            .padding(.horizontal, 12)
            .frame(height: topBarHeight)
        }
        .frame(
            width: hud.isBeaconOpen ? expandedWidth : collapsedWidth,
            height: hud.isBeaconOpen ? 300 : topBarHeight
        )
        .clipped()
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.25), value: hud.isBeaconOpen)
    }
}

// Row with global-tap callback
struct BeaconListItem: View {
    let beaconName: String
    var onSelect: ((CGPoint, Color) -> Void)? = nil

    private var beaconColor: Color {
        let hash = beaconName.hash
        let hue = Double(abs(hash % 360)) / 360.0
        return Color(hue: hue, saturation: 0.7, brightness: 0.8)
    }

    var body: some View {
        HStack(spacing: 10) {
            Circle().fill(beaconColor).frame(width: 12, height: 12)
            Text(beaconName)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(.primary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(beaconColor.opacity(0.2))
        )
        .contentShape(Rectangle())
        .onTapGesture(coordinateSpace: .global) { globalPoint in
            onSelect?(globalPoint, beaconColor)
        }
    }
}
