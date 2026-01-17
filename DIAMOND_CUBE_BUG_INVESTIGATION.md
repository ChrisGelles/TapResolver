# Diamond Cube on Wrong Markers - Investigation
**Date:** January 16, 2025  
**Focus:** Tracing `isZoneCorner` flag flow to identify why diamond cubes appear on wrong markers

---

## Question 1: `isZoneCorner` Flag in PendingMarker

### PendingMarker Struct Definition

**Location:** Lines 32-37 in `ARCalibrationCoordinator.swift`

```32:37:TapResolver/TapResolver/State/ARCalibrationCoordinator.swift
struct PendingMarker {
    let mapPointID: UUID
    let position: simd_float3
    let isNeighborCorner: Bool  // true = diamond marker, false = ghost sphere
    let zoneName: String?       // For neighbor corners only
}
```

**Answer:** **NO** — `PendingMarker` does **NOT** have an `isZoneCorner` field.

**It has:** `isNeighborCorner: Bool` — indicates whether it's a neighbor corner (diamond) vs triangle vertex (ghost sphere)

### Where `isNeighborCorner` is Set

#### In `spawnNeighborCornerMarkers()` (line 1637):

```1634:1639:TapResolver/TapResolver/State/ARCalibrationCoordinator.swift
pendingMarkers[mapPointUUID] = PendingMarker(
    mapPointID: mapPointUUID,
    position: prediction.arPosition,
    isNeighborCorner: true,
    zoneName: neighborZone.displayName
)
```

**Value:** Always `true` — all neighbor corners are marked as neighbor corners

#### In `plantGhostsForAllTriangleVerticesBilinear()` (line 1970):

```1967:1971:TapResolver/TapResolver/State/ARCalibrationCoordinator.swift
pendingMarkers[vertexID] = PendingMarker(
    mapPointID: vertexID,
    position: finalGhostPosition,
    isNeighborCorner: false,
    zoneName: nil
)
```

**Value:** Always `false` — all triangle vertices are marked as non-neighbor corners

**Key Finding:** `isNeighborCorner` is set to `false` **regardless** of whether the triangle vertex has `.zoneCorner` role.

---

## Question 2: `spawnCollectedMarkers()` Marker Creation

### Decision Logic

**Location:** Lines 1743-1768 in `spawnCollectedMarkers()`

```1743:1768:TapResolver/TapResolver/State/ARCalibrationCoordinator.swift
if marker.isNeighborCorner {
    // Spawn diamond marker for neighbor corner
    NotificationCenter.default.post(
        name: NSNotification.Name("SpawnNeighborCornerMarker"),
        object: nil,
        userInfo: [
            "position": [marker.position.x, marker.position.y, marker.position.z],
            "mapPointID": mapPointID.uuidString,
            "zoneName": marker.zoneName ?? "Unknown"
        ]
    )
    spawnedNeighborCornerIDs.insert(mapPointID.uuidString)
    print("   💎 Spawned neighbor corner \(String(mapPointID.uuidString.prefix(8)))")
} else {
    // Spawn ghost marker for triangle vertex
    ghostMarkerPositions[mapPointID] = marker.position
    NotificationCenter.default.post(
        name: NSNotification.Name("PlaceGhostMarker"),
        object: nil,
        userInfo: [
            "mapPointID": mapPointID,
            "position": marker.position
        ]
    )
    print("   👻 Spawned ghost \(String(mapPointID.uuidString.prefix(8)))")
}
```

**Answer:** 
- Decision is based on `marker.isNeighborCorner` (NOT `isZoneCorner`)
- **NO check** for `pendingMarker.isZoneCorner` or `pendingMarker.sourceType`
- **NO check** of MapPoint's roles at spawn time
- Falls back to notification handler checking roles

**Problem:** Triangle vertices with `.zoneCorner` role get `isNeighborCorner: false`, so they spawn via `PlaceGhostMarker`, but the handler checks roles and adds diamond cube anyway.

---

## Question 3: Ghost Render Handler

### `handlePlaceGhostMarker()` Code Block

**Location:** Lines 1083-1092 in `ARViewContainer.swift`

