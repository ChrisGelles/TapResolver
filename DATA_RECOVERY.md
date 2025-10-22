# Map Point Data Recovery

## Incident Summary

**Date:** October 22, 2025  
**Issue:** Location switching bug caused map point data loss in UserDefaults while session JSON files remained intact on disk.

**Root Cause:** During location switching, `MapPointStore.clearAndReloadForActiveLocation()` cleared in-memory data before loading, and if anything interrupted the load process, empty data was saved to UserDefaults, overwriting existing map points.

**Impact:** Map points disappeared from UI, but 60 session JSON files remained in `/Documents/locations/museum/Scans/` directory.

---

## Recovery Process

### Prerequisites
- Session JSON files exist in `/Documents/locations/{locationID}/Scans/`
- Old session files are in v1 format with fields:
  - `mapPointID` (UUID string)
  - `coordinatesX` (Double)
  - `coordinatesY` (Double)
  - `obinsPerBeacon` (histogram data)

### Step 1: Recover Map Points

```swift
// In Xcode console or via temporary UI button
mapPointStore.recoverFromSessionFiles()
```

**What it does:**
1. Scans `/Scans/` directory for JSON files
2. Extracts `mapPointID`, `coordinatesX`, `coordinatesY` from each file
3. Groups sessions by unique map point
4. Creates `MapPoint` objects with correct positions but empty sessions
5. Saves recovered points to UserDefaults

**Result:** Map points reappear at correct locations showing 0 sessions.

### Step 2: Reconnect Sessions

```swift
// After Step 1 completes successfully
mapPointStore.reconnectSessionFiles()
```

**What it does:**
1. Reads all session JSON files again
2. Converts old v1 format → current `ScanSession` format:
   - Parses `obinsPerBeacon` histogram bins
   - Calculates statistics (median, MAD, p10, p90)
   - Rebuilds histogram structure
   - Creates `BeaconData` with metadata
3. Groups converted sessions by map point ID
4. Attaches sessions to recovered map points
5. Saves complete data to UserDefaults

**Result:** Map points show correct session counts with full beacon data.

---

## Data Format Conversion

### Old V1 Format (Session JSON Files)
```json
{
  "mapPointID": "00C272BC-4703-4B16-BAAF-73C515BEAB5A",
  "coordinatesX": 3695.43,
  "coordinatesY": 4737.46,
  "startTime": "2025-10-15T13:52:29Z",
  "endTime": "2025-10-15T13:52:39Z",
  "duration": 10.001,
  "deviceHeight": 1.05,
  "interval": 500,
  "obinsPerBeacon": {
    "02-brightFalcon": [
      {"rssi": -65, "count": 15},
      {"rssi": -66, "count": 23},
      ...
    ]
  }
}
```

### Current ScanSession Format (UserDefaults)
```swift
ScanSession(
    scanID: "scan_2025-10-15T13-52-29Z_00C272BC...",
    sessionID: "F9315227-652D-41B7-B4C4-EDF56AE0EA46",
    pointID: "00C272BC-4703-4B16-BAAF-73C515BEAB5A",
    locationID: "museum",
    timingStartISO: "2025-10-15T13:52:29Z",
    timingEndISO: "2025-10-15T13:52:39Z",
    duration_s: 10.001,
    deviceHeight_m: 1.05,
    facing_deg: nil,
    beacons: [
        BeaconData(
            beaconID: "02-brightFalcon",
            stats: Stats(median_dbm: -66, mad_db: 2, ...),
            hist: Histogram(binMin_dbm: -80, binMax_dbm: -50, ...),
            samples: nil,  // Not available in v1 format
            meta: Metadata(name: "02-brightFalcon", model: "iPhone iOS", txPower: nil, msInt: 500)
        )
    ]
)
```

---

## Prevention Measures Implemented

### 1. Reload Protection Flag
```swift
private var isReloading: Bool = false
```
- Set to `true` during `clearAndReloadForActiveLocation()`
- Blocks all `save()` calls during reload
- Prevents race conditions

### 2. Empty Array Protection
```swift
// In save() method
if points.isEmpty {
    if let existingDTO = ctx.read(...), !existingDTO.isEmpty {
        print("🛑 Blocked save of empty array")
        return
    }
}
```
- Checks UserDefaults before saving empty array
- Blocks save if data exists
- Logs warning for debugging

### 3. Explicit Clear Method
```swift
public func clearAllPoints() {
    // Intentionally bypasses protection
    // Must be called explicitly
}
```
- For intentional deletion only
- Cannot happen accidentally

---

## Usage Instructions

### For Future Data Loss

1. **Verify session files exist:**
   ```bash
   # Check Scans directory
   ls /Documents/locations/{locationID}/Scans/
   ```

2. **Add temporary recovery UI:**
   ```swift
   // In MapPointLogView or debug menu
   Button("Recover Points") {
       mapPointStore.recoverFromSessionFiles()
   }
   Button("Reconnect Sessions") {
       mapPointStore.reconnectSessionFiles()
   }
   ```

3. **Run recovery:**
   - Tap "Recover Points" button
   - Check console for success message
   - Tap "Reconnect Sessions" button
   - Verify map points and sessions restored

4. **Remove temporary UI:**
   - Delete recovery buttons after successful recovery

### Programmatic Access

```swift
// Option 1: Console commands (via lldb or temporary code)
mapPointStore.recoverFromSessionFiles()
mapPointStore.reconnectSessionFiles()

// Option 2: Temporary view
struct DataRecoveryView: View {
    @EnvironmentObject var mapPointStore: MapPointStore
    
    var body: some View {
        VStack {
            Button("Step 1: Recover Points") {
                mapPointStore.recoverFromSessionFiles()
            }
            Button("Step 2: Reconnect Sessions") {
                mapPointStore.reconnectSessionFiles()
            }
        }
    }
}
```

---

## Technical Notes

### Sample Data Limitation
- Old v1 format stored histogram bins, not raw RSSI samples
- Converted sessions have `samples: nil`
- New scans after recovery will have `samples: [RssiSample]`
- Both formats coexist without issues (samples field is optional)

### Session File Naming
- Session files named by UUID: `{sessionID}.json`
- Located in: `/Documents/locations/{locationID}/Scans/`
- One file per scan session
- Files persist independently of UserDefaults

### Statistics Calculation
- Median, MAD, percentiles calculated from histogram bins
- Expands bins into individual RSSI values for accurate statistics
- MAD = Median Absolute Deviation (robust measure of variability)

---

## Files Modified

- `State/MapPointStore.swift` - Added protection flags and guards
- `Utils/MapDataRestoration.swift` - Recovery utilities (can be removed after use)

## Files Created

- `Utils/MapDataRestoration.swift` - Recovery code
- `DATA_RECOVERY.md` - This documentation

---

## Contact

For questions about this recovery process, refer to chat session: October 22, 2025

