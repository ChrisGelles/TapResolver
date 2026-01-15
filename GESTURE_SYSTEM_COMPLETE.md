# TapResolver Gesture System

## Branch
`feature/gesture-rebuild`

## Status
**✅ GESTURE SYSTEM COMPLETE** (December 6, 2025)

All milestones achieved:
- [x] Milestone 0: Setup & Tracking
- [x] Milestone 1: Transform Store Replacement
- [x] Milestone 1a: NaN Fallback Fix
- [x] Milestone 2: Pan Gesture Wiring
- [x] Milestone 3: Pinch/Rotate Bridge Wiring
- [x] Milestone 4: Double-Tap Zoom
- [x] Milestone 5: Overlay Pinch Guard
- [x] Milestone 6: Cleanup & Legacy Removal
- [x] Milestone 7: Integration Testing
- [x] **Milestone 8: Unified UIKit Gestures** ← Final breakthrough

---

## Purpose

Replace the gesture and transform system to achieve:
1. **Centroid-pivot pinch/rotate**: Map zooms toward/away from the point between the user's fingers, not the view center (Google Maps behavior)
2. **Seamless finger transitions**: User can fluidly transition between 2-finger pinch/rotate and 1-finger pan without lifting all fingers
3. **No position jumps**: Transitions between gesture modes preserve map position exactly

---

## Architecture Overview

### The Breakthrough: Unified UIKit Gesture System

The key insight that enabled seamless transitions was **eliminating the UIKit/SwiftUI gesture boundary**. 

**Problem with mixed systems:**
When UIKit's `UIPinchGestureRecognizer` starts with 2 fingers, it "owns" both touches. When one finger lifts, the remaining touch stays bound to the ended recognizer. SwiftUI's `DragGesture` operates in a parallel universe—it never sees that finger. Result: pan fails after 2→1 transition.

**Solution:**
All map gestures (pan, pinch, rotate) are now handled by UIKit recognizers in `PinchRotateCentroidBridge`. The pan recognizer runs simultaneously with pinch/rotate, tracking touches from the moment they begin. When finger count drops from 2→1, the pan recognizer already owns the remaining touch.

### Transform Flow (Current Architecture)
```
User Input (screen space)
       │
       ├─── 1 Finger ─────────► UIPanGestureRecognizer
       │                              │
       │                              ▼
       │                        PinchRotateCentroidBridge.handlePanUpdate()
       │                              │
       │                              ▼
       │                        TransformProcessor.handlePan()
       │                              │
       │                              ▼
       │                        MapTransformStore.beginPan/updatePan/endPan
       │
       └─── 2 Fingers ────────► UIPinchGestureRecognizer + UIRotationGestureRecognizer
                                      │
                                      ▼
                                PinchRotateCentroidBridge.handleGestureUpdate()
                                      │
                                      ▼
                                TransformProcessor.handlePinchRotate()
                                      │
                                      ▼
                                MapTransformStore (direct write)
                                      │
                                      ▼
                                GestureHandler.syncToExternalTransform() (on .ended)
```

### Gesture State Machine
```
                    ┌─────────────────────────────────────────┐
                    │                                         │
                    ▼                                         │
[No Touches] ──(1 finger)──► [PAN MODE] ──(lift finger)──────┘
                    │              │
                    │       (add 2nd finger)
                    │              │
                    │              ▼
                    │        [PINCH/ROTATE MODE]
                    │              │
             (2 fingers)    (lift 1 finger)
                    │              │
                    │              ▼
                    └────────► [PAN MODE] ◄─── seamless transition!
                                   │
                            (lift finger)
                                   │
                                   ▼
                            [No Touches]
```

### Key Design Decisions

1. **Window-Level Gesture Recognizers**: `PinchRotateCentroidBridge` attaches UIKit recognizers to the window, not a blocking UIView. This allows SwiftUI overlays (buttons, drawers) to receive taps while still capturing multi-touch gestures.

2. **Centroid-Pivot Transform**: Pinch/rotate pivots around the finger centroid, not the view center. The anchor point (map coordinate under fingers) is captured at gesture start and maintained throughout via matrix math in `TransformProcessor.handlePinchRotate()`.

