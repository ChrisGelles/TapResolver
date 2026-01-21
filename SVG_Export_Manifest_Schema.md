# SVG Export Manifest Schema

## Overview

When TapResolver exports an SVG file, it embeds a JSON manifest in a dedicated text layer. This manifest serves as a frozen snapshot of the app's data state at export time, enabling intelligent reimport that can detect user edits and update geometry accordingly.

**Key principle:** The manifest is machine data, not user-editable. Users edit the polygon geometry in Illustrator; the manifest provides the "before" state for comparison.

---

## Location in SVG

The manifest lives in a `<g>` element with `id="data"`, containing a `<text>` element with JSON content:

```xml
<g id="data">
  <text class="manifest" transform="translate(22.7 72.7)">
    <tspan x="0" y="0">{</tspan>
    <tspan x="0" y="21.6">  "tapResolver": {</tspan>
    <!-- ... JSON continues across tspan elements ... -->
  </text>
</g>
```

**Parsing note:** On import, concatenate all `<tspan>` text content within `<g id="data">` and parse as JSON.

---

## Schema Version

Current version: **1.0**

The `tapResolver.version` field enables future schema migrations.

---

## Complete Schema

```json
{
  "tapResolver": {
    "version": "1.0",
    "exportedAt": "2026-01-19T14:30:00Z",
    "app": "TapResolver iOS 1.0",
    "device": "iPhone"
  },
  
  "location": {
    "id": "museum",
    "mapDimensions": [8192, 8192],
    "pixelsPerMeter": 47.2
  },
  
  "mapPoints": {
    "E325D867-1A2B-3C4D-5E6F-7890ABCDEF12": { 
      "position": [3532.4, 7055.6], 
      "name": "Dunk NW",
      "roles": ["zoneCorner", "triangleEdge"]
    },
    "F5DE687B-1A2B-3C4D-5E6F-7890ABCDEF12": { 
      "position": [3532.4, 6967.4], 
      "name": null,
      "roles": ["triangleEdge"]
    }
  },
  
  "triangles": {
    "tri-E325D867": {
      "vertices": [
        "E325D867-1A2B-3C4D-5E6F-7890ABCDEF12",
        "F5DE687B-1A2B-3C4D-5E6F-7890ABCDEF12",
        "D8BF400C-1A2B-3C4D-5E6F-7890ABCDEF12"
      ]
    }
  },
  
  "zones": {
    "dunk-theater": {
      "displayName": "Dunk Theater",
      "groupID": "evolvingLife-zones",
      "corners": [
        "E325D867-1A2B-3C4D-5E6F-7890ABCDEF12",
        "F5DE687B-1A2B-3C4D-5E6F-7890ABCDEF12",
        "D8BF400C-1A2B-3C4D-5E6F-7890ABCDEF12",
        "AABBCCDD-1A2B-3C4D-5E6F-7890ABCDEF12"
      ]
    }
  }
}
```

---

## Field Definitions

### `tapResolver` — Export Metadata

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `version` | String | ✅ | Schema version for migration support |
| `exportedAt` | String (ISO8601) | ✅ | Export timestamp for conflict detection |
| `app` | String | ✅ | Source application and version |
| `device` | String | ✅ | Device type (e.g., "iPhone", "iPad") |

### `location` — Map Context

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | String | ✅ | Location identifier (e.g., "museum") |
| `mapDimensions` | [Int, Int] | ✅ | Map image size in pixels [width, height] |
| `pixelsPerMeter` | Float | ✅ | Scale factor from MetricSquare calibration |

### `mapPoints` — Vertex Registry

Dictionary keyed by MapPoint UUID string.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `position` | [Float, Float] | ✅ | Pixel coordinates [x, y] at export time |
| `name` | String \| null | ✅ | Optional user-assigned name |
| `roles` | [String] | ✅ | Array of roles (see MapPointRole values) |

**MapPointRole values:**
- `"zoneCorner"` — Vertex of a Zone polygon
- `"triangleEdge"` — Vertex of a Triangle
- `"surveyMarker"` — BLE survey location (deprecated on MapPoint)
- `"anchor"` — Fixed reference point

### `triangles` — Triangle Registry

