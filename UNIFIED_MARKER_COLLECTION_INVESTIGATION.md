# Unified Marker Collection Architecture - Detailed Investigation
**Date:** January 16, 2025  
**Focus:** Exact implementation details for unified marker collection design

---

## Question 1: Completion Flow Location

### Exact Line Range

**Opening line:** `1350`  
**Closing line:** `1461`

```1350:1461:TapResolver/TapResolver/State/ARCalibrationCoordinator.swift
} else {
    // All corners placed - set up bilinear projection and plant ghosts
    print("✅ [ZONE_CORNER] All \(totalCorners) corners placed")
    
    // Mark zone as planted for wavefront propagation
    if let zoneID = activeZoneID, totalCorners == 4 {
        markZoneAsPlanted(zoneID)
        
        // Spawn neighbor corner markers
        if let zone = safeZoneStore?.zone(withID: zoneID) {
            print("🌊 [WAVEFRONT] Zone '\(zone.displayName)' planted — \(zone.neighborZoneIDs.count) neighbors ready for prediction")
            spawnNeighborCornerMarkers(for: zoneID)
        }
    }
    
    // Save the starting corner index to Zone for rotation tracking
    if let zoneID = activeZoneID,
       let startingIndex = currentStartingCornerIndex {
        safeZoneStore?.updateLastStartingCornerIndex(zoneID: zoneID, index: startingIndex)
        print("💾 [ZONE_CORNER] Saved starting index \(startingIndex) to Zone")
    }
    
    // BILINEAR SETUP: Gather and sort corner data
    // ... (lines 1372-1429) ...
    
    // Plant ghosts using bilinear projection only
    plantGhostsForAllTriangleVerticesBilinear()
    
    // Plant origin marker at map center projected via bilinear
    // ... (lines 1434-1455) ...
    
    // Transition to crawl mode
    calibrationState = .readyToFill
    statusText = "Zone corners complete - adjust ghosts as needed"
    print("🎯 [ZONE_CORNER] Entering crawl mode with \(ghostMarkerPositions.count) ghost(s)")
}
```

### Function Calls in Order

1. **Line 1356:** `markZoneAsPlanted(zoneID)` - Marks zone as planted
2. **Line 1361:** `spawnNeighborCornerMarkers(for: zoneID)` - Spawns neighbor corner diamonds
3. **Line 1368:** `safeZoneStore?.updateLastStartingCornerIndex(zoneID:zoneID, index:startingIndex)` - Saves rotation tracking
4. **Line 1395:** `sortCornersCounterClockwise(cornersForSorting)` - Sorts corners CCW
5. **Line 1416:** `isValidQuad(corners:sortedZoneCorners2D)` - Validates quad shape
6. **Line 1432:** `plantGhostsForAllTriangleVerticesBilinear()` - Plants triangle vertex ghosts
7. **Line 1437:** `projectPointViaBilinear(mapPoint:mapCenter)` - Projects origin marker
8. **Line 1447:** `NotificationCenter.default.post(...)` - Posts `PlaceOriginMarker` notification
9. **Line 1458:** `calibrationState = .readyToFill` - State transition (property assignment)

---

## Question 2: Data Produced by `spawnNeighborCornerMarkers()`

### Source of `mapPointID`

**Origin:** `neighborZone.cornerMapPointIDs` (line 1549)

**Flow:**
1. Function iterates over `plantedZone.neighborZoneIDs` (line 1579)
2. For each neighbor zone, gets `neighborZone.cornerMapPointIDs` (line 1549)
3. Each `cornerID` is a `String` from the Zone's `cornerMapPointIDs` array
4. Passed to `predictNeighborCornerPositions()` which returns `[(mapPointID: String, arPosition: simd_float3)]?`
5. The `mapPointID` in the prediction tuple is the same `cornerID` string

**Type:** `String` (UUID string representation)

### Source of `position` (Predicted AR Position)

**Origin:** Bilinear projection from planted zone

**Flow:**
1. `predictNeighborCornerPositions()` creates a `BilinearProjection` from the planted zone's corners (line 1541)
2. For each neighbor corner, projects the 2D map position via `projection.project(mapPoint.mapPoint)` (line 1555)
3. Returns `predictedAR` as `simd_float3`

**Calculation:**
- Uses planted zone's 4 corners: `plantedMapCorners` (2D) → `plantedARCorners` (3D)
- Creates bilinear projection: `BilinearProjection(mapCorners:plantedMapCorners, arCorners:plantedARCorners)`
- Projects neighbor corner's 2D map position to 3D AR space

### Other Metadata Available

**At spawn time (in `spawnDiamondMarker()`):**
- `position`: `simd_float3` - Predicted AR position
- `mapPointID`: `String` - MapPoint UUID as string
- `zoneName`: `String` - Display name of neighbor zone (from `neighborZone.displayName`)

