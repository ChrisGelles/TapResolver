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
    @EnvironmentObject private var zoneGroupStore: ZoneGroupStore
    @EnvironmentObject private var mapTransform: MapTransformStore
    
    // Track which groups are expanded
    @State private var expandedGroupIDs: Set<String> = []
    
    // MARK: - Layout Constants
    private let collapsedWidth: CGFloat = 56
    private let expandedWidth: CGFloat = 220
    private let topBarHeight: CGFloat = 48
    private let drawerMaxHeight: CGFloat = 240
    private let rowHeight: CGFloat = 44
    private let rowSpacing: CGFloat = 6
    
    private var idealOpenHeight: CGFloat {
        // Count group headers + expanded zones + ungrouped zones
        let groupHeaderCount = zoneGroupStore.groups.count
        let expandedZoneCount = expandedGroupIDs.reduce(0) { count, groupID in
            count + (zoneGroupStore.group(withID: groupID)?.zoneIDs.count ?? 0)
        }
        let ungroupedCount = ungroupedZones.count
        let hasUngroupedHeader = ungroupedCount > 0 ? 1 : 0
        
        let totalRows = groupHeaderCount + expandedZoneCount + ungroupedCount + hasUngroupedHeader
        let contentHeight = CGFloat(totalRows) * (rowHeight + rowSpacing)
        return topBarHeight + contentHeight + 12
    }
    
    /// Zones that don't belong to any group
    private var ungroupedZones: [Zone] {
        zoneStore.zones.filter { $0.groupID == nil }
    }
    
    /// Get zones belonging to a specific group
    private func zonesInGroup(_ groupID: String) -> [Zone] {
        zoneStore.zones.filter { $0.groupID == groupID }
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
                // Visibility toggle
                Button {
                    zoneStore.zonesVisible.toggle()
                } label: {
                    Image(systemName: zoneStore.zonesVisible ? "eye.fill" : "eye.slash")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(zoneStore.zonesVisible ? .green : .secondary)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                
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
                // Zone Groups with their child zones
                ForEach(zoneGroupStore.groups) { group in
                    // Group header
                    ZoneGroupHeader(
                        group: group,
                        zoneCount: zonesInGroup(group.id).count,
                        isExpanded: expandedGroupIDs.contains(group.id),
                        isSelected: zoneGroupStore.selectedGroupID == group.id,
                        onToggleExpand: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if expandedGroupIDs.contains(group.id) {
                                    expandedGroupIDs.remove(group.id)
                                } else {
                                    expandedGroupIDs.insert(group.id)
                                }
                            }
                        },
                        onSelect: {
                            if zoneGroupStore.selectedGroupID == group.id {
                                zoneGroupStore.selectedGroupID = nil
                            } else {
                                zoneGroupStore.selectedGroupID = group.id
                            }
                        }
                    )
                    
                    // Child zones (when expanded)
                    if expandedGroupIDs.contains(group.id) {
                        ForEach(zonesInGroup(group.id)) { zone in
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
                                },
                                onRename: { newName in
                                    zoneStore.renameZone(zoneID: zone.id, newName: newName)
                                }
                            )
                            .padding(.leading, 16) // Indent child zones
                        }
                    }
                }
                
                // Ungrouped zones section
                if !ungroupedZones.isEmpty {
                    // Ungrouped header
                    HStack {
                        Text("Ungrouped")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(ungroupedZones.count)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .padding(.top, 8)
                    
                    ForEach(ungroupedZones) { zone in
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
                            },
                            onRename: { newName in
                                zoneStore.renameZone(zoneID: zone.id, newName: newName)
                            }
                        )
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    mapTransform.isHUDInteracting = true
                }
                .onEnded { _ in
                    mapTransform.isHUDInteracting = false
                }
        )
    }
}

// MARK: - Zone List Item

struct ZoneListItem: View {
    let zone: Zone
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    let onToggleLock: () -> Void
    let onRename: (String) -> Void
    
    @State private var showDeleteConfirmation = false
    @State private var showRenameDialog = false
    @State private var newName = ""
    
    var body: some View {
        HStack(spacing: 6) {
            // Zone name button (tap to select, long-press to rename)
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
                .onTapGesture {
                    onSelect()
                }
                .onLongPressGesture {
                    newName = zone.name
                    showRenameDialog = true
                }
                .alert("Rename Zone", isPresented: $showRenameDialog) {
                    TextField("Zone name", text: $newName)
                    Button("Cancel", role: .cancel) {
                        newName = ""
                    }
                    Button("Rename") {
                        onRename(newName)
                        newName = ""
                    }
                } message: {
                    Text("Enter a new name for '\(zone.name)'")
                }
            
            Spacer()
            
            // Triangle count
            HStack(spacing: 2) {
                Image(systemName: "triangle")
                    .font(.system(size: 9))
                Text("\(zone.memberTriangleIDs.count)")
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

// MARK: - Zone Group Header

struct ZoneGroupHeader: View {
    let group: ZoneGroup
    let zoneCount: Int
    let isExpanded: Bool
    let isSelected: Bool
    let onToggleExpand: () -> Void
    let onSelect: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            // Expand/collapse chevron
            Button(action: onToggleExpand) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
            
            // Color indicator
            Circle()
                .fill(group.color)
                .frame(width: 12, height: 12)
            
            // Group name (tap to select)
            Text(group.displayName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(1)
                .onTapGesture {
                    onSelect()
                }
            
            Spacer()
            
            // Zone count badge
            Text("\(zoneCount)")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(group.color.opacity(0.8))
                .cornerRadius(6)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .frame(height: 44)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? group.color.opacity(0.3) : Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? group.color : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Preview

#Preview {
    ZoneDrawer()
        .environmentObject(HUDPanelsState())
        .environmentObject(ZoneStore())
        .environmentObject(ZoneGroupStore())
        .environmentObject(MapTransformStore())
        .preferredColorScheme(.dark)
}

