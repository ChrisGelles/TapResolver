# Survey Marker RSSI Data Collection Model

## Purpose

The Survey Marker system collects Bluetooth Low Energy (BLE) signal strength data at precisely known spatial locations within an AR-calibrated environment. The goal is to build a comprehensive dataset that correlates:

- **Signal strength (RSSI)** from multiple BLE beacons
- **Device position** in 3D space (AR coordinates)
- **Device orientation** (which direction the camera faces)
- **Time** (millisecond-precision timestamps)

This data enables analysis of how device orientation affects signal reception ("body shadow" effects), supports building positioning heatmaps, and allows research into RSSI-based indoor positioning accuracy.

---

## Core Concept: Event-Driven Sampling

Unlike fixed-rate sampling (e.g., 60Hz), this model uses **event-driven sampling**. Data is recorded only when a BLE beacon advertisement is received. This approach:

1. **Directly correlates** each RSSI reading with the exact device pose at that moment
2. **Captures natural signal patterns** including gaps between advertisements
3. **Reduces storage** by not recording redundant pose data when no signal is received
4. **Preserves timing characteristics** of each beacon's advertising interval

### How BLE Advertising Works

BLE beacons broadcast advertisement packets at configured intervals (typically 100ms to 1000ms). Each advertisement received by the device triggers a CoreBluetooth callback containing:

- Beacon identifier (UUID)
- RSSI value (signal strength in dBm)
- Implicit timestamp (when callback fires)

The device does not receive "raw radio signals" or "echoes" - the Bluetooth hardware resolves multipath interference into a single RSSI value per advertisement. However, RSSI variance over time reflects environmental factors including multipath, orientation, and body shadowing.

---

## Data Hierarchy

```
Location (e.g., "museum")
  └── SurveyPoint (keyed by 2D map coordinate)
        └── sessions: [SurveySession]
              ├── Metadata (id, timing, location)
              ├── Reference pose (summary)
              └── beacons: [SurveyBeaconMeasurement]
                    ├── Beacon identity & metadata
                    ├── Statistical summary (computed on exit)
                    ├── Histogram (computed on exit)
                    └── samples: [RssiPoseSample]  ← Raw timeline
                          ├── Timestamp (ms)
                          ├── RSSI (dBm)
                          └── Device pose (position + orientation)
```

---

## Data Structures

### RssiPoseSample

The atomic unit of collected data. One sample is created each time a BLE advertisement is received during a dwell session.

```swift
public struct RssiPoseSample: Codable, Equatable {
    public let ms: Int64      // Milliseconds since dwell session started
    public let rssi: Int      // Signal strength in dBm, or 0 for boundary marker
    
    // Device position in AR session coordinate space (meters)
    public let x: Float       // Left/right from AR session origin
    public let y: Float       // Up/down (height) from AR session origin
    public let z: Float       // Forward/back from AR session origin
    
    // Device orientation as quaternion (unitless, normalized)
    public let qx: Float      // Quaternion X component
    public let qy: Float      // Quaternion Y component
    public let qz: Float      // Quaternion Z component
    public let qw: Float      // Quaternion W component (scalar)
}
```

#### Field Details

| Field | Type | Description |
|-------|------|-------------|
| `ms` | Int64 | Milliseconds elapsed since dwell session began. Shared timebase across all beacons in a session. |
| `rssi` | Int | Received Signal Strength Indicator in dBm. Typical range: -100 (weak) to -30 (strong). Value of 0 indicates a session boundary marker, not an actual reading. |
| `x, y, z` | Float | Device camera position in the current AR session's coordinate frame. Units are meters. Origin is where ARKit initialized. |
| `qx, qy, qz, qw` | Float | Device camera orientation encoded as a unit quaternion. Represents which direction the device is facing in 3D space. |

#### Quaternion Primer

A quaternion encodes 3D rotation without gimbal lock. The four components satisfy: `qx² + qy² + qz² + qw² = 1`

- **Identity** (no rotation): `qw=1, qx=qy=qz=0`
- **qw** is the cosine of half the rotation angle
- **qx, qy, qz** encode the rotation axis scaled by sine of half the angle

For analysis, quaternions can be converted to:
- **Euler angles** (yaw/pitch/roll) for human interpretation
- **Direction vectors** (e.g., "forward" vector) for body shadow analysis
- **Rotation matrices** for geometric transformations

#### Session Boundary Markers

Each beacon's sample timeline is **bookended** with `rssi = 0` markers:

```
Timeline:  [0ms, rssi=0] → [150ms, rssi=-72] → ... → [800ms, rssi=0]
              ↑                                           ↑
           Enter marker                              Exit marker
```

This creates clean interpolation boundaries when visualizing the data:
- The signal "ramps up" from zero at session start
- The signal "ramps down" to zero at session end
- Flat zero segments indicate no signal was received

---

### SurveyBeaconMeasurement

