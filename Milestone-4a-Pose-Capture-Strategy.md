# Milestone 4a: ARKit Pose Capture Strategy

## Overview

Replace placeholder identity poses with real ARKit camera transforms during Survey Marker dwell sessions. The architecture prioritizes minimal processing overhead during data capture by storing raw AR session coordinates with a "decipher key" for later conversion.

## Core Principle: Deferred Conversion

**Recording Time (4 Hz):**
- Copy 7 floats from `frame.camera.transform` (position + quaternion)
- No matrix multiplication, no coordinate conversion
- Raw values straight from ARKit

**Analysis Time (later):**
- Apply the session transform to convert raw poses → baked/canonical space
- Correlate with RSSI timestamps

This separation keeps the AR rendering loop unimpeded during data collection.

---

## Data Structures

### New: SessionTransformSnapshot (Codable)

Captures the "decipher key" — the transform relating this AR session's coordinate frame to canonical/baked space.

```swift
public struct SessionTransformSnapshot: Codable, Equatable {
    public let rotationY: Float        // Y-axis rotation (radians)
    public let translationX: Float     // Translation X
    public let translationY: Float     // Translation Y
    public let translationZ: Float     // Translation Z
    public let scale: Float            // AR meters / canonical meters
    
    public static let invalid = SessionTransformSnapshot(
        rotationY: 0, translationX: 0, translationY: 0, translationZ: 0, scale: 0
    )
}
```

### Modified: SurveySession

Add optional session transform field:

```swift
public struct SurveySession: Codable, Identifiable, Equatable {
    // ... existing fields ...
    
    // AR Session transform for converting poseTrack to canonical space
    public let sessionTransform: SessionTransformSnapshot?  // NEW
    
    // ... existing poseTrack, beacons, etc. ...
}
```

### Modified: SurveyDevicePose

Add convenience initializer for ARKit transform extraction:

```swift
extension SurveyDevicePose {
    /// Extract pose from ARKit camera transform matrix
    public init(transform: simd_float4x4) {
        // Position from translation column
        self.x = transform.columns.3.x
        self.y = transform.columns.3.y
        self.z = transform.columns.3.z
        
        // Quaternion from rotation matrix (single SIMD instruction)
        let quat = simd_quatf(transform)
        self.qx = quat.imag.x
        self.qy = quat.imag.y
        self.qz = quat.imag.z
        self.qw = quat.real
    }
}
```

---

## Data Flow

### At Session Start (once)

```
User enters Survey Marker sphere
    │
    ├─► SurveyMarkerEntered notification
    │
    └─► SurveySessionCollector.startSession()
            │
            ├─► Capture session transform from ARCalibrationCoordinator
            │       arCalibrationCoordinator.getSessionTransformSnapshot()
            │
            └─► Capture initial pose from ARViewCoordinator
                    ARViewContainer.ARViewCoordinator.current?.getCurrentPose()
```

### At 4 Hz During Dwell

```
BLE update received
    │
    └─► handleBLEUpdate()
            │
            ├─► Get camera transform (7 floats, no math)
            │       ARViewContainer.ARViewCoordinator.current?.getCurrentPose()
            │
            └─► Append PoseSample to poseTrack
```

### At Session End

```
User exits Survey Marker sphere
    │
    └─► finalizeSession()
            │
            └─► Package into SurveySession:
                    - sessionTransform (decipher key)
                    - poseTrack (raw AR coordinates)
                    - beacons (RSSI data)
```

---

## Component Responsibilities

### ARCalibrationCoordinator
- Owns `cachedCanonicalToSessionTransform` (computed when 2 markers planted)
- Exposes `getSessionTransformSnapshot()` for survey capture
- Exposes `hasValidSessionTransform` boolean check

### ARViewContainer.ARViewCoordinator
- Static `current` reference (already exists)
- New `getCurrentPose() -> SurveyDevicePose?` method
- Accesses `sceneView.session.currentFrame?.camera.transform`

### SurveySessionCollector
- Receives `ARCalibrationCoordinator` via `configure()`
- Captures transform snapshot at session start
- Captures raw pose at 4 Hz via static coordinator reference
- Packages both into persisted `SurveySession`

---

## Validation (Future)

Survey Marker visual feedback progression:
- **Red** → No data or < 3 seconds
- **Yellow** → 3-9 seconds dwell time
- **Green** → 9+ seconds, limited angular coverage
- **Blue** → 9+ seconds AND 3+ facing sectors covered

Angular coverage computed from pose quaternions at analysis time, not during capture.

---

## Files Modified

| File | Changes |
|------|---------|
| `SurveyDataSchema.swift` | Add `SessionTransformSnapshot` struct, update `SurveySession` |
| `SurveyDevicePose` (in schema) | Add `init(transform:)` convenience initializer |
| `ARCalibrationCoordinator.swift` | Add `getSessionTransformSnapshot()` public method |
| `ARViewContainer.swift` | Add `getCurrentPose()` method to coordinator |
| `SurveySessionCollector.swift` | Inject coordinator, capture transform and poses |
| `TapResolverApp.swift` | Update `configure()` call to pass coordinator |

---

## Performance Characteristics

**Per-sample capture cost:**
- 3 float reads (position from matrix column)
- 1 SIMD operation (`simd_quatf` from matrix)
- 4 float reads (quaternion components)
- Array append

**Estimated time:** < 1 microsecond per sample

**No impact on:**
- AR rendering loop
- Plane detection
- Feature point tracking
- SceneKit node updates
