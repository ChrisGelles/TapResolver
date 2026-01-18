# Corner Mesh and Hierarchical Transformation System

**Date:** January 17, 2026  
**Context:** Wavefront Zone Calibration - Phase 3 Implementation  
**Problem Solved:** How to spawn ghost markers for neighbor zone corners when bilinear projection is zone-local

---

## The Core Problem

When calibrating Zone A (e.g., kitchen-area), we establish a bilinear frame from its 4 corners. This bilinear projection works well for points **inside** Zone A's quadrilateral (triangle vertices, interior points).

However, Zone B's corners (e.g., office) may be **entirely outside** Zone A's frame. Bilinear extrapolation beyond the frame boundaries is mathematically unstable and produces inaccurate predictions.

**We need a different approach for predicting neighbor zone corner positions.**

---

## The Solution: Two Parallel Improving Meshes

TapResolver uses two complementary mesh systems that operate at different scales:

| Mesh | Points | Transform Type | Scope | Refinement Method |
|------|--------|----------------|-------|-------------------|
| **Corner Mesh** | Zone corner points | Similarity Transform | Global (entire map) | Each confirmed corner adds correspondence + distortion |
| **Triangle Mesh** | Triangle vertices | Bilinear + Barycentric | Local (within zone) | Each confirmed vertex adds distortion within zone frame |

The Corner Mesh is the **coarse scaffold** — it gets predictions into the ballpark.  
The Triangle Mesh is the **fine detail** — it handles local distortions within each zone's bilinear frame.

---

## Hierarchical Transformation Model

### Level 1: Global Map-to-Session Transform (Corner Mesh)

**Scope:** All zones share the same map coordinate system.

**Transform Type:** Similarity Transform (4 degrees of freedom)
- Rotation (1 DOF) — map orientation vs. phone orientation
- Uniform Scale (1 DOF) — accounts for metersPerPixel calibration error
- Translation (2 DOF) — map origin vs. AR session origin

**Data Source:** All confirmed zone corners across all planted zones
- Each corner has: map position (2D pixels) + AR position (3D session coords)
- Minimum 2 corners required; improves with each additional corner

**Purpose:** 
- Predict positions for corners of zones not yet calibrated
- Provide initial estimates before zone-local refinement

**Refinement:**
- Each time a corner is confirmed, recompute the similarity transform
- More corners → more accurate global alignment
- Corner distortion vectors (predicted vs. actual) accumulate for future blending

---

### Level 2: Zone Bilinear Frame (Local)

**Scope:** Points within a single zone's quadrilateral boundary.

**Transform Type:** Bilinear Interpolation (corner-pinning)
- 4 corners define the projection frame
- Interior points use bilinear interpolation (u,v parameters in [0,1])
- Exterior points use bilinear extrapolation (less reliable)

**Data Source:** The 4 confirmed corners of a specific zone
- Requires all 4 corners to be established

**Purpose:**
- Project triangle vertices within the zone
- Handle local distortions that the global transform can't capture

**Refinement:**
- Partner/overlapping zones may share corners
- Shared corners can be refined when the partner zone is calibrated
- Ghost markers appear at predicted positions; user adjustments improve accuracy

---

### Level 3: Triangle Barycentric (Hyperlocal)

**Scope:** Points within a single triangular cell.

**Transform Type:** Barycentric Interpolation
- 3 vertices define the triangle
- Any interior point expressed as weighted combination of vertices

**Data Source:** 3 confirmed triangle vertices

**Purpose:**
- Most precise positioning for survey markers and interior points
- Handles micro-distortions within individual triangles

---

## Coordinate Systems Reference

| System | Dimensions | Origin | Persistence |
|--------|------------|--------|-------------|
| **Map Pixels** | 2D | Top-left of floor plan image | Permanent (in image) |
| **Map Meters** | 2D | Center of map | Permanent (computed) |
| **Canonical/Baked** | 3D | Center of map (Y=0 ground plane) | Persistent across sessions |
| **AR Session** | 3D | Phone position at session start | Dies with session |

