# Corner-Pin Bilinear Transformation and Triangular Patch Distortion Mesh: Relationship and Integration

**Version:** 1.0  
**Date:** January 2025  
**Status:** Architectural Documentation

---

## Executive Summary

TapResolver uses a **two-layer calibration system** that combines global bilinear corner-pin projection with local triangular patch refinement:

1. **Bilinear Corner-Pin (Global Layer):** Projects all triangle vertices from 2D map coordinates to 3D AR space using four zone corners as control points
2. **Triangular Patch Mesh (Local Layer):** Provides fine-grained distortion correction through barycentric interpolation within triangular regions

These systems work together: bilinear provides the initial projection framework, while triangular patches enable localized corrections that accumulate over multiple calibration sessions.

---

## 1. The Two-Layer Architecture

### 1.1 Layer 1: Bilinear Corner-Pin Projection (Global)

**Purpose:** Establish initial 2D→3D mapping for the entire zone using four corner control points.

**How It Works:**
- Four zone corners define a quadrilateral in both 2D map space and 3D AR space
- Any point within (or outside) the quad can be projected using bilinear interpolation
- The projection handles non-uniform distortion across the mapped area

**Mathematical Model:**
```
Given:
  - 4 corners: A (0,0), B (1,0), C (1,1), D (0,1) in UV space
  - Point P with UV coordinates (u, v)
  
Projection:
  AR_P = (1-u)(1-v) × AR_A + u(1-v) × AR_B + uv × AR_C + (1-u)v × AR_D
```

**Key Properties:**
- **Global:** Single projection function covers entire zone
- **Non-uniform:** Handles distortion that varies across the space
- **Extrapolatable:** Works for points outside the quad (UV > 1 or < 0)

### 1.2 Layer 2: Triangular Patch Mesh (Local)

**Purpose:** Provide localized distortion correction within triangular regions.

**How It Works:**
- The zone is subdivided into triangular patches (Triangulated Irregular Network - TIN)
- Each triangle has 3 vertices (MapPoints with `.triangleEdge` role)
- Barycentric interpolation provides smooth transitions between triangles

**Mathematical Model:**
```
Given:
  - Triangle vertices: V0, V1, V2 (in 2D map space)
  - Point P within triangle
  - Barycentric weights: w0, w1, w2 (sum to 1.0)
  
Interpolation:
  AR_P = w0 × AR_V0 + w1 × AR_V1 + w2 × AR_V2
```

**Key Properties:**
- **Local:** Each triangle provides independent correction
- **Smooth:** Adjacent triangles share edges for seamless transitions
- **Refinable:** Each calibration pass improves accuracy

---

## 2. How They Work Together

### 2.1 Initial Projection Phase

When Zone Corner calibration completes (4th corner placed):

```
┌─────────────────────────────────────────────────────────────┐
│ Step 1: Bilinear Setup                                      │
│   • Sort 4 corners counter-clockwise                        │
│   • Store 2D positions: sortedZoneCorners2D                │
│   • Store 3D positions: sortedZoneCorners3D                │
│   • Set flag: hasBilinearCorners = true                      │
└─────────────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 2: Project All Triangle Vertices                       │
│   Function: plantGhostsForAllTriangleVerticesBilinear()     │
│                                                              │
│   For each triangle vertex:                                  │
│     1. Get 2D map position (CGPoint)                         │
│     2. Compute UV coordinates via inverseBilinear()          │
│     3. Project to 3D AR via bilinearInterpolate()            │
│     4. Apply distortion correction (if available)           │
│     5. Ground to floor level                                 │
│     6. Spawn Ghost Marker                                    │
└─────────────────────────────────────────────────────────────┘
```

**Code Reference:** `ARCalibrationCoordinator.swift:1590-1690`

### 2.2 Distortion Correction Storage

**Critical Insight:** Distortion vectors are stored **relative to bilinear projection**, not as absolute positions.

```
For each MapPoint:
  idealPosition = bilinearProjection(2D_map_position)
  actualPosition = userAdjustedPosition (from calibration)
  
  distortionVector = actualPosition - idealPosition
  
  Stored: consensusDistortionVector (blended across sessions)
```

**Why This Works:**
- Bilinear projection adapts to current corner positions (which vary by session)
- Distortion represents the **difference from projection to reality**
- This difference is a property of **physical space**, not the session
- Different corners → different projection → same distortion → correct final position

**Code Reference:** `ARCalibrationCoordinator.swift:1657-1666`

### 2.3 Ghost Planting with Distortion Correction

When planting ghosts for triangle vertices:

```swift
// 1. Project via bilinear (initial position)
guard var finalGhostPosition = projectPointViaBilinear(mapPoint: mapPoint.mapPoint) else {
    return  // Point outside quad
}

// 2. Ground to floor level
finalGhostPosition.y = groundY

// 3. Apply distortion correction if available
if let distortion = mapPoint.consensusDistortionVector {
    let horizontalCorrection = simd_float3(distortion.x, 0, distortion.z)
    finalGhostPosition += horizontalCorrection
    // Ghost now appears at corrected position
}
```

