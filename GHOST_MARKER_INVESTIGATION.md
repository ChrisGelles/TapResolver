# Ghost Marker Visibility Investigation

**Date:** 2025-01-XX  
**Purpose:** Investigate why ghost markers may not appear during calibration crawl when survey markers are present

---

## Question 1: Ghost Marker State Control

### Findings

**No explicit `ghostMarkersEnabled` boolean found.** Ghost marker visibility is controlled by:

1. **Creation Conditions** - Ghosts are created when:
   - `plantGhostsForAdjacentTriangles()` is called after triangle calibration completes
   - `RefreshAdjacentGhosts` notification is handled (during crawl mode)

2. **State Checks** - Ghost creation checks:
   - Vertex already has AR position in `mapPointARPositions` → Skip
   - Ghost already exists → Skip
   - Cannot calculate ghost position → Skip
   - No adjacent triangles → Skip

**Key Code Locations:**
- `ARCalibrationCoordinator.plantGhostsForAdjacentTriangles()` (line ~2004)
- `ARViewContainer.handleRefreshAdjacentGhosts()` (line ~1155-1220)

---

## Question 2: Fill Triangle Side Effects

### State Changes When Survey Markers Are Added

**When "Fill Triangle" button is tapped:**

1. **Calibration State Transition:**
   ```swift
   arCalibrationCoordinator.enterSurveyMode()  // .readyToFill → .surveyMode
   ```

2. **Notification Posted:**
   ```swift
   NotificationCenter.default.post(
       name: NSNotification.Name("FillTriangleWithSurveyMarkers"),
       ...
   )
   ```

3. **Survey Markers Created:**
   - `handleFillTriangleWithSurveyMarkers()` calls `generateSurveyMarkers()`
   - Adds markers to `surveyMarkers` dictionary
   - Updates `trianglesWithSurveyMarkers` set

**Key Finding:** `enterSurveyMode()` transitions state from `.readyToFill` to `.surveyMode`. This state change does NOT prevent ghost markers from appearing - ghost selection works in ANY state (per HANDOFF doc).

**Code Locations:**
- `ARViewWithOverlays.swift` line ~940-958 (Fill Triangle button)
- `ARCalibrationCoordinator.enterSurveyMode()` (line ~2547)
- `ARViewContainer.handleFillTriangleWithSurveyMarkers()` (line ~484)

---

## Question 3: Calibration State Transitions

### CalibrationState Enum

```swift
enum CalibrationState: Equatable {
    case placingVertices(currentIndex: Int)  // Placing vertex AR markers (0, 1, or 2)
    case readyToFill                          // All 3 vertices placed, awaiting Fill Triangle
    case surveyMode                           // Placing survey grid markers
    case idle                                 // No active calibration
}
```

### State Transitions Related to Survey Markers

1. **Fill Triangle Button:**
   - `.readyToFill` → `.surveyMode` (via `enterSurveyMode()`)

2. **Exit Survey Mode:**
   - `.surveyMode` → `.readyToFill` (via `exitSurveyMode()`)

**Key Finding:** Filling a triangle with survey markers changes state to `.surveyMode`, but this does NOT prevent ghost markers from appearing. Ghost interaction buttons show whenever `selectedGhostMapPointID != nil` regardless of state.

**Code Location:**
- `ARCalibrationCoordinator.swift` line ~15-20 (enum definition)
- `ARCalibrationCoordinator.enterSurveyMode()` (line ~2547)
- `ARCalibrationCoordinator.exitSurveyMode()` (line ~2557)

---

## Question 4: Ghost Marker Regeneration Trigger

### Triggers for Ghost Marker Creation

1. **After Triangle Calibration Completes:**
   - `finalizeCalibration()` calls `plantGhostsForAdjacentTriangles()`
   - Creates ghosts for far vertices of adjacent triangles

2. **During Calibration Crawl:**
   - `transitionToReadyToFillAndRefreshGhosts()` posts `RefreshAdjacentGhosts` notification
   - `ARViewContainer` handles notification and creates ghosts for unplanted vertices

