# TapResolver SVG Round-Trip System

## Overview

The SVG round-trip system enables exporting spatial calibration data (triangles, zones, MapPoints) to Adobe Illustrator-compatible SVG files, editing them externally, and re-importing with intelligent change detection. This supports the "design in Illustrator, calibrate in AR" workflow.

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              EXPORT FLOW                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌───────────┐ │
│  │ MapPointStore│    │TrianglePatch │    │  ZoneStore   │    │ZoneGroup  │ │
│  │   .points    │    │    Store     │    │   .zones     │    │   Store   │ │
│  └──────┬───────┘    └──────┬───────┘    └──────┬───────┘    └─────┬─────┘ │
│         │                   │                   │                  │       │
│         └───────────────────┴───────────────────┴──────────────────┘       │
│                                     │                                       │
│                                     ▼                                       │
│                          ┌──────────────────┐                              │
│                          │  SVGManifest     │                              │
│                          │   .build()       │                              │
│                          └────────┬─────────┘                              │
│                                   │                                        │
│                                   ▼                                        │
│                          ┌──────────────────┐                              │
│                          │   SVGDocument    │                              │
│                          │ (layer builder)  │                              │
│                          └────────┬─────────┘                              │
│                                   │                                        │
│                                   ▼                                        │
│                     ┌─────────────────────────┐                            │
│                     │ SVGIllustratorFormatter │                            │
│                     │  (post-processing)      │                            │
│                     └───────────┬─────────────┘                            │
│                                 │                                          │
│                                 ▼                                          │
│                          ┌─────────────┐                                   │
│                          │  .svg file  │                                   │
│                          └─────────────┘                                   │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                              IMPORT FLOW                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│                          ┌─────────────┐                                   │
│                          │  .svg file  │                                   │
│                          └──────┬──────┘                                   │
│                                 │                                          │
│              ┌──────────────────┼──────────────────┐                       │
│              │                  │                  │                       │
│              ▼                  ▼                  ▼                       │
│     ┌────────────────┐ ┌────────────────┐ ┌────────────────┐              │
│     │TriangleSVGParser│ │ ZoneSVGParser │ │ SVGManifest    │              │
│     │ (XMLParser)    │ │ (XMLParser)   │ │  .extract()    │              │
│     └───────┬────────┘ └───────┬────────┘ └───────┬────────┘              │
│             │                  │                  │                       │
│             ▼                  ▼                  ▼                       │
│     ┌────────────────┐ ┌────────────────┐ ┌────────────────┐              │
│     │  RawTriangle[] │ │   RawZone[]   │ │ ImportDiffReport│              │
│     │  (CGPoints)    │ │  (CGPoints)   │ │ (detected edits)│              │
│     └───────┬────────┘ └───────┬────────┘ └───────┬────────┘              │
│             │                  │                  │                       │
│             └──────────────────┴──────────────────┘                       │
│                                │                                          │
│                                ▼                                          │
│                     ┌──────────────────────┐                              │
│                     │    SVGImporter       │                              │
│                     │  (orchestrator)      │                              │
│                     └──────────┬───────────┘                              │
│                                │                                          │
│              ┌─────────────────┼─────────────────┐                        │
│              │                 │                 │                        │
│              ▼                 ▼                 ▼                        │
│     ┌────────────────┐ ┌────────────────┐ ┌────────────────┐             │
│     │ MapPointResolver│ │ applyUnanimous │ │ applySplits    │             │
│     │ (deduplication)│ │    Moves()     │ │ (fork points)  │             │
│     └───────┬────────┘ └───────┬────────┘ └───────┬────────┘             │
│             │                  │                  │                       │
│             └──────────────────┴──────────────────┘                       │
│                                │                                          │
│                                ▼                                          │
│         ┌──────────────────────┼──────────────────────┐                   │
│         │                      │                      │                   │
│         ▼                      ▼                      ▼                   │
│  ┌──────────────┐     ┌───────────────┐     ┌──────────────┐             │
│  │ MapPointStore│     │TrianglePatch  │     │  ZoneStore   │             │
│  │  (updated)   │     │    Store      │     │  (updated)   │             │
│  └──────────────┘     └───────────────┘     └──────────────┘             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Coordinate System

