# Wavefront Zone Calibration System

**Date:** January 14, 2026  
**Status:** Design Specification  
**Authors:** Chris Gelles, Claude (Anthropic)

---

## Executive Summary

TapResolver uses a multi-zone corner-pin architecture to map 2D floor plans into 3D AR space. Each Zone is a quadrilateral defined by four Corner Points that control a bilinear projection operation. Triangular patches within each zone form a distortion mesh for fine-grained spatial alignment.

The **Wavefront Zone Calibration System** enables progressive, cascading calibration across multiple overlapping zones. When one zone is calibrated, the system predicts the corner positions of neighboring zones, allowing the user to confirm and calibrate outward in any direction—like a wavefront propagating across the map.

---

## Problem Statement

### The Single Corner-Pin Limitation

Bilinear interpolation (corner-pin) provides stable results near the center of the control quadrilateral but becomes increasingly unstable for points outside or far from the frame. A single corner-pin operation cannot reliably cover a large map.

### The Solution: Tiled Corner-Pins

Divide the map into multiple overlapping zones, each providing local stability to its contained triangles. Where zones overlap, their influences blend smoothly, creating seamless transitions across the entire map.

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│   ┌───────────Zone A────────┐                       │
│   │ ◆                     ◆ │                       │
│   │      △ △ △ △ △         │                       │
│   │     △ △ △ △ △ △        │                       │
│   │    △ △ △ ┌──Zone B─────┼───────────┐           │
│   │   △ △ △ △│█ █ █ █ █    │         ◆ │           │
│   │ ◆       ◆│█ █ █ █ █ █  │           │           │
│   └──────────┼─────────────┘ △ △ △ △   │           │
│              │   △ △ △ △ △ △ △ △ △ △   │           │
│              │ ◆                     ◆ │           │
│              └─────────────────────────┘           │
│                                                     │
│   ◆ = Zone Corner Point (Diamond-Cube Marker)      │
│   △ = Triangle owned by one zone                   │
│   █ = Triangle in overlap (shared by A and B)      │
└─────────────────────────────────────────────────────┘
```

---

## Core Concepts

### Wavefront Propagation Model

Calibration propagates outward from a seed zone:

1. **Seed Zone Planted** → User manually places 4 corner markers
2. **Interior Fill** → System places Ghost Markers for member triangle vertices
3. **Neighbor Prediction** → System predicts neighboring zone corners
4. **Neighbor Confirmation** → User taps to confirm/adjust neighbor corners
5. **Neighbor Activation** → Confirmed zone becomes planted, repeat from step 2

```
         Zone A planted
              │
              ▼
    ┌─────────────────────┐
    │  A's interior       │
    │  triangles: Ghosts  │
    │  placed ✓           │
    └─────────────────────┘
              │
              ▼
    ┌─────────────────────┐
    │  A∩B overlap        │
    │  triangles: Ghosts  │
    │  placed ✓           │
    │                     │
    │  B's corners:       │
    │  Diamond markers    │◄── Predicted, awaiting tap
    │  PREDICTED          │
    └─────────────────────┘
              │
              ▼
         User taps to confirm
         B's corner markers
              │
              ▼
    ┌─────────────────────┐
    │  B's interior       │
    │  triangles: Ghosts  │
    │  placed ✓           │
    │                     │
    │  C's corners:       │
    │  Diamond markers    │
    │  PREDICTED          │
    └─────────────────────┘
              │
              ▼
           ...continues...
```

### Position History Accumulation

Every marker confirmation adds to the MapPoint's position history. Over time:

- Initial calibrations are exploratory
- Later calibrations benefit from accumulated history
- Predictions become increasingly accurate
- The system becomes self-correcting

This applies to both triangle vertices AND zone corners—corner relationships improve with each session.

---

## Zone Corner Marker: Diamond-Cube Design

### Geometry

A cube rotated 45° on TWO axes, creating a three-dimensional diamond shape visible from any angle.

```swift
// SceneKit implementation
let cube = SCNBox(width: 0.10, height: 0.10, length: 0.10, chamferRadius: 0)

