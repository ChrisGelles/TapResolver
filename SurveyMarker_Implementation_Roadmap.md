# Survey Marker Data Collection: Implementation Roadmap

## Overview

This document details the implementation plan for TapResolver's Survey Marker data collection system. The system captures BLE signal strength data synchronized with device pose at precisely calibrated AR positions, enabling empirical indoor positioning model construction.

---

## Final Data Model

### RssiPoseSample

The atomic unit of collected data. Created each time a BLE advertisement is received during a dwell session.

```swift
public struct RssiPoseSample: Codable, Equatable {
    public let ms: Int64              // Milliseconds since session start
    public let rssi: Int              // Signal strength (dBm), 0 = boundary marker
    
    // Device pose at moment of BLE callback (AR session coordinates)
    public let x: Float               // Position X (meters)
    public let y: Float               // Position Y (meters)
    public let z: Float               // Position Z (meters)
    public let qx: Float              // Quaternion X
    public let qy: Float              // Quaternion Y
    public let qz: Float              // Quaternion Z
    public let qw: Float              // Quaternion W
}
```

### SurveySession

One complete dwell session at a Survey Marker.

```swift
public struct SurveySession: Codable, Identifiable, Equatable {
    public let id: String                     // UUID string
    public let locationID: String             // Location identifier
    
    // Timing
    public let startISO: String               // ISO8601 start timestamp
    public let endISO: String                 // ISO8601 end timestamp
    public let duration_s: Double             // Must be ≥3.0 seconds to persist
    
    // Reference pose (snapshot at session start)
    public let devicePose: SurveyDevicePose
    
    // Compass snapshot for magnetic distortion mapping
    public let compassHeading_deg: Float      // Raw magnetic north at session start
    
    // Per-beacon measurements
    public let beacons: [SurveyBeaconMeasurement]
}
```

### SurveyBeaconMeasurement

All data for one beacon during one session.

```swift
public struct SurveyBeaconMeasurement: Codable, Equatable {
    public let beaconID: String
    public let stats: SurveyStats             // Computed on session end
    public let histogram: SurveyHistogram     // Computed on session end
    public let samples: [RssiPoseSample]      // Raw timeline, bookended with rssi=0
    public let meta: SurveyBeaconMeta
}
```

### SurveyPointQuality

Quality metrics aggregated at the survey point level.

```swift
public struct AngularCoverage: Codable, Equatable {
    /// Accumulated dwell time per compass sector (8 sectors, 45° each)
    /// Index 0 = North (337.5° to 22.5°), proceeding clockwise
    var sectorTime_s: [Double]  // 8 elements
    
    init() {
        sectorTime_s = Array(repeating: 0.0, count: 8)
    }
    
    /// Sectors with ≥1 second of data
    var coveredSectorCount: Int {
        sectorTime_s.filter { $0 >= 1.0 }.count
    }
    
    /// Add time to appropriate sector(s) based on heading
    /// Includes blurring: headings within 10° of boundary credit both sectors
    mutating func addTime(_ seconds: Double, atHeading heading: Double)
}

public struct SurveyPointQuality: Codable, Equatable {
    var totalDwellTime_s: Double = 0.0
    var angularCoverage: AngularCoverage = AngularCoverage()
    var sessionCount: Int = 0
    
    var colorTier: ColorTier {
        if totalDwellTime_s < 3.0 { return .red }
        if totalDwellTime_s < 9.0 { return .yellow }
        if angularCoverage.coveredSectorCount >= 3 { return .blue }
        return .green
    }
    
    enum ColorTier: String, Codable {
        case red, yellow, green, blue
        
        var uiColor: UIColor {
            switch self {
            case .red: return .systemRed
            case .yellow: return .systemYellow
            case .green: return .systemGreen
            case .blue: return .systemBlue
            }
        }
    }
}
```

### SurveyPoint

A survey location with accumulated sessions and quality metrics.

