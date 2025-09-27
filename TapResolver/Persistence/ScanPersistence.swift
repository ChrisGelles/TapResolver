//
//  ScanPersistence.swift
//  TapResolver
//
//  Created by restructuring on 9/26/25.
//

import Foundation

enum ScanPersistence {
    static func saveSession(_ session: BeaconLogSession) {
        do {
            let enc = JSONEncoder()
            enc.outputFormatting = [.prettyPrinted, .sortedKeys]
            enc.dateEncodingStrategy = .iso8601

            // Folder: Documents/scans
            let fm = FileManager.default
            let docs = try fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let scansDir = docs.appendingPathComponent("scans", isDirectory: true)
            if !fm.fileExists(atPath: scansDir.path) {
                try fm.createDirectory(at: scansDir, withIntermediateDirectories: true)
            }

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
