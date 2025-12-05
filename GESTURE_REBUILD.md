# Gesture System Rebuild Tracker

## Branch

`feature/gesture-rebuild`

## Purpose

Replace the gesture and transform system to achieve centroid-pivot pinch/rotate behavior. The map should zoom toward/away from the point between the user's fingers, not the view center.

## Status

| Milestone | Description | Status |
|-----------|-------------|--------|
| 0 | Setup & Tracking | ✅ Complete |
| 1 | Transform Store Replacement | ✅ Complete |
| 1a | NaN Fallback Fix | ✅ Complete |
| 2 | Pan Gesture Wiring | ✅ Complete (existing pipeline works) |
| 3 | Pinch/Rotate Bridge Wiring | ✅ Complete |
| 4 | Double-Tap Zoom | ⬜ Not Started |
| 5 | Overlay Pinch Guard | ⬜ Not Started |
| 6 | Cleanup & Legacy Removal | ⬜ Not Started |
| 7 | Integration Testing | ⬜ Not Started |

---

## Files Modified

### REPLACED (full new implementation)

| File | Milestone | Status | Notes |
|------|-----------|--------|-------|
| `Transforms/MapTransformStore.swift` | 1 | 🔄 | New transform brain |
| `Transforms/PinchRotateCentroidBridge.swift` | 3 | ⬜ | Currently NOP, will be functional |

### MODIFIED (surgical changes)

| File | Struct/Function | Milestone | Status | Notes |
|------|-----------------|-----------|--------|-------|
| `UI/Map/MapContainer.swift` | `MapCanvas` overlay block | 3 | ✅ | Wired bridge to store |
| `Transforms/GestureHandler.swift` | `syncToExternalTransform` | 3 | ✅ | Added sync method |
| `Transforms/MapTransformStore.swift` | `_setTotals` | 3 | ✅ | Guard for isPinching |
| `UI/Overlays/BeaconOverlayDots.swift` | `DraggableDot.body` | 5 | ⬜ | Add isPinching guard |
| `UI/Overlays/MetricSquaresOverlay.swift` | `centerDragGesture`, `cornerResizeGesture` | 5 | ⬜ | Add isPinching guard |

### EVALUATED (may need changes)

| File | Milestone | Outcome | Notes |
|------|-----------|---------|-------|
| `Transforms/GestureHandler.swift` | 6 | ⬜ | May be removed/reduced |
| `Transforms/TransformProcessor.swift` | 6 | ⬜ | Verify wiring still works |

### UNCHANGED (confirmed compatible)

| File | Reason |
|------|--------|
| `UI/Root/ContentView.swift` | No gesture code |
| `UI/Root/MapNavigationView.swift` | Only calls setScreenCenter (API unchanged) |
| `UI/Root/HUDContainer.swift` | Non-transformable layer |
| All other overlays | Use existing coordinate conversion methods (API unchanged) |

---

## API Surface

### Existing (unchanged signatures)

- `mapToScreen(_ mapPoint: CGPoint) -> CGPoint`
- `screenToMap(_ screenPoint: CGPoint) -> CGPoint`
- `screenTranslationToMap(_ translation: CGSize) -> CGSize`
- `setMapSize(_ size: CGSize)`
- `setScreenCenter(_ point: CGPoint)`
- `totalScale: CGFloat` (published)
- `totalRotationRadians: CGFloat` (published)
- `totalOffset: CGSize` (published)
- `mapSize: CGSize` (published, read-only)
- `screenCenter: CGPoint` (published, read-only)

### New additions

- `isPinching: Bool` (published) — overlays check this to yield to map gestures
- `beginPan()` / `updatePan(translation:)` / `endPan()` — pan session
- `beginPinch(atCentroidScreen:)` / `updatePinch(pinchScale:pinchRotation:centroidScreen:)` / `endPinch()` — pinch session
- `zoom(by:aroundScreenPoint:)` — programmatic zoom for double-tap
- `resetTransform()` — reset to defaults
- `minScale: CGFloat` / `maxScale: CGFloat` — scale limits (0.1 to 10.0)

### Compatibility shims (temporary, will be removed in Milestone 6)

- `_setMapSize(_:)` (internal) — bridge for TransformProcessor
- `_setScreenCenter(_:)` (internal) — bridge for TransformProcessor
- `_setTotals(scale:rotationRadians:offset:)` (internal) — bridge for TransformProcessor
- `centerOnPoint(_:animated:)` (public) — programmatic navigation, restored from old store

---

## Testing Checklist

### Milestone 1

- [ ] App compiles without errors
- [ ] Map image displays correctly
- [ ] Existing overlays render at correct positions
- [ ] Pan/pinch gestures do NOT work yet (expected — not wired)

### Milestone 2

- [ ] One-finger drag pans the map smoothly

### Milestone 3

- [ ] Two-finger pinch zooms toward/away from finger centroid
- [ ] Two-finger rotate spins around finger centroid
- [ ] Combined pinch+rotate works simultaneously

### Milestone 4

- [ ] Double-tap zooms toward tap location

### Milestone 5

- [ ] Dragging beacon dot during pinch is ignored (no erratic movement)
- [ ] Dragging metric square during pinch is ignored

### Milestone 6

- [ ] No dead code remaining
- [ ] Clean compile with no warnings

### Milestone 7

- [ ] All tests pass on physical device
- [ ] Ready to merge into main branch

---

## Notes

- This work is on a parallel worktree, separate from AR Markers development
- Results should merge cleanly once complete
- The AR Markers branch will need to be aware of `isPinching` if it adds any new draggable overlays

---

## Known Issues (Pre-existing)

### MapPointDrawer.swift Type-Check Error

The compiler reports: "The compiler is unable to type-check this expression in reasonable time"

This is a pre-existing fragility in `MapPointDrawer.swift` line 22, not caused by our changes. The complex expression in that file's body is taxing the Swift type-checker.

**Workaround options:**

1. Break up the complex expression into separate computed properties

2. Add explicit type annotations to help the compiler

3. Extract sub-views into separate structs

**Status:** Not blocking Milestone 1 — this is separate from gesture rebuild work.