Aggregates all data collected for one beacon during one dwell session.

```swift
public struct SurveyBeaconMeasurement: Codable, Equatable {
    public let beaconID: String
    public let stats: SurveyStats
    public let histogram: SurveyHistogram
    public let samples: [RssiPoseSample]
    public let meta: SurveyBeaconMeta
}
```

#### Field Details

| Field | Type | Description |
|-------|------|-------------|
| `beaconID` | String | Unique identifier for this beacon (typically UUID string or device name) |
| `stats` | SurveyStats | Statistical summary computed when dwell session ends |
| `histogram` | SurveyHistogram | RSSI distribution in 1dB bins, computed when dwell session ends |
| `samples` | [RssiPoseSample] | Raw timeline of all readings, bookended with rssi=0 markers |
| `meta` | SurveyBeaconMeta | Beacon metadata: name, model, TX power, advertising interval |

---

### SurveyStats

Statistical summary of RSSI readings for one beacon during one session. Computed when the user exits the Survey Marker sphere.

```swift
public struct SurveyStats: Codable, Equatable {
    public let median_dbm: Int        // Median RSSI value
    public let mad_db: Int            // Median Absolute Deviation
    public let p10_dbm: Int           // 10th percentile (weak signals)
    public let p90_dbm: Int           // 90th percentile (strong signals)
    public let sampleCount: Int       // Total valid samples (excluding markers)
}
```

#### Why These Statistics?

- **Median** is robust against outliers (unlike mean)
- **MAD** (Median Absolute Deviation) measures signal stability
- **p10/p90** capture the typical range without extreme values
- **sampleCount** indicates data quality (more samples = more reliable)

---

### SurveyHistogram

Distribution of RSSI values in 1dB bins. Useful for visualizing signal characteristics and detecting multimodal distributions (which might indicate multipath interference).

```swift
public struct SurveyHistogram: Codable, Equatable {
    public let binMin_dbm: Int       // Typically -100
    public let binMax_dbm: Int       // Typically -30
    public let binSize_db: Int       // Typically 1
    public let counts: [Int]         // Count per bin
}
```

Example: If `binMin=-100`, `binMax=-30`, `binSize=1`, then `counts` has 71 elements. `counts[0]` is the count of readings at -100 dBm, `counts[70]` is the count at -30 dBm.

---

### SurveyBeaconMeta

Metadata about the beacon, captured at survey time for reference.

```swift
public struct SurveyBeaconMeta: Codable, Equatable {
    public let name: String                    // Human-readable name
    public let model: String                   // Beacon hardware model
    public let txPower: Int?                   // Configured TX power (dBm)
    public let advertisingInterval_ms: Int?    // Configured advertising interval
}
```

---

### SurveyDevicePose

A single reference pose for the session (legacy/summary field). The detailed pose data lives in each `RssiPoseSample`.

```swift
public struct SurveyDevicePose: Codable, Equatable {
    public let x: Float
    public let y: Float
    public let z: Float
    public let qx: Float
    public let qy: Float
    public let qz: Float
    public let qw: Float
}
```

This might represent:
- Pose at session start
- Average pose during session
- Pose at session midpoint

Retained for backward compatibility and quick reference.

---

### SurveySession

One complete data collection session at a Survey Marker location.

```swift
public struct SurveySession: Codable, Identifiable, Equatable {
    public let id: String                      // UUID string
    public let locationID: String              // Which location (e.g., "museum")
    
    // Timing
    public let startISO: String                // ISO8601 timestamp
    public let endISO: String                  // ISO8601 timestamp
    public let duration_s: Double              // Session duration in seconds
    
    // Reference pose (summary)
    public let devicePose: SurveyDevicePose
    
    // Per-beacon measurements
    public let beacons: [SurveyBeaconMeasurement]
}
```

---

### SurveyPoint

A survey location identified by its 2D map coordinates. Accumulates multiple sessions over time.

```swift
public struct SurveyPoint: Codable, Identifiable, Equatable {
    public let id: String                      // Derived from coordinates
    public let mapX: Double                    // X coordinate on floor plan (pixels)
    public let mapY: Double                    // Y coordinate on floor plan (pixels)
    public var sessions: [SurveySession]       // All collection sessions at this point
}
```

---

## Recording Workflow

### 1. Survey Marker Placement

Survey Markers are placed in AR space at known map coordinates. Each marker has:
- A 3D position in AR session coordinates
- A corresponding 2D position on the floor plan map
- A collision sphere the user "enters" with their device

### 2. Dwell Session Start

When the device enters a Survey Marker's collision sphere:

1. `SurveyMarkerEntered` notification fires
2. Session timer begins (ms counter starts at 0)
3. For each known beacon, insert an `rssi = 0` boundary marker with current pose
4. Begin capturing BLE advertisements

### 3. During Dwell

Each time a BLE advertisement callback fires:

