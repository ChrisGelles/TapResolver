//
//  MapPointDrawer.swift
//  TapResolver
//
//  by Chris Gelles
//

import SwiftUI
import CoreGraphics

struct MapPointDrawer: View {
    @EnvironmentObject private var mapPointStore: MapPointStore
    @EnvironmentObject private var mapTransform: MapTransformStore
    @EnvironmentObject private var hud: HUDPanelsState

    private let crosshairScreenOffset = CGPoint(x: 0, y: 0)
    private let collapsedWidth: CGFloat = 56
    private let expandedWidth: CGFloat = 172
    private let topBarHeight: CGFloat = 48

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.4))

            // List
            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(mapPointStore.points.sorted(by: { $0.createdDate > $1.createdDate }), id: \.id) { point in
                        MapPointListItem(
                            point: point,
                            coordinateText: mapPointStore.coordinateString(for: point),
                            isActive: mapPointStore.isActive(point.id),
                            onSelect: {
                                mapPointStore.toggleActive(id: point.id)
                            },
                            onDelete: {
                                mapPointStore.removePoint(id: point.id)
                            }
                        )
                        .frame(height: 44)
                        .padding(.leading, 4)
                    }
                }
                .padding(.top, topBarHeight + 6)
                .padding(.bottom, 8)
                .padding(.trailing, 6)
            }
            .scrollIndicators(.hidden)
            .opacity(hud.isMapPointOpen ? 1 : 0)          // hide visuals when closed
            .allowsHitTesting(hud.isMapPointOpen)         // ignore touches when closed

            // Top bar
            HStack(spacing: 2) {
                if hud.isMapPointOpen {
                    Text("Log Points")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer(minLength: 0)
                }
                Button {
                    if hud.isMapPointOpen { 
                        mapPointStore.deactivateAll()
                        hud.closeAll() 
                    } else { 
                        hud.openMapPoint() 
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color.black.opacity(0.4)))
                        .rotationEffect(.degrees(hud.isMapPointOpen ? 180 : 0))
                        .contentShape(Circle())
                }
                .accessibilityLabel(hud.isMapPointOpen ? "Close map point drawer" : "Open map point drawer")
            }
            .padding(.horizontal, 8)
            .frame(height: topBarHeight)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(
            width: hud.isMapPointOpen ? expandedWidth : collapsedWidth,
            height: hud.isMapPointOpen ? min(320, idealOpenHeight) : topBarHeight
        )
        .clipped()
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.25), value: hud.isMapPointOpen)
    }

    private var idealOpenHeight: CGFloat {
        let rows = CGFloat(mapPointStore.points.count)
        let rowsHeight = rows * 44 + (rows - 1) * 6 + 6 + 8
        let total = max(topBarHeight, min(320, topBarHeight + rowsHeight))
        return total
    }
}

struct MapPointListItem: View {
    let point: MapPointStore.MapPoint
    let coordinateText: String
    let isActive: Bool
    var onSelect: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 2) {
            // Coordinate display in rounded rectangle - tappable for selection
            Button(action: { onSelect?() }) {
                Text(coordinateText)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(isActive ? Color(hex: 0x10fff1).opacity(0.9) : Color.blue.opacity(0.2))
                    )
                    .fixedSize(horizontal: true, vertical: true)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isActive ? "Deactivate map point" : "Activate map point")
            
            Spacer(minLength: 0)

            // Delete button (red X)
            Button(action: { onDelete?() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.red)
                    .frame(width: 24, height: 24)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete map point")
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
}