**Available but not passed:**
- `neighborZone.id`: `String` - Zone ID
- `plantedZoneID`: `String` - Source zone that triggered spawning
- `neighborZone.cornerMapPointIDs`: `[String]` - All corners of neighbor zone

---

## Question 3: Data Produced by `plantGhostsForAllTriangleVerticesBilinear()`

### Source of `vertexID`

**Origin:** All triangle vertices from `safeTriangleStore.triangles`

**Flow:**
1. Collects all unique vertex IDs from all triangles (lines 1800-1805):
```swift
var allVertexIDs = Set<UUID>()
for triangle in safeTriangleStore.triangles {
    for vertexID in triangle.vertexIDs {
        allVertexIDs.insert(vertexID)
    }
}
```

**Type:** `UUID` (not String)

### Source of `finalGhostPosition`

**Origin:** Bilinear projection + distortion correction + grounding

**Flow:**
1. Gets MapPoint's 2D position: `mapPoint.mapPoint` (line 1833)
2. Projects via bilinear: `projectPointViaBilinear(mapPoint: mapPoint.mapPoint)` (line 1847)
   - Uses `sortedZoneCorners2D` and `sortedZoneCorners3D` (set up earlier)
3. Grounds to floor level: `finalGhostPosition.y = groundY` (line 1853)
   - `groundY` comes from first placed corner's Y position (line 1817)
4. Applies distortion correction if available (lines 1857-1859):
   - Uses `mapPoint.consensusDistortionVector`
   - Only applies horizontal (X, Z) correction

**Final calculation:**
```swift
var finalGhostPosition = projectPointViaBilinear(mapPoint: mapPoint.mapPoint)!
finalGhostPosition.y = groundY  // Ground to floor
if let distortion = mapPoint.consensusDistortionVector {
    finalGhostPosition += simd_float3(distortion.x, 0, distortion.z)  // Horizontal correction
}
```

### `isZoneCorner` Determination

**NOT determined at spawn time in `plantGhostsForAllTriangleVerticesBilinear()`**

**Determined later:** In `handlePlaceGhostMarker()` notification handler (lines 1083-1092):

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

**Used in:** `MarkerOptions.isZoneCorner` (line 1106) to create composite ghost geometry

**Note:** The role check happens in the notification handler, not in the collection function. The collection function doesn't know or care about roles.

---

## Question 4: Notification Payloads

### `PlaceGhostMarker` Notification

**Posting location:** Line 1872-1879 in `plantGhostsForAllTriangleVerticesBilinear()`

**userInfo dictionary:**
```swift
userInfo: [
    "mapPointID": vertexID,        // UUID
    "position": finalGhostPosition  // simd_float3
]
```

**Keys and Types:**
- `"mapPointID"`: `UUID` (not String!)
- `"position"`: `simd_float3`

**Handler extraction:** Lines 1068-1069
```swift
guard let mapPointID = notification.userInfo?["mapPointID"] as? UUID,
      let position = notification.userInfo?["position"] as? simd_float3 else {
```

**Note:** `simd_float3` can be passed directly in `userInfo` because it's `Codable`.

### `SpawnNeighborCornerMarker` Notification

**Posting location:** Line 1630-1638 in `spawnDiamondMarker()`

**userInfo dictionary:**
```swift
userInfo: [
    "position": [position.x, position.y, position.z],  // [Float] array
    "mapPointID": mapPointID,                          // String
    "zoneName": zoneName                                // String
]
```

**Keys and Types:**
- `"position"`: `[Float]` - Array of 3 floats `[x, y, z]`
- `"mapPointID"`: `String` - UUID as string
- `"zoneName"`: `String` - Display name of zone

**Handler extraction:** Lines 282-284
```swift
let positionArray = userInfo["position"] as? [Float],
    positionArray.count == 3,
    let mapPointID = userInfo["mapPointID"] as? String else {
```

**Why `[Float]` instead of `simd_float3`?**

**Answer:** Likely because `simd_float3` may not serialize properly through NotificationCenter's `userInfo` dictionary. The `userInfo` dictionary uses `[String: Any]` which requires types that can be stored in `Any`. While `simd_float3` is `Codable`, NotificationCenter may not handle it correctly, so it's converted to a primitive array.

**Reconstruction:** Line 289
```swift
let position = simd_float3(positionArray[0], positionArray[1], positionArray[2])
```

---

## Question 5: Tracking Dictionary Locations

### Property Definitions in `ARCalibrationCoordinator`

**Location:** Lines 44, 55, 58, 166

#### `ghostMarkerPositions`

**Line 58:**
```swift
/// Ghost marker positions tracked by the coordinator (set by ARViewContainer)
var ghostMarkerPositions: [UUID: simd_float3] = [:]
```