All SVG operations use **Map Pixel** coordinates:
- Origin: Top-left of floor plan image
- Units: Pixels
- Y-axis: Positive downward (standard image coordinates)

The `pixelsPerMeter` scale factor (from MetricSquare) converts to real-world distances for deduplication thresholds.

---

## Component Reference

### 1. SVGDocument.swift

**Purpose:** Builds layered SVG documents with CSS styling, embedded images, and manifest data.

**Key Methods:**

| Method | Inputs | Output | Description |
|--------|--------|--------|-------------|
| `init(width:height:)` | CGFloat, CGFloat | SVGDocument | Creates document with canvas dimensions |
| `registerStyle(className:css:)` | String, String | void | Adds CSS class to `<defs>` |
| `setBackgroundImage(_:)` | UIImage | void | Embeds PNG as base64 `<image>` |
| `addLayer(id:content:)` | String, String | void | Adds `<g id="...">` with raw SVG content |
| `addCircleLayer(...)` | circles array, styleClass | void | Batch-adds circles with CSS class |
| `addManifestLayer(_:)` | JSON String | void | Embeds manifest as hidden `<text>` element |
| `generateSVG()` | — | String | Produces complete SVG markup |

**Layer Structure:**
```xml
<svg viewBox="0 0 W H">
  <defs><style>...</style></defs>
  <image id="map-background" .../>    <!-- embedded PNG -->
  <g id="triangles">...</g>
  <g id="zones">
    <g id="groupA-zones">...</g>
    <g id="groupB-zones">...</g>
  </g>
  <g id="data">                        <!-- hidden manifest -->
    <text class="dataClass">...</text>
  </g>
</svg>
```

---

### 2. SVGManifest.swift

**Purpose:** Embeds identity and position metadata in SVG for intelligent reimport.

**Data Structure:**
```json
{
  "tapResolver": {
    "version": "1.0",
    "exportedAt": "2025-01-21T10:30:00Z",
    "app": "TapResolver iOS 1.5",
    "device": "iPad"
  },
  "location": {
    "id": "CMNH-3N",
    "mapDimensions": [2048, 1536],
    "pixelsPerMeter": 42.5
  },
  "mapPoints": {
    "UUID-STRING": {
      "position": [1024.5, 768.2],
      "name": "Corner A",
      "roles": ["triangle_edge", "zone_corner"]
    }
  },
  "triangles": {
    "tri-rooster": {
      "id": "FULL-UUID-STRING",
      "displayName": "tri-rooster",
      "vertices": ["UUID-1", "UUID-2", "UUID-3"]
    }
  },
  "zones": {
    "Dunk Theater": {
      "displayName": "Dunk Theater",
      "groupID": "evolvingLife-zones",
      "corners": ["UUID-A", "UUID-B", "UUID-C", "UUID-D"]
    }
  }
}
```

**Key Methods:**

| Method | Inputs | Output | Description |
|--------|--------|--------|-------------|
| `build(...)` | location, mapPoints, triangles, zones | SVGManifest | Constructs manifest from app state |
| `encodeToJSON()` | — | String? | Pretty-printed JSON for embedding |
| `extract(from:)` | SVG String | SVGManifest? | Parses manifest from imported SVG |
| `detectChanges(...)` | zones, triangles, threshold | ImportDiffReport | Compares manifest to imported polygons |

**Change Detection Types:**

- **Unanimous Move:** All references to a MapPoint moved to the same new position → safe to update
- **Split Required:** References moved to different positions → need to fork the MapPoint

---

### 3. SVGIllustratorFormatter.swift

**Purpose:** Post-processes SVG to match Adobe Illustrator conventions for clean round-tripping.

**Transformations Applied:**

| Transformation | Before | After |
|----------------|--------|-------|
| CSS class names | `.triangleEdge` | `.st0` (with comment) |
| Polygon points | `x,y x,y x,y` | `x y x y x y x y` (closed) |
| Numbers | `1024.0` | `1024` |
| Hex colors | `#FF0000` | `#ff0000` |
| Opacity | `0.30` | `.3` |
| SVG root | `<svg ...>` | `<svg version="1.1" ...>` |

**Processing Flow:**
```
Input SVG → addVersionAttribute → transformCSSClasses → transformPolygonPoints → formatNumbers → Output SVG
```

---

