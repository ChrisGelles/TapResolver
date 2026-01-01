# Calibration Mesh System — Architectural Specification

**Version:** 1.0 Draft  
**Date:** December 28, 2025  
**Status:** For Review

---

## 1. Overview

The Calibration Mesh system replaces the current Zone Corner + Rigid Body Transform approach with a unified corner-pin (bilinear interpolation) projection method. This creates a self-consistent spatial calibration framework where zone corners establish the initial AR-to-map correspondence, and subsequent user calibrations refine accuracy with confidence weighting.

### 1.1 Key Concepts

- **Calibration Mesh:** The network of MapPoints (triangle vertices) within a zone, with their spatial relationships. These are the calibratable points.
- **Zone Corners:** The 4 designated MapPoints that define the zone boundary. User plants AR markers at these first.
- **Bilinear Interpolation:** The projection method that transforms 2D map coordinates into AR positions using the 4 zone corners as control points.
- **Barycentric Interpolation:** The method for deriving AR positions of Feature points (interior to triangles) from their containing triangle's calibrated vertices.

### 1.2 Design Principles

1. **Corners are scaffolding:** Once the mesh is projected, corners lose their special "corner-pin control" status and become equal mesh members.
2. **2D map is truth:** Adjustments refine AR projection only; map topology is immutable (for now).
3. **Independent adjustment:** Moving one point does not affect neighbors.
4. **Confidence weighting:** Calibrated positions have higher weight than unconfirmed projections.

---

## 2. System Lifecycle

### Phase 1: Zone Corner Establishment

**Trigger:** User selects "Zone Corner Calibration" mode  
**State:** `.placingVertices(index: 0..3)`

1. System identifies the 4 designated zone corner MapPoints
2. User plants AR markers at each corner in sequence
3. System records AR position for each corner
4. After 4th corner: automatic transition to Phase 2

**Validation:**
- The 4 corners must form a valid (non-self-intersecting) quadrilateral
- If corners cross (bowtie shape), warn user and abort run
- No position data retained on abort; user must restart

### Phase 2: Mesh Projection (The Handoff)

**Trigger:** 4th zone corner planted  
**State:** `.readyToFill`

1. System gathers all mesh vertices (MapPoints with edge/corner roles) within the zone
2. For each vertex, compute its UV coordinates within the 2D map quad
3. Apply bilinear interpolation to project AR position
4. Spawn Ghost Markers at projected positions
5. **Handoff complete:** Zone corners are now just mesh points

**Output:**
- All mesh vertices have Ghost Markers in AR scene
- Including the 4 original corners (now indistinguishable from other mesh points)

### Phase 3: Mesh Calibration

**Trigger:** User interaction with Ghost Markers  
**State:** `.readyToFill` (continues)

User walks the space and calibrates mesh vertices via:
- **Confirm Placement:** Accept ghost position as-is (confidence = 0.5 initially, upgrades with repeat confirmations)
- **Place Marker to Adjust:** Replace ghost with AR marker at crosshair position (confidence = 1.0)
- **Reposition Marker:** Free placement mode for large adjustments

**Behaviors:**
- Calibrated points: Ghost removed, AR marker placed, position recorded
- Uncalibrated points: Ghost remains at bilinear-projected position
- Original corner points: Can be adjusted like any other mesh point (drift correction)

### Phase 4: Feature Point Derivation

**Trigger:** Query for Feature point position (navigation, display)  
**Precondition:** Containing triangle has calibrated vertices

1. Identify the triangle containing the Feature point (2D map lookup)
2. Retrieve calibrated AR positions of the 3 triangle vertices
3. Compute barycentric coordinates of Feature point within triangle (2D)
4. Apply barycentric interpolation to derive AR position

**Note:** Feature points are never directly calibrated. Their accuracy depends on surrounding mesh vertex calibration.

---

## 3. Coordinate Systems

| System | Description | Usage |
|--------|-------------|-------|
| **Map Pixel** | 2D coordinates in floor plan image pixels | UI display, tap detection |
| **Map Meters** | 2D coordinates in real-world meters on map plane | Distance calculations, UV computation |
| **AR Session** | 3D coordinates in current ARKit session | Live rendering, marker placement |
| **Canonical/Baked** | 3D reference frame for persistent storage | Cross-session position history |

### 3.1 UV Computation

For bilinear interpolation, each mesh vertex needs UV coordinates within the zone quad:

```
Given:
  - Zone corners: A (bottom-left), B (bottom-right), C (top-right), D (top-left)
  - All in Map Meters coordinates
  - Point P to project

Compute:
  u = horizontal position [0,1] from left edge to right edge
  v = vertical position [0,1] from bottom edge to top edge

Method:
  Use inverse bilinear mapping (iterative or closed-form for quads)
```

