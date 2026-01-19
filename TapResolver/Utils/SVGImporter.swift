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

/// Result of triangle SVG import
struct TriangleSVGImportResult {
    let trianglesCreated: Int
    let trianglesSkipped: Int
    let mapPointsCreated: Int
    let mapPointsReused: Int
    let zonesUpdated: Int
    let errors: [String]
    let warnings: [String]
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
        
        // Log manifest status and detect changes
        if let manifest = parseResult.manifest {
            print("📋 [SVGImporter] Found manifest v\(manifest.tapResolver.version)")
            print("   Exported: \(manifest.tapResolver.exportedAt)")
            print("   MapPoints in manifest: \(manifest.mapPoints.count)")
            print("   Zones in manifest: \(manifest.zones.count)")
            
            // Detect vertex changes
            let thresholdPixels = CGFloat(deduplicationThresholdMeters) * pixelsPerMeter
            let diffReport = manifest.detectChanges(
                zones: parseResult.zones,
                triangles: [],  // Zone import doesn't process triangles
                thresholdPixels: thresholdPixels
            )
            
            print("📋 [SVGImporter] Diff Report:")
            print("   Unanimous moves: \(diffReport.unanimousMoves.count)")
            print("   Splits required: \(diffReport.splits.count)")
            
            for analysis in diffReport.unanimousMoves {
                if let newPos = analysis.unanimousNewPosition {
                    print("   ➡️ MapPoint \(analysis.mapPointID.prefix(8)): move to (\(String(format: "%.1f", newPos.x)), \(String(format: "%.1f", newPos.y)))")
                }
            }
            
            for analysis in diffReport.splits {
                print("   ⚠️ MapPoint \(analysis.mapPointID.prefix(8)): SPLIT required (\(analysis.diffs.count) conflicting references)")
            }
            
            // Apply detected changes
            var mapPointsUpdated = 0
            var mapPointsSplit = 0
            
            if !diffReport.unanimousMoves.isEmpty {
                mapPointsUpdated = applyUnanimousMoves(diffReport.unanimousMoves, mapPointStore: mapPointStore)
            }
            
            if !diffReport.splits.isEmpty {
                mapPointsSplit = applySplits(
                    diffReport.splits,
                    mapPointStore: mapPointStore,
                    zoneStore: zoneStore,
                    triangleStore: nil  // Zone import doesn't have triangle store access
                )
            }
            
            if mapPointsUpdated > 0 || mapPointsSplit > 0 {
                print("📋 [SVGImporter] Applied changes: \(mapPointsUpdated) moved, \(mapPointsSplit) split")
            }
            
        } else {
            print("📋 [SVGImporter] No manifest found - using legacy import mode")
        }
        
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
    
