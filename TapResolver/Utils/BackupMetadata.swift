//
//  BackupMetadata.swift
//  TapResolver
//
//  Metadata structure for .tapmap backup files
//

import Foundation

/// Metadata for .tapmap backup files
struct BackupMetadata: Codable {
    let format: String              // "tapresolver.backup.v2" (v2 adds triangles, zones, morgue, compass)
    let exportedBy: String          // "TapResolver iOS v1.0.0"
    let exportDate: String          // ISO8601 timestamp
    let authorName: String          // Who created this backup
    let locations: [LocationSummary]
    let totalLocations: Int
    let includesAssets: Bool
    
    struct LocationSummary: Codable {
        let id: String
        let name: String
        let originalID: String
        let sessionCount: Int
        let beaconCount: Int
        let mapDimensions: [Int]    // [width, height]
    }
}