3. **Unified UIKit Path**: Both pan and pinch/rotate now flow through `PinchRotateCentroidBridge`. SwiftUI's `GestureHandler.panOnlyGesture` is retained but commented out—map gestures no longer use it.

4. **State Synchronization**: After bridge gestures end, `GestureHandler.syncToExternalTransform()` is called to align its internal state with `MapTransformStore`. This prevents jumps if any SwiftUI gesture code is re-enabled.

5. **Critical `.began` Event on 2→1 Transition**: When transitioning from pinch to pan, we must emit a pan `.began` event so `MapTransformStore.beginPan()` captures the current offset. Without this, `panInitialOffset` would be stale, causing a position jump.

---

## Files

### Core Gesture Files

| File | Purpose | Status |
|------|---------|--------|
| `Transforms/PinchRotateCentroidBridge.swift` | Window-level UIKit recognizers for pinch/rotate/pan | ✅ Complete |
| `Transforms/TransformProcessing.swift` | Coalesces gesture updates, handles pinch math | ✅ Complete |
| `Transforms/MapTransformStore.swift` | Single source of truth for transform state | ✅ Complete |
| `Transforms/GestureHandler.swift` | SwiftUI gesture handler (retained for double-tap, sync) | ✅ Complete |
| `UI/Map/MapContainer.swift` | Wires bridge to processor, applies transforms | ✅ Complete |

### Files with `isPinching` Guards

| File | Struct/Function | Purpose |
|------|-----------------|---------|
| `UI/Overlays/BeaconOverlayDots.swift` | `DraggableDot.body` | Prevents dot drag during map pinch |
| `UI/Overlays/MetricSquaresOverlay.swift` | `centerDragGesture`, `cornerResizeGesture` | Prevents square interaction during map pinch |

### Unchanged Files

| File | Reason |
|------|--------|
| `UI/Root/ContentView.swift` | No gesture code |
| `UI/Root/MapNavigationView.swift` | Only calls `setScreenCenter` (API unchanged) |
| `UI/Root/HUDContainer.swift` | Non-transformable layer |
| All other overlays | Use existing coordinate conversion methods (API unchanged) |

---

## Critical Fixes Applied

### Issue 1: Pinch-to-Pan Transition Jump (Scale Clamping)

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

### Issue 2: 2→1 Finger Transition Broke Pan (UIKit/SwiftUI Boundary)

**Symptom**: After lifting one finger during a pinch, the remaining finger could not pan the map.

**Root Cause**: UIKit gesture recognizers "own" touches. When `UIPinchGestureRecognizer` starts with 2 fingers, it claims both. When one finger lifts, the remaining touch stays bound to the ended recognizer. SwiftUI's `DragGesture` never saw a `.began` event for that finger.

**Fix**: Move pan handling into `PinchRotateCentroidBridge` using a `UIPanGestureRecognizer` that runs simultaneously with pinch/rotate. The pan recognizer tracks touches from the start, so it already "owns" the remaining finger when pinch ends.

**Lesson**: Don't mix gesture systems when you need seamless handoffs. Keep everything in one system (UIKit) when touch ownership matters.

---

### Issue 3: 2→1 Transition Position Jump (Missing `.began` Event)

**Symptom**: Even with unified UIKit gestures, there was still a position jump when transitioning from 2 fingers to 1.

**Root Cause**: After 2→1 transition, we set `isPanActive = true` but never sent a `.began` pan event. When pan `.changed` arrived, `TransformProcessor.handlePan(.changed)` called `store.updatePan(translation)`, but `panInitialOffset` was never updated—it was stale from the previous pan session.

**Fix**: Emit a proper pan `.began` event immediately after 2→1 transition:
```swift
// In handleGestureUpdate(), after 2→1 transition:
if let pan = pan {
    pan.setTranslation(.zero, in: attachedWindow)
    isPanActive = true
    
    // CRITICAL: Send .began so store.beginPan() captures current offset
    onUpdate(State(
        phase: .began,
        gestureMode: .pan,
        // ...
    ))
}
```

**Lesson**: State machine transitions must be complete. If you're switching modes, ensure all initialization events fire.

---

## API Reference

### MapTransformStore

| Property/Method | Purpose |
|-----------------|---------|
| `totalScale: CGFloat` | Current composite scale (published) |
| `totalRotationRadians: CGFloat` | Current composite rotation (published) |
| `totalOffset: CGSize` | Current composite pan offset (published) |
| `isPinching: Bool` | True during active pinch/rotate gesture (published) |
| `mapSize: CGSize` | Map image size in local units (published, read-only) |
| `screenCenter: CGPoint` | Visual center of screen (published, read-only) |
| `mapToScreen(_ mapPoint:) -> CGPoint` | Convert map coords → screen coords |
| `screenToMap(_ screenPoint:) -> CGPoint` | Convert screen coords → map coords |
| `screenTranslationToMap(_ translation:) -> CGSize` | Convert screen delta → map delta |
| `beginPan()` | Start pan session, captures current offset |
| `updatePan(translation:)` | Update during pan with cumulative translation |
| `endPan()` | End pan session |
| `beginPinch(atCentroidScreen:)` | Start pinch session |
| `updatePinch(pinchScale:pinchRotation:centroidScreen:)` | Update during pinch |
| `endPinch()` | End pinch session |
| `zoom(by:aroundScreenPoint:)` | Programmatic zoom for double-tap |
| `centerOnPoint(_:animated:)` | Programmatic navigation |
| `resetTransform()` | Reset to identity transform |

### TransformProcessor

| Property/Method | Purpose |
|-----------------|---------|
| `handlePinchRotate(phase:scaleFromStart:rotationFromStart:centroidInScreen:)` | Process pinch/rotate from bridge |
| `handlePan(phase:translation:)` | Process pan from bridge |
| `enqueueCandidate(scale:rotationRadians:offset:)` | Coalesce updates from GestureHandler |
| `bind(to store:)` | Connect to MapTransformStore |
| `setMapSize(_:)` | Update map dimensions |
| `setScreenCenter(_:)` | Update screen center |

### PinchRotateCentroidBridge

| State Property | Purpose |
|----------------|---------|
| `phase` | `.began`, `.changed`, `.ended`, `.cancelled` |
| `gestureMode` | `.pinchRotate` or `.pan` |
| `scale` | Cumulative scale from gesture start (pinch mode) |
| `rotationRadians` | Cumulative rotation from gesture start (pinch mode) |
| `centroidInScreen` | Screen-space finger centroid (pinch mode) |
| `panTranslation` | Cumulative translation from gesture start (pan mode) |
| `isNavigationSessionActive` | True while any finger is in contact |

### GestureHandler

| Property/Method | Purpose |
|-----------------|---------|
| `panOnlyGesture` | SwiftUI gesture (currently unused for map) |
| `doubleTapZoom()` | Zoom in by `zoomStep` factor |
| `resetTransform()` | Reset to identity transform |
| `syncToExternalTransform(scale:rotation:offset:)` | Align state after bridge gesture ends |
| `onTotalsChanged` | Callback when totals change |

---

## Console Log Signatures

### Healthy Gesture Flow

**Fresh 1-finger pan:**
```
🖐️ [XXms] Pan BEGAN (UIKit)
🖐️ [TransformProcessor] Pan began
🖐️ [XXms] Pan ENDED (UIKit)
🖐️ [TransformProcessor] Pan ended
```

**Fresh 2-finger pinch:**
```
✌️ [XXms] Pinch BEGAN (fresh) at (X, Y)
... (no spam during gesture)
✌️ [XXms] Pinch ENDED (lift both)
```

**2→1 transition (the breakthrough):**
```
✌️→☝️ [XXms] Pinch ENDED (2→1), pan will continue
🖐️ [XXms] Pan BEGAN (after 2→1 transition)
🖐️ [TransformProcessor] Pan began
... (pan continues smoothly)
🖐️ [XXms] Pan ENDED (UIKit)
🖐️ [TransformProcessor] Pan ended
```

**1→2 transition:**
```
🖐️→✌️ [XXms] Pan ended, switching to pinch
🖐️ [TransformProcessor] Pan ended
☝️→✌️ [XXms] Pinch BEGAN (1→2) at (X, Y)
```

