//
//  MapPointSessionListView.swift
//  TapResolver
//
//  Created on 10/12/2025
//
//  Role: Displays all scan sessions for a specific map point
//  - Styled like BeaconListItem
//  - Sessions show: YYYYMMDD-HHMM-facing°
//  - Lock/unlock to prevent deletion
//  - Delete with confirmation
//

import SwiftUI

struct MapPointSessionListView: View {
    @EnvironmentObject private var mapPointLogManager: MapPointLogManager
    @EnvironmentObject private var mapPointStore: MapPointStore
    @Environment(\.dismiss) private var dismiss
    
    let pointID: String
    
    @State private var lockedSessions: Set<String> = []
    @State private var sessionToDelete: String?
    @State private var showDeleteConfirmation = false
    @State private var isLoadingSessions = true
    
    // Color palette for session items (cycles through)
    private let sessionColors: [Color] = [
        Color(hue: 0.55, saturation: 0.6, brightness: 0.7),  // Blue
        Color(hue: 0.33, saturation: 0.6, brightness: 0.7),  // Green
        Color(hue: 0.15, saturation: 0.6, brightness: 0.7),  // Orange
        Color(hue: 0.75, saturation: 0.6, brightness: 0.7),  // Purple
        Color(hue: 0.50, saturation: 0.6, brightness: 0.7),  // Cyan
        Color(hue: 0.08, saturation: 0.6, brightness: 0.7),  // Yellow-Orange
    ]
    
    private var mapPointEntry: MapPointLogManager.MapPointLogEntry? {
        mapPointLogManager.mapPoints.first { $0.id == pointID }
    }
    
    private var sessions: [MapPointLogManager.SessionMetadata] {
        mapPointEntry?.sessions ?? []
    }
    
    private var pointName: String {
        // Try to get from mapPointLogManager first (has coordinates)
        if let entry = mapPointEntry {
            return String(format: "%.2f, %.2f", entry.coordinates.x, entry.coordinates.y)
        }
        
        // Fallback: get from mapPointStore
        if let point = mapPointStore.points.first(where: { $0.id.uuidString == pointID }) {
            return String(format: "%.2f, %.2f", point.mapPoint.x, point.mapPoint.y)
        }
        
        return "Unknown"
    }
    
    var body: some View {
        let _ = print("🔍 MapPointSessionListView DEBUG:")
        let _ = print("   pointID: \(pointID)")
        let _ = print("   mapPointLogManager.mapPoints.count: \(mapPointLogManager.mapPoints.count)")
        let _ = print("   Found entry: \(mapPointEntry != nil)")
        let _ = print("   Sessions count: \(sessions.count)")
        
        return VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Text("Point (\(pointName))m")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { dismiss() }) {
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
            
            // Sessions list
            if isLoadingSessions {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    Text("Loading sessions...")
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.85))
            } else if sessions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.4))
                    Text("No Sessions")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    Text("No scan data for this map point")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.85))
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(Array(sessions.enumerated()), id: \.element.id) { index, session in
                            SessionListItem(
                                session: session,
                                color: sessionColors[index % sessionColors.count],
                                isLocked: lockedSessions.contains(session.id),
                                onToggleLock: {
                                    toggleLock(for: session.id)
                                },
                                onDelete: {
                                    sessionToDelete = session.id
                                    showDeleteConfirmation = true
                                }
                            )
                        }
                    }
                    .padding(16)
                }
                .background(Color.black.opacity(0.85))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: UIScreen.main.bounds.height * 0.5)
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .shadow(radius: 10)
        .alert("Delete Session?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                sessionToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let id = sessionToDelete {
                    deleteSession(id)
                }
                sessionToDelete = nil
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .onAppear {
            print("🔍 Session List Opened for pointID: \(pointID)")
            print("   Current mapPointLogManager.mapPoints.count: \(mapPointLogManager.mapPoints.count)")
            
            loadLockedSessions()
            
            // Force reload scan data to ensure we have latest
            Task {
                print("   ⏳ Reloading all scan data...")
                await mapPointLogManager.loadAll(context: PersistenceContext.shared)
                
                print("   ✅ Reload complete. mapPoints.count: \(mapPointLogManager.mapPoints.count)")
                if let entry = mapPointEntry {
                    print("   ✅ Found entry for pointID with \(entry.sessions.count) sessions")
                } else {
                    print("   ⚠️ No entry found for pointID: \(pointID)")
                }
                
                isLoadingSessions = false
            }
        }
    }
    
    // MARK: - Actions
    
    private func toggleLock(for sessionID: String) {
        if lockedSessions.contains(sessionID) {
            lockedSessions.remove(sessionID)
        } else {
            lockedSessions.insert(sessionID)
        }
        saveLockedSessions()
    }
    
    private func deleteSession(_ sessionID: String) {
        Task {
            do {
                try await mapPointLogManager.deleteSession(pointID: pointID, sessionID: sessionID)
                
                // If no sessions left, dismiss view
                if sessions.isEmpty {
                    dismiss()
                }
            } catch {
                print("❌ Failed to delete session: \(error)")
            }
        }
    }
    
    // MARK: - Persistence
    
    private func loadLockedSessions() {
        let key = "MapPointLog.LockedSessions.\(pointID)"
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode(Set<String>.self, from: data) {
            lockedSessions = saved
        }
    }
    
    private func saveLockedSessions() {
        let key = "MapPointLog.LockedSessions.\(pointID)"
        if let data = try? JSONEncoder().encode(lockedSessions) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

// MARK: - Session List Item

private struct SessionListItem: View {
    let session: MapPointLogManager.SessionMetadata
    let color: Color
    let isLocked: Bool
    let onToggleLock: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // Session name in colored rounded rectangle (styled like BeaconListItem)
            Text(formatSessionName())
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(color.opacity(0.8))
                )
            
            Spacer(minLength: 4)
            
            // Session info (duration, beacon count)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(Int(session.duration))s • \(session.beaconCount) beacons")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            // Lock toggle
            Button(action: onToggleLock) {
                Image(systemName: isLocked ? "lock.fill" : "lock.open")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(isLocked ? .yellow : .white.opacity(0.6))
                    .frame(width: 24, height: 24)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            
            // Delete button (only if unlocked)
            if !isLocked {
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.red)
                        .frame(width: 24, height: 24)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
    }
    
    private func formatSessionName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmm"
        let dateTimeStr = formatter.string(from: session.timestamp)
        
        // Format facing with degree symbol
        let facingStr: String
        if let facing = session.facing {
            facingStr = String(format: "%.0f°", facing)
        } else {
            facingStr = "---°"
        }
        
        return "\(dateTimeStr)-\(facingStr)"
    }
}

