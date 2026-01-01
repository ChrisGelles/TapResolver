# Calibration Mesh Implementation Roadmap

**Goal:** Replace rigid body transform with bilinear interpolation, creating a calibrated mesh of MapPoints corresponding to AR Markers, enabling Survey Marker flooding for BLE data collection.

---

## Current State (Working)

| Component | Status | Notes |
|-----------|--------|-------|
| Zone Corner placement | ✅ Working | 4 corners planted in sequence |
| State transition to `.readyToFill` | ✅ Working | Automatic after 4th corner |
| Ghost marker projection | ✅ Working | Currently uses rigid body transform |
| Ghost confirmation (Confirm Placement) | ✅ Working | Fixed Dec 27 - state check expanded |
| Ghost adjustment (Place Marker to Adjust) | ✅ Working | Fixed Dec 27 - deferred ghost removal |
| Survey marker placement | ✅ Working | Separate pipeline, ready to use |

---

## Milestone 1: Bilinear Projection Math
**Effort:** Small (1-2 hours)  
**Risk:** Low

### Deliverables
1. `BilinearInterpolation.swift` utility with:
   - `bilinearInterpolate(u:v:corners:) -> simd_float3` — forward projection
   - `inverseBilinear(point:corners:) -> (u: Float, v: Float)?` — UV from 2D position
   - `isValidQuad(corners:) -> Bool` — non-self-intersecting check

2. Unit tests for:
   - Corner positions return correct UV (0,0), (1,0), (1,1), (0,1)
   - Center point returns UV (0.5, 0.5)
   - Self-intersecting quad returns invalid

### Acceptance Criteria
- [ ] Functions compile and pass unit tests
- [ ] No integration yet — isolated utility code

---

## Milestone 2: Wire Bilinear into Ghost Projection
**Effort:** Medium (2-3 hours)  
**Risk:** Medium (replaces existing logic)  
**Depends on:** Milestone 1

### Current Flow (to replace)
```
4th corner planted
  → computeRigidBodyTransform(from: corners)
  → for each mesh vertex:
      → apply transform to get AR position
      → spawn ghost at position
```

### New Flow
```
4th corner planted
  → validate quad (corners don't cross)
  → for each mesh vertex:
      → compute UV from 2D map position
      → bilinearInterpolate(uv, cornerARPositions)
      → spawn ghost at interpolated position
```

### Deliverables
1. Modify `ARCalibrationCoordinator` (or wherever ghost projection lives):
   - Remove rigid body transform computation
   - Add bilinear projection call
   - Add quad validity check with user warning on failure

2. Update zone corner data structure:
   - Store corner AR positions in consistent order (define convention: CCW from bottom-left)
   - Ensure corner MapPoint 2D positions are also accessible for UV computation

### Acceptance Criteria
- [ ] Plant 4 zone corners → ghosts appear at bilinear-interpolated positions
- [ ] Ghost positions are visually correct (smooth interpolation across zone)
- [ ] Crossing corners (invalid quad) shows warning, aborts run
- [ ] No rigid body transform code executes in this path

---

## Milestone 3: Corner Demotion
**Effort:** Small (1 hour)  
**Risk:** Low  
**Depends on:** Milestone 2

### Current Behavior
- Zone corners remain "special" after handoff
- May have different handling in ARMarkerPlaced, tap detection, etc.

### New Behavior
- After handoff, corners are mesh vertices like any other
- Can be adjusted (drift correction)
- No special-case code paths

### Deliverables
1. Audit corner-specific code paths:
   - `ARMarkerPlaced` handler — remove corner-specific branches post-handoff
   - Ghost selection — corners should be selectable/adjustable
   - Visual distinction — corners may retain visual indicator but behave identically

2. Verify corner adjustment works:
   - Tap on corner ghost → buttons appear
   - Adjust corner → marker placed at new position
   - Original corner position is replaced (not duplicated)

### Acceptance Criteria
- [ ] After handoff, corner ghosts behave identically to interior ghosts
- [ ] Corners can be confirmed/adjusted
- [ ] Adjusting a corner does not break anything

---

## Milestone 4: Calibration Tracking & Persistence
**Effort:** Medium (2-3 hours)  
**Risk:** Medium  
**Depends on:** Milestone 3

