# Handoff Document: Drift Detection, Position History & Discard Functionality

## Context

This document captures design decisions and architectural considerations for managing AR position data quality in TapResolver. These topics were identified during a performance debugging session focused on Survey Markers but belong in a separate implementation track.

---

## Problem 1: UserDefaults Size Limit

### Symptom

From Xcode console log:
```
CFPrefsPlistSource<...>: Attempting to store >= 4194304 bytes of data in CFPreferences/NSUserDefaults on this platform is invalid. This is a bug in TapResolver or a library it uses.
```

The app is hitting the 4MB practical limit for UserDefaults on iOS.

### What's Stored

Current data footprint:
```
📖 [DATA_LOAD] locations.museum.MapPoints_v1: 70 items, 98973 bytes (~99KB)
📖 [DATA_LOAD] locations.home.MapPoints_v1: 21 items, 96739 bytes (~97KB)
📊 [DATA_SUMMARY] 70 MapPoints, 27 with history, 328 total position records across 65 sessions
📊 [DATA_SUMMARY] 21 MapPoints, 19 with history, 374 total position records across 66 sessions
```

Plus:
- TrianglePatchStore (21 triangles with vertex data, AR marker IDs)
- BeaconLists (19 beacons)
- SurveyPoints (growing with each survey session)
- ARWorldMapStore metadata
- HUD state, location preferences, debug flags

### Root Cause

Position history accumulates with each calibration session. The system was designed to build consensus from multiple observations, but without aggressive pruning, it grows unbounded.

Current eviction (per MapPoint):
```
🗑️ [POSITION_HISTORY] Evicted oldest record from 2C9EFCA9 (session: 5103A932)
```

There's a cap of 20 records per MapPoint. With 91 MapPoints across locations, that's up to 1,820 position records max — but combined with all other data, it's hitting the limit.

### Pruning Strategy Options

| Strategy | Pros | Cons |
|----------|------|------|
| Keep N newest per MapPoint | Simple, predictable | Loses old high-confidence data |
| Keep N highest confidence | Quality-focused | May lose recent corrections |
| Keep N newest + N highest confidence | Balanced | More complex |
| Age-based decay (discard >30 days) | Automatic cleanup | May lose valuable calibrations |
| Session-based limit (keep last N sessions globally) | Consistent pruning | Doesn't account for quality |
| Reduce cap from 20 → 10 | Quick fix | Loses half the consensus data |

### Recommendation

Consider a hybrid approach:
1. Reduce per-MapPoint cap from 20 → 10 (immediate relief)
2. Add global session limit (keep last 30 sessions worth of data)
3. Optionally: move historical position data to file storage, keep only "baked" consensus in UserDefaults

---

## Problem 2: Drift Detection & Recovery

### Current Infrastructure

The system already has drift detection:
```
🔍 [DRIFT_CHECK] Marker 6FCDC18C: recorded=(3.34, 2.51) current=(3.34, 2.51) drift=0.000m
```

This compares:
- **Recorded position:** Where the marker was placed (stored in ARMarker)
- **Current position:** Where ARKit thinks the marker is now (live transform)

The difference indicates how much ARKit's coordinate frame has drifted since placement.

### User Need

When the user visually notices markers are in the wrong place (unrecoverable drift), they need:
1. A way to **diagnose** — Confirm drift is real, not just visual perception
2. A way to **escape** — Discard bad data before it corrupts consensus

### Proposed UI: Check Drift Button

**Concept:** User taps a button, system reports drift status.

**Output examples:**
- "3 markers checked. Max drift: 0.04m ✅"
- "3 markers checked. Max drift: 0.31m ⚠️ — Consider discarding this session"

**Implementation notes:**
- Iterate through all AR markers placed this session
- For each marker, compute distance between recorded and current position
- Report max/average drift
- Could show per-marker breakdown on tap

### Alternative: Force Re-orientation

**Question from Chris:** "Is there a way to nudge the system to force a re-orientation to flag drift that isn't being automatically corrected?"

**Options explored:**

1. **Manual "Check Drift" button** — Reports drift, user decides
2. **Force session transform recomputation** — Re-run rigid body transform with current positions
3. **Continuous drift monitoring with auto-warning** — Background monitoring, badge when threshold exceeded
4. **"Recalibrate from Here"** — User confirms they're at a known location, system corrects from that single point