```swift
public struct SurveyPoint: Codable, Identifiable, Equatable {
    public let id: String                     // Derived from initial coordinates
    public var mapX: Double                   // Map X coordinate (pixels) - weighted average
    public var mapY: Double                   // Map Y coordinate (pixels) - weighted average
    public var sessions: [SurveySession]
    public var quality: SurveyPointQuality    // Aggregated metrics
    
    // For weighted coordinate averaging
    // Coordinates = weightedSum / totalWeight
    var weightedSumX: Double                  // Σ(mapX × dwellTime)
    var weightedSumY: Double                  // Σ(mapY × dwellTime)
    // totalWeight is quality.totalDwellTime_s
    
    /// Recalculate mapX/mapY from weighted sums
    mutating func recalculateCoordinates() {
        guard quality.totalDwellTime_s > 0 else { return }
        mapX = weightedSumX / quality.totalDwellTime_s
        mapY = weightedSumY / quality.totalDwellTime_s
    }
}
```

---

## Spatial Rules

### Merge Zone (0–3cm)

When a Survey Marker is placed within 3cm of an existing survey point:
- Sessions are added to the **existing** point
- No new point is created
- **Coordinates are recalculated** as a weighted average of all contributing positions

**Weighted coordinate averaging:**
- Each session contributes its marker's map coordinates
- Weight = session's dwell time (seconds)
- New point coordinates = Σ(coordinate × weight) / Σ(weight)

Example:
- Existing point at (100.0, 200.0) with 6 seconds of data
- New session at (100.02, 200.01) with 3 seconds of data
- New coordinates: ((100.0 × 6) + (100.02 × 3)) / 9 = 100.0067
- Y similarly: ((200.0 × 6) + (200.01 × 3)) / 9 = 200.0033

This causes the survey point to drift toward the weighted centroid of all measurements.

### Inheritance Zone (3–50cm)

When a Survey Marker is placed 3–50cm from an existing survey point:
- A **new** point is created at the marker's coordinates
- Initial display color inherits from nearby point(s)
- Inheritance strength decays linearly with distance:
  - At 3cm: 100% inheritance
  - At 50cm: 0% inheritance
- Once the new point collects its own data, quality is computed from its own sessions

### No Inheritance (>50cm)

- New point starts with no data (red)
- No quality inheritance from distant points

---

## Session Validity Rules

### Minimum Duration: 3 Seconds

Sessions shorter than 3 seconds are **discarded entirely**:
- Not persisted to storage
- Do not affect quality metrics
- User receives no color change feedback

This matches the existing dwell timer threshold for "ready" state.

### Boundary Markers

Each beacon's sample timeline is bookended with `rssi = 0` markers:
- First sample: `ms = 0`, `rssi = 0`, pose at session start
- Last sample: `ms = duration_ms`, `rssi = 0`, pose at session end

This creates clean interpolation boundaries for visualization.

---

## Color Tier Progression

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   RED ──────────► YELLOW ──────────► GREEN ──────────► BLUE    │
│                                                                 │
│   No data         3+ seconds         9+ seconds       9+ secs  │
│   (0 sessions)    (1+ sessions)      temporal         temporal │
│                                                                 │
│                                                        AND      │
│                                                                 │
│                                                       3+ sectors│
│                                                       covered   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Angular Coverage for Blue

To reach Blue status, the user must have captured data while facing **at least 3 different compass sectors** (of 8 total). Each sector requires ≥1 second of accumulated dwell time.

**Sector blurring:** When device heading is within 10° of a sector boundary, both adjacent sectors receive partial time credit. This prevents edge-case frustration where 44° only credits sector 0 but 46° only credits sector 1.

---

## Implementation Roadmap

### Milestone 1: Data Structure Updates

**Goal:** Update `SurveyPointStore.swift` with new data model.

**Tasks:**
1. Replace `RssiSample` with `RssiPoseSample`
2. Add `compassHeading_deg` to `SurveySession`
3. Create `AngularCoverage` struct
4. Create `SurveyPointQuality` struct with `ColorTier` enum
5. Add `quality` property to `SurveyPoint`
6. Update all initializers and persistence code

