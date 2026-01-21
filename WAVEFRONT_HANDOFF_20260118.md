# Wavefront Zone Calibration — Session Handoff
## Date: January 18, 2026

---

## Current State: Phase 3 COMPLETE, Refinements Needed

The Wavefront Zone Calibration system is **functional**. All 5 test zones (kitchen-area, diningroom, LR-north, office, LR-south) were successfully calibrated in a single session lasting ~8.75 minutes with 27 MapPoints confirmed.

### What's Working

1. **Corner Mesh Transform** — Similarity transform (scale + rotation + translation) computed from confirmed corner correspondences. Sub-10cm RMS errors consistently.

2. **Wavefront Progression** — Zones cascade correctly:
   - Initial zone planted → neighbor corners become eligible
   - "Plot Next Zone" button appears when near eligible corner
   - Tapping spawns 3 remaining corner ghosts for neighbor zone
   - After 4/4 corners confirmed → triangle ghosts spawn

3. **Interior Corners Detection** — NEW: Zones whose corners lie INSIDE another zone's polygon are now reachable. This solved the LR-north/LR-south isolation problem.

4. **Deduplication** — `markerExistsForMapPoint()` unified check prevents most duplicate spawning.

5. **Bilinear Projection with Distortion Correction** — Ghost positions predicted via bilinear frame, then corrected using accumulated distortion vectors.

---

## Immediate Refinements (Priority Order)

### Refinement 1: Bilinear Corner Data Capture

**Problem:** When `startNextZoneCalibration()` detects a corner "already has marker, counting as confirmed", it doesn't ensure that corner's AR position is in `mapPointARPositions`. Later, `setupBilinearCornersFromZone()` fails because it can't find all 4 corners.

**Evidence from log:**
```
🌊 [WAVEFRONT_V2] Corner 4 (0AEDA4D2) already has marker, counting as confirmed
...
⚠️ [BILINEAR_SETUP] Missing data for corner 0AEDA4D2
❌ [BILINEAR_SETUP] Expected 4 corners, got 3
```

**Root Cause:** The check `markerExistsForMapPoint(cornerID)` returns true (marker exists), but if the marker was placed via a different code path (e.g., as a triangle vertex or interior corner), `mapPointARPositions[cornerID]` might not have been set.

**Fix Location:** `ARCalibrationCoordinator.swift`, in `startNextZoneCalibration()`, around the loop that checks existing corners.

**Fix Approach:** When a corner is detected as "already has marker", verify `mapPointARPositions[cornerID]` exists. If not, attempt to retrieve position from:
1. `ghostMarkerPositions[cornerID]` (if still a ghost)
2. Scene node lookup via `sessionMarkerToMapPoint` reverse lookup
3. If all else fails, log error but don't count as confirmed

**Cursor Investigation Questions:**
1. In `startNextZoneCalibration()`, show the complete logic for the "already has marker" path
2. What dictionaries track AR positions for placed markers? Is there redundancy?
3. When `placeMarker()` is called, does it always update `mapPointARPositions`?

---

### Refinement 2: Throttle AR_NORTH Logging

**Problem:** The AR north angle calculation logs every frame, creating spam similar to `UpdateGhostSelection`.

**Evidence:**
```
🧭 [AR_NORTH] South=(0.63, 1.21) North=(1.70, 1.49) → AR north angle=14.7°
🧭 [AR_NORTH] South=(0.63, 1.21) North=(1.70, 1.49) → AR north angle=14.7°
... (repeated hundreds of times)
```

**Fix:** Add throttling — only log when angle changes by more than 1° or on first calculation.

**Fix Location:** Find `[AR_NORTH]` logging and add throttle property + conditional.

---

### Refinement 3: Investigate PiP Map Warning

**Problem:** Frequent warning that may or may not indicate a real issue:
```
⚠️ PiP Map: isCalibrationMode=true, focusedPointID=nil, currentVertexIndex=3
```

**Action:** Determine if this is:
- Expected state during zone corner calibration (benign)
- Indicating missing focus point (bug)
- Just noisy logging that should be removed

---

### Refinement 4: UpdateGhostSelection Spam (INSTRUCTIONS PROVIDED)

**Status:** Cursor instructions were provided but may not be implemented yet.

**Fix:** In `ARViewContainer.swift`, add `lastLoggedGhostCount` property and only log when count changes.

---

## Next Milestones (From Original Roadmap)

### Phase 4: Corner Distortion Recording

**Goal:** When user adjusts a corner ghost to a different position than predicted, record the `predicted - actual` vector as a distortion sample.

**Purpose:** These distortion vectors improve future predictions. If corner A was off by (0.1m, 0.05m), nearby points should apply similar correction.

**Implementation:**
1. In ghost confirmation flow, compare `originalGhostPosition` to `actualPlacementPosition`
2. Store distortion in MapPoint or separate `CornerDistortion` struct
3. When projecting future ghosts, interpolate nearby distortion vectors

**Already Partially Working:** The log shows distortion vectors being applied:
```
📐 [GHOST_CORRECTION] 0AEDA4D2: applied distortion (0.099, -0.048)m, magnitude=0.110m
```

This suggests distortion recording exists but may need refinement for corner-specific handling.

---

### Phase 5: Invitation Ghost

**Goal:** After completing a zone, spawn a single "invitation ghost" at the closest reachable neighbor corner to guide the user toward the next expansion opportunity.

**Current State:** After zone completion, ALL neighbor corners spawn (if not already placed). This works but doesn't guide the user.

**Implementation:**
1. After zone completion, find the closest unplanted neighbor zone corner
2. Spawn only that one ghost with special visual treatment (pulsing? different color?)
3. When user confirms it, "Plot Next Zone" appears as usual

---

