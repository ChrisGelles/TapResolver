# Gesture System Rebuild Tracker

## Branch
`feature/gesture-rebuild`

## Status
- [x] Milestone 0: Setup
- [x] Milestone 1: Transform Store
- [x] Milestone 2: Pan Gesture
- [x] Milestone 3: Pinch/Rotate Bridge
- [x] Milestone 4: Double-Tap Zoom
- [x] Milestone 5: Overlay Pinch Guard
- [x] Milestone 6: Cleanup
- [x] Milestone 7: Integration Testing

**✅ GESTURE SYSTEM COMPLETE** (December 2024)

---

## Architecture Overview

### Transform Flow
```
User Input (screen space)
       │
       ├─── Pan ──────────────► GestureHandler.panOnlyGesture
       │                              │
       │                              ▼
       │                        onTotalsChanged callback
       │                              │
       │                              ▼
       │                        TransformProcessor.enqueueCandidate
       │                              │
       │                              ▼
       │                        MapTransformStore._setTotals
       │
       └─── Pinch/Rotate ────► PinchRotateCentroidBridge (window-level)
                                      │
                                      ▼
                                MapTransformStore.beginPinch/updatePinch/endPinch
                                      │
                                      ▼
                                syncToExternalTransform (on .ended)
```

### Key Design Decisions

1. **Window-Level Gesture Recognizers**: `PinchRotateCentroidBridge` attaches UIKit recognizers to the window, not a blocking UIView. This allows SwiftUI overlays to receive taps while still capturing two-finger gestures.

2. **Centroid-Pivot Transform**: Pinch/rotate pivots around the finger centroid, not the view center. The anchor point (map coordinate under fingers) is captured at gesture start and maintained throughout.

3. **Dual Gesture Paths**: Pan uses SwiftUI's `DragGesture` via `GestureHandler`, while pinch/rotate uses UIKit via the bridge. Both converge on `MapTransformStore` as single source of truth.

4. **State Synchronization**: After bridge gestures end, `GestureHandler.syncToExternalTransform()` is called to align its internal state with `MapTransformStore`, preventing jumps on subsequent pan gestures.

---

## Files Modified

### REPLACED (new implementation)
| File | Status | Notes |
|------|--------|-------|
| `Transforms/MapTransformStore.swift` | ✅ | Centroid-pivot pinch/rotate, coordinate conversions |
| `Transforms/PinchRotateCentroidBridge.swift` | ✅ | Window-level UIKit recognizers |

### MODIFIED (surgical changes)
| File | Struct/Function | Change | Status |
|------|-----------------|--------|--------|
| `UI/Map/MapContainer.swift` | `MapCanvas.body` | Gesture wiring, bridge overlay | ✅ |
| `Transforms/GestureHandler.swift` | `totalScale`, `syncToExternalTransform` | Removed clamping, added sync method | ✅ |
| `UI/Overlays/BeaconOverlayDots.swift` | `DraggableDot.body` | `isPinching` guard | ✅ |
| `UI/Overlays/MetricSquaresOverlay.swift` | `centerDragGesture` | `isPinching` guard | ✅ |

### EVALUATED (confirmed working)
| File | Outcome | Notes |
|------|---------|-------|
| `Transforms/GestureHandler.swift` | ✅ Retained | Handles pan + double-tap + sync |
| `Transforms/TransformProcessor.swift` | ✅ Retained | Debounces updates to store |

### UNCHANGED (confirmed compatible)
| File | Reason |
|------|--------|
| `UI/Root/ContentView.swift` | No gesture code |
| `UI/Root/MapNavigationView.swift` | Only sets screenCenter (unchanged API) |
| `UI/Root/HUDContainer.swift` | Non-transformable layer |

---

## Critical Fixes Applied

### Issue: Pinch-to-Pan Transition Jump

**Symptom**: After pinch/rotate gesture ended, first pan caused visible jump in scale/position.

**Root Cause**: `GestureHandler.totalScale` had scale clamping that created a mismatch:
```swift
// BEFORE (broken):
var totalScale: CGFloat {
    let raw = steadyScale * gestureScale
    return max(minScale, min(maxScale, raw))  // ← Clamping here
}
```

When `MapTransformStore` allowed scale `0.408` but `GestureHandler` clamped to `0.5`, the first pan pushed `0.5` to the processor, causing a jump from `0.408` → `0.5`.

**Fix**: Remove clamping from computed property; apply limits only at gesture boundaries:
```swift
// AFTER (correct):
var totalScale: CGFloat {
    steadyScale * gestureScale  // No clamping
}
```

**Lesson**: Clamping belongs at gesture boundaries (user input limits), not in computed properties participating in state synchronization.

---

## API Reference

### MapTransformStore

| Property/Method | Purpose |
|-----------------|---------|
| `totalScale` | Current composite scale |
| `totalRotationRadians` | Current composite rotation |
| `totalOffset` | Current composite pan offset |
| `isPinching` | True during active pinch/rotate gesture |
| `mapToScreen(_ mapPoint:)` | Convert map coords → screen coords |
| `screenToMap(_ screenPoint:)` | Convert screen coords → map coords |
| `screenTranslationToMap(_ translation:)` | Convert screen delta → map delta |
| `beginPinch(atCentroidScreen:)` | Start pinch session |
| `updatePinch(pinchScale:pinchRotation:centroidScreen:)` | Update during pinch |
| `endPinch()` | End pinch session |
| `centerOnPoint(_:animated:)` | Programmatic navigation |

### GestureHandler

| Property/Method | Purpose |
|-----------------|---------|
| `panOnlyGesture` | SwiftUI gesture for one-finger pan |
| `doubleTapZoom()` | Zoom in by `zoomStep` factor |
| `resetTransform()` | Reset to identity transform |
| `syncToExternalTransform(scale:rotation:offset:)` | Align state after bridge gesture ends |
| `onTotalsChanged` | Callback when totals change |

### PinchRotateCentroidBridge

| Property | Purpose |
|----------|---------|
| `State.phase` | `.began`, `.changed`, `.ended`, `.cancelled` |
| `State.scale` | Cumulative scale from gesture start |
| `State.rotationRadians` | Cumulative rotation from gesture start |
| `State.centroidInScreen` | Screen-space finger centroid |

---

## Testing Checklist

- [x] Pan: smooth one-finger drag
- [x] Pinch: zoom toward/away from fingers (centroid-pivot)
- [x] Rotate: spin around finger centroid
- [x] Double-tap: zoom toward tap point
- [x] No jump on pinch → pan transition
- [x] No jump on rotate → pan transition
- [x] Beacon dot drag: tracks correctly after zoom/rotate
- [x] Metric square drag: tracks correctly after zoom/rotate
- [x] Triangle overlay: renders correctly after transforms
- [x] RSSI labels: position correctly after transforms

---

## Known Issues / Future Work

### Overlay Drag Offset (Issue 2 - Diagnosed, Not Yet Fixed)

**Symptom**: MapPoints and BeaconDots have incorrect drag offsets when moved.

**Root Cause**: Coordinate space mismatch. These overlays use `.local` coordinate space for drag gestures, but `screenTranslationToMap()` expects `.global` (screen space) input. Result: double transformation.

**Proposed Fix**: Change drag gestures from `.local` to `.global`:
```swift
// In MapPointOverlay.swift and BeaconOverlayDots.swift:
DragGesture(minimumDistance: 6, coordinateSpace: .global)
```

**Status**: Ready for implementation in next phase.
