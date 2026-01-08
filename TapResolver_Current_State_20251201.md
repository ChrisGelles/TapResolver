# TapResolver: Current State Summary
**Date:** December 1, 2025  
**Session Context:** Ghost marker fixes, PiP map investigation, architectural analysis

---

## What's Working

### Ghost Marker Duplication Fix ✅
**File:** `ARCalibrationCoordinator.swift` (~line 858)

Changed duplicate check from `arWorldMapStore.markers` to `mapPointARPositions`:
```swift
// OLD (broken): Only checked regular calibration path
let hasMarkerInCurrentSession = arWorldMapStore.markers.contains { ... }

// NEW (working): Checks session-wide dictionary updated by BOTH paths
let hasPositionInCurrentSession = mapPointARPositions[farVertexID] != nil
```

**Verified:** Console shows `⏭️ [GHOST_PLANT] Skipping MapPoint XXXX - already has AR position in current session`

### GhostInteractionButtons Wiring Fix ✅
**File:** `ARViewWithOverlays.swift` (~line 610)

Callbacks were mis-wired - each closure body was assigned to wrong parameter:
- `onConfirmGhost` → was doing reposition logic
- `onPlaceMarker` → was doing confirm logic  
- `onReposition` → was doing place marker logic

**Fixed:** All three callbacks now execute correct behavior. "Place Marker" button works during initial calibration.

### Ghost Visibility Detection ✅
**File:** `ARViewContainer.swift`

Three-state UI for ghost interaction:
1. Ghost selected AND visible → Show Confirm/Adjust/Reposition buttons
2. Ghost nearby but NOT visible (behind user) → Show "Unconfirmed Marker Nearby" message
3. No ghost nearby → Show standard "Place Marker" button

Uses `isPositionInCameraView()` with 50pt screen margin.

### Reposition Marker Feature ✅
**File:** `GhostInteractionButtons.swift`, `ARViewWithOverlays.swift`

Purple "Reposition Marker" button added for large spaces where ghost is far from correct position:
- Removes ghost from scene
- Sets `pendingRepositionMapPointID`
- Returns to standard placement mode
- Next marker placed targets the original ghost's MapPoint

---

## Known Issues (Not Yet Fixed)

### Main Thread Safety Warning ⚠️
**File:** `ARViewContainer.swift`

`isPositionInCameraView()` accesses `sceneView.bounds` from SceneKit's background rendering queue.

**Fix specified but not applied:**
1. Add `cachedViewBounds: CGRect` property to Coordinator
2. Update in `updateUIView()` on main thread
3. Use cached bounds in `isPositionInCameraView()`

**Impact:** Feature works despite race condition, but may cause intermittent issues.

### PiP Map Not Following User ❌
**File:** `ARViewWithOverlays.swift`

User position should display on PiP map during crawl mode. Currently not working.

**Root cause identified:** `projectARPositionToMap()` looks for AR positions in wrong data path:
- Currently uses: `triangle.arMarkerIDs` → `arStore.marker()`
- Should use: `mapPointARPositions` (session-wide dictionary)

**Architectural decision made:** Rebuild projection to:
1. Use `mapPointARPositions` as source of truth
2. Iterate ALL triangles with 3 calibrated vertices
3. Find containing triangle via barycentric weights
4. Extrapolate when outside all triangles (same math as ghost planting)
5. Work in ANY state (not just `.readyToFill`)

### Crawl Mode Ignores Historical Consensus ❌
**File:** `ARCalibrationCoordinator.swift`

`calculateGhostPosition()` (line 528, crawl mode) only uses current session data.

`calculateGhostPositionForThirdVertex()` (line 683, initial calibration) correctly uses:
1. Historical consensus positions
2. Rigid transform from consensus → current frame
3. Fallback to 2D map geometry

**Fix needed:** Add same consensus + transform priority to `calculateGhostPosition()`.

### Triangle Calibration Persistence in Crawl Mode ❓
**Suspected issue:** Triangles activated via crawl may not be marked `isCalibrated = true`.

**Not yet verified.** Need to trace `activateAdjacentTriangle()` vs `finalizeCalibration()`.

---

## Session-Scoped vs Persisted Data

| Data | Scope | Location | Updated By |
|------|-------|----------|------------|
| `mapPointARPositions` | Session | Coordinator | Both calibration paths ✅ |
| `sessionMarkerPositions` | Session | Coordinator | Regular calibration |
| `MapPoint.positionHistory` | Persisted | MapPointStore | Both paths (via `addPositionRecord`) |
| `MapPoint.consensusPosition` | Computed | MapPoint | Derived from positionHistory |
| `triangle.arMarkerIDs` | Persisted | TrianglePatchStore | Regular calibration only ⚠️ |
| `triangle.isCalibrated` | Persisted | TrianglePatchStore | `finalizeCalibration()` only ⚠️ |

---

## Files Modified This Session

| File | Changes |
|------|---------|
| `ARCalibrationCoordinator.swift` | Ghost duplicate check fix |
| `ARViewWithOverlays.swift` | Callback wiring fix, `pendingRepositionMapPointID` state |
| `GhostInteractionButtons.swift` | Added `onReposition` callback, purple button |
| `ARViewContainer.swift` | (Main thread fix specified, not applied) |

---

## Architecture Documents Created

1. **TapResolver_Triangular_Distortion_Grid_Architecture.md**
   - Full TIN rubber-sheet model explanation
   - Coordinate frame alignment via consensus + rigid transform
   - Self-reinforcing calibration loop
   - Implementation gaps and priorities
   - Code locations for fixes

---

## Next Session Priorities

### Priority 1: Fix Crawl Mode Ghost Planting
Add consensus + transform logic to `calculateGhostPosition()`:
```
PRIORITY 1: Check consensusPosition + compute rigid transform
PRIORITY 2: Fall back to current session barycentric (existing code)
```

### Priority 2: Fix User Position Projection
Rewrite `projectARPositionToMap()`:
- Move to coordinator (owns `mapPointARPositions`)
- Iterate all usable triangles
- Find containing triangle or extrapolate from nearest
- Remove `.readyToFill` state dependency

### Priority 3: Verify Triangle Calibration Persistence
Trace `activateAdjacentTriangle()` to ensure crawled triangles get `isCalibrated = true`.

### Priority 4: Apply Main Thread Safety Fix
Cache `sceneView.bounds` on main thread for background access.

---

## Files to Upload Next Session

- `ARCalibrationCoordinator.swift` (full, for ghost calculation fixes)
- `MapPointStore.swift` or `MapPoint.swift` (for consensusPosition implementation)
- `TapResolver_Triangular_Distortion_Grid_Architecture.md` (as context)
- This document (as current state reference)

---

## Console Logging Reference

**Working indicators:**
- `⏭️ [GHOST_PLANT] Skipping MapPoint XXXX - already has AR position` → Duplicate prevention working
- `👻 [GHOST_NEARBY] Ghost XXXX is X.XXm away but not in camera view` → Visibility detection working
- `🔍 [PLACE_MARKER_BTN] Button tapped` followed by `PlaceMarkerAtCursor` → Correct callback

**Problem indicators:**
- `🎯 [PIP_TRANSFORM] readyToFill state - calculating triangle bounds` → User follow NOT working (should show `📍 [PIP_TRANSFORM] Following user at...`)
- `📐 [GHOST_3RD] No consensus - calculating from 2D map geometry` → Historical data not being used
- `⚠️ [GHOST_UI] No ghost position/ID available for confirmation` → Wrong callback executing

---

## Token Usage

Session ended at ~188,000 / 190,000 tokens (99%)
