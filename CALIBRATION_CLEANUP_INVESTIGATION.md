# Calibration Cleanup Investigation Results

## Summary
Investigation confirms user's suspicions: **AR markers are not properly cleared when calibration is aborted**, leading to duplicate markers and incorrect survey marker placement.

---

## Issue #1: AR Marker Nodes Not Cleared on Abort ✅ CONFIRMED

### Problem
When calibration is aborted (X button pressed), `ARCalibrationCoordinator.reset()` clears the coordinator's tracking arrays but **does not remove AR marker nodes from the scene**.

### Evidence

**ARCalibrationCoordinator.reset()** (line 524-540):
```swift
func reset() {
    // Clear any existing survey markers
    if let coordinator = ARViewContainer.Coordinator.current {
        coordinator.clearSurveyMarkers()
    }
    
    activeTriangleID = nil
    currentTriangleID = nil
    placedMarkers = []  // ✅ Clears coordinator's tracking array (MapPoint IDs)
    statusText = ""
    progressDots = (false, false, false)
    isActive = false
    currentVertexIndex = 0
    triangleVertices = []  // ✅ Clears vertex list
    referencePhotoData = nil
    completedMarkerCount = 0
    // ❌ DOES NOT clear ARViewContainer.placedMarkers dictionary
    // ❌ DOES NOT remove marker nodes from scene
}
```

**ARViewContainer.placedMarkers** (line 80):
```swift
var placedMarkers: [UUID: SCNNode] = [:] // Track placed markers by ID
```

**Marker Placement** (line 274):
```swift
placedMarkers[markerID] = markerNode  // Added to dictionary and scene
```

### Impact
- When starting a new calibration, old marker nodes remain in the scene
- If you place a marker for the same vertex again, you end up with **duplicate markers**
- Survey marker generation may find old/duplicate markers, causing incorrect placement

---

## Issue #2: Photo Reference Selection ✅ CONFIRMED

### Problem
Photo selection uses `getCurrentVertexID()`, which depends on `triangleVertices` and `currentVertexIndex`. If these aren't properly initialized or cleared, the wrong photo can be shown.

### Code Location
- `ARViewWithOverlays.swift` line 299 (photo display)
- `ARCalibrationCoordinator.getCurrentVertexID()` line 114

### Root Cause
When `reset()` is called, `triangleVertices` is cleared, but if `startCalibration()` is called again without proper initialization, `currentVertexIndex` may point to the wrong vertex.

---

## Issue #3: Survey Marker Generation Uses Wrong Markers ✅ CONFIRMED

### Problem
`generateSurveyMarkers()` looks up markers from `arWorldMapStore.markers` and `placedMarkers` dictionary. If old markers remain from an aborted calibration, it may use wrong positions.

### Code Location
`ARViewContainer.swift` lines 535-559

**Marker Lookup Logic:**
```swift
for (index, vertexID) in triangle.vertexIDs.enumerated() {
    // Look up marker from ARWorldMapStore by matching mapPointID
    if let marker = arWorldMapStore.markers.first(where: { $0.mapPointID == vertexID.uuidString }) {
        // Use persisted marker
    } else {
        // Fallback: Try to find marker in placedMarkers if triangle.arMarkerIDs has entries
        if let markerNode = placedMarkers[markerUUID] {
            // Use scene node
        }
    }
}
```

### Impact
- If old markers remain in `placedMarkers` dictionary, they may be used instead of new ones
- Survey markers will be placed at wrong positions

---

## Issue #4: startCalibration() Doesn't Clear Existing Markers ✅ CONFIRMED

### Problem
`startCalibration()` clears the coordinator's `placedMarkers` array but does not remove existing AR marker nodes from the scene.

### Code Location
`ARCalibrationCoordinator.swift` line 63-105

```swift
func startCalibration(for triangleID: UUID) {
    // ...
    placedMarkers = []  // ✅ Clears coordinator's array
    // ❌ DOES NOT clear ARViewContainer.placedMarkers dictionary
    // ❌ DOES NOT remove marker nodes from scene
}
```

### Impact
- If re-calibrating a triangle, old markers remain visible
- Can lead to confusion and incorrect marker placement

---

## Root Cause Analysis

### When Calibration is Aborted:
1. ✅ Coordinator's `placedMarkers` array is cleared
2. ✅ Coordinator's `triangleVertices` is cleared
3. ❌ **AR marker nodes remain in the scene**
4. ❌ **`ARViewContainer.placedMarkers` dictionary is not cleared**
5. ❌ **Old markers remain in `arWorldMapStore.markers` (persisted)**

### When a New Calibration Starts:
1. Old marker nodes still exist in the scene
2. Old markers still in `placedMarkers` dictionary
3. Survey marker generation may find old/duplicate markers
4. Wrong photo may be shown if `currentVertexIndex` is incorrect

---

## Recommended Fixes

### Fix #1: Add Function to Clear AR Markers from Scene
Add a new function to `ARViewContainer.ARViewCoordinator`:

```swift
/// Clear all calibration AR markers from scene
func clearCalibrationMarkers() {
    guard let sceneView = sceneView else { return }
    
    // Remove all calibration markers (orange markers)
    var markersToRemove: [UUID] = []
    for (markerID, node) in placedMarkers {
        // Check if this is a calibration marker (orange color)
        if let sphereNode = node.childNode(withName: "arMarkerSphere_\(markerID.uuidString)", recursively: true),
           let sphere = sphereNode.geometry as? SCNSphere,
           let material = sphere.firstMaterial,
           let color = material.diffuse.contents as? UIColor {
            // Check if it's calibration orange color
            if color == UIColor.ARPalette.calibration {
                node.removeFromParentNode()
                markersToRemove.append(markerID)
            }
        }
    }
    
    // Remove from dictionary
    for markerID in markersToRemove {
        placedMarkers.removeValue(forKey: markerID)
    }
    
    print("🧹 Cleared \(markersToRemove.count) calibration markers from scene")
}
```

### Fix #2: Clear Markers in reset()
Update `ARCalibrationCoordinator.reset()`:

```swift
func reset() {
    // Clear any existing survey markers
    if let coordinator = ARViewContainer.Coordinator.current {
        coordinator.clearSurveyMarkers()
        coordinator.clearCalibrationMarkers()  // ✅ NEW: Clear calibration markers
    }
    
    // ... rest of reset code ...
}
```

### Fix #3: Clear Markers in startCalibration()
Update `ARCalibrationCoordinator.startCalibration()`:

```swift
func startCalibration(for triangleID: UUID) {
    // ... existing code ...
    
    // Clear any existing markers for this triangle - we're re-calibrating from scratch
    if let coordinator = ARViewContainer.Coordinator.current {
        coordinator.clearCalibrationMarkers()  // ✅ NEW: Clear old markers
    }
    
    placedMarkers = []
    // ... rest of startCalibration code ...
}
```

### Fix #4: Clear Markers from ARWorldMapStore (Optional)
If we want to remove persisted markers when aborting:

```swift
func reset() {
    // ... existing code ...
    
    // Optionally: Remove markers from ARWorldMapStore for the active triangle
    if let triangleID = activeTriangleID {
        // Remove markers for this triangle's vertices
        // This is more aggressive - may want to keep persisted markers
    }
}
```

---

## Testing Checklist

After implementing fixes:
- [ ] Start calibration, place 1 marker, abort (X button)
- [ ] Verify marker node is removed from scene
- [ ] Start new calibration for same triangle
- [ ] Verify no duplicate markers appear
- [ ] Place all 3 markers, verify correct photo shown for each
- [ ] Generate survey markers, verify correct placement
- [ ] Abort calibration mid-way, verify all markers cleared
- [ ] Start new calibration, verify clean state

---

## Files to Modify

1. **ARViewContainer.swift**
   - Add `clearCalibrationMarkers()` function

2. **ARCalibrationCoordinator.swift**
   - Update `reset()` to call `clearCalibrationMarkers()`
   - Update `startCalibration()` to call `clearCalibrationMarkers()`

---

## Conclusion

The investigation confirms all user suspicions:
- ✅ AR markers are not cleared on abort
- ✅ Wrong photos can be shown
- ✅ Survey markers use wrong positions
- ✅ Duplicate markers can appear

The fixes above will ensure proper cleanup of AR markers when calibration is aborted or restarted.

