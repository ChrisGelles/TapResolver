# Zones and Zone Groups SVG Import/Export Flow

**Date:** January 11, 2026  
**Status:** Documentation of Current Implementation

---

## Overview

TapResolver supports bidirectional SVG interchange for Zones and Zone Groups, enabling workflow integration with Adobe Illustrator. The system uses MapPoints as the atomic coordinate primitive, ensuring spatial consistency across all entities.

---

## SVG File Organization

### Expected SVG Structure (Import Format)

SVG files imported into TapResolver should follow this hierarchical structure:

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
  
  <!-- Background map image (optional) -->
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
</svg>
```

### Key Structural Elements

1. **Zone Groups:** `<g>` elements whose `id` attribute ends with `-zones` (e.g., `evolvingLife-zones`)
2. **Zones:** `<polygon>` elements nested inside zone group `<g>` elements
3. **Zone IDs:** The `id` attribute of the `<polygon>` element (spaces allowed, e.g., "Dunk Theater")
4. **CSS Classes:** Used to determine group colors from `<style>` definitions
5. **Points Attribute:** SVG `points` attribute contains comma-separated or space-separated coordinate pairs

### Export Format (Current Implementation)

The current export implementation creates a flat structure without zone groups:

```xml
<g id="zones">
  <polygon id="zone-{shortID}" class="zone-quad-{shortID}" points="..."/>
  <rect id="zone-{shortID}-corner-0" class="zone-corner-{shortID}" .../>
  <rect id="zone-{shortID}-corner-1" class="zone-corner-{shortID}" .../>
  <rect id="zone-{shortID}-corner-2" class="zone-corner-{shortID}" .../>
  <rect id="zone-{shortID}-corner-3" class="zone-corner-{shortID}" .../>
  <text id="zone-{shortID}-label" class="zone-label-{shortID}" ...>{zone.name}</text>
</g>
```

**Note:** The export currently does not preserve zone group hierarchy. All zones are exported in a single flat layer.

---

## Import Flow

### Step 1: User Initiates Import

**Location:** `SVGExportPanel.swift` (lines 177-200)

1. User taps "Import Zones from SVG" button
2. System checks for MetricSquare calibration (required for coordinate conversion)
3. File picker opens, allowing user to select an SVG file
4. Security-scoped resource access is requested for the selected file

### Step 2: SVG Parsing

**Location:** `ZoneSVGParser.swift` (lines 64-130)

The `ZoneSVGParser` class uses `XMLParser` to traverse the SVG DOM:

1. **Reset State:** Clears previous parse results
2. **XML Traversal:** Processes elements using delegate methods:
   - `didStartElement`: Handles `<g>`, `<polygon>`, and `<style>` elements
   - `foundCharacters`: Accumulates CSS content from `<style>` elements
   - `didEndElement`: Finalizes group and style parsing
3. **Group Detection:** Tracks `<g>` elements with IDs ending in `-zones`
4. **Zone Extraction:** Parses `<polygon>` elements, extracting:
   - `id` attribute → zone ID
   - `points` attribute → corner coordinates (parsed as `CGPoint` array)
   - `class` attribute → CSS class for color lookup
   - Parent group context → group ID
5. **CSS Parsing:** Extracts color definitions from `<style>` elements using regex pattern matching
6. **Color Resolution:** Matches group colors using two strategies:
   - Strategy 1: Direct match from group ID (e.g., `evolvingLife-zones` → `evolvinglife`)
   - Strategy 2: Use CSS class from first zone in the group

**Output:** `SVGParseResult` containing:
- `groups`: Array of `RawZoneGroup` objects
- `zones`: Array of `RawZone` objects
- `cssStyles`: Dictionary mapping CSS class names to hex colors
- `errors`: Array of parsing errors

### Step 3: MapPoint Resolution

**Location:** `SVGImporter.swift` (lines 85-90) and `MapPointResolver.swift`

The `MapPointResolver` handles coordinate deduplication:

1. **Initialization:** Creates resolver with:
   - `mapPointStore`: Reference to existing MapPoints
   - `thresholdMeters`: 0.5 meters (default)
   - `pixelsPerMeter`: Conversion factor from MetricSquare calibration

2. **Resolution Process:** For each zone corner coordinate:
   - **Batch Check:** First checks if this exact position was already resolved in the current import batch
   - **Proximity Check:** Checks for nearby points within threshold in the batch
   - **Existing Point Check:** Queries `MapPointStore.findNear()` for existing MapPoints within threshold
   - **New Point Creation:** If no match found, creates a new `MapPoint` with `.zoneCorner` role

3. **Role Assignment:** Adds `.zoneCorner` role to matched existing points

**Output:** Array of MapPoint UUIDs for each zone's corners

### Step 4: Zone Group Creation

**Location:** `SVGImporter.swift` (lines 92-107)

1. **Iterate Raw Groups:** For each `RawZoneGroup` from parsing:
2. **Duplicate Check:** Skips if group already exists in `ZoneGroupStore`
3. **Create Group:** Calls `zoneGroupStore.createGroup()` with:
   - `id`: Group ID from SVG (e.g., `evolvingLife-zones`)
   - `displayName`: Derived from ID (e.g., `evolvingLife-zones` → `Evolving Life Zones`)
   - `colorHex`: Resolved from CSS (e.g., `#3154ff`)