**Result:**
- First session: Ghosts appear at bilinear-projected positions
- Subsequent sessions: Ghosts appear at bilinear + distortion correction
- Each adjustment refines the distortion vector
- System converges toward accurate positions

---

## 3. The Feedback Loop

### 3.1 Session N: Initial Calibration

```
1. User places 4 zone corners
   → Bilinear projection established

2. System projects all triangle vertices via bilinear
   → Ghost markers appear at projected positions

3. User adjusts misaligned ghosts
   → Distortion vectors computed: actual - bilinear

4. Distortion vectors stored per MapPoint
   → consensusDistortionVector updated (weighted average)

5. User calibrates multiple triangles
   → More distortion data accumulated
```

### 3.2 Session N+1: Refined Calibration

```
1. User places 4 zone corners (may be different positions due to drift)
   → New bilinear projection established

2. System projects triangle vertices:
   → Bilinear projection (adapts to new corners)
   → + Distortion correction (from Session N)
   → = More accurate ghost positions

3. User makes smaller adjustments (if any)
   → Distortion vectors refined further

4. Consensus improves with each session
   → System converges toward physical reality
```

### 3.3 Why It Works Across Sessions

**The Key Insight:**

```
Session A corners: A₁, B₁, C₁, D₁
Session B corners: A₂, B₂, C₂, D₂  (different positions)

Point P:
  Session A: bilinear₁(P) + distortion(P) = actual(P)
  Session B: bilinear₂(P) + distortion(P) = actual(P)
  
  distortion(P) is the SAME (physical property)
  bilinear₁ ≠ bilinear₂ (different corner positions)
  But: bilinear₁(P) + distortion = bilinear₂(P) + distortion
```

The distortion vector is **session-invariant** because it represents the difference between idealized map geometry and physical reality.

---

## 4. Triangular Patches: Local Refinement

### 4.1 Triangle Structure

Each triangle in the mesh:
- **Vertices:** 3 MapPoints with `.triangleEdge` role
- **Edges:** Shared with adjacent triangles
- **Interior:** Can contain feature points (not directly calibrated)

### 4.2 Barycentric Interpolation Within Triangles

For points inside a triangle (feature points, user position):

```
1. Identify containing triangle (2D map lookup)
2. Compute barycentric coordinates (w0, w1, w2)
3. Retrieve calibrated AR positions of 3 vertices
4. Interpolate: AR_point = w0×AR_V0 + w1×AR_V1 + w2×AR_V2
```

**Advantages:**
- Smooth transitions between triangles
- Local corrections don't affect distant regions
- Can extrapolate outside triangles (weights extend beyond [0,1])

### 4.3 Relationship to Bilinear

**Bilinear provides:**
- Initial positions for triangle vertices
- Global framework for the entire zone

**Triangular patches provide:**
- Local refinement within regions
- Smooth interpolation for interior points
- Independent correction per triangle

**Together:**
- Bilinear establishes the coordinate frame
- Triangles refine local accuracy
- Distortion vectors bridge the gap

---

