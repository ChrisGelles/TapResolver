> ⚠️ **ARCHIVED DOCUMENT**

> 

> This document has been superseded by the "Touch Claim Mechanisms" section in `GESTURE_SYSTEM_COMPLETE.md`.

> 

> Retained for historical reference only.

---

# Overlay Drag Gesture Conflict Fix

**Date:** December 2024  
**Branch:** `gesture-worktree-merge`  
**Commit:** `aa89ec4`

---

## Problem

When dragging overlay elements (Beacon Dots, Map Points, or Metric Squares), the map would also pan simultaneously. This created a confusing user experience where dragging an overlay element would move both the element AND the map.

### Root Cause

`PinchRotateCentroidBridge` attaches UIKit gesture recognizers to the **window** level to capture all touches. This means:

1. When a user starts dragging a Beacon Dot, both the SwiftUI `DragGesture` (on the dot) and the UIKit `UIPanGestureRecognizer` (on the window) fire simultaneously
2. The window-level pan recognizer captures the touch before SwiftUI can claim exclusive ownership
3. Result: Both the overlay element AND the map move during drag

---

## Solution

Add an `isOverlayDragging` flag to `MapTransformStore` that overlays can set when they start dragging. The bridge checks this flag and skips/cancels map pan when an overlay claims the touch.

### Architecture

```
Overlay Drag Start
       │
       ▼
Set mapTransform.isOverlayDragging = true
       │
       ▼
PinchRotateCentroidBridge.handlePanUpdate()
       │
       ├─► Check isOverlayDragging()
       │   │
       │   ├─► true: Cancel pan, return early
       │   └─► false: Continue with pan
       │
       ▼
Overlay Drag End
       │
       ▼
Set mapTransform.isOverlayDragging = false
```

---

## Implementation Details

### 1. MapTransformStore.swift

Added a published flag that overlays can set:

```swift
/// Indicates whether an overlay element (dot, point, square) is being dragged.
/// The bridge should skip map pan while this is true.
@Published var isOverlayDragging: Bool = false
```

### 2. PinchRotateCentroidBridge.swift

- Added `isOverlayDragging: () -> Bool` closure parameter
- Modified `handlePanUpdate()` to check the flag before processing pan
- If flag is true and pan is active, sends `.cancelled` event to clean up state
- Returns early to prevent map pan during overlay drag

### 3. MapContainer.swift

Wires the flag check to the bridge:

```swift
PinchRotateCentroidBridge(isOverlayDragging: { mapTransform.isOverlayDragging }) { update in
    // ...
}
```

### 4. Overlay Files

**BeaconOverlayDots.swift**, **MapPointOverlay.swift**, **MetricSquaresOverlay.swift**:
- Set `mapTransform.isOverlayDragging = true` when drag starts (`startPoint == nil` check)
- Set `mapTransform.isOverlayDragging = false` when drag ends (`.onEnded` handler)

---

## Behavior Changes

### Before Fix
- Dragging a Beacon Dot → Dot moves AND map pans
- Dragging a Map Point → Point moves AND map pans  
- Dragging/Resizing Metric Square → Square moves AND map pans

### After Fix
- Dragging a Beacon Dot → **Only** dot moves
- Dragging a Map Point → **Only** point moves
- Dragging/Resizing Metric Square → **Only** square moves
- Touching empty map area → Map pans normally
- Pinch/rotate gestures → Unaffected
- 2→1 and 1→2 transitions → Still work smoothly

---

## Testing Checklist

- [x] Beacon Dot drag: Only dot moves, map does NOT pan
- [x] Map Point drag: Only point moves, map does NOT pan
- [x] Metric Square drag: Only square moves, map does NOT pan
- [x] Metric Square resize: Only square resizes, map does NOT pan
- [x] Map pan: Touching empty area and dragging pans map normally
- [x] Pinch/rotate: Two-finger gestures work as before
- [x] Transitions: 2→1 and 1→2 finger transitions still work smoothly

---

## Files Modified

1. `TapResolver/Transforms/MapTransformStore.swift` - Added `isOverlayDragging` flag
2. `TapResolver/Transforms/PinchRotateCentroidBridge.swift` - Added flag check in pan handler
3. `TapResolver/UI/Map/MapContainer.swift` - Wired flag check to bridge
4. `TapResolver/UI/Overlays/BeaconOverlayDots.swift` - Set flag on drag start/end
5. `TapResolver/UI/Overlays/MapPointOverlay.swift` - Set flag on drag start/end
6. `TapResolver/UI/Overlays/MetricSquaresOverlay.swift` - Set flag on drag/resize start/end

---

## Related Documentation

See `GESTURE_SYSTEM_COMPLETE.md` for the complete gesture system architecture and design decisions.

---

## Future Considerations

This fix uses a simple boolean flag. If more complex gesture coordination is needed in the future (e.g., multiple overlays dragging simultaneously, gesture priority systems), consider:

1. Using a reference-counted system instead of a boolean
2. Adding gesture priority/ownership tracking
3. Implementing a gesture coordinator pattern

For now, the boolean flag is sufficient since only one overlay can be dragged at a time in the current UI design.
