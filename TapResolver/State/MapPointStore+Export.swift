//
//  MapPointStore+Export.swift
//  TapResolver
//
//  Export functionality for MapPointStore
//

import Foundation

extension MapPointStore {
    
    /// Generate master export JSON from all map points and their sessions
    func exportMasterJSON() async throws -> Data {
        let ctx = PersistenceContext.shared
        
        print("\n" + String(repeating: "=", count: 80))
        print("📤 EXPORT MASTER JSON - START")
        print(String(repeating: "=", count: 80))
        print("Location: \(ctx.locationID)")
        print("Points in store: \(points.count)")
        print("Total sessions: \(totalSessionCount())")
        
        var mapPointsData: [[String: Any]] = []
        
        for (index, point) in points.enumerated() {
            let shortID = String(point.id.uuidString.prefix(8))
            print("  Processing point \(index + 1)/\(points.count): \(shortID)... - \(point.sessions.count) sessions")
            
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
                "totalMapPoints": points.count,
                "totalSessions": totalSessionCount()
            ],
            "mapPoints": mapPointsData
        ]
        
        print("✅ Export complete: \(mapPointsData.count) points exported")
        print(String(repeating: "=", count: 80) + "\n")
        
        return try JSONSerialization.data(withJSONObject: masterExport, options: [.prettyPrinted, .sortedKeys])
    }
    
    private func appVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }
}

