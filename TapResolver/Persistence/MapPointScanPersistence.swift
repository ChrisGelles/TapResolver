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

            // Folder: Documents/scans
            let fm = FileManager.default
            let docs = try fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let scansDir = docs.appendingPathComponent("scans", isDirectory: true)
            if !fm.fileExists(atPath: scansDir.path) {
                try fm.createDirectory(at: scansDir, withIntermediateDirectories: true)
            }

            // Filename: scanID.json (fallback to timestamp if empty)
            let base = record.scanID.isEmpty ? ISO8601DateFormatter().string(from: Date()) : record.scanID
            let url = scansDir.appendingPathComponent("\(base).json")

            let data = try enc.encode(record)
            try data.write(to: url, options: .atomic)
            print("💾 Saved scan record to \(url.path)")
            
            // New per-location path
            _ctx.ensureLocationDirs()
            let newBase = record.scanID.isEmpty ? ISO8601DateFormatter().string(from: Date()) : record.scanID
            let newURL = _ctx.scansNewDir.appendingPathComponent("scan_record_\(newBase).json")
            try data.write(to: newURL, options: .atomic)
            print("💾 Also saved scan record to \(newURL.path)")
        } catch {
            print("❌ Failed to save scan record: \(error)")
        }
    }
}
