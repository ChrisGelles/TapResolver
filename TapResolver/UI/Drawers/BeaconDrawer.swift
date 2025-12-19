//
//  BeaconDrawer.swift
//  TapResolver
//

import SwiftUI
import CoreGraphics
import Combine

struct BeaconDrawer: View {
    @EnvironmentObject private var beaconDotStore: BeaconDotStore
    @EnvironmentObject private var mapTransform: MapTransformStore
    @EnvironmentObject private var hud: HUDPanelsState
    @EnvironmentObject private var beaconLists: BeaconListsStore

    private let crosshairScreenOffset = CGPoint(x: 0, y: 0)
    private let collapsedWidth: CGFloat = 56
    private let expandedWidth: CGFloat = 220
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
                        let hasDot = beaconDotStore.dot(for: name) != nil
                        BeaconListItem(
                            beaconName: name,
                            isLocked: locked,
                            hasDot: hasDot,
                            elevationText: beaconDotStore.displayElevationText(for: name),
                            txPowerText: txPowerDisplayText(for: name),
                            isSelected: false,
                            onSelect: { _, color in
                                // Center on dot if one exists
                                if let dot = beaconDotStore.dot(for: name) {
                                    mapTransform.centerOnPoint(dot.mapPoint, animated: true)
                                }
                                
                                // Only toggle dot if unlocked (existing behavior)
                                guard !locked else { return }
                                
                                guard mapTransform.mapSize != .zero else {
                                    print("⚠️ Beacon add ignored: mapTransform not ready (mapSize == .zero)")
                                    return
                                }
                                let targetScreen = mapTransform.screenCenter
                                // Configurable X and Y pixel offsets
                                let offsetX: CGFloat = 0.0  // Adjust this value as needed
                                let offsetY: CGFloat = 48.0  // Adjust this value as needed
                                let adjustedScreen = CGPoint(x: targetScreen.x + offsetX, y: targetScreen.y + offsetY)
                                let mapPoint = mapTransform.screenToMap(adjustedScreen)
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
                                // Start elevation editing directly in this drawer
                                beaconDotStore.startElevationEdit(for: name)
                            },
                            onSelectForTxPower: {
                                NotificationCenter.default.post(name: .beaconSelectedForTxPower, object: name)
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
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        mapTransform.isHUDInteracting = true
                    }
                    .onEnded { _ in
                        mapTransform.isHUDInteracting = false
                    }
            )

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
            .padding(.horizontal, 8)
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
    
    private func txPowerDisplayText(for beaconID: String) -> String {
        if let txPower = beaconDotStore.getTxPower(for: beaconID) {
            return "\(txPower)dBm"
        } else {
            return "Tx"
        }
    }
}

struct BeaconListItem: View {
    let beaconName: String
    let isLocked: Bool
    let hasDot: Bool
    let elevationText: String
    let txPowerText: String
    let isSelected: Bool
    var onSelect: ((CGPoint, Color) -> Void)? = nil
    var onToggleLock: (() -> Void)? = nil
    var onDemote: (() -> Void)? = nil
    var onEditElevation: (() -> Void)? = nil
    var onSelectForTxPower: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 2) {

            // Capsule button (dot + name) — disabled when locked
            HStack(spacing: 2) {
                ZStack {
                    Circle()
                        .fill(beaconColor(for: beaconName))
                        .frame(width: 12, height: 12)
                    // Show checkmark if beacon has a dot placed on map
                    if hasDot {
                        Image(systemName: "checkmark")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 12, height: 12)                  // ← tweak dot size
                .padding(.leading, 6)
                Text(beaconName)
                    .font(.system(size: 10, weight: .medium, design: .monospaced)) // ← font
                    .foregroundColor(.primary)
                    //.lineLimit(10)
                    .allowsTightening(true)
                    //.truncationMode(.tail)
                    .frame(minWidth: 60, maxWidth: 72, alignment: .leading)        // ← tweak name width
            }
            .padding(.horizontal, 0)                                // ← capsule H padding
            .padding(.vertical, 6)                                  // ← capsule V padding
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(beaconColor(for: beaconName).opacity(isLocked ? 0.10 : 0.20))
            )
            .contentShape(Rectangle())
            .onTapGesture(coordinateSpace: .global) { globalPoint in
                if isLocked {
                    // When locked, select for Tx Power editing
                    onSelectForTxPower?()
                } else {
                    // When unlocked, add/remove dot
                    onSelect?(globalPoint, beaconColor(for: beaconName))
                }
            }

            // Elevation "pill" (opens keypad)
            Button {
                onEditElevation?()
            } label: {
                Text(elevationText)
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 0)                        // ← pill H padding
                    .padding(.vertical, 4)                          // ← pill V padding
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(4)
                    .fixedSize(horizontal: true, vertical: true)
            }
            .buttonStyle(.plain)

            // Tx Power "pill" (opens Tx Power selection)
            Button {
                onSelectForTxPower?()
            } label: {
                Text(txPowerText)
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 0)                        // ← pill H padding
                    .padding(.vertical, 4)                          // ← pill V padding
                    .background(isSelected ? Color.blue.opacity(0.7) : Color.black.opacity(0.5))
                    .cornerRadius(4)
                    .fixedSize(horizontal: true, vertical: true)
            }
            .buttonStyle(.plain)

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
        .padding(.horizontal, 0)                                    // ← row side padding
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
