//
//  SVGManifest.swift
//  TapResolver
//
//  Data structures for SVG export manifest.
//  Embedded as JSON in exported SVGs to enable intelligent reimport.
//

import Foundation
import CoreGraphics
import UIKit

// MARK: - Manifest Root

/// Complete manifest embedded in SVG exports
struct SVGManifest: Codable {
    let tapResolver: SVGManifestMetadata
    let location: SVGManifestLocation
    let mapPoints: [String: SVGManifestMapPoint]  // UUID string → point data
    let triangles: [String: SVGManifestTriangle]  // triangle ID → vertex refs
    let zones: [String: SVGManifestZone]          // zone ID → corner refs
}

// MARK: - Metadata

/// Export metadata for versioning and conflict detection
struct SVGManifestMetadata: Codable {
    let version: String
    let exportedAt: String  // ISO8601
    let app: String
    let device: String
    
    /// Create metadata for current export
    static func current() -> SVGManifestMetadata {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        
        return SVGManifestMetadata(
            version: "1.0",
            exportedAt: formatter.string(from: Date()),
            app: "TapResolver iOS \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")",
            device: UIDevice.current.model
        )
    }
}

// MARK: - Location

/// Location context for the export
struct SVGManifestLocation: Codable {
    let id: String
    let mapDimensions: [Int]  // [width, height] in pixels
    let pixelsPerMeter: Float?
}

// MARK: - MapPoint

/// MapPoint state at export time
struct SVGManifestMapPoint: Codable {
    let position: [Float]  // [x, y] in pixels
    let name: String?
    let roles: [String]    // MapPointRole raw values
}

// MARK: - Triangle

/// Triangle vertex references
struct SVGManifestTriangle: Codable {
    let vertices: [String]  // 3 MapPoint UUID strings
}

// MARK: - Zone

/// Zone corner references and group membership
struct SVGManifestZone: Codable {
    let displayName: String
    let groupID: String?
    let corners: [String]  // 4 MapPoint UUID strings
}

// MARK: - Encoding

extension SVGManifest {
    
    /// Encode manifest to JSON string for embedding in SVG
    /// - Returns: Pretty-printed JSON string, or nil if encoding fails
    func encodeToJSON() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        guard let data = try? encoder.encode(self) else {
            print("❌ [SVGManifest] Failed to encode manifest")
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
}

// MARK: - Decoding

extension SVGManifest {
    
    /// Decode manifest from JSON string extracted from SVG
    /// - Parameter json: JSON string from SVG text layer
    /// - Returns: Parsed manifest, or nil if decoding fails
    static func decode(from json: String) -> SVGManifest? {
        guard let data = json.data(using: .utf8) else {
            print("❌ [SVGManifest] Failed to convert JSON string to data")
            return nil
        }
        
        do {
            let manifest = try JSONDecoder().decode(SVGManifest.self, from: data)
            print("✅ [SVGManifest] Decoded manifest v\(manifest.tapResolver.version)")
            print("   Location: \(manifest.location.id)")
            print("   MapPoints: \(manifest.mapPoints.count)")
            print("   Triangles: \(manifest.triangles.count)")
            print("   Zones: \(manifest.zones.count)")
            return manifest
        } catch {
            print("❌ [SVGManifest] Failed to decode manifest: \(error)")
            return nil
        }
    }
}

// MARK: - Builder

extension SVGManifest {
    
    /// Build manifest from current app state
    /// - Parameters:
    ///   - locationID: Current location identifier
    ///   - mapWidth: Map image width in pixels
    ///   - mapHeight: Map image height in pixels
    ///   - pixelsPerMeter: Scale factor (nil if not calibrated)
    ///   - mapPoints: All MapPoints to include
    ///   - triangles: All triangles to include
    ///   - zones: All zones to include
    /// - Returns: Complete manifest ready for embedding
    static func build(
        locationID: String,
        mapWidth: Int,
        mapHeight: Int,
        pixelsPerMeter: Float?,
        mapPoints: [MapPointStore.MapPoint],
        triangles: [TrianglePatch],
        zones: [Zone]
    ) -> SVGManifest {
        
        // Build MapPoints dictionary
        var mapPointsDict: [String: SVGManifestMapPoint] = [:]
        for point in mapPoints {
            let roles = point.roles.map { $0.rawValue }
            mapPointsDict[point.id.uuidString] = SVGManifestMapPoint(
                position: [Float(point.position.x), Float(point.position.y)],
                name: point.name,
                roles: roles
            )
        }
        
        // Build Triangles dictionary
        var trianglesDict: [String: SVGManifestTriangle] = [:]
        for triangle in triangles {
            let triangleID = "tri-\(triangle.id.uuidString.prefix(8))"
            let vertices = triangle.vertexIDs.map { $0.uuidString }
            trianglesDict[triangleID] = SVGManifestTriangle(vertices: vertices)
        }
        
        // Build Zones dictionary
        var zonesDict: [String: SVGManifestZone] = [:]
        for zone in zones {
            zonesDict[zone.id] = SVGManifestZone(
                displayName: zone.displayName,
                groupID: zone.groupID,
                corners: zone.cornerMapPointIDs
            )
        }
        
        return SVGManifest(
            tapResolver: .current(),
            location: SVGManifestLocation(
                id: locationID,
                mapDimensions: [mapWidth, mapHeight],
                pixelsPerMeter: pixelsPerMeter
            ),
            mapPoints: mapPointsDict,
            triangles: trianglesDict,
            zones: zonesDict
        )
    }
}