**Published?** NO - Not `@Published`  
**UI Updates?** NO - Modifications don't trigger UI updates

**Note:** Comment says "set by ARViewContainer" - the coordinator's copy is updated by the AR view handler (line 1117).

#### `spawnedNeighborCornerIDs`

**Line 166:**
```swift
/// MapPoint IDs of neighbor corners that have been spawned as diamond markers
/// Prevents duplicate spawning when multiple planted zones share a neighbor
private(set) var spawnedNeighborCornerIDs: Set<String> = []
```

**Published?** NO - Not `@Published`  
**UI Updates?** NO - Modifications don't trigger UI updates  
**Access:** `private(set)` - Read-only from outside, writable internally

#### `mapPointARPositions`

**Line 44:**
```swift
/// Maps MapPoint ID to AR position for current session (for ghost calculation)
var mapPointARPositions: [UUID: simd_float3] = [:]
```

**Published?** NO - Not `@Published`  
**UI Updates?** NO - Modifications don't trigger UI updates

#### `adjustedGhostMapPoints`

**Line 55:**
```swift
/// MapPoints whose ghosts were adjusted to AR markers this session (prevents re-planting)
var adjustedGhostMapPoints: Set<UUID> = []
```

**Published?** NO - Not `@Published`  
**UI Updates?** NO - Modifications don't trigger UI updates

### Summary

**None of these properties are `@Published`**, so modifying them does **NOT** trigger SwiftUI view updates. They are internal state tracking dictionaries.

---

## Question 6: Current Deduplication in Each Function

### `spawnNeighborCornerMarkers()` Checks

**Exact checks before spawning (lines 1579-1606):**

1. **Zone-level check (line 1581):**
```swift
// Skip already-planted zones
if plantedZoneIDs.contains(neighborID) {
    print("   ⏭️ Neighbor '\(String(neighborID.prefix(8)))' already planted, skipping")
    continue
}
```

2. **Zone existence check (line 1586):**
```swift
guard let neighborZone = zoneStore.zone(withID: neighborID) else {
    print("   ⚠️ Neighbor zone '\(String(neighborID.prefix(8)))' not found")
    continue
}
```

3. **Prediction success check (line 1592):**
```swift
guard let predictions = predictNeighborCornerPositions(
    neighborZone: neighborZone,
    plantedZoneID: plantedZoneID
) else {
    print("   ⚠️ Failed to predict corners for '\(neighborZone.displayName)'")
    continue
}
```

4. **Per-corner deduplication (line 1603):**
```swift
// Skip if already spawned (from another planted zone)
if spawnedNeighborCornerIDs.contains(prediction.mapPointID) {
    print("   ⏭️ Corner \(String(prediction.mapPointID.prefix(8))) already spawned")
    continue
}
```

**After spawning (line 1615):**
```swift
spawnedNeighborCornerIDs.insert(prediction.mapPointID)
```

### `plantGhostsForAllTriangleVerticesBilinear()` Checks

**Exact checks before spawning (lines 1819-1850):**

1. **Bilinear setup check (line 1794):**
```swift
guard hasBilinearCorners else {
    print("❌ [ZONE_CORNER_GHOSTS_BILINEAR] Bilinear corners not set up")
    return
}
```

2. **Already has AR position check (line 1821):**
```swift
// Skip if already has AR position (placed as corner or already confirmed)
if mapPointARPositions[vertexID] != nil {
    skippedHasPosition += 1
    continue
}
```

3. **Already adjusted check (line 1827):**
```swift
// Skip if ghost was already adjusted
if adjustedGhostMapPoints.contains(vertexID) {
    skippedHasPosition += 1
    continue
}
```

4. **MapPoint existence check (line 1833):**
```swift
guard let mapPoint = safeMapStore.points.first(where: { $0.id == vertexID }) else {
    print("⚠️ [ZONE_CORNER_GHOSTS_BILINEAR] MapPoint \(String(vertexID.uuidString.prefix(8))) not found")
    skippedNoMapPoint += 1
    continue
}
```

5. **Bilinear projection success check (line 1847):**
```swift
guard var finalGhostPosition = projectPointViaBilinear(mapPoint: mapPoint.mapPoint) else {
    skippedOutsideQuad += 1
    continue
}
```

**After calculating position (line 1869):**
```swift
ghostMarkerPositions[vertexID] = finalGhostPosition
```

**Note:** `ghostMarkerPositions` is updated **BEFORE** posting notification, but this happens in the same function, so it's effectively part of the spawning process.

---

## Question 7: Return Values and Side Effects

### `spawnNeighborCornerMarkers()`

**Return type:** `Void` (no return value)

