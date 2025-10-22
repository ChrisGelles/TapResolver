//
//  MapPointLogView.swift
//  TapResolver
//
//  Created on 10/12/2025
//
//  Role: Bottom drawer displaying map points in a grid with quality color coding
//  - Draggable from 0% to 50% of screen height
//  - Shows 4-column grid when session list closed, 3-column when open
//  - Dots are color-coded by scan quality
//  - Opens to 40% with bounce animation
//

import SwiftUI
import UniformTypeIdentifiers

struct MapPointLogView: View {
    @EnvironmentObject private var hudPanels: HUDPanelsState
    @EnvironmentObject private var mapPointStore: MapPointStore
    
    // Current drawer height as fraction of screen (0.0 to 0.5)
    @State private var drawerHeight: CGFloat = 0
    // Drawer height at the moment drag began (anchors gesture calculation)
    @State private var dragStartHeight: CGFloat = 0
    
    @State private var selectedPointID: String? = nil
    @State private var showExportPicker = false
    @State private var exportData: Data?
    
    private let minHeight: CGFloat = 0
    private let maxHeight: CGFloat = 0.5
    private let defaultHeight: CGFloat = 0.4
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Draggable handle
                drawerHandle
                    .frame(height: 44)
                    .contentShape(Rectangle())
                    .gesture(dragGesture(geometry: geometry))
                