```1083:1092:TapResolver/TapResolver/ARFoundation/ARViewContainer.swift
// Check if this MapPoint has the .zoneCorner role
let isZoneCornerPoint: Bool
if let mapPoint = mapPointStore?.points.first(where: { $0.id == mapPointID }) {
    isZoneCornerPoint = mapPoint.roles.contains(.zoneCorner)
    if isZoneCornerPoint {
        print("🔷 [GHOST_RENDER] MapPoint \(String(mapPointID.uuidString.prefix(8))) has .zoneCorner role → composite ghost")
    }
} else {
    isZoneCornerPoint = false
}
```

**Answer:**
- **YES** — Checks `mapPoint.roles.contains(.zoneCorner)`
- **NO** — Does NOT receive `isZoneCorner` flag from notification `userInfo`
- Determines diamond cube status **at render time** by checking MapPoint roles

**Used in MarkerOptions (line 1106):**

```1095:1107:TapResolver/TapResolver/ARFoundation/ARViewContainer.swift
let ghostNode = ARMarkerRenderer.createNode(
    at: position,
    options: MarkerOptions(
        color: .orange,  // User-specified color for ghosts
        markerID: UUID(),  // Temporary ID for ghost
        userDeviceHeight: userDeviceHeight,
        badgeColor: nil,
        radius: 0.03,
        animateOnAppearance: true,  // Smooth appearance animation
        animationOvershoot: 0.04,
        isGhost: true,  // CRITICAL: Enables pulsing animation and transparency
        isZoneCorner: isZoneCornerPoint
    )
)
```

---

## Question 4: Notification Payload Differences

### `PlaceGhostMarker` Notification

**Location:** Line 1759-1765 in `spawnCollectedMarkers()`

```1759:1765:TapResolver/TapResolver/State/ARCalibrationCoordinator.swift
NotificationCenter.default.post(
    name: NSNotification.Name("PlaceGhostMarker"),
    object: nil,
    userInfo: [
        "mapPointID": mapPointID,
        "position": marker.position
    ]
)
```

**Keys:**
- `"mapPointID"`: `UUID`
- `"position"`: `simd_float3`

**NO `isZoneCorner` flag** — Handler must check MapPoint roles

### `SpawnNeighborCornerMarker` Notification

**Location:** Line 1745-1752 in `spawnCollectedMarkers()`

```1745:1752:TapResolver/TapResolver/State/ARCalibrationCoordinator.swift
NotificationCenter.default.post(
    name: NSNotification.Name("SpawnNeighborCornerMarker"),
    object: nil,
    userInfo: [
        "position": [marker.position.x, marker.position.y, marker.position.z],
        "mapPointID": mapPointID.uuidString,
        "zoneName": marker.zoneName ?? "Unknown"
    ]
)
```

**Keys:**
- `"position"`: `[Float]` array
- `"mapPointID"`: `String`
- `"zoneName"`: `String`

**NO `isZoneCorner` flag** — Handler hardcodes `isZoneCorner: true` (line 299)

**Handler Code (line 299):**

```293:300:TapResolver/TapResolver/ARFoundation/ARViewContainer.swift
let options = MarkerOptions(
    color: .orange,  // Ghost zone corners use orange sphere
    markerID: UUID(),
    userDeviceHeight: self.userDeviceHeight,
    animateOnAppearance: true,
    isGhost: true,  // Pulsing effect
    isZoneCorner: true
)
```

**Answer:** **NEITHER** notification passes `isZoneCorner` flag. Both handlers determine it differently:
- `PlaceGhostMarker` → checks MapPoint roles
- `SpawnNeighborCornerMarker` → hardcodes `true`

---

## Question 5: Triangle-Only Vertex Collection

### Value Set for Non-Zone-Corner Triangle Vertices

**Location:** Line 1970 in `plantGhostsForAllTriangleVerticesBilinear()`

```1967:1971:TapResolver/TapResolver/State/ARCalibrationCoordinator.swift
pendingMarkers[vertexID] = PendingMarker(
    mapPointID: vertexID,
    position: finalGhostPosition,
    isNeighborCorner: false,
    zoneName: nil
)
```

**Answer:** 
- `isNeighborCorner: false` is **explicitly set** (not determined later)
- This value is set **regardless** of whether the vertex has `.zoneCorner` role
- The value is determined **at collection time**, not at render time

