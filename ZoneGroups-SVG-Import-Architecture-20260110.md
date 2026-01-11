# Zone Groups & SVG Import Architecture
**Date:** January 10, 2026  
**Status:** Pre-Implementation Design Document

---

## Executive Summary

Adding hierarchical zone organization (ZoneGroups containing Zones) and bidirectional SVG interchange with Adobe Illustrator. All spatial entities ultimately reference MapPoints as the atomic coordinate primitive.

---

## Current State Analysis

### What Exists

| Component | Status | Storage Key | Notes |
|-----------|--------|-------------|-------|
| MapPoint | ✅ Complete | `MapPoints_v1` | Has `roles: Set<MapPointRole>`, includes `.zoneCorner` |
| MapPointRole | ✅ Complete | — | Enum with `.triangleEdge`, `.zoneCorner`, etc. |
| Zone | ⚠️ Needs Update | `zones_{locationID}` | **Limited to exactly 4 corners** |
| ZoneGroup | ❌ Missing | — | Does not exist |
| TrianglePatch | ✅ Complete | `triangles_v1` | References MapPoint IDs |
| SVG Export | ✅ Exists | — | `SVGDocument`, `SVGExporter` |
| SVG Import | ❌ Missing | — | No parser exists |
| CodableColor | ❌ Missing | — | Need for ZoneGroup colors |

### Critical Finding: Zone Corner Limitation

Current `Zone` struct enforces exactly 4 corners:

```swift
public struct Zone: Identifiable, Codable, Equatable {
    public var cornerIDs: [UUID]  // "4 MapPoint IDs in CCW order" per comment
    
    public var isValid: Bool {
        cornerIDs.count == 4  // ← HARD-CODED LIMIT
    }
}
```

**Problem:** SVG zones are arbitrary polygons (3-20+ vertices). Must remove this limitation.

---

## Proposed Data Model

### ZoneGroup (NEW)

```swift
/// Organizational container for related zones
/// Example: "Evolving Life" group contains 10 zones
public struct ZoneGroup: Codable, Identifiable, Equatable {
    public let id: String                   // "evolvingLife-zones" (from SVG)
    public var displayName: String          // "Evolving Life Zones"
    public var colorHex: String             // "#3154ff"
    public var zoneIDs: [String]            // Ordered list of zone IDs in this group
    public var createdAt: Date
    public var modifiedAt: Date
    
    public init(
        id: String,
        displayName: String,
        colorHex: String,
        zoneIDs: [String] = [],
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.displayName = displayName
        self.colorHex = colorHex
        self.zoneIDs = zoneIDs
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
    
    /// SwiftUI Color from hex string
    public var color: Color {
        Color(hex: colorHex) ?? .gray
    }
}
```

### Zone (UPDATED)

```swift
public struct Zone: Identifiable, Codable, Equatable {
    // CHANGED: String ID instead of UUID for human-readable SVG IDs
    public let id: String                   // "dunk-theater" (from SVG, or UUID string)
    public var displayName: String          // "Dunk Theater"
    
    // CHANGED: Now String to match MapPoint ID format flexibility
    public var cornerMapPointIDs: [String]  // N MapPoint IDs in order (no longer limited to 4)
    
    // NEW: Group membership
    public var groupID: String?             // "evolvingLife-zones" or nil if ungrouped
    
    // CHANGED: String IDs for triangles
    public var memberTriangleIDs: [String]  // Triangles overlapping this zone
    
    // Existing fields preserved
    public var lastStartingCornerIndex: Int?
    public var isLocked: Bool
    public var createdAt: Date
    public var modifiedAt: Date
    
    /// Zone is valid if it has at least 3 corners (minimum polygon)
    public var isValid: Bool {
        cornerMapPointIDs.count >= 3  // CHANGED from == 4
    }
    
    /// Get corner positions from MapPointStore
    public func corners(from store: MapPointStore) -> [CGPoint] {
        cornerMapPointIDs.compactMap { idString in
            guard let uuid = UUID(uuidString: idString) else { return nil }
            return store.point(for: uuid)?.position
        }
    }
}
```

