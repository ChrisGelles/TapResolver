# Survey Marker Positioning System: Approach & Development Phases

## Executive Summary

TapResolver's Survey Marker system builds an empirical indoor positioning database by collecting real-world Bluetooth signal measurements at precisely known locations. Rather than relying on theoretical RF propagation models, we capture what signals *actually do* in a specific environment—with all its walls, reflections, furniture, and unpredictable characteristics.

The system follows a **collect → export → analyze → bake → apply** pipeline, keeping raw data collection separate from the compact operational model used for live positioning.

---

## Core Philosophy

### Empirical Over Theoretical

Traditional indoor positioning often starts with idealized models:
- "Signal strength follows inverse-square law"
- "Subtract path loss exponent × log(distance)"
- "Beacon TX power minus expected loss equals distance"

**These rarely work in practice.**

Real environments introduce:
- Multipath interference (signals bouncing off walls, floors, ceilings)
- Absorption by furniture, people, and materials
- Antenna orientation effects
- Environmental noise from other 2.4GHz devices
- "Dead zones" that defy geometric prediction

**Our approach:** Treat each survey point as ground truth. Capture what the signals actually look like at that location. Build the positioning model from observed reality, not theoretical expectation.

### Body Shadow Awareness

When a user holds a phone, their body can partially block signals from beacons behind them. This creates a directional bias in received signal strength.

We capture device orientation alongside RSSI to:
1. Detect whether body shadow affects readings at each point
2. Potentially correct for this effect during live positioning
3. At minimum, understand it as a source of variance

This may or may not prove significant—we're capturing the data to find out.

---

## Data Lifecycle