**Side effects:**
1. **Posts notifications:** `SpawnNeighborCornerMarker` via `spawnDiamondMarker()` (line 1630)
2. **Updates tracking dictionary:** `spawnedNeighborCornerIDs.insert(prediction.mapPointID)` (line 1615)
3. **Prints logs:** Various print statements for debugging

**Does NOT:**
- Update `ghostMarkerPositions`
- Update `mapPointARPositions`
- Update `adjustedGhostMapPoints`
- Return any value

### `plantGhostsForAllTriangleVerticesBilinear()`

**Return type:** `Void` (no return value)

**Side effects:**
1. **Posts notifications:** `PlaceGhostMarker` (line 1872)
2. **Updates tracking dictionary:** `ghostMarkerPositions[vertexID] = finalGhostPosition` (line 1869)
   - **Note:** This is updated **directly** in the function, before the notification handler runs
3. **Prints logs:** Various print statements and statistics

**Does NOT:**
- Update `spawnedNeighborCornerIDs`
- Update `mapPointARPositions` (only reads it)
- Update `adjustedGhostMapPoints` (only reads it)
- Return any value

### Key Difference

**`plantGhostsForAllTriangleVerticesBilinear()`** updates `ghostMarkerPositions` **directly** before posting notification.

**`spawnNeighborCornerMarkers()`** updates `spawnedNeighborCornerIDs` **directly** after posting notification.

Both functions update their respective tracking dictionaries **before** the notification handlers run, ensuring the dictionaries are populated synchronously.

---

## Question 8: Candidate Location for `spawnCollectedMarkers()`

### Current Flow

**After both collection functions:**
- Line 1361: `spawnNeighborCornerMarkers()` completes
- Line 1432: `plantGhostsForAllTriangleVerticesBilinear()` completes
- Line 1434-1455: Origin marker planting
- Line 1458: `calibrationState = .readyToFill` (state transition)

### Clean Insertion Point

**Recommended location:** **Line 1456** (after origin marker planting, before state transition)

**Rationale:**
1. Both collection functions have completed
2. Origin marker has been planted (if applicable)
3. All marker data has been collected and stored in tracking dictionaries
4. State transition hasn't happened yet
5. Clean separation: collection → spawning → state transition

**Proposed code structure:**
```swift
// Line 1432: plantGhostsForAllTriangleVerticesBilinear() completes

// Line 1434-1455: Origin marker planting

// NEW: Unified spawning point
spawnCollectedMarkers()  // <-- Insert here (line 1456)

// Line 1458: Transition to crawl mode
calibrationState = .readyToFill
```

### Alternative Location

**Line 1433** (between `plantGhostsForAllTriangleVerticesBilinear()` and origin marker planting)

**Pros:**
- Immediately after both collection functions
- Before any other marker operations

**Cons:**
- Origin marker is a special case that might need different handling
- Less clear separation between collection and spawning

### Recommended Approach

**Insert at line 1456** with this structure:

```swift
// Plant ghosts using bilinear projection only
plantGhostsForAllTriangleVerticesBilinear()

// Plant origin marker at map center projected via bilinear
if let mapSize = cachedMapSize {
    // ... origin marker code ...
}

// UNIFIED MARKER SPAWNING: Spawn all collected markers with deduplication
spawnCollectedMarkers()

// Transition to crawl mode
calibrationState = .readyToFill
```

This ensures:
- All collection is complete
- Origin marker is handled separately (if needed)
- Unified spawning happens once
- State transition is the final step

---

## Summary for Unified Architecture Design

### Data Collection Phase

**Function 1:** `spawnNeighborCornerMarkers()`
- Collects: `(mapPointID: String, position: simd_float3, zoneName: String)`
- Stores in: `spawnedNeighborCornerIDs` (Set<String>)
- Immediately spawns: YES (posts notification)

**Function 2:** `plantGhostsForAllTriangleVerticesBilinear()`
- Collects: `(vertexID: UUID, finalGhostPosition: simd_float3)`
- Stores in: `ghostMarkerPositions` (Dictionary<UUID, simd_float3>)
- Immediately spawns: YES (posts notification)

### Proposed Unified Collection

**New function:** `collectAllPendingMarkers() -> [PendingMarker]`

**Data structure:**
```swift
struct PendingMarker {
    let mapPointID: UUID
    let position: simd_float3
    let sourceType: MarkerSourceType  // .neighborZoneCorner, .triangleVertex, .origin
    let zoneID: String?
    let zoneName: String?
    let isZoneCorner: Bool  // Determined from MapPoint roles
}
```

**Unified spawning:** `spawnCollectedMarkers(_ markers: [PendingMarker])`
- Single deduplication check
- Single notification posting
- Single tracking dictionary update

**Insertion point:** Line 1456 (after origin marker, before state transition)
