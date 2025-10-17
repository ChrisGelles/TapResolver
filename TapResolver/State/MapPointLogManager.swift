//
//  MapPointLogManager.swift
//  TapResolver
//
//  Created on 10/12/2025
//
//  Role: Manages lightweight session index (pointID -> [sessionID])
//  - Scans filesystem to build index
//  - Reloads automatically when location changes
//  - Provides session counts and lists for UI
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class MapPointLogManager: ObservableObject {
    
    // NOTE: This class is now ONLY used for JSON export functionality.
    // All session data is read directly from MapPointStore by the UI.
    // The sessionIndex is obsolete and should be removed in a future refactor.
    
    // MARK: - Published State
    
    /// Lightweight index: pointID -> [sessionID]
    @Published private(set) var sessionIndex: [String: [String]] = [:]
    
    // MARK: - Dependencies
    
    private let ctx = PersistenceContext.shared
    private var bag = Set<AnyCancellable>()
    private weak var mapPointStore: MapPointStore?
    
    // DIAGNOSTIC: Track instance
    private let instanceID = UUID().uuidString
    
    // MARK: - Initialization
    
    init() {
        print("🧠 MapPointLogManager init — ID: \(String(instanceID.prefix(8)))...")
    }
    
    /// Wire up dependency to MapPointStore (call from AppBootstrap)
    func setMapPointStore(_ store: MapPointStore) {
        print("📎 LogManager \(String(instanceID.prefix(8)))... wired to MapPointStore \(String(store.instanceID.prefix(8)))...")
        self.mapPointStore = store
        
        // Subscribe to MapPointStore updates (point/session changes)
        store.objectWillChange
            .sink { [weak self] _ in
                self?.refreshSessionIndex()
            }
            .store(in: &bag)
        
        // Subscribe to reload notifications (e.g., location change)
        NotificationCenter.default.publisher(for: .mapPointsDidReload)
            .sink { [weak self] _ in
                self?.refreshSessionIndex()
            }
            .store(in: &bag)
        
        // Initial sync
        refreshSessionIndex()
    }
    
    // MARK: - Public API
    
    /// Get session count for a specific map point
    func sessionCount(for pointID: String) -> Int {
        return sessionIndex[pointID]?.count ?? 0
    }
    
    /// Get session IDs for a specific map point
    func sessions(for pointID: String) -> [String] {
        return sessionIndex[pointID] ?? []
    }
    
    /// Refresh session index from MapPointStore
    /// Since data is in UserDefaults, it's already loaded - just read it
    func refreshSessionIndex() {
        guard let store = mapPointStore else {
            sessionIndex = [:]
            return
        }
        
        print("🪄 [LogManager] Refreshing session index — \(store.points.count) points in store")
        
        var index: [String: [String]] = [:]
        
        for point in store.points {
            let sessionIDs = point.sessions.map { $0.sessionID }
            if !sessionIDs.isEmpty {
                index[point.id.uuidString] = sessionIDs
            }
        }
        
        sessionIndex = index
    }
    
    /// Delete a specific scan session
    func deleteSession(pointID: String, sessionID: String) {
        guard let store = mapPointStore,
              let pointUUID = UUID(uuidString: pointID) else {
            return
        }
        
        store.removeSession(pointID: pointUUID, sessionID: sessionID)
        refreshSessionIndex()
    }
    /// Load full scan data for a specific session
    func loadSessionData(sessionID: String) async -> MapPointStore.ScanSession? {
        guard let store = mapPointStore else { return nil }
        
        // Find the session in any map point
        for point in store.points {
            if let session = point.sessions.first(where: { $0.sessionID == sessionID }) {
                return session
            }
        }
        
        return nil
    }
    
    /// Generate master export JSON
    func exportMasterJSON() async throws -> Data {
        print("\n🔍 EXPORT DEBUG - MapPointLogManager")
        print("   Manager instance: \(String(instanceID.prefix(8)))...")
        print("   Store reference exists: \(mapPointStore != nil)")
        
        guard let store = mapPointStore else {
            throw NSError(domain: "MapPointLogManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "MapPointStore not available"])
        }
        
        print("   Store points array: \(store.points.count) points")
        print("   First 3 point IDs:")
        for (i, point) in store.points.prefix(3).enumerated() {
            print("     \(i+1). \(String(point.id.uuidString.prefix(8)))... - \(point.sessions.count) sessions")
        }
        
        // ADD LOGGING
        print("\n" + String(repeating: "=", count: 80))
        print("📤 EXPORT MASTER JSON - START")
        print(String(repeating: "=", count: 80))
        print("Location: \(ctx.locationID)")
        print("Points in store: \(store.points.count)")
        print("Total sessions: \(store.points.reduce(0) { $0 + $1.sessions.count })")
        
        var mapPointsData: [[String: Any]] = []
        
        for (index, point) in store.points.enumerated() {
            // ADD LOGGING
            let shortID = String(point.id.uuidString.prefix(8))
            print("  Processing point \(index + 1)/\(store.points.count): \(shortID)... - \(point.sessions.count) sessions")
            // Convert sessions to JSON-compatible dictionaries
            let sessionsData = try point.sessions.map { session -> [String: Any] in
                let jsonData = try JSONEncoder().encode(session)
                return try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
            }
            
            mapPointsData.append([
                "pointID": point.id.uuidString,
                "coordinates": [Double(point.mapPoint.x), Double(point.mapPoint.y)],
                "sessions": sessionsData
            ])
        }
        
        let masterExport: [String: Any] = [
            "exportDate": ISO8601DateFormatter().string(from: Date()),
            "locationID": ctx.locationID,
            "metadata": [
                "appVersion": appVersion(),
                "totalMapPoints": store.points.count,
                "totalSessions": store.totalSessionCount()
            ],
            "mapPoints": mapPointsData
        ]
        
        // ADD LOGGING
        print("✅ Export complete: \(mapPointsData.count) points exported")
        print(String(repeating: "=", count: 80) + "\n")
        
        return try JSONSerialization.data(withJSONObject: masterExport, options: [.prettyPrinted, .sortedKeys])
    }
    
    // MARK: - Private Helpers
    
    private func appVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }
    
}