**Key Insight:** The Corner Mesh similarity transform bridges **Map Pixels** → **AR Session** directly, bypassing Canonical space for ghost placement. Canonical positions are still baked after confirmation for cross-session persistence.

---

## Similarity Transform: Mathematical Foundation

### What It Computes

Given N corner correspondences: `{(map₁, ar₁), (map₂, ar₂), ..., (mapₙ, arₙ)}`

Find the best-fit transform: `ar = s * R * map + t`

Where:
- `s` = uniform scale factor
- `R` = 2D rotation matrix (around Y axis, since map is XZ plane)
- `t` = translation vector

### Why Similarity (not Rigid, not Affine)

| Transform | DOF | Preserves | Use Case |
|-----------|-----|-----------|----------|
| Rigid | 3 | Distances, angles | Only if metersPerPixel is perfect |
| **Similarity** | 4 | Angles, ratios | Handles rotation + small scale error |
| Affine | 6 | Parallel lines | Too flexible, can shear the map |

**Similarity is the sweet spot** — it respects the map's geometry while accounting for real-world factors (user rotation, scale calibration drift).

### Least Squares Fitting

With N ≥ 2 correspondences, compute the transform that minimizes:

```
Σᵢ ||arᵢ - (s * R * mapᵢ + t)||²
```