### ID Strategy

| Entity | ID Type | Format | Example |
|--------|---------|--------|---------|
| MapPoint | UUID | Standard UUID | `E325D867-...` |
| Zone | String | Human-readable or UUID | `dunk-theater` or `A1B2C3D4-...` |
| ZoneGroup | String | Human-readable | `evolvingLife-zones` |
| TrianglePatch | UUID | Standard UUID | `F8FF09C8-...` |

**Rationale:** MapPoints are too numerous for human tracking (UUID). Zones and groups benefit from readable IDs for SVG interchange and debugging.

---

## Storage Architecture

### Keys

| Store | Key Pattern | Example |
|-------|-------------|---------|
| ZoneGroupStore | `ZoneGroups_v1` | `locations.museum.ZoneGroups_v1` |
| ZoneStore | `Zones_v2` | `locations.museum.Zones_v2` (new version) |
| MapPointStore | `MapPoints_v1` | `locations.museum.MapPoints_v1` (unchanged) |
| TrianglePatchStore | `triangles_v1` | `locations.museum.triangles_v1` (unchanged) |

### Migration

Existing zones (v1) use UUID IDs and require exactly 4 corners. Migration:

1. Convert UUID to String (`.uuidString`)
2. Keep `cornerIDs` array (rename to `cornerMapPointIDs`)
3. Add `groupID = nil` (ungrouped)
4. Add `displayName` (parse from existing `name` or generate)

---

## SVG Structure (Canonical Format)

