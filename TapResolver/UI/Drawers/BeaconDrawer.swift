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
    @EnvironmentObject private var beaconLists: BeaconListsStore

    private let crosshairScreenOffset = CGPoint(x: 0, y: 0)
    private let collapsedWidth: CGFloat = 56
    private let expandedWidth: CGFloat = 160
    private let topBarHeight: CGFloat = 48

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.4))

            // List
            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(beaconLists.beacons.sorted(), id: \.self) { name in
                        let locked = beaconDotStore.isLocked(name)
                        BeaconListItem(
                            beaconName: name,
                            isLocked: locked,
                            elevationText: beaconDotStore.displayElevationText(for: name),
                            onSelect: { _, color in
                                guard mapTransform.mapSize != .zero else {
                                    print("⚠️ Beacon add ignored: mapTransform not ready (mapSize == .zero)")
                                    return
                                }
                                let targetScreen = mapTransform.screenCenter
                                let mapPoint = mapTransform.screenToMap(targetScreen)
                                beaconDotStore.toggleDot(for: name, mapPoint: mapPoint, color: color)
                                hud.isBeaconOpen = false
                            },
                            onToggleLock: {
                                beaconDotStore.toggleLock(name)
                            },
                            onDemote: {
                                beaconLists.demoteToMorgue(name)
                            },
                            onEditElevation: {
                                beaconDotStore.startElevationEdit(for: name)
                            }
                        )
                    }
                }
                .padding(.top, topBarHeight + 6)
                .padding(.bottom, 8)
                .padding(.trailing, 6)
            }
            .scrollIndicators(.hidden)

            // Top bar
            HStack(spacing: 2) {
                if hud.isBeaconOpen {
                    Text("Beacon List")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer(minLength: 0)
                }
                Button {
                    if hud.isBeaconOpen { hud.closeAll() } else { hud.openBeacon() }
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
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(
            width: hud.isBeaconOpen ? expandedWidth : collapsedWidth,
            height: hud.isBeaconOpen ? min(320, idealOpenHeight) : topBarHeight
        )
        .clipped()
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.25), value: hud.isBeaconOpen)
    }

    private var idealOpenHeight: CGFloat {
        let rows = CGFloat(beaconLists.beacons.count)
        let rowsHeight = rows * 44 + (rows - 1) * 6 + 6 + 8
        let total = max(topBarHeight, min(320, topBarHeight + rowsHeight))
        return total
    }
}

struct BeaconListItem: View {
    let beaconName: String
    let isLocked: Bool
    let elevationText: String
    var onSelect: ((CGPoint, Color) -> Void)? = nil
    var onToggleLock: (() -> Void)? = nil
    var onDemote: (() -> Void)? = nil
    var onEditElevation: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 8) {
            // Beacon dot (tap to add/remove from map)
            Button {
                onSelect?(CGPoint.zero, beaconColor(for: beaconName))
            } label: {
                Circle()
                    .fill(beaconColor(for: beaconName))
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle().stroke(Color.white, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .disabled(isLocked) // Visual feedback when locked

            // Beacon name (tap to add/remove from map)
            Button {
                onSelect?(CGPoint.zero, beaconColor(for: beaconName))
            } label: {
                Text(beaconName)
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.black.opacity(isLocked ? 0.1 : 0.3))
                    )
            }
            .buttonStyle(.plain)
            .disabled(isLocked) // Visual feedback when locked

            // Elevation textfield
            Button {
                onEditElevation?()
            } label: {
                Text(elevationText)
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(4)
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)

            // 🔒 Lock toggle
            Button {
                onToggleLock?()
            } label: {
                Image(systemName: isLocked ? "lock.fill" : "lock.open")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(isLocked ? .yellow : .primary)
                    .frame(width: 24, height: 24)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isLocked ? "Unlock beacon" : "Lock beacon")

            // Demote button (red arrow down)
            Button {
                onDemote?()
            } label: {
                Image(systemName: "arrow.down")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.red)
                    .frame(width: 24, height: 24)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Move to morgue")
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .contentShape(Rectangle())
    }

    private func beaconColor(for beaconID: String) -> Color {
        let hash = beaconID.hash
        let hue = Double(abs(hash % 360)) / 360.0
        return Color(hue: hue, saturation: 0.7, brightness: 0.8)
    }
}
