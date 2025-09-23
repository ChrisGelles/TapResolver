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
                        .frame(height: 44)
                        .padding(.leading, 8)
                    }
                }
                .padding(.top, topBarHeight + 6)
                .padding(.bottom, 8)
                .padding(.trailing, 6)
            }
            .scrollIndicators(.hidden)
            .opacity(hud.isBeaconOpen ? 1 : 0)          // hide visuals when closed
            .allowsHitTesting(hud.isBeaconOpen)         // ignore touches when closed

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

            // Capsule button (dot + name) — disabled when locked
            HStack(spacing: 6) {
                Circle()
                    .fill(beaconColor(for: beaconName))
                    .frame(width: 12, height: 12)                  // ← tweak dot size
                Text(beaconName)
                    .font(.system(size: 9, weight: .medium, design: .monospaced)) // ← font
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(minWidth: 0, maxWidth: 72, alignment: .leading)        // ← tweak name width
            }
            .padding(.horizontal, 8)                                // ← capsule H padding
            .padding(.vertical, 6)                                  // ← capsule V padding
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(beaconColor(for: beaconName).opacity(isLocked ? 0.10 : 0.20))
            )
            .contentShape(Rectangle())
            .onTapGesture(coordinateSpace: .global) { globalPoint in
                guard !isLocked else { return } // block when locked
                onSelect?(globalPoint, beaconColor(for: beaconName))
            }
            .disabled(isLocked)

            // Elevation “pill” (opens keypad)
            Button {
                onEditElevation?()
            } label: {
                Text(elevationText)
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)                        // ← pill H padding
                    .padding(.vertical, 4)                          // ← pill V padding
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(4)
                    .fixedSize(horizontal: true, vertical: true)
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)

            // 🔒 Lock toggle
            Button(action: { onToggleLock?() }) {
                Image(systemName: isLocked ? "lock.fill" : "lock.open")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(isLocked ? .yellow : .primary)
                    .frame(width: 24, height: 24)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isLocked ? "Unlock beacon" : "Lock beacon")

            // Demote (down arrow)
            Button(action: { onDemote?() }) {
                Image(systemName: "arrow.down")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.red)
                    .frame(width: 24, height: 24)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Send to Morgue")
        }
        .padding(.horizontal, 4)                                    // ← row side padding
        .padding(.vertical, 6)                                      // ← row vertical padding
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .contentShape(Rectangle())
        .frame(height: 44)                                          // ← row height (matches drawer)
    }

    private func beaconColor(for beaconID: String) -> Color {
        let hash = beaconID.hash
        let hue = Double(abs(hash % 360)) / 360.0
        return Color(hue: hue, saturation: 0.7, brightness: 0.8)
    }
}