### Problem Indicators

**Console spam during pinch (should NOT happen):**
```
🚫 [_setTotals] isPinching=true — ignoring...
```
This indicates the `enqueueCandidate` early-return guard isn't working.

**Missing `.began` after 2→1:**
If you see `✌️→☝️ Pinch ENDED (2→1)` without a following `🖐️ Pan BEGAN (after 2→1 transition)`, the pan will jump.

---

## Testing Checklist

### Core Gestures
- [x] Pan: smooth one-finger drag
- [x] Pinch: zoom toward/away from fingers (centroid-pivot)
- [x] Rotate: spin around finger centroid
- [x] Combined pinch+rotate works simultaneously
- [x] Double-tap: zoom toward tap point

### Transitions (The Hard Part)
- [x] **2→1 transition**: No position jump when lifting one finger
- [x] **2→1 pan works**: Remaining finger can pan smoothly
- [x] **1→2 transition**: Adding second finger switches to pinch without jump
- [x] **Infinite cycling**: Can go 2→1→2→1→2... without accumulating errors

### Overlays
- [x] Beacon dot drag: tracks correctly after zoom/rotate
- [x] Metric square drag: tracks correctly after zoom/rotate
- [x] Triangle overlay: renders correctly after transforms
- [x] RSSI labels: position correctly after transforms
- [x] Dragging beacon dot during pinch is ignored (no erratic movement)
- [x] Dragging metric square during pinch is ignored

### Edge Cases
- [x] Rapid finger add/remove (debounced at 50ms)
- [x] Transform state survives location switch
- [x] No NaN or infinite values in transform state

---

## Touch Claim Mechanisms

The window-level UIKit gesture recognizers in `PinchRotateCentroidBridge` capture all touches by design. This creates a conflict when the user interacts with overlay elements or HUD components—both the element AND the map would respond. 

We solve this with **claim flags** in `MapTransformStore` that child views set when they need exclusive touch ownership.

### Architecture

```
User Touch on UI Element

       │

       ▼

Child View sets claim flag = true

       │

       ├──► Overlay dragging: mapTransform.isOverlayDragging = true

       │

       └──► HUD scrolling:    mapTransform.isHUDInteracting = true

       │

       ▼

PinchRotateCentroidBridge.shouldBlockPan()

       │

       ├──► Returns true: Skip/cancel map pan

       │

       └──► Returns false: Process map pan normally

       │

       ▼

User lifts finger

       │

       ▼

Child View sets claim flag = false
```

### Claim Flags

| Flag | Purpose | Set By |

|------|---------|--------|

| `isOverlayDragging` | Blocks map pan during overlay element drags | BeaconOverlayDots, MapPointOverlay, MetricSquaresOverlay |

| `isHUDInteracting` | Blocks map pan during HUD scrolling/sliding | Drawer ScrollViews, DebugSettingsPanel, MapPointLogView, CustomSlider |

### Implementation Pattern

#### For SwiftUI Overlays (Drag Gestures)

```swift
// In overlay view with DragGesture:

.onChanged { value in

    if startPoint == nil {

        startPoint = element.position

        mapTransform.isOverlayDragging = true  // ← Claim touch

    }

    // ... drag logic

}

.onEnded { _ in

    startPoint = nil

    mapTransform.isOverlayDragging = false     // ← Release touch

}

```

#### For SwiftUI ScrollViews

```swift
ScrollView {

    // ... content

}

.simultaneousGesture(

    DragGesture(minimumDistance: 0)

        .onChanged { _ in mapTransform.isHUDInteracting = true }

        .onEnded { _ in mapTransform.isHUDInteracting = false }

)

```

#### For Buttons in Forms with simultaneousGesture

When a Form (or List) has a `.simultaneousGesture(DragGesture...)` modifier for touch claiming, **all buttons inside that Form must use `.buttonStyle(.plain)`** to prevent tap conflicts.

**Problem**: Without `.buttonStyle(.plain)`, SwiftUI's default button behavior in a Form conflicts with the `DragGesture`, causing button taps to be swallowed and not trigger their actions.

**Solution**: Always add `.buttonStyle(.plain)` before `.disabled()` or other modifiers:

```swift
Form {
    // ... content
    
    Button {
        // Action
    } label: {
        // Label
    }
    .buttonStyle(.plain)  // ← REQUIRED when parent Form has simultaneousGesture
    .disabled(...)
}
.simultaneousGesture(
    DragGesture(minimumDistance: 0)
        .onChanged { _ in mapTransform.isHUDInteracting = true }
        .onEnded { _ in mapTransform.isHUDInteracting = false }
)
```

**Example**: `SVGExportPanel.swift` uses this pattern for both Export and Import buttons to ensure they work correctly with the panel's gesture handling.

#### For UIKit Components (UISlider)

UIKit components can't directly access SwiftUI environment objects, so they use NotificationCenter:

```swift
// In UIViewRepresentable Coordinator:

@objc func touchBegan() {

    NotificationCenter.default.post(name: .sliderInteractionBegan, object: nil)

}

@objc func touchEnded() {

    NotificationCenter.default.post(name: .sliderInteractionEnded, object: nil)

}

// In parent SwiftUI view:

.onReceive(NotificationCenter.default.publisher(for: .sliderInteractionBegan)) { _ in

    mapTransform.isHUDInteracting = true

}

.onReceive(NotificationCenter.default.publisher(for: .sliderInteractionEnded)) { _ in

    mapTransform.isHUDInteracting = false

}

```

### Bridge Integration

In `PinchRotateCentroidBridge`, the `shouldBlockPan` closure checks both flags:

```swift
// Wired in MapContainer.swift:

shouldBlockPan: { mapTransform.isOverlayDragging || mapTransform.isHUDInteracting }

```

When `shouldBlockPan()` returns `true`:

1. If pan is not active: Early return, ignore the touch

2. If pan is already active: Send `.cancelled` event to clean up state, then return

### Files Using Touch Claim

| File | Component | Claim Flag |

|------|-----------|------------|

| `BeaconOverlayDots.swift` | DraggableDot | `isOverlayDragging` |

| `MapPointOverlay.swift` | Point drag gesture | `isOverlayDragging` |

| `MetricSquaresOverlay.swift` | Drag + resize gestures | `isOverlayDragging` |

| `BeaconDrawer.swift` | ScrollView | `isHUDInteracting` |

| `MapPointDrawer.swift` | ScrollView | `isHUDInteracting` |

| `MetricSquareDrawer.swift` | ScrollView | `isHUDInteracting` |

| `MorgueDrawer.swift` | ScrollView | `isHUDInteracting` |

| `DebugSettingsPanel` | ScrollView (in HUDContainer.swift) | `isHUDInteracting` |

| `MapPointLogView.swift` | ScrollView | `isHUDInteracting` |

| `MapPointSessionListView.swift` | ScrollView | `isHUDInteracting` |

| `CustomSlider` | UISlider (in HUDContainer.swift) | `isHUDInteracting` (via notification) |

### Testing Checklist

**Overlay Drags (isOverlayDragging)**

- [ ] Beacon Dot drag: Only dot moves, map does NOT pan

- [ ] Map Point drag: Only point moves, map does NOT pan

- [ ] Metric Square drag: Only square moves, map does NOT pan

- [ ] Metric Square resize: Only square resizes, map does NOT pan

**HUD Interactions (isHUDInteracting)**

- [ ] Beacon Drawer scroll: Map does NOT pan

- [ ] Map Point Drawer scroll: Map does NOT pan

- [ ] Metric Square Drawer scroll: Map does NOT pan

- [ ] Morgue Drawer scroll: Map does NOT pan

- [ ] Debug Settings Panel scroll: Map does NOT pan

- [ ] Map Point Log scroll: Map does NOT pan

- [ ] Session List scroll: Map does NOT pan

- [ ] Duration Slider drag: Map does NOT pan

**Normal Operation (no flags set)**

- [ ] Touching empty map area: Map pans normally

- [ ] Pinch/rotate gestures: Work as expected

- [ ] 2→1 and 1→2 transitions: Still smooth

### Adding New Claimable Components

When adding a new UI element that should block map pan:

1. **For SwiftUI views with DragGesture**: Set `mapTransform.isOverlayDragging = true` in `.onChanged` (first call), clear in `.onEnded`

