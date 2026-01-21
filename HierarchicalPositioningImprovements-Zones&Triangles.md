---

## Zone/Triangle Calibration Refinement — Project Brief

### Document Status
**Created:** 2026-01-21  
**Status:** Investigation Complete, Implementation Pending  
**Context Token Count:** ~107,000 (~56%)

---

## Executive Summary

The Zone/Triangle calibration system has working position history recording but fails to leverage that history across sessions. Additionally, extrapolated ghost positions receive the same confidence as interpolated positions, and no reconciliation occurs when a containing Zone is later confirmed. This document outlines findings and a 4-phase implementation plan to address these gaps.

---

## Part 1: Investigation Findings

### What's Working

| Component | Status | Evidence |
|-----------|--------|----------|
| Zone Corner → positionHistory recording | ✅ Working | `registerZoneCornerAnchor()` line 1543: `.calibration`, confidence 0.95 |
| Fill point → positionHistory recording | ✅ Working | `registerFillPointMarker()` line 2236: `.ghostAdjust`, confidence 0.90 |
| Shared MapPoint skip logic | ✅ Working | `plantGhostsForAllTriangleVerticesBilinear()` lines 2484-2494 |
| Shared MapPoint available to triangle mesh | ✅ Working | Corner position stored in `mapPointARPositions` at line 1531 |
| Extrapolation detection in bilinear | ✅ Exists | `BilinearInterpolation.swift` line 358: detects `uv.u < 0 || uv.u > 1 || uv.v < 0 || uv.v > 1` |
| Distortion vector calculation | ✅ Partial | `registerFillPointMarker()` lines 2218-2226 calculates delta |

### What's Broken or Missing

| Component | Status | Evidence |
|-----------|--------|----------|
| Zone Corner history → Similarity Transform | ❌ Not implemented | `gatherCornerCorrespondences()` line 5294 only reads `mapPointARPositions` (current session) |
| Extrapolation status exposed to callers | ❌ Not implemented | `projectPointViaBilinear()` returns `simd_float3?` only, no extrapolation flag |
| Extrapolation confidence penalty | ❌ Not implemented | All ghosts receive same confidence regardless of projection type |
| Reconciliation when containing Zone confirms | ❌ Not implemented | No logic compares predicted vs. actual for already-confirmed vertices |
| Distortion vectors used for reconciliation | ❌ Not implemented | Vectors calculated but not applied when Zone B confirms |

### Critical Gap: Zone Corner Mesh Not Self-Improving

**The Problem:**

`gatherCornerCorrespondences()` builds the correspondence set for the Similarity Transform:

```swift
// Line 5294 - ONLY uses current session
guard let arPosition = mapPointARPositions[cornerID] else { continue }
```

This means:
- Zone Corner confirmations DO record to `positionHistory` ✅
- But future sessions DON'T read that history ❌
- Each session starts fresh with zero correspondences
- The "self-improving Zone Corner mesh" doesn't actually improve across sessions

**Impact:** Similarity Transform accuracy is limited to corners planted in the current session only. Historical calibration data (potentially dozens of sessions) is ignored.

---

## Part 2: Architectural Context

### The Two-Mesh System

| Mesh | Solver | Scope | Distortion Tracking |
|------|--------|-------|---------------------|
| **Zone Corner Mesh** | Similarity Transform | Entire map | Planned — should improve with each session |
| **Triangle Vertex Mesh** | Bilinear Interpolation | Within zone quad | Working — distortion vectors recorded |

Zone Corners form the coarse scaffold. Triangle Vertices provide fine-grained correction within each zone.

### Confidence Scoring Model

| Source | Current Confidence | Notes |
|--------|-------------------|-------|
| Zone Corner placement | 0.95 | `.calibration` source type |
| Fill point confirmation | 0.90 | `.ghostAdjust` source type |
| Extrapolated position (confirmed) | 0.90 | **Should be ~0.45** until containing Zone confirms |
| After reconciliation | 0.90 | Penalty removed once authoritative Zone confirms |

### Position History Recording Threshold

Recording to position history should only occur after sufficient correspondences exist for meaningful consensus:

- **Minimum:** 6 confirmed corners (~2 zones, accounting for shared corners)
- **Rationale:** Fewer than 6 points gives poor Similarity Transform fit; recording those positions pollutes the consensus

---

## Part 3: Implementation Approach

### Guiding Principles

1. **Hierarchy:** Zone Corners are authoritative. Triangle Vertices derive from Zone quad.
2. **Accumulation:** Every confirmation contributes to position history (after threshold met).
3. **Reconciliation:** When a containing Zone confirms, extrapolated vertices get distortion vectors recorded and confidence upgraded.
4. **Extrapolation penalty is temporary:** Low confidence only until authoritative Zone confirms.

### Dependency Graph

```
Priority 3: Zone Corner History
    │
    │ (no dependencies)
    │
    ▼
Priority 1: Expose Extrapolation Status
    │
    │ (no dependencies)
    │
    ▼
Priority 2: Extrapolation Confidence Penalty
    │
    │ (depends on Priority 1)
    │
    ▼
Priority 4: Reconciliation Logic
    │
    │ (depends on Priority 3 for Zone mesh)
    │
    ▼
    Complete
```

**Recommended Sequence:** 3 → 1 → 2 → 4

---

## Part 4: Priority Phase Details

### Priority 3: Zone Corner History → Similarity Transform

**Objective:** Enable `gatherCornerCorrespondences()` to use baked positions from previous sessions, not just current-session planted corners.

**Current Behavior:**
```swift
guard let arPosition = mapPointARPositions[cornerID] else { continue }
```
Only current session. Historical data ignored.

**Desired Behavior:**
```swift
// Try current session first
if let arPosition = mapPointARPositions[cornerID] {
    use(arPosition)
} 
// Fall back to projected baked position
else if hasValidSessionTransform,
        let baked = mapPoint.bakedCanonicalPosition,
        let projected = projectBakedToSession(baked) {
    use(projected)
}
```

**Prerequisites:**
- Session↔canonical transform must exist (established after ≥2 corners with both current AND baked positions)
- Position history recording gated by ≥6 corner threshold

**Files Affected:**
- `ARCalibrationCoordinator.swift`: `gatherCornerCorrespondences()`, `registerZoneCornerAnchor()`

**Success Criteria:**
- [ ] Console shows baked projection count > 0 in sessions with historical data
- [ ] Similarity Transform uses more correspondences
- [ ] Position history recording skipped until ≥6 corners

---

### Priority 1: Expose Extrapolation Status from Bilinear

**Objective:** Make `projectPointViaBilinear()` report whether the projected position was interpolated (inside quad) or extrapolated (outside quad).

**Current Behavior:**
```swift
func projectPointViaBilinear(mapPoint: CGPoint) -> simd_float3?
```
Returns position only. Extrapolation detected internally but not exposed.

**Desired Behavior:**
```swift
struct BilinearProjectionResult {
    let position: simd_float3
    let isExtrapolated: Bool
    let uvCoordinates: (u: Float, v: Float)
}

func projectPointViaBilinear(mapPoint: CGPoint) -> BilinearProjectionResult?
```

**Files Affected:**
- `ARCalibrationCoordinator.swift`: `projectPointViaBilinear()`
- `BilinearInterpolation.swift`: Already detects extrapolation, may need to return flag
- Callers of `projectPointViaBilinear()`: Update to handle new return type

**Success Criteria:**
- [ ] Console logs distinguish `[BILINEAR]` vs `[BILINEAR_EXTRAP]` at spawn time
- [ ] Callers receive extrapolation status
- [ ] No change to projection math itself

---

### Priority 2: Extrapolation Confidence Penalty

**Objective:** Ghosts spawned via extrapolation receive reduced confidence (~0.45) until their containing Zone is confirmed.

**Current Behavior:**
All confirmed ghosts receive 0.90 confidence regardless of projection type.

**Desired Behavior:**
```
Ghost spawned via extrapolation → tagged as extrapolated
    │
    ▼
User confirms ghost
    │
    ├── isExtrapolated? → confidence = 0.45
    │
    └── not extrapolated? → confidence = 0.90
    
Later: Containing Zone confirmed → reconciliation runs → confidence upgraded to 0.90
```

