//
//  BeaconDrawer.swift
//  TapResolver
//

import SwiftUI
import CoreGraphics

// One shared screen-space tweak for crosshair and dot-drop alignment
enum CrosshairConfig {
    static var screenOffset = CGPoint(x: 100, y: 100)
}

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
            .opacity(hud.isBeaconOpen ? 1 : 0)          // <— hide visuals when closed
            .allowsHitTesting(hud.isBeaconOpen)         // <— ignore touches when closed

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
                        hud.openBeacon()
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

// Row with capsule (tap to drop dot) + Elevation + Lock + Demote
struct BeaconListItem: View {
    let beaconName: String
    let isLocked: Bool
    let elevationText: String
    var onSelect: ((CGPoint, Color) -> Void)? = nil
    var onToggleLock: (() -> Void)? = nil
    var onDemote: (() -> Void)? = nil
    var onEditElevation: (() -> Void)? = nil

    private var beaconColor: Color {
        let hash = beaconName.hash
        let hue = Double(abs(hash % 360)) / 360.0
        return Color(hue: hue, saturation: 0.7, brightness: 0.8)
    }

    var body: some View {
        HStack(spacing: 4) {
            // Capsule (tap to add/remove dot) - disabled when locked
            HStack(spacing: 6) {
                Circle().fill(beaconColor).frame(width: 12, height: 12)
                Text(beaconName)
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundColor(.primary)
                    .frame(width: 32)
            }
            .padding(.horizontal, 3)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(beaconColor.opacity(isLocked ? 0.1 : 0.2))
            )
            .contentShape(Rectangle())
            .onTapGesture(coordinateSpace: .global) { globalPoint in
                guard !isLocked else { return } // Block when locked
                onSelect?(globalPoint, beaconColor)
            }
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

            // 🔒 Lock toggle
            Button(action: { onToggleLock?() }) {
                Image(systemName: isLocked ? "lock.fill" : "lock.open")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(isLocked ? .yellow : .primary)
                    .frame(width: 24, height: 24)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isLocked ? "Unlock dot" : "Lock dot")

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
    }
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
        .opacity(hud.isBeaconOpen ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 0.15), value: hud.isBeaconOpen)
    }
}

// MARK: - Elevation keypad overlay
struct BeaconElevationKeypadOverlay: View {
    @EnvironmentObject private var beaconDotStore: BeaconDotStore

    private let keyRows: [[String]] = [
        ["1","2","3"],
        ["4","5","6"],
        ["7","8","9"],
        [".","0","⌫"]
    ]

    var body: some View {
        if let edit = beaconDotStore.activeElevationEdit {
            ZStack {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture { beaconDotStore.activeElevationEdit = nil }

                VStack(spacing: 10) {
                    Text(edit.text.isEmpty ? " " : edit.text)
                        .font(.system(size: 22, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.top, 12)

                    VStack(spacing: 8) {
                        ForEach(0..<keyRows.count, id: \.self) { r in
                            HStack(spacing: 8) {
                                ForEach(keyRows[r], id: \.self) { key in
                                    Button { tap(key: key) } label: {
                                        Text(key)
                                            .font(.system(size: 20, weight: .medium))
                                            .frame(width: 68, height: 44)
                                            .background(Color.white.opacity(0.12))
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        HStack {
                            Button {
                                let beaconID = edit.beaconID
                                let text = edit.text
                                beaconDotStore.commitElevationText(text, for: beaconID)
                                beaconDotStore.activeElevationEdit = nil
                            } label: {
                                Text("Enter")
                                    .font(.system(size: 18, weight: .semibold))
                                    .frame(maxWidth: .infinity, minHeight: 46)
                                    .background(Color.white.opacity(0.2))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 16)
                    .background(.ultraThinMaterial)
                    .cornerRadius(14)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
            .transition(.opacity)
            .zIndex(200)
            .allowsHitTesting(true)
        }
    }

    private func tap(key: String) {
        guard var edit = beaconDotStore.activeElevationEdit else { return }
        switch key {
        case "⌫":
            if !edit.text.isEmpty { edit.text.removeLast() }
        case ".":
            if !edit.text.contains(".") { edit.text.append(".") }
        default:
            if key.allSatisfy({ $0.isNumber }) {
                if edit.text == "0" { edit.text = key }
                else { edit.text.append(contentsOf: key) }
            }
        }
        beaconDotStore.activeElevationEdit = edit
    }
}
