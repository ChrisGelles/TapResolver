# Marker Planting Flow Investigation
**Date:** January 16, 2025  
**Focus:** Cornered Zones - marker planting flow after zone corner calibration completes

---

## Question 1: What triggers after 4th zone corner is confirmed?

**Answer:** When `placedMarkers.count == totalCorners` (line 1350 in `ARCalibrationCoordinator.swift`), the following sequence executes:

### Sequence of Events (in order):

1. **`markZoneAsPlanted(zoneID)`** (line 1356)
   - Adds zone to `plantedZoneIDs` set
   - Triggers `onZonePlanted?` callback

2. **`spawnNeighborCornerMarkers(for: zoneID)`** (line 1361)
   - Called **BEFORE** bilinear setup
   - Spawns diamond markers for neighbor zone corners

3. **Bilinear Setup** (lines 1372-1429)
   - Gathers corner data (ID, 2D map position, 3D AR position)
   - Sorts corners counter-clockwise via `sortCornersCounterClockwise()`
   - Populates `sortedZoneCorners2D` and `sortedZoneCorners3D`
   - Validates quad (checks for self-intersection)
   - Sets `hasBilinearCorners = true` (implicitly via array counts)

4. **`plantGhostsForAllTriangleVerticesBilinear()`** (line 1432)
   - Called **AFTER** bilinear setup completes
   - Plants ghost markers for all triangle vertices

5. **Origin Marker Planting** (lines 1434-1455)
   - Projects map center via bilinear
   - Posts `PlaceOriginMarker` notification

6. **State Transition** (line 1458)
   - `calibrationState = .readyToFill`

**Key Finding:** There is **NO single orchestrating function**. The sequence is linear within the `else` block of `registerZoneCornerAnchor()`.

---

## Question 2: What calls `plantGhostsForAllTriangleVerticesBilinear()`?

**Answer:** Called **directly** at line 1432 in `registerZoneCornerAnchor()`, immediately after bilinear setup completes.

**Call Site:**
```1350:1432:TapResolver/TapResolver/State/ARCalibrationCoordinator.swift
} else {
    // All corners placed - set up bilinear projection and plant ghosts
    print("✅ [ZONE_CORNER] All \(totalCorners) corners placed")
    
    // ... bilinear setup code ...
    
    // Plant ghosts using bilinear projection only
    plantGhostsForAllTriangleVerticesBilinear()
```

**Execution Context:**
- Called synchronously after bilinear setup
- Not triggered via notification
- No conditions gate execution (only `hasBilinearCorners` guard inside the function)

---

## Question 3: What calls `spawnNeighborCornerMarkers()`?

**Answer:** Called at line 1361 in `registerZoneCornerAnchor()`, **BEFORE** bilinear setup.

**Call Site:**
```1354:1362:TapResolver/TapResolver/State/ARCalibrationCoordinator.swift
// Mark zone as planted for wavefront propagation
if let zoneID = activeZoneID, totalCorners == 4 {
    markZoneAsPlanted(zoneID)
    
    // Spawn neighbor corner markers
    if let zone = safeZoneStore?.zone(withID: zoneID) {
        print("🌊 [WAVEFRONT] Zone '\(zone.displayName)' planted — \(zone.neighborZoneIDs.count) neighbors ready for prediction")
        spawnNeighborCornerMarkers(for: zoneID)
    }
}
```

**Sequence Relative to `plantGhostsForAllTriangleVerticesBilinear()`:**
- `spawnNeighborCornerMarkers()` runs **FIRST** (line 1361)
- `plantGhostsForAllTriangleVerticesBilinear()` runs **SECOND** (line 1432)

**Gap:** There is a ~70 line gap between these calls (bilinear setup happens in between).

---

## Question 4: Do these functions check for already-spawned markers?

### `plantGhostsForAllTriangleVerticesBilinear()` Checks:

**YES** - Checks `mapPointARPositions`:
```1819:1824:TapResolver/TapResolver/State/ARCalibrationCoordinator.swift
for vertexID in allVertexIDs {
    // Skip if already has AR position (placed as corner or already confirmed)
    if mapPointARPositions[vertexID] != nil {
        skippedHasPosition += 1
        continue
    }
```