**Implementation Options:**
1. Store `isExtrapolated` flag in `PendingMarker` struct
2. Pass flag through `PlaceGhostMarker` notification
3. Store flag in `ghostMarkerPositions` (change to dictionary of structs)

**Files Affected:**
- `ARCalibrationCoordinator.swift`: `PendingMarker`, ghost spawning, confirmation handlers
- Possibly `ARViewContainer.swift`: notification handling

**Success Criteria:**
- [ ] Extrapolated ghost confirmation logs confidence = 0.45
- [ ] Interior ghost confirmation logs confidence = 0.90
- [ ] Position history records reflect correct confidence

---

### Priority 4: Reconciliation When Containing Zone Confirms

**Objective:** When Zone B is planted and contains vertices previously confirmed via extrapolation from Zone A, calculate where Zone B WOULD have placed them and record distortion vectors.

**Current Behavior:**
No comparison occurs. Extrapolated vertices remain at their confirmed positions with low confidence forever.

**Desired Behavior:**
```
Zone B planted (4 corners confirmed)
    │
    ▼
For each triangle vertex INSIDE Zone B:
    │
    ├── Already has confirmed position (from extrapolation)?
    │       │
    │       ├── Calculate: predicted = Zone B bilinear projection
    │       ├── Calculate: delta = confirmed - predicted
    │       ├── Record delta as distortion vector
    │       └── Upgrade confidence from 0.45 → 0.90
    │
    └── No confirmed position? → Spawn ghost as normal
```

**Files Affected:**
- `ARCalibrationCoordinator.swift`: Zone completion handler, new reconciliation function
- `MapPointStore.swift`: Distortion vector storage (already exists at `consensusDistortionVector`)

**Success Criteria:**
- [ ] Console logs "Reconciling vertex X: predicted (a,b,c) vs confirmed (d,e,f), delta = (x,y,z)"
- [ ] Distortion vector recorded on MapPoint
- [ ] Confidence upgraded from 0.45 to 0.90
- [ ] Always records delta (no threshold filtering)

---

## Part 5: Open Questions

1. **Threshold basis:** Should ≥6 threshold use `mapPointARPositions.count` or `plantedZoneIDs.count >= 2`?

2. **Correspondence weighting:** Should baked-projected correspondences be weighted differently than current-session correspondences in Similarity Transform computation?

3. **Extrapolation margin:** How far outside the quad is acceptable for extrapolation before returning nil? Current behavior allows any extrapolation.

4. **Confidence upgrade trigger:** Does reconciliation run immediately when Zone B completes, or on next app launch, or manually triggered?

---

## Part 6: File Reference

| File | Relevant Functions |
|------|-------------------|
| `ARCalibrationCoordinator.swift` | `gatherCornerCorrespondences()`, `projectPointViaBilinear()`, `plantGhostsForAllTriangleVerticesBilinear()`, `registerZoneCornerAnchor()`, `registerFillPointMarker()`, `spawnAllZoneCornerGhosts()` |
| `BilinearInterpolation.swift` | `projectPointBilinear()`, `inverseBilinear()` |
| `MapPointStore.swift` | `addPositionRecord()`, `consensusDistortionVector` property |
| `ARViewWithOverlays.swift` | Ghost confirmation button handlers |

---

## Part 7: Logging Tags

| Tag | Meaning |
|-----|---------|
| `📐 [CORRESPONDENCES]` | Correspondence gathering for Similarity Transform |
| `📐 [BILINEAR]` | Interior point projection (interpolation) |
| `📐 [BILINEAR_EXTRAP]` | Exterior point projection (extrapolation) |
| `📍 [POSITION_HISTORY]` | Position recording to history |
| `🔄 [RECONCILE]` | Reconciliation when containing Zone confirms |
| `⚠️ [CONFIDENCE]` | Confidence scoring decisions |

---

**Document Status:** Ready for implementation  
**Next Step:** Cursor instructions for Priority 3