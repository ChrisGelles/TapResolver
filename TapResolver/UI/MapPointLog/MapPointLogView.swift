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
    @EnvironmentObject private var mapPointStore: MapPointStore
    
    @State private var selectedPointID: String?
    @State private var showExportPicker = false
    @State private var exportData: Data?
    
    private let columns = [
        GridItem(.flexible()),
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
                
            } else if mapPointStore.points.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.4))
                    Text("No Map Points")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Add map points to see them here")
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
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(mapPointStore.points) { point in
                            MapPointDotView(
                                point: point,
                                sessionCount: mapPointLogManager.mapPoints.first(where: { $0.id == point.id.uuidString })?.sessions.count ?? 0,
                                onTap: {
                                    selectedPointID = point.id.uuidString
                                }
                            )
                        }
                    }
                    .padding(20)
                }
                .background(Color.black.opacity(0.85))
            }
            
            // Bottom toolbar
            if mapPointLogManager.mapPoints.reduce(0, { $0 + $1.sessions.count }) > 0 {
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
            MapPointSessionListView(pointID: pointID)
                .environmentObject(mapPointLogManager)
                .environmentObject(mapPointStore)
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
    let point: MapPointStore.MapPoint
    let sessionCount: Int
    let onTap: () -> Void
    
    private let mapPointBlue = Color(hex: 0x10fff1)
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    // Main dot
                    Circle()
                        .fill(sessionCount > 0 ? mapPointBlue : Color.gray.opacity(0.4))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white.opacity(0.3), lineWidth: 1.5)
                        )
                    
                    // Session count badge (only if > 0)
                    if sessionCount > 0 {
                        Text("\(sessionCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 20, height: 20)
                            .background(Circle().fill(Color.red))
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.white, lineWidth: 1.5)
                            )
                            .offset(x: 6, y: -6)
                    }
                }
                
                // Point ID (shortened)
                Text(shortenedPointID(point.id.uuidString))
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(sessionCount > 0 ? 0.8 : 0.4))
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