## 5. Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    ZONE CORNER CALIBRATION                      │
│                    (4 corners placed)                           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              BILINEAR PROJECTION SETUP                          │
│  • Sort corners CCW                                             │
│  • Store 2D/3D corner positions                                 │
│  • hasBilinearCorners = true                                    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│         PROJECT ALL TRIANGLE VERTICES                           │
│                                                                  │
│  For each triangle vertex:                                      │
│    ┌────────────────────────────────────────────┐              │
│    │ 1. Get 2D map position                     │              │
│    │ 2. inverseBilinear() → UV coordinates       │              │
│    │ 3. bilinearInterpolate() → AR position    │              │
│    │ 4. Apply consensusDistortionVector (if any)│              │
│    │ 5. Ground to floor                        │              │
│    │ 6. Spawn Ghost Marker                      │              │
│    └────────────────────────────────────────────┘              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              USER CALIBRATES GHOSTS                              │
│                                                                  │
│  For each adjusted ghost:                                       │
│    ┌────────────────────────────────────────────┐              │
│    │ 1. actualPosition = user placement          │              │
│    │ 2. idealPosition = bilinear projection      │              │
│    │ 3. distortionVector = actual - ideal        │              │
│    │ 4. Blend with historical data                │              │
│    │ 5. Update consensusDistortionVector         │              │
│    └────────────────────────────────────────────┘              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│         NEXT SESSION: REFINED PROJECTION                        │
│                                                                  │
│  Ghost positions = bilinear + consensusDistortionVector        │
│  → More accurate initial positions                              │
│  → Smaller user adjustments needed                              │
│  → System converges toward reality                              │
└─────────────────────────────────────────────────────────────────┘
```

---

## 6. Key Code Locations

| Component | File | Function/Method | Purpose |
|-----------|------|----------------|---------|
| **Bilinear Setup** | `ARCalibrationCoordinator.swift` | After 4th corner placement | Sort corners, populate arrays |
| **Ghost Planting** | `ARCalibrationCoordinator.swift` | `plantGhostsForAllTriangleVerticesBilinear()` | Project all triangle vertices |
| **Bilinear Projection** | `ARCalibrationCoordinator.swift` | `projectPointViaBilinear()` | 2D map → 3D AR via bilinear |
| **Inverse Bilinear** | `BilinearInterpolation.swift` | `inverseBilinear()` | 2D point → UV coordinates |
| **Forward Bilinear** | `BilinearInterpolation.swift` | `bilinearInterpolate()` | UV → 3D AR position |
| **Distortion Storage** | `MapPointStore.swift` | `consensusDistortionVector` | Per-MapPoint distortion vector |
| **Distortion Application** | `ARCalibrationCoordinator.swift` | Lines 1657-1666 | Apply correction to ghost position |
| **Triangle Structure** | `TrianglePatch.swift` | `TrianglePatch` struct | Triangle vertex IDs |
| **Barycentric Interpolation** | `TrianglePatchStore.swift` | Various methods | Interpolation within triangles |

---

## 7. Important Distinctions

### 7.1 Bilinear vs. Barycentric

| Aspect | Bilinear (Corner-Pin) | Barycentric (Triangular) |
|--------|----------------------|---------------------------|
| **Control Points** | 4 corners (quad) | 3 vertices (triangle) |
| **Scope** | Global (entire zone) | Local (single triangle) |
| **Use Case** | Initial projection of all vertices | Interpolation within triangles |
| **Distortion Handling** | Non-uniform across zone | Uniform within triangle |
| **Extrapolation** | Yes (UV outside [0,1]) | Yes (weights outside [0,1]) |

### 7.2 Distortion Vector Storage

**What is stored:**
- `consensusDistortionVector: simd_float3?` per MapPoint
- Represents: `actualPosition - bilinearProjectedPosition`
- Blended across sessions using weighted average

**What is NOT stored:**
- Absolute positions (session-dependent)
- Per-triangle distortion (uses global bilinear + local correction)
- Rigid body transforms (replaced by bilinear)

### 7.3 Triangle Vertices vs. Feature Points

**Triangle Vertices:**
- Directly calibrated via ghost adjustment
- Stored in `MapPoint` with `.triangleEdge` role
- Projected via bilinear + distortion correction

**Feature Points:**
- Interior to triangles, not directly calibrated
- Derived via barycentric interpolation from triangle vertices
- Accuracy depends on vertex calibration quality

---

## 8. Advantages of This Architecture

### 8.1 Global Consistency
- Bilinear provides unified coordinate frame
- All points use same projection method
- Consistent across entire zone

### 8.2 Local Refinement
- Triangular patches enable fine-grained corrections
- Local distortions don't affect distant regions
- Smooth transitions between patches

### 8.3 Session Independence
- Distortion vectors are session-invariant
- Works with different corner positions each session
- Accumulates accuracy over time

### 8.4 Scalability
- Works for zones of any size
- Handles non-uniform distortion
- Can extrapolate beyond defined corners

---

## 9. Limitations and Considerations

### 9.1 Quad Validity
- Corners must form non-self-intersecting quadrilateral
- Highly skewed quads may produce distortion
- System validates quad geometry before use

### 9.2 Corner Drift
- Corner positions may vary between sessions
- Bilinear adapts automatically
- Distortion vectors compensate for drift

### 9.3 Triangle Coverage
- Points outside all triangles use extrapolation
- Accuracy degrades with distance from triangles
- More triangles = better coverage

### 9.4 Distortion Accumulation
- Distortion vectors accumulate over sessions
- Weighted averaging prevents outliers
- System converges toward accurate positions

---

## 10. Future Enhancements

### 10.1 Multi-Zone Support
- Extend bilinear to multiple zones
- Handle zone boundaries and overlaps
- Shared vertices between zones

### 10.2 Dynamic Corner Adjustment
- Allow corner re-calibration mid-session
- Re-project uncalibrated vertices
- Update distortion vectors accordingly

### 10.3 Confidence Weighting
- Weight distortion vectors by calibration confidence
- Higher confidence = more influence on consensus
- Visual feedback for calibration quality

---

## 11. Related Documentation

- **Zone Corner Workflow:** `ZoneCornerWorkflow.md` - Detailed workflow and coordinate systems
- **Triangular Distortion Grid:** `TapResolver_Triangular_Distortion_Grid_Architecture.md` - Triangle mesh architecture
- **Calibration Mesh Spec:** `CalibrationMesh-ArchitecturalSpec.md` - Future architecture vision
- **Bilinear Math:** `BilinearInterpolation.swift` - Implementation details

---

## 12. Summary

The corner-pin bilinear transformation and triangular patch distortion mesh work together as a **two-layer calibration system**:

1. **Bilinear (Global):** Establishes initial 2D→3D projection using four zone corners
2. **Triangular Patches (Local):** Provide fine-grained distortion correction within regions
3. **Distortion Vectors:** Bridge the gap, storing corrections relative to bilinear projections
4. **Feedback Loop:** Each calibration session refines accuracy, converging toward physical reality

This architecture provides global consistency while enabling local refinement, making it robust to session variations and capable of handling non-uniform distortion across large spaces.
