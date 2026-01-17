# Wavefront Zone Calibration State Investigation
**Date:** January 16, 2025  
**Focus:** Understanding neighbor zone filtering, planted zone tracking, and wavefront propagation

---

## Question 1: Neighbor Zone Filtering

### Collection Iterated Over

**Answer:** `spawnNeighborCornerMarkers()` iterates over `plantedZone.neighborZoneIDs`

**Exact Loop Structure:**

```1593:1642:TapResolver/TapResolver/State/ARCalibrationCoordinator.swift
for neighborID in plantedZone.neighborZoneIDs {
    // Skip already-planted zones
    if plantedZoneIDs.contains(neighborID) {
        print("   ⏭️ Neighbor '\(String(neighborID.prefix(8)))' already planted, skipping")
        continue
    }
    
    guard let neighborZone = zoneStore.zone(withID: neighborID) else {
        print("   ⚠️ Neighbor zone '\(String(neighborID.prefix(8)))' not found")
        continue
    }
    
    // Predict corner positions
    guard let predictions = predictNeighborCornerPositions(
        neighborZone: neighborZone,
        plantedZoneID: plantedZoneID
    ) else {
        print("   ⚠️ Failed to predict corners for '\(neighborZone.displayName)'")
        continue
    }
    
    // Collect neighbor corner markers for unified spawning
    for prediction in predictions {
        // ... collection logic ...
    }
}
```

**Filtering Applied:**
1. **Zone-level filter:** `if plantedZoneIDs.contains(neighborID)` — skips already-planted zones
2. **Zone existence check:** `guard let neighborZone = zoneStore.zone(withID: neighborID)` — skips missing zones
3. **Prediction success check:** `guard let predictions = predictNeighborCornerPositions(...)` — skips zones where prediction fails

---

## Question 2: Planted Zone Tracking

### `plantedZoneIDs` Definition

**Location:** Line 173 in `ARCalibrationCoordinator.swift`

```swift
private(set) var plantedZoneIDs: Set<String> = []
```

**Access:** `private(set)` — read-only externally, writable internally

### What Adds Zones to It

**Function:** `markZoneAsPlanted(_ zoneID: String)` (line 1489)

```1489:1500:TapResolver/TapResolver/State/ARCalibrationCoordinator.swift
func markZoneAsPlanted(_ zoneID: String) {
    guard !plantedZoneIDs.contains(zoneID) else {
        print("📐 [ARCalibrationCoordinator] Zone \(String(zoneID.prefix(8))) already planted")
        return
    }
    
    plantedZoneIDs.insert(zoneID)
    print("✅ [ARCalibrationCoordinator] Zone planted: \(String(zoneID.prefix(8))) (total planted: \(plantedZoneIDs.count))")
    
    // Trigger wavefront propagation
    onZonePlanted?(zoneID)
}
```

**Called From:** `registerZoneCornerAnchor()` when all 4 corners are placed (line 1367)

### What Removes Zones from It

**Function:** `resetPlantedZones()` (line 1508)

```1508:1514:TapResolver/TapResolver/State/ARCalibrationCoordinator.swift
func resetPlantedZones() {
    let zoneCount = plantedZoneIDs.count
    let cornerCount = spawnedNeighborCornerIDs.count
    plantedZoneIDs.removeAll()
    spawnedNeighborCornerIDs.removeAll()
    print("🔄 [ARCalibrationCoordinator] Reset planted zones (was \(zoneCount) zones, \(cornerCount) spawned corners)")
}
```

**Called:** On session start/end (not shown in current code, but likely called from session reset)

### Check for Already-Planted Neighbors

**YES** — Line 1595:

```swift
if plantedZoneIDs.contains(neighborID) {
    print("   ⏭️ Neighbor '\(String(neighborID.prefix(8)))' already planted, skipping")
    continue
}
```

This prevents spawning neighbor corners for zones that have already been fully planted.

---

## Question 3: Shared Corner Detection

### Checks Before Spawning Diamond Marker

**In `spawnNeighborCornerMarkers()` (collection phase):**

1. **`pendingMarkers[mapPointUUID] != nil`** (line 1622)
   - Skips if already collected in this cycle

2. **`mapPointARPositions[mapPointUUID] != nil`** (line 1628)
   - Skips if already has AR position (shared corner from planted zone)

**In `spawnCollectedMarkers()` (spawning phase):**

3. **`shouldSpawnMarker(mapPointID:)`** (line 1737) — unified deduplication check:
   - `mapPointARPositions[mapPointID] != nil` (line 1717)
   - `adjustedGhostMapPoints.contains(mapPointID)` (line 1719)
   - `ghostMarkerPositions[mapPointID] != nil` (line 1721)
   - `spawnedNeighborCornerIDs.contains(mapPointID.uuidString)` (line 1723)

### Does It Check Triangle Vertex Confirmation?

**YES** — Indirectly:

- `mapPointARPositions[mapPointUUID] != nil` check (line 1628) will be true if:
  - Corner was placed as zone corner (during `registerZoneCornerAnchor()`)
  - Corner was confirmed as triangle vertex (via `registerFillPointMarker()` or `registerMarker()`)
  - Corner was confirmed as ghost (via `registerFillPointMarker()`)

**However:** There is **NO explicit check** for "was this corner already confirmed as a triangle vertex" — it relies on the `mapPointARPositions` dictionary being populated.

---

## Question 4: Zone Completion Tracking

### Mechanism for Tracking All Triangle Vertices Confirmed

**Answer:** **NO explicit zone completion tracking mechanism found**

**Searched for:**
- `zoneCompletionStatus` — **NOT FOUND**
- `onZoneComplete` — **NOT FOUND**
- `onAllVerticesConfirmed` — **NOT FOUND**

**What EXISTS:**
- `onZonePlanted` callback (line 181) — triggered when zone corners are placed, NOT when triangle vertices are confirmed
- `plantedZoneIDs` — tracks zones with all 4 corners placed, NOT zones with all triangle vertices confirmed

### Triangle Membership Tracking

**Zone has `memberTriangleIDs`** (computed in `ZoneStore.computeTriangleMembership()`), but:

- **NO check** in `ARCalibrationCoordinator` that verifies all vertices of `memberTriangleIDs` are confirmed
- **NO callback** triggered when a zone's triangles become fillable
- **NO mechanism** to detect "zone is complete" based on triangle vertex confirmations

**Conclusion:** Zone completion is tracked only at the **corner level** (4 corners = planted), not at the **triangle vertex level**.

---

## Question 5: Triangle Vertex Confirmation Flow

### Function That Handles Confirmation

**Primary function:** `registerFillPointMarker()` (line 1670)

**Also:** `registerMarker()` (line 858) — for initial placements

### Does It Check Zone Completion?

**NO** — `registerFillPointMarker()` does NOT check:
- If this was the last unconfirmed vertex in a zone
- If zone completion should be triggered
- If wavefront propagation should cascade

**What It Does:**
1. Registers marker→MapPoint mapping
2. Updates `mapPointARPositions[mapPointID]`
3. Records position history
4. Updates baked canonical position
5. **NO zone completion check**

### Does It Trigger Cascade?

**NO** — No cascade or wavefront propagation triggered by triangle vertex confirmation.

**Wavefront propagation only happens:**
- When zone corners are placed (via `markZoneAsPlanted()` → `onZonePlanted?` callback)
- **NOT** when triangle vertices are confirmed

---

## Question 6: Neighbor Corner Prediction Source

### Bilinear Projection Used

**Answer:** Uses the **planted zone's corners** for bilinear projection

**Flow in `predictNeighborCornerPositions()`:**

