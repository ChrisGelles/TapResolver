# Zone Corner Calibration: Geometry and Workflow

## Overview

Zone Corner calibration establishes a **bilinear mapping** between 2D map coordinates and 3D AR space using four corner markers. Unlike triangle-based calibration (which uses rigid body transforms), Zone Corner uses **corner-pin projection** that handles non-uniform distortion across the mapped area.

The system implements a **self-improving feedback loop**: each ghost adjustment contributes distortion data that improves future sessions.

---

## Coordinate Frames

TapResolver uses four coordinate systems. Understanding these is essential for following the data flow.

### 1. Map Pixel Coordinates
- **Origin:** Top-left corner of map image
- **Units:** Pixels
- **Axes:** +X right, +Y down
- **Used for:** `MapPoint.position`, UI rendering, 2D map display
- **Example:** `CGPoint(x: 1227.4, y: 966.8)`

### 2. Map Meters Coordinates
- **Origin:** Center of map image at floor level
- **Units:** Meters
- **Axes:** +X right, +Z down (matching map orientation), +Y up
- **Used for:** Intermediate calculations, ideal position computation
- **Conversion:** `metersPerPixel` from MetricSquare

### 3. Canonical/Baked Coordinates
- **Origin:** Center of map image at floor level
- **Units:** Meters
- **Axes:** +X right, +Z down, +Y up (toward ceiling)
- **Used for:** Persistent storage (`canonicalPosition`), cross-session data, distortion vectors
- **Key property:** Deterministic—same 2D map position always yields same canonical position

### 4. AR Session Coordinates
- **Origin:** ARKit world origin (arbitrary, changes each session)
- **Units:** Meters
- **Axes:** ARKit right-handed coordinate system
- **Used for:** Live marker positions, ghost rendering, real-time tracking
- **Key property:** Ephemeral—only valid within current session

### Coordinate Conversion Summary

```
Map Pixel → Canonical:
  computeCanonicalFromMapPosition()
  canonicalX = (pixelX - mapCenterX) × metersPerPixel
  canonicalZ = (pixelY - mapCenterY) × metersPerPixel
  canonicalY = 0 (floor level)

Map Pixel → AR Session (via bilinear):
  1. inverseBilinear(): Map Pixel → UV coordinates
  2. bilinearInterpolate(): UV → AR Session position

Canonical → AR Session:
  Requires session transform (from corner placement)
```

---

## Bilinear Interpolation

### The Corner-Pin Model

Zone Corner calibration treats the mapped area as a **quadrilateral** defined by four corners. Any point inside (or outside) the quad can be projected using bilinear interpolation.

```
    D (0,1) ─────────────── C (1,1)
       │                       │
       │         •P            │
       │      (u,v)            │
       │                       │
    A (0,0) ─────────────── B (1,0)
```

**UV Coordinates:**
- `(0,0)` = Corner A (bottom-left in CCW order)
- `(1,0)` = Corner B (bottom-right)
- `(1,1)` = Corner C (top-right)
- `(0,1)` = Corner D (top-left)
- Any point P has UV coordinates `(u,v)` representing its relative position

### Forward Interpolation (UV → 3D)

Given UV coordinates and four 3D corner positions, compute the interpolated position:

```
P(u,v) = (1-u)(1-v)×A + u(1-v)×B + uv×C + (1-u)v×D
```

This is a weighted average where each corner contributes based on proximity.

### Inverse Interpolation (2D → UV)

Given a 2D point and four 2D corner positions, find the UV coordinates. This requires solving a **quadratic equation** (the quad may not be rectangular).

**File:** `BilinearInterpolation.swift`, `inverseBilinear()` (lines 202-298)

The algorithm:
1. Express the bilinear equation as quadratic in `u`
2. Solve using quadratic formula
3. Select the valid root (real, typically in or near [0,1])
4. Compute `v` from the result

### Extrapolation

