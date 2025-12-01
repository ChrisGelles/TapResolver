# Architectural Review: Ghost Marker Lifecycle Consolidation

**Status:** Flagged for future session  
**Priority:** Medium (after Milestone 3 functional completion)  
**Created:** November 30, 2025  
**Context:** Discovered during Milestone 3 Calibration Crawl implementation

---

## Problem Statement

Ghost marker lifecycle management is currently scattered across multiple notification handlers and conditional state checks, leading to:

1. **Orphaned ghosts** — Ghost markers that aren't properly removed when state transitions occur
2. **Duplicate code paths** — Multiple places checking for ghost-related states
3. **Difficult debugging** — No single source of truth for ghost state
4. **Edge case failures** — States like "adjust 3rd vertex ghost" were missed because logic was duplicated rather than centralized

### Specific Incident (Nov 30, 2025)

When adjusting the 3rd vertex ghost position during initial triangle calibration:
- Ghost was created correctly
- User tapped "Adjust" button
- Marker placed at crosshair ✓
- Ghost NOT removed ✗ (code path only handled `.readyToFill` state)
- Triangle finalized, new adjacent ghosts planted
- Result: Orphaned ghost + new ghosts = visual confusion

---

## Current Architecture

### Ghost Creation Points
- `plantGhostFor3rdVertex()` — After 2nd marker placed during calibration
- `plantGhostsForAdjacentTriangles()` — After triangle calibration completes

### Ghost Removal Points
- `handleRemoveGhostMarker()` — Notification handler in ARViewContainer
- `handleConfirmGhostMarker()` — Converts ghost to real marker (removes ghost node)

### Ghost State Tracking
- `ghostMarkerPositions: [UUID: simd_float3]` — In ARViewContainer.Coordinator
- `selectedGhostMapPointID: UUID?` — In ARCalibrationCoordinator

### State Checks for Ghost Interactions
- `GhostInteractionButtons.onConfirmGhost` — Checks `.readyToFill` vs `.placingVertices`
- `GhostInteractionButtons.onPlaceMarker` — Checks `.readyToFill` vs `.placingVertices(2)`
- `checkGhostProximity()` — Checks if any ghost is within range
- Various notification handlers — Check state before processing

---

## Proposed Solution

### Centralized Ghost State Machine

Create a dedicated `GhostMarkerManager` (or extend `ARCalibrationCoordinator`) with explicit states:

```swift
enum GhostState {
    case none
    case planted(mapPointID: UUID, position: simd_float3, purpose: GhostPurpose)
    case approaching(mapPointID: UUID, distance: Float)
    case selected(mapPointID: UUID)
    case confirming(mapPointID: UUID)
    case adjusting(mapPointID: UUID)
    case removed
}

enum GhostPurpose {
    case thirdVertex          // During initial 3-point calibration
    case adjacentTriangle     // During crawl mode
}
```

### Single Entry Points

```swift
// Creation
func plantGhost(for mapPointID: UUID, at position: simd_float3, purpose: GhostPurpose)

// Selection (proximity-based)
func selectGhostIfInRange(cameraPosition: simd_float3) -> UUID?

// User Actions
func confirmSelectedGhost() -> Bool   // Returns success
func adjustSelectedGhost() -> Bool    // Returns success

// Cleanup
func removeGhost(mapPointID: UUID)
func removeAllGhosts()
```

### Benefits

1. **Single source of truth** — All ghost state in one place
2. **Explicit transitions** — State machine prevents invalid states
3. **Auditable** — Easy to log all state transitions
4. **Testable** — Can unit test state machine in isolation
5. **No orphans** — Every creation has a corresponding removal path

---

## Implementation Notes

### Files Likely Affected
- `ARCalibrationCoordinator.swift` — Add ghost state management
- `ARViewContainer.swift` — Simplify to delegate to coordinator
- `ARViewWithOverlays.swift` — Simplify button handlers
- `GhostInteractionButtons.swift` — Simplify to single action calls

### Migration Strategy
1. Create new centralized ghost management alongside existing code
2. Route new code through centralized manager
3. Gradually migrate existing handlers
4. Remove old scattered logic once verified

### Testing Checklist
- [ ] 3rd vertex ghost: Confirm works
- [ ] 3rd vertex ghost: Adjust works (ghost removed)
- [ ] Adjacent ghost: Confirm works (crawl mode activates)
- [ ] Adjacent ghost: Adjust works (crawl mode activates)
- [ ] Multiple ghosts: Correct one selected by proximity
- [ ] Walk away from ghost: Deselection works
- [ ] Exit AR view: All ghosts cleaned up
- [ ] Re-enter AR view: Fresh ghost state

---

## Related Issues

- **Session tracking bug** — First calibrated triangle not added to `sessionCalibratedTriangles` (fixed separately)
- **Ghost marker color** — 3rd vertex ghost confirm creates blue marker instead of orange (tracked separately)

---

## Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| Nov 30, 2025 | Deferred to post-Milestone 3 | Need functional crawl mode first; architectural cleanup is lower priority than working features |

---

## References

- Milestone 3 spec: Ghost Markers with Placement Validation
- Console logs showing orphaned ghost behavior
- `ARViewContainer.swift` — Current ghost handling
- `ARCalibrationCoordinator.swift` — Current state management
