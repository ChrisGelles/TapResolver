//
//  ZoneDrawer.swift
//  TapResolver
//
//  Drawer for viewing and selecting calibration zones.
//  Follows the MapPointDrawer pattern.
//

import SwiftUI

struct ZoneDrawer: View {
    @EnvironmentObject private var hud: HUDPanelsState
    @EnvironmentObject private var zoneStore: ZoneStore
    
    // MARK: - Layout Constants
    private let collapsedWidth: CGFloat = 56
    private let expandedWidth: CGFloat = 180
    private let topBarHeight: CGFloat = 48
    private let drawerMaxHeight: CGFloat = 240
    private let rowHeight: CGFloat = 44
    private let rowSpacing: CGFloat = 6
    
    private var idealOpenHeight: CGFloat {
        let contentHeight = CGFloat(zoneStore.zones.count) * (rowHeight + rowSpacing)
        return topBarHeight + contentHeight + 12
    }
    
    private var currentWidth: CGFloat {
        hud.isZoneOpen ? expandedWidth : collapsedWidth
    }
    
    private var currentHeight: CGFloat {
        hud.isZoneOpen ? min(drawerMaxHeight, idealOpenHeight) : topBarHeight
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.4))
            
            VStack(spacing: 0) {
                // Top bar with title and toggle button
                topBar
                
                // Expandable content
                if hud.isZoneOpen {
                    zoneList
                }
            }
        }
        .frame(width: currentWidth, height: currentHeight)
        .animation(.easeInOut(duration: 0.25), value: hud.isZoneOpen)
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack(spacing: 8) {
            if hud.isZoneOpen {
                Text("Zones")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                // Count badge
                if !zoneStore.zones.isEmpty {
                    Text("\(zoneStore.zones.count)")
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.8))
                        .cornerRadius(8)
                }
                
                Spacer()
            }
            
            // Toggle button
            Button {
                if hud.isZoneOpen {
                    hud.closeAll()
                } else {
                    hud.openZone()
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .rotationEffect(.degrees(hud.isZoneOpen ? 180 : 0))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.black.opacity(0.4)))
            }
        }
        .padding(.horizontal, 8)
        .frame(height: topBarHeight)
    }
    
    // MARK: - Zone List
    
    private var zoneList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: rowSpacing) {
                ForEach(zoneStore.zones) { zone in
                    ZoneListItem(
                        zone: zone,
                        isSelected: zoneStore.selectedZoneID == zone.id,
                        onSelect: {
                            if zoneStore.selectedZoneID == zone.id {
                                zoneStore.selectZone(nil)
                            } else {
                                zoneStore.selectZone(zone.id)
                            }
                        },
                        onDelete: {
                            zoneStore.deleteZone(zone.id)
                        },
                        onToggleLock: {
                            zoneStore.toggleLock(zoneID: zone.id)
                        }
                    )
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
    }
}

// MARK: - Zone List Item

struct ZoneListItem: View {
    let zone: Zone
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    let onToggleLock: () -> Void
    
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        HStack(spacing: 6) {
            // Zone name button (tappable, shows selection state)
            Button(action: onSelect) {
                Text(zone.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(isSelected ? Color(hex: 0x10fff1).opacity(0.9) : Color.blue.opacity(0.2))
                    )
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Triangle count
            HStack(spacing: 2) {
                Image(systemName: "triangle")
                    .font(.system(size: 9))
                Text("\(zone.triangleIDs.count)")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
            }
            .foregroundColor(.secondary)
            
            // Lock toggle
            Button(action: onToggleLock) {
                Image(systemName: zone.isLocked ? "lock.fill" : "lock.open")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(zone.isLocked ? .yellow : .primary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            
            // Delete button (only when unlocked)
            if !zone.isLocked {
                Button {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red.opacity(0.8))
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Color.white.opacity(0.1)))
                }
                .confirmationDialog("Delete '\(zone.name)'?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                    Button("Delete", role: .destructive) {
                        onDelete()
                    }
                    Button("Cancel", role: .cancel) {}
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .frame(height: 44)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.08))
        )
    }
}

// MARK: - Preview

#Preview {
    ZoneDrawer()
        .environmentObject(HUDPanelsState())
        .environmentObject(ZoneStore())
        .preferredColorScheme(.dark)
}