**YES** - Checks `adjustedGhostMapPoints`:
```1826:1830:TapResolver/TapResolver/State/ARCalibrationCoordinator.swift
// Skip if ghost was already adjusted
if adjustedGhostMapPoints.contains(vertexID) {
    skippedHasPosition += 1
    continue
}
```

**NO** - Does **NOT** check `ghostMarkerPositions` before spawning.

### `spawnNeighborCornerMarkers()` Checks:

**YES** - Checks `spawnedNeighborCornerIDs`:
```1601:1606:TapResolver/TapResolver/State/ARCalibrationCoordinator.swift
// Spawn diamond markers for each corner
for prediction in predictions {
    // Skip if already spawned (from another planted zone)
    if spawnedNeighborCornerIDs.contains(prediction.mapPointID) {
        print("   ⏭️ Corner \(String(prediction.mapPointID.prefix(8))) already spawned")
        continue
    }
```

**NO** - Does **NOT** check:
- `ghostMarkerPositions`
- `mapPointARPositions`
- `adjustedGhostMapPoints`

### Overlap Risk:

**YES** - The same MapPoint ID **could** be processed by both functions:
- `plantGhostsForAllTriangleVerticesBilinear()` processes **all triangle vertices** (including zone corners)
- `spawnNeighborCornerMarkers()` processes **neighbor zone corners** (which may also be triangle vertices)

**Example Scenario:**
- Zone A's corner MapPoint `X` is a triangle vertex
- Zone B is a neighbor of Zone A
- When Zone A completes:
  1. `spawnNeighborCornerMarkers()` spawns diamond for Zone B's corner `X` (if `X` is Zone B's corner)
  2. `plantGhostsForAllTriangleVerticesBilinear()` spawns ghost for `X` (if `X` is a triangle vertex)

**Current Protection:** Only `spawnedNeighborCornerIDs` prevents double-spawning in `spawnNeighborCornerMarkers()`, but this doesn't check if `plantGhostsForAllTriangleVerticesBilinear()` already spawned a ghost.

---

## Question 5: What is the overlap between triangle vertices and neighbor zone corners?

**Answer:** MapPoints can have **both** `.triangleEdge` and `.zoneCorner` roles simultaneously.

### Evidence:

From `MapPointStore.swift`:
```2556:2565:TapResolver/TapResolver/State/MapPointStore.swift
func diagnoseRoleDistribution(pixelsPerMeter: CGFloat? = nil) {
    let zoneCornerOnly = points.filter { 
        $0.roles.contains(.zoneCorner) && !$0.roles.contains(.triangleEdge) 
    }
    let triangleEdgeOnly = points.filter { 
        $0.roles.contains(.triangleEdge) && !$0.roles.contains(.zoneCorner) 
    }
    let bothRoles = points.filter { 
        $0.roles.contains(.zoneCorner) && $0.roles.contains(.triangleEdge) 
    }
```

### Processing Behavior:

**`plantGhostsForAllTriangleVerticesBilinear()`:**
- Processes **ALL** triangle vertices (regardless of role)
- Does **NOT** filter by `.zoneCorner` role
- If a MapPoint has both roles, it **WILL** be processed

**`spawnNeighborCornerMarkers()`:**
- Processes **ONLY** zone corners from neighbor zones
- Does **NOT** check for `.triangleEdge` role
- If a MapPoint has both roles, it **WILL** be processed

### Order of Processing:

Since `spawnNeighborCornerMarkers()` runs **FIRST** (line 1361) and `plantGhostsForAllTriangleVerticesBilinear()` runs **SECOND** (line 1432):

1. **First:** `spawnNeighborCornerMarkers()` spawns diamond for MapPoint `X` (if `X` is a neighbor zone corner)
2. **Second:** `plantGhostsForAllTriangleVerticesBilinear()` spawns ghost for MapPoint `X` (if `X` is a triangle vertex)

**Result:** MapPoint `X` could get **both** a diamond marker (from neighbor spawning) **and** a ghost marker (from triangle vertex planting).

---

## Question 6: Are different notification types used?

**Answer:** YES - Two different notification types are used.

### Triangle Vertex Ghosts:

**Notification:** `PlaceGhostMarker`
```1872:1879:TapResolver/TapResolver/State/ARCalibrationCoordinator.swift
// Post notification to render ghost in AR view
NotificationCenter.default.post(
    name: NSNotification.Name("PlaceGhostMarker"),
    object: nil,
    userInfo: [
        "mapPointID": vertexID,
        "position": finalGhostPosition
    ]
)
```