### 3.2 Bilinear Projection

```
Given:
  - UV coordinates (u, v) for point P
  - AR positions of corners: AR_A, AR_B, AR_C, AR_D

Compute:
  AR_P = (1-u)(1-v) × AR_A 
       + u(1-v) × AR_B 
       + uv × AR_C 
       + (1-u)v × AR_D
```

### 3.3 Barycentric Derivation (Feature Points)

```
Given:
  - Triangle vertices V0, V1, V2 (calibrated AR positions)
  - Feature point F (2D map position)
  - Barycentric coordinates (w0, w1, w2) of F within triangle

Compute:
  AR_F = w0 × AR_V0 + w1 × AR_V1 + w2 × AR_V2
```

---

## 4. Data Model

### 4.1 Zone Definition

```swift
struct CalibrationZone {
    let id: UUID
    let name: String
    
    // The 4 corner MapPoint IDs, in order (CCW or CW, consistent)
    let cornerIDs: [UUID]  // exactly 4
    
    // All mesh vertex MapPoint IDs within this zone
    var meshVertexIDs: Set<UUID>
    
    // Calibration state
    var cornerARPositions: [UUID: simd_float3]  // populated during Phase 1
    var isProjected: Bool  // true after Phase 2 handoff
}
```

### 4.2 Mesh Vertex Calibration Record

```swift
struct MeshVertexCalibration {
    let mapPointID: UUID
    let zoneID: UUID
    
    // Position
    var arPosition: simd_float3
    var canonicalPosition: simd_float3?  // baked for persistence
    
    // Confidence
    var calibrationSource: CalibrationSource
    var confidenceWeight: Float  // 0.5 for unconfirmed, 1.0 for confirmed
    var confirmationCount: Int   // for progressive confidence building
    
    // Metadata
    var sessionID: UUID
    var timestamp: Date
}

enum CalibrationSource {
    case bilinearProjection  // initial ghost position, unconfirmed
    case userConfirmed       // user accepted ghost position
    case userAdjusted        // user placed at crosshair
}
```

### 4.3 Position History (Accumulated)

```swift
struct PositionHistoryEntry {
    let mapPointID: UUID
    let canonicalPosition: simd_float3
    let confidenceWeight: Float
    let sessionID: UUID
    let timestamp: Date
}

// Consensus position computed as weighted average across sessions
func computeConsensusPosition(for mapPointID: UUID) -> simd_float3? {
    let entries = positionHistory.filter { $0.mapPointID == mapPointID }
    guard !entries.isEmpty else { return nil }
    
    let totalWeight = entries.reduce(0) { $0 + $1.confidenceWeight }
    let weightedSum = entries.reduce(simd_float3.zero) { 
        $0 + $1.canonicalPosition * $1.confidenceWeight 
    }
    return weightedSum / totalWeight
}
```

---

## 5. State Machine