Dictionary keyed by triangle ID (matches SVG polygon `id` attribute).

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `vertices` | [String, String, String] | ✅ | Three MapPoint UUIDs in vertex order |

**Triangle ID format:** `tri-{UUID-prefix}` (e.g., `tri-E325D867`)

### `zones` — Zone Registry

Dictionary keyed by zone code ID (matches SVG polygon `id` attribute).

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `displayName` | String | ✅ | Human-readable zone name |
| `groupID` | String \| null | ✅ | Parent ZoneGroup ID, or null if ungrouped |
| `corners` | [String ×4] | ✅ | Four MapPoint UUIDs in counter-clockwise order |

**Zone ID format:** Lowercase, hyphenated code derived from display name (e.g., `"Dunk Theater"` → `"dunk-theater"`)

---

## Import Behavior

### Comparison Model

| Source | Represents | User Edits? |
|--------|-----------|-------------|
| Manifest (`<g id="data">`) | State at export time | No |
| Polygon geometry (`<polygon>`) | Current SVG state | Yes |

### Diff Detection

For each polygon in the SVG:

1. Look up polygon ID in manifest (`triangles` or `zones`)
2. Retrieve original vertex positions via MapPoint UUIDs
3. Compare original positions to current polygon vertex positions
4. Position delta beyond threshold (0.5m) = user edit detected

### MapPoint Update Rules

| Condition | Action |
|-----------|--------|
| **All** polygons referencing a MapPoint moved it to the **same** new position | Update MapPoint position in place; clear calibration data |
| **Some** polygons moved, others kept original position | **Split:** Create new MapPoint at new position; update divergent polygons to reference new MapPoint; original MapPoint unchanged |
| Position unchanged | No action |

### Calibration Data Cleared on Move

When a MapPoint position updates (unanimous move), the following are reset:

- `arPositionHistory` → `[]`
- `canonicalPosition` → `nil`
- `canonicalConfidence` → `nil`
- `canonicalSampleCount` → `0`

Preserved:
- `id` (UUID)
- `name`
- `roles` (may gain new roles)
- `triangleMemberships` (updated to reflect new associations)

### New Geometry

Polygons with IDs **not present** in manifest are treated as new:

- New MapPoints created at vertex positions (deduplicated against existing)
- New Triangle or Zone created with fresh ID

### Deleted Geometry

Polygons present in manifest but **missing from SVG**:

- **Current behavior:** No automatic deletion (orphaned in app)
- **Future consideration:** Optional "sync deletions" import mode

### Duplicate Polygon IDs

If multiple polygons share the same ID (Illustrator duplication):

1. Check each instance's vertex positions against manifest
2. Instance matching original positions → keeps original ID
3. Instance with new positions → renamed with suffix (e.g., `dunk-theater` → `dunk-theater-01`)
4. Both instances imported as separate entities

---

## SVG Layer Structure (Reference)

Expected SVG structure for export/import compatibility:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<svg id="museum-map" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 8192 8192">
  
  <!-- Styles -->
  <!-- Note: Illustrator may mangle class names to shortened forms (st0, st1, etc.)
       On import, derive group membership from DOM hierarchy, not CSS classes. -->
  <defs>
    <style>
      .evolvinglife { fill: #3154ff; opacity: 0.2; }
      .calibrated { fill: #00ff00; opacity: 0.15; }
      .uncalibrated { fill: #ff0000; opacity: 0.15; }
    </style>
  </defs>
  
  <!-- Background map image -->
  <image id="map-background" width="8192" height="8192" xlink:href="map.png"/>
  
  <!-- Zone Groups -->
  <g id="zones">
    <g id="evolvingLife-zones">
      <polygon id="dunk-theater" class="evolvinglife" points="3532.4,7055.6 3532.4,6967.4 ..."/>
    </g>
  </g>
  
  <!-- Triangles -->
  <g id="triangles">
    <polygon id="tri-E325D867" class="calibrated" points="..."/>
  </g>
  
  <!-- Export Manifest (machine data, do not edit) -->
  <g id="data">
    <text class="manifest">
      <!-- JSON manifest content -->
    </text>
  </g>
  
</svg>
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-19 | Initial schema |