// MARK: - Scan Quality Evaluation

extension MapPointLogManager {
    
    /// Quality categories for map point scans
    enum ScanQuality: Comparable {
        case none, poor, fair, good
        
        var color: Color {
            switch self {
            case .none: return Color.gray.opacity(0.4)
            case .poor: return .red
            case .fair: return .orange
            case .good: return .green
            }
        }
        
        var description: String {
            switch self {
            case .none: return "No data"
            case .poor: return "Poor - needs attention"
            case .fair: return "Fair"
            case .good: return "Good"
            }
        }
    }
    
    /// Calculate overall scan quality for a map point based on worst session
    func scanQuality(for pointID: String) -> ScanQuality {
        guard let store = mapPointStore,
              let point = store.points.first(where: { $0.id.uuidString == pointID }) else {
            return .none
        }
        
        guard !point.sessions.isEmpty else {
            return .none
        }
        
        // Evaluate each session and take the WORST quality (highlights problems)
        let qualities = point.sessions.map { session in
            evaluateSessionQuality(session)
        }
        
        return qualities.min() ?? .none
    }
    
    /// Evaluate quality of a single session based on beacon RSSI values
    private func evaluateSessionQuality(_ session: MapPointStore.ScanSession) -> ScanQuality {
        // Count beacons with good RSSI (> -80 dBm)
        let goodBeacons = session.beacons.filter { beacon in
            beacon.stats.median_dbm > -80  // Good signal threshold
        }.count
        
        // Categorize based on good beacon count
        // 3+ good beacons = acceptable scan
        switch goodBeacons {
        case 0:
            return .none
        case 1...2:
            return .poor
        case 3...4:
            return .fair
        default:
            return .good  // 5+ good beacons
        }
    }
}