**Problem:** Triangle vertices with `.zoneCorner` role get `isNeighborCorner: false`, so they:
1. Get collected as triangle vertices (not neighbor corners)
2. Spawn via `PlaceGhostMarker` notification
3. Handler checks roles and adds diamond cube anyway

**Result:** Diamond cubes appear on triangle vertices that have `.zoneCorner` role, even though they're not neighbor corners.

---

## Question 6: MarkerOptions Creation

### Source of `isZoneCorner` Parameter

**For `PlaceGhostMarker` notification:**

**Flow:**
1. `spawnCollectedMarkers()` posts `PlaceGhostMarker` (line 1759)
2. `handlePlaceGhostMarker()` receives notification (line 1067)
3. Handler checks `mapPoint.roles.contains(.zoneCorner)` (line 1086)
4. Sets `isZoneCornerPoint` boolean (line 1084-1092)
5. Passes to `MarkerOptions(isZoneCorner: isZoneCornerPoint)` (line 1106)

**Source:** MapPoint's roles checked **at render time** in notification handler

**For `SpawnNeighborCornerMarker` notification:**

**Flow:**
1. `spawnCollectedMarkers()` posts `SpawnNeighborCornerMarker` (line 1745)
2. Handler receives notification (line 278)
3. Handler **hardcodes** `isZoneCorner: true` (line 299)
4. Passes to `MarkerOptions(isZoneCorner: true)` (line 299)

**Source:** **Hardcoded `true`** — assumes all neighbor corners are zone corners

---

## Root Cause Analysis

### The Bug

**Problem:** Diamond cubes appear on triangle vertices that have `.zoneCorner` role, even though they're not neighbor corners.

**Root Cause:** 
1. `PendingMarker.isNeighborCorner` is set to `false` for **all** triangle vertices (regardless of `.zoneCorner` role)
2. Triangle vertices spawn via `PlaceGhostMarker` notification
3. Handler checks `mapPoint.roles.contains(.zoneCorner)` and adds diamond cube
4. **Result:** Triangle vertices with `.zoneCorner` role get diamond cubes

**Why This Happens:**
- `isNeighborCorner` in `PendingMarker` means "is this a neighbor corner?" not "should this have a diamond cube?"
- Diamond cube decision is made **at render time** based on MapPoint roles, not at collection time
- Triangle vertices with `.zoneCorner` role are collected as `isNeighborCorner: false` but still get diamond cubes because the handler checks roles

### The Mismatch

**Collection Time:**
- `isNeighborCorner: false` → "This is a triangle vertex, not a neighbor corner"

**Render Time:**
- `isZoneCorner: true` → "This MapPoint has `.zoneCorner` role, so add diamond cube"

**Result:** Diamond cubes on triangle vertices that happen to have `.zoneCorner` role.

---

## Summary

### Key Findings

1. **`PendingMarker` has `isNeighborCorner`** (not `isZoneCorner`) — indicates source type, not visual appearance
2. **Triangle vertices always get `isNeighborCorner: false`** — regardless of `.zoneCorner` role
3. **Diamond cube decision made at render time** — handler checks MapPoint roles for `PlaceGhostMarker`
4. **No `isZoneCorner` flag in notifications** — both handlers determine it differently
5. **Mismatch between collection and rendering** — collection uses `isNeighborCorner`, rendering uses role check

### The Bug Flow

1. Triangle vertex with `.zoneCorner` role gets collected with `isNeighborCorner: false`
2. Spawns via `PlaceGhostMarker` notification (because `isNeighborCorner: false`)
3. Handler checks `mapPoint.roles.contains(.zoneCorner)` → `true`
4. Handler sets `isZoneCorner: true` in `MarkerOptions`
5. **Diamond cube appears** on triangle vertex (wrong!)

### Potential Fix

**Option 1:** Add `isZoneCorner` field to `PendingMarker` and set it based on MapPoint roles at collection time

**Option 2:** Pass `isZoneCorner` flag in `PlaceGhostMarker` notification `userInfo`

**Option 3:** Change handler logic to only add diamond cube for neighbor corners, not all zone corners
