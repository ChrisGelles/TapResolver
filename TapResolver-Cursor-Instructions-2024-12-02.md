# TapResolver Cursor Instructions - December 2, 2024

## Session Summary

Three fixes identified and ready for implementation:

| Priority | Issue | Status |
|----------|-------|--------|
| 3 | Triangle persistence in crawl mode | Instructions ready |
| 1 | Consensus + rigid transform for crawl ghosts | Implemented by Cursor (verify) |
| - | Fill Triangle button broken | Instructions ready |

---

## Priority 3: Triangle Persistence in Crawl Mode

### Problem

When triangles are calibrated via crawl mode (confirming ghost markers), the calibration is tracked in memory (`sessionCalibratedTriangles`) but NOT persisted to storage. After app restart, crawled triangles show as uncalibrated on the 2D map.

**Root Cause:**
- `finalizeCalibration()` calls `triangleStore.markCalibrated()` ✅
- `activateAdjacentTriangle()` only calls `sessionCalibratedTriangles.insert()` ❌

### Cursor Instructions

**CRITICAL CONSTRAINTS:**
1. Make ONLY the changes specified below
2. Do NOT refactor, optimize, or modify any other code
3. If you encounter errors, STOP and report the error message—do not attempt fixes
4. **Do NOT automatically push to git. Wait for explicit instructions to do so.**

---

**File:** `ARCalibrationCoordinator.swift`

**Location:** Inside `func activateAdjacentTriangle(...)`, find these lines (around line 1540-1542):

```swift
        // Set state to readyToFill since all 3 vertices are now calibrated
        calibrationState = .readyToFill
        
        // Add adjacent triangle to session calibrated set
        sessionCalibratedTriangles.insert(adjacentTriangle.id)
        print("✅ [ADJACENT_ACTIVATE] Added \(String(adjacentTriangle.id.uuidString.prefix(8))) to sessionCalibratedTriangles (now \(sessionCalibratedTriangles.count) triangle(s))")
```

**Change:** Insert persistence call IMMEDIATELY AFTER the `sessionCalibratedTriangles.insert(adjacentTriangle.id)` line:

```swift
        // Set state to readyToFill since all 3 vertices are now calibrated
        calibrationState = .readyToFill
        
        // Add adjacent triangle to session calibrated set
        sessionCalibratedTriangles.insert(adjacentTriangle.id)
        print("✅ [ADJACENT_ACTIVATE] Added \(String(adjacentTriangle.id.uuidString.prefix(8))) to sessionCalibratedTriangles (now \(sessionCalibratedTriangles.count) triangle(s))")
        
        // CRITICAL: Persist calibration to storage (mirrors finalizeCalibration behavior)
        triangleStore.markCalibrated(adjacentTriangle.id, quality: 1.0)
        print("💾 [ADJACENT_ACTIVATE] Persisted calibration for triangle \(String(adjacentTriangle.id.uuidString.prefix(8)))")
```

### Acceptance Criteria

1. **Build succeeds** without errors or warnings

2. **Console logging:** During crawl mode, after confirming a ghost marker:
   - `✅ [ADJACENT_ACTIVATE] Added XXXXXXXX to sessionCalibratedTriangles`
   - `💾 [ADJACENT_ACTIVATE] Persisted calibration for triangle XXXXXXXX` ← **NEW**

3. **Persistence test:**
   - Calibrate initial triangle (normal 3-point placement)
   - Crawl to adjacent triangle (confirm ghost)
   - Force-quit app (swipe up from app switcher)
   - Relaunch app
   - Check 2D map: Crawled triangle should show **calibrated color**

4. **No regression:** Initial triangle calibration still works as before

---

## Priority 1: Consensus + Rigid Transform for Crawl Mode Ghosts

### Problem

Two different ghost calculation functions exist:
- `calculateGhostPositionForThirdVertex()` - Uses consensus + rigid transform ✅
- `calculateGhostPosition()` (crawl mode) - Only uses current session data ❌