```1534:1558:TapResolver/TapResolver/State/ARCalibrationCoordinator.swift
// Get planted zone's corner correspondences (map → AR)
var plantedMapCorners: [CGPoint] = []
var plantedARCorners: [simd_float3] = []

for cornerID in plantedZone.cornerMapPointIDs {
    guard let mapPoint = safeMapStore.points.first(where: { $0.id.uuidString == cornerID }) else {
        print("⚠️ [WAVEFRONT] Planted zone corner \(String(cornerID.prefix(8))) not found in MapPointStore")
        return nil
    }
    
    // Get the AR position for this corner (from mapPointARPositions we stored during placement)
    guard let arPosition = mapPointARPositions[mapPoint.id] else {
        print("⚠️ [WAVEFRONT] No AR position for planted corner \(String(cornerID.prefix(8)))")
        return nil
    }
    
    plantedMapCorners.append(mapPoint.mapPoint)
    plantedARCorners.append(arPosition)
}

// Create bilinear projection from planted zone
guard let projection = BilinearProjection(mapCorners: plantedMapCorners, arCorners: plantedARCorners) else {
    print("⚠️ [WAVEFRONT] Failed to create bilinear projection")
    return nil
}
```

### Does It Check Position History?

**NO** — `predictNeighborCornerPositions()` does **NOT** check:
- Historical position records
- Consensus positions
- Baked canonical positions

**Priority:** **Bilinear prediction ONLY** — no fallback to historical data

**Note:** The function only uses `mapPointARPositions` to get the planted zone's corner positions. It does not check if the neighbor corner has historical data before predicting.

---

## Question 7: Current Dedup Checks in `spawnNeighborCornerMarkers()`

### ALL Checks Before Collection (Not Spawning)

**In the `for prediction in predictions` loop (lines 1615-1641):**

1. **UUID conversion check** (line 1616):
   ```swift
   guard let mapPointUUID = UUID(uuidString: prediction.mapPointID) else {
       print("   ⚠️ Invalid UUID string: \(prediction.mapPointID)")
       continue
   }
   ```

2. **`pendingMarkers[mapPointUUID] != nil`** (line 1622):
   ```swift
   if pendingMarkers[mapPointUUID] != nil {
       print("   ⏭️ Corner \(String(prediction.mapPointID.prefix(8))) already collected")
       continue
   }
   ```

3. **`mapPointARPositions[mapPointUUID] != nil`** (line 1628):
   ```swift
   if mapPointARPositions[mapPointUUID] != nil {
       print("   ⏭️ Corner \(String(prediction.mapPointID.prefix(8))) already placed")
       continue
   }
   ```

**Note:** `spawnNeighborCornerMarkers()` now **collects** markers instead of spawning immediately. The actual spawning happens later in `spawnCollectedMarkers()`.

### Dedup Checks in `spawnCollectedMarkers()` (Actual Spawning)

**In `spawnCollectedMarkers()` (line 1737):**

Calls `shouldSpawnMarker(mapPointID:)` which checks:

1. **`mapPointARPositions[mapPointID] != nil`** (line 1717)
2. **`adjustedGhostMapPoints.contains(mapPointID)`** (line 1719)
3. **`ghostMarkerPositions[mapPointID] != nil`** (line 1721)
4. **`spawnedNeighborCornerIDs.contains(mapPointID.uuidString)`** (line 1723)

**After spawning neighbor corner:**
- Updates `spawnedNeighborCornerIDs.insert(mapPointID.uuidString)` (line 1754)

---

## Question 8: What Triggers After `spawnNeighborCornerMarkers()`?

### Sequence After `spawnNeighborCornerMarkers()` Completes

**Location:** In `registerZoneCornerAnchor()` completion flow (lines 1361-1470)

**Exact Sequence:**

