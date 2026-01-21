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
    private let deduplicationThresholdMeters: Float = 0.01  // 1cm tolerance for point-snapped SVG edits
    
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
        
        // Track which triangles are in the manifest (already exist in app)
        var manifestTriangleIDs: Set<String> = []
        
        // Log manifest status and detect changes
        if let manifest = parseResult.manifest {
            print("📋 [SVGImporter] Found manifest v\(manifest.tapResolver.version)")
            print("   Triangles in manifest: \(manifest.triangles.count)")
            
            // Detect vertex changes
            let thresholdPixels = CGFloat(deduplicationThresholdMeters) * CGFloat(pixelsPerMeter)
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
            
            // Build set of manifest triangle IDs for filtering
            manifestTriangleIDs = Set(manifest.triangles.keys)
            print("📋 [SVGImporter] Manifest contains \(manifestTriangleIDs.count) triangles - will skip these during creation")
            
        } else {
            print("📋 [SVGImporter] No manifest found - using legacy import mode")
        }
        
        // ============================================================
        // PHASE 1: PROCESS MANIFEST TRIANGLES (update existing only)
        // ============================================================
        
        // Partition triangles into manifest (existing) vs new
        let manifestTrianglesRaw = parseResult.triangles.filter { rawTriangle in
            let triangleID = rawTriangle.id ?? ""
            return manifestTriangleIDs.contains(triangleID)
        }
        let newTrianglesRaw = parseResult.triangles.filter { rawTriangle in
            let triangleID = rawTriangle.id ?? ""
            return !manifestTriangleIDs.contains(triangleID)
        }
        
        print("📋 [SVGImporter] Phase 1: Processing \(manifestTrianglesRaw.count) manifest triangles")
        print("📋 [SVGImporter] Phase 2 pending: \(newTrianglesRaw.count) new triangles")
        
        var trianglesCreated = 0
        var trianglesSkipped = 0
        var warnings = parseResult.warnings
        
        // Phase 1: Handle manifest triangles (skip creation, update displayNames)
        for rawTriangle in manifestTrianglesRaw {
            let triangleID = rawTriangle.id ?? "unnamed"
            
            // Find existing triangle by displayName or UUID
            if let existingIndex = triangleStore.triangles.firstIndex(where: { triangle in
                if let displayName = triangle.displayName, displayName == triangleID {
                    return true
                }
                if triangleID.hasPrefix("tri-") {
                    let uuidPart = String(triangleID.dropFirst(4))
                    if triangle.id.uuidString == uuidPart {
                        return true
                    }
                    if triangle.id.uuidString.hasPrefix(uuidPart) {
                        return true
                    }
                }
                return false
            }) {
                // Triangle exists - update displayName if needed
                let svgID = rawTriangle.id ?? ""
                if !svgID.isEmpty && !isUUIDBasedName(svgID) {
                    if triangleStore.triangles[existingIndex].displayName != svgID {
                        triangleStore.triangles[existingIndex].displayName = svgID
                        print("📝 [SVGImporter] Updated displayName for existing triangle: '\(svgID)'")
                    }
                }
                print("⏭️ [SVGImporter] Triangle '\(triangleID)' exists - skipping creation")
                trianglesSkipped += 1
            } else {
                // Triangle in manifest but not in app - will recreate in Phase 2
                print("🔄 [SVGImporter] Triangle '\(triangleID)' in manifest but missing from app - queuing for creation")
                // Add to new triangles for Phase 2
                // (We'll handle this by not filtering it out - but it's already filtered)
            }
        }
        
        // ============================================================
        // CLEANUP: Merge duplicate MapPoints at same position
        // ============================================================
        let duplicatesMerged = cleanupDuplicateMapPoints(
            mapPointStore: mapPointStore,
            triangleStore: triangleStore,
            zoneStore: zoneStore,
            thresholdPixels: 2.0  // 2 pixel tolerance
        )
        if duplicatesMerged > 0 {
            print("🧹 [SVGImporter] Merged \(duplicatesMerged) duplicate MapPoint(s)")
        }
        
        // ============================================================
        // PHASE 2: PROCESS NEW TRIANGLES (create after MapPoints settled)
        // ============================================================
        
        print("📋 [SVGImporter] Phase 2: Creating new triangles (MapPoints now stable)")
        
        // Create fresh resolver with current MapPointStore state
        let resolver = MapPointResolver(
            mapPointStore: mapPointStore,
            thresholdMeters: deduplicationThresholdMeters,
            pixelsPerMeter: CGFloat(pixelsPerMeter)
        )
        
        for rawTriangle in newTrianglesRaw {
            let triangleID = rawTriangle.id ?? "unnamed"
            
            print("🆕 [SVGImporter] New triangle: '\(triangleID)' - creating")
            
            // Resolve vertices to MapPoints (uses current, updated positions)
            var vertexIDs: [UUID] = []
            for vertex in rawTriangle.vertices {
                let resolved = resolver.resolve(vertex, roles: [.triangleEdge])
                vertexIDs.append(resolved)
            }
            
            // Check for collinearity
            if areCollinear(rawTriangle.vertices[0], rawTriangle.vertices[1], rawTriangle.vertices[2]) {
                warnings.append("Skipped collinear triangle '\(triangleID)' at (\(Int(rawTriangle.vertices[0].x)), \(Int(rawTriangle.vertices[0].y)))")
                print("⏭️ [SVGImporter] Triangle '\(triangleID)' is collinear - skipping")
                trianglesSkipped += 1
                continue
            }
            
            // Check if a triangle with these exact 3 vertices already exists
            let vertexSet = Set(vertexIDs)
            if let existingTriangle = triangleStore.triangles.first(where: { Set($0.vertexIDs) == vertexSet }) {
                // Update displayName if this is a custom name
                let svgID = rawTriangle.id ?? ""
                if !svgID.isEmpty && !isUUIDBasedName(svgID) {
                    if let index = triangleStore.triangles.firstIndex(where: { $0.id == existingTriangle.id }) {
                        triangleStore.triangles[index].displayName = svgID
                        print("📝 [SVGImporter] Updated triangle \(existingTriangle.id.uuidString.prefix(8)) displayName to '\(svgID)'")
                    }
                }
                print("⏭️ [SVGImporter] Triangle '\(triangleID)' has same vertices as existing - skipping")
                trianglesSkipped += 1
                continue
            }
            
            // Get vertex positions for overlap check
            guard let newPositions = getVertexPositions(vertexIDs, mapPointStore: mapPointStore) else {
                warnings.append("Could not get positions for triangle '\(triangleID)'")
                print("⚠️ [SVGImporter] Could not get positions for '\(triangleID)' - skipping")
                trianglesSkipped += 1
                continue
            }
            
            // Check for geometric overlap with existing triangles
            if hasGeometricOverlap(newPositions: newPositions, triangleStore: triangleStore, mapPointStore: mapPointStore) {
                warnings.append("Skipped overlapping triangle '\(triangleID)' at (\(Int(rawTriangle.vertices[0].x)), \(Int(rawTriangle.vertices[0].y)))")
                print("❌ [SVGImporter] Triangle '\(triangleID)' has geometric overlap - skipping")
                trianglesSkipped += 1
                continue
            }
            
            // Create the triangle
            let svgID = rawTriangle.id ?? ""
            let isCustomName = !svgID.isEmpty && !isUUIDBasedName(svgID)
            let displayName: String? = isCustomName ? svgID : nil
            
            let triangle = TrianglePatch(vertexIDs: vertexIDs, displayName: displayName)
            
            if let name = displayName {
                print("✅ [SVGImporter] Created triangle with displayName: '\(name)' → UUID: \(triangle.id.uuidString.prefix(8))")
            } else {
                print("✅ [SVGImporter] Created triangle: \(triangle.id.uuidString.prefix(8))")
            }
            
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
    
    /// Check if an SVG ID is UUID-based (e.g., "tri-3A598EFC..." or "tri-XXXXXXXX-XXXX-...")
    private func isUUIDBasedName(_ name: String) -> Bool {
        guard name.hasPrefix("tri-") else { return false }
        let suffix = String(name.dropFirst(4))
        // Check if it looks like a UUID (8+ hex chars or full UUID format)
        let hexChars = CharacterSet(charactersIn: "0123456789ABCDEFabcdef-")
        return suffix.unicodeScalars.allSatisfy { hexChars.contains($0) } && suffix.count >= 8
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
            
            // DIAGNOSTIC: Log position groups
            print("📊 [SPLIT] MapPoint \(analysis.mapPointID.prefix(8)) position groups:")
            for (key, diffs) in positionGroups {
                print("   Group '\(key)': \(diffs.count) triangles")
                for diff in diffs {
                    print("      - \(diff.sourcePolygonID): (\(String(format: "%.2f", diff.newPosition.x)), \(String(format: "%.2f", diff.newPosition.y)))")
                }
            }
            
            // Find which position is the "original" (matches manifest) vs "moved"
            let originalKey = "\(Int(analysis.originalPosition.x)),\(Int(analysis.originalPosition.y))"
            print("   Original position key: '\(originalKey)' (actual: (\(String(format: "%.2f", analysis.originalPosition.x)), \(String(format: "%.2f", analysis.originalPosition.y))))")
            
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
        // Match by displayName OR UUID (full or prefix)
        guard let index = triangleStore.triangles.firstIndex(where: { triangle in
            // Match by displayName if triangle has one
            if let displayName = triangle.displayName, displayName == triangleID {
                return true
            }
            // Match by full UUID format: "tri-{fullUUID}"
            if triangleID == "tri-\(triangle.id.uuidString)" {
                return true
            }
            // Match by 8-char UUID prefix format: "tri-{prefix}"
            let prefix8 = "tri-\(triangle.id.uuidString.prefix(8))"
            if prefix8 == triangleID {
                return true
            }
            return false
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
                displayName: updatedTriangle.displayName,
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
    
    // MARK: - Geometric Overlap Detection
    
    /// Get vertex positions from MapPointStore
    private func getVertexPositions(_ vertexIDs: [UUID], mapPointStore: MapPointStore) -> [CGPoint]? {
        var positions: [CGPoint] = []
        for id in vertexIDs {
            guard let point = mapPointStore.points.first(where: { $0.id == id }) else {
                return nil
            }
            positions.append(point.position)
        }
        return positions
    }
    
    /// Check if new triangle has geometric overlap with any existing triangle
    /// Uses proper edge intersection and strict point-in-triangle tests
    private func hasGeometricOverlap(
        newPositions: [CGPoint],
        triangleStore: TrianglePatchStore,
        mapPointStore: MapPointStore
    ) -> Bool {
        guard newPositions.count == 3 else { return true }
        
        for existingTriangle in triangleStore.triangles {
            guard let existingPositions = getVertexPositions(existingTriangle.vertexIDs, mapPointStore: mapPointStore),
                  existingPositions.count == 3 else {
                continue
            }
            
            // Check for proper edge-edge intersection
            if hasProperEdgeIntersection(newPositions, existingPositions) {
                print("      ❌ REJECT: Edge intersection with \(existingTriangle.id.uuidString.prefix(8))")
                return true
            }
            
            // Check for strict containment (vertex inside other triangle)
            if hasStrictContainment(newPositions, existingPositions) {
                print("      ❌ REJECT: Containment overlap with \(existingTriangle.id.uuidString.prefix(8))")
                return true
            }
            
            print("      ✅ No overlap with \(existingTriangle.id.uuidString.prefix(8))")
        }
        
        return false
    }
    
    /// Check if any edge of triangle A properly intersects any edge of triangle B
    /// "Proper" means intersection at interior point, not endpoint touch or collinear overlap
    private func hasProperEdgeIntersection(_ triA: [CGPoint], _ triB: [CGPoint]) -> Bool {
        let edgesA = [(triA[0], triA[1]), (triA[1], triA[2]), (triA[2], triA[0])]
        let edgesB = [(triB[0], triB[1]), (triB[1], triB[2]), (triB[2], triB[0])]
        
        for edgeA in edgesA {
            for edgeB in edgesB {
                if segmentsProperlyIntersect(edgeA.0, edgeA.1, edgeB.0, edgeB.1) {
                    return true
                }
            }
        }
        return false
    }
    
    /// Check if segments AB and CD properly intersect (at interior points, not endpoints)
    private func segmentsProperlyIntersect(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint, _ d: CGPoint) -> Bool {
        // Using cross product to determine orientation
        func cross(_ o: CGPoint, _ p: CGPoint, _ q: CGPoint) -> CGFloat {
            return (p.x - o.x) * (q.y - o.y) - (p.y - o.y) * (q.x - o.x)
        }
        
        let d1 = cross(c, d, a)
        let d2 = cross(c, d, b)
        let d3 = cross(a, b, c)
        let d4 = cross(a, b, d)
        
        // Check for proper intersection (opposite signs, not touching at endpoints)
        if ((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
           ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0)) {
            return true
        }
        
        // Note: We explicitly do NOT count endpoint touches as intersections
        // This allows shared vertices and shared edges
        
        return false
    }
    
    /// Check if any vertex of triangle A is strictly inside triangle B, or vice versa
    /// "Strictly inside" means interior only, not on boundary
    private func hasStrictContainment(_ triA: [CGPoint], _ triB: [CGPoint]) -> Bool {
        // Check A's vertices in B
        for vertex in triA {
            if isStrictlyInsideTriangle(vertex, triB) {
                return true
            }
        }
        
        // Check B's vertices in A
        for vertex in triB {
            if isStrictlyInsideTriangle(vertex, triA) {
                return true
            }
        }
        
        return false
    }
    
    /// Check if point P is strictly inside triangle (interior only, not on boundary)
    private func isStrictlyInsideTriangle(_ p: CGPoint, _ triangle: [CGPoint]) -> Bool {
        guard triangle.count == 3 else { return false }
        
        let a = triangle[0]
        let b = triangle[1]
        let c = triangle[2]
        
        // Compute barycentric coordinates
        let v0 = CGPoint(x: c.x - a.x, y: c.y - a.y)
        let v1 = CGPoint(x: b.x - a.x, y: b.y - a.y)
        let v2 = CGPoint(x: p.x - a.x, y: p.y - a.y)
        
        let dot00 = v0.x * v0.x + v0.y * v0.y
        let dot01 = v0.x * v1.x + v0.y * v1.y
        let dot02 = v0.x * v2.x + v0.y * v2.y
        let dot11 = v1.x * v1.x + v1.y * v1.y
        let dot12 = v1.x * v2.x + v1.y * v2.y
        
        let invDenom = 1.0 / (dot00 * dot11 - dot01 * dot01)
        let u = (dot11 * dot02 - dot01 * dot12) * invDenom
        let v = (dot00 * dot12 - dot01 * dot02) * invDenom
        
        // Strictly inside means all barycentric coords > 0 (not >= 0)
        // Using small epsilon to account for floating point
        let epsilon: CGFloat = 0.0001
        return (u > epsilon) && (v > epsilon) && (u + v < 1.0 - epsilon)
    }
    
    // MARK: - Duplicate MapPoint Cleanup
    
    /// Find and merge MapPoints at the same position
    /// Returns number of duplicates merged
    private func cleanupDuplicateMapPoints(
        mapPointStore: MapPointStore,
        triangleStore: TrianglePatchStore,
        zoneStore: ZoneStore,
        thresholdPixels: CGFloat
    ) -> Int {
        var mergedCount = 0
        var indicesToRemove: [Int] = []
        
        // Find duplicates
        for i in 0..<mapPointStore.points.count {
            if indicesToRemove.contains(i) { continue }
            
            for j in (i+1)..<mapPointStore.points.count {
                if indicesToRemove.contains(j) { continue }
                
                let p1 = mapPointStore.points[i]
                let p2 = mapPointStore.points[j]
                
                let dx = p1.position.x - p2.position.x
                let dy = p1.position.y - p2.position.y
                let distance = sqrt(dx * dx + dy * dy)
                
                if distance < thresholdPixels {
                    // Found duplicate - merge j into i (keep older/more calibrated)
                    let keepIndex: Int
                    let deleteIndex: Int
                    
                    // Prefer the one with more calibration data, then older
                    if p1.canonicalSampleCount >= p2.canonicalSampleCount {
                        keepIndex = i
                        deleteIndex = j
                    } else {
                        keepIndex = j
                        deleteIndex = i
                    }
                    
                    let keepID = mapPointStore.points[keepIndex].id
                    let deleteID = mapPointStore.points[deleteIndex].id
                    
                    print("🔀 [SVGImporter] Merging duplicate MapPoint \(deleteID.uuidString.prefix(8)) into \(keepID.uuidString.prefix(8))")
                    
                    // Merge data
                    mergeMapPointData(
                        from: deleteIndex,
                        into: keepIndex,
                        mapPointStore: mapPointStore
                    )
                    
                    // Update triangle references
                    updateAllTriangleReferences(
                        from: deleteID,
                        to: keepID,
                        triangleStore: triangleStore
                    )
                    
                    // Update zone references
                    updateAllZoneReferences(
                        from: deleteID,
                        to: keepID,
                        zoneStore: zoneStore
                    )
                    
                    indicesToRemove.append(deleteIndex)
                    mergedCount += 1
                }
            }
        }
        
        // Remove duplicates (in reverse order to preserve indices)
        for index in indicesToRemove.sorted().reversed() {
            mapPointStore.points.remove(at: index)
        }
        
        return mergedCount
    }
    
    /// Merge data from one MapPoint into another
    private func mergeMapPointData(from sourceIndex: Int, into targetIndex: Int, mapPointStore: MapPointStore) {
        let source = mapPointStore.points[sourceIndex]
        
        // Merge triangle memberships
        for membership in source.triangleMemberships {
            if !mapPointStore.points[targetIndex].triangleMemberships.contains(membership) {
                mapPointStore.points[targetIndex].triangleMemberships.append(membership)
            }
        }
        
        // Merge roles
        for role in source.roles {
            mapPointStore.points[targetIndex].roles.insert(role)
        }
        
        // Keep name if target doesn't have one
        if mapPointStore.points[targetIndex].name == nil && source.name != nil {
            mapPointStore.points[targetIndex].name = source.name
        }
        
        // Merge AR position history
        mapPointStore.points[targetIndex].arPositionHistory.append(contentsOf: source.arPositionHistory)
        
        // If source has calibration but target doesn't, use source's
        if mapPointStore.points[targetIndex].canonicalPosition == nil && source.canonicalPosition != nil {
            mapPointStore.points[targetIndex].canonicalPosition = source.canonicalPosition
            mapPointStore.points[targetIndex].canonicalConfidence = source.canonicalConfidence
            mapPointStore.points[targetIndex].canonicalSampleCount = source.canonicalSampleCount
        }
    }
    
    /// Update all triangles that reference oldID to reference newID
    private func updateAllTriangleReferences(from oldID: UUID, to newID: UUID, triangleStore: TrianglePatchStore) {
        for i in 0..<triangleStore.triangles.count {
            var triangle = triangleStore.triangles[i]
            var updated = false
            
            var updatedVertexIDs = triangle.vertexIDs
            for j in 0..<updatedVertexIDs.count {
                if updatedVertexIDs[j] == oldID {
                    updatedVertexIDs[j] = newID
                    updated = true
                }
            }
            
            if updated {
                // Rebuild triangle with updated vertexIDs
                triangleStore.triangles[i] = TrianglePatch(
                    id: triangle.id,
                    displayName: triangle.displayName,
                    vertexIDs: updatedVertexIDs,
                    isCalibrated: triangle.isCalibrated,
                    calibrationQuality: triangle.calibrationQuality,
                    transform: triangle.transform,
                    createdAt: triangle.createdAt,
                    lastCalibratedAt: triangle.lastCalibratedAt,
                    arMarkerIDs: triangle.arMarkerIDs,
                    userPositionWhenCalibrated: triangle.userPositionWhenCalibrated,
                    legMeasurements: triangle.legMeasurements,
                    worldMapFilename: triangle.worldMapFilename,
                    worldMapFilesByStrategy: triangle.worldMapFilesByStrategy,
                    lastStartingVertexIndex: triangle.lastStartingVertexIndex
                )
                print("   📝 Updated triangle \(triangle.id.uuidString.prefix(8)) vertex: \(oldID.uuidString.prefix(8)) → \(newID.uuidString.prefix(8))")
            }
        }
    }
    
    /// Update all zones that reference oldID to reference newID
    private func updateAllZoneReferences(from oldID: UUID, to newID: UUID, zoneStore: ZoneStore) {
        let oldIDString = oldID.uuidString
        let newIDString = newID.uuidString
        
        for i in 0..<zoneStore.zones.count {
            var zone = zoneStore.zones[i]
            
            if let cornerIndex = zone.cornerMapPointIDs.firstIndex(of: oldIDString) {
                zone.cornerMapPointIDs[cornerIndex] = newIDString
                zoneStore.zones[i] = zone
                print("   📝 Updated zone '\(zone.id)' corner: \(oldIDString.prefix(8)) → \(newIDString.prefix(8))")
            }
        }
    }
}