// Rotate on TWO axes for diamond orientation
cubeNode.eulerAngles.x = .pi / 4  // 45° pitch
cubeNode.eulerAngles.z = .pi / 4  // 45° roll
```

### Face Colors

Each of the 6 cube faces has a distinct color, using complementary pairs on opposite faces:

| Face | Color | Opposite Face | Opposite Color |
|------|-------|---------------|----------------|
| +X | Red | -X | Cyan |
| +Y | Green | -Y | Magenta |
| +Z | Blue | -Z | Yellow |

```swift
// SCNBox face order: +X, -X, +Y, -Y, +Z, -Z
cube.materials = [
    makeMaterial(.red),      // +X
    makeMaterial(.cyan),     // -X
    makeMaterial(.green),    // +Y
    makeMaterial(.magenta),  // -Y
    makeMaterial(.blue),     // +Z
    makeMaterial(.yellow)    // -Z
]
```

### State Transitions

| State | Appearance | Interaction |
|-------|------------|-------------|
| **Predicted** | Multi-color faces (R/G/B/C/M/Y) | Tap to enter confirmation |
| **Planted/Confirmed** | All faces turn **solid blue** | Standard AR marker behavior |

### Size

Slightly larger than sphere markers for enhanced visibility:
- Sphere markers: ~0.06-0.08m
- Diamond-cube: 0.10m

---

## Zone Neighbor Relationships

### Computation Method

Two zones are neighbors if their quadrilateral boundaries overlap. This is a pure geometry check—no triangle involvement.

```swift
func zonesOverlap(_ zoneA: Zone, _ zoneB: Zone) -> Bool {
    let cornersA = zoneA.cornerPositions  // [CGPoint]
    let cornersB = zoneB.cornerPositions  // [CGPoint]
    return quadrilateralsIntersect(cornersA, cornersB)
}
```

### Computation Triggers

- Single zone created → compute neighbors for that zone
- Batch zone import → compute all neighbors once at end of import
- Zone corners modified → recompute that zone's neighbors

### Storage

```swift
public struct Zone {
    // Existing
    public var cornerMapPointIDs: [String]
    public var memberTriangleIDs: [String]
    
    // New
    public var neighborZoneIDs: [String]  // Computed from geometry overlap
}
```

---

## Calibration Flow (Detailed)

### Phase 0: Pre-AR Preparation

```
Zones exist with:
  - cornerMapPointIDs (4 corners each)
  - memberTriangleIDs (triangles within)
  - neighborZoneIDs (pre-computed overlaps)
      │
      ▼
User selects Zone to calibrate
      │
      ▼
Enter AR View → New AR Session begins
```

### Phase 1: Seed Zone Corner Placement

```
User in AR View
      │
      ▼
Place Zone A's 4 Corner Points as AR Markers
      │
      ├── Each corner uses DIAMOND-CUBE head (multi-color)
      │
      ├── User confirms each corner position
      │
      ├── On confirmation:
      │     • Diamond turns BLUE
      │     • Position recorded to corner MapPoint's history
      │
      └── All 4 corners confirmed
      │
      ▼
Zone A is "planted" (session-scoped state)
```

### Phase 2: Member Triangle Ghost Placement

```
Zone A planted
      │
      ▼
For each MapPoint in Zone A's member triangles:
      │
      ├── Compute AR position via Zone A's bilinear projection
      │     (uses position history consensus if available)
      │
      └── Place Ghost Marker (sphere head) at computed position
      │
      ▼
Zone A's triangle mesh represented in AR space
```

### Phase 3: Neighbor Corner Prediction

```
Zone A planted
      │
      ▼
Look up Zone A's neighborZoneIDs
      │
      ▼
For each neighbor Zone B (not already planted):
      │
      └── For each of Zone B's 4 Corner MapPoints:
            │
            ├── Compute predicted AR position via Zone A's bilinear projection
            │     (enhanced by corner position history if available)
            │
            └── Place DIAMOND-CUBE MARKER (multi-color)
                  at predicted position
      │
      ▼
User sees colorful diamond markers for neighbor zone corners
```

### Phase 4: Neighbor Corner Confirmation (Tap-Activated)

```
User sees Diamond Markers for Zone B's corners
      │
      ▼
User TAPS a Diamond Marker
      │
      ├── (Tap required—NOT proximity-triggered like Ghost Markers)
      │
      └── This differentiates corner markers and confirms
          user intent to calibrate another zone
      │
      ▼
Enter confirm/adjust/reposition flow:
      │
      ├── Confirm: Position recorded to history, diamond turns BLUE
      │
      ├── Adjust: User repositions marker, then confirms
      │
      └── Reposition: Reset and try again
      │
      ▼
Repeat for all 4 of Zone B's corners
      │
      ▼
All 4 confirmed → Zone B is "planted"
      │
      ▼