### 4. TriangleSVGParser.swift

**Purpose:** XMLParser delegate that extracts triangle polygons from the `<g id="triangles">` layer.

**Inputs:**
- Raw SVG data

**Outputs:**
- `TriangleSVGParseResult`:
  - `triangles: [RawTriangle]` — parsed polygon data
  - `errors: [String]` — fatal issues
  - `warnings: [String]` — non-fatal issues
  - `manifest: SVGManifest?` — embedded metadata

**RawTriangle Structure:**
```swift
struct RawTriangle {
    let id: String?          // e.g., "tri-E325D867"
    let vertices: [CGPoint]  // Exactly 3 points in Map Pixel coords
}
```

**Layer Detection:**
- Looks for `<g id="triangles">` (case-insensitive)
- Only processes `<polygon>` elements inside that group
- Handles closed polygons (removes duplicate final vertex)

---

### 5. ZoneSVGParser.swift

**Purpose:** XMLParser delegate that extracts zone polygons from `<g id="zones">` with nested group structure.

**Expected SVG Structure:**
```xml
<g id="zones">
  <g id="evolvingLife-zones">
    <polygon id="Dunk Theater" class="evolvingLife" points="..."/>
    <polygon id="Butterfly Pavilion" class="evolvingLife" points="..."/>
  </g>
  <g id="discovery-zones">
    <polygon id="Fossil Lab" class="discovery" points="..."/>
  </g>
</g>
```

**Outputs:**
- `SVGParseResult`:
  - `groups: [RawZoneGroup]` — group metadata with color
  - `zones: [RawZone]` — polygon data with group membership
  - `cssStyles: [String: String]` — class → hex color mapping
  - `manifest: SVGManifest?`

**Color Assignment:**
1. Try CSS class from zone's `class` attribute
2. Try CSS class derived from group ID (e.g., `evolvingLife-zones` → `evolvingLife`)
3. Fall back to deterministic hash-based color from 12-color palette

---

### 6. SVGImporter.swift

**Purpose:** Orchestrates the complete import pipeline: parsing, MapPoint resolution, change detection, and entity creation.

**Key Methods:**

| Method | Purpose |
|--------|---------|
| `importZones(from:)` | Import zones and zone groups from SVG |
| `importTriangles(from:...)` | Import triangles from SVG |
| `applyUnanimousMoves(...)` | Update MapPoint positions for unanimous changes |
| `applySplits(...)` | Fork MapPoints when references moved to different positions |
| `cleanupDuplicateMapPoints(...)` | Merge MapPoints at same position after import |

**Import Pipeline (Triangles):**

```
1. Parse SVG → TriangleSVGParser → RawTriangle[]
2. Extract manifest (if present)
3. Detect changes via manifest.detectChanges()
4. Apply unanimous moves (update existing MapPoints)
5. Apply splits (fork MapPoints with conflicting references)
6. Create MapPointResolver for deduplication
7. For each RawTriangle:
   a. Check for existing triangle (by ID or vertex positions)
   b. Resolve vertices → get/create MapPoints
   c. Validate no overlapping triangles
   d. Create TrianglePatch
8. Cleanup duplicate MapPoints
9. Return TriangleSVGImportResult
```

**Deduplication Threshold:** 0.01 meters (1cm) — vertices within this distance share a MapPoint.

---

### 7. MapPointResolver (internal to SVGImporter)

**Purpose:** Resolves CGPoint positions to existing or new MapPoints with spatial deduplication.

**Algorithm:**
```
For each CGPoint to resolve:
  1. Search existing MapPoints within threshold distance
  2. If found: reuse existing UUID, add requested roles
  3. If not found: create new MapPoint with position and roles
  Return UUID array in same order as input points
```

---

### 8. SVGExportPanel.swift

**Purpose:** SwiftUI panel providing UI for export/import configuration.

**Export Options:**
- Map background (embedded PNG)
- Calibration mesh (MapPoints)
- RSSI heatmap (survey data)
- Triangles
- Zones
- Illustrator formatting

**Import Options:**
- Triangles toggle
- Zones toggle

---

### 9. SVGExportOptions.swift

**Purpose:** Observable state object tracking export configuration and filename generation.

**Filename Pattern:** `{locationID}-{layers}-{date}-v{version}.svg`

