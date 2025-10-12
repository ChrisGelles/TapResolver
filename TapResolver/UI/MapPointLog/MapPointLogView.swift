//
//  MapPointLogView.swift
//  TapResolver
//
//  Created on 10/12/2025
//
//  Role: Main overlay for viewing and managing map point scan sessions
//  - Displays 3-column grid of map points with recorded data
//  - Shows session count badges
//  - Provides export functionality
//

import SwiftUI

struct MapPointLogView: View {
    @EnvironmentObject private var mapPointLogManager: MapPointLogManager
    @EnvironmentObject private var hudPanels: HUDPanelsState
    
    @State private var selectedPointID: String?
    @State private var showExportPicker = false
    @State private var exportData: Data?
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Map Point Log")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Close button
                Button(action: {
                    hudPanels.toggleMapPointLog()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.white.opacity(0.2)))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.black.opacity(0.9))
            
            Divider()
                .background(Color.white.opacity(0.3))
            
            // Content area
            if mapPointLogManager.isLoading {
                // Loading state
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    Text("Loading scan data...")
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.85))
                
            } else if mapPointLogManager.mapPoints.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.4))
                    Text("No Scan Data")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Record scans at map points to see them here")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.85))
                
            } else {
                // Grid of map points
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(mapPointLogManager.mapPoints) { entry in
                            MapPointDotView(
                                entry: entry,
                                onTap: {
                                    selectedPointID = entry.id
                                }
                            )
                        }
                    }
                    .padding(20)
                }
                .background(Color.black.opacity(0.85))
            }
            
            // Bottom toolbar
            if !mapPointLogManager.mapPoints.isEmpty {
                VStack(spacing: 0) {
                    Divider()
                        .background(Color.white.opacity(0.3))
                    
                    Button(action: {
                        Task {
                            await exportAllSessions()
                        }
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export All Sessions")
                                .fontWeight(.semibold)
                        }
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue.opacity(0.8))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
                .background(Color.black.opacity(0.9))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: UIScreen.main.bounds.height * 0.5) // Lower half of screen
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .shadow(radius: 10)
        .sheet(isPresented: $showExportPicker) {
            if let data = exportData {
                SaveToFilesPicker(
                    data: data,
                    suggestedFileName: generateExportFileName(),
                    onCompleted: { success in
                        if success {
                            print("✅ Master export saved successfully")
                        }
                        exportData = nil
                    }
                )
            }
        }
        .sheet(item: $selectedPointID) { pointID in
            // Drill-down view will be added in next step
            Text("Sessions for \(pointID)")
                .foregroundColor(.white)
        }
        .onAppear {
            Task {
                await mapPointLogManager.loadAll(context: PersistenceContext.shared)
            }
        }
    }
    
    // MARK: - Export Logic
    
    private func exportAllSessions() async {
        do {
            let data = try await mapPointLogManager.exportMasterJSON()
            exportData = data
            showExportPicker = true
        } catch {
            print("❌ Export failed: \(error)")
        }
    }
    
    private func generateExportFileName() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withYear, .withMonth, .withDay, .withTime, .withColonSeparatorInTime]
        let timestamp = formatter.string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let locationID = PersistenceContext.shared.locationID
        return "TapResolver_MasterExport_\(locationID)_\(timestamp).json"
    }
}

// MARK: - Map Point Dot View

private struct MapPointDotView: View {
    let entry: MapPointLogManager.MapPointLogEntry
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    // Main dot
                    Circle()
                        .fill(entry.color)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white.opacity(0.3), lineWidth: 2)
                        )
                    
                    // Session count badge
                    if !entry.sessions.isEmpty {
                        Text("\(entry.sessions.count)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(Color.red))
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.white, lineWidth: 2)
                            )
                            .offset(x: 8, y: -8)
                    }
                }
                
                // Point ID (shortened)
                Text(shortenedPointID(entry.id))
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }
    
    private func shortenedPointID(_ id: String) -> String {
        // Show first 8 characters of UUID
        String(id.prefix(8))
    }
}

// MARK: - Helper Extensions

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Identifiable String Extension

extension String: Identifiable {
    public var id: String { self }
}