Return to Phase 2 (Zone B's interior triangles)
      │
      ▼
Return to Phase 3 (Zone B's neighbors, excluding planted zones)
      │
      ▼
Wavefront continues...
```

---

## Marker Type Summary

| Marker | Head Shape | Trigger | Color States | Purpose |
|--------|------------|---------|--------------|---------|
| **Ghost Marker** | Sphere | Proximity | Gray → confirmed | Triangle vertex prediction |
| **Survey Marker** | Sphere | Proximity | Survey color | BLE survey points |
| **AR Marker** | Sphere | Proximity | Various → Blue | Confirmed positions |
| **Zone Corner** | Diamond-Cube | **Tap** | Multi-color → Blue | Zone corner calibration |

---

## Flexibility Principles

| Aspect | Behavior |
|--------|----------|
| **Seed Zone** | User chooses any zone to start |
| **Direction** | Calibration can proceed in any direction through neighbor graph |
| **Backtracking** | User can return to earlier areas, calibrate in any order |
| **Partial Calibration** | Valid state—not all zones need planting in one session |
| **Session Independence** | Each session builds on accumulated position history |
| **History Value** | More sessions → better predictions → faster future calibration |

---

## Blend Behavior for Overlap Triangles

For triangles belonging to multiple zones, Ghost positions blend based on normalized zone coordinates:

### Before Neighboring Zone Planted

- 100% influence from the planted zone
- Neighbor has no planted corners yet, so no contribution

### After Both Zones Planted

- Geometric blend based on triangle's position within each zone
- Triangle near Zone A's center → mostly A's projection
- Triangle near Zone B's center → mostly B's projection
- Triangle equidistant → 50/50 blend

### Blend Formula (Normalized Coordinates)

```
For triangle T in zones [A, B]:
  
  // Get edge distance within each zone (0 at edge, 0.5 at center)
  edgeDist_A = minDistanceToZoneEdge(T.centroid, zoneA)
  edgeDist_B = minDistanceToZoneEdge(T.centroid, zoneB)
  
  // Normalize to weights
  total = edgeDist_A + edgeDist_B
  weight_A = edgeDist_A / total
  weight_B = edgeDist_B / total
  
  // Blend positions
  ghost_position = weight_A * projectFromZoneA(T.centroid) 
                 + weight_B * projectFromZoneB(T.centroid)
```

---

## Data Model Changes

### Zone (Additions)

```swift
public struct Zone {
    // Existing
    public let id: String
    public var displayName: String
    public var cornerMapPointIDs: [String]  // 4 corners
    public var memberTriangleIDs: [String]
    public var groupID: String?
    
    // New
    public var neighborZoneIDs: [String]    // Zones with overlapping boundaries
}
```

### Session-Scoped State (Not Persisted)

```swift
// Tracked during AR session, reset on session end
var plantedZoneIDs: Set<String> = []
```

### MapPoint (No Changes)

Zone corner MapPoints already exist and support position history. Corner confirmations naturally record to history through the existing flow.

---

## Implementation Phases

| Phase | Task | Deliverable |
|-------|------|-------------|
| **A1** | Diamond-cube geometry | `ZoneCornerMarkerNode` in SceneKit |
| **A2** | Test scene integration | Diamond marker in AR test scene |
| **B1** | Zone overlap computation | `quadrilateralsIntersect()` function |
| **B2** | Neighbor persistence | `neighborZoneIDs` computed on create/import |
| **C1** | Neighbor corner prediction | Bilinear projection for neighbor corners |
| **C2** | Diamond marker placement | Predicted corners appear as diamond markers |
| **D1** | Tap-to-confirm interaction | Diamond markers respond to tap, not proximity |
| **D2** | Color state transition | Multi-color → blue on confirmation |
| **E1** | Wavefront propagation | Auto-spawn next neighbor predictions |
| **E2** | Session state tracking | Track planted zones within session |

---

## Visual Effects Compositing Analogy

This architecture mirrors professional VFX compositing workflows:

| VFX Concept | TapResolver Equivalent |
|-------------|------------------------|
| Corner-pinned footage | Zone with bilinear projection |
| Distortion mesh / spline warp | Triangle patch grid |
| Soft edge blending | Overlap zone weight blending |
| Multi-pass compositing | Multiple overlapping zones |
| Match-move tracking | Position history accumulation |

Just as a compositor applies multiple corner-pinned elements with soft-edge blending to create a seamless composite, TapResolver applies multiple zone projections with geometric blending to create a seamless AR spatial map.

---

## Future Considerations

### Automatic Drift Detection

Zone corners could serve as "anchor points" for detecting session drift. If a corner's computed position diverges significantly from its historical consensus, the system could flag potential drift.

### Zone Calibration Quality Metrics

Track calibration quality per zone based on:
- Corner position variance across sessions
- Triangle vertex confirmation accuracy
- Blend region consistency

### Suggested Calibration Order

System could suggest optimal calibration starting points based on:
- Zones with most position history (most reliable predictions)
- Zones with most neighbors (maximum wavefront reach)
- User's current physical location

---

## Glossary

| Term | Definition |
|------|------------|
| **Zone** | A quadrilateral region defined by 4 corner MapPoints |
| **Zone Corner** | One of the 4 MapPoints defining a zone's boundary |
| **Neighbor Zone** | A zone whose boundary overlaps with another zone |
| **Planted Zone** | A zone whose 4 corners have been confirmed in the current AR session |
| **Diamond-Cube Marker** | Visual marker for zone corners—cube rotated 45° on two axes |
| **Wavefront** | The progressive propagation of calibration from planted zones to neighbors |
| **Position History** | Accumulated AR position records for a MapPoint across sessions |
| **Bilinear Projection** | Corner-pin transformation from 2D map to 3D AR coordinates |
| **Ghost Marker** | Predicted AR position for a MapPoint, awaiting confirmation |
| **Overlap Triangle** | A triangle belonging to multiple zones |

---

## Document History

| Date | Author | Changes |
|------|--------|---------|
| 2026-01-14 | Chris Gelles, Claude | Initial specification |