Example: `CMNH-3N-map-mesh-2025-01-21-v03.svg`

---

## Data Models

### TrianglePatch (TrianglePatch.swift)

Represents a calibration triangle in the TIN mesh.

**Key Fields:**
```swift
struct TrianglePatch: Codable, Identifiable {
    let id: UUID
    var displayName: String?           // e.g., "tri-rooster"
    let vertexIDs: [UUID]              // Exactly 3 MapPoint IDs (immutable)
    var isCalibrated: Bool
    var calibrationQuality: Float      // 0.0 (red) to 1.0 (green)
    var transform: Similarity2D?       // Map → AR floor plane
    var lastStartingVertexIndex: Int?  // For rotating starting vertex
}
```

**Note:** `vertexIDs` is a `let` constant. To update vertex references during merge operations, the entire TrianglePatch must be reconstructed using the full initializer.

### MapPoint (MapPointStore.swift)

Represents a spatial anchor point.

**Key Fields:**
```swift
struct MapPoint: Codable, Identifiable {
    let id: UUID
    var position: CGPoint              // Map Pixel coordinates
    var roles: Set<MapPointRole>       // .triangleEdge, .zoneCorner, etc.
    var name: String?
    var canonicalPosition: simd_float3? // Baked AR position
    var arPositionHistory: [ARPositionRecord]
    var triangleMemberships: [UUID]    // Triangle IDs using this point
}
```

### Zone (ZoneStore.swift)

Represents a calibration zone (quadrilateral).

**Key Fields:**
```swift
struct Zone: Codable, Identifiable {
    let id: String                     // Often the display name
    var displayName: String
    var cornerMapPointIDs: [String]    // 4 MapPoint UUID strings (CCW order)
    var groupID: String?               // Parent ZoneGroup
    var memberTriangleIDs: [String]    // Triangles inside this zone
}
```

---

## Extension Points

### Adding New Export Layers

1. Add toggle to `SVGExportOptions`
2. Add UI toggle to `SVGExportPanel`
3. Implement layer builder method in `SVGExportPanel` (e.g., `addBeaconLayer(...)`)
4. Call builder method in `performExport()` when toggle is enabled
5. Register any new CSS styles via `doc.registerStyle(...)`

### Adding New Import Entity Types

1. Create parser class (e.g., `BeaconSVGParser: NSObject, XMLParserDelegate`)
2. Define raw result struct (e.g., `RawBeacon`)
3. Add manifest section in `SVGManifest` and `SVGManifestBeacon`
4. Add resolution logic to `SVGImporter`
5. Add UI toggle to `SVGExportPanel` import section

### Custom Post-Processing

The `SVGIllustratorFormatter` is designed as a pure function. To add new transformations:

1. Add private static method (e.g., `transformFooElements(_:)`)
2. Chain it in the `format(_:)` method

---

## Known Limitations

1. **Polygon Vertex Order:** Import assumes vertices are in the same order as export. Vertex reordering in Illustrator may cause incorrect MapPoint matching.

2. **Single-Location Scope:** The manifest stores one location ID. Cross-location imports are not supported.

3. **No Undo for Splits:** When a MapPoint is split during import, there's no automatic way to merge them back.

4. **Manifest Required for Change Detection:** Importing an SVG without a manifest falls back to "legacy mode" with position-only matching.

5. **Nested Groups in Zones:** Only direct children of zone groups are parsed as zones. Deeper nesting is ignored with a warning.

---

## Fix Reference: updateAllTriangleReferences

**Problem:** `vertexIDs` on `TrianglePatch` is a `let` constant, making direct subscript mutation impossible.

**Solution:** Build a mutable copy of the array before modifying:

```swift
// Before (compile error)
for j in 0..<triangle.vertexIDs.count {
    if triangle.vertexIDs[j] == oldID {
        triangle.vertexIDs[j] = newID  // ❌ Cannot assign
    }
}

// After (working)
var updatedVertexIDs = triangle.vertexIDs
for j in 0..<updatedVertexIDs.count {
    if updatedVertexIDs[j] == oldID {
        updatedVertexIDs[j] = newID    // ✅ Works
    }
}
// Then use updatedVertexIDs when reconstructing TrianglePatch
```

This pattern applies whenever you need to update vertex references during merge or split operations.