### Phase 6: Multi-Zone Corner Tie-Breaking

**Goal:** Handle corners shared by 3+ zones gracefully.

**Current State:** `checkNextZoneEligibility()` returns the first unplanted zone containing a corner. If multiple zones share that corner, selection is arbitrary.

**Implementation:**
1. When multiple zones share a corner, present UI to choose which zone to expand
2. Or: automatically select based on:
   - Zone with most corners already confirmed
   - Zone with smallest area (calibrate smaller zones first)
   - User preference/priority setting

---

### Future Enhancement: Confidence-Based Weighting

**Goal:** Weight position samples by confidence when computing consensus positions.

**Factors affecting confidence:**
- Distance from bilinear frame center (extrapolation = lower confidence)
- Number of position history samples
- Age of samples (recent = higher confidence)
- RMS error of Corner Mesh transform at time of capture

---

### Future Enhancement: Automatic Drift Detection

**Goal:** Use corner markers with known geometric relationships to detect when AR session has drifted.

**Implementation:**
1. Corners with roles like `.convexCorner` and `.concaveCorner` have known map positions
2. Periodically re-project these corners and compare to their placed AR positions
3. If discrepancy exceeds threshold, warn user or trigger recalibration

---

## Key Architecture Context

### Four Coordinate Systems

1. **Map Pixel** — 2D pixel coordinates on floor plan image (origin: top-left)
2. **Map Meters** — 2D real-world meters (scaled from pixels via `metersPerPixel`)
3. **Canonical/Baked** — 3D reference frame for persistent storage (survives sessions)
4. **AR Session** — 3D coordinates in current ARKit session (ephemeral)

### Transform Hierarchy

```
Map Pixel → (metersPerPixel) → Map Meters
                                    ↓
                            Corner Mesh Transform
                            (similarity: scale + rotation + translation)
                                    ↓
                              AR Session XZ
                                    ↓
                            + Ground Plane Y
                                    ↓
                              AR Session 3D
```

### Key Dictionaries

| Dictionary | Purpose |
|------------|---------|
| `mapPointARPositions[UUID]` | AR position of confirmed markers |
| `ghostMarkerPositions[UUID]` | AR position of spawned ghosts |
| `adjustedGhostMapPoints` | Set of MapPoint IDs converted from ghost to marker |
| `spawnedNeighborCornerIDs` | Set of corner IDs spawned as diamond markers |
| `pendingMarkers[UUID]` | Markers collected for batch spawning |
| `sessionMarkerToMapPoint[String]` | Marker UUID → MapPoint UUID mapping |

### Key Functions

| Function | Purpose |
|----------|---------|
| `markerExistsForMapPoint(_:)` | Unified check for ANY marker existence |
| `computeCornerMeshTransform()` | Compute similarity transform from correspondences |
| `gatherCornerCorrespondences()` | Collect all confirmed corner (map, AR) pairs |
| `startNextZoneCalibration()` | Spawn corner ghosts for neighbor zone |
| `plantGhostsForAllTriangleVerticesBilinear()` | Spawn triangle vertex ghosts |
| `spawnInteriorZoneCorners()` | NEW: Find and spawn corners inside zone polygon |
| `spawnCollectedMarkers()` | Batch spawn all pending markers |
| `setupBilinearCornersFromZone()` | Configure bilinear frame from 4 zone corners |

---

## Files to Request for Continuation

If starting fresh session, request these files:

1. `ARCalibrationCoordinator.swift` — Main calibration state machine
2. `ARViewContainer.swift` — AR scene management, marker spawning
3. `ARViewWithOverlays.swift` — UI overlays, button handlers
4. `ZoneStore.swift` — Zone data and neighbor relationships
5. Most recent console log — For debugging context

---

## Test Procedure for Verification

1. Start calibration in kitchen-area zone
2. Place 4 corner markers
3. Confirm neighbor zone corner (should show diamond)
4. Tap "Plot Next Zone" when button appears
5. Verify 3 corner ghosts spawn at predicted positions
6. Confirm all 4 corners
7. Verify triangle ghosts spawn (check for `UNIFIED_SPAWN` log)
8. Verify no duplicate markers appear
9. Continue wavefront to remaining zones
10. Verify interior corners enable reaching isolated zones

---

## Session Statistics (Last Successful Run)

- **Date:** January 18, 2026, 16:19
- **Duration:** 525 seconds
- **Zones planted:** 5 (kitchen-area, diningroom, LR-north, office, LR-south)
- **MapPoints confirmed:** 27
- **Corner Mesh RMS errors:** 0.081m, 0.093m, 0.096m
- **Duplicates prevented:** 7 (via dedup)
- **Interior corners found:** 2 (61DD1DAF in diningroom, 9F5A872B in office)

---

## Known Issues Not Yet Addressed

1. **Demote flow complexity** — Users sometimes need to demote and re-confirm corners to trigger eligibility. Flow should be smoother.

2. **CRAWL_CROSSHAIR path** — Fixed to update `adjustedGhostMapPoints` and `mapPointARPositions`, but verify fix was applied.

3. **Position history not visibly improving** — User observed markers not improving with repeated placements. May need investigation into history accumulation.

4. **Zone topology assumptions** — System assumes 4-corner quadrilateral zones. Triangular or 5+ corner zones not supported.

---

## Architectural Principles (From Chris)

1. **DRY** — Don't duplicate functionality. Check for existing code before creating new.
2. **Evidence-based debugging** — Console logs before accepting solutions.
3. **Surgical changes** — Incremental fixes over wholesale refactoring.
4. **Data integrity** — Never corrupt position history or baked positions.
5. **Machine metaphor** — Functions are machines with inputs, operations, and outputs.

---

*Document generated for session continuity. Last updated: January 18, 2026, ~16:30*
