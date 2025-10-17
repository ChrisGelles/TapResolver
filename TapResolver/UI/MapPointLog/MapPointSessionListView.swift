//
//  MapPointSessionListView.swift
//  TapResolver
//
//  Created on 10/12/2025
//
//  Role: Displays all scan sessions for a specific map point
//

import SwiftUI

struct MapPointSessionListView: View {
    @EnvironmentObject private var mapPointStore: MapPointStore
    
    let pointID: String
    let onDismiss: () -> Void
    
    @State private var sessions: [SessionInfo] = []
    @State private var lockedSessions: Set<String> = []
    @State private var sessionToDelete: String?
    @State private var showDeleteConfirmation = false
    @State private var isLoading = true
    
    struct SessionInfo: Identifiable {
        let id: String // sessionID
        let timestamp: Date
        let duration: Double
        let beaconCount: Int
        let facing: Double?
    }
    
    private let sessionColors: [Color] = [
        Color(hue: 0.55, saturation: 0.6, brightness: 0.7),
        Color(hue: 0.33, saturation: 0.6, brightness: 0.7),
        Color(hue: 0.15, saturation: 0.6, brightness: 0.7),
        Color(hue: 0.75, saturation: 0.6, brightness: 0.7),
        Color(hue: 0.50, saturation: 0.6, brightness: 0.7),
        Color(hue: 0.08, saturation: 0.6, brightness: 0.7),
    ]
    
    private var pointName: String {
        if let point = mapPointStore.points.first(where: { $0.id.uuidString == pointID }) {
            return String(format: "%.2f, %.2f", point.mapPoint.x, point.mapPoint.y)
        }
        return "Unknown"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Point (\(pointName))px")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Text("Sessions")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.black.opacity(0.9))
            
            Divider()
                .background(Color.white.opacity(0.3))
            
            // Sessions list
            if isLoading {
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            loadLockedSessions()
            Task {
                await loadSessions()
            }
        }
    }
    
    // MARK: - Actions
    
    private func loadSessions() async {
        // Get sessions directly from MapPointStore
        guard let point = mapPointStore.points.first(where: { $0.id.uuidString == pointID }) else {
            sessions = []
            isLoading = false
            return
        }
        
        var loadedSessions: [SessionInfo] = []
        
        for session in point.sessions {
            let timestamp = ISO8601DateFormatter().date(from: session.timingStartISO) ?? Date()
            
            let info = SessionInfo(
                id: session.sessionID,
                timestamp: timestamp,
                duration: session.duration_s,
                beaconCount: session.beacons.count,
                facing: session.facing_deg
            )
            
            loadedSessions.append(info)
        }
        
        sessions = loadedSessions.sorted { $0.timestamp > $1.timestamp }
        isLoading = false
    }
    
    private func toggleLock(for sessionID: String) {
        if lockedSessions.contains(sessionID) {
            lockedSessions.remove(sessionID)
        } else {
            lockedSessions.insert(sessionID)
        }
        saveLockedSessions()
    }
    
    private func deleteSession(_ sessionID: String) {
        guard let pointUUID = UUID(uuidString: pointID) else { return }
        
        mapPointStore.removeSession(pointID: pointUUID, sessionID: sessionID)
        
        Task {
            await loadSessions()
            
            if sessions.isEmpty {
                onDismiss()
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
    let session: MapPointSessionListView.SessionInfo
    let color: Color
    let isLocked: Bool
    let onToggleLock: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
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
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(Int(session.duration))s • \(session.beaconCount) beacons")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Button(action: onToggleLock) {
                Image(systemName: isLocked ? "lock.fill" : "lock.open")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(isLocked ? .yellow : .white.opacity(0.6))
                    .frame(width: 24, height: 24)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            
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
        
        let facingStr: String
        if let facing = session.facing {
            facingStr = String(format: "%.0f°", facing)
        } else {
            facingStr = "---°"
        }
        
        return "\(dateTimeStr)-\(facingStr)"
    }
}