```
┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│   📱 COLLECTION                                                     │
│   On-device, verbose, temporary                                     │
│                                                                     │
│   User walks to Survey Marker → dwells → raw data captured          │
│   • RSSI samples with timestamps                                    │
│   • Device pose (position + orientation) per sample                 │
│   • Session metadata                                                │
│                                                                     │
│   Storage: ~12 KB per session                                       │
│                                                                     │
└────────────────────────────────┬────────────────────────────────────┘
                                 │
                                 │  Export (JSON)
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│   🗄️ CENTRAL DATABASE                                               │
│   Off-device, persistent, comprehensive                             │
│                                                                     │
│   All sessions from all collection passes aggregated                │
│   • Multiple sessions per survey point                              │
│   • Multiple collection dates/conditions                            │
│   • Full fidelity raw data preserved                                │
│                                                                     │
└────────────────────────────────┬────────────────────────────────────┘
                                 │
                                 │  Analysis & Processing
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│   🔬 ANALYSIS                                                       │
│   Pattern extraction, model building                                │
│                                                                     │
│   • Extract fingerprints (characteristic RSSI patterns per point)   │
│   • Build body shadow correction model (if warranted)               │
│   • Identify beacon-specific characteristics                        │
│   • Clean/validate noisy or inconsistent sessions                   │
│   • Visualize signal falloff across the map                         │
│                                                                     │
└────────────────────────────────┬────────────────────────────────────┘
                                 │
                                 │  Bake (distill to compact form)
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│   📦 OPERATIONAL MODEL                                              │
│   On-device, compact, read-only                                     │
│                                                                     │
│   Fingerprint database:                                             │
│   "At map coordinate (X, Y), expect these signal characteristics"   │
│                                                                     │
│   Body shadow model (optional):                                     │
│   "When facing away from beacon B, expect RSSI reduced by N dBm"    │
│                                                                     │
│   Storage: ~200 bytes per survey point                              │
│                                                                     │
└────────────────────────────────┬────────────────────────────────────┘
                                 │
                                 │  Runtime lookup
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│   📍 LIVE POSITIONING                                               │
│   Real-time, continuous                                             │
│                                                                     │
│   Continuous BLE advertisement stream                               │
│        ↓                                                            │
│   Compare live readings to fingerprint database                     │
│        ↓                                                            │
│   (Optional) Apply body shadow correction                           │
│        ↓                                                            │
│   Estimate user position on map                                     │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Why This Architecture?

### Separation of Concerns

**Collection** is about capturing everything that might be useful. We don't know yet exactly which patterns matter most, so we err on the side of completeness.

**Analysis** happens offline where we have time and tools to explore. Python, Jupyter notebooks, visualization libraries—whatever helps us understand the data.

**Operational** is about efficiency. The positioning algorithm runs continuously on a mobile device. It needs compact data and fast lookups, not research-grade detail.

### Storage Reality

Raw collection data is verbose:
- 12 KB per session
- 100 survey points × 3 sessions = 3.6 MB
- Grows with each collection pass

This is fine for temporary storage, but:
- Users don't want their phone filling up
- Most of this detail isn't needed at runtime
- Raw data belongs in a proper database, not UserDefaults

Hence: **export early, purge often.**

### Iterative Refinement

We don't yet know:
- What fingerprint structure works best
- How much body shadow matters
- What signal patterns are most distinctive

The pipeline allows us to:
1. Collect rich data
2. Analyze and learn
3. Bake a compact model
4. Test positioning accuracy
5. Identify gaps
6. Collect more targeted data
7. Repeat

---

## Development Phases

### Phase 1: Collection Pipeline (Current Focus)

**Goal:** Capture high-quality survey data during dwell sessions.

**Deliverables:**
- `RssiPoseSample` data structure (RSSI + pose per BLE callback)
- Wiring from BLE scanner → ARKit pose → sample buffer
- Session lifecycle management (enter marker → collect → exit marker)
- Statistics computation on exit (median, MAD, percentiles, histogram)
- Persistence to `SurveyPointStore`

**Success Criteria:**
- User can dwell in a Survey Marker and see session recorded
- Data includes timestamped RSSI and device pose
- Sessions are bookended with boundary markers

---

### Phase 2: Export & Purge

**Goal:** Move raw data off-device into central database.

**Deliverables:**
- JSON export of all sessions for a location
- Share sheet integration (AirDrop, Files, email)
- Purge mechanism to clear exported sessions
- UI to view collection status, trigger export/purge

**Success Criteria:**
- User can export all survey data as JSON
- User can purge sessions after confirming export
- Central database accumulates data from multiple collection passes

---

### Phase 3: Analysis Tooling (Off-Device)

**Goal:** Understand signal patterns and build models.

**Deliverables:**
- Python scripts / Jupyter notebooks for data exploration
- Visualization of RSSI patterns across map
- Fingerprint extraction algorithms
- Body shadow correlation analysis
- Data quality validation

**Success Criteria:**
- Can identify characteristic signal patterns per survey point
- Can visualize beacon signal falloff across the environment
- Understand whether body shadow correction is worthwhile
- Define the "fingerprint" structure for operational use

---

### Phase 4: Baked Model Import

**Goal:** Load compact positioning data back to device.

**Deliverables:**
- Baked fingerprint data structure (compact)
- Import mechanism from central database
- Storage in appropriate on-device format
- Versioning to handle model updates

**Success Criteria:**
- Compact model loads quickly at app launch
- Storage footprint is minimal (~200 bytes per point)
- Can update model without full app reinstall

---

### Phase 5: Live Positioning

**Goal:** Estimate user position from live BLE signals.

**Deliverables:**
- Continuous BLE monitoring during navigation
- Fingerprint matching algorithm
- Position estimation with confidence
- (Optional) Body shadow correction based on device orientation
- UI showing estimated position on map

**Success Criteria:**
- Real-time position updates as user moves
- Reasonable accuracy (TBD based on analysis findings)
- Graceful degradation when signals are ambiguous

---

## Data Flow Details

### Collection Pass Workflow

```
1. User enters AR calibration mode
2. Survey Markers appear in AR space at calibrated positions
3. User physically walks to a Survey Marker
4. Device enters the marker's collision sphere
   → Session timer starts
   → BLE listener begins capturing advertisements
   → Each advertisement triggers:
      • Timestamp (ms since session start)
      • RSSI value (dBm)
      • Device pose from ARKit (position + quaternion)
   → Sample appended to beacon's buffer
