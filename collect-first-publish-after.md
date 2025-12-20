# Collect First, Publish After: A Pattern for Real-Time Data Systems

**Project:** TapResolver  
**Date:** December 18, 2024  
**Context:** Lessons learned from survey marker performance optimization

---

## The Philosophy

When building systems that process real-time data streams, separate the concerns of **collection** and **publication**:

- **Collection:** Capturing raw data as it arrives, with minimal processing
- **Publication:** Broadcasting processed data to interested consumers

These should be decoupled in both timing and responsibility. The component that collects data should not be the same code path that triggers UI updates, Combine notifications, or other reactive side effects.

**The core insight:** Data arrives on its own schedule. Publication should happen on YOUR schedule.

---

## Why This Matters

### The Problem with Fused Collection/Publication

When collection and publication are fused, you inherit the worst characteristics of both:

```
External data source (unpredictable timing)
    ↓
Single code path that both:
    - Stores the data
    - Triggers @Published / Combine / UI updates
    ↓
Reactive cascade (SwiftUI redraws, subscriber notifications)
    ↓
Main thread pressure proportional to data arrival rate
```

If data arrives in bursts (common with Bluetooth, network, sensors), your UI layer experiences those same bursts. If the main thread is briefly busy, callbacks queue up and fire all at once when it unblocks — creating artificial bursts even from steady data sources.

### The Solution: Decouple Timing

```
External data source (unpredictable timing)
    ↓
Collection: Store to buffer (minimal work, no side effects)
    ↓
[Time passes, data accumulates]
    ↓
Publication: Process buffer, notify consumers (YOUR schedule)
    ↓
Predictable, controlled main thread usage
```

Publication happens when YOU decide, not when the data source decides.

---

## Case Study: BLE Data During Survey Dwell

### The Original Architecture

```swift
// BluetoothScanner.swift - CoreBluetooth delegate
func centralManager(_ central: CBCentralManager,
                    didDiscover peripheral: CBPeripheral, ...) {
    
    // FUSED: Collection and publication in same code path
    devices[idx].rssi = rssi           // Store data
    devices[idx].lastSeen = Date()     // ← Triggers @Published
}
```

Every Bluetooth advertisement updated an `@Published` array, triggering Combine notifications. With 4 beacons advertising at 4Hz each, that's 16 Combine notifications per second — plus the "burst" phenomenon when callbacks queued during main thread work.

**Observed behavior:**
```
10:46:00.152 | handleBLEUpdate | devices=3
10:46:00.152 | handleBLEUpdate | devices=3
10:46:00.152 | handleBLEUpdate | devices=3
... (18 notifications within 1 millisecond)
```

This is physically impossible for real Bluetooth timing. The bursts occurred because:
1. Main thread was briefly busy (ARKit frame, SceneKit render, etc.)
2. CoreBluetooth queued callbacks
3. Main thread unblocked
4. All queued callbacks fired, each triggering Combine
5. 18 notifications arrived "simultaneously"

**Impact:** Timer callbacks couldn't fire during these bursts. A dwell timer that should show 4.7 seconds showed 0.6 seconds — running at only 13% of real time.

### The Refactored Architecture

```swift
// BluetoothScanner.swift - CoreBluetooth delegate
func centralManager(_ central: CBCentralManager,
                    didDiscover peripheral: CBPeripheral, ...) {
    
    // SEPARATED: Collection path during active survey
    if let collector = surveyCollector, collector.isCollecting {
        collector.ingestBLEData(beaconID: name, rssi: rssi)  // Direct call
        return  // Skip @Published entirely
    }
    
    // Normal path: Publication for UI consumers (when not surveying)
    devices[idx].rssi = rssi
}
```

```swift
// SurveySessionCollector.swift - Collection endpoint
func ingestBLEData(beaconID: String, rssi: Int) {
    guard isCollecting else { return }
    guard whitelist.contains(beaconID) else { return }
    
    // Throttle to 4Hz
    let now = CACurrentMediaTime()
    guard now - lastSampleTime[beaconID] >= 0.250 else { return }
    lastSampleTime[beaconID] = now
    
    // Buffer the sample (no publication)
    ingestSample(beaconID: beaconID, rssi: rssi, pose: currentPose)
}
```

**Collection** happens via direct function call — no Combine, no @Published, no SwiftUI reactivity.

**Publication** happens once, when the survey session ends:
```swift
func endSession() {
    // Process buffered data
    let session = activeSession
    
    // Publish to store (single write)
    store.addSession(processedSession, atMapCoordinate: coordinate)
}
```

**Observed behavior after refactor:**
```
18:19:09.738 | ingestSample | beacon=17-thorny...
18:19:10.342 | ingestSample | beacon=18-mighty...  (0.6s later)
18:19:11.208 | ingestSample | beacon=14-jazzy...   (0.9s later)
```

Steady cadence. No bursts. Timer accuracy: 100%.

---

## The Pattern Generalized

### Data Flow Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    DATA SOURCES                             │
│  (unpredictable timing, potentially bursty)                 │
├─────────────────┬─────────────────┬─────────────────────────┤
│  CoreBluetooth  │     ARKit       │   Other Sensors         │
│   (BLE RSSI)    │  (Device Pose)  │   (Compass, etc.)       │
└────────┬────────┴────────┬────────┴────────┬────────────────┘
         │                 │                 │
         │ ingestBLEData() │ ingestPose()    │ ingestSensor()
         │                 │                 │
         ▼                 ▼                 ▼
