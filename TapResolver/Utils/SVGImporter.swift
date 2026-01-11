//
//  SVGImporter.swift
//  TapResolver
//
//  Orchestrates SVG import: parsing, MapPoint resolution, and entity creation.
//

import Foundation
import CoreGraphics

/// Result of an SVG import operation
public struct SVGImportResult {
    public let groupsCreated: Int
    public let zonesCreated: Int
    public let mapPointsCreated: Int
    public let mapPointsReused: Int
    public let errors: [String]
    public let warnings: [String]
    
    public var success: Bool {
        errors.isEmpty
    }
}

/// Orchestrates SVG zone import
public class SVGImporter {
    
    // MARK: - Dependencies
    
    private let mapPointStore: MapPointStore
    private let zoneStore: ZoneStore
    private let zoneGroupStore: ZoneGroupStore
    private let pixelsPerMeter: CGFloat
    
    // MARK: - Configuration
    
    /// Threshold in meters for MapPoint deduplication
    private let deduplicationThresholdMeters: Float = 0.5
    
    // MARK: - Initialization
    
    public init(
        mapPointStore: MapPointStore,
        zoneStore: ZoneStore,
        zoneGroupStore: ZoneGroupStore,
        pixelsPerMeter: CGFloat
    ) {
        self.mapPointStore = mapPointStore
        self.zoneStore = zoneStore
        self.zoneGroupStore = zoneGroupStore
        self.pixelsPerMeter = pixelsPerMeter
    }
    
    // MARK: - Import
    
    /// Import zones from SVG data
    /// - Parameter data: Raw SVG file data
    /// - Returns: Import result with statistics and any errors
    public func importZones(from data: Data) -> SVGImportResult {
        var errors: [String] = []
        var warnings: [String] = []
        
        print("📥 [SVGImporter] Starting import...")
        
        // 1. Parse SVG
        let parser = ZoneSVGParser()
        let parseResult = parser.parse(data: data)
        
        errors.append(contentsOf: parseResult.errors)
        
        guard !parseResult.zones.isEmpty else {
            errors.append("No zones found in SVG file")
            return SVGImportResult(
                groupsCreated: 0,
                zonesCreated: 0,
                mapPointsCreated: 0,
                mapPointsReused: 0,
                errors: errors,
                warnings: warnings
            )
        }
        
        print("📥 [SVGImporter] Parsed \(parseResult.groups.count) groups, \(parseResult.zones.count) zones")
        
        // 2. Create MapPoint resolver
        let resolver = MapPointResolver(
            mapPointStore: mapPointStore,
            thresholdMeters: deduplicationThresholdMeters,
            pixelsPerMeter: pixelsPerMeter
        )
        
        // 3. Create zone groups
        var groupsCreated = 0
        for rawGroup in parseResult.groups {
            // Check if group already exists
            if zoneGroupStore.group(withID: rawGroup.id) != nil {
                print("⏭️ [SVGImporter] Group '\(rawGroup.id)' already exists, skipping")
                continue
            }
            
            zoneGroupStore.createGroup(
                id: rawGroup.id,
                displayName: rawGroup.displayName,
                colorHex: rawGroup.colorHex
            )
            groupsCreated += 1
        }
        
        // 4. Create zones with resolved MapPoints
        var zonesCreated = 0
        for rawZone in parseResult.zones {
            // Validate corner count
            if rawZone.corners.count != 4 {
                warnings.append("Zone '\(rawZone.displayName)' has \(rawZone.corners.count) corners, expected 4. Skipping.")
                continue
            }
            
            // Check if zone already exists
            let zoneID = rawZone.id.asCodeID
            if zoneStore.zone(withID: zoneID) != nil {
                print("⏭️ [SVGImporter] Zone '\(zoneID)' already exists, skipping")
                continue
            }
            
            // Resolve corner MapPoints
            let cornerPointIDs = resolver.resolve(rawZone.corners, roles: [.zoneCorner])
            let cornerIDStrings = cornerPointIDs.map { $0.uuidString }
            
            // Create zone
            zoneStore.createZone(
                id: zoneID,
                displayName: rawZone.displayName,
                cornerMapPointIDs: cornerIDStrings,
                groupID: rawZone.groupID
            )
            
            // Add zone to group
            if let groupID = rawZone.groupID {
                zoneGroupStore.addZone(zoneID, toGroup: groupID)
            }
            
            zonesCreated += 1
        }
        
        // 5. Commit new MapPoints
        let mapPointsCreated = resolver.commit()
        let mapPointsReused = resolver.resolvedCount - mapPointsCreated
        
        print("📥 [SVGImporter] Import complete:")
        print("   Groups created: \(groupsCreated)")
        print("   Zones created: \(zonesCreated)")
        print("   MapPoints created: \(mapPointsCreated)")
        print("   MapPoints reused: \(mapPointsReused)")
        
        if !warnings.isEmpty {
            print("   ⚠️ Warnings: \(warnings.count)")
            for warning in warnings {
                print("      - \(warning)")
            }
        }
        
        return SVGImportResult(
            groupsCreated: groupsCreated,
            zonesCreated: zonesCreated,
            mapPointsCreated: mapPointsCreated,
            mapPointsReused: mapPointsReused,
            errors: errors,
            warnings: warnings
        )
    }
    
    /// Import zones from a file URL
    /// - Parameter url: URL to SVG file
    /// - Returns: Import result
    public func importZones(from url: URL) -> SVGImportResult {
        do {
            let data = try Data(contentsOf: url)
            return importZones(from: data)
        } catch {
            return SVGImportResult(
                groupsCreated: 0,
                zonesCreated: 0,
                mapPointsCreated: 0,
                mapPointsReused: 0,
                errors: ["Failed to read file: \(error.localizedDescription)"],
                warnings: []
            )
        }
    }
}