**Acceptance Criteria:**
- [ ] Project compiles with no errors
- [ ] Existing `SurveyPointStore` tests pass (if any)
- [ ] New structs are `Codable` and persist correctly

**Dependencies:** None

**Estimated complexity:** Low-medium

---

### Milestone 2: Survey Session Collector

**Goal:** Create `SurveySessionCollector.swift` to manage dwell session lifecycle.

**Tasks:**
1. Create new file `SurveySessionCollector.swift`
2. Subscribe to `SurveyMarkerEntered` notification → start session
3. Subscribe to `SurveyMarkerExited` notification → end session
4. Track session timing (start time, elapsed ms)
5. Maintain per-beacon sample buffers during dwell
6. Enforce 3-second minimum duration on exit
7. Insert boundary markers (rssi=0) at start and end

**Inputs needed:**
- Notification from AR collision detection (exists)
- Map coordinate from Survey Marker (exists in notification userInfo)

**Outputs:**
- Calls `SurveyPointStore.addSession()` on valid session completion

**Acceptance Criteria:**
- [ ] Session starts on marker entry
- [ ] Session ends on marker exit
- [ ] Sessions <3 seconds are discarded with console log
- [ ] Valid sessions are persisted to `SurveyPointStore`

**Dependencies:** Milestone 1

**Estimated complexity:** Medium

---

### Milestone 3: BLE Callback Wiring

**Goal:** Route BLE advertisement callbacks to the collector during dwell.

**Tasks:**
1. Add callback/delegate mechanism to `SurveySessionCollector`
2. Modify `BluetoothScanner` to forward RSSI readings during active dwell
3. Filter to only known/whitelisted beacons (or all beacons—TBD)
4. Each callback creates an `RssiPoseSample` (without pose yet)

**Acceptance Criteria:**
- [ ] BLE callbacks reach collector during dwell
- [ ] Samples accumulate in per-beacon buffers
- [ ] Console log shows sample counts on session end

**Dependencies:** Milestone 2

**Estimated complexity:** Medium

---

### Milestone 4: ARKit Pose Capture

**Goal:** Capture device pose at each BLE callback.

**Tasks:**
1. Determine pose access pattern:
   - Option A: Collector holds weak reference to ARSession
   - Option B: Closure injection from coordinator
   - Option C: Coordinator provides pose via callback
2. Implement pose capture at BLE callback moment
3. Populate pose fields in `RssiPoseSample`

**Technical note:** ARKit runs at ~60Hz. BLE callbacks arrive at ~1-10Hz per beacon. When BLE callback fires, grab current ARKit pose (within ~16ms accuracy).

**Acceptance Criteria:**
- [ ] Each `RssiPoseSample` has valid pose data (non-zero quaternion)
- [ ] Pose values change appropriately when device moves
- [ ] No threading violations (main thread access for ARKit)

**Dependencies:** Milestone 3

**Estimated complexity:** Medium

---

### Milestone 5: Compass Snapshot

**Goal:** Capture compass heading at session start.

**Tasks:**
1. Access `CompassOrientationManager` from collector
2. Capture raw magnetic heading when session starts
3. Store in `SurveySession.compassHeading_deg`

**Acceptance Criteria:**
- [ ] Each persisted session has compass heading
- [ ] Value is raw magnetic north (0-360°)
- [ ] Graceful handling if compass unavailable (use -1 or similar sentinel)

**Dependencies:** Milestone 2

**Estimated complexity:** Low

---

### Milestone 6: Angular Coverage Computation

**Goal:** Compute angular coverage from session data on exit.

**Tasks:**
1. Extract yaw (heading) from quaternion samples
2. Convert AR session yaw to map-relative heading (using north offset calibration)
3. For each sample, determine which sector(s) it credits
4. Accumulate sector time based on sample intervals
5. Apply sector blurring for samples near boundaries (±10°)
6. Update `SurveyPoint.quality.angularCoverage` on session end

