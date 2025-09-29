//
//  MapPointScanPersistence.swift
//  TapResolver
//
//  Created by restructuring on 9/26/25.
//

import Foundation

enum MapPointScanPersistence {
    private static let _ctx = PersistenceContext.shared
    static func saveRecord(_ record: MapPointScanUtility.ScanRecord) {
        do {
            let enc = JSONEncoder()
            enc.outputFormatting = [.prettyPrinted, .sortedKeys]
            enc.dateEncodingStrategy = .iso8601

            // Use location-scoped directory
            _ctx.ensureLocationDirs()
            let scansDir = _ctx.scansNewDir

            // Filename: scanID.json (fallback to timestamp if empty)
            let base = record.scanID.isEmpty ? ISO8601DateFormatter().string(from: Date()) : record.scanID
            let url = scansDir.appendingPathComponent("scan_record_\(base).json")

            let data = try enc.encode(record)
            try data.write(to: url, options: .atomic)
            print("💾 Saved scan record to \(url.path)")
        } catch {
            print("❌ Failed to save scan record: \(error)")
        }
    }
}