Standard closed-form solution exists (Procrustes analysis / Horn's method).

---

## Corner Distortion Vectors

### Concept

When a corner ghost is spawned at a **predicted** position and the user **adjusts** it:

```
distortion_vector = actual_position - predicted_position
```

This captures the local error at that corner — the difference between what the global transform predicted and where the point actually belongs.

### Storage

```swift
struct CornerDistortionRecord {
    let mapPointID: UUID
    let predictedPosition: simd_float3
    let actualPosition: simd_float3
    let distortionVector: simd_float3  // actual - predicted
    let sessionID: UUID
    let timestamp: Date
}
```

### Usage

When predicting a new corner position:
1. Apply similarity transform → base prediction
2. Find nearby corners with distortion records
3. Blend distortion vectors (inverse distance weighting)
4. Adjust prediction by blended distortion

This creates a **self-improving prediction system** — each calibration session contributes corrections that improve future predictions.

---

## Wavefront Zone Calibration Flow

### Phase 1: Entry Zone Calibration

1. User selects entry zone (e.g., kitchen-area)
2. Guided placement of 4 corner markers
3. Each corner: map position (known) + AR position (placed by user)
4. After 4 corners: zone is "planted"
   - Bilinear frame established for this zone
   - Triangle ghosts spawned via bilinear projection
   - Corner Mesh initialized with 4 correspondences

### Phase 2: Neighbor Zone Trigger

1. User confirms ghosts in entry zone's triangle mesh
2. Some ghosts have **diamond cube indicators** (neighbor zone corners)
3. When a diamond ghost is confirmed:
   - It becomes the 5th corner in the Corner Mesh
   - Similarity transform is (re)computed with 5 points
   - "Plot Next Zone" button becomes available

### Phase 3: Neighbor Zone Corner Spawning

1. User taps "Plot Next Zone"
2. System identifies the neighbor zone (e.g., office)
3. Trigger corner is already confirmed (from Phase 2)
4. For remaining 3 corners:
   - Compute predicted AR position via similarity transform
   - Optionally blend nearby corner distortions
   - Spawn ghost marker at predicted position
5. Enter ghost crawl mode for corner confirmation

### Phase 4: Neighbor Zone Completion

1. User confirms/adjusts each corner ghost
2. Each confirmation:
   - Records corner distortion vector
   - Updates Corner Mesh (recompute similarity transform)
   - Tracks progress (2/4, 3/4, 4/4)
3. When all 4 corners confirmed:
   - Zone is "planted"
   - Bilinear frame established for this zone
   - Triangle ghosts spawned via bilinear projection
   - Wavefront continues to next neighbor

---

## Data Structures Required

### Corner Correspondence Collection

```swift
/// Stores all confirmed zone corners for global transform computation
struct CornerCorrespondence {
    let mapPointID: UUID
    let mapPosition: CGPoint       // 2D map pixels
    let arPosition: simd_float3    // 3D AR session coords
    let zoneID: String             // Which zone this corner belongs to
    let sessionID: UUID
    let timestamp: Date
}

// In ARCalibrationCoordinator:
private var confirmedCornerCorrespondences: [CornerCorrespondence] = []
```

### Similarity Transform Cache

```swift
/// Cached global map-to-session transform
struct MapToSessionTransform {
    let scale: Float
    let rotation: Float           // Radians around Y axis
    let translation: simd_float2  // XZ offset
    let residualError: Float      // RMS error of fit
    let cornerCount: Int          // How many corners contributed
}

// In ARCalibrationCoordinator:
private var cachedMapToSessionTransform: MapToSessionTransform?
```

### Corner Distortion Storage

```swift
/// Records prediction error for improving future predictions
struct CornerDistortion {
    let mapPointID: UUID
    let distortionVector: simd_float3
    let magnitude: Float
    let sessionID: UUID
}

// In ARCalibrationCoordinator:
private var cornerDistortions: [UUID: CornerDistortion] = [:]
```

---

## Implementation Checklist

### Required Functions

- [ ] `computeSimilarityTransform(from correspondences: [CornerCorrespondence]) -> MapToSessionTransform?`
- [ ] `projectMapPointViaCornerMesh(_ mapPosition: CGPoint) -> simd_float3?`
- [ ] `recordCornerDistortion(mapPointID: UUID, predicted: simd_float3, actual: simd_float3)`
- [ ] `blendNearbyCornerDistortions(at mapPosition: CGPoint) -> simd_float3`

### Integration Points

- [ ] After each zone corner confirmation → add to `confirmedCornerCorrespondences`
- [ ] After each corner confirmation → recompute similarity transform
- [ ] In `startNextZoneCalibration()` → use `projectMapPointViaCornerMesh()` instead of bilinear
- [ ] After ghost corner adjustment → record distortion vector

---

## Relationship to Existing Systems

### What Changes

| Component | Current Behavior | New Behavior |
|-----------|------------------|--------------|
| `projectBakedToSession()` | Uses `cachedCanonicalToSessionTransform` | Unchanged (still used for triangle vertices with baked data) |
| `predictNeighborCornerPositions()` | Uses planted zone's bilinear | Should use Corner Mesh similarity transform |
| `startNextZoneCalibration()` | Tries canonical projection (fails) | Should use Corner Mesh similarity transform |

### What Stays the Same

- Bilinear projection for triangle vertices within a zone
- Barycentric interpolation for survey points
- Canonical/baked position storage for cross-session persistence
- Position history accumulation
- Ghost adjustment and distortion recording

---

## Key Architectural Principle

**Corner points define reference frames; they are not projected through them.**

- Zone corners **establish** the bilinear frame — they don't get projected through it
- The Corner Mesh operates at a higher level, relating corners to each other globally
- Once a zone's corners are confirmed, the bilinear frame handles everything inside

**Analogy:** 
- Corner Mesh = surveyor's control network (large-scale reference points)
- Zone Bilinear = local coordinate grid within a building
- Triangle Barycentric = room-level positioning within the grid

---

## Session Continuity Notes

If this Claude session terminates unexpectedly:

1. **Current state:** Phase 3 of Wavefront implementation
2. **Problem identified:** `startNextZoneCalibration()` fails because `cachedCanonicalToSessionTransform` is nil
3. **Solution agreed:** Implement Corner Mesh with similarity transform
4. **Next step:** Write Cursor instructions for similarity transform computation and integration

**Key files to review:**
- `ARCalibrationCoordinator.swift` — main coordinator
- `WAVEFRONT_ZONE_CALIBRATION_SYSTEM.md` — wavefront design doc
- This document — Corner Mesh architecture

**Do not:**
- Use bilinear extrapolation for points outside the current zone
- Assume `cachedCanonicalToSessionTransform` exists in zone corner mode
- Skip the similarity transform in favor of simple offset calculation (rotation matters)