**Acceptance Criteria:**
- [ ] Angular coverage updates after each session
- [ ] Multiple sessions accumulate coverage correctly
- [ ] Blurring works at sector boundaries
- [ ] Console log shows sector coverage on session end

**Dependencies:** Milestones 4, 5

**Estimated complexity:** Medium-high

---

### Milestone 7: Statistics Computation

**Goal:** Compute RSSI statistics and histogram on session end.

**Tasks:**
1. Implement median calculation for RSSI values (excluding boundary markers)
2. Implement MAD (Median Absolute Deviation)
3. Implement p10/p90 percentiles
4. Build histogram (1dB bins, -100 to -30 dBm)
5. Package into `SurveyStats` and `SurveyHistogram`

**Acceptance Criteria:**
- [ ] Each `SurveyBeaconMeasurement` has valid stats
- [ ] Stats exclude boundary markers (rssi=0)
- [ ] Histogram bin counts sum to sample count

**Dependencies:** Milestone 3

**Estimated complexity:** Low-medium

---

### Milestone 8: Sphere Color Feedback

**Goal:** Update Survey Marker outer sphere color based on data quality.

**Tasks:**
1. Add method to `SurveyMarker` to update exterior color
2. Query `SurveyPointStore` for quality at marker's map coordinate
3. Apply spatial inheritance for new markers (3-50cm decay)
4. Set color on marker creation (initial state)
5. Update color on session completion (dwell exit)

**SceneKit implementation:**
- Access sphere node via `marker.node` child hierarchy
- Update `geometry.firstMaterial?.diffuse.contents`

**Acceptance Criteria:**
- [ ] New markers show inherited color (or red if no nearby data)
- [ ] Color updates to yellow/green/blue after valid sessions
- [ ] Color transitions are immediate (no animation needed initially)

**Dependencies:** Milestones 2, 6

**Estimated complexity:** Medium

---

### Milestone 9: Spatial Merge Logic

**Goal:** Implement merge zone (0-3cm) with weighted averaging and inheritance zone (3-50cm).

**Tasks:**
1. In `SurveyPointStore.addSession()`:
   - Find nearest existing point to incoming coordinates
   - If within 3cm: merge into existing point with weighted coordinate averaging
   - If 3-50cm: create new point (inheritance is display-only)
   - If >50cm: create new point, no inheritance
2. Add method `nearestPoint(to:)` → (SurveyPoint?, distance)
3. Add method `inheritedQuality(at:)` → SurveyPointQuality? with decay
4. Implement weighted coordinate averaging:
   - Track `weightedSumX`, `weightedSumY` in SurveyPoint
   - On merge: add (newX × newDwellTime) to weightedSumX, same for Y
   - Recalculate `mapX = weightedSumX / totalDwellTime_s`
5. Update point's `id` handling (id stays constant even as coordinates drift)

**Acceptance Criteria:**
- [ ] Sessions at nearly-identical coordinates merge correctly
- [ ] Merged point coordinates drift toward weighted centroid
- [ ] New points are created beyond 3cm threshold
- [ ] Inheritance decay is linear from 3cm (100%) to 50cm (0%)
- [ ] Point `id` remains stable across merges

**Dependencies:** Milestone 1

**Estimated complexity:** Medium

---

### Milestone 10: Integration & Polish

**Goal:** Wire everything together and verify end-to-end flow.

**Tasks:**
1. Instantiate `SurveySessionCollector` in app bootstrap
2. Wire to `BluetoothScanner` and ARKit coordinator
3. Inject `SurveyPointStore` reference
4. Add console logging for debugging
5. Test complete flow: enter → dwell → exit → color update
6. Clean up temporary diagnostics

**Acceptance Criteria:**
- [ ] Complete dwell session persists all expected data
- [ ] Sphere color reflects accumulated quality
- [ ] No memory leaks or retain cycles
- [ ] No threading violations
- [ ] Console output shows clear session lifecycle

