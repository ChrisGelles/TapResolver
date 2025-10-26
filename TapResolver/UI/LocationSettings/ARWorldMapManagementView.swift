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
            
            if worldMapStore.metadata.exists {
                // Status card
                statusCard
                
                // Scan history
                scanHistorySection
                
                // Actions
                actionsSection
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
                    Image(systemName: "arrow.triangle.branch")
                        .font(.system(size: 18))
                    
                    Text("Extend AR Environment")
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
                    Image(systemName: "camera.fill")
                        .font(.system(size: 18))
                    
                    Text("Scan AR Environment")
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