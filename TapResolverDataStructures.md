# TapResolver Data Structures Reference

## Overview

This document details the core data structures used in TapResolver's spatial mapping system, their persistence mechanisms, and relationships.

---

## MapPoint

**File:** `MapPointStore.swift` (lines 174-260)

The fundamental spatial entity representing a point on the 2D map with associated calibration data.

### Properties

#### Identity & Position
| Property | Type | Persisted | Description |
|----------|------|-----------|-------------|
| `id` | `UUID` | ✅ | Unique identifier |
| `position` | `CGPoint` | ✅ | 2D map pixel coordinates |
| `name` | `String?` | ✅ | Optional user-assigned name |
| `createdDate` | `Date` | ✅ | Creation timestamp |

#### AR Linkage
| Property | Type | Persisted | Description |
|----------|------|-----------|-------------|
| `linkedARMarkerID` | `UUID?` | ✅ | Legacy AR marker link |
| `arMarkerID` | `String?` | ✅ | Current ARWorldMapStore marker link |

#### Roles & Membership
| Property | Type | Persisted | Description |
|----------|------|-----------|-------------|
| `roles` | `Set<MapPointRole>` | ✅ | Functional roles (zoneCorner, triangleEdge, etc.) |
| `triangleMemberships` | `[UUID]` | ✅ | Triangle IDs this point belongs to |
| `isLocked` | `Bool` | ✅ | Whether point can be edited |

#### Photo Data
| Property | Type | Persisted | Description |
|----------|------|-----------|-------------|
| `locationPhotoData` | `Data?` | ✅ | Photo bytes (legacy, may be on disk) |
| `photoFilename` | `String?` | ✅ | Filename if photo stored on disk |
| `photoOutdated` | `Bool?` | ✅ | Flag if position changed after photo |
| `photoCapturedAtPosition` | `CGPoint?` | ✅ | Position when photo was captured |

#### Calibration Data
| Property | Type | Persisted | Description |
|----------|------|-----------|-------------|
| `arPositionHistory` | `[ARPositionRecord]` | ✅ | Historical 3D position observations |
| `canonicalPosition` | `SIMD3<Float>?` | ✅ | Baked position in canonical frame (meters) |
| `canonicalConfidence` | `Float?` | ✅ | Aggregate confidence score (0.0-1.0) |
| `canonicalSampleCount` | `Int` | ✅ | Number of calibration sessions |
| `consensusDistortionVector` | `SIMD3<Float>?` | ✅ | Offset from idealized geometry |

#### BLE Survey Data
| Property | Type | Persisted | Description |
|----------|------|-----------|-------------|
| `sessions` | `[ScanSession]` | ✅ | Full BLE scan session data |

#### Computed Properties
| Property | Type | Description |
|----------|------|-------------|
| `mapPoint` | `CGPoint` | Alias for `position` |
| `consensusPosition` | `SIMD3<Float>?` | Weighted average from position history |

### Canonical Position Frame

The `canonicalPosition` uses a consistent reference frame:
- **Origin:** Center of map image at floor level
- **Units:** Meters
- **Axes:** +X right, +Z down (map orientation), +Y up
- **Y value:** Typically 0 (floor) or slight offset

This frame is **session-independent**, allowing data to persist meaningfully across AR sessions.

### Distortion Vector

The `consensusDistortionVector` represents the difference between:
- **Ideal position:** Where the point would be if the map were geometrically perfect
- **Actual position:** Where the point actually is in physical space

```
consensusDistortionVector = actualCanonical - idealCanonical
```

Used to correct ghost placement in future sessions.

---

## MapPointDTO

**File:** `MapPointStore.swift` (lines 792-818)

Data Transfer Object for MapPoint persistence. Flattens complex types for JSON encoding.

### Properties

```swift
private struct MapPointDTO: Codable {
    let id: UUID
    let x: CGFloat                              // position.x
    let y: CGFloat                              // position.y
    let name: String?
    let createdDate: Date
    let sessions: [ScanSession]
    let linkedARMarkerID: UUID?
    let arMarkerID: String?
    let roles: [MapPointRole]?                  // Set → Array
    let locationPhotoData: Data?
    let photoFilename: String?
    let photoOutdated: Bool?
    let photoCapturedAtPositionX: CGFloat?      // CGPoint.x
    let photoCapturedAtPositionY: CGFloat?      // CGPoint.y
    let triangleMemberships: [UUID]?
    let isLocked: Bool?
    let arPositionHistory: [ARPositionRecord]?
    let bakedCanonicalPositionArray: [Float]?   // SIMD3 → [x, y, z]
    let bakedConfidence: Float?
    let bakedSampleCount: Int?
    let consensusDistortionVectorArray: [Float]? // SIMD3 → [x, y, z]
}
```

### Mapping

**Save (MapPoint → MapPointDTO):**
- `CGPoint` flattened to separate `x`, `y` fields
- `Set<MapPointRole>` converted to `[MapPointRole]`
- `SIMD3<Float>` converted to `[Float]` arrays

**Load (MapPointDTO → MapPoint):**
- `x`, `y` reconstructed to `CGPoint`
- `[MapPointRole]` converted to `Set<MapPointRole>`
- `[Float]` arrays converted to `SIMD3<Float>` (if count == 3)

---

## ARPositionRecord

**File:** `MapPointStore.swift` (lines 25-75)

A single observation of a MapPoint's 3D position from an AR session.

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `UUID` | Unique record identifier |
| `position` | `SIMD3<Float>` | 3D AR position (session coordinates) |
| `sessionID` | `UUID` | AR session that created this record |
| `timestamp` | `Date` | When the observation was made |
| `sourceType` | `SourceType` | How the position was recorded |
| `distortionVector` | `SIMD3<Float>?` | Adjustment from ghost position (if applicable) |
| `confidenceScore` | `Float` | Weight for averaging (0.0-1.0) |

### SourceType Enum

```swift
enum SourceType: String, Codable {
    case calibration    // Manual placement during triangle/corner calibration
    case ghostConfirm   // User confirmed ghost position without adjustment
    case ghostAdjust    // User adjusted ghost to new position
    case relocalized    // Position derived from session transform
}
```

### When Records Are Created

| Action | SourceType | Confidence |
|--------|------------|------------|
| Place zone corner | `.calibration` | 0.95 |
| Place triangle vertex | `.calibration` | 0.95 |
| Confirm ghost (no adjustment) | `.ghostConfirm` | 0.85 |
| Adjust ghost | `.ghostAdjust` | 0.90 |
| Relocalization | `.relocalized` | varies |

---

## Triangle (TrianglePatch)

**File:** `TrianglePatch.swift` (lines 26-102)

Represents a triangular calibration region defined by three MapPoints.

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `UUID` | Unique triangle identifier |
| `vertexIDs` | `[UUID]` | Exactly 3 MapPoint IDs |
| `isCalibrated` | `Bool` | Whether fully calibrated |
| `calibrationQuality` | `Float` | Quality score (0.0 red → 1.0 green) |
| `transform` | `Similarity2D?` | Map → AR floor transform (nil until calibrated) |
| `createdAt` | `Date` | Creation timestamp |
| `lastCalibratedAt` | `Date?` | Last calibration timestamp |
| `arMarkerIDs` | `[String]` | AR marker IDs (matches vertexIDs order) |
| `userPositionWhenCalibrated` | `simd_float3?` | User's AR position at final marker |
| `legMeasurements` | `[TriangleLegMeasurement]` | Distance measurements for quality |
| `worldMapFilename` | `String?` | Legacy world map filename |
| `worldMapFilesByStrategy` | `[String: String]` | World maps per reloc strategy |
| `lastStartingVertexIndex` | `Int?` | Starting vertex from last session |

### Relationship to MapPoints

- **Triangle → MapPoint:** `vertexIDs` array references 3 MapPoint IDs
- **MapPoint → Triangle:** `triangleMemberships` array lists containing triangle IDs
- **Bidirectional:** Both sides maintain the relationship

---

## Zone Corner Bilinear Data

**File:** `ARCalibrationCoordinator.swift` (lines 48-52)

Ephemeral data structures for bilinear projection (not persisted).

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `sortedZoneCorners2D` | `[CGPoint]` | 2D map positions, CCW order |
| `sortedZoneCorners3D` | `[simd_float3]` | 3D AR positions, matching order |
| `hasBilinearCorners` | `Bool` | Whether corners are set up |

### Corner Ordering (A, B, C, D)

```
    D (0,1) ─────────────── C (1,1)
       │                       │
       │                       │
       │                       │
    A (0,0) ─────────────── B (1,0)
```

Corners are sorted counter-clockwise starting from bottom-left.

---

## Persistence Architecture

### Storage Mechanism

TapResolver uses **UserDefaults** via a `PersistenceContext` that provides location-scoped storage.

```swift
let ctx = PersistenceContext.shared
ctx.write(key, value: encodableData)  // Write with location context
ctx.read(key, as: Type.self)          // Read with location context
```

### UserDefaults Keys

| Key | Content | Scope |
|-----|---------|-------|
| `MapPoints_v1` | `[MapPointDTO]` | Location-specific |
| `MapPointsActive_v1` | `UUID?` | Location-specific |
| `ARMarkers_v1` | AR marker data | Location-specific |
| `AnchorPackages_v1` | Anchor packages | Location-specific |
| `triangles_v1` | `[Triangle]` | Location-specific |
| `MetricSquares_v1` | Scale data | Location-specific |
| `BeaconLists_beacons_v1` | Beacon lists | Location-specific |

### Bake Metadata Keys

Stored directly in UserDefaults (not via `ctx`):

| Key | Content | Description |
|-----|---------|-------------|
| `bakeTimestampKey` | `Date` | When last bake occurred |
| `bakeSessionCountKey` | `Int` | Sessions processed in last bake |

### Save Flow

```
MapPoint modified
       │
       ▼
mapPointStore.save()
       │
       ▼
Convert [MapPoint] → [MapPointDTO]
  • Flatten CGPoint to x, y
  • Convert Set to Array
  • Convert SIMD3 to [Float]
       │
       ▼
ctx.write(pointsKey, value: dto)
       │
       ▼
UserDefaults (JSON encoded)
```

### Load Flow

```
App launch / location change
       │
       ▼
mapPointStore.reloadPoints()
       │
       ▼
ctx.read(pointsKey, as: [MapPointDTO].self)
       │
       ▼
Convert [MapPointDTO] → [MapPoint]
  • Reconstruct CGPoint from x, y
  • Convert Array to Set
  • Convert [Float] to SIMD3
  • Load photos from disk if filename exists
       │
       ▼
Run migrations
  • Legacy AR position purge
  • Role metadata defaults
  • Photo outdated flags
       │
       ▼
points array populated
```

### Position History Persistence

Position history is **embedded in MapPoint**, not stored separately:

```
MapPoint
  └── arPositionHistory: [ARPositionRecord]
        └── Each record is Codable
        
MapPointDTO
  └── arPositionHistory: [ARPositionRecord]?
        └── Same array, directly serialized
```

No separate storage or joining required.

---

## Data Relationships Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        MapPointStore                         │
│  points: [MapPoint]                                          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                          MapPoint                            │
├─────────────────────────────────────────────────────────────┤
│  id: UUID                                                    │
│  position: CGPoint ──────────────────────► 2D Map Location   │
│  canonicalPosition: SIMD3<Float>? ───────► 3D Baked Position │
│  consensusDistortionVector: SIMD3<Float>? ► Correction Data  │
│  arPositionHistory: [ARPositionRecord] ──► Session History   │
│  triangleMemberships: [UUID] ────────────► Triangle Links    │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
┌─────────────────────────┐     ┌─────────────────────────────┐
│    ARPositionRecord     │     │          Triangle           │
├─────────────────────────┤     ├─────────────────────────────┤
│  position: SIMD3<Float> │     │  vertexIDs: [UUID] (3)      │
│  sessionID: UUID        │     │  isCalibrated: Bool         │
│  sourceType: SourceType │     │  transform: Similarity2D?   │
│  distortionVector: ...? │     │  calibrationQuality: Float  │
│  confidenceScore: Float │     └─────────────────────────────┘
└─────────────────────────┘
```

---

## Migration Notes

### Photo Storage Migration
- Legacy: `locationPhotoData` stored in UserDefaults
- Current: Photos stored on disk, `photoFilename` references file
- Migration: On load, if `photoFilename` exists, load from disk

### Position History Purge
- Legacy data may have position records with invalid session transforms
- `purgeLegacyARPositionHistoryIfNeeded()` clears incompatible data
- Tracks purge status to avoid repeated processing

### Role Metadata
- Older MapPoints may lack `roles` property
- Migration sets default roles based on existing data

---

## Related Documentation

- **Zone Corner Workflow:** See [ZoneCornerWorkflow.md](ZoneCornerWorkflow.md) for calibration process details
- **Coordinate Frames:** Detailed in Zone Corner Workflow document
- **Bilinear Interpolation:** Algorithm details in Zone Corner Workflow document