Crawl mode ghosts don't benefit from historical position data.

### Solution

Add consensus + rigid transform priority logic to `calculateGhostPosition()`, matching the approach in `calculateGhostPositionForThirdVertex()`.

### Cursor Instructions

**CRITICAL CONSTRAINTS:**
1. Make ONLY the changes specified below
2. Do NOT refactor, optimize, or modify any other code
3. If you encounter errors, STOP and report the error message—do not attempt fixes
4. **Do NOT automatically push to git. Wait for explicit instructions to do so.**

---

**File:** `ARCalibrationCoordinator.swift`

**Location:** Inside `private func calculateGhostPosition(...)`, find the section after barycentric weight calculation and BEFORE the "STEP 3: Get triangle's 3 vertex AR positions" comment (around lines 584-590):

```swift
        let w2 = (v2.x * v1.y - v1.x * v2.y) / denom
        let w3 = (v0.x * v2.y - v2.x * v0.y) / denom
        let w1 = 1.0 - w2 - w3
        
        print("📐 [GHOST_CALC] Barycentric weights: w1=\(String(format: "%.3f", w1)), w2=\(String(format: "%.3f", w2)), w3=\(String(format: "%.3f", w3))")
        
        // STEP 3: Get triangle's 3 vertex AR positions (3D positions)
```

**Change:** Insert the following consensus + rigid transform logic BETWEEN the barycentric weights print statement AND the "STEP 3" comment:

```swift
        let w2 = (v2.x * v1.y - v1.x * v2.y) / denom
        let w3 = (v0.x * v2.y - v2.x * v0.y) / denom
        let w1 = 1.0 - w2 - w3
        
        print("📐 [GHOST_CALC] Barycentric weights: w1=\(String(format: "%.3f", w1)), w2=\(String(format: "%.3f", w2)), w3=\(String(format: "%.3f", w3))")
        
        // PRIORITY 1: Attempt consensus + rigid transform (mirrors calculateGhostPositionForThirdVertex)
        // Check if target MapPoint AND at least 2 triangle vertices have consensus positions
        if let targetConsensus = mapPoint.consensusPosition {
            print("📍 [GHOST_CALC] Target has consensus position - attempting rigid transform")
            
            // Gather vertices that have BOTH consensus AND current session position
            var correspondences: [(consensus: simd_float3, current: simd_float3)] = []
            
            for (index, vertexMapPoint) in vertexMapPoints.enumerated() {
                if let vertexConsensus = vertexMapPoint.consensusPosition,
                   let vertexCurrent = mapPointARPositions[vertexMapPoint.id] {
                    correspondences.append((consensus: vertexConsensus, current: vertexCurrent))
                    print("   ✅ Vertex[\(index)] \(String(vertexMapPoint.id.uuidString.prefix(8))): consensus + current available")
                } else {
                    let hasConsensus = vertexMapPoint.consensusPosition != nil
                    let hasCurrent = mapPointARPositions[vertexMapPoint.id] != nil
                    print("   ⚠️ Vertex[\(index)] \(String(vertexMapPoint.id.uuidString.prefix(8))): consensus=\(hasConsensus), current=\(hasCurrent)")
                }
            }
            
            // Need at least 2 correspondences for rigid transform
            if correspondences.count >= 2 {
                print("📍 [GHOST_CALC] Found \(correspondences.count) correspondences - computing rigid transform")
                print("   Historical: P1=(\(String(format: "%.2f, %.2f, %.2f", correspondences[0].consensus.x, correspondences[0].consensus.y, correspondences[0].consensus.z))), P2=(\(String(format: "%.2f, %.2f, %.2f", correspondences[1].consensus.x, correspondences[1].consensus.y, correspondences[1].consensus.z)))")
                print("   Current:    P1=(\(String(format: "%.2f, %.2f, %.2f", correspondences[0].current.x, correspondences[0].current.y, correspondences[0].current.z))), P2=(\(String(format: "%.2f, %.2f, %.2f", correspondences[1].current.x, correspondences[1].current.y, correspondences[1].current.z)))")
                
                // Calculate rigid transform from consensus coordinate frame to current session frame
                if let transform = calculate2PointRigidTransform(
                    oldPoints: (correspondences[0].consensus, correspondences[1].consensus),
                    newPoints: (correspondences[0].current, correspondences[1].current)
                ) {
                    // Verify transform quality
                    let cosR = cos(transform.rotationY)
                    let sinR = sin(transform.rotationY)
                    let rotatedOld1 = simd_float3(
                        correspondences[1].consensus.x * cosR - correspondences[1].consensus.z * sinR,
                        correspondences[1].consensus.y,
                        correspondences[1].consensus.x * sinR + correspondences[1].consensus.z * cosR
                    )
                    let transformedOld1 = rotatedOld1 + transform.translation
                    let verificationError = simd_distance(transformedOld1, correspondences[1].current)
                    
                    if verificationError > 1.0 {
                        print("⚠️ [GHOST_CALC] Verification error \(String(format: "%.2f", verificationError))m exceeds 1.0m threshold")
                        print("   Historical consensus unreliable for this session - falling back to barycentric")
                        // Fall through to PRIORITY 2 (existing barycentric code below)
                    } else {
                        // Apply transform to target's consensus position
                        let transformedPosition = applyRigidTransform(
                            position: targetConsensus,
                            rotationY: transform.rotationY,
                            translation: transform.translation
                        )
                        
                        print("👻 [GHOST_CALC] Transformed consensus position: (\(String(format: "%.2f", transformedPosition.x)), \(String(format: "%.2f", transformedPosition.y)), \(String(format: "%.2f", transformedPosition.z)))")
                        print("   Original consensus: (\(String(format: "%.2f", targetConsensus.x)), \(String(format: "%.2f", targetConsensus.y)), \(String(format: "%.2f", targetConsensus.z)))")
                        print("   Verification error: \(String(format: "%.3f", verificationError))m ✓")
                        
                        return transformedPosition
                    }
                } else {
                    print("⚠️ [GHOST_CALC] Rigid transform calculation failed - falling back to barycentric")
                    // Fall through to PRIORITY 2
                }
            } else {
                print("📐 [GHOST_CALC] Only \(correspondences.count) correspondence(s) - need 2 for transform, using barycentric")
                // Fall through to PRIORITY 2
            }
        } else {
            print("📐 [GHOST_CALC] No consensus for target MapPoint \(String(mapPoint.id.uuidString.prefix(8))) - using barycentric")
            // Fall through to PRIORITY 2
        }
        
        // PRIORITY 2: Barycentric interpolation from current session data (existing code follows)
        
        // STEP 3: Get triangle's 3 vertex AR positions (3D positions)
```

**Notes:**
- Uses existing `mapPoint.consensusPosition` computed property
- Uses existing `vertexMapPoints` array (populated earlier in function)
- Uses existing helper functions `calculate2PointRigidTransform()` and `applyRigidTransform()`
- Returns early if transform succeeds; falls through to existing code if not

### Acceptance Criteria

1. **Build succeeds**

2. **First calibration pass (no history):**
   ```
   📐 [GHOST_CALC] No consensus for target MapPoint XXXXXXXX - using barycentric
   ```

3. **Second calibration pass (with history) - success:**
   ```
   📍 [GHOST_CALC] Target has consensus position - attempting rigid transform
      ✅ Vertex[0] XXXXXXXX: consensus + current available
      ✅ Vertex[1] YYYYYYYY: consensus + current available
   📍 [GHOST_CALC] Found 2 correspondences - computing rigid transform
   👻 [GHOST_CALC] Transformed consensus position: (...)
      Verification error: 0.XXXm ✓
   ```

