# Crash Investigation: `'-[__NSCFNumber count]: unrecognized selector sent to instance'`

**Crash Context:** App crashes with `'-[__NSCFNumber count]: unrecognized selector sent to instance 0x8000000000000000'` after placing the final corner marker when all 5 zones are complete. The crash occurs in the notification handling chain after `ARMarkerPlaced` is received.

**Error Analysis:** The address `0x8000000000000000` is a tagged pointer for small integers in Objective-C/Swift. This suggests an integer value is being stored where an array/collection is expected, and `.count` is being called on it.

---

## Category 1: Notification UserInfo Type Safety

### Q1: All ARMarkerPlaced notification posts with userInfo

**Findings:**

1. **`ARViewContainer.swift:1791-1798`** - Normal marker placement:
```swift
userInfo: [
    "markerID": markerID,
    "position": [position.x, position.y, position.z] // ✅ Array
]
```

2. **`ARViewContainer.swift:634-638`** - Generic ghost adjustment (re-post):
```swift
var userInfo: [String: Any] = [
    "markerID": markerID,
    "position": [position.x, position.y, position.z], // ✅ Array
    "ghostMapPointID": ghostMapPointID,
    "isGhostConfirm": true,
    "mapPointID": ghostMapPointID
]
if let origPos = originalGhostPosition {
    userInfo["originalGhostPosition"] = [origPos.x, origPos.y, origPos.z] // ✅ Array
}
```

3. **`ARViewContainer.swift:1457-1466`** - Ghost confirmation:
```swift
userInfo: [
    "markerID": markerID,
    "position": [estimatedPosition.x, estimatedPosition.y, estimatedPosition.z], // ✅ Array
    "isGhostConfirm": true,
    "ghostMapPointID": ghostMapPointID
]
```

**Verdict:** All `ARMarkerPlaced` notifications correctly pass `position` as `[Float]` arrays. No `NSNumber` values found in position fields.

---

### Q2: CRAWL_CROSSHAIR path notifications

**Location:** `ARViewContainer.swift:538-577`

**Flow:**
1. `placeMarker()` is called at line 556 → This posts `ARMarkerPlaced` with standard `userInfo` (position as array)
2. No additional `ARMarkerPlaced` notification is posted in this path
3. `activateAdjacentTriangle()` is called but doesn't post notifications

**Verdict:** Only one `ARMarkerPlaced` notification is posted, with correct array format.

---

### Q3: `.count` calls on notification.userInfo values in ARViewWithOverlays

**Location:** `ARViewWithOverlays.swift:263-580`

**All `.count` calls found:**

1. **Line 216:** `if let posArray = notification.userInfo?["cameraPosition"] as? [Float], posArray.count == 3`
   - ✅ Type checked before `.count`

2. **Line 224:** `if let uuid = UUID(uuidString: key), posArray.count == 3`
   - ✅ `posArray` is from `ghostPosDict` which is cast to `[String: [Float]]`

3. **Line 292:** `let positionArray = notification.userInfo?["position"] as? [Float], positionArray.count == 3`
   - ✅ Type checked before `.count`

4. **Line 323:** `let positionArray = notification.userInfo?["position"] as? [Float], positionArray.count == 3`
   - ✅ Type checked before `.count`

5. **Line 440:** `if let origPosArray = notification.userInfo?["originalGhostPosition"] as? [Float], origPosArray.count == 3`
   - ✅ Type checked before `.count`

6. **Line 463:** `let positionArray = notification.userInfo?["position"] as? [Float], positionArray.count == 3`
   - ✅ Type checked before `.count`

7. **Line 569:** `if let originalGhostPosArray = notification.userInfo?["originalGhostPosition"] as? [Float], originalGhostPosArray.count == 3`
   - ✅ Type checked before `.count`

**Verdict:** All `.count` calls are properly type-checked. However, there may be indirect `.count` calls through SwiftUI bindings or `onChange` modifiers.

---

### Q4: All `notification.userInfo?["position"]` accesses

**Findings:** All accesses use proper type casting:
- `as? [Float]` before accessing
- Guard statements check `count == 3`

**Potential Issue:** If `position` is somehow set to a single `Float` or `NSNumber` instead of an array, the cast would fail and return `nil`, but downstream code might still try to call `.count` on the wrong type if there's a type confusion elsewhere.

---

## Category 2: State When All Zones Complete

### Q5: State of eligibility variables when all zones complete

**Variables:**
- `nextZoneEligibleMapPointID: UUID?` (line 203)
- `nextZoneEligibleZoneID: String?` (line 206)
- `confirmedNeighborCorners: [String: Set<UUID>]` (line 200)

**When zones complete:**
- `registerZoneCornerAnchor()` completes the 4th corner
- `checkNextZoneEligibility()` is called (if it exists)
- Need to check what happens when no more zones are eligible

**Finding:** `checkNextZoneEligibility()` function not found in search results. Need to search for zone completion logic.

---

### Q6: checkNextZoneEligibility() when no unplanted neighbors

**Finding:** Function not found. However, eligibility is set in `registerFillPointMarker()` around lines 2072-2084:

```swift
if let eligibleZone = zonesContainingCorner.first(where: { !plantedZoneIDs.contains($0.id) }) {
    nextZoneEligibleMapPointID = mapPointID
    nextZoneEligibleZoneID = eligibleZone.id
} else {
    // No eligible zone found - variables remain unchanged
    print("🔍 [ELIGIBILITY] No eligible zone found...")
}
```

**Issue:** When no eligible zone exists, `nextZoneEligibleMapPointID` and `nextZoneEligibleZoneID` are NOT explicitly set to `nil`. They retain their previous values.

---

### Q7: Flow after 4th corner confirmation

**Location:** `ARCalibrationCoordinator.swift:1471-1690` (`registerZoneCornerAnchor`)

**Flow:**
1. 4th corner placed → `registerZoneCornerAnchor()` called
2. Line 1551: `placedMarkers.append(mapPointID)`
3. Line 1552: `completedMarkerCount = placedMarkers.count`
4. Line 1554: Check if `placedMarkers.count == totalCorners` (4)
5. If complete:
   - Line 1556-1686: Compute transform, plant ghosts, set `calibrationState = .readyToFill`
   - Line 1686: `print("🎯 [ZONE_CORNER] Entering crawl mode with \(ghostMarkerPositions.count) ghost(s)")`
   - **⚠️ POTENTIAL ISSUE:** `ghostMarkerPositions.count` is called here

**Notifications posted:**
- None directly in `registerZoneCornerAnchor`
- Ghost planting may trigger `UpdateGhostSelection` notifications

**@Published properties changed:**
- `placedMarkers` (array append)
- `completedMarkerCount` (Int)
- `calibrationState` (enum)

---

## Category 3: Ghost Selection State

### Q8: updateGhostSelection() when ghostPositions is empty

**Location:** `ARCalibrationCoordinator.swift:5059-5100+`

**When empty:**
- `closestID` remains `nil`
- `selectedGhostMapPointID` is set to `nil` if it was previously set
- No `.count` calls on `ghostPositions` in this function

**Verdict:** No direct `.count` issues here.

---

### Q9: RemoveGhostMarker notification handling

**Search needed:** Find where `RemoveGhostMarker` is handled and what dictionaries are modified.

**Known locations:**
- `ARViewContainer.swift:544-548` posts `RemoveGhostMarker`
- Need to find handler in `ARCalibrationCoordinator`

---

### Q10: State after all zones complete and final ghost confirmed

**Variables to check:**
- `ghostMarkerPositions: [UUID: simd_float3]` - Should be empty or nearly empty
- `selectedGhostMapPointID: UUID?` - Should be nil
- `pendingMarkers: [UUID: PendingMarker]` - Should be empty

**Finding:** Need to trace the final ghost confirmation flow to see what state is set.

---

## Category 4: SwiftUI Binding and @Published Properties

### Q11: ForEach loops over arCalibrationCoordinator collections

**Found in `ARViewWithOverlays.swift`:**

1. **Line 2150:** `.onChange(of: arCalibrationCoordinator.placedMarkers.count)`
   - ✅ Safe - `placedMarkers` is `[UUID]`, `.count` is Int property

2. **Line 2232:** `triangle.vertexIDs.count == 3`
   - ✅ Safe - `vertexIDs` is `[UUID]`

**Potential Issue:** If any `@Published` property is accidentally set to a wrong type (e.g., Int instead of Array), SwiftUI's `onChange` might trigger with the wrong type.

---

### Q12: @Published dictionary/array properties

**Found in `ARCalibrationCoordinator.swift`:**

1. `@Published var placedMarkers: [UUID] = []` (line 45)
2. `@Published var sessionCalibratedTriangles: Set<UUID> = []` (line 49)
3. `@Published var demotedGhostMapPointIDs: Set<UUID> = []` (line 106)

**Non-@Published but accessed:**
- `var mapPointARPositions: [UUID: simd_float3] = [:]` (line 56)
- `var ghostMarkerPositions: [UUID: simd_float3] = [:]` (line 70)
- `var pendingMarkers: [UUID: PendingMarker] = [:]` (line 73)
- `var confirmedNeighborCorners: [String: Set<UUID>] = [:]` (line 200)

**Issue:** If any of these are accidentally set to a single value instead of a collection, `.count` calls would crash.

---

### Q13: onChange modifiers reacting to collection changes

**Found:**
- Line 2150: `.onChange(of: arCalibrationCoordinator.placedMarkers.count)`

**Race Condition Risk:** If `placedMarkers` is temporarily replaced with a wrong type during state updates, the `onChange` handler might receive the wrong type.

---

## Category 5: The Specific Crash Path

### Q14: Code path after ARMarkerPlaced trace but before crash

**Sequence from logs:**
```
📍 [CRAWL_CROSSHAIR] Registered marker 47D34897 → MapPoint 7314A6D4
🔍 [ACTIVATE_ADJACENT_DEBUG] Function called with: ...
⚠️ [ADJACENT_ACTIVATE] No uncalibrated triangle shares 2 vertices...
⚠️ [CRAWL_CROSSHAIR] Failed to activate adjacent triangle
🔍 [REGISTER_MARKER_TRACE] ARMarkerPlaced notification received
*** Terminating app...
```

**Handler path in `ARViewWithOverlays.swift:263-580`:**

1. Line 263: `.onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ARMarkerPlaced")))`
2. Line 264: Trace printed
3. Line 270: `isGhostConfirm` extracted
4. Line 272: `ghostMapPointID` extracted
5. Line 274-279: If ghost confirm, clear selection
6. Line 282-285: Check survey mode (skip if true)
7. Line 287-316: Check swath survey mode (skip)
8. Line 318-455: **ZONE CORNER CALIBRATION MODE** - This is the active path!

**Zone Corner path (lines 318-455):**
- Line 320: `arViewLaunchContext.launchMode == .zoneCornerCalibration`
- Line 321-323: Extract `markerID` and `positionArray` with type check
- Line 326-336: Determine `isPlacingVertices` vs `readyToFill`
- Line 339-341: Extract ghost confirm info
- Line 343-389: If `isPlacingVertices` → register corner
- Line 391-454: If `isZoneCornerGhostConfirm` → register ghost

**After `activateAdjacentTriangle` returns nil:**
- The function returns `nil` at line 4905
- No state changes occur in the nil return path
- However, the notification handler continues processing

**CRITICAL:** The crash happens AFTER the trace, so it's in the zone corner handler. Need to check what happens when processing the final corner marker.

---

### Q15: activateAdjacentTriangle() state changes when returning nil

**Location:** `ARCalibrationCoordinator.swift:4850-4906`

**When returning nil:**
- Line 4904: `print("⚠️ [ADJACENT_ACTIVATE] No uncalibrated triangle shares 2 vertices...")`
- Line 4905: `return nil`
- **No state modifications occur**

**Verdict:** Returning nil doesn't modify state, so this shouldn't cause downstream issues.

---

### Q16: Integer/count stored in dictionary expected to contain arrays

**Search for patterns:**
- Dictionary assignments where a count/int might be stored
- `userInfo` dictionaries with ambiguous types

**Found in `ARViewContainer.swift:624-633`:**
```swift
var userInfo: [String: Any] = [
    "markerID": markerID,
    "position": [position.x, position.y, position.z],
    "ghostMapPointID": ghostMapPointID,
    "isGhostConfirm": true,
    "mapPointID": ghostMapPointID
]
```

**Potential Issue:** If `position` is accidentally set to a single `Float` instead of `[Float]`, but the key name suggests it should be an array, downstream code might call `.count` on it.

**However:** All accesses properly cast to `[Float]` first, so this shouldn't be the issue.

---

## Category 6: Eligibility Checking Path

### Q17: checkNextZoneEligibility() return path when no eligible zone

**Finding:** Function not found. Eligibility is set inline in `registerFillPointMarker()`.

**When no eligible zone:**
- Lines 2085-2091: Logs but doesn't clear `nextZoneEligibleMapPointID` or `nextZoneEligibleZoneID`
- These retain previous values
- If a view tries to access these and expects arrays, could cause issues

---

### Q18: SwiftUI view code accessing eligibility state after ARMarkerPlaced

**Need to search:** Find views that bind to `nextZoneEligibleMapPointID` or `nextZoneEligibleZoneID` and call `.count` on them.

---

### Q19: @Published properties changed in registerFillPointMarker

**Location:** `ARCalibrationCoordinator.swift:1968+`

**Need to read:** Full function to see what @Published properties change.

---

## Category 7: Dictionary Key/Value Type Confusion

### Q20: Ambiguous dictionary types in ARCalibrationCoordinator

**Found:**
- `sessionMarkerPositions: [String: simd_float3]` (line 53) - ✅ Typed
- `mapPointARPositions: [UUID: simd_float3]` (line 56) - ✅ Typed
- `ghostMarkerPositions: [UUID: simd_float3]` (line 70) - ✅ Typed
- `pendingMarkers: [UUID: PendingMarker]` (line 73) - ✅ Typed
- `confirmedNeighborCorners: [String: Set<UUID>]` (line 200) - ✅ Typed

**Verdict:** All dictionaries are properly typed. No `[String: Any]` or `[UUID: Any]` found in coordinator.

---

### Q21: Assignments to sessionMarkerPositions, mapPointARPositions, etc.

**Need to search:** Find all assignments to these dictionaries to verify correct types are stored.

---

### Q22: notification.userInfo values used without explicit casting

**Finding:** All accesses found use explicit casting:
- `as? [Float]`
- `as? UUID`
- `as? Bool`

**However:** If a value is extracted and stored in a variable, then later accessed, there could be type confusion.

---

## CRITICAL FINDINGS

### Most Likely Crash Cause

Based on the investigation, the most likely cause is:

**PRIMARY SUSPECT: Line 1686 in `registerZoneCornerAnchor()`**

```swift
print("🎯 [ZONE_CORNER] Entering crawl mode with \(ghostMarkerPositions.count) ghost(s)")
```

**Analysis:**
- `ghostMarkerPositions` is declared as `var ghostMarkerPositions: [UUID: simd_float3] = [:]` (line 70)
- Dictionaries DO have a `.count` property, so this should be safe
- **HOWEVER:** If `ghostMarkerPositions` is somehow corrupted or set to a wrong type, this would crash
- The crash address `0x8000000000000000` suggests a tagged pointer (small integer), which means something that should be a collection is actually an `NSNumber`

**Secondary Suspects:**

1. **Notification userInfo type confusion:** If `position` is somehow set to a single `Float` or `NSNumber` instead of `[Float]`, and there's a code path that doesn't properly cast it before calling `.count`, it would crash.

2. **SwiftUI binding race condition:** If a `@Published` property is temporarily set to the wrong type during a state update, and a SwiftUI view tries to call `.count` on it, it would crash.

3. **Dictionary assignment corruption:** If `ghostMarkerPositions` is ever assigned a non-dictionary value (e.g., a count integer), subsequent `.count` calls would crash.

**Key Finding:** All `.count` calls on `userInfo` values are properly type-checked. The issue is likely in state management or dictionary assignments.

---

## RECOMMENDED INVESTIGATION STEPS

1. **Add defensive type checking** before all `.count` calls on dictionary/array values from `userInfo`
2. **Add logging** in `registerZoneCornerAnchor()` to verify `ghostMarkerPositions` type before line 1686
3. **Check** if `ghostMarkerPositions` is ever assigned a non-dictionary value
4. **Verify** all `@Published` property assignments maintain correct types
5. **Add** explicit nil checks and type validation in notification handlers

---

## ASSIGNMENT ANALYSIS

### ghostMarkerPositions Assignments Found

All assignments to `ghostMarkerPositions` are correct:
- `ARViewContainer.swift:1218` - `ghostMarkerPositions[mapPointID] = position` ✅
- `ARViewContainer.swift:1221` - `arCalibrationCoordinator?.ghostMarkerPositions[mapPointID] = position` ✅
- `ARViewContainer.swift:1270` - `ghostMarkerPositions[mapPointID] = position` ✅
- `ARViewContainer.swift:1273` - `arCalibrationCoordinator?.ghostMarkerPositions[mapPointID] = position` ✅
- `ARViewContainer.swift:1923` - `self.ghostMarkerPositions[mapPointID] = position` ✅
- `ARCalibrationCoordinator.swift:2211` - `ghostMarkerPositions[mapPointID] = marker.position` ✅
- `ARCalibrationCoordinator.swift:2310` - `ghostMarkerPositions[vertexID] = ghostPosition` ✅

**Verdict:** All assignments are type-safe. The dictionary is never reassigned to a different type.

---

## CRASH PATH ANALYSIS

### Exact Crash Location

Based on the log sequence:
```
📍 [CRAWL_CROSSHAIR] Registered marker 47D34897 → MapPoint 7314A6D4
🔍 [ACTIVATE_ADJACENT_DEBUG] Function called with: ...
⚠️ [ADJACENT_ACTIVATE] No uncalibrated triangle shares 2 vertices...
⚠️ [CRAWL_CROSSHAIR] Failed to activate adjacent triangle
🔍 [REGISTER_MARKER_TRACE] ARMarkerPlaced notification received
*** Terminating app...
```

**The crash happens:**
1. After `ARMarkerPlaced` notification is received
2. In the notification handler in `ARViewWithOverlays.swift`
3. Specifically in the Zone Corner calibration path (lines 318-455)
4. After the trace is printed but before the handler completes

**Most likely crash point:** Line 1686 in `registerZoneCornerAnchor()` when it calls `ghostMarkerPositions.count`, BUT this is called AFTER the notification handler processes the marker. So the crash might be happening in a SwiftUI view update triggered by state changes.

---

## ACTIONABLE FIXES

### Fix 1: Add Defensive Type Check at Line 1686

```swift
// Before line 1686:
let ghostCount: Int
if let ghostDict = ghostMarkerPositions as? [UUID: simd_float3] {
    ghostCount = ghostDict.count
} else {
    print("⚠️ [ZONE_CORNER] CRITICAL: ghostMarkerPositions is not a dictionary! Type: \(type(of: ghostMarkerPositions))")
    ghostCount = 0
}
print("🎯 [ZONE_CORNER] Entering crawl mode with \(ghostCount) ghost(s)")
```

### Fix 2: Add Type Validation in Notification Handler

Add after line 264 in `ARViewWithOverlays.swift`:
```swift
// Defensive check: verify userInfo types
if let positionValue = notification.userInfo?["position"] {
    if !(positionValue is [Float]) {
        print("⚠️ [REGISTER_MARKER_TRACE] CRITICAL: position is not [Float]! Type: \(type(of: positionValue))")
        return
    }
}
```

### Fix 3: Add Runtime Type Checking

Add a helper function to validate dictionary types:
```swift
func validateGhostMarkerPositions() -> Bool {
    guard ghostMarkerPositions is [UUID: simd_float3] else {
        print("❌ [TYPE_CHECK] ghostMarkerPositions corrupted! Type: \(type(of: ghostMarkerPositions))")
        return false
    }
    return true
}
```

Call this before line 1686.

---

## NEXT STEPS

1. ✅ Search for all assignments to `ghostMarkerPositions` - COMPLETE (all are type-safe)
2. ✅ Search for all places where `.count` is called on values that might come from `userInfo` - COMPLETE (all are type-checked)
3. **Add defensive type checking in the crash path** - TODO
4. **Review zone completion flow for type safety issues** - TODO
5. **Add runtime validation** before critical `.count` calls - TODO
6. **Test with all 5 zones complete** to reproduce and verify fix - TODO