**Handler:** `handlePlaceGhostMarker()` in `ARViewContainer.swift`
- Creates ghost marker node (orange sphere)
- Stores in `ghostMarkers[mapPointID]`
- Stores position in `ghostMarkerPositions[mapPointID]`
- Also updates `arCalibrationCoordinator?.ghostMarkerPositions[mapPointID]`

### Neighbor Corner Markers:

**Notification:** `SpawnNeighborCornerMarker`
```1630:1638:TapResolver/TapResolver/State/ARCalibrationCoordinator.swift
// Post notification to AR view to create the marker
NotificationCenter.default.post(
    name: NSNotification.Name("SpawnNeighborCornerMarker"),
    object: nil,
    userInfo: [
        "position": [position.x, position.y, position.z],
        "mapPointID": mapPointID,
        "zoneName": zoneName
    ]
)
```

**Handler:** Closure observer in `ARViewContainer.swift` (lines 273-320)
- Creates diamond marker node (orange sphere with `isZoneCorner: true`)
- Stores in `placedMarkers[markerID]` (different dictionary!)
- Does **NOT** store in `ghostMarkers` or `ghostMarkerPositions`
- Registers marker→MapPoint mapping in `sessionMarkerToMapPoint`

### Tracking Dictionaries:

**`PlaceGhostMarker` uses:**
- `ghostMarkers[mapPointID]` (in ARViewContainer)
- `ghostMarkerPositions[mapPointID]` (in both ARViewContainer and ARCalibrationCoordinator)

**`SpawnNeighborCornerMarker` uses:**
- `placedMarkers[markerID]` (in ARViewContainer) - **Different dictionary!**
- `spawnedNeighborCornerIDs` (Set<String> in ARCalibrationCoordinator)
- `sessionMarkerToMapPoint[markerIDString]` (for demotion support)

**Key Finding:** They use **separate tracking dictionaries**, which means a MapPoint could theoretically have entries in both systems simultaneously.

---

## Question 7: What prevents double-spawning?

### Current Deduplication Logic:

#### `spawnedNeighborCornerIDs`:
- **Populated:** Line 1615 in `spawnNeighborCornerMarkers()` - `spawnedNeighborCornerIDs.insert(prediction.mapPointID)`
- **Checked:** Line 1603 in `spawnNeighborCornerMarkers()` - `if spawnedNeighborCornerIDs.contains(prediction.mapPointID)`
- **Cleared:** Line 1498 in `resetPlantedZones()` - `spawnedNeighborCornerIDs.removeAll()`
- **Removed on demotion:** Line 2056 in `demoteMarkerToGhost()` - `spawnedNeighborCornerIDs.remove(mapPointIDString)`

#### `ghostMarkerPositions`:
- **Populated:** 
  - Line 1869 in `plantGhostsForAllTriangleVerticesBilinear()` - `ghostMarkerPositions[vertexID] = finalGhostPosition`
  - Line 1114 in `handlePlaceGhostMarker()` - `ghostMarkerPositions[mapPointID] = position`
- **Checked:** 
  - Line 1078 in `handlePlaceGhostMarker()` - `if ghostMarkers[mapPointID] != nil` (checks `ghostMarkers`, not `ghostMarkerPositions`)
  - Line 1821 in `plantGhostsForAllTriangleVerticesBilinear()` - **NOT checked before spawning**
- **Removed:** When ghost is confirmed/adjusted (lines 1219, 1242, 1347)

#### `adjustedGhostMapPoints`:
- **Populated:** When ghost is adjusted to AR marker (line 580 in `ARViewContainer.swift`, line 937 in `ARViewWithOverlays.swift`)
- **Checked:** 
  - Line 1827 in `plantGhostsForAllTriangleVerticesBilinear()` - `if adjustedGhostMapPoints.contains(vertexID)`
  - Line 3044 in `plantGhostsForAdjacentTriangles()` - `if adjustedGhostMapPoints.contains(farVertexID)`
- **Cleared:** Line 4097 in `resetSessionState()` - `adjustedGhostMapPoints.removeAll()`

### Gaps in Protection:

1. **`spawnNeighborCornerMarkers()` does NOT check:**
   - `ghostMarkerPositions` - Could spawn diamond even if ghost already exists
   - `mapPointARPositions` - Could spawn diamond even if corner was already placed
   - `adjustedGhostMapPoints` - Could spawn diamond even if ghost was already adjusted

2. **`plantGhostsForAllTriangleVerticesBilinear()` does NOT check:**
   - `ghostMarkerPositions` - Could spawn ghost even if one already exists (relies on `handlePlaceGhostMarker()` check)
   - `spawnedNeighborCornerIDs` - Could spawn ghost even if diamond was already spawned

3. **Cross-function protection:**
   - No shared check between the two functions
   - Each function only checks its own tracking dictionary

---

## Question 8: Proposed architecture check

### Current Architecture Issues:

1. **Two separate spawning paths** with different tracking dictionaries
2. **No unified deduplication** across both paths
3. **Potential for double-spawning** when MapPoint has both roles

### Proposed Unified Architecture:

#### Single Data Structure:

```swift
struct PendingMarker {
    let mapPointID: UUID
    let predictedARPosition: simd_float3
    let sourceType: MarkerSourceType  // .triangleVertex, .neighborZoneCorner, .origin
    let zoneID: String?  // Optional zone context
}

// Unified collection
var pendingMarkers: [UUID: PendingMarker] = [:]
```

**Alternative:** Use existing `ghostMarkerPositions` as the unified structure, but add metadata:
```swift
struct GhostMarkerMetadata {
    let position: simd_float3
    let sourceType: MarkerSourceType
    let zoneID: String?
}

var ghostMarkerMetadata: [UUID: GhostMarkerMetadata] = [:]
```

#### Unified Deduplication Point:

**Location:** Before any marker creation, check unified structure:
```swift
func shouldSpawnMarker(mapPointID: UUID) -> Bool {
    // Check all possible states
    if mapPointARPositions[mapPointID] != nil { return false }  // Already placed
    if adjustedGhostMapPoints.contains(mapPointID) { return false }  // Already adjusted
    if ghostMarkerPositions[mapPointID] != nil { return false }  // Already spawned
    if spawnedNeighborCornerIDs.contains(mapPointID.uuidString) { return false }  // Already spawned as neighbor
    return true
}
```

#### Single Point of Marker Creation:

**Function:** `spawnUnifiedGhostMarker(mapPointID: UUID, position: simd_float3, sourceType: MarkerSourceType, zoneID: String?)`

**Responsibilities:**
1. Check unified deduplication
2. Determine marker type (ghost sphere vs diamond) based on `sourceType` and MapPoint roles
3. Post appropriate notification (`PlaceGhostMarker` or `SpawnNeighborCornerMarker`)
4. Update unified tracking dictionary

**Call Sites:**
- `plantGhostsForAllTriangleVerticesBilinear()` → calls `spawnUnifiedGhostMarker(..., sourceType: .triangleVertex)`
- `spawnNeighborCornerMarkers()` → calls `spawnUnifiedGhostMarker(..., sourceType: .neighborZoneCorner)`

### Benefits:

1. **Single source of truth** for pending markers
2. **Unified deduplication** prevents double-spawning
3. **Clearer separation** between collection phase and spawning phase
4. **Easier debugging** - one place to check marker state

---

## Summary of Findings

### Key Issues Identified:

1. **Timing Gap:** `spawnNeighborCornerMarkers()` runs BEFORE bilinear setup, while `plantGhostsForAllTriangleVerticesBilinear()` runs AFTER
2. **No Cross-Function Checks:** Each function only checks its own tracking dictionary
3. **Role Overlap:** MapPoints with both `.triangleEdge` and `.zoneCorner` roles can be processed by both functions
4. **Separate Tracking:** Two different notification types use different tracking dictionaries
5. **Potential Double-Spawning:** A MapPoint could get both a diamond marker and a ghost marker

### Recommended Next Steps:

1. **Add cross-checks** in `spawnNeighborCornerMarkers()`:
   - Check `ghostMarkerPositions` before spawning
   - Check `mapPointARPositions` before spawning
   - Check `adjustedGhostMapPoints` before spawning

2. **Add cross-checks** in `plantGhostsForAllTriangleVerticesBilinear()`:
   - Check `spawnedNeighborCornerIDs` before spawning

3. **Consider unified architecture** for future refactoring:
   - Single collection phase
   - Single spawning phase
   - Unified deduplication