    /// Import triangles from SVG data
    /// - Parameters:
    ///   - data: SVG file data
    ///   - triangleStore: Store to add triangles to
    ///   - mapPointStore: Store for vertex MapPoints
    ///   - zoneStore: Store to update triangle membership
    ///   - pixelsPerMeter: Conversion factor from MetricSquare
    /// - Returns: Import result with statistics
    func importTriangles(
        from data: Data,
        triangleStore: TrianglePatchStore,
        mapPointStore: MapPointStore,
        zoneStore: ZoneStore,
        pixelsPerMeter: Float
    ) -> TriangleSVGImportResult {
        
        // Step 1: Parse SVG
        print("📐 [SVGImporter] importTriangles called, data size: \(data.count) bytes")
        let parser = TriangleSVGParser()
        let parseResult = parser.parse(data: data)
        
        if !parseResult.errors.isEmpty {
            return TriangleSVGImportResult(
                trianglesCreated: 0,
                trianglesSkipped: 0,
                mapPointsCreated: 0,
                mapPointsReused: 0,
                zonesUpdated: 0,
                errors: parseResult.errors,
                warnings: parseResult.warnings
            )
        }
        
        // Log manifest status and detect changes
        if let manifest = parseResult.manifest {
            print("📋 [SVGImporter] Found manifest v\(manifest.tapResolver.version)")
            print("   Triangles in manifest: \(manifest.triangles.count)")
            
            // Detect vertex changes
            let thresholdPixels = CGFloat(0.5) * CGFloat(pixelsPerMeter)  // 0.5 meters
            let diffReport = manifest.detectChanges(
                zones: [],  // Triangle import doesn't process zones
                triangles: parseResult.triangles,
                thresholdPixels: thresholdPixels
            )
            
            print("📋 [SVGImporter] Diff Report:")
            print("   Unanimous moves: \(diffReport.unanimousMoves.count)")
            print("   Splits required: \(diffReport.splits.count)")
            
            for analysis in diffReport.unanimousMoves {
                if let newPos = analysis.unanimousNewPosition {
                    print("   ➡️ MapPoint \(analysis.mapPointID.prefix(8)): move to (\(String(format: "%.1f", newPos.x)), \(String(format: "%.1f", newPos.y)))")
                }
            }
            
            for analysis in diffReport.splits {
                print("   ⚠️ MapPoint \(analysis.mapPointID.prefix(8)): SPLIT required (\(analysis.diffs.count) conflicting references)")
            }
            
            // Apply detected changes
            var mapPointsUpdated = 0
            var mapPointsSplit = 0
            
            if !diffReport.unanimousMoves.isEmpty {
                mapPointsUpdated = applyUnanimousMoves(diffReport.unanimousMoves, mapPointStore: mapPointStore)
            }
            
            if !diffReport.splits.isEmpty {
                mapPointsSplit = applySplits(
                    diffReport.splits,
                    mapPointStore: mapPointStore,
                    zoneStore: zoneStore,
                    triangleStore: triangleStore
                )
            }
            
            if mapPointsUpdated > 0 || mapPointsSplit > 0 {
                print("📋 [SVGImporter] Applied changes: \(mapPointsUpdated) moved, \(mapPointsSplit) split")
            }
            
        } else {
            print("📋 [SVGImporter] No manifest found - using legacy import mode")
        }
        
        // Step 2: Setup MapPoint resolver
        let resolver = MapPointResolver(
            mapPointStore: mapPointStore,
            thresholdMeters: 0.5,
            pixelsPerMeter: CGFloat(pixelsPerMeter)
        )
        
        var trianglesCreated = 0
        var trianglesSkipped = 0
        var warnings = parseResult.warnings
        
        // Step 3: Create triangles
        for rawTriangle in parseResult.triangles {
            // Resolve vertices to MapPoints
            var vertexIDs: [UUID] = []
            for vertex in rawTriangle.vertices {
                let resolved = resolver.resolve(vertex, roles: [.triangleEdge])
                vertexIDs.append(resolved)
            }
            
            // Check for collinearity
            if areCollinear(rawTriangle.vertices[0], rawTriangle.vertices[1], rawTriangle.vertices[2]) {
                warnings.append("Skipped collinear triangle at (\(Int(rawTriangle.vertices[0].x)), \(Int(rawTriangle.vertices[0].y)))")
                trianglesSkipped += 1
                continue
            }
            
            // Check for overlap with existing triangles
            if triangleStore.hasInteriorOverlap(with: vertexIDs, mapPointStore: mapPointStore) {
                warnings.append("Skipped overlapping triangle at (\(Int(rawTriangle.vertices[0].x)), \(Int(rawTriangle.vertices[0].y)))")
                trianglesSkipped += 1
                continue
            }
            
            // Create triangle
            let triangle = TrianglePatch(vertexIDs: vertexIDs)
            triangleStore.triangles.append(triangle)
            
            // Update MapPoint memberships
            for vertexID in vertexIDs {
                if let index = mapPointStore.points.firstIndex(where: { $0.id == vertexID }) {
                    if !mapPointStore.points[index].triangleMemberships.contains(triangle.id) {
                        mapPointStore.points[index].triangleMemberships.append(triangle.id)
                    }
                }
            }
            
            trianglesCreated += 1
        }
        
        // Step 4: Commit MapPoints
        let resolvedCountBeforeCommit = resolver.resolvedCount
        let mapPointsCreated = resolver.commit()
        let mapPointsReused = resolvedCountBeforeCommit - mapPointsCreated
        mapPointStore.save()
        triangleStore.save()
        
        // Step 5: Recompute zone membership
        let zoneCountBefore = zoneStore.zones.map { $0.memberTriangleIDs.count }
        zoneStore.recomputeAllTriangleMembership()
        let zoneCountAfter = zoneStore.zones.map { $0.memberTriangleIDs.count }
        
        let zonesUpdated = zip(zoneCountBefore, zoneCountAfter).filter { $0 != $1 }.count
        
        print("📐 [SVGImporter] Imported \(trianglesCreated) triangles, skipped \(trianglesSkipped)")
        print("📐 [SVGImporter] MapPoints: \(mapPointsCreated) created, \(mapPointsReused) reused")
        print("📐 [SVGImporter] Zones updated: \(zonesUpdated)")
        
        return TriangleSVGImportResult(
            trianglesCreated: trianglesCreated,
            trianglesSkipped: trianglesSkipped,
            mapPointsCreated: mapPointsCreated,
            mapPointsReused: mapPointsReused,
            zonesUpdated: zonesUpdated,
            errors: [],
            warnings: warnings
        )
    }
    