5. User exits the collision sphere (or dwells long enough)
   → Session ends
   → Boundary markers inserted
   → Statistics computed
   → Session persisted to SurveyPointStore
6. Repeat for other Survey Markers
7. When finished, export collected data
8. Purge raw sessions from device
```

### Export Format

```json
{
  "locationID": "museum-main-floor",
  "exportDate": "2025-12-14T15:30:00Z",
  "surveyPoints": [
    {
      "mapX": 245.5,
      "mapY": 892.0,
      "sessions": [
        {
          "id": "A1B2C3...",
          "startISO": "2025-12-14T14:22:15Z",
          "endISO": "2025-12-14T14:22:19Z",
          "duration_s": 4.2,
          "devicePose": { "x": 1.2, "y": 1.5, "z": -0.8, "qx": 0, "qy": 0, "qz": 0, "qw": 1 },
          "beacons": [
            {
              "beaconID": "Beacon-NorthWall",
              "stats": { "median_dbm": -68, "mad_db": 2, "p10_dbm": -72, "p90_dbm": -65, "sampleCount": 35 },
              "histogram": { "binMin_dbm": -100, "binMax_dbm": -30, "binSize_db": 1, "counts": [...] },
              "samples": [
                { "ms": 0, "rssi": 0, "x": 1.2, "y": 1.5, "z": -0.8, "qx": 0, "qy": 0, "qz": 0, "qw": 1 },
                { "ms": 105, "rssi": -67, "x": 1.2, "y": 1.5, "z": -0.8, "qx": 0.01, "qy": 0, "qz": 0, "qw": 0.99 },
                ...
              ],
              "meta": { "name": "Beacon-NorthWall", "model": "Kontakt-Pro", "txPower": -12, "advertisingInterval_ms": 100 }
            },
            ...
          ]
        }
      ]
    },
    ...
  ]
}
```

### Baked Model Format (Conceptual)

Structure TBD based on analysis findings. Likely something like:

```json
{
  "locationID": "museum-main-floor",
  "bakedDate": "2025-12-20T10:00:00Z",
  "modelVersion": "1.0",
  "fingerprints": [
    {
      "mapX": 245.5,
      "mapY": 892.0,
      "beacons": {
        "Beacon-NorthWall": { "median": -68, "spread": 4 },
        "Beacon-SouthWall": { "median": -75, "spread": 6 },
        "Beacon-EastDoor": { "median": -82, "spread": 3 }
      }
    },
    ...
  ],
  "bodyShadowModel": {
    "enabled": true,
    "correctionCurve": [ ... ]
  }
}
```

---

## Open Questions

These will be answered through analysis:

1. **Fingerprint granularity:** What's the minimum data needed to distinguish survey points? Just medians? Need variance? Need histogram shape?

2. **Body shadow significance:** Does device orientation measurably affect RSSI in practice? Is correction worth the complexity?

3. **Temporal stability:** Do fingerprints change over time (furniture moved, seasonal changes)? How often must we resurvey?

4. **Positioning algorithm:** Nearest-neighbor fingerprint matching? Probabilistic weighting? Particle filter? Depends on data characteristics.

5. **Density requirements:** How close must survey points be for accurate positioning? 1 meter? 2 meters? Depends on signal distinctiveness.

---

## Summary

| Phase | Location | Data | Purpose |
|-------|----------|------|---------|
| Collection | Device | Rich (~12KB/session) | Capture everything |
| Database | Central | Accumulated | Permanent storage |
| Analysis | Off-device | Full fidelity | Pattern discovery |
| Baked | Device | Compact (~200B/point) | Runtime positioning |
| Positioning | Device | Live stream | User location |

The pipeline ensures we capture comprehensive data for research while keeping the operational footprint minimal. Export early, purge often, and let the central database hold the full history.