### Step 5: Zone Creation

**Location:** `SVGImporter.swift` (lines 109-143)

1. **Iterate Raw Zones:** For each `RawZone` from parsing:
2. **Validation:** 
   - Checks for exactly 4 corners (required for bilinear interpolation)
   - Skips zones with incorrect corner count (adds warning)
3. **Duplicate Check:** Skips if zone already exists (by ID)
4. **MapPoint Resolution:** Calls `resolver.resolve()` for all 4 corners
5. **Zone Creation:** Calls `zoneStore.createZone()` with:
   - `id`: Zone ID converted to code-safe format (via `asCodeID`)
   - `displayName`: From SVG polygon `id`
   - `cornerMapPointIDs`: Array of resolved MapPoint UUID strings
   - `groupID`: Parent group ID (if any)
6. **Group Assignment:** Adds zone to group via `zoneGroupStore.addZone()`

### Step 6: Commit MapPoints

**Location:** `SVGImporter.swift` (lines 145-147) and `MapPointResolver.swift` (lines 118-137)

1. **Commit:** Calls `resolver.commit()` to save all newly created MapPoints
2. **Statistics:** Calculates:
   - `mapPointsCreated`: New points added
   - `mapPointsReused`: Existing points matched

### Step 7: Return Results

**Location:** `SVGImporter.swift` (lines 162-169)

Returns `SVGImportResult` with:
- `groupsCreated`: Number of new groups
- `zonesCreated`: Number of new zones
- `mapPointsCreated`: Number of new MapPoints
- `mapPointsReused`: Number of existing MapPoints reused
- `errors`: Array of error messages
- `warnings`: Array of warning messages (e.g., zones with wrong corner count)

### Step 8: User Feedback

**Location:** `SVGExportPanel.swift` (lines 251-261)

Displays alert with import statistics or error messages.

---

## Export Flow

### Step 1: User Initiates Export

**Location:** `SVGExportPanel.swift` (lines 159-175)

1. User configures export options (toggles for map background, triangles, zones, etc.)
2. User taps "Export SVG" button
3. Export runs on background thread to avoid blocking UI

### Step 2: Data Capture

**Location:** `SVGExportPanel.swift` (lines 290-297)

Captures current state on main thread:
- `locationID`: Current location identifier
- `points`: All MapPoints from `MapPointStore`
- `zones`: All zones from `ZoneStore`
- `triangles`: All triangles from `TrianglePatchStore`
- `pixelsPerMeter`: Conversion factor from MetricSquare

### Step 3: SVG Document Creation

**Location:** `SVGExportPanel.swift` (lines 312-318) and `SVGDocument.swift`

