# Triangle Patch Persistence Investigation

## Summary

**Triangle patches ARE persisted**, but there's a **rendering dependency issue** that causes them to appear inconsistently.

---

## Persistence Mechanism

### Storage Location
- **Storage Type**: UserDefaults (namespaced)
- **Key Format**: `"locations.<locationID>.triangles_v1"`
- **Example**: `"locations.museum.triangles_v1"`
- **Encoding**: JSON via `PersistenceContext`

### Code Location
```swift
// TrianglePatchStore.swift
private let persistenceKey = "triangles_v1"
private let ctx = PersistenceContext.shared

func save() {
    ctx.write(persistenceKey, value: triangles)  // Uses namespaced key
    print("💾 Saved \(triangles.count) triangle(s)")
}

func load() {
    guard let decoded: [TrianglePatch] = ctx.read(persistenceKey, as: [TrianglePatch].self) else {
        print("📂 No saved triangles found")
        return
    }
    triangles = decoded
    print("📂 Loaded \(triangles.count) triangle(s)")
}
```

---

## Loading Flow

### Initialization
1. **ContentView.swift** creates `TrianglePatchStore` as `@StateObject` (line 22)
2. **TrianglePatchStore.init()** immediately calls `load()`
3. **Problem**: At this point, `PersistenceContext.shared.locationID` may still be default ("home")

### Location Switching
1. **MapNavigationView.switchToLocation()** (line 175):
   - Sets `PersistenceContext.shared.locationID = id` FIRST
   - Then calls `trianglePatchStore.load()` (line 196)
   - This should work correctly

---

## Rendering Dependency Issue

### How Triangles Are Rendered
**TriangleOverlay.swift** renders triangles by:
1. Iterating through `triangleStore.triangles`
2. For each triangle, calling `getVertexPositions(vertexIDs)`
3. `getVertexPositions()` looks up MapPoints from `mapPointStore.points` using vertex IDs

```swift
private func getVertexPositions(_ vertexIDs: [UUID]) -> [CGPoint]? {
    var positions: [CGPoint] = []
    for id in vertexIDs {
        guard let point = mapPointStore.points.first(where: { $0.id == id }) else {
            return nil  // ❌ Returns nil if MapPoint not found
        }
        positions.append(point.mapPoint)
    }
    return positions.isEmpty ? nil : positions
}
```

### The Problem
**Triangles won't render if:**
- Triangles are loaded ✅
- But MapPoints aren't loaded yet ❌
- Or MapPoints are loaded but vertex IDs don't match ❌

**This explains why triangles "sometimes" appear:**
- They appear when MapPoints are loaded AND vertex IDs match
- They disappear when MapPoints aren't loaded or IDs don't match

---

## Potential Issues

### Issue 1: Initial Load Timing
- `TrianglePatchStore.init()` loads immediately
- May load from wrong location if `locationID` isn't set yet
- **Fix**: Don't load in `init()`, or ensure `locationID` is set first

### Issue 2: MapPoint Dependency
- Triangles require MapPoints to render
- If MapPoints load after triangles, triangles won't render
- **Fix**: Ensure MapPoints load before triangles, or add retry logic

### Issue 3: Vertex ID Mismatch
- Triangles store vertex IDs (UUIDs)
- If MapPoints are deleted/recreated, IDs won't match
- **Fix**: Add validation or migration logic

---

## Diagnostic Steps

### Check 1: Verify Persistence Key
```swift
// Add to UserDefaultsDiagnostics.swift
static func inspectTriangles(locationID: String) {
    let key = "locations.\(locationID).triangles_v1"
    let defaults = UserDefaults.standard
    
    guard let data = defaults.data(forKey: key) else {
        print("❌ No triangles found for key: \(key)")
        return
    }
    
    print("✅ Found triangles data: \(data.count) bytes")
    
    // Try to decode
    if let triangles = try? JSONDecoder().decode([TrianglePatch].self, from: data) {
        print("✅ Decoded \(triangles.count) triangles")
        for (idx, tri) in triangles.enumerated() {
            print("  [\(idx+1)] Triangle \(String(tri.id.uuidString.prefix(8)))")
            print("      Vertices: \(tri.vertexIDs.map { String($0.uuidString.prefix(8)) })")
            print("      Calibrated: \(tri.isCalibrated)")
        }
    } else {
        print("❌ Failed to decode triangles")
    }
}
```

### Check 2: Verify MapPoint Loading
```swift
// Check if MapPoints are loaded when triangles try to render
// Add logging to TriangleOverlay.getVertexPositions()
```

### Check 3: Verify Load Order
```swift
// In MapNavigationView.switchToLocation()
// Ensure load order is:
// 1. Set locationID
// 2. Load MapPoints
// 3. Load Triangles
```

---

## Recommended Fixes

### Fix 1: Defer Initial Load
```swift
// TrianglePatchStore.swift
init() {
    // Don't load here - wait for explicit load() call
    // load()  // ❌ Remove this
}

// Add explicit load call after locationID is set
func reloadForActiveLocation() {
    load()
}
```

### Fix 2: Add Retry Logic
```swift
// TriangleOverlay.swift
// Retry rendering when MapPoints become available
.onChange(of: mapPointStore.points.count) { _ in
    // Force re-render when MapPoints load
}
```

### Fix 3: Add Validation
```swift
// TrianglePatchStore.swift
func load() {
    guard let decoded: [TrianglePatch] = ctx.read(persistenceKey, as: [TrianglePatch].self) else {
        print("📂 No saved triangles found")
        return
    }
    
    // Validate vertex IDs exist in MapPoints
    // Filter out triangles with invalid vertex IDs
    triangles = decoded.filter { triangle in
        // Check if all vertices exist
    }
}
```

---

## Current Status

✅ **Persistence**: Working (UserDefaults, namespaced)
✅ **Loading**: Working (called in init() and switchToLocation())
❌ **Rendering**: Inconsistent (depends on MapPoint loading order)

---

## Next Steps

1. Add diagnostic logging to verify triangles are actually persisted
2. Check load order in `switchToLocation()`
3. Add retry logic for triangle rendering when MapPoints load
4. Add validation to filter invalid triangles

