# TapResolver Coordinate Systems & Data Model Deep Dive

## Overview

TapResolver is an AR-based indoor positioning system that bridges 2D floor plan maps with 3D AR spatial tracking. The core challenge is transforming between multiple coordinate spaces while maintaining accuracy across different AR sessions.

---

## The Four Coordinate Spaces

### 1. **Map Pixel Space** (2D)
- **Units:** Pixels
- **Origin:** Top-left corner of the floor plan image
- **Axes:** X increases right, Y increases down (standard image coordinates)
- **Used by:** `MapPoint.position` (CGPoint)

Example: A point at `CGPoint(x: 1200, y: 800)` is 1200 pixels from the left edge, 800 pixels from the top.

### 2. **Map Meter Space** (2D)
- **Units:** Real-world meters
- **Origin:** Top-left corner of the floor plan
- **Conversion:** `metersPerPixel` from `MetricSquareStore` (user calibrates a known-size square)
- **Axes:** Same as pixel space, but scaled

Conversion:
```swift
let metersPerPixel = square.meters / square.side  // e.g., 0.02 m/px
let positionInMeters = CGPoint(
    x: pixelPosition.x * metersPerPixel,
    y: pixelPosition.y * metersPerPixel
)
```

### 3. **Canonical/Baked Space** (3D)
- **Units:** Meters
- **Origin:** **Center of the map image** (this is crucial!)
- **Axes:** 
  - X: positive = right on map
  - Y: vertical (floor height, typically -1.1m)
  - Z: positive = down on map (matches map Y direction)
- **Used by:** `MapPoint.bakedCanonicalPosition` (SIMD3<Float>)

This is the **consensus reference frame** — positions accumulated from 18+ historical AR sessions, normalized to a map-centered coordinate system. It's the "source of truth" for where things actually are.

Conversion from Map Pixels to Canonical:
```swift
let pixelsPerMeter = 1.0 / metersPerPixel
let canonicalOrigin = CGPoint(x: mapSize.width / 2, y: mapSize.height / 2)
let floorHeight: Float = -1.1  // Standard floor level

let canonicalPosition = SIMD3<Float>(
    Float(mapPoint.position.x - canonicalOrigin.x) / pixelsPerMeter,
    floorHeight,
    Float(mapPoint.position.y - canonicalOrigin.y) / pixelsPerMeter
)
```

### 4. **AR Session Space** (3D)
- **Units:** Meters
- **Origin:** Where ARKit initialized (arbitrary, changes each session)
- **Axes:** ARKit standard (Y is up, -Z is camera forward at start)
- **Used by:** `mapPointARPositions[uuid]`, AR marker positions, ghost markers

Each AR session has a **different origin and orientation**. The same physical location will have different coordinates in different sessions.

---

## Data Structures

### MapPoint (Persistent)
```swift
struct MapPoint {
    let id: UUID
    var position: CGPoint                      // Map pixel coordinates
    var bakedCanonicalPosition: SIMD3<Float>?  // Consensus position in canonical frame
    var bakedConfidence: Float?                // 0.0-1.0, based on sample count
    var bakedSampleCount: Int                  // How many sessions contributed
    var arPositionHistory: [ARPositionRecord]  // Raw historical data
    // ... other fields
}
```

### CalibrationTriangle
```swift
struct CalibrationTriangle {
    let id: UUID
    var vertexIDs: [UUID]     // 3 MapPoint IDs
    var arMarkerIDs: [String] // AR marker IDs (may be empty for interior triangles!)
    // ...
}
```

**Important:** `arMarkerIDs` can be empty for interior triangles (triangles completely surrounded by others). Their vertices were planted while calibrating neighboring triangles, not from inside.

### ARCalibrationCoordinator Runtime State
```swift
// Current session marker positions (ephemeral, reset each session)
var mapPointARPositions: [UUID: simd_float3]  // MapPoint ID → AR position

// Session transform (computed after planting 2 markers)
var cachedCanonicalToSessionTransform: SessionToCanonicalTransform?

// Ghost markers (temporary AR visualizations)
var ghostMarkerPositions: [UUID: simd_float3]  // In AR session space
```

---

## The Transform Pipeline

### When Transform is Computed

After the user plants **2 AR markers** in a session, the system computes a rigid body transform:

```
Canonical Space ←→ Session Space
```

This is done in `computeSessionTransformForBakedData()`:

1. Takes two MapPoints that have both:
   - `bakedCanonicalPosition` (from historical consensus)
   - Current session AR position (`mapPointARPositions`)

2. Computes rotation (Y-axis only), scale, and translation

3. Caches the transform for the rest of the session

### Checking if Transform is Available

```swift
if arCalibrationCoordinator.hasValidSessionTransform {
    // Can now project baked positions to current session
}
```

### Projecting Baked → Session

```swift
// Given a baked canonical position, get its position in current AR session
if let sessionPosition = arCalibrationCoordinator.projectBakedToSession(bakedPosition) {
    // sessionPosition is in current AR session coordinates
}
```

This is the **key function for Survey Markers**. If you have positions in canonical/meters space, project them to session space using this.

### Getting Triangle Vertices in Session Space

```swift
// Get all 3 vertex positions for a triangle in current session space
// Automatically uses session-planted positions OR projects baked positions
if let positions = arCalibrationCoordinator.getTriangleVertexPositionsFromBaked(triangleID) {
    // positions: [UUID: SIMD3<Float>] — all 3 vertices in session space
}
```

This is the **hybrid function** that checks:
1. First: Does vertex have a session-planted position? Use it.
2. Fallback: Does vertex have baked position? Project it.

---

## The Baked Position System

### What "Baking" Means

At the end of each calibration session, the system:

1. Computes `session → canonical` transform for that session
2. Transforms all session AR positions to canonical space
3. Accumulates into `bakedCanonicalPosition` as weighted average
4. Updates confidence based on sample count

### Why Canonical is Map-Centered

Using map center as origin ensures:
- Positions are stable regardless of map resolution
- No dependency on ARKit's arbitrary session origins
- Historical data can be compared across sessions

### Baked Fields on MapPoint

| Field | Type | Description |
|-------|------|-------------|
| `bakedCanonicalPosition` | `SIMD3<Float>?` | 3D position in canonical frame |
| `bakedConfidence` | `Float?` | 0.0-1.0, higher = more reliable |
| `bakedSampleCount` | `Int` | Number of sessions that contributed |

---

## Survey Markers

Survey Markers are a grid of points placed inside a calibrated triangle for BLE beacon data collection.

### The Coordinate Flow for Survey Markers

```
Survey Grid Definition (meters, relative to triangle)
        ↓
Canonical Space (map-centered meters)
        ↓
Session Space (via projectBakedToSession)
        ↓
AR Visualization (red-topped spheres)
```

### Correct Approach

If you have Survey Marker positions in meters (e.g., `gridPoints_m`):

1. **Ensure positions are in canonical frame** (map-centered, meters)
2. **Check** `hasValidSessionTransform` is true
3. **Project** using `projectBakedToSession(canonicalPosition)`
4. **Place** AR markers at the returned session positions

**DO NOT** create a separate "three-point anchor" system. Use the existing calibration infrastructure.

### Example Code Pattern

```swift
// Assuming gridPointCanonical is in canonical space (meters, map-centered)
guard arCalibrationCoordinator.hasValidSessionTransform else {
    print("Cannot place survey markers - no session transform")
    return
}

for gridPointCanonical in surveyGridCanonicalPositions {
    if let sessionPosition = arCalibrationCoordinator.projectBakedToSession(gridPointCanonical) {
        // Place AR marker at sessionPosition
        createSurveyMarker(at: sessionPosition)
    }
}
```

---

## Key Functions Reference

### Transform & Projection

| Function | Purpose |
|----------|---------|
| `computeSessionTransformForBakedData(mapSize:metersPerPixel:)` | Computes canonical↔session transform after 2 markers planted |
| `hasValidSessionTransform` | Bool property — is transform available? |
| `projectBakedToSession(_:)` | Projects canonical position → session position |
| `getTriangleVertexPositionsFromBaked(_:)` | Gets all 3 triangle vertices in session space (hybrid) |

### Triangle & Validation

| Function | Purpose |
|----------|---------|
| `triangleHasBakedVertices(_:)` | Do all 3 vertices have baked positions? |
| `triangleCanBeFilled(_:)` | Can triangle be filled? (checks session OR baked) |

### State Management

| Function | Purpose |
|----------|---------|
| `enterSurveyMode()` | Transitions to `.surveyMode` state |
| `exitSurveyMode()` | Reverts state when validation fails |
| `transitionToReadyToFillAndRefreshGhosts(placedMapPointID:)` | Continues crawl after ghost promotion |

---

## Ghost Markers

Ghost Markers are predicted positions for unplanted triangle vertices, shown as translucent spheres.

### Ghost Creation Flow

```
1. Triangle with unplanted vertices identified
2. For each unplanted vertex:
   a. Check if MapPoint has bakedCanonicalPosition
   b. If yes, projectBakedToSession() to get AR position
   c. Create translucent sphere at that position
3. User walks to ghost, can Confirm (accept prediction) or Adjust (manual placement)
```

### Ghost Interaction (State-Independent)

After today's fixes, ghost interaction works in ANY state:
- `selectedGhostMapPointID` stores currently selected ghost
- `shouldShowGhostButtons` returns true if ANY ghost is selected
- Adjust removes ghost, places marker, triggers adjacent triangle discovery

---

## Common Gotchas

### 1. Interior Triangles Have Empty arMarkerIDs

Triangles surrounded by others never had markers planted "from inside." Their `arMarkerIDs` arrays are empty/partial. **Always fall back to baked positions.**

### 2. Transform Only Valid After 2 Markers

`hasValidSessionTransform` is false until user plants 2 AR markers in the current session. Check this before projecting.

### 3. Session Positions vs Baked Positions

- `mapPointARPositions[id]` — current session only, ephemeral
- `bakedCanonicalPosition` — historical consensus, persistent

Use session positions when available (more accurate for current session), fall back to baked.

### 4. Coordinate Handedness

- Map: Y increases DOWN (image coordinates)
- Canonical: Z increases DOWN (matches map Y)
- AR: Y is UP, -Z is forward

The conversion handles this, but be aware when debugging.

---

## File Locations

| File | Contains |
|------|----------|
| `ARCalibrationCoordinator.swift` | Transform computation, state management, baked helpers |
| `MapPointStore.swift` | MapPoint struct, persistence, consensus calculation |
| `ARViewContainer.swift` | AR rendering, ghost/marker placement, notifications |
| `ARViewWithOverlays.swift` | UI buttons, ghost interaction handlers |
| `TrianglePatchStore.swift` | CalibrationTriangle struct, triangle management |

---

## Summary for Survey Markers

**Yes, Phase 2 LOD rendering should use `projectBakedToSession()`.**

The flow:
1. Define survey grid in canonical space (meters, map-centered)
2. When user triggers fill, check `hasValidSessionTransform`
3. Project each grid point: `projectBakedToSession(gridPointCanonical)`
4. Place AR markers at returned session positions

The existing calibration infrastructure handles all the coordinate math. Don't reinvent it.