4. **Fallback patterns work:**
   - Verification error > 1.0m → falls back to barycentric
   - Insufficient correspondences → falls back to barycentric

5. **No regression:** 3rd vertex ghost during initial calibration still uses `[GHOST_3RD]` logs

---

## Fill Triangle Button Fix

### Problem

Fill Triangle button posts notification missing `triangleStore`. Handler expects 4 parameters but only receives 3.

**Console shows:**
```
⚠️ [FILL_TRIANGLE] Invalid notification data:
   triangleID: true
   spacing: true
   triangleStore: false   ← MISSING
   arWorldMapStore: true
```

### Cursor Instructions

**CRITICAL CONSTRAINTS:**
1. Make ONLY the changes specified below
2. Do NOT refactor, optimize, or modify any other code
3. If you encounter errors, STOP and report the error message—do not attempt fixes
4. **Do NOT automatically push to git. Wait for explicit instructions to do so.**

---

**File:** `ARViewWithOverlays.swift`

**Location:** Find the Fill Triangle button action (search for `"Fill Triangle button"` comment):

```swift
                        // Fill Triangle button
                        Button(action: {
                            print("🎯 [FILL_TRIANGLE_BTN] Button tapped")
                            print("   Current state: \(arCalibrationCoordinator.stateDescription)")
                            
                            arCalibrationCoordinator.enterSurveyMode()
                            
                            print("🎯 [FILL_TRIANGLE_BTN] Entering survey mode")
                            print("   New state: \(arCalibrationCoordinator.stateDescription)")
                            
                            NotificationCenter.default.post(
                                name: NSNotification.Name("FillTriangleWithSurveyMarkers"),
                                object: nil,
                                userInfo: [
                                    "triangleID": triangle.id,
                                    "spacing": surveySpacing,
                                    "arWorldMapStore": arCalibrationCoordinator.arStore
                                ]
                            )
                        }) {
```

**Change:** Add `"triangleStore": arCalibrationCoordinator.triangleStore` to userInfo:

```swift
                        // Fill Triangle button
                        Button(action: {
                            print("🎯 [FILL_TRIANGLE_BTN] Button tapped")
                            print("   Current state: \(arCalibrationCoordinator.stateDescription)")
                            
                            arCalibrationCoordinator.enterSurveyMode()
                            
                            print("🎯 [FILL_TRIANGLE_BTN] Entering survey mode")
                            print("   New state: \(arCalibrationCoordinator.stateDescription)")
                            
                            NotificationCenter.default.post(
                                name: NSNotification.Name("FillTriangleWithSurveyMarkers"),
                                object: nil,
                                userInfo: [
                                    "triangleID": triangle.id,
                                    "spacing": surveySpacing,
                                    "triangleStore": arCalibrationCoordinator.triangleStore,
                                    "arWorldMapStore": arCalibrationCoordinator.arStore
                                ]
                            )
                        }) {
```

### Acceptance Criteria

1. **Build succeeds**

2. **No more invalid notification error** - should NOT see:
   ```
   ⚠️ [FILL_TRIANGLE] Invalid notification data:
      triangleStore: false
   ```

3. **Survey markers appear** after tapping Fill Triangle:
   - Console shows `✅ [FILL_TRIANGLE] Found triangle XXXXXXXX`
   - Grid of survey markers renders within triangle

---

## Files Summary

| File | Changes |
|------|---------|
| `ARCalibrationCoordinator.swift` | Priority 3: Add `markCalibrated()` call |
| `ARCalibrationCoordinator.swift` | Priority 1: Add consensus + rigid transform logic (~70 lines) |
| `ARViewWithOverlays.swift` | Fill Triangle: Add `triangleStore` to notification |

---

## Testing Order

1. **Fill Triangle fix** - Quick verification
2. **Priority 3** - Triangle persistence (requires app restart test)
3. **Priority 1** - Consensus transform (requires multiple calibration sessions)