```
┌─────────────────────────────────────────────────────────────────┐
│                         ZONE CORNER MODE                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐    plant corner    ┌──────────────────────┐  │
│  │    .idle     │ ─────────────────► │ .placingVertices(0)  │  │
│  └──────────────┘                    └──────────────────────┘  │
│                                               │                 │
│                                         plant corner            │
│                                               ▼                 │
│                                      ┌──────────────────────┐  │
│                                      │ .placingVertices(1)  │  │
│                                      └──────────────────────┘  │
│                                               │                 │
│                                         plant corner            │
│                                               ▼                 │
│                                      ┌──────────────────────┐  │
│                                      │ .placingVertices(2)  │  │
│                                      └──────────────────────┘  │
│                                               │                 │
│                                         plant corner            │
│                                               ▼                 │
│                                      ┌──────────────────────┐  │
│                                      │ .placingVertices(3)  │  │
│                                      └──────────────────────┘  │
│                                               │                 │
│                                    4th corner planted           │
│                                     (HANDOFF MOMENT)            │
│                                               ▼                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                     .readyToFill                          │  │
│  │  ┌────────────────────────────────────────────────────┐  │  │
│  │  │ • Project all mesh vertices via bilinear           │  │  │
│  │  │ • Spawn Ghost Markers                              │  │  │
│  │  │ • User calibrates mesh (confirm/adjust ghosts)     │  │  │
│  │  │ • Corners demoted to regular mesh points           │  │  │
│  │  └────────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 6. Implementation Phases

### Phase A: Foundation (Current Sprint)

1. **Bilinear projection math**
   - UV computation from zone corners + point position
   - Bilinear interpolation function
   - Quad validity check (non-self-intersecting)

2. **Replace rigid body transform**
   - Swap current ghost projection to use bilinear
   - Remove rigid body transform computation
   - Update ghost placement in `.readyToFill` transition

3. **Corner demotion**
   - After handoff, corners become regular mesh points
   - Remove special-case handling for corner markers

### Phase B: Confidence System

1. **Calibration source tracking**
   - Tag each position with source (projected/confirmed/adjusted)
   - Store confidence weight

2. **Weighted position history**
   - Unconfirmed projections: weight = 0.5
   - Confirmed placements: weight = 1.0
   - Consensus computation uses weights

3. **Visual feedback**
   - Different ghost appearance for unconfirmed vs. partially-confirmed positions

### Phase C: Feature Point Derivation

1. **Triangle containment lookup**
   - Given Feature point, find containing triangle

2. **Barycentric computation**
   - Compute barycentric coordinates in 2D
   - Apply to calibrated AR vertex positions

3. **Feature point display**
   - Render derived Feature positions in AR scene

### Phase D: Multi-Zone Support (Future)

1. **Zone definition UI**
   - Swath Editor integration
   - Corner assignment per zone

2. **Shared boundaries**
   - Adjacent zones share edge/corner points
   - Single calibration applies to both zones

3. **Zone membership**
   - MapPoints tagged with zone membership
   - Queries filter by zone

---

## 7. Migration Strategy

### 7.1 Data Purge

Per user guidance: historical position data from previous calibration approaches will be purged rather than converted. The new system establishes a clean foundation.

**Purge scope:**
- All existing `canonicalPosition` values
- Session transform history
- Baked position records

**Retain:**
- MapPoint definitions (IDs, roles, 2D coordinates)
- Triangle mesh topology
- Zone corner designations

### 7.2 Rollback Path

Until the new system is validated:
- Keep old code paths behind feature flag
- Ability to revert to rigid body transform if issues arise

---

## 8. Open Questions

1. **Corner ordering convention:** CCW or CW? Must be consistent for UV computation.

2. **Non-rectangular zones:** Bilinear works best with roughly rectangular quads. Highly skewed quads may produce distortion. Accept this limitation or add warnings?

3. **Session transform:** The current system computes session-to-baked transforms. How does this interact with bilinear projection? (Likely: bilinear operates in AR session space; baking happens separately.)

4. **Drift detection:** When corners are re-calibrated (adjusted), should the system re-project uncalibrated mesh vertices? Or keep them at original positions?

---

## 9. Acceptance Criteria (Phase A)

- [ ] 4 zone corners can be planted in sequence
- [ ] Invalid quad (crossing) is detected and rejected
- [ ] After 4th corner, all mesh vertices get Ghost Markers via bilinear projection
- [ ] Ghost positions are visually correct (interior points interpolated smoothly)
- [ ] Ghosts can be confirmed/adjusted as before
- [ ] Original corner points can be adjusted post-handoff
- [ ] No rigid body transform code executed in Zone Corner flow

---

## Appendix A: Bilinear Math Reference

### A.1 Forward Bilinear (UV → Position)

```swift
func bilinearInterpolate(
    u: Float, v: Float,
    cornerA: simd_float3,  // (0, 0) - e.g., bottom-left
    cornerB: simd_float3,  // (1, 0) - e.g., bottom-right
    cornerC: simd_float3,  // (1, 1) - e.g., top-right
    cornerD: simd_float3   // (0, 1) - e.g., top-left
) -> simd_float3 {
    let p00 = cornerA
    let p10 = cornerB
    let p11 = cornerC
    let p01 = cornerD
    
    return (1 - u) * (1 - v) * p00
         + u * (1 - v) * p10
         + u * v * p11
         + (1 - u) * v * p01
}
```

### A.2 Inverse Bilinear (Position → UV)

For 2D map coordinates, finding UV of a point within a quad:

```swift
func inverseBilinear(
    point: CGPoint,
    cornerA: CGPoint,  // (0, 0)
    cornerB: CGPoint,  // (1, 0)
    cornerC: CGPoint,  // (1, 1)
    cornerD: CGPoint   // (0, 1)
) -> (u: Float, v: Float)? {
    // Iterative Newton-Raphson or closed-form solution
    // Returns nil if point is outside quad
    // ...
}
```

---

## Appendix B: Glossary

| Term | Definition |
|------|------------|
| **Calibration Mesh** | Network of MapPoints (triangle vertices) used for spatial calibration |
| **Zone Corner** | One of 4 designated MapPoints defining a zone boundary |
| **Bilinear Interpolation** | Projection method using 4 corners to map 2D→AR positions |
| **Barycentric Interpolation** | Interpolation within a triangle using 3 vertices |
| **Feature Point** | MapPoint interior to a triangle, not directly calibrated |
| **Ghost Marker** | Semi-transparent AR marker at projected position, awaiting user calibration |
| **Handoff** | Transition from corner placement to mesh calibration mode |
| **Confidence Weight** | Numerical weight (0.5–1.0) indicating calibration reliability |