**Recommendation:** Start with Option 1 (Check Drift button) paired with Discard button. Add sophistication later if needed.

---

## Problem 3: Discard Session Position Data

### User Story

As a user, when I notice unrecoverable drift that could compromise position data, I want to discard this session's AR position data so that bad observations don't corrupt my calibration consensus.

### Design Decisions (Confirmed by Chris)

| Question | Answer |
|----------|--------|
| What gets discarded? | Just this session's position records. Historic position data from previous sessions is unaffected. |
| Remove AR markers from scene? | Yes — closing the scene is part of the discard action |
| Require confirmation? | Yes — "This will discard N position records from this session" |
| Only available when drift detected? | No — always available. User judgment is trusted. |

### UI Specification

**Button:**
- **Icon:** Red stop sign with exclamation point (🛑 or ⛔ with ❗)
- **Location:** Bottom right corner (accessible but not prominent)
- **Label:** "Discard Session" or just icon with accessibility label

**Confirmation Dialog:**
- Title: "Discard Session Data?"
- Message: "This will discard [N] position records from this session. Historic calibration data will not be affected."
- Actions: "Discard & Exit" (destructive) / "Cancel"

### Implementation Notes

**Data to discard:**

When a marker is registered during calibration, position history is added:
```
📍 [POSITION_HISTORY] calibration → MapPoint 2C9EFCA9 (#20)
   ↳ pos: (-0.82, -1.03, -1.65) @ 7:40:16 PM
```

Each position record has a `sessionID`. To discard:
1. Get current session ID
2. For each MapPoint that has position history from this session:
   - Remove position records where `sessionID == currentSessionID`
3. Save MapPointStore
4. Dismiss AR view
5. Reset calibration state

**What NOT to discard:**
- Position records from previous sessions
- The MapPoints themselves
- Triangle definitions
- Photos (they're useful reference regardless)

### Edge Cases

1. **No markers placed yet:** Button disabled or shows "Nothing to discard"
2. **User re-enters AR after discard:** Fresh session, no contamination
3. **Partial calibration (1 of 3 vertices):** Still discards that one position record

---

## Proposed UI Layout

```
┌─────────────────────────────────────────┐
│                                         │
│            AR View                      │
│                                         │
│                                         │
│                                         │
│                                         │
│                                         │
│                                         │
│                                    ┌──┐ │
│                                    │📐│ │  ← Check Drift
│                                    └──┘ │
│                                    ┌──┐ │
│                                    │🛑│ │  ← Discard Session
│                                    └──┘ │
└─────────────────────────────────────────┘
```

Both buttons in bottom-right stack, similar to existing debug/tool buttons.

---

## Related Code Locations

**Position history storage:**
- `MapPointStore` — stores `MapPoint` array with `positionHistory`
- `ARPositionRecord` — individual position observation with sessionID, confidence, timestamp

**Session tracking:**
- `ARWorldMapStore` or session context — tracks current session ID
- Session ID is generated at AR view launch

**Drift detection:**
- Already exists in calibration flow — look for `[DRIFT_CHECK]` logging
- Compares `ARMarker.position` (recorded) vs current SceneKit node position

**Discard implementation:**
- Would be a new method on `MapPointStore`: `discardPositionRecords(forSessionID:)`
- Called from AR view dismiss handler

---

## Open Questions for Implementation Chat

1. **Where is session ID currently stored?** Need to identify which records belong to "this session"
2. **Is there a global session registry?** Or is session ID only in ARWorldMapStore?
3. **Should discard also remove any AR markers from the scene graph?** (Probably yes, since we're dismissing anyway)
4. **Performance:** With 70+ MapPoints, iterating through all position history on discard — acceptable?

---

## Summary

| Feature | Purpose | Priority |
|---------|---------|----------|
| UserDefaults pruning | Prevent data loss from size limit | High (ticking bomb) |
| Check Drift button | Diagnose drift issues | Medium |
| Discard Session button | Escape from bad calibration | Medium |
| Position history optimization | Long-term data hygiene | Low (after above) |

This document provides context for a separate implementation chat. The Survey Markers / Threading chat should remain focused on BLE performance and thread management.
