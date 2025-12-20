# LESSON LEARNED: UIKit Threading Violations in ARKit/SceneKit

**Date:** December 13, 2025  
**Project:** TapResolver  
**Severity:** Critical - caused ARKit tracking loss and coordinate frame corruption

---

## The Problem

During AR calibration sessions, the app would randomly experience:
- 0.78+ second frame freezes
- ARKit dropping to `INITIALIZING` state (complete tracking loss)
- ~4 seconds to recover to `NORMAL` tracking
- Previously planted AR markers appearing displaced after recovery
- Silent coordinate frame drift contaminating position history

**This was extremely difficult to diagnose** because:
- No crash occurred
- ARKit reported tracking as "NORMAL" before and after
- The freeze appeared random (actually depended on when SceneKit's render thread hit the bad code path)

---

## The Root Cause

```swift
// ❌ ILLEGAL: Called from SceneKit's background rendering thread
func isPositionInCameraView(_ position: simd_float3, margin: CGFloat = 50) -> Bool {
    guard let sceneView = sceneView else { return false }
    
    let screenPoint = sceneView.projectPoint(SCNVector3(position))
    
    // ... 
    
    let screenBounds = sceneView.bounds  // 💀 UIKit API ON WRONG THREAD
    let insetBounds = screenBounds.insetBy(dx: margin, dy: margin)
    
    // ...
}
```

This function was called from `renderer(_:updateAtTime:)`, which runs on **SceneKit's background rendering queue** (`com.apple.scenekit.renderingQueue`).

`UIView.bounds` is a UIKit API that **must only be accessed from the main thread**.

---

## How Xcode Told Us (We Just Had to Listen)

The console log contained this warning that we initially overlooked:

```
Main Thread Checker: UI API called on a background thread: -[UIView bounds]
PID: 61419, TID: 2917855, Thread name: (none), Queue name: com.apple.scenekit.renderingQueue.ARSCNView0x11990d000
Backtrace:
5   TapResolver.debug.dylib  ...isPositionInCameraView...
6   TapResolver.debug.dylib  ...renderer_12updateAtTime...
```

**The Main Thread Checker told us exactly what was wrong and where.**

---

## The Fix

Replace UIKit-dependent code with pure ARKit camera matrix math:

```swift
// ✅ THREAD-SAFE: Uses only ARKit camera matrices
func isPositionInCameraView(_ position: simd_float3, margin: Float = 0.1) -> Bool {
    guard let sceneView = sceneView,
          let frame = sceneView.session.currentFrame else { return false }
    
    let camera = frame.camera
    
    // Get camera matrices (thread-safe)
    let viewMatrix = camera.viewMatrix(for: .portrait)
    let projectionMatrix = camera.projectionMatrix(for: .portrait, 
                                                    viewportSize: CGSize(width: 1, height: 1), 
                                                    zNear: 0.001, 
                                                    zFar: 1000)
    
    // Transform to clip space
    let worldPos = simd_float4(position.x, position.y, position.z, 1.0)
    let viewPos = viewMatrix * worldPos
    let clipPos = projectionMatrix * viewPos
    
    // Check if behind camera
    if clipPos.w <= 0 { return false }
    
    // Convert to NDC and check bounds
    let ndcX = clipPos.x / clipPos.w
    let ndcY = clipPos.y / clipPos.w
    let threshold = 1.0 - margin
    
    return abs(ndcX) < threshold && abs(ndcY) < threshold
}
```

---

## The Golden Rules

### 1. **NEVER access UIKit from SceneKit's render callbacks**

These methods run on background threads:
- `renderer(_:updateAtTime:)`
- `renderer(_:didApplyConstraintsAtTime:)`
- `renderer(_:willRenderScene:atTime:)`

UIKit APIs that are OFF LIMITS from these callbacks:
- `UIView.bounds`
- `UIView.frame`
- `UIScreen.main.bounds`
- Any `UIView` property access
- Any `UIViewController` access

### 2. **If you need screen dimensions, cache them**

```swift
// Cache on main thread when view appears
private var cachedViewBounds: CGRect = .zero

func updateUIView(_ uiView: ARSCNView, context: Context) {
    // This runs on main thread - safe to read bounds
    context.coordinator.cachedViewBounds = uiView.bounds
}

// Use cached value from render thread
func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
    let bounds = cachedViewBounds  // ✅ Safe - reading a simple struct
}
```

### 3. **Prefer pure math over UIKit when possible**

ARKit provides everything you need for spatial calculations:
- `ARCamera.viewMatrix(for:)` - thread-safe
- `ARCamera.projectionMatrix(for:viewportSize:zNear:zFar:)` - thread-safe
- `ARCamera.transform` - thread-safe
- `ARFrame.camera` - thread-safe

### 4. **Read the Main Thread Checker warnings**

Xcode's Main Thread Checker exists for a reason. When you see:
```
Main Thread Checker: UI API called on a background thread
```

**STOP EVERYTHING AND FIX IT.** These warnings often don't crash immediately but cause intermittent, hard-to-diagnose issues like:
- UI freezes
- Data corruption
- ARKit tracking loss
- Race conditions

---

## Downstream Consequences of This Bug

Because this threading violation caused ARKit to lose and reinitialize tracking mid-session:

1. **Coordinate frame corruption:** The AR world origin would shift
2. **Marker displacement:** Previously planted markers appeared in wrong locations
3. **Position history contamination:** New markers were recorded in the shifted coordinate frame
4. **Baked data pollution:** Bad positions averaged into the consensus
5. **Ghost marker drift:** Future ghost positions calculated from contaminated history

**The bug didn't just cause a momentary glitch - it poisoned the data.**

---

## How to Audit for Similar Issues

1. Search codebase for UIKit access in render callbacks:
   ```
   grep -n "bounds\|frame\|UIScreen" **/AR*.swift
   ```

2. Run with Main Thread Checker enabled (Xcode default)

3. Look for warnings containing:
   - `scenekit.renderingQueue`
   - `Main Thread Checker`
   - `UI API called on a background thread`

4. Any function called from `renderer(_:updateAtTime:)` should be audited for UIKit dependencies

---

## Summary

**The Lesson:** Threading violations don't always crash. Sometimes they cause silent, intermittent corruption that's far worse. When Xcode warns you about thread safety, believe it and fix it immediately.

**The Pattern:** If you're in a SceneKit render callback and need screen information, either cache it from the main thread or compute it from ARKit's thread-safe camera matrices.