### Export Format (App → Illustrator)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<svg id="museum-map" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 8192 8192">
  <defs>
    <style>
      .evolvinglife { fill: #3154ff; opacity: 0.2; }
      .dynamicEarth { fill: #0000ff; opacity: 0.2; }
      /* ... other group styles ... */
    </style>
  </defs>
  
  <!-- Background map image -->
  <image id="map-background" width="8192" height="8192" xlink:href="map.png"/>
  
  <!-- Zone Groups -->
  <g id="zones">
    <g id="evolvingLife-zones">
      <polygon id="Dunk Theater" class="evolvinglife" points="3532.4,7055.6 3532.4,6967.4 ..."/>
      <polygon id="Urban Evo" class="evolvinglife" points="3948.3,7424.4 4064,6947.8 ..."/>
    </g>
    <g id="dynamicEarth-zones">
      <polygon id="T-Rex Zone" class="dynamicEarth" points="2827,1160.3 2966.4,2055.1 ..."/>
    </g>
  </g>
  
  <!-- Triangles (separate layer) -->
  <g id="triangles">
    <polygon id="tri-E325D867" class="calibrated" points="..."/>
    <polygon id="tri-F8FF09C8" class="uncalibrated" points="..."/>
  </g>
  
  <!-- Future: Beacons, MapPoints, Walls, etc. -->
</g>
</svg>
```

### Import Parsing Rules

1. **Zone Groups:** `<g>` elements whose ID ends with `-zones`
2. **Zones:** `<polygon>` elements inside zone groups
3. **Zone ID:** Element `id` attribute (spaces allowed in Illustrator)
4. **Zone Display Name:** Same as ID (preserved as-is)
5. **Zone Code ID:** Generated from display name (`"Dunk Theater"` → `"dunk-theater"`)
6. **Group Color:** Extracted from CSS class in `<defs>` or computed from class name

### Illustrator Round-Trip Considerations

| What Illustrator Does | How We Handle It |
|----------------------|------------------|
| Mangles CSS classes to `st0`, `st1`, etc. | Ignore classes; derive group from DOM hierarchy |
| Preserves `id` attributes | ✅ Use for zone identification |
| Preserves `<g>` hierarchy | ✅ Use for group membership |
| Preserves `<defs>` block | Parse for colors if present |
| May reorder elements | Zone order derived from DOM order |

---

## MapPoint Deduplication

### The Problem

SVG import provides raw coordinates. Multiple zones may share corners. We must:
1. Avoid creating duplicate MapPoints at the same location
2. Match imported coordinates to existing MapPoints
3. Assign appropriate roles to matched/new MapPoints

### Threshold

**0.5 meters** - Points within this distance are considered the same.

Requires pixel-to-meter conversion from MetricSquare:
```swift
let pixelsPerMeter = metricSquare.side / metricSquare.meters
let thresholdPixels = 0.5 * pixelsPerMeter
```

### Algorithm

```swift
struct MapPointResolver {
    let store: MapPointStore
    let thresholdPixels: CGFloat
    
    // Cache for batch deduplication within single import
    private var resolvedPoints: [String: CGPoint] = [:]  // pointID -> position
    
    /// Find existing MapPoint within threshold, or nil
    func findExisting(near point: CGPoint) -> MapPoint? {
        store.points.first { existing in
            let dx = existing.position.x - point.x
            let dy = existing.position.y - point.y
            let distance = sqrt(dx*dx + dy*dy)
            return distance < thresholdPixels
        }
    }
    
    /// Find already-resolved point within threshold (for batch import)
    func findInBatch(near point: CGPoint) -> String? {
        for (id, resolved) in resolvedPoints {
            let dx = resolved.x - point.x
            let dy = resolved.y - point.y
            let distance = sqrt(dx*dx + dy*dy)
            if distance < thresholdPixels {
                return id
            }
        }
        return nil
    }
    
    /// Resolve coordinate to MapPoint ID (find existing, find in batch, or create new)
    mutating func resolve(_ point: CGPoint, role: MapPointRole) -> String {
        // 1. Check existing MapPoints
        if let existing = findExisting(near: point) {
            store.assignRole(role, to: existing.id)
            resolvedPoints[existing.id.uuidString] = existing.position
            return existing.id.uuidString
        }
        
        // 2. Check batch cache (other corners from this import)
        if let batchID = findInBatch(near: point) {
            // Already resolved in this import batch
            return batchID
        }
        
        // 3. Create new MapPoint
        let newPoint = store.createPoint(at: point, roles: [role])
        resolvedPoints[newPoint.id.uuidString] = point
        return newPoint.id.uuidString
    }
}
```

---

## Triangle Membership Calculation

### Rule

A triangle is a member of a zone if **any portion** of the triangle's area overlaps the zone's polygon area.

### Algorithm Options

| Method | Accuracy | Complexity | Performance |
|--------|----------|------------|-------------|
| Vertex inside polygon | Low (misses edge cases) | Simple | O(n) |
| Centroid inside polygon | Low (misses partial overlap) | Simple | O(n) |
| Bounding box intersection | Medium (false positives) | Simple | O(1) |
| **Polygon intersection** | **Exact** | Complex | O(n×m) |

**Recommendation:** Polygon intersection using Sutherland-Hodgman clipping. For 46 zones × 34 triangles = 1,564 tests. Each test is O(vertices). Total: <1 second.

### Implementation

```swift
struct PolygonIntersection {
    /// Returns true if polygons have any overlapping area
    static func hasOverlap(_ poly1: [CGPoint], _ poly2: [CGPoint]) -> Bool {
        // Quick reject: bounding boxes don't overlap
        guard boundingBoxesOverlap(poly1, poly2) else { return false }
        
        // Sutherland-Hodgman: clip poly1 by each edge of poly2
        var clipped = poly1
        for i in 0..<poly2.count {
            let edgeStart = poly2[i]
            let edgeEnd = poly2[(i + 1) % poly2.count]
            clipped = clipPolygonByEdge(clipped, edgeStart: edgeStart, edgeEnd: edgeEnd)
            if clipped.isEmpty { return false }
        }
        
        // If anything remains after clipping, there's overlap
        return !clipped.isEmpty
    }
    
    private static func boundingBoxesOverlap(_ p1: [CGPoint], _ p2: [CGPoint]) -> Bool {
        let b1 = boundingBox(p1)
        let b2 = boundingBox(p2)
        return b1.intersects(b2)
    }
    
    private static func boundingBox(_ points: [CGPoint]) -> CGRect {
        guard let first = points.first else { return .zero }
        var minX = first.x, maxX = first.x
        var minY = first.y, maxY = first.y
        for p in points.dropFirst() {
            minX = min(minX, p.x); maxX = max(maxX, p.x)
            minY = min(minY, p.y); maxY = max(maxY, p.y)
        }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
    
    private static func clipPolygonByEdge(_ polygon: [CGPoint], edgeStart: CGPoint, edgeEnd: CGPoint) -> [CGPoint] {
        // Sutherland-Hodgman edge clipping
        // ... implementation details ...
    }
}
```

### Auto-Assignment Flow

```swift
func assignTriangleMembership(zones: inout [Zone], triangles: [TrianglePatch], mapPointStore: MapPointStore) {
    for i in 0..<zones.count {
        let zoneCorners = zones[i].corners(from: mapPointStore)
        var memberIDs: [String] = []
        
        for triangle in triangles {
            let triCorners = triangle.vertexIDs.compactMap { id in
                mapPointStore.point(for: id)?.position
            }
            guard triCorners.count == 3 else { continue }
            
            if PolygonIntersection.hasOverlap(zoneCorners, triCorners) {
                memberIDs.append(triangle.id.uuidString)
            }
        }
        
        zones[i].memberTriangleIDs = memberIDs
    }
}
```

---

## SVG Parser Design

### XMLParser Delegate

```swift
class ZoneSVGParser: NSObject, XMLParserDelegate {
    
    // Results
    var zoneGroups: [ZoneGroup] = []
    var zones: [Zone] = []
    var styles: [String: String] = [:]  // className -> colorHex
    
    // Parsing state
    private var currentGroupID: String?
    private var currentGroupDisplayName: String?
    private var inDefsBlock = false
    private var inStyleBlock = false
    private var styleContent = ""
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, 
                namespaceURI: String?, qualifiedName: String?, 
                attributes: [String: String] = [:]) {
        
        switch elementName {
        case "defs":
            inDefsBlock = true
            
        case "style" where inDefsBlock:
            inStyleBlock = true
            styleContent = ""
            
        case "g":
            if let id = attributes["id"], id.hasSuffix("-zones") {
                currentGroupID = id
                currentGroupDisplayName = id
                    .replacingOccurrences(of: "-zones", with: "")
                    .asDisplayName
            }
            
        case "polygon":
            guard let currentGroupID = currentGroupID,
                  let id = attributes["id"],
                  let pointsString = attributes["points"] else { return }
            
            let corners = parsePoints(pointsString)
            let displayName = id  // Preserve spaces from Illustrator
            let codeID = id.asCodeID
            let cssClass = attributes["class"]
            
            let zone = Zone(
                id: codeID,
                displayName: displayName,
                cornerMapPointIDs: [],  // Populated during MapPoint resolution
                groupID: currentGroupID,
                memberTriangleIDs: [],
                isLocked: false,
                createdAt: Date(),
                modifiedAt: Date()
            )
            
            zones.append(zone)
            
            // Store raw corners for later MapPoint resolution
            rawCornersByZoneID[codeID] = corners
            
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName: String?) {
        
        switch elementName {
        case "style" where inStyleBlock:
            inStyleBlock = false
            parseCSS(styleContent)
            
        case "defs":
            inDefsBlock = false
            
        case "g" where currentGroupID != nil:
            // Finalize group
            let zonesInGroup = zones.filter { $0.groupID == currentGroupID }
            let colorHex = styles[currentGroupID!.replacingOccurrences(of: "-zones", with: "")] ?? "#808080"
            
            let group = ZoneGroup(
                id: currentGroupID!,
                displayName: currentGroupDisplayName!,
                colorHex: colorHex,
                zoneIDs: zonesInGroup.map { $0.id }
            )
            zoneGroups.append(group)
            
            currentGroupID = nil
            currentGroupDisplayName = nil
            
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if inStyleBlock {
            styleContent += string
        }
    }
    
    // MARK: - Helpers
    
    private func parsePoints(_ string: String) -> [CGPoint] {
        // "3532.4,7055.6 3532.4,6967.4 ..." or "3532.4 7055.6 3532.4 6967.4 ..."
        let cleaned = string.replacingOccurrences(of: ",", with: " ")
        let components = cleaned.split(separator: " ").compactMap { Double($0) }
        
        var points: [CGPoint] = []
        for i in stride(from: 0, to: components.count - 1, by: 2) {
            points.append(CGPoint(x: components[i], y: components[i + 1]))
        }
        return points
    }
    
    private func parseCSS(_ css: String) {
        // Parse ".evolvinglife { fill: #3154ff; ... }"
        let pattern = #"\.(\w+)\s*\{[^}]*fill:\s*([#\w]+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
        
        let range = NSRange(css.startIndex..., in: css)
        for match in regex.matches(in: css, range: range) {
            if let classRange = Range(match.range(at: 1), in: css),
               let colorRange = Range(match.range(at: 2), in: css) {
                let className = String(css[classRange])
                let color = String(css[colorRange])
                styles[className] = color
            }
        }
    }
}
```

---

## Import Flow (Complete)

```
┌─────────────────────────────────────────────────────────────────┐
│  1. PARSE SVG                                                   │
│     └── XMLParser extracts groups, zones, raw coordinates       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  2. RESOLVE MAPPOINTS                                           │
│     For each zone's raw corners:                                │
│     ├── Find existing MapPoint within 0.5m → use it, add role   │
│     ├── Find batch-resolved point within 0.5m → reuse ID        │
│     └── Create new MapPoint with .zoneCorner role               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  3. BUILD ZONE OBJECTS                                          │
│     └── Replace raw corners with resolved MapPoint IDs          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  4. CALCULATE TRIANGLE MEMBERSHIP                               │
│     For each zone:                                              │
│     └── For each triangle: if polygon overlap → add to members  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  5. PERSIST                                                     │
│     ├── ZoneGroupStore.save()                                   │
│     ├── ZoneStore.save()                                        │
│     └── MapPointStore.save() (new points and role updates)      │
└─────────────────────────────────────────────────────────────────┘
```

---

## Files to Create/Modify

### New Files

| File | Purpose |
|------|---------|
| `State/ZoneGroup.swift` | ZoneGroup struct |
| `State/ZoneGroupStore.swift` | Persistence and management |
| `Utils/SVGImporter.swift` | SVG parsing and import orchestration |
| `Utils/MapPointResolver.swift` | Coordinate deduplication |
| `Utils/PolygonIntersection.swift` | Triangle membership calculation |
| `Utils/Color+Hex.swift` | Color ↔ hex string conversion |

### Modified Files

| File | Changes |
|------|---------|
| `State/Zone.swift` | Remove 4-corner limit, add String IDs, add groupID |
| `State/ZoneStore.swift` | Update persistence key, migration from v1 |
| `State/MapPointStore.swift` | Add `findNear(point:threshold:)` method |
| `UI/Panels/SVGExportPanel.swift` | Add import button/flow |

---

## Implementation Phases

### Phase 1: Data Model Foundation
1. Create `ZoneGroup` struct
2. Update `Zone` struct (remove 4-corner limit, String IDs)
3. Create `ZoneGroupStore`
4. Update `ZoneStore` with migration
5. Add `Color+Hex` extension

### Phase 2: MapPoint Resolution
1. Add `findNear(point:threshold:)` to MapPointStore
2. Create `MapPointResolver` for batch deduplication
3. Add `createPoint(at:roles:)` convenience method

### Phase 3: SVG Import
1. Create `ZoneSVGParser` (XMLParser delegate)
2. Create `SVGImporter` orchestration class
3. Wire up to UI (import button in settings/export panel)

### Phase 4: Triangle Membership
1. Create `PolygonIntersection` utility
2. Add membership calculation to import flow
3. Add UI for manual membership editing

### Phase 5: SVG Export Update
1. Update `SVGDocument` to export zone groups
2. Match canonical format for round-trip compatibility

---

## Testing Checklist

### Unit Tests

- [ ] `ZoneGroup` encoding/decoding
- [ ] `Zone` encoding/decoding (with String IDs)
- [ ] Zone migration from v1 to v2
- [ ] SVG points parsing (comma and space formats)
- [ ] CSS color extraction
- [ ] MapPoint deduplication within threshold
- [ ] Polygon intersection (overlapping, adjacent, disjoint)

### Integration Tests

- [ ] Import provided `museum-map-zones-2026-01-10-v03.svg`
- [ ] Verify 13 zone groups created
- [ ] Verify 47 zones created
- [ ] Verify MapPoints created/reused correctly
- [ ] Verify triangle membership calculated
- [ ] Export and verify round-trip fidelity

### Manual Tests

- [ ] Import SVG, view zones on map
- [ ] Edit zone membership manually
- [ ] Export, edit in Illustrator, re-import
- [ ] Zone colors display correctly
- [ ] Group hierarchy visible in UI

---

## Decisions (Resolved)

### 1. Zone v1 Migration
**Decision:** Delete existing zones. Fresh start. MapPoint position history to AR Markers is preserved separately. Early enough in development that recalibration is trivial.

### 2. UI for Zone Groups
**Decision:** Collapsible sections. Each ZoneGroup is a collapsible header containing its zones. Zones cannot belong to multiple groups. Membership editing within zones.

### 3. Conflict Resolution on Import
**Decision:** Hierarchical checks:

```
┌─────────────────────────────────────────────────────────────────┐
│  Import zone "dunk-theater"                                     │
│                                                                 │
│  1. Existing zone with same ID?                                 │
│     ├── YES: Are MapPoints identical?                           │
│     │        ├── YES → Skip import, keep existing               │
│     │        └── NO  → Continue to step 2                       │
│     └── NO  → Create new zone                                   │
│                                                                 │
│  2. Check spatial relationship to intended ZoneGroup:           │
│     ├── Near/contiguous to other zones in group?                │
│     │        ├── YES → Favor import (update shape)              │
│     │        └── NO  → Error: "Zone not contiguous to group"    │
│     │                  Reject import                            │
│                                                                 │
│  Future: Visual overlay comparison before overwrite             │
└─────────────────────────────────────────────────────────────────┘
```

### 4. Triangle Membership UI
**Decision:** Repurpose existing Swath Editor. Frame all triangles, allow select/deselect for zone membership. Swath concept is mostly deprecated; this gives it new purpose as Zone Editor.

---

## Appendix: Name Parsing

```swift
extension String {
    /// "Dunk Theater" → "dunk-theater"
    var asCodeID: String {
        self.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "_", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "-" }
    }
    
    /// "dunk-theater" → "Dunk Theater"
    var asDisplayName: String {
        self.split(separator: "-")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }
}
```

## Appendix: Color+Hex

```swift
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        guard hexSanitized.count == 6,
              let rgb = UInt64(hexSanitized, radix: 16) else {
            return nil
        }
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
    
    var hexString: String {
        // Convert to UIColor to extract components
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let ri = Int(r * 255)
        let gi = Int(g * 255)
        let bi = Int(b * 255)
        
        return String(format: "#%02X%02X%02X", ri, gi, bi)
    }
}
```