**Dependencies:** All previous milestones

**Estimated complexity:** Medium

---

## Dependency Graph

```
                    ┌─────────────────┐
                    │  Milestone 1    │
                    │  Data Structs   │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
              ▼              ▼              ▼
     ┌────────────┐  ┌────────────┐  ┌────────────┐
     │ Milestone 2│  │ Milestone 9│  │            │
     │ Collector  │  │ Spatial    │  │            │
     └──────┬─────┘  │ Merge      │  │            │
            │        └────────────┘  │            │
     ┌──────┴──────┐                 │            │
     │             │                 │            │
     ▼             ▼                 │            │
┌─────────┐  ┌─────────┐            │            │
│ Mile. 3 │  │ Mile. 5 │            │            │
│ BLE Wire│  │ Compass │            │            │
└────┬────┘  └────┬────┘            │            │
     │            │                 │            │
     ▼            │                 │            │
┌─────────┐       │                 │            │
│ Mile. 4 │       │                 │            │
│ Pose    │       │                 │            │
└────┬────┘       │                 │            │
     │            │                 │            │
     ├────────────┤                 │            │
     │            │                 │            │
     ▼            ▼                 │            │
┌─────────────────────┐             │            │
│    Milestone 6      │             │            │
│  Angular Coverage   │             │            │
└──────────┬──────────┘             │            │
           │                        │            │
           │    ┌───────────────────┘            │
           │    │                                │
           ▼    ▼                                │
     ┌─────────────┐                             │
     │ Milestone 7 │                             │
     │ Statistics  │                             │
     └──────┬──────┘                             │
            │                                    │
            ▼                                    │
     ┌─────────────┐                             │
     │ Milestone 8 │◄────────────────────────────┘
     │ Sphere Color│
     └──────┬──────┘
            │
            ▼
     ┌─────────────┐
     │ Milestone 10│
     │ Integration │
     └─────────────┘
```

---

## Future Work (Post-Integration)

These are explicitly **out of scope** for this implementation phase:

### Export Pipeline
- JSON export of all sessions
- Share sheet integration
- Purge after export confirmation

### Map Quality Overlay
- 2D visualization of data coverage on floor plan
- Heat map showing quality levels
- Toggle overlay on/off

### Analysis Tooling
- Off-device Python/Jupyter exploration
- Fingerprint extraction algorithms
- Body shadow correlation analysis

### Baked Model Import
- Compact fingerprint format
- Import from central database
- Version management

### Live Positioning
- Real-time BLE monitoring
- Fingerprint matching algorithm
- Position estimation with confidence

---

## Files to Create/Modify

### New Files
- `SurveySessionCollector.swift` — Dwell session lifecycle management

### Modified Files
- `SurveyPointStore.swift` — Updated data structures, spatial logic
- `SurveyMarker.swift` — Color update method
- `ARMarkerRenderer.swift` — Possibly, for dynamic color support
- `BluetoothScanner.swift` — Callback forwarding during dwell
- `AppBootstrap.swift` or `TapResolverApp.swift` — Collector instantiation

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Threading violations (BLE callback + ARKit) | Medium | High | Ensure all ARKit access on main thread |
| BLE callback frequency too low | Low | Medium | Longer dwell times, beacon interval tuning |
| Quaternion → heading conversion errors | Medium | Medium | Unit tests, visual debugging |
| Large data size slows persistence | Low | Low | Async save, batch updates |
| Color update flicker | Low | Low | Debounce or threshold changes |

---

## Success Metrics

After Milestone 10 is complete:

1. **Data capture works:** User can dwell in Survey Marker, exit, and see session persisted
2. **Pose is accurate:** Exported data shows meaningful position/orientation values
3. **Quality accumulates:** Multiple sessions increase quality metrics correctly
4. **Visual feedback works:** Sphere color reflects data quality
5. **Spatial rules work:** Near-identical positions merge; distant positions don't
6. **No regressions:** Existing AR calibration functionality unaffected