```1361:1470:TapResolver/TapResolver/State/ARCalibrationCoordinator.swift
} else {
    // All corners placed - set up bilinear projection and plant ghosts
    print("✅ [ZONE_CORNER] All \(totalCorners) corners placed")
    
    // Mark zone as planted for wavefront propagation
    if let zoneID = activeZoneID, totalCorners == 4 {
        markZoneAsPlanted(zoneID)
        
        // Spawn neighbor corner markers
        if let zone = safeZoneStore?.zone(withID: zoneID) {
            print("🌊 [WAVEFRONT] Zone '\(zone.displayName)' planted — \(zone.neighborZoneIDs.count) neighbors ready for prediction")
            spawnNeighborCornerMarkers(for: zoneID)  // <-- LINE 1372
        }
    }
    
    // Save the starting corner index to Zone for rotation tracking
    // ... (lines 1376-1381) ...
    
    // BILINEAR SETUP: Gather and sort corner data
    // ... (lines 1383-1440) ...
    
    // Plant ghosts using bilinear projection only
    plantGhostsForAllTriangleVerticesBilinear()  // <-- LINE 1443
    
    // Plant origin marker at map center projected via bilinear
    // ... (lines 1445-1466) ...
    
    // Unified marker spawning with deduplication
    spawnCollectedMarkers()  // <-- LINE 1469
    
    // Transition to crawl mode
    calibrationState = .readyToFill
    statusText = "Zone corners complete - adjust ghosts as needed"
    print("🎯 [ZONE_CORNER] Entering crawl mode with \(ghostMarkerPositions.count) ghost(s)")
}
```

### Could Triangle Vertex Ghosts Duplicate Diamond Markers?

**YES** — Potential duplication risk exists:

**Timeline:**
1. **Line 1372:** `spawnNeighborCornerMarkers()` collects neighbor corners into `pendingMarkers`
2. **Line 1443:** `plantGhostsForAllTriangleVerticesBilinear()` collects triangle vertices into `pendingMarkers`
   - **Checks:** `if pendingMarkers[vertexID] != nil` (line 1954) — skips if already collected as neighbor corner
3. **Line 1469:** `spawnCollectedMarkers()` spawns all collected markers with unified deduplication

**Protection:**
- **Collection phase:** `plantGhostsForAllTriangleVerticesBilinear()` checks `pendingMarkers` before collecting (line 1954)
- **Spawning phase:** `spawnCollectedMarkers()` calls `shouldSpawnMarker()` which checks all tracking dictionaries

**However:** If a MapPoint has both `.zoneCorner` and `.triangleEdge` roles:
- It could be collected as neighbor corner (diamond) in step 1
- It would be skipped in step 2 (already in `pendingMarkers`)
- It would spawn as diamond in step 3

**Result:** No duplication — the unified collection/spawning prevents it.

---

## Summary of Findings

### Key Insights

1. **Neighbor filtering:** Uses `plantedZone.neighborZoneIDs` with `plantedZoneIDs.contains()` check
2. **Planted tracking:** `plantedZoneIDs` tracks zones with 4 corners placed, reset on session end
3. **Shared corner detection:** Checks `mapPointARPositions` before collecting, but no explicit triangle vertex check
4. **Zone completion:** **NO mechanism** tracks when all triangle vertices in a zone are confirmed
5. **Vertex confirmation:** Does NOT trigger wavefront propagation or zone completion checks
6. **Prediction source:** Uses planted zone's bilinear projection, **NO historical data fallback**
7. **Dedup checks:** Multiple layers — collection phase + unified spawning phase
8. **Duplication risk:** Protected by unified collection/spawning architecture

### Gaps Identified

1. **No zone completion tracking** based on triangle vertex confirmations
2. **No historical data fallback** in neighbor corner prediction
3. **No cascade trigger** when triangle vertices complete a zone's triangles

### Current Architecture Strengths

1. **Unified collection/spawning** prevents double-spawning
2. **Multiple dedup layers** catch duplicates at different stages
3. **Planted zone tracking** prevents re-spawning neighbor corners for completed zones