    // MARK: - Geometry Helpers
    
    private func areCollinear(_ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint) -> Bool {
        // Cross product of vectors (p2-p1) and (p3-p1)
        let cross = (p2.x - p1.x) * (p3.y - p1.y) - (p2.y - p1.y) * (p3.x - p1.x)
        return abs(cross) < 1.0  // Threshold for floating point comparison
    }
    
    // MARK: - Apply Diff Changes
    
    /// Apply unanimous moves - update MapPoint positions and clear calibration
    /// - Parameters:
    ///   - moves: Array of unanimous move analyses
    ///   - mapPointStore: Store to update
    /// - Returns: Number of MapPoints updated
    private func applyUnanimousMoves(
        _ moves: [MapPointDiffAnalysis],
        mapPointStore: MapPointStore
    ) -> Int {
        var updatedCount = 0
        
        for analysis in moves {
            guard let newPosition = analysis.unanimousNewPosition,
                  let uuid = UUID(uuidString: analysis.mapPointID),
                  let index = mapPointStore.points.firstIndex(where: { $0.id == uuid }) else {
                print("⚠️ [SVGImporter] Could not find MapPoint \(analysis.mapPointID.prefix(8)) for move")
                continue
            }
            
            let oldPosition = mapPointStore.points[index].position
            
            // Update position
            mapPointStore.points[index].position = newPosition
            
            // Clear calibration data
            mapPointStore.points[index].arPositionHistory = []
            mapPointStore.points[index].canonicalPosition = nil
            mapPointStore.points[index].canonicalConfidence = nil
            mapPointStore.points[index].canonicalSampleCount = 0
            
            print("✅ [SVGImporter] Moved MapPoint \(analysis.mapPointID.prefix(8)): (\(String(format: "%.1f", oldPosition.x)), \(String(format: "%.1f", oldPosition.y))) → (\(String(format: "%.1f", newPosition.x)), \(String(format: "%.1f", newPosition.y)))")
            
            updatedCount += 1
        }
        
        if updatedCount > 0 {
            mapPointStore.save()
            print("💾 [SVGImporter] Saved \(updatedCount) moved MapPoint(s)")
        }
        
        return updatedCount
    }
    
    /// Apply splits - create new MapPoints and update polygon references
    /// - Parameters:
    ///   - splits: Array of split analyses
    ///   - mapPointStore: Store to create new points in
    ///   - zoneStore: Store to update zone references
    ///   - triangleStore: Store to update triangle references (optional)
    /// - Returns: Number of new MapPoints created
    private func applySplits(
        _ splits: [MapPointDiffAnalysis],
        mapPointStore: MapPointStore,
        zoneStore: ZoneStore,
        triangleStore: TrianglePatchStore?
    ) -> Int {
        var createdCount = 0
        
        for analysis in splits {
            // Group diffs by their new position
            var positionGroups: [String: [VertexDiff]] = [:]  // "x,y" -> diffs
            
            for diff in analysis.diffs {
                let key = "\(Int(diff.newPosition.x)),\(Int(diff.newPosition.y))"
                positionGroups[key, default: []].append(diff)
            }
            
            // Find which position is the "original" (matches manifest) vs "moved"
            let originalKey = "\(Int(analysis.originalPosition.x)),\(Int(analysis.originalPosition.y))"
            
            for (posKey, diffs) in positionGroups {
                // Skip the group at the original position - those keep the original MapPoint
                if posKey == originalKey {
                    continue
                }
                
                guard let firstDiff = diffs.first else { continue }
                
                // Create new MapPoint at the new position
                let newPoint = MapPointStore.MapPoint(
                    mapPoint: firstDiff.newPosition,
                    roles: [.zoneCorner, .triangleEdge],  // Assign both roles to be safe
                    isLocked: true
                )
                mapPointStore.points.append(newPoint)
                
                print("🆕 [SVGImporter] Created split MapPoint \(newPoint.id.uuidString.prefix(8)) at (\(String(format: "%.1f", firstDiff.newPosition.x)), \(String(format: "%.1f", firstDiff.newPosition.y)))")
                
                // Update references for all polygons that moved to this position
                for diff in diffs {
                    switch diff.sourceType {
                    case .zone:
                        updateZoneReference(
                            zoneID: diff.sourcePolygonID,
                            oldMapPointID: diff.mapPointID,
                            newMapPointID: newPoint.id.uuidString,
                            zoneStore: zoneStore
                        )
                    case .triangle:
                        if let triangleStore = triangleStore {
                            updateTriangleReference(
                                triangleID: diff.sourcePolygonID,
                                oldMapPointID: diff.mapPointID,
                                newMapPointID: newPoint.id,
                                triangleStore: triangleStore
                            )
                        }
                    }
                }
                
                createdCount += 1
            }
        }
        
        if createdCount > 0 {
            mapPointStore.save()
            zoneStore.save()
            triangleStore?.save()
            print("💾 [SVGImporter] Saved \(createdCount) split MapPoint(s)")
        }
        
        return createdCount
    }
    
