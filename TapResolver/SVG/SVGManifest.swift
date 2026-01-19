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
public struct SVGManifest: Codable {
    let tapResolver: SVGManifestMetadata
    let location: SVGManifestLocation
    let mapPoints: [String: SVGManifestMapPoint]  // UUID string → point data
    let triangles: [String: SVGManifestTriangle]  // triangle ID → vertex refs
    let zones: [String: SVGManifestZone]          // zone ID → corner refs
}

// MARK: - Metadata

/// Export metadata for versioning and conflict detection
public struct SVGManifestMetadata: Codable {
    let version: String
    let exportedAt: String  // ISO8601
    let app: String
    let device: String
    
    /// Create metadata for current export
    public static func current() -> SVGManifestMetadata {
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
public struct SVGManifestLocation: Codable {
    let id: String
    let mapDimensions: [Int]  // [width, height] in pixels
    let pixelsPerMeter: Float?
}

// MARK: - MapPoint

/// MapPoint state at export time
public struct SVGManifestMapPoint: Codable {
    let position: [Float]  // [x, y] in pixels
    let name: String?
    let roles: [String]    // MapPointRole raw values
}

// MARK: - Triangle

/// Triangle vertex references
public struct SVGManifestTriangle: Codable {
    let vertices: [String]  // 3 MapPoint UUID strings
}

// MARK: - Zone

/// Zone corner references and group membership
public struct SVGManifestZone: Codable {
    let displayName: String
    let groupID: String?
    let corners: [String]  // 4 MapPoint UUID strings
}

// MARK: - Encoding

extension SVGManifest {
    
    /// Encode manifest to JSON string for embedding in SVG
    /// - Returns: Pretty-printed JSON string, or nil if encoding fails
    public func encodeToJSON() -> String? {
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
    public static func decode(from json: String) -> SVGManifest? {
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

// MARK: - SVG Extraction

extension SVGManifest {
    
    /// Extract manifest JSON from SVG data layer
    /// Handles both app-exported format and Illustrator-reformatted format
    /// - Parameter svgString: Complete SVG file content
    /// - Returns: Parsed manifest, or nil if no manifest found or parsing fails
    static func extract(from svgString: String) -> SVGManifest? {
        // Find the data layer
        guard let dataLayerStart = svgString.range(of: "<g id=\"data\">"),
              let dataLayerEnd = svgString.range(of: "</g>", range: dataLayerStart.upperBound..<svgString.endIndex) else {
            print("📋 [SVGManifest] No data layer found in SVG")
            return nil
        }
        
        let dataLayerContent = String(svgString[dataLayerStart.upperBound..<dataLayerEnd.lowerBound])
        
        // Extract all text content from <tspan> elements
        // Pattern matches content between > and < within tspans
        var jsonLines: [String] = []
        
        let tspanPattern = #"<tspan[^>]*>([^<]*)</tspan>"#
        guard let regex = try? NSRegularExpression(pattern: tspanPattern, options: []) else {
            print("❌ [SVGManifest] Failed to create tspan regex")
            return nil
        }
        
        let range = NSRange(dataLayerContent.startIndex..<dataLayerContent.endIndex, in: dataLayerContent)
        let matches = regex.matches(in: dataLayerContent, options: [], range: range)
        
        for match in matches {
            guard let contentRange = Range(match.range(at: 1), in: dataLayerContent) else {
                continue
            }
            
            var line = String(dataLayerContent[contentRange])
            
            // Decode XML entities back to JSON characters
            line = line
                .replacingOccurrences(of: "&quot;", with: "\"")
                .replacingOccurrences(of: "&apos;", with: "'")
                .replacingOccurrences(of: "&lt;", with: "<")
                .replacingOccurrences(of: "&gt;", with: ">")
                .replacingOccurrences(of: "&amp;", with: "&")
            
            jsonLines.append(line)
        }
        
        guard !jsonLines.isEmpty else {
            print("📋 [SVGManifest] Data layer found but no text content extracted")
            return nil
        }
        
        // Reconstruct JSON (join lines, they may have leading whitespace from pretty-print)
        let jsonString = jsonLines.joined(separator: "\n")
        
        print("📋 [SVGManifest] Extracted \(jsonLines.count) lines from data layer")
        
        // Parse the JSON
        return decode(from: jsonString)
    }
}

// MARK: - Diff Detection

/// Represents a detected vertex position change
public struct VertexDiff {
    public let mapPointID: String        // UUID string from manifest
    public let originalPosition: CGPoint // Position at export time (from manifest)
    public let newPosition: CGPoint      // Position in imported SVG
    public let sourcePolygonID: String   // Zone or triangle ID
    public let sourceType: PolygonSourceType
    
    public enum PolygonSourceType {
        case zone
        case triangle
    }
    
    /// Distance moved in pixels
    public var deltaPixels: CGFloat {
        let dx = newPosition.x - originalPosition.x
        let dy = newPosition.y - originalPosition.y
        return sqrt(dx * dx + dy * dy)
    }
}

/// Result of analyzing diffs for a single MapPoint
public struct MapPointDiffAnalysis {
    public let mapPointID: String
    public let originalPosition: CGPoint
    public let diffs: [VertexDiff]
    
    /// All polygons agree on the new position (within threshold)
    public var isUnanimousMove: Bool {
        guard let firstNew = diffs.first?.newPosition else { return false }
        let threshold: CGFloat = 1.0  // 1 pixel tolerance for "same position"
        return diffs.allSatisfy { diff in
            let dx = diff.newPosition.x - firstNew.x
            let dy = diff.newPosition.y - firstNew.y
            return sqrt(dx * dx + dy * dy) < threshold
        }
    }
    
    /// The unanimous new position (only valid if isUnanimousMove is true)
    public var unanimousNewPosition: CGPoint? {
        guard isUnanimousMove else { return nil }
        return diffs.first?.newPosition
    }
    
    /// Some polygons moved, others didn't - requires split
    public var requiresSplit: Bool {
        return !isUnanimousMove && diffs.count > 0
    }
}

/// Complete diff report for an import operation
public struct ImportDiffReport {
    public let manifestVersion: String
    public let exportedAt: String
    public let analyses: [String: MapPointDiffAnalysis]  // mapPointID -> analysis
    
    /// MapPoints that moved unanimously (all references agree)
    public var unanimousMoves: [MapPointDiffAnalysis] {
        analyses.values.filter { $0.isUnanimousMove }
    }
    
    /// MapPoints that need splitting (references disagree)
    public var splits: [MapPointDiffAnalysis] {
        analyses.values.filter { $0.requiresSplit }
    }
    
    /// MapPoints with no changes
    public var unchangedCount: Int {
        analyses.values.filter { $0.diffs.isEmpty }.count
    }
}

extension SVGManifest {
    
    /// Detect vertex position changes between manifest and imported polygons
    /// - Parameters:
    ///   - zones: Parsed zones from SVG
    ///   - triangles: Parsed triangles from SVG  
    ///   - thresholdPixels: Minimum movement to count as a change
    /// - Returns: Diff report with all detected changes
    func detectChanges(
        zones: [RawZone],
        triangles: [RawTriangle],
        thresholdPixels: CGFloat
    ) -> ImportDiffReport {
        var allDiffs: [String: [VertexDiff]] = [:]  // mapPointID -> diffs
        
        // Check zones
        for rawZone in zones {
            let zoneID = rawZone.id.asCodeID
            
            // Try exact match first, then fallback matches
            let manifestZone: SVGManifestZone?
            let matchedZoneID: String
            
            if let exact = self.zones[zoneID] {
                manifestZone = exact
                matchedZoneID = zoneID
            } else if let exact = self.zones[rawZone.id] {
                // Try raw ID without asCodeID transform
                manifestZone = exact
                matchedZoneID = rawZone.id
                print("📋 [DiffDetect] Zone matched by raw ID: '\(rawZone.id)'")
            } else {
                // Try case-insensitive match
                let altMatch = self.zones.first { (key, _) in
                    key.lowercased() == zoneID.lowercased() ||
                    key.lowercased() == rawZone.id.lowercased()
                }
                if let altMatch = altMatch {
                    manifestZone = altMatch.value
                    matchedZoneID = altMatch.key
                    print("📋 [DiffDetect] Zone matched case-insensitive: '\(rawZone.id)' → '\(altMatch.key)'")
                } else {
                    print("📋 [DiffDetect] Zone '\(zoneID)' (raw: '\(rawZone.id)') not in manifest - new zone")
                    print("   Available manifest zones: \(Array(self.zones.keys).sorted())")
                    continue
                }
            }
            
            guard let zone = manifestZone else { continue }
            
            // Compare each corner
            for (index, cornerID) in zone.corners.enumerated() {
                guard index < rawZone.corners.count,
                      let manifestPoint = self.mapPoints[cornerID] else {
                    continue
                }
                
                let originalPos = CGPoint(
                    x: CGFloat(manifestPoint.position[0]),
                    y: CGFloat(manifestPoint.position[1])
                )
                let newPos = rawZone.corners[index]
                
                let dx = newPos.x - originalPos.x
                let dy = newPos.y - originalPos.y
                let distance = sqrt(dx * dx + dy * dy)
                
                if distance >= thresholdPixels {
                    let diff = VertexDiff(
                        mapPointID: cornerID,
                        originalPosition: originalPos,
                        newPosition: newPos,
                        sourcePolygonID: matchedZoneID,
                        sourceType: .zone
                    )
                    allDiffs[cornerID, default: []].append(diff)
                    print("📋 [DiffDetect] Zone '\(matchedZoneID)' corner \(index): moved \(String(format: "%.1f", distance))px")
                }
            }
        }
        
        // Check triangles
        for rawTriangle in triangles {
            // Try to match by ID first (more reliable), fall back to vertex matching
            let matchResult: (String, SVGManifestTriangle)?
            
            if let rawID = rawTriangle.id, let manifestTriangle = self.triangles[rawID] {
                matchResult = (rawID, manifestTriangle)
                print("📋 [DiffDetect] Matched triangle by ID: '\(rawID)'")
            } else if let rawID = rawTriangle.id {
                // Try without the ID having exact match (maybe prefix difference)
                let found = self.triangles.first { (key, _) in
                    key == rawID || key.contains(rawID) || rawID.contains(key)
                }
                if let found = found {
                    matchResult = found
                    print("📋 [DiffDetect] Matched triangle by partial ID: '\(rawID)' → '\(found.0)'")
                } else {
                    matchResult = findMatchingTriangle(rawTriangle)
                }
            } else {
                matchResult = findMatchingTriangle(rawTriangle)
            }
            
            guard let (triangleID, manifestTriangle) = matchResult else {
                print("📋 [DiffDetect] Triangle not found in manifest - new triangle")
                continue
            }
            
            // Compare each vertex
            for (index, vertexID) in manifestTriangle.vertices.enumerated() {
                guard index < rawTriangle.vertices.count,
                      let manifestPoint = self.mapPoints[vertexID] else {
                    continue
                }
                
                let originalPos = CGPoint(
                    x: CGFloat(manifestPoint.position[0]),
                    y: CGFloat(manifestPoint.position[1])
                )
                let newPos = rawTriangle.vertices[index]
                
                let dx = newPos.x - originalPos.x
                let dy = newPos.y - originalPos.y
                let distance = sqrt(dx * dx + dy * dy)
                
                if distance >= thresholdPixels {
                    let diff = VertexDiff(
                        mapPointID: vertexID,
                        originalPosition: originalPos,
                        newPosition: newPos,
                        sourcePolygonID: triangleID,
                        sourceType: .triangle
                    )
                    allDiffs[vertexID, default: []].append(diff)
                    print("📋 [DiffDetect] Triangle '\(triangleID)' vertex \(index): moved \(String(format: "%.1f", distance))px")
                }
            }
        }
        
        // Build analyses
        var analyses: [String: MapPointDiffAnalysis] = [:]
        
        for (mapPointID, diffs) in allDiffs {
            guard let manifestPoint = self.mapPoints[mapPointID] else { continue }
            
            let originalPos = CGPoint(
                x: CGFloat(manifestPoint.position[0]),
                y: CGFloat(manifestPoint.position[1])
            )
            
            analyses[mapPointID] = MapPointDiffAnalysis(
                mapPointID: mapPointID,
                originalPosition: originalPos,
                diffs: diffs
            )
        }
        
        return ImportDiffReport(
            manifestVersion: tapResolver.version,
            exportedAt: tapResolver.exportedAt,
            analyses: analyses
        )
    }
    
    /// Find a triangle in the manifest that matches the raw triangle's vertices
    private func findMatchingTriangle(_ rawTriangle: RawTriangle) -> (String, SVGManifestTriangle)? {
        // Try to match by comparing vertex positions
        for (triangleID, manifestTriangle) in self.triangles {
            guard manifestTriangle.vertices.count == rawTriangle.vertices.count else { continue }
            
            // Check if vertices match (allowing for vertex order rotation)
            var allMatch = true
            for (index, vertexID) in manifestTriangle.vertices.enumerated() {
                guard let manifestPoint = self.mapPoints[vertexID],
                      index < rawTriangle.vertices.count else {
                    allMatch = false
                    break
                }
                
                let manifestPos = CGPoint(
                    x: CGFloat(manifestPoint.position[0]),
                    y: CGFloat(manifestPoint.position[1])
                )
                let rawPos = rawTriangle.vertices[index]
                
                // If ANY vertex is close to its original position, this might be the right triangle
                // (moved vertices will be detected as diffs)
                let dx = rawPos.x - manifestPos.x
                let dy = rawPos.y - manifestPos.y
                let distance = sqrt(dx * dx + dy * dy)
                
                // Use a generous threshold for matching (500px) - we just need to identify the triangle
                if distance > 500 {
                    allMatch = false
                    break
                }
            }
            
            if allMatch {
                return (triangleID, manifestTriangle)
            }
        }
        
        return nil
    }
}