1. Get current ARKit camera transform (position + orientation)
2. Calculate elapsed ms since session start
3. Create `RssiPoseSample` with:
   - `ms`: elapsed time
   - `rssi`: value from callback
   - `x, y, z`: current position
   - `qx, qy, qz, qw`: current orientation
4. Append to the appropriate beacon's sample buffer

### 4. Dwell Session End

When the device exits the Survey Marker's collision sphere:

1. `SurveyMarkerExited` notification fires
2. For each beacon with samples:
   - Insert final `rssi = 0` boundary marker with current pose
   - Compute `SurveyStats` from valid samples
   - Compute `SurveyHistogram` from valid samples
   - Package into `SurveyBeaconMeasurement`
3. Create `SurveySession` with all measurements
4. Append session to the `SurveyPoint` for this location
5. Persist to storage

---

## Example Data

### Single Session Timeline (One Beacon)

```
ms      rssi    x       y       z       qw      qx      qy      qz
--------------------------------------------------------------------
0       0       -0.41   0.65    -0.27   0.99    0.01    0.02    0.01   ← Enter
152     -68     -0.41   0.65    -0.27   0.99    0.01    0.02    0.01
289     -71     -0.42   0.65    -0.26   0.98    0.02    0.03    0.01
445     -67     -0.42   0.66    -0.26   0.97    0.03    0.05    0.02
598     -72     -0.41   0.66    -0.27   0.96    0.04    0.07    0.02
751     -69     -0.41   0.65    -0.27   0.97    0.03    0.05    0.01
890     -70     -0.42   0.65    -0.26   0.98    0.02    0.03    0.01
1045    -68     -0.42   0.65    -0.26   0.99    0.01    0.02    0.01
1200    0       -0.42   0.65    -0.26   0.99    0.01    0.02    0.01   ← Exit
```

### Computed Statistics

From the above 7 valid readings (excluding boundary markers):

```
median_dbm: -69
mad_db: 2
p10_dbm: -72
p90_dbm: -67
sampleCount: 7
```

### Histogram (partial)

```
binMin_dbm: -100
binMax_dbm: -30
counts[28]: 1   // -72 dBm (one reading)
counts[29]: 1   // -71 dBm (one reading)
counts[30]: 1   // -70 dBm (one reading)
counts[31]: 2   // -69 dBm (two readings)
counts[32]: 2   // -68 dBm (two readings)
counts[33]: 1   // -67 dBm (one reading)
// All other bins: 0
```

---

## Analysis Possibilities

### Body Shadow Detection

By correlating device orientation (quaternion) with RSSI variance:

1. Convert quaternion to a "forward" direction vector
2. Calculate angle between device forward and beacon direction
3. Plot RSSI vs. angle
4. Identify if signal drops when body is between device and beacon

### Position Verification

The pose data allows verification that the user held the device reasonably still:

1. Calculate position variance during session
2. Flag sessions with excessive movement
3. Weight or discard unstable sessions

### Beacon Characterization

Multiple sessions at the same point reveal:

1. Beacon advertising consistency
2. Environmental noise patterns
3. Time-of-day variations (if sessions span different times)

### Positioning Algorithm Training

The combined dataset enables:

1. Fingerprinting (RSSI pattern → known location)
2. Trilateration refinement (known position → calibrate distance model)
3. Orientation-aware positioning (correct for body shadow)

---

## Storage Considerations

### Per-Sample Size

Each `RssiPoseSample` contains:
- 1 Int64 (8 bytes)
- 1 Int (8 bytes on 64-bit)
- 7 Floats (28 bytes)

Total: ~44 bytes per sample

### Typical Session Size

Assuming:
- 3-second dwell duration
- 5 beacons detected
- 10 advertisements per beacon per second

Data generated:
- 150 samples × 44 bytes = ~6.6 KB raw samples
- Plus stats, histogram, metadata: ~1 KB per beacon
- Plus session metadata: ~200 bytes

**Total per session: ~12 KB**

### Scalability

- 100 survey points × 3 sessions each × 12 KB = ~3.6 MB per location
- Acceptable for on-device storage
- JSON compression would reduce by ~60-70%

---

## Future Enhancements

### Considered but Deferred

1. **Automatic gap markers**: Insert `rssi = 0` when beacon goes silent for > 2× advertising interval. Deferred in favor of simpler start/end bookends.

2. **Fixed-rate pose sampling**: Record pose at constant rate regardless of BLE events. Rejected as it doesn't correlate directly with signal data.

3. **Raw sample storage only**: Defer stats/histogram computation to analysis time. Rejected because on-device computation at dwell exit is cheap and provides immediate feedback.

### Possible Additions

1. **Magnetic heading**: Capture compass bearing alongside quaternion for absolute orientation reference.

2. **Acceleration data**: Detect if user was walking vs. standing still.

3. **Multiple session aggregation**: Merge statistics across sessions at same point.