3. **After Adjacent Triangle Activation:**
   - `activateAdjacentTriangle()` calls `plantGhostsForAdjacentTriangles()` again
   - Creates ghosts for newly activated triangle's neighbors

**Key Finding:** Ghost markers are created:
- ✅ After each triangle calibration completes
- ✅ After ghost confirmation/adjustment (via `RefreshAdjacentGhosts`)
- ❌ NOT called periodically
- ✅ Called on calibration state change (when triangle completes)

**Code Locations:**
- `ARCalibrationCoordinator.finalizeCalibration()` (line ~2523)
- `ARCalibrationCoordinator.transitionToReadyToFillAndRefreshGhosts()` (line ~2568)
- `ARCalibrationCoordinator.activateAdjacentTriangle()` (line ~3236)
- `ARViewContainer` RefreshAdjacentGhosts observer (line ~1155)

---

## Question 5: Survey Markers Presence Check

### CRITICAL FINDING: NO BLOCKING CHECK FOUND

**Searched for:**
- `guard surveyMarkers.isEmpty`
- `if !surveyMarkers.isEmpty { return }`
- `surveyMarkers.count == 0`
- Any conditional checking surveyMarkers before ghost creation

**Result:** ❌ **NO SUCH CHECK EXISTS**

The only survey marker-related check found is in ghost proximity selection optimization:

```swift
// MARK: - Ghost Proximity Selection
// OPTIMIZATION: Skip ghost proximity entirely when inside a survey sphere
if currentlyInsideSurveyMarkerID != nil {
    // Inside survey sphere - no need to check ghosts
    return
}
```

**This check:**
- Only affects ghost SELECTION (highlighting when near)
- Does NOT prevent ghost CREATION
- Does NOT prevent ghost VISIBILITY
- Only skips proximity checks when camera is inside a survey sphere

**Code Location:**
- `ARViewContainer.checkSurveyMarkerCollisions()` line ~2275

---

## Summary & Conclusion

### Ghost Marker Visibility is NOT Blocked by Survey Markers

1. ✅ **No state gating** - Ghost markers can appear in any calibration state
2. ✅ **No survey marker check** - No code checks `surveyMarkers.isEmpty` before creating ghosts
3. ✅ **Fill Triangle side effects** - Only changes state to `.surveyMode`, doesn't disable ghosts
4. ✅ **Ghost regeneration** - Triggers work correctly after calibration and crawl actions

### Potential Root Causes (If Ghosts Still Don't Appear)

If ghost markers are not appearing when survey markers exist, possible causes:

1. **State Transition Timing** - Ghosts may be created before survey markers, then hidden by some other mechanism
2. **Scene Node Visibility** - Ghost nodes may exist but be hidden/occluded
3. **Position Calculation Failure** - `calculateGhostPosition()` may be failing silently
4. **Adjacent Triangle Detection** - `findAdjacentTriangles()` may not be finding triangles correctly
5. **Session Position Check** - Vertices may already have positions in `mapPointARPositions`, causing skip

### Recommended Next Steps

1. Add logging to `plantGhostsForAdjacentTriangles()` to see if it's being called
2. Check `ghostMarkerPositions` dictionary to see if ghosts are created but not visible
3. Verify `calculateGhostPosition()` is succeeding
4. Check if `mapPointARPositions` already contains vertex positions (causing skip)

---

## Code References

### Key Files

- `TapResolver/State/ARCalibrationCoordinator.swift`
  - `plantGhostsForAdjacentTriangles()` - line ~2004
  - `enterSurveyMode()` - line ~2547
  - `transitionToReadyToFillAndRefreshGhosts()` - line ~2568
  - `CalibrationState` enum - line ~15

- `TapResolver/ARFoundation/ARViewContainer.swift`
  - `handleFillTriangleWithSurveyMarkers()` - line ~484
  - `RefreshAdjacentGhosts` observer - line ~1155
  - `createGhostMarker()` - line ~712
  - Ghost proximity check - line ~2275

- `TapResolver/ARFoundation/ARViewWithOverlays.swift`
  - Fill Triangle button - line ~940
  - `shouldShowGhostButtons` - line ~667

