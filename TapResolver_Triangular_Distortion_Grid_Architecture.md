# TapResolver: Triangular-Cell Distortion Grid System

## Architectural Vision

TapResolver builds a **self-reinforcing spatial correction mesh** that progressively improves AR-to-Map accuracy through accumulated calibration data. Each calibration pass adds "nails" to a rubber sheet, pinning the 2D map to physical reality.

---

## Core Concept: Triangulated Irregular Network (TIN)

The system treats the museum floor as a mesh of triangular patches. Each triangle:

- Has 3 vertices (MapPoints with `.triangleEdge` role)
- When calibrated, maps 3 known 2D positions → 3 measured AR positions
- Provides **local distortion correction** via barycentric interpolation
- Shares edges with adjacent triangles for seamless transitions

```
    Map Space (2D)                    AR Space (3D)
    
       A────────B                        A'────────B'
      / \      / \                      / \      / \
     /   \  T1/   \                    /   \    /   \
    /  T0 \  /  T2 \      ═══════>    /     \  /     \
   C───────D────────E                C'──────D'───────E'
    \     / \      /                  \     / \      /
     \   /   \    /                    \   /   \    /
      \ / T3  \  /                      \ /     \  /
       F───────G                         F'──────G'

   Each triangle independently corrects for local map distortion
```

---

## The Coordinate Frame Problem

### The Challenge

ARKit sessions start with arbitrary origins. Session 1's coordinate frame ≠ Session 2's frame:

```
Session A origin: (0, 0, 0) at front entrance
Session B origin: (0, 0, 0) at gift shop (different physical location!)

Same MapPoint "D" might be recorded as:
  - Session A: AR position (4.2, -1.1, -3.8)
  - Session B: AR position (-2.1, -1.0, 5.4)
  
These are BOTH correct within their respective frames.
```

### The Solution: Consensus + Rigid Transform

**Map-Canonical Coordinate System** emerges from consensus:

1. **Store all observations** in `MapPoint.positionHistory` with session IDs
2. **Compute consensus** as weighted average (higher confidence = more weight)
3. **When new session starts**, find 2+ shared MapPoints between historical consensus and current session
4. **Compute rigid transform** (rotation + translation) from consensus → current frame
5. **Apply transform** to historical positions to plant accurate ghosts

```
Session B starts, places markers on MapPoints X and Y:

Historical consensus:     Current session:
  X: (1.0, -1.1, 2.0)      X: (3.5, -1.0, -1.2)
  Y: (4.0, -1.1, 2.5)      Y: (6.5, -1.0, -1.7)

Compute transform T such that:
  T(consensus_X) ≈ current_X
  T(consensus_Y) ≈ current_Y

Now for any MapPoint Z with consensus position:
  ghost_Z = T(consensus_Z)
```

---

## Data Model

### MapPoint.positionHistory

```swift
struct ARPositionRecord: Codable {
    let position: simd_float3      // AR world position
    let sessionID: String          // Which AR session
    let timestamp: Date            // When recorded
    let confidence: Float          // 0.0-1.0 (affects consensus weight)
    // 0.95 = confirmed ghost
    // 0.90 = adjusted ghost  
    // 0.85 = regular marker placement
    // 0.10 = outlier/rejected
}
```

### MapPoint.consensusPosition (Computed Property)

```swift
var consensusPosition: simd_float3? {
    // Weighted average of positionHistory
    // Higher confidence records have more influence
    // Outliers (low confidence) are effectively ignored
    // Returns nil if insufficient data
}
```

### Triangle Patch State

```swift
struct TrianglePatch {
    let vertexIDs: [UUID]           // 3 MapPoint IDs
    var isCalibrated: Bool          // Has been calibrated at least once
    var arMarkerIDs: [String]       // Current session's AR markers (may be stale)
    var legMeasurements: [...]      // Distance comparisons for quality
}
```

### Session-Scoped State (ARCalibrationCoordinator)

```swift
// Current session positions - lost on app close
private var mapPointARPositions: [UUID: simd_float3]  // MapPointID → AR position

// This is the SOURCE OF TRUTH for current session
// Updated by both regular calibration AND crawl mode
```

---

## Data Flow

### Recording (Marker Placed or Ghost Confirmed)

```
User places marker OR confirms ghost
    │
    ▼
mapPointARPositions[mapPointID] = arPosition  ← Session cache (ephemeral)
    │
    ▼
ARPositionRecord created with:
  - position: arPosition
  - sessionID: current session
  - confidence: 0.95 (confirmed) / 0.90 (adjusted) / 0.85 (placed)
    │
    ▼
mapStore.addPositionRecord(mapPointID, record)  ← Persisted to MapPoint.positionHistory
    │
    ▼
MapPoint.consensusPosition recalculates  ← Available for future sessions
```

### Retrieval (Planting Ghost Marker)

```
Need to plant ghost for MapPoint Z in adjacent triangle
    │
    ▼
┌─────────────────────────────────────────────────────────┐
│ PRIORITY 1: Consensus + Rigid Transform                  │
│                                                          │
│ Does Z have consensusPosition?                           │
│ Do 2 shared edge vertices have BOTH:                     │
│   - Current session position (in mapPointARPositions)    │
│   - Consensus position (from positionHistory)            │
│                                                          │
│ If YES:                                                  │
│   1. Compute rigid transform: consensus → current        │
│   2. Verify transform quality (< 1.0m error)             │
│   3. ghost_Z = transform(consensus_Z)                    │
│   4. RETURN ghost_Z                                      │
└─────────────────────────────────────────────────────────┘
    │ (if consensus unavailable or transform fails)
    ▼
┌─────────────────────────────────────────────────────────┐
│ PRIORITY 2: Barycentric from Current Session             │
│                                                          │
│ Get 3 vertex positions from mapPointARPositions          │
│ Calculate barycentric weights from 2D map positions      │
│ Apply weights to 3D AR positions                         │
│ RETURN interpolated position                             │
└─────────────────────────────────────────────────────────┘
```

---

## The Self-Reinforcing Loop

```
┌──────────────────────────────────────────────────────────────┐
│                     CALIBRATION PASS N                        │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  1. User enters through any triangle on 2D map               │
│     (New AR session with new origin)                         │
│                                                              │
│  2. Places first 2 markers                                   │
│     → Establishes current session frame                      │
│     → If these MapPoints have consensus, compute transform   │
│                                                              │
│  3. Ghost planted for 3rd vertex                             │
│     → Uses transformed consensus if available                │
│     → Falls back to 2D map geometry if not                   │
│                                                              │
│  4. User confirms/adjusts ghost                              │
│     → New ARPositionRecord added to positionHistory          │
│     → Consensus improves for this MapPoint                   │
│                                                              │
│  5. Crawl to adjacent triangle                               │
│     → Ghost planted using same hierarchical logic            │
│     → 2 shared edge vertices provide transform               │
│     → 1 new vertex gets ghost from consensus OR barycentric  │
│                                                              │
│  6. Repeat steps 4-5 across multiple triangles               │
│                                                              │
│  7. Session ends                                             │
│     → All confirmed positions now in positionHistory         │
│     → Consensus for all touched MapPoints is updated         │
│                                                              │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────┐
│                     CALIBRATION PASS N+1                      │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  • More MapPoints have consensus positions                   │
│  • Rigid transforms are more accurate (more correspondences) │
│  • Ghosts are planted closer to physical reality             │
│  • User adjustments are smaller                              │
│  • New data further refines consensus                        │
│                                                              │
│  RESULT: Each pass improves accuracy of subsequent passes    │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

## User Position Projection

### Current State (Broken)

`projectARPositionToMap()` in ARViewWithOverlays.swift:
- Only looks at `selectedTriangle`
- Gets AR positions from `triangle.arMarkerIDs` → `arStore.marker()` (wrong data path)
- Returns nil if user outside triangle

### Required Behavior

```
User's AR camera position (continuous)
    │
    ▼
Find ALL triangles with 3 vertices in mapPointARPositions
    │
    ▼
For each usable triangle:
  - Compute barycentric weights from user's AR XZ position
  - If user INSIDE triangle (all weights 0-1) → use this triangle
    │
    ▼
If inside a triangle:
  - Apply barycentric weights to 2D MapPoint positions
  - Return interpolated 2D map position
    │
    ▼
If OUTSIDE all triangles:
  - Find nearest triangle (by centroid)
  - Extrapolate using same barycentric math (weights extend beyond 0-1)
  - Return extrapolated position (lower confidence, but functional)
```

### Key Insight

User position projection should:
1. Work globally (not tied to `.readyToFill` state)
2. Activate as soon as ≥2 markers placed (linear interpolation possible)
3. Use the same extrapolation math as ghost markers
4. Automatically improve as more triangles are calibrated

---

## Current Implementation Gaps

### Gap 1: Crawl Mode Ignores Consensus

**Location:** `ARCalibrationCoordinator.calculateGhostPosition()` (line 528)

**Problem:** Only uses current session data (`sessionMarkerPositions`, `mapPointARPositions`). Does NOT check `consensusPosition` or compute rigid transforms.

**Fix:** Add PRIORITY 1 logic (consensus + transform) before existing barycentric logic. Mirror the approach in `calculateGhostPositionForThirdVertex()`.

### Gap 2: User Position Uses Wrong Data Path

**Location:** `ARViewWithOverlays.projectARPositionToMap()` (line 1708)

**Problem:** Looks for AR positions in `triangle.arMarkerIDs` → `arStore.marker()`. This path isn't updated during crawl mode.

**Fix:** Move projection to coordinator, use `mapPointARPositions` as source, iterate all usable triangles.

### Gap 3: Triangle Calibration Not Persisted in Crawl Mode

**Location:** `ARCalibrationCoordinator.activateAdjacentTriangle()`

**Problem:** Initial triangle uses `finalizeCalibration()` which sets `triangle.isCalibrated = true`. Crawl mode may not be calling equivalent.

**Fix:** Ensure `activateAdjacentTriangle()` marks the new triangle as calibrated after ghost is confirmed.

---

## Files Involved

| File | Role |
|------|------|
| `ARCalibrationCoordinator.swift` | Session state, ghost calculation, crawl logic |
| `MapPoint.swift` (via MapPointStore) | Position history, consensus computation |
| `TrianglePatch.swift` | Triangle model, calibration status |
| `TrianglePatchStore.swift` | Triangle persistence, barycentric projection |
| `ARViewWithOverlays.swift` | User position tracking, PiP map |
| `BarycentricMapping.swift` | Utility functions for interpolation |

---

## Implementation Priority

1. **Fix crawl mode ghost planting** - Add consensus + transform priority
2. **Fix user position projection** - Use mapPointARPositions, iterate all triangles
3. **Verify triangle calibration persistence** - Ensure crawled triangles marked calibrated
4. **Add extrapolation for outside-triangle positions** - Same math, extended weights

---

## Success Metrics

After implementation:

- [ ] Ghost markers improve accuracy with each calibration pass
- [ ] User position displays on PiP map during any calibration state (after 2+ markers)
- [ ] User position smoothly transitions between triangles
- [ ] Crawled triangles appear as calibrated on 2D map
- [ ] Console shows "Transformed consensus" logs during crawl mode (not just "using map geometry")

---

## Session Handoff Notes

**Context window exhausted at:** ~188k/190k tokens (99%)

**Last verified working:**
- Ghost duplication fix (checking `mapPointARPositions` instead of `arWorldMapStore.markers`)
- GhostInteractionButtons callback wiring fix
- Main thread safety fix specified but not yet applied

**Files to request in next session:**
- `ARCalibrationCoordinator.swift` (full)
- `MapPoint.swift` or `MapPointStore.swift` (for consensusPosition implementation)
- This document as architectural reference

**Key code locations:**
- `calculateGhostPosition()` - line 528 (needs consensus priority)
- `calculateGhostPositionForThirdVertex()` - line 683 (reference implementation)
- `projectARPositionToMap()` - line 1708 (needs rewrite)
- `mapPointARPositions` - line 43 (session truth source)
