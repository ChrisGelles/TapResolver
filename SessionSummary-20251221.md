## Session Summary: December 21, 2025

**Token Count:** ~81,000 tokens (~43% of context)

---

## Accomplishments

### 1. Calibration Crawl + Survey Mode Coexistence

**Problem:** When Survey Markers were placed (state = `.surveyMode`), the Calibration Crawl stopped working. Ghost markers for adjacent uncalibrated triangles wouldn't appear.

**Root Cause:** The crawl mode check only accepted `.readyToFill` state:
```swift
if case .readyToFill = arCalibrationCoordinator.calibrationState
```

**Fix:** Added computed property and updated both button handlers.

**Files Modified:**
- `ARCalibrationCoordinator.swift` — Added `isCrawlEligibleState` computed property
- `ARViewWithOverlays.swift` — Updated 2 conditions in `onConfirmGhost` and `onPlaceMarker`

**Code Added:**
```swift
// ARCalibrationCoordinator.swift
var isCrawlEligibleState: Bool {
    switch calibrationState {
    case .readyToFill, .surveyMode:
        return true
    case .placingVertices, .idle:
        return false
    }
}
```

---

### 2. UI Conflict Resolution — Ghost Buttons vs Survey Buttons

**Problem:** Ghost interaction buttons and Survey button bar displayed simultaneously, cluttering the screen.

**Fix:** Added condition to suppress Survey buttons when a ghost is selected.

**Files Modified:**
- `ARViewWithOverlays.swift` — Survey button visibility condition

**Code Change:**
```swift
// Before
if [state condition] {
    // Survey buttons
}

// After  
if [state condition],
   arCalibrationCoordinator.selectedGhostMapPointID == nil {
    // Survey buttons
}
```

---

### 3. AR Marker Hiding for Survey Proximity

**Problem:** AR Markers (orange sphere-toppers) visually interfered with nearby Survey Markers.

**Fix:** Hide AR markers within 0.25m of any Survey Marker on fill, restore on clear.

**Files Modified:**
- `ARViewContainer.swift`

**Code Added:**
```swift
// New property
private var hiddenARMarkersForSurveyProximity: Set<UUID> = []

// New methods
private func hideARMarkersNearSurveyMarkers(proximityThreshold: Float = 0.25)
private func unhideProximityHiddenARMarkers()
```

**Call Sites:**
- `handleFillTriangleWithSurveyMarkers()` — calls `hideARMarkersNearSurveyMarkers()` after placement
- `clearSurveyMarkers()` — calls `unhideProximityHiddenARMarkers()`
- `clearSurveyMarkersForTriangle()` — calls unhide if `surveyMarkers.isEmpty`

---

### 4. All Markers Hidden Inside Survey Sphere

**Problem:** When camera entered a Survey Marker sphere, other AR/Ghost markers remained visible and cluttered the feedback view.

**Fix:** Hide all AR and Ghost markers on sphere entry, restore on exit (respecting proximity-hidden state).

**Files Modified:**
- `ARViewContainer.swift` — Inside `checkSurveyMarkerCollisions()`

**Code Added (ENTER block):**
```swift
currentlyInsideSurveyMarkerID = markerID

// Hide all AR and ghost markers while inside sphere
for (_, node) in placedMarkers {
    node.isHidden = true
}
for (_, node) in ghostMarkers {
    node.isHidden = true
}
```

**Code Added (EXIT block):**
```swift
currentlyInsideSurveyMarkerID = nil

// Restore AR markers (except proximity-hidden) and all ghost markers
for (markerID, node) in placedMarkers {
    if !hiddenARMarkersForSurveyProximity.contains(markerID) {
        node.isHidden = false
    }
}
for (_, node) in ghostMarkers {
    node.isHidden = false
}
```

---

### 5. Demote Re-Adjust Flow Fix

**Problem:** Tapping an AR Marker to demote it, then adjusting via "Place Marker to Adjust" incorrectly routed through the Calibration Crawl path. This caused:
- `activateAdjacentTriangle()` to be called (and fail)
- Duplicate markers created for the same MapPoint
- Ghost selection not cleared

**Root Cause:** Both crawl and demote flows shared the same code path. No check distinguished demoted ghosts from crawl ghosts.

**Fix:** Added early-return check for `demotedGhostMapPointIDs` before crawl logic.

**Files Modified:**
- `ARViewWithOverlays.swift` — Added demote check in both `onConfirmGhost` and `onPlaceMarker`

