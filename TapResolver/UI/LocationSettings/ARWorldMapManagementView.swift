//
//  ARWorldMapManagementView.swift
//  TapResolver
//
//  Created by Chris Gelles on 10/26/25.
//


//
//  ARWorldMapManagementView.swift
//  TapResolver
//
//  Role: Settings panel for AR World Map management
//

import SwiftUI

struct ARWorldMapManagementView: View {
    @EnvironmentObject private var worldMapStore: ARWorldMapStore
    @State private var showScanView = false
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            header
            
            // Show patches if they exist
            if !worldMapStore.patches.isEmpty {
                patchesSection
            } else if worldMapStore.metadata.exists {
                // Legacy single world map exists
                legacyWorldMapSection
            } else {
                // No map exists
                emptyStateView
            }
            
            Spacer()
        }
        .padding(20)
        .sheet(isPresented: $showScanView) {
            ARWorldMapScanView(isPresented: $showScanView)
                .environmentObject(worldMapStore)
        }
        .alert("Delete AR Environment?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                worldMapStore.deleteWorldMap()
            }
        } message: {
            Text("This will permanently delete the AR world map and all scan data. AR markers will no longer work until you rescan.")
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("AR Environment")
                    .font(.system(size: 24, weight: .bold))
                
                Text("Spatial mapping for AR features")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if worldMapStore.metadata.exists {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.green)
            }
        }
    }
    
    // MARK: - Status Card
    
    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "map.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                
                Text("World Map Status")
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
                
                Text("v\(worldMapStore.metadata.version)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .cornerRadius(4)
            }
            
            Divider()
            
            // Metrics
            HStack(spacing: 20) {
                metricItem(icon: "point.3.filled.connected.trianglepath.dotted",
                          label: "Feature Points",
                          value: "\(worldMapStore.metadata.featurePointCount)")
                
                Spacer()
                
                metricItem(icon: "square.stack.3d.up.fill",
                          label: "Planes",
                          value: "\(worldMapStore.metadata.planeCount)")
                
                Spacer()
                
                metricItem(icon: "doc.fill",
                          label: "File Size",
                          value: String(format: "%.1f MB", worldMapStore.metadata.fileSize_mb))
            }
            
            Divider()
            
            // Last updated
            HStack {
                Text("Last Updated:")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formatDate(worldMapStore.metadata.lastUpdated))
                    .font(.system(size: 14, weight: .medium))
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func metricItem(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Scan History
    
    private var scanHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Scan History")
                .font(.system(size: 16, weight: .semibold))
            
            ForEach(worldMapStore.metadata.scanSessions.suffix(5).reversed(), id: \.sessionID) { session in
                scanSessionRow(session)
            }
            
            if worldMapStore.metadata.scanSessions.count > 5 {
                Text("+ \(worldMapStore.metadata.scanSessions.count - 5) earlier sessions")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.leading, 12)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func scanSessionRow(_ session: ARWorldMapStore.WorldMapMetadata.ScanSession) -> some View {
        HStack(spacing: 12) {
            Image(systemName: session.action == "initial_scan" ? "doc.badge.plus" : "arrow.triangle.branch")
                .font(.system(size: 16))
                .foregroundColor(session.action == "initial_scan" ? .green : .blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(session.areaCovered)
                    .font(.system(size: 14, weight: .medium))
                
                Text("\(formatDate(session.timestamp)) • \(String(format: "%.1fs", session.duration_s))")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("+\(session.newFeaturePoints)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.blue)
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    // MARK: - Actions
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            // Extend button
            Button(action: {
                showScanView = true
            }) {
                HStack {
                    Image(systemName: "plus.viewfinder")
                        .font(.system(size: 18))
                    
                    Text("Scan New Patch")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.blue)
                .cornerRadius(10)
            }
            
            // Delete button
            Button(action: {
                showDeleteConfirmation = true
            }) {
                HStack {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 18))
                    
                    Text("Delete AR Environment")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.red)
                .cornerRadius(10)
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "arkit")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No AR Environment")
                .font(.system(size: 20, weight: .semibold))
            
            Text("Scan your environment to enable AR features like marker placement and grid generation.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                showScanView = true
            }) {
                HStack {
                    Image(systemName: "plus.viewfinder")
                        .font(.system(size: 18))
                    
                    Text("Scan New Patch")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.green)
                .cornerRadius(10)
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
        }
        .padding(.top, 60)
    }
    
    // MARK: - Patches Section

    private var patchesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Image(systemName: "square.3.layers.3d")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                
                Text("Map Patches")
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
                
                Text("\(worldMapStore.patches.count)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            
            // Patches list
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(worldMapStore.patches.sorted(by: { $0.createdDate > $1.createdDate })) { patch in
                        PatchListItem(patch: patch)
                    }
                }
            }
            .frame(maxHeight: 300)
            
            // Actions
            VStack(spacing: 12) {
                // Scan new patch
                Button(action: {
                    showScanView = true
                }) {
                    HStack {
                        Image(systemName: "plus.viewfinder")
                            .font(.system(size: 18))
                        
                        Text("Scan New Patch")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
            }
        }
    }

    // MARK: - Legacy World Map Section

    private var legacyWorldMapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Legacy World Map")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.secondary)
            
            statusCard
            
            Text("This location uses the old single world map format. New scans will create patches.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            
            // Actions
            actionsSection
        }
    }
    
    // MARK: - Utilities
    
    private func formatDate(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else {
            return "Unknown"
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .short
        return displayFormatter.string(from: date)
    }
}

// MARK: - Patch List Item

private struct PatchListItem: View {
    let patch: WorldMapPatch
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(patch.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("v\(patch.version)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue)
                    .cornerRadius(6)
            }
            
            HStack(spacing: 12) {
                Label("\(String(format: "%.1f", patch.fileSize_mb)) MB", systemImage: "doc.fill")
                Label("\(patch.featurePointCount)", systemImage: "dot.scope")
                Spacer()
                Text(formatDate(patch.createdDate))
            }
            .font(.system(size: 11))
            .foregroundColor(.secondary)
        }
        .padding(10)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}