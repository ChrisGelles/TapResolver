//
//  ScanPersistence.swift
//  TapResolver
//
//  Created by restructuring on 9/26/25.
//

import Foundation

enum ScanPersistence {
    private static let _ctx = PersistenceContext.shared
    static func saveSession(_ session: BeaconLogSession) {
        do {
            let enc = JSONEncoder()
            enc.outputFormatting = [.prettyPrinted, .sortedKeys]
            enc.dateEncodingStrategy = .iso8601

            // Use location-scoped directory
            _ctx.ensureLocationDirs()
            let scansDir = _ctx.scansNewDir

            // Filename: sessionID.json (fallback to timestamp if empty)
            let base = session.sessionID.isEmpty ? ISO8601DateFormatter().string(from: session.startTime) : session.sessionID
            let url = scansDir.appendingPathComponent("\(base).json")

            let data = try enc.encode(session)
            try data.write(to: url, options: .atomic)
            print("💾 Saved scan session to \(url.path)")
        } catch {
            print("❌ Failed to save scan session: \(error)")
        }
    }
}