                // Content area
                ZStack(alignment: .leading) {
                    // Map point grid
                    mapPointGrid(geometry: geometry)
                    
                    // Session list panel (slides in from left)
                    if let pointID = selectedPointID {
                        sessionListPanel(pointID: pointID, geometry: geometry)
                            .transition(.move(edge: .leading))
                    }
                }
            }
            .frame(height: geometry.size.height * maxHeight)  // Always max height
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.9))
            .cornerRadius(16, corners: [.topLeft, .topRight])
            .shadow(color: .black.opacity(0.2), radius: 10, y: -5)
            .offset(y: calculateDrawerOffset(geometry: geometry))  // Use offset instead of changing height
            .frame(maxHeight: .infinity, alignment: .bottom)  // Align to bottom
            .ignoresSafeArea(edges: .bottom)
        }
        .fileExporter(
            isPresented: $showExportPicker,
            document: exportData.map { JSONDocument(data: $0) },
            contentType: .json,
            defaultFilename: generateExportFileName()
        ) { result in
            if case .success(let url) = result {
                print("✅ Export saved to: \(url)")
            }
        }
        .onAppear {
            print("🖼️ MapPointLogView using MapPointStore ID: \(String(mapPointStore.instanceID.prefix(8)))...")
            
            // Animate drawer opening with bounce
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                drawerHeight = defaultHeight
            }
        }
    }
    
    // MARK: - Drawer Handle
    
    private var drawerHandle: some View {
        VStack(spacing: 12) {
            Capsule()
                .fill(Color.white.opacity(0.5))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
            
            HStack {
                Text("Map Point Log")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Storage scan button
                Button(action: {
                    StorageDiagnostics.printAllMapPointStorageLocations()
                    StorageDiagnostics.scanAllUserDefaultsKeys()
                }) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.orange)
                }
                
                // Diagnostic button
                Button(action: {
                    mapPointStore.printUserDefaultsDiagnostic()
                }) {
                    Image(systemName: "stethoscope")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.yellow)
                }
                
                // RECOVERY BUTTON (temporary - delete after successful recovery)
                Button(action: {
                    mapPointStore.recoverFromSessionFiles()
                }) {
                    Image(systemName: "bandage.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.green)
                }
                
                // SESSION RECONNECTION BUTTON (temporary - delete after successful recovery)
                Button(action: {
                    mapPointStore.reconnectSessionFiles()
                }) {
                    Image(systemName: "link.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                }
                
                // Export button
                Button(action: {
                    Task { await exportAllSessions() }
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                // Close button
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        drawerHeight = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        hudPanels.toggleMapPointLog()
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
    }
    
    private func dragGesture(geometry: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 6, coordinateSpace: .global)
            .onChanged { value in
                // Cache drawer height at drag start (only once per gesture)
                if dragStartHeight == 0 {
                    dragStartHeight = drawerHeight
                }
                
                // Calculate delta from drag start and apply to anchored start height
                let delta = -value.translation.height / geometry.size.height
                drawerHeight = min(max(dragStartHeight + delta, minHeight), maxHeight)
            }
            .onEnded { value in
                let delta = -value.translation.height / geometry.size.height
                let finalHeight = dragStartHeight + delta
                let clampedHeight = min(max(finalHeight, minHeight), maxHeight)
                let velocity = -value.predictedEndTranslation.height / geometry.size.height
                
                // Snap to detents based on velocity
                if abs(velocity) < 0.5 {
                    // Snap to nearest detent if moving slowly
                    if clampedHeight < 0.15 {
                        drawerHeight = 0
                    } else if clampedHeight < 0.3 {
                        drawerHeight = 0.25
                    } else if clampedHeight > 0.45 {
                        drawerHeight = 0.5
                    } else {
                        drawerHeight = 0.4
                    }
                } else {
                    // Fast swipe - use calculated position
                    drawerHeight = clampedHeight
                }
                
                // Reset drag start anchor for next gesture
                dragStartHeight = 0
            }
    }
    
    private func calculateDrawerOffset(geometry: GeometryProxy) -> CGFloat {
        // Clamp current drawer height
        let clampedHeight = min(max(drawerHeight, minHeight), maxHeight)
        
        // Convert visible height to Y offset
        return (maxHeight - clampedHeight) * geometry.size.height
    }
    
    private func calculateDrawerHeight(geometry: GeometryProxy) -> CGFloat {
        // Clamp current drawer height
        let clampedHeight = min(max(drawerHeight, minHeight), maxHeight)
        return geometry.size.height * clampedHeight
    }
    
    // MARK: - Map Point Grid
    
    private func mapPointGrid(geometry: GeometryProxy) -> some View {
        let isSessionListOpen = selectedPointID != nil
        let columnCount = isSessionListOpen ? 3 : 4
        let gridWidth = isSessionListOpen ? geometry.size.width * 0.5 : geometry.size.width
        
        let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: columnCount)
        
        return Group {
            if mapPointStore.points.isEmpty {
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
                
            } else {
                // Grid of map points
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(mapPointStore.points) { point in
                            MapPointDotView(
                                point: point,
                                sessionCount: point.sessions.count,
                                quality: mapPointStore.scanQuality(for: point.id),
                                onTap: {
                                    withAnimation(.easeInOut(duration: 0.35)) {
                                        selectedPointID = point.id.uuidString
                                    }
                                }
                            )
                        }
                    }
                    .padding(16)
                }
                .frame(width: gridWidth, alignment: isSessionListOpen ? .trailing : .center)
                .animation(.easeInOut(duration: 0.35), value: isSessionListOpen)
            }
        }
    }
    
    // MARK: - Session List Panel
    
    private func sessionListPanel(pointID: String, geometry: GeometryProxy) -> some View {
        let drawerActualHeight = calculateDrawerHeight(geometry: geometry)
        let panelHeight = min(drawerActualHeight * 1.1, geometry.size.height * 0.5)
        let panelWidth = geometry.size.width * 0.5
        
        return MapPointSessionListView(pointID: pointID, onDismiss: {
            withAnimation(.easeInOut(duration: 0.35)) {
                selectedPointID = nil
            }
        })
        .frame(width: panelWidth)
        .frame(height: panelHeight)
        .background(Color.black.opacity(0.9))
        .shadow(color: .black.opacity(0.15), radius: 8, x: 2, y: 0)
        .environmentObject(mapPointStore)
    }
    
    // MARK: - Export Logic
    
    private func exportAllSessions() async {
        do {
            let data = try await mapPointStore.exportMasterJSON()
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
    let quality: MapPointStore.ScanQuality
    let onTap: () -> Void
    
    // Reduced dot size by 40%: 40pt → 24pt
    private let dotSize: CGFloat = 24
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    // Main dot with quality color
                    Circle()
                        .fill(quality.color)
                        .frame(width: dotSize, height: dotSize)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white.opacity(0.3), lineWidth: 1.5)
                        )
                    
                    // Session count badge (same size as before: 20pt)
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

// MARK: - JSON Document for Export

struct JSONDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    
    let data: Data
    
    init(data: Data) {
        self.data = data
    }
    
    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Identifiable String Extension

extension String: Identifiable {
    public var id: String { self }
}