**Code Added (both handlers):**
```swift
// DEMOTE RE-ADJUST: If this ghost was demoted from an AR marker,
// simply place marker at new position (no crawl/adjacent activation)
if arCalibrationCoordinator.demotedGhostMapPointIDs.contains(ghostMapPointID) {
    print("🔄 [DEMOTE_READJUST] Adjusting demoted marker...")
    
    // Remove ghost, place marker, clear demote state
    // ... (notification posts)
    
    arCalibrationCoordinator.demotedGhostMapPointIDs.remove(ghostMapPointID)
    arCalibrationCoordinator.selectedGhostMapPointID = nil
    arCalibrationCoordinator.selectedGhostEstimatedPosition = nil
    
    return  // Early exit — skip crawl logic
}
```

---

## Code Cleanliness Assessment

### ✅ Adheres to DRY

**`isCrawlEligibleState`** — Single source of truth for crawl eligibility. If we add a new eligible state, one place to update.

**Proximity hiding coordination** — The `hiddenARMarkersForSurveyProximity` set cleanly separates "hidden because of Survey proximity" from "hidden because inside sphere." Exit logic correctly respects both states without duplication.

### ✅ Adheres to Collect/Publish Separation

The visibility changes are **immediate UI updates** (not data collection), so they appropriately mutate SceneKit node properties directly. No mixing of data persistence with UI updates.

The Survey Marker color system (from prior session) correctly follows collect-first/publish-after: `finalizeSessionAsync()` computes on background, hops to MainActor for store write, THEN posts notification for UI color updates.

### ⚠️ Areas of Concern

**1. Demote check duplication**

The demote early-return logic is nearly identical in both `onConfirmGhost` and `onPlaceMarker`. Consider extracting:

```swift
// Future cleanup: Extract to helper
private func handleDemoteReadjust(ghostMapPointID: UUID, useGhostPosition: Bool) -> Bool {
    guard arCalibrationCoordinator.demotedGhostMapPointIDs.contains(ghostMapPointID) else {
        return false
    }
    // ... common logic
    return true
}
```

**2. Visibility state implicit coupling**

The sphere exit code must "know" about `hiddenARMarkersForSurveyProximity`. This works but is implicit. A more explicit approach might be a `MarkerVisibilityManager` that tracks all visibility reasons per marker.

**3. Notification chain complexity**

The flow: Tap → DemoteMarkerToGhost → DemoteMarkerResponse → RemoveGhostMarker → PlaceMarkerAtCursor → ARMarkerPlaced

This chain spans multiple files and notification handlers. It works, but debugging requires tracing across many hops. Consider whether a single coordinator method could replace some of this.

**4. Hit test logging verbosity**

`[HIT_TEST_DIAG]` logs every hit result including unnamed nodes. Useful for debugging but excessive for production.

---

## Future Cleanup Opportunities

| Priority | Item | Effort |
|----------|------|--------|
| Low | Extract demote handling to shared helper | 30 min |
| Low | Create `MarkerVisibilityManager` class | 2 hrs |
| Medium | Consolidate notification chains where possible | 3 hrs |
| Low | Move magic numbers to config (0.25m threshold) | 15 min |

None of these are urgent — the code works correctly and is maintainable.

---

## Diagnostic Logs to Disable

### High-Volume (disable first)

| Tag | Location | Purpose |
|-----|----------|---------|
| `👆 [TAP_DIAG]` | ARViewContainer | Every tap event with screen position |
| `🎯 [HIT_TEST_DIAG]` | ARViewContainer | Every hit test result, all nodes |
| `📏 Map scale set:` | Multiple | Logs on every coordinate conversion |

### Medium-Volume (keep for now, disable later)

| Tag | Location | Purpose |
|-----|----------|---------|
| `👁️ [AR_HIDE]` / `[AR_SHOW]` | ARViewContainer | Visibility changes |
| `👁️ [SPHERE_ENTER]` / `[SPHERE_EXIT]` | ARViewContainer | Sphere collision |
| `🔄 [DEMOTE_READJUST]` | ARViewWithOverlays | Demote flow tracking |
| `👻 [GHOST_SELECT]` / `[GHOST_NEARBY]` | ARCalibrationCoordinator | Ghost proximity |

### Keep Active (useful for ongoing debugging)

| Tag | Location | Purpose |
|-----|----------|---------|
| `🔗 [CRAWL_CONFIRM]` / `[CRAWL_ADJUST]` | ARViewWithOverlays | Crawl flow routing |
| `🔍 [ACTIVATE_ADJACENT_DEBUG]` | ARCalibrationCoordinator | Triangle activation |
| `💥 [SURVEY_COLLISION]` | ARViewContainer | Sphere entry/exit timing |
| `📊 [SurveyPointStore]` | SurveyPointStore | Data persistence |
| `🎨 [ARViewContainer]` | ARViewContainer | Color updates |

---

**Token consumption for this response:** ~2,000 tokens