# kBeacon Integration Plan for TapResolver

## Overview

Integrate kbeaconlib2 SDK to read beacon configuration (TX power, advertising interval) directly from KBeacon devices, eliminating manual entry.

---

## Source Material

Working implementation exists in standalone app: `KBeaconSettings`
- Repository: `/Users/cgelles/Documents/GitHub/kbeacon-stuff/KBeaconSettings`
- Build guide and API fixes documented in `kbeacon-stuff-20251217-2200.txt`

---

## Components to Migrate

### From KBeaconSettings → TapResolver

| File | Purpose | Modifications |
|------|---------|---------------|
| `BeaconManager.swift` | SDK wrapper, scanning, connection | Rename to `KBeaconConnectionManager`, adapt to TapResolver architecture |
| `BeaconSettingsView.swift` | Connection UI, config reading | Split into BeaconInspector (debug) and BeaconList integration |
| `PasteFriendlyTextField.swift` | Password entry UIKit wrapper | Copy as-is (solves SwiftUI paste menu bug) |

---

## CocoaPods Setup Required

TapResolver currently does NOT use CocoaPods. Adding kbeaconlib2 requires:

### 1. Create Podfile
```ruby
platform :ios, '14.0'
use_frameworks!

target 'TapResolver' do
  pod 'kbeaconlib2', '~> 1.2.1'
end
```

### 2. Install
```bash
cd /path/to/TapResolver
pod install
```

### 3. Switch to Workspace
After `pod install`, always open `TapResolver.xcworkspace` (NOT `.xcodeproj`)

### 4. Build Settings Fixes
- `ENABLE_USER_SCRIPT_SANDBOXING = NO`
- May need to edit `Pods/.../Pods-TapResolver-frameworks.sh` to replace `rsync` with `cp`

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│              KBeaconConnectionManager               │
│  (Wraps kbeaconlib2, handles connect/read/write)    │
├─────────────────────────────────────────────────────┤
│  - scanForBeacons() → [KBeacon]                     │
│  - connect(beacon, password) → Bool                 │
│  - readConfiguration() → BeaconConfig               │
│  - disconnect()                                     │
│  - connectionState: Published<ConnectionState>      │
└─────────────────────────────────────────────────────┘
            ↑                           ↑
            │                           │
   ┌────────┴────────┐        ┌────────┴────────┐
   │ BeaconInspector │        │ BeaconListEditor │
   │   (Debug UI)    │        │ (Read from Device)│
   └─────────────────┘        └──────────────────┘
```

---

## UI Entry Points

### 1. Debug Settings Panel — "Beacon Inspector"
- Connect to any beacon in range
- Read TX power, interval, battery, firmware
- Diagnostic tool for troubleshooting
- Doesn't modify BeaconList data
- Useful for verifying beacon configuration

### 2. BeaconList Editor — Per-beacon "Read from Device"
- When editing a beacon entry, button to connect & read
- Auto-populates TX power and interval fields
- Requires beacon to be nearby and powered on
- Saves directly to BeaconList entry

---

## Password Storage Design

### Phase 1: Per-Location
```swift
// Store in Keychain, keyed by location ID
struct LocationBeaconAuth: Codable {
    let locationID: UUID
    var password: String
}

class BeaconPasswordStore {
    func getPassword(for locationID: UUID) -> String?
    func setPassword(_ password: String, for locationID: UUID)
    func deletePassword(for locationID: UUID)
}
```

All beacons at a location share one password. Simple UI.

### Phase 2: Per-Beacon (Future)
More granular, automated security. Different passwords per beacon.

---

## kbeaconlib2 API Notes

### Delegate Signatures (Swift quirks)
```swift
// Scanning callback
func onBeaconDiscovered(beacons: [KBeacon]) { }

// Bluetooth state
func onCentralBleStateChange(newState: BLECentralMgrState) {
    switch newState {
    case .PowerOn:  // Note: uppercase P
    case .PowerOff:
    default: break
    }
}

// Connection
beacon.connect(password, timeout: 15.0, delegate: self)

// Connection state delegate
extension KBeaconConnectionManager: ConnStateDelegate {
    func onConnStateChange(_ beacon: KBeacon, state: KBConnState, evt: KBConnEvtReason) {
        // Handle state changes
    }
}
```

### Reading Configuration
```swift
// TX Power from slot config
if let slotCfg = beacon.getSlotCfg(0) as? KBCfgAdvBase {
    let txPower = Int(slotCfg.getTxPower())
    let interval = slotCfg.getAdvPeriod()  // milliseconds
}
```

### RSSI Type
```swift
// RSSI is Int8, not Int32
func rssiColor(_ rssi: Int8) -> Color { }
```

---

## Data Flow: Read from Device

```
1. User taps "Read from Device" on beacon entry
2. KBeaconConnectionManager.connect(beacon, password)
3. On success: readConfiguration()
4. BeaconConfig returned with txPower, interval
5. Auto-populate BeaconList entry fields
6. disconnect()
7. User saves BeaconList
```

---

## Work Estimate

| Task | Effort |
|------|--------|
| Add CocoaPods + kbeaconlib2 | 30 min |
| Port BeaconManager → KBeaconConnectionManager | 1 hr |
| Port PasteFriendlyTextField | 10 min |
| Create BeaconInspectorView (Debug) | 1 hr |
| Add "Read from Device" to BeaconList editor | 1 hr |
| Password storage (Keychain, per-location) | 45 min |
| **Total** | ~4-5 hrs |

---

## Files Reference

### Existing KBeaconSettings files to reference:
- `KBeaconSettings/BeaconManager.swift` — Connection logic
- `KBeaconSettings/BeaconSettingsView.swift` — UI and config reading
- `KBeaconSettings/PasteFriendlyTextField.swift` — UIKit text field wrapper
- `KBeaconSettings/ContentView.swift` — Beacon list and scanning UI

### Build guide with all API fixes:
- `kbeacon-stuff-20251217-2200.txt` — Lines 120-200 cover API signature fixes

---

## Future Enhancements

1. **Write configuration** — Adjust TX power levels for optimal RSSI
2. **Battery monitoring** — Alert when beacon battery low
3. **Firmware info** — Track beacon versions
4. **Bulk configuration** — Apply settings to multiple beacons
5. **Per-beacon passwords** — Enhanced security model