1. **Load Map Image:** Gets map background image for location
2. **Create Document:** Initializes `SVGDocument` with map dimensions
3. **Set Document ID:** Sets root SVG element ID (e.g., `museum-map`)
4. **Add Background:** Optionally embeds map image as base64 PNG

### Step 4: Zones Layer Generation

**Location:** `SVGExportPanel.swift` (lines 734-781)

1. **Style Registration:** For each zone, registers CSS classes:
   - `zone-quad-{shortID}`: Orange dashed stroke for zone outline
   - `zone-corner-{shortID}`: Orange filled squares for corners
   - `zone-label-{shortID}`: Orange text for zone name

2. **Zone Rendering:** For each zone:
   - **Corner Lookup:** Resolves corner MapPoint IDs to `CGPoint` positions
   - **Validation:** Skips zones without exactly 4 corners
   - **Polygon:** Creates `<polygon>` element with corner coordinates
   - **Corner Markers:** Creates `<rect>` elements for each corner (10x10px squares)
   - **Label:** Creates `<text>` element at zone centroid with zone name

3. **Layer Addition:** Adds all zone content to `zones` layer

### Step 5: SVG Generation

**Location:** `SVGDocument.swift` (lines 121-160)

1. **XML Header:** Writes XML declaration and SVG root element
2. **Styles Section:** Writes `<defs><style>` block with all registered CSS classes
3. **Background Image:** Writes `<image>` element if background was embedded
4. **Layers:** Writes each layer as `<g id="{layerID}">` containing its content
5. **Closing:** Closes SVG root element

### Step 6: File Writing

**Location:** `SVGDocument.swift` (lines 165-178)

1. **Generate SVG String:** Converts document to complete SVG XML string
2. **Write to Temp:** Saves to temporary directory with generated filename
3. **Return URL:** Returns file URL for sharing

### Step 7: Share Sheet

**Location:** `SVGExportPanel.swift` (lines 222-226)

Displays iOS share sheet allowing user to save or share the SVG file.

---

## Data Model

### Zone Structure

```swift
public struct Zone {
    public let id: String                    // Human-readable or UUID string
    public var displayName: String           // Display name (e.g., "Dunk Theater")
    public var cornerMapPointIDs: [String]  // 4 MapPoint UUID strings (CCW order)
    public var groupID: String?              // Optional parent group ID
    public var memberTriangleIDs: [String]   // Triangles intersecting zone
    public var isLocked: Bool                // Prevents deletion
    // ... timestamps, etc.
}
```

### ZoneGroup Structure

```swift
public struct ZoneGroup {
    public let id: String                    // Human-readable (e.g., "evolvingLife-zones")
    public var displayName: String           // Display name (e.g., "Evolving Life Zones")
    public var colorHex: String              // Hex color (e.g., "#3154ff")
    public var zoneIDs: [String]             // Ordered list of zone IDs
    // ... timestamps, etc.
}
```

### MapPoint Structure

```swift
public struct MapPoint {
    public let id: UUID                      // Unique identifier
    public var mapPoint: CGPoint             // Pixel coordinates
    public var roles: Set<MapPointRole>       // Includes .zoneCorner
    public var isLocked: Bool                 // Prevents deletion
    // ... canonical position, etc.
}
```

---

## Coordinate System

### Import Coordinate Flow

1. **SVG Coordinates:** Raw pixel coordinates from `points` attribute
2. **CGPoint Conversion:** Parsed as `CGPoint(x: Double, y: Double)`
3. **MapPoint Resolution:** Matched to existing or created as new MapPoint
4. **Storage:** Stored as `MapPoint.mapPoint: CGPoint` in MapPointStore

### Export Coordinate Flow

1. **MapPoint Lookup:** Zone corner IDs → MapPoint UUIDs → `CGPoint` positions
2. **SVG Formatting:** Coordinates formatted as `"x1,y1 x2,y2 x3,y3 x4,y4"` string
3. **SVG Output:** Written to `<polygon points="...">` attribute

### Coordinate Deduplication