┌─────────────────────────────────────────────────────────────┐
│                 COLLECTION LAYER                            │
│           (SurveySessionCollector)                          │
│                                                             │
│  Responsibilities:                                          │
│  • Receive raw data via direct function calls               │
│  • Filter (whitelist, validity checks)                      │
│  • Throttle (rate limiting per source)                      │
│  • Buffer (accumulate samples in memory)                    │
│  • Timestamp (associate with session timeline)              │
│                                                             │
│  Does NOT:                                                  │
│  • Trigger @Published updates                               │
│  • Send Combine notifications                               │
│  • Cause SwiftUI redraws                                    │
└─────────────────────────────┬───────────────────────────────┘
                              │
                              │ [Session ends]
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                 PUBLICATION LAYER                           │
│                                                             │
│  Triggered by:                                              │
│  • Session completion                                       │
│  • Explicit user action                                     │
│  • Timed interval (if needed)                               │
│                                                             │
│  Actions:                                                   │
│  • Process buffered data (compute statistics)               │
│  • Write to persistent store                                │
│  • Update @Published properties                             │
│  • Trigger UI refresh (once, controlled)                    │
└─────────────────────────────────────────────────────────────┘
```

### Key Principles

1. **Direct injection over subscription**
   - Data sources call collector methods directly
   - Avoid Combine/publisher subscriptions for high-frequency data
   - Function calls are cheaper than reactive machinery

2. **Filter at the collection point**
   - The collector decides what data to keep
   - Data sources stay generic ("here's what I received")
   - Filtering rules live with the component that uses the data

3. **Throttle before buffering**
   - Apply rate limits during collection, not after
   - Prevents buffer bloat from bursty sources
   - Maintains predictable memory usage

4. **Buffer in memory, publish on completion**
   - Accumulate samples without side effects
   - Single publication event when session ends
   - Batch writes are more efficient than incremental

5. **Publication is an explicit action**
   - Never publish as a side effect of collection
   - The collector controls when publication happens
   - UI updates happen on YOUR schedule

---

## Implementation Checklist

When adding a new data source to the collection system:

### Collection Side

- [ ] Create `ingestXxx()` method in collector
- [ ] Add validity checks (null, range, format)
- [ ] Add filtering logic (whitelist, relevance)
- [ ] Add throttling (rate limit per source)
- [ ] Buffer to in-memory structure
- [ ] NO @Published updates in this path
- [ ] NO Combine notifications in this path

### Source Side

- [ ] Add weak reference to collector
- [ ] Check `collector.isCollecting` before injection
- [ ] Call `collector.ingestXxx()` directly
- [ ] Skip normal publication path during collection
- [ ] Maintain normal path for non-collection use cases

### Publication Side

- [ ] Trigger on explicit session end
- [ ] Process buffered data (statistics, aggregation)
- [ ] Single write to persistent store
- [ ] Clear buffers after successful write
- [ ] Update @Published properties (once)

---

## Performance Results

### Before: Fused Collection/Publication

| Metric | Value |
|--------|-------|
| Combine notifications during dwell | ~200/session |
| Timestamp clustering | 10-20 in 1ms |
| Timer accuracy | 13-67% |
| Main thread pressure | High, unpredictable |

### After: Separated Collection/Publication

| Metric | Value |
|--------|-------|
| Combine notifications during dwell | **0** |
| Timestamp clustering | **None (steady cadence)** |
| Timer accuracy | **100%** |
| Main thread pressure | **Low, predictable** |

---

## Future Applications

This pattern scales to additional data sources:

### Pose Data (Planned)
```swift
// ARViewContainer - ARSession delegate
func session(_ session: ARSession, didUpdate frame: ARFrame) {
    if let collector = surveyCollector, collector.isCollecting {
        let pose = extractPose(from: frame.camera.transform)
        collector.ingestPoseData(pose: pose, timestamp: frame.timestamp)
        return
    }
    // Normal AR processing...
}
```

### Sensor Fusion (Future)
```swift
// Unified collection of BLE + Pose + Compass
func ingestBLEData(...)   // 4 Hz
func ingestPoseData(...)  // 10 Hz (throttled from 60)
func ingestCompass(...)   // 1 Hz

// All streams buffer independently
// Publication merges them into unified survey record
```

---

## Anti-Patterns to Avoid

### ❌ Publishing on every collection event

```swift
// BAD: Every BLE callback triggers UI
func didDiscover(...) {
    devices[idx].rssi = rssi  // @Published fires
}
```

### ❌ Subscribing to high-frequency publishers

```swift
// BAD: Combine subscription to bursty source
scanner.$devices
    .sink { devices in
        self.processAll(devices)  // Called 200 times/session
    }
```

### ❌ Filtering after publication

```swift
// BAD: Publish everything, filter in subscriber
// (Combine machinery runs for data you'll discard)
```

### ❌ Throttling at the wrong layer

```swift
// BAD: Throttle in UI, not collection
// (Data still flows through Combine, just displayed less often)
```

---

## Summary

**Collect first, publish after** is not just an optimization — it's an architectural principle that keeps real-time data systems responsive and predictable.

The key insight: **Reactive frameworks (Combine, SwiftUI) are designed for UI state, not high-frequency data streams.** When you force sensor data through reactive pipelines, you inherit timing characteristics you can't control.

By separating collection (raw data in) from publication (processed data out), you gain:
- Predictable main thread usage
- Immunity to source timing bursts
- Clear responsibility boundaries
- Easier testing and debugging
- Foundation for multi-source fusion

The pattern requires slightly more explicit code (direct function calls instead of subscriptions), but the reliability and performance gains are substantial.

---

## References

- `BluetoothScanner.swift` — Direct injection implementation
- `SurveySessionCollector.swift` — Collection layer with throttling and buffering
- `survey-marker-performance-learnings.md` — Detailed debugging journey
- `ble-direct-injection-instructions.md` — Implementation instructions
