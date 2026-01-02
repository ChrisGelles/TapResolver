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
    private let rowHeight: CGFloat = 52
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
    
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        HStack(spacing: 8) {
            // Selection indicator
            Circle()
                .fill(isSelected ? Color(hex: 0x10fff1).opacity(0.9) : Color.clear)
                .frame(width: 8, height: 8)
            
            // Zone info (tappable)
            Button(action: onSelect) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(zone.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        // Corner count
                        Image(systemName: "square.dashed")
                            .font(.system(size: 9))
                        Text("\(zone.cornerIDs.count)")
                            .font(.system(size: 10))
                        
                        // Triangle count
                        Image(systemName: "triangle")
                            .font(.system(size: 9))
                        Text("\(zone.triangleIDs.count)")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .buttonStyle(.plain)
            
            // Delete button
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
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(height: 52)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.orange.opacity(0.15) : Color.white.opacity(0.08))
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