2. **For SwiftUI ScrollViews**: Add `.simultaneousGesture(DragGesture...)` pattern setting `isHUDInteracting`

3. **For UIKit components**: Use NotificationCenter to bridge to SwiftUI, then set `isHUDInteracting` in the `.onReceive` handler

4. **For new claim types**: Add a new `@Published` flag to `MapTransformStore` and include it in the `shouldBlockPan` check in `MapContainer.swift`

---

## Known Issues / Future Work

### Overlay & HUD Touch Conflicts (RESOLVED - December 2024)

**Symptom**: Dragging overlay elements or scrolling HUD panels would also pan the map simultaneously.

**Root Cause**: Window-level UIKit gesture recognizers captured all touches, including those on overlay elements and HUD components.

**Fix**: Added touch claim flags (`isOverlayDragging`, `isHUDInteracting`) to `MapTransformStore`. Components set these flags when they need exclusive touch ownership, and `PinchRotateCentroidBridge` skips map pan when either flag is true.

**Status**: ✅ Fixed. See "Touch Claim Mechanisms" section above for complete documentation.

---

### Overlay Drag Offset (Issue 2 - Diagnosed, Not Yet Fixed)

**Symptom**: MapPoints and BeaconDots have incorrect drag offsets when moved.

**Root Cause**: Coordinate space mismatch. These overlays use `.local` coordinate space for drag gestures, but `screenTranslationToMap()` expects `.global` (screen space) input. Result: double transformation.

**Proposed Fix**: Change drag gestures from `.local` to `.global`:
```swift
// In MapPointOverlay.swift and BeaconOverlayDots.swift:
DragGesture(minimumDistance: 6, coordinateSpace: .global)
```

**Status**: Ready for implementation in next phase.

**Note**: This issue was resolved as part of the overlay drag conflict fix - overlays now use `.global` coordinate space.

---

### "Publishing changes from within view updates" Warnings

**Symptom**: Console shows repeated warnings during app launch:
```
Publishing changes from within view updates is not allowed, this will cause undefined behavior.
```

**Root Cause**: `MapPointStore` reload triggers `@Published` property changes during SwiftUI view evaluation.

**Impact**: Cosmetic (warnings only), no functional issues observed.

**Proposed Fix**: Defer published changes to next runloop tick using `DispatchQueue.main.async`.

**Status**: Low priority, not blocking.

---

### GestureHandler Cleanup Opportunity

With pan now handled by UIKit, `GestureHandler.panOnlyGesture` is unused for map navigation. The class is retained for:
- `doubleTapZoom()` 
- `resetTransform()`
- `syncToExternalTransform()` for state alignment
- Potential future use by other views

Could be simplified or split into separate concerns in a future refactor.

---

## Architecture Principles (Lessons Learned)

1. **Don't mix gesture systems for handoffs**: UIKit and SwiftUI gestures operate in parallel universes. If you need seamless touch ownership transfer, stay in one system.

2. **State machine transitions must be complete**: When switching modes (pinch→pan), ensure all initialization events fire. A missing `.began` event means stale initial state.

3. **Clamping belongs at boundaries, not in computed properties**: Computed properties that participate in state sync should return raw values. Apply limits only when accepting user input.

4. **The pan recognizer must track during pinch**: To hand off a touch, the receiving recognizer must already be tracking it. Run pan simultaneously with pinch, just suppress its output until needed.

5. **Reset translation on mode switch**: When transitioning 2→1, call `pan.setTranslation(.zero)` so deltas start fresh from the current position.

---

## Version History

| Date | Change | Author |
|------|--------|--------|
| Dec 2024 | Initial gesture rebuild complete (Milestones 0-7) | Chris + Claude |
| Dec 6, 2025 | Milestone 8: Unified UIKit gestures, seamless 2→1→2 transitions | Chris + Claude |

---

*This document replaces `GestureSystem.md`, `GESTURE_REBUILD.md`, and `OVERLAY_DRAG_GESTURE_FIX.md`.*

*For historical context on the centroid-pivot implementation decisions, see `CENTROID_PIVOT_GESTURE_REBUILD.md` (archived).*
