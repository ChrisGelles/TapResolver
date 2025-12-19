//
//  MorgueDrawer.swift
//  TapResolver
//

import SwiftUI

struct MorgueDrawer: View {
    @EnvironmentObject private var hud: HUDPanelsState
    @EnvironmentObject private var beaconLists: BeaconListsStore
    @EnvironmentObject private var mapTransform: MapTransformStore

    private let collapsedWidth: CGFloat = 56
    private let expandedWidth: CGFloat = 180
    private let topBarHeight: CGFloat = 48
    private let rowHeight: CGFloat = 44
    private let drawerMaxHeight: CGFloat = 300

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.4))

            // List (gray items) — smart sorted: beacon-pattern alphabetical, others newest first
            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(beaconLists.sortedMorgue) { item in
                        MorgueListItem(
                            name: item.displayName,
                            hasHistory: item.hasHistory,
                            onPromote: {
                                beaconLists.promoteToBeacons(item.displayName)
                            },
                            onClearHistory: {
                                beaconLists.clearHistory(for: item.displayName)
                            }
                        )
                        .frame(height: rowHeight)
                        .padding(.leading, 8)
                    }
                }
                .padding(.top, topBarHeight + 6)
                .padding(.bottom, 8)
                .padding(.trailing, 6)
            }
            .scrollIndicators(.hidden)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        mapTransform.isHUDInteracting = true
                    }
                    .onEnded { _ in
                        mapTransform.isHUDInteracting = false
                    }
            )

            // Header
            HStack(spacing: 2) {
                if hud.isMorgueOpen {
                    Text("Morgue")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer(minLength: 0)
                }
                Button {
                    if hud.isMorgueOpen {
                        hud.closeAll()
                    } else {
                        hud.openMorgue() // closes others
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color.black.opacity(0.4)))
                        .rotationEffect(.degrees(hud.isMorgueOpen ? 180 : 0))
                        .contentShape(Circle())
                }
                .accessibilityLabel(hud.isMorgueOpen ? "Close morgue drawer" : "Open morgue drawer")
            }
            .padding(.horizontal, 12)
            .frame(height: topBarHeight)
        }
        .frame(
            width: hud.isMorgueOpen ? expandedWidth : collapsedWidth,
            height: hud.isMorgueOpen ? drawerMaxHeight : topBarHeight
        )
        .clipped()
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.25), value: hud.isMorgueOpen)
    }
}

private struct MorgueListItem: View {
    let name: String
    let hasHistory: Bool
    var onPromote: () -> Void
    var onClearHistory: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            // Dot indicator - yellow star if has history, gray dot if ephemeral
            if hasHistory {
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.yellow)
                    .frame(width: 12, height: 12)
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 8, height: 8)
            }
            Text(name)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(.primary)
                .lineLimit(1)
            Spacer(minLength: 0)
            
            // Clear history button (red X) - only shown for items with history
            if hasHistory {
                Button(action: onClearHistory) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.red)
                        .frame(width: 20, height: 20)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear history (make ephemeral)")
            }
            // Promote button (green arrow up)
            Button(action: onPromote) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.green)
                    .frame(width: 24, height: 24)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Promote to Beacon list")
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(hasHistory ? Color.yellow.opacity(0.1) : Color.gray.opacity(0.2))
        )
        .contentShape(Rectangle())
    }
}
