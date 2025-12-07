# Centroid-Pivot Gesture System: Complete Rebuild Documentation

**Date:** December 4, 2025  
**Status:** ✅ WORKING  
**Files Modified:** `MapContainer.swift`, `MapTransformStore.swift`, `GestureHandler.swift`, `PinchRotateCentroidBridge.swift`

---

## The Goal

Implement Google Maps-style pinch-to-zoom where the map zooms toward/away from the point **between your fingers** (the centroid), not the view center. Same for rotation.

**Before:** Pinch zoomed around view center → disorienting, loses spatial context  
**After:** Pinch zooms around finger centroid → natural, intuitive navigation

---

## Why This Was So Hard

### The Core Problem: SwiftUI Gestures Don't Expose Touch Positions

SwiftUI's `MagnificationGesture` and `RotationGesture` only report:
- Scale factor (cumulative from gesture start)
- Rotation angle (cumulative from gesture start)

They do **NOT** report:
- Where the fingers are
- The centroid between the fingers
- Any positional information whatsoever

Without finger positions, you cannot compute where to pivot the transform.

### The Solution: UIKit Bridge

UIKit's gesture recognizers (`UIPinchGestureRecognizer`, `UIRotationGestureRecognizer`) **do** expose finger positions via `.location(in:)`. So we created a `UIViewRepresentable` bridge to capture this data.

### The Trap That Ate Days: `hitTest` Timing

We initially tried to make the UIKit bridge "smart" by only responding to two-finger touches:

```swift
// ❌ THIS DOES NOT WORK
private final class PassThroughWhenSingleTouchView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let active = event?.allTouches?.filter { $0.phase != .cancelled && $0.phase != .ended }.count ?? 0
        if active < 2 { return nil }  // Let single touches pass through
        return super.hitTest(point, with: event)
    }
}
```

**Why it fails:** `hitTest` is called when the **first** finger touches down. At that moment, `activeCount = 1`. The view returns `nil`, excluding itself from the responder chain. When the second finger arrives, it's too late — the view was already excluded.

**The fix:** Remove the `hitTest` override entirely. Let all touches reach the view. The gesture recognizers themselves naturally require 2+ fingers to activate:

```swift
// ✅ THIS WORKS
private final class PassThroughWhenSingleTouchView: UIView {
    // No hitTest override — let all touches reach the gesture recognizers.
    // The recognizers themselves filter for 2+ finger gestures.
}
```

Single-finger touches still pass through to SwiftUI because we set `cancelsTouchesInView = false` on the recognizers.

---

## Architecture Overview

### Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                        USER INPUT                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ONE FINGER (Pan)              TWO FINGERS (Pinch/Rotate)       │
│       │                              │                           │
│       ▼                              ▼                           │
│  SwiftUI DragGesture           UIKit Recognizers                │
│       │                              │                           │
│       ▼                              ▼                           │
│  MapGestureHandler          PinchRotateCentroidBridge           │
│       │                              │                           │
│       │                              │ (reports scale, rotation, │
│       │                              │  AND centroid position)   │
│       ▼                              ▼                           │
│  TransformProcessor ◄───────► MapTransformStore                 │
│  (legacy, for pan)            (source of truth)                 │
│                                      │                           │
│                                      ▼                           │
│                              SwiftUI View Modifiers              │
│                              .scaleEffect()                      │
│                              .rotationEffect()                   │
│                              .offset()                           │
└─────────────────────────────────────────────────────────────────┘
```

### Gesture Split

| Gesture Type | Handler | Why |
|--------------|---------|-----|
| Pan (1-finger) | SwiftUI `DragGesture` via `MapGestureHandler` | Works fine, no centroid needed |
| Pinch (2-finger) | UIKit via `PinchRotateCentroidBridge` | Provides finger positions |
| Rotate (2-finger) | UIKit via `PinchRotateCentroidBridge` | Provides finger positions |

---

## Key Files and Their Roles

### `PinchRotateCentroidBridge.swift`
**Purpose:** UIViewRepresentable that wraps UIKit gesture recognizers and reports centroid position.

**Key Implementation Details:**
```swift
struct State {
    enum Phase { case began, changed, ended, cancelled }
    var phase: Phase
    var scale: CGFloat              // Cumulative from gesture start (1.0 = no change)
    var rotationRadians: CGFloat    // Cumulative from gesture start (0.0 = no change)
    var centroidInScreen: CGPoint   // Screen coordinates of finger midpoint
}
```

**Critical Settings:**
```swift
pinch.cancelsTouchesInView = false  // Don't block SwiftUI gestures
rot.cancelsTouchesInView = false
pinch.delegate = coordinator        // Enable simultaneous recognition
rot.delegate = coordinator
// Coordinator returns true for shouldRecognizeSimultaneouslyWith
```

### `MapTransformStore.swift`
**Purpose:** Single source of truth for all transform state. Acts like an After Effects null/controller.

**Key Methods:**
- `beginPinch(atCentroidScreen:)` — Captures initial state and anchor point
- `updatePinch(pinchScale:pinchRotation:centroidScreen:)` — Applies transform with centroid pivot
- `endPinch()` — Cleans up, sets `isPinching = false`

**The Centroid-Pivot Math:**
```swift
func updatePinch(pinchScale: CGFloat, pinchRotation: CGFloat, centroidScreen: CGPoint) {
    // 1. Apply new scale and rotation
    let newScale = pinchInitialScale * pinchScale
    let newRotation = pinchInitialRotation + pinchRotation
    totalScale = newScale
    totalRotationRadians = newRotation
    
    // 2. Compute where the anchor point would land with initial offset
    totalOffset = pinchInitialOffset
    let projectedScreenPos = mapToScreen(pinchAnchorMapPoint)
    
    // 3. Adjust offset so anchor stays under centroid
    let dx = centroidScreen.x - projectedScreenPos.x
    let dy = centroidScreen.y - projectedScreenPos.y
    totalOffset = CGSize(
        width: pinchInitialOffset.width + dx,
        height: pinchInitialOffset.height + dy
    )
}
```

This is the **After Effects pattern**: "move anchor point, inverse-move position."

### `MapContainer.swift`
**Purpose:** Hosts the map image and wires up all gesture handlers.

**Key Wiring:**
```swift
.overlay(
    PinchRotateCentroidBridge { update in
        switch update.phase {
        case .began:
            mapTransform.beginPinch(atCentroidScreen: update.centroidInScreen)
        case .changed:
            mapTransform.updatePinch(
                pinchScale: update.scale,
                pinchRotation: update.rotationRadians,
                centroidScreen: update.centroidInScreen
            )
        case .ended, .cancelled:
            mapTransform.endPinch()
            // Sync GestureHandler to prevent jump on next gesture
            gestures.syncToExternalTransform(
                scale: mapTransform.totalScale,
                rotation: Angle(radians: Double(mapTransform.totalRotationRadians)),
                offset: mapTransform.totalOffset
            )
        }
    }
    .ignoresSafeArea()
)
.gesture(gestures.panOnlyGesture)  // Pan only — pinch/rotate via bridge
```

### `GestureHandler.swift`
**Purpose:** Manages SwiftUI gesture state for pan (and legacy pinch/rotate).

**Key Addition:**
```swift
func syncToExternalTransform(scale: CGFloat, rotation: Angle, offset: CGSize) {
    steadyScale = scale
    steadyRotation = rotation
    steadyOffset = offset
    gestureScale = 1.0
    gestureRotation = .degrees(0)
    gestureTranslation = .zero
}
```

This prevents a "jump" when transitioning from bridge-driven pinch back to SwiftUI-driven pan.

---

## Coordinate Systems

| System | Origin | Units | Used For |
|--------|--------|-------|----------|
| Map-local | Top-left of image | Image pixels/points | Storing positions, overlays |
| Screen | Top-left of screen | Screen points | Gesture input, display |
| Centroid | Reported by UIKit | Screen points | Pivot calculations |

**Conversions:**
- `mapToScreen(_:)` — Transform map point through scale/rotation/offset
- `screenToMap(_:)` — Inverse transform (for hit testing, anchor capture)
- `screenTranslationToMap(_:)` — Convert drag deltas (for overlay drags)

---

## The `isPinching` Guard

When the bridge is driving scale/rotation, the old `TransformProcessor` pipeline might still be sending values. We guard against conflicts:

```swift
// In _setTotals() (legacy compatibility shim)
if isPinching {
    // Only update offset during pinch — bridge handles scale/rotation
    totalOffset = safeOffset
} else {
    totalScale = safeScale
    totalRotationRadians = CGFloat(safeRotation)
    totalOffset = safeOffset
}
```

---

## Lessons Learned

### 1. `hitTest` Timing is Non-Intuitive
`hitTest` is called per-touch, not per-gesture. A two-finger gesture starts with one finger. If you exclude the view on the first touch, the second touch never reaches it.

### 2. SwiftUI and UIKit Can Coexist
With proper configuration (`cancelsTouchesInView = false`, `shouldRecognizeSimultaneouslyWith = true`), UIKit recognizers can handle multi-touch while SwiftUI handles single-touch.

### 3. The "Anchor Point" Pattern
To make a transform pivot around an arbitrary point:
1. Capture the map-local point under the centroid at gesture start
2. After each transform update, compute where that point would appear on screen
3. Adjust the offset so it appears under the current centroid

### 4. State Sync Between Systems
When two systems (SwiftUI gestures, UIKit bridge) can modify the same state, sync their internal bookkeeping when control transfers. Otherwise you get "jumps."

### 5. Diagnostic Logging is Critical
The `🤏 [BRIDGE]` and `🤏 [STORE]` logs let us immediately see:
- Is the bridge firing? (If not, hitTest or wiring problem)
- Are values reasonable? (Scale near 1.0, centroid in screen bounds)
- Is the store receiving updates? (If not, callback wiring problem)

---

## Future Cleanup (Milestone 6)

Once this is stable, remove:
- `_setTotals()`, `_setMapSize()`, `_setScreenCenter()` compatibility shims
- `TransformProcessor` (can be simplified or removed)
- `combinedGesture` from `GestureHandler` (no longer used)
- Diagnostic print statements

---

## Console Output When Working

```
🤏 [BRIDGE] phase:began scale:1.000 rot:0.000 centroid:(200,400)
🤏 [STORE] beginPinch — anchor:(500,300) centroid:(200,400) initialScale:1.000
🤏 [BRIDGE] phase:changed scale:1.234 rot:0.100 centroid:(205,395)
🤏 [STORE] updatePinch — scale:1.234 rot:0.100 offset:(50,30) centroid:(205,395)
... (many changed events)
🤏 [BRIDGE] phase:ended scale:1.234 rot:0.100 centroid:(210,390)
🤏 [STORE] endPinch — finalScale:1.234 finalRot:0.100 finalOffset:(55,35)
```

---

## Summary

| Problem | Cause | Solution |
|---------|-------|----------|
| SwiftUI can't do centroid pivot | No finger position data | UIKit bridge |
| Bridge never fired | `hitTest` excluded view on first touch | Remove `hitTest` override |
| Jump on gesture end | GestureHandler out of sync | `syncToExternalTransform()` |
| Two systems fighting | Both trying to set scale/rotation | `isPinching` guard |
| NaN rotation | Old SwiftUI gesture producing NaN | Disabled via `panOnlyGesture` |

---

## Git Commit Message

```
feat(gestures): Implement centroid-pivot pinch/rotate

- Add PinchRotateCentroidBridge for UIKit gesture integration
- Rebuild MapTransformStore with session-based pinch/rotate methods
- Split gestures: SwiftUI pan, UIKit pinch/rotate
- Fix hitTest trap that blocked two-finger gestures
- Add isPinching guard to prevent transform conflicts
- Add syncToExternalTransform() to prevent gesture discontinuities

The map now zooms toward/away from the point between your fingers,
matching Google Maps behavior.
```