UV values outside `[0,1]` represent points **outside the quad**. The bilinear math still works, allowing projection of points beyond the defined corners. The log marks these as `[BILINEAR_EXTRAP]`.

---

## Zone Corner Workflow

### Phase 1: Corner Placement

**Entry Point:** `startZoneCornerCalibration(zoneCornerIDs: [UUID])`

**State Transitions:**
```
.idle → .placingVertices(currentIndex: 0)
     → .placingVertices(currentIndex: 1)
     → .placingVertices(currentIndex: 2)
     → .placingVertices(currentIndex: 3)
     → .readyToFill
```

**For Each Corner (0-3):**

1. **UI Guidance:** System shows which corner to place, displays photo reference
2. **User Action:** Positions crosshair over physical corner, taps "Place Marker"
3. **`handlePlaceMarkerAtCursor()`:** Creates AR marker at crosshair position
4. **`registerZoneCornerAnchor()`:**
   - Validates MapPoint is in `triangleVertices` (the 4 corner IDs)
   - Records position in `mapPointARPositions[mapPointID]`
   - Creates `ARPositionRecord` with `sourceType: .calibration`
   - Adds to MapPoint's position history
   - Saves to ARWorldMapStore
5. **State Update:** `currentVertexIndex += 1`, advances to next corner

### Phase 2: Bilinear Setup (After 4th Corner)

**Triggered:** Immediately after 4th corner placed

**Process:**
1. **Gather Corner Data:** Collects (MapPointID, 2D position, 3D position) for all 4
2. **Sort CCW:** `sortCornersCounterClockwise()` orders corners consistently
3. **Populate Arrays:**
   - `sortedZoneCorners2D: [CGPoint]` — 2D map positions (A, B, C, D order)
   - `sortedZoneCorners3D: [simd_float3]` — 3D AR positions (matching order)
4. **Validate Quad:** Checks for self-intersection
5. **Set Flag:** `hasBilinearCorners = true`

### Phase 3: Ghost Planting

**Function:** `plantGhostsForAllTriangleVerticesBilinear()`

**Process:**
1. **Collect Vertices:** Gathers all unique MapPoint IDs from all triangles
2. **Filter:**
   - Skip if `mapPointARPositions[vertexID] != nil` (already placed as corner)
   - Skip if `adjustedGhostMapPoints.contains(vertexID)` (already adjusted this session)
3. **For Each Remaining Vertex:**
   - Get MapPoint's 2D position
   - **Check for distortion correction:** If `mapPoint.consensusDistortionVector` exists, apply it
   - Project via `projectPointViaBilinear(mapPoint: position)`
   - Ground to floor level (`finalPosition.y = groundY`)
   - Apply distortion correction: `finalPosition += horizontalCorrection`
   - Post `PlaceGhostMarker` notification
4. **Log Summary:** Reports planted/skipped counts, correction statistics

### Phase 4: Ghost Adjustment

**Selection:**
- `updateGhostSelection()` runs periodically with camera position
- Finds closest ghost within 2.0m horizontal distance
- Sets `selectedGhostMapPointID` if ghost is visible in camera view

**Adjustment Flow:**

```
User taps "Place Marker to Adjust"
         │
         ▼
handlePlaceMarkerAtCursor()
  • Places marker at crosshair
  • Posts ARMarkerPlaced with isGhostConfirm=true, mapPointID
         │
         ▼
ARViewWithOverlays notification handler
  • Detects isGhostConfirm=true
  • Extracts originalGhostPosition
  • Calls registerFillPointMarker()
         │
         ▼
registerFillPointMarker()
  • Creates ARPositionRecord (sourceType: .ghostAdjust)
  • Computes distortionVector = adjustedPosition - originalGhostPosition
  • Adds record to MapPoint's position history
  • Calls updateBakedPositionIncrementally()
         │
         ▼
updateBakedPositionIncrementally()
  • Zone Corner branch: computes canonical from 2D map position
  • Blends with existing samples (weighted average)
  • Computes consensusDistortionVector
  • Saves to UserDefaults
```