- **Threshold:** 0.5 meters (configurable)
- **Conversion:** `thresholdPixels = thresholdMeters * pixelsPerMeter`
- **Algorithm:** Euclidean distance calculation between points
- **Purpose:** Prevents duplicate MapPoints when zones share corners

---

## Error Handling

### Import Errors

1. **XML Parse Errors:** Captured by `XMLParserDelegate.parseErrorOccurred`
2. **Missing Zones:** Error if no zones found in file
3. **Invalid Corner Count:** Warning for zones with ≠ 4 corners (skipped)
4. **Duplicate Groups:** Skipped silently (logged)
5. **Duplicate Zones:** Skipped silently (logged)
6. **File Access Errors:** Error if security-scoped resource access fails

### Export Errors

1. **Missing Map Image:** Export fails if map image cannot be loaded
2. **Missing Corners:** Zones with < 4 corners are skipped
3. **File Write Errors:** Error if SVG cannot be written to temp directory

---

## Storage

### Persistence Keys

- **ZoneGroups:** `ZoneGroups_v1_{locationID}` (UserDefaults)
- **Zones:** `Zones_v2_{locationID}` (UserDefaults)
- **MapPoints:** `MapPoints_v1` (UserDefaults, shared across locations)

### Data Flow

```
SVG File (Import)
    ↓
ZoneSVGParser → RawZoneGroup[], RawZone[]
    ↓
SVGImporter → MapPointResolver
    ↓
ZoneGroupStore.createGroup()
ZoneStore.createZone()
MapPointStore (new points + role updates)
    ↓
UserDefaults (persistence)
```

```
UserDefaults (Export)
    ↓
ZoneStore.zones
ZoneGroupStore.groups
MapPointStore.points
    ↓
SVGExportPanel.addZonesLayer()
    ↓
SVGDocument.generateSVG()
    ↓
SVG File (Export)
```

---

## Limitations and Notes

### Current Limitations

1. **Export Does Not Preserve Groups:** The export implementation creates a flat zone structure and does not recreate zone group hierarchy in the SVG
2. **4-Corner Requirement:** Zones must have exactly 4 corners (required for bilinear interpolation)
3. **No Round-Trip Fidelity:** Import → Export → Import may not preserve exact structure due to flat export

### Design Decisions

1. **MapPoint as Primitive:** All spatial entities reference MapPoints, ensuring coordinate consistency
2. **Batch Deduplication:** MapPointResolver handles deduplication within a single import batch
3. **Role-Based Points:** MapPoints can have multiple roles (e.g., `.zoneCorner`, `.triangleEdge`)
4. **Human-Readable IDs:** Zone and ZoneGroup IDs are human-readable strings (not UUIDs) for SVG interchange

---

## Files Involved

### Core Import/Export
- `TapResolver/Utils/SVGImporter.swift` - Import orchestration
- `TapResolver/Utils/ZoneSVGParser.swift` - SVG XML parsing
- `TapResolver/Utils/MapPointResolver.swift` - Coordinate deduplication
- `TapResolver/UI/Panels/SVGExportPanel.swift` - UI and export logic
- `TapResolver/Utils/SVGBuilder/SVGDocument.swift` - SVG document builder

### Data Models
- `TapResolver/State/Zone.swift` - Zone entity
- `TapResolver/State/ZoneGroup.swift` - ZoneGroup entity
- `TapResolver/State/ZoneStore.swift` - Zone persistence and management
- `TapResolver/State/ZoneGroupStore.swift` - ZoneGroup persistence and management
- `TapResolver/State/MapPointStore.swift` - MapPoint persistence and queries

### Utilities
- `TapResolver/Utils/Color+Hex.swift` - Color ↔ hex string conversion

---

## Future Enhancements

1. **Group-Aware Export:** Update export to preserve zone group hierarchy in SVG
2. **Round-Trip Fidelity:** Ensure import → export → import preserves structure
3. **Flexible Corner Count:** Support zones with variable corner counts (if bilinear requirement is relaxed)
4. **Import Validation:** Add more comprehensive validation and error reporting
5. **Incremental Import:** Support importing only new zones/groups without duplicates
