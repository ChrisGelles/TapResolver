# TapResolver Coordinate Projection Models

## Overview

TapResolver operates in two coordinate spaces that must be continuously synchronized:

1. **AR Space** — 3D coordinates from ARKit (meters, session-relative origin)
2. **Map Space** — 2D pixel coordinates on the floor plan image

This document describes the two approaches for projecting between these spaces.

---

## Coordinate Spaces Defined

### AR Space (Session Coordinates)
- **Origin:** Where ARKit initialized (device position at session start)
- **Units:** Meters
- **Axes:** 
  - X: Right
  - Y: Up (gravity-opposite)
  - Z: Backward (toward user at start)
- **Lifetime:** Single AR session only
- **Challenge:** Origin changes every session

### Map Space (Pixel Coordinates)
- **Origin:** Top-left corner of map image
- **Units:** Pixels
- **Axes:**
  - X: Right
  - Y: Down
- **Lifetime:** Persistent
- **Challenge:** No inherent scale information

### Canonical Space (Introduced in Baked Position System)
- **Origin:** Center of map image
- **Units:** Meters
- **Axes:**
  - X: Right (same as map)
  - Z: Down (same as map Y, but called Z for 3D consistency)
  - Y: Height (vertical)
- **Lifetime:** Persistent
- **Purpose:** Bridge between AR sessions — all historical data transformed here

---

## Approach 1: Per-Triangle Barycentric Projection (Original)

### When Used
- Projecting user's AR position to map coordinates for PiP display
- Only works when user is inside (or near) a calibrated triangle
- Requires at least one triangle with 3 known AR vertex positions

### How It Works

```
┌─────────────────────────────────────────────────────────────┐
│  Camera AR Position (x, y, z)                               │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Find calibrated triangle with 3 AR vertex positions        │
│  (searches sessionCalibratedTriangles)                      │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Compute barycentric weights in AR XZ plane                 │
│                                                             │
│  Given triangle vertices P0, P1, P2 and point P:            │
│                                                             │
│  v0 = P1 - P0                                               │
│  v1 = P2 - P0                                               │
│  v2 = P  - P0                                               │
│                                                             │
│  dot00 = v0 · v0                                            │
│  dot01 = v0 · v1                                            │
│  dot02 = v0 · v2                                            │
│  dot11 = v1 · v1                                            │
│  dot12 = v1 · v2                                            │
│                                                             │
│  invDenom = 1 / (dot00 * dot11 - dot01 * dot01)             │
│  u = (dot11 * dot02 - dot01 * dot12) * invDenom             │
│  v = (dot00 * dot12 - dot01 * dot02) * invDenom             │
│  w = 1 - u - v                                              │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Apply same weights to map pixel coordinates                │
│                                                             │
│  mapX = w * map0.x + u * map1.x + v * map2.x                │
│  mapY = w * map0.y + u * map1.y + v * map2.y                │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Map Position (pixels)                                      │
└─────────────────────────────────────────────────────────────┘
```

### Code Location
- `ARViewWithOverlays.swift` → `projectARPositionToMap(arPosition:)`
- `ARViewWithOverlays.swift` → `projectUsingBarycentric(...)`

### Limitations
- Only works inside calibrated triangles
- Requires triangle search each frame
- Cannot project positions outside the calibrated mesh
- Different triangles may have slightly different transforms (distortion)

### Advantages
- Handles per-triangle distortion naturally
- Works with minimal calibration (just one triangle)
- No global transform required

---

## Approach 2: Canonical Frame Transform (Baked Position System)

### When Used
- Ghost marker placement from historical data
- User position projection (when transform is available)
- Any position on the map (not limited to triangle interiors)

### Prerequisites
- At least 2 markers planted on MapPoints with baked positions
- Session transform computed from those markers

### How It Works

```
┌─────────────────────────────────────────────────────────────┐
│  Camera AR Position (x, y, z) — Session Space               │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Apply session→canonical inverse transform                  │
│                                                             │
│  The transform encodes:                                     │
│  • Scale (session units to canonical units)                 │
│  • Rotation (session orientation to canonical orientation)  │
│  • Translation (session origin to canonical origin)         │
│                                                             │
│  canonical = inverse(sessionTransform) * sessionPosition    │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Canonical Position (x, y, z) — Map-Centered, Meters        │
│                                                             │
│  Origin is at map center pixel                              │
│  X+ is map right                                            │
│  Z+ is map down                                             │
│  Y is height (preserved from AR)                            │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Scale to pixel coordinates                                 │
│                                                             │
│  mapX = mapCenterX + (canonical.x × pixelsPerMeter)         │
│  mapY = mapCenterY + (canonical.z × pixelsPerMeter)         │
│                                                             │
│  where:                                                     │
│  • mapCenterX = mapWidth / 2                                │
│  • mapCenterY = mapHeight / 2                               │
│  • pixelsPerMeter from MetricSquare calibration             │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Map Position (pixels)                                      │
└─────────────────────────────────────────────────────────────┘
```

### Session Transform Computation

When 2+ markers are planted on MapPoints with baked canonical positions:

```
┌─────────────────────────────────────────────────────────────┐
│  For each planted marker:                                   │
│  • Session AR position (where user planted it)              │
│  • Baked canonical position (from historical data)          │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Compute rigid body transform (2D, XZ plane):               │
│                                                             │
│  Given correspondences:                                     │
│    canonical₁ ↔ session₁                                    │
│    canonical₂ ↔ session₂                                    │
│                                                             │
│  Solve for: scale, rotation, translation                    │
│  Such that: session = scale * rotate(canonical) + translate │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Cache transform for session lifetime                       │
│  • cachedCanonicalToSessionTransform                        │
│  • Verification error logged (should be < 0.1m)             │
└─────────────────────────────────────────────────────────────┘
```

### Code Location
- `ARCalibrationCoordinator.swift` → `computeSessionTransformForBakedData()`
- `ARCalibrationCoordinator.swift` → `calculateGhostPositionFromBakedData(...)`
- `ARCalibrationCoordinator.swift` → `projectBakedToSession(...)`
- `MapPointStore.swift` → `bakeDownHistoricalData(...)`

### Limitations
- Requires 2+ planted markers to compute transform
- Assumes uniform scale/rotation across entire map
- Does not capture per-triangle distortion

### Advantages
- Works anywhere on the map (not limited to triangle interiors)
- Single transform computation, then O(1) projection
- Leverages all historical calibration data
- Much faster per-frame calculation

---

## Hybrid Approach (Current Implementation)

The system uses both approaches strategically:

| Situation | Approach Used |
|-----------|---------------|
| Ghost placement for 3rd vertex | Baked transform (fast path) |
| Ghost placement fallback | Per-triangle barycentric (legacy) |
| User position for PiP map | Barycentric (works inside triangles) |
| Triangle containment check | AR-space direct (no projection needed) |
| Future: User position anywhere | Canonical transform (planned) |

---

## Triangle Containment (Separate from Projection)

Determining which triangle contains the user does NOT require projecting to map space.

### AR-Space Containment Check
```
┌─────────────────────────────────────────────────────────────┐
│  Camera AR Position (x, y, z)                               │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  For each known triangle:                                   │
│  • Get AR positions of 3 vertices                           │
│    (from mapPointARPositions or projected baked data)       │
│  • Check if camera XZ is inside triangle XZ                 │
│    (barycentric test, ignoring Y height)                    │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Return first containing triangle ID (or nil)               │
└─────────────────────────────────────────────────────────────┘
```

This is more efficient because:
- No coordinate transformation required
- Comparison happens in native AR units
- Only needs vertex positions, not full projection pipeline

### Code Location
- `ARViewWithOverlays.swift` → `findContainingTriangleInARSpace(...)`
- `ARViewWithOverlays.swift` → `pointInTriangleXZ(...)`

---

## Data Structures

### MapPoint Baked Fields
```swift
public var bakedCanonicalPosition: SIMD3<Float>?  // Position in canonical frame
public var bakedConfidence: Float?                 // Weighted confidence (0-1)
public var bakedSampleCount: Int = 0               // Number of sessions contributing
```

### Cached Transform (ARCalibrationCoordinator)
```swift
private var cachedCanonicalToSessionTransform: simd_float4x4?
private var cachedMapSize: CGSize?
private var cachedMetersPerPixel: Float?
```

### Canonical Frame Definition (CanonicalFrame.swift)
```swift
struct CanonicalFrame {
    let mapSize: CGSize           // Map dimensions in pixels
    let pixelsPerMeter: Float     // From MetricSquare
    let floorHeight: Float        // Y value for floor plane (typically negative)
    
    var origin: CGPoint {         // Map center
        CGPoint(x: mapSize.width / 2, y: mapSize.height / 2)
    }
}
```

---

## Performance Characteristics

| Operation | Old Approach | New Approach |
|-----------|--------------|--------------|
| Setup cost | None | One-time transform computation (~1ms) |
| Per-frame projection | Triangle search + barycentric | Matrix multiply + scale |
| Memory | Minimal | Cache transform + map params |
| Coverage | Inside calibrated triangles only | Entire map |

---

## Future Considerations

### Per-Triangle Distortion Correction
The canonical transform assumes uniform scale/rotation. Real maps have distortion. Future work could:
- Track per-triangle scale variance
- Apply local corrections within each triangle
- Use TIN (Triangulated Irregular Network) for smooth interpolation

### Multi-Floor Support
Current system assumes single floor plane. Extensions needed:
- Floor detection from MapPoint Y values
- Per-floor canonical frames
- Floor transition detection

### Continuous Refinement
As more calibration data accumulates:
- Baked positions become more accurate
- Outlier detection can flag bad measurements
- Map corrections can be computed from systematic errors

---

## Document History

| Date | Author | Changes |
|------|--------|---------|
| 2025-12-08 | Claude/Chris | Initial document |