### Deliverables
1. **CalibrationRecord structure:**
   ```swift
   struct MeshVertexCalibration {
       let mapPointID: UUID
       var arPosition: simd_float3
       var source: CalibrationSource  // .projected | .confirmed | .adjusted
       var confidenceWeight: Float    // 0.5 or 1.0
       var timestamp: Date
   }
   ```

2. **Tracking logic:**
   - When ghost is confirmed at projected position: source = `.confirmed`, weight = 0.5
   - When ghost is adjusted to crosshair: source = `.adjusted`, weight = 1.0
   - Store in `ARCalibrationCoordinator.calibratedVertices: [UUID: MeshVertexCalibration]`

3. **Persistence:**
   - Bake calibrated positions to canonical space at session end
   - Store with confidence weights
   - Purge legacy position history (per migration strategy)

### Acceptance Criteria
- [ ] Each calibrated vertex has tracked source and confidence
- [ ] Positions persist across app restart
- [ ] Legacy position data is purged (clean slate)

---

## Milestone 5: End-to-End Validation
**Effort:** Small (1 hour)  
**Risk:** Low  
**Depends on:** Milestone 4

### Test Scenario
1. Launch Zone Corner calibration
2. Plant 4 corners at designated MapPoints
3. Verify: all mesh vertex ghosts appear at bilinear-interpolated positions
4. Walk zone, calibrate several vertices (mix of confirm/adjust)
5. Verify: calibrated vertices have AR markers, uncalibrated retain ghosts
6. Verify: corner points can be adjusted like any other
7. Exit AR view, re-enter
8. Verify: calibrated positions are restored

### Acceptance Criteria
- [ ] Complete flow works without crashes
- [ ] Visual positions are correct (no obvious projection errors)
- [ ] Persistence works
- [ ] Ready for Survey Marker flooding

---

## Milestone 6: Survey Marker Flooding
**Effort:** Small-Medium (1-2 hours)  
**Risk:** Low  
**Depends on:** Milestone 5

### Current State
Survey Markers can be placed individually at crosshair position within calibrated space.

### Enhancement
"Flood Zone" action that:
1. Computes grid positions within the zone boundary
2. For each grid position, derives AR position via:
   - If inside a fully-calibrated triangle → barycentric from vertices
   - Otherwise → bilinear from zone corners
3. Places Survey Markers at derived positions
4. Begins BLE data collection

### Deliverables
1. Grid generation within zone boundary
2. Position derivation (barycentric with bilinear fallback)
3. Batch Survey Marker placement
4. UI trigger ("Flood Zone" button)

### Acceptance Criteria
- [ ] Flood action places grid of Survey Markers
- [ ] Markers are correctly positioned in AR space
- [ ] BLE sampling begins on each marker
- [ ] Performance is acceptable (no frame drops during placement)

---

## Summary Timeline

| Milestone | Description | Effort | Cumulative |
|-----------|-------------|--------|------------|
| M1 | Bilinear math utilities | 1-2 hrs | 1-2 hrs |
| M2 | Wire into ghost projection | 2-3 hrs | 3-5 hrs |
| M3 | Corner demotion | 1 hr | 4-6 hrs |
| M4 | Calibration tracking | 2-3 hrs | 6-9 hrs |
| M5 | End-to-end validation | 1 hr | 7-10 hrs |
| M6 | Survey marker flooding | 1-2 hrs | 8-12 hrs |

**Total estimated effort:** 8-12 hours of focused development

---

## Dependencies & Blockers

| Item | Status | Notes |
|------|--------|-------|
| Zone corner designation in MapPoints | ✅ Exists | `role: .zoneCorner` or similar |
| Mesh vertex identification | ✅ Exists | Triangle vertices in TIN |
| Survey Marker infrastructure | ✅ Exists | Ready to use |
| Corner ordering convention | ❓ Needs decision | CCW from bottom-left recommended |

---

## Decision Required Before M2

**Corner ordering:** The 4 zone corners must be ordered consistently for UV computation.

**Recommendation:** Counter-clockwise starting from bottom-left (as viewed on 2D map):
```
D ←───── C
│        ↑
│        │
↓        │
A ─────→ B

A = (0,0), B = (1,0), C = (1,1), D = (0,1)
```

This matches standard texture mapping conventions.

**Question for you:** Is this ordering already implicit in how zone corners are designated/stored? Or does it need to be established?