---

## The Feedback Loop

### Data Flow Per Session

```
Session N:
  1. Plant ghosts via bilinear projection
  2. Apply existing distortion corrections (if any)
  3. User adjusts ghosts that are misaligned
  4. Compute new distortion vectors
  5. Blend with historical data (weighted average)
  6. Save to persistent storage

Session N+1:
  1. Load accumulated distortion vectors
  2. Plant ghosts with corrections applied
  3. Ghosts appear closer to correct positions
  4. User makes smaller adjustments (if any)
  5. Distortion vectors refined further
```

### Why It Works Across Sessions

**Key Insight:** Distortion vectors are stored relative to the **bilinear projection**, not absolute positions.

Each session has different corner placements (user starts in different location, drift occurs). But:
- The bilinear projection adapts to current corner positions
- Distortion represents the **difference from projection to reality**
- This difference is a property of the **physical space**, not the session

So: different corners → different projection → same distortion correction → correct final position.

### Distortion Vector Computation

**In `updateBakedPositionIncrementally()`:**

```swift
// Compute where the point SHOULD be (ideal geometry)
let idealCanonical = computeIdealCanonicalPosition(from: mapPosition)

// Compute where the point ACTUALLY is (blended from observations)
let actualCanonical = weightedAverage(historicalPositions)

// Distortion = actual - ideal
consensusDistortionVector = actualCanonical - idealCanonical
```

**Interpretation:** If distortion is `(0.05, -0.02, 0.03)`, reality is 5cm right, 2cm down, and 3cm forward from the idealized map geometry at this point.

---

## Key Functions Reference

| Function | File | Purpose |
|----------|------|---------|
| `startZoneCornerCalibration()` | ARCalibrationCoordinator.swift:503 | Initialize Zone Corner session |
| `registerZoneCornerAnchor()` | ARCalibrationCoordinator.swift:1240 | Record corner placement |
| `plantGhostsForAllTriangleVerticesBilinear()` | ARCalibrationCoordinator.swift:1564 | Project and place ghost markers |
| `projectPointViaBilinear()` | ARCalibrationCoordinator.swift:1647 | 2D map → 3D AR projection |
| `registerFillPointMarker()` | ARCalibrationCoordinator.swift:1419 | Record ghost adjustment |
| `updateBakedPositionIncrementally()` | ARCalibrationCoordinator.swift:4546 | Update canonical position and distortion |
| `computeCanonicalFromMapPosition()` | ARCalibrationCoordinator.swift:4711 | Map pixels → canonical meters |
| `inverseBilinear()` | BilinearInterpolation.swift:202 | 2D point → UV coordinates |
| `bilinearInterpolate()` | BilinearInterpolation.swift:339 | UV → 3D position |

---

## CalibrationState Enum

```swift
enum CalibrationState: Equatable {
    case idle                              // No active calibration
    case placingVertices(currentIndex: Int) // Placing corners (0-3 for Zone Corner)
    case readyToFill                        // Corners placed, ghosts visible
    case surveyMode                         // BLE survey mode (separate feature)
}
```

**Zone Corner Flow:**
- `.idle` → User initiates Zone Corner calibration
- `.placingVertices(0)` → Placing first corner
- `.placingVertices(1)` → Placing second corner
- `.placingVertices(2)` → Placing third corner
- `.placingVertices(3)` → Placing fourth corner
- `.readyToFill` → All corners placed, ghosts visible, ready for adjustments

---

## Related Documentation

- **Data Structures:** See [TapResolverDataStructures.md](TapResolverDataStructures.md) for `MapPoint`, `MapPointDTO`, `ARPositionRecord`, persistence details
- **Triangle Calibration:** Separate workflow using rigid body transforms (not covered here)
- **Survey Mode:** BLE beacon data collection (separate feature)