    /// Update a zone's corner reference from old MapPoint to new MapPoint
    private func updateZoneReference(
        zoneID: String,
        oldMapPointID: String,
        newMapPointID: String,
        zoneStore: ZoneStore
    ) {
        guard let index = zoneStore.zones.firstIndex(where: { $0.id == zoneID }) else {
            print("⚠️ [SVGImporter] Zone '\(zoneID)' not found for reference update")
            return
        }
        
        var updatedCorners = zoneStore.zones[index].cornerMapPointIDs
        if let cornerIndex = updatedCorners.firstIndex(of: oldMapPointID) {
            updatedCorners[cornerIndex] = newMapPointID
            zoneStore.zones[index].cornerMapPointIDs = updatedCorners
            print("   📝 Updated zone '\(zoneID)' corner: \(oldMapPointID.prefix(8)) → \(newMapPointID.prefix(8))")
        }
    }
    
    /// Update a triangle's vertex reference from old MapPoint to new MapPoint
    private func updateTriangleReference(
        triangleID: String,
        oldMapPointID: String,
        newMapPointID: UUID,
        triangleStore: TrianglePatchStore
    ) {
        // Triangle IDs in manifest are like "tri-E325D867", need to match
        guard let index = triangleStore.triangles.firstIndex(where: { triangle in
            let manifestID = "tri-\(triangle.id.uuidString.prefix(8))"
            return manifestID == triangleID
        }) else {
            print("⚠️ [SVGImporter] Triangle '\(triangleID)' not found for reference update")
            return
        }
        
        guard let oldUUID = UUID(uuidString: oldMapPointID) else {
            print("⚠️ [SVGImporter] Invalid UUID: \(oldMapPointID)")
            return
        }
        
        var updatedTriangle = triangleStore.triangles[index]
        var updatedVertices = updatedTriangle.vertexIDs
        if let vertexIndex = updatedVertices.firstIndex(of: oldUUID) {
            updatedVertices[vertexIndex] = newMapPointID
            updatedTriangle = TrianglePatch(
                id: updatedTriangle.id,
                vertexIDs: updatedVertices,
                isCalibrated: updatedTriangle.isCalibrated,
                calibrationQuality: updatedTriangle.calibrationQuality,
                transform: updatedTriangle.transform,
                createdAt: updatedTriangle.createdAt,
                lastCalibratedAt: updatedTriangle.lastCalibratedAt,
                arMarkerIDs: updatedTriangle.arMarkerIDs,
                userPositionWhenCalibrated: updatedTriangle.userPositionWhenCalibrated,
                legMeasurements: updatedTriangle.legMeasurements,
                worldMapFilename: updatedTriangle.worldMapFilename,
                worldMapFilesByStrategy: updatedTriangle.worldMapFilesByStrategy,
                lastStartingVertexIndex: updatedTriangle.lastStartingVertexIndex
            )
            triangleStore.triangles[index] = updatedTriangle
            print("   📝 Updated triangle '\(triangleID)' vertex: \(oldMapPointID.prefix(8)) → \(newMapPointID.uuidString.prefix(8))")
        }
    }
}
