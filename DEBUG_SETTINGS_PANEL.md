# Debug Settings Panel Documentation

## Overview

The Debug Settings Panel is a comprehensive debugging and maintenance interface accessible from the main HUD. It provides toggles for debug overlays, diagnostic tools, data management functions, and recovery utilities.

**Location:** `TapResolver/UI/Root/HUDContainer.swift` (DebugSettingsPanel struct)

**Access:** Tap the gear icon (⚙️) in the main HUD to open/close the panel.

---

## Button Categories

The panel is organized into several functional categories:

1. **Debug Toggles** - Visual overlays and debug modes
2. **Data Purge Actions** - Destructive operations to clear specific data types
3. **User Position Tracking** - Settings for map following behavior
4. **Feature Flags** - Toggle UI features on/off
5. **Logging & Export** - Console log management and data export
6. **MapPoint Maintenance** - Duplicate detection and merging
7. **Beacon Management** - KBeacon inspection and configuration
8. **Data Recovery** - Recovery utilities for corrupted or missing data
9. **One-Time Cleanup** - Migration and cleanup utilities

---

## Debug Toggles

### 🔹 Facing
**Icon:** `location.north.fill`  
**Type:** Toggle  
**Color:** Primary (gray)

**Function:** Toggles the facing direction overlay on the map. Shows the user's current orientation/direction.

**State:** Visual indicator changes when active.

---

### 🔍 Reloc Debug
**Icon:** `location.magnifyingglass` / `location.magnifyingglass.fill`  
**Type:** Toggle  
**Color:** Primary (gray)

**Function:** Enables/disables relocalization debugging visualization. Shows debug information related to ARKit relocalization.

**State:** Icon fills when active.

---

### 🐜 Survey Trace
**Icon:** `ant.circle` / `ant.circle.fill`  
**Type:** Toggle  
**Color:** Green when enabled, Primary when disabled

**Function:** Enables/disables survey thread trace logging. When enabled, prints detailed trace information about survey operations to the console.

**Persistence:** State is saved to UserDefaults (`debug.surveyThreadTrace`).

**Console Output:** `🔍 Survey Thread Trace: ON/OFF`

---

### 📡 BLE Scan
**Icon:** `dot.radiowaves.left.and.right`  
**Type:** Toggle  
**Color:** Green when scanning, Gray when stopped

**Function:** Starts/stops continuous Bluetooth Low Energy scanning for beacons.

**Behavior:**
- When stopped: Calls `btScanner.startContinuous()`
- When scanning: Calls `btScanner.stopContinuous()`

---

## Diagnostic & Reset Actions

### 👁️ Diagnostic
**Icon:** `eye.fill`  
**Type:** Action  
**Color:** Blue

**Function:** Prints a comprehensive diagnostic report to the console showing what data will be affected by purge operations. Shows:
- Current location
- Triangle count and calibration status
- AR marker associations
- Files that will be affected
- Other locations that will NOT be affected

**Output:** Console diagnostic report with location isolation check.

---

### ❌ Soft Reset
**Icon:** `xmark.circle.fill`  
**Type:** Destructive Action (with confirmation)  
**Color:** Red

**Function:** Clears all calibration data for the current location while preserving triangle mesh structure.

**What it clears:**
- Triangle calibration flags (`isCalibrated = false`)
- AR marker associations (`arMarkerIDs = []`)
- Calibration quality scores
- Leg measurements
- World map file references
- Transform matrices
- Calibration timestamps

**What it preserves:**
- Triangle mesh structure (vertices, connectivity)
- 2D map coordinates
- Other locations' data

**Confirmation:** Shows alert with location-specific warning.

**Console Output:** Detailed reset report with before/after counts.

---

### 🗑️ Purge AR History
**Icon:** `trash.circle`  
**Type:** Destructive Action (with confirmation)  
**Color:** Orange

**Function:** Removes all AR position history records from all MapPoints for the current location.

**What it clears:**
- All `arPositionHistory` arrays from MapPoints
- Consensus position calculations (will be reset)

**What it preserves:**
- 2D map coordinates
- Triangle structure
- Canonical positions (if any)

**Confirmation:** Shows alert with count of records to be purged.

---

### 📍 Purge Canonical
**Icon:** `mappin.slash`  
**Type:** Destructive Action (with confirmation)  
**Color:** Red

**Function:** Clears all baked canonical positions from MapPoints.

**What it clears:**
- `canonicalPosition` from all MapPoints
- `canonicalConfidence` values
- `canonicalSampleCount` data

**Impact:** Ghost markers will fall back to barycentric interpolation until new calibration sessions rebuild canonical positions.

**Confirmation:** Shows alert with count of MapPoints that have canonical data.

**Result Alert:** Shows summary of cleared data.

---

### 🔄 Full Reset
**Icon:** `arrow.counterclockwise.circle.fill`  
**Type:** Destructive Action (with confirmation)  
**Color:** Red

**Function:** Performs both Soft Reset and Purge AR History in sequence.

**Operations:**
1. Clears all calibration data (Soft Reset)
2. Purges all AR position history

**What it preserves:**
- 2D map coordinates
- Triangle mesh structure

**Confirmation:** Shows alert explaining both operations.

---

### 📸 Purge Photos
**Icon:** `photo.on.rectangle.angled`  
**Type:** Destructive Action (with confirmation)  
**Color:** Orange

**Function:** Deletes all photo assets associated with MapPoints for the current location.

**What it clears:**
- All photo files stored for MapPoints
- Photo references in MapPoint data

**Confirmation:** Shows alert with count of photos to be deleted.

**Warning:** Cannot be undone.

---

### 🗑️ Purge Orphaned Triangles
**Icon:** `trash.slash`  
**Type:** Destructive Action (with confirmation)  
**Color:** Red

**Function:** Removes triangles that reference MapPoints which no longer exist.

**Process:**
- Compares triangle vertex IDs against current MapPoint IDs
- Deletes triangles with invalid references

**Confirmation:** Shows alert explaining the operation.

**Result Alert:** Shows count of removed triangles or "No orphaned triangles found".

---

### 🗑️ Purge Rigid Body Data
**Icon:** `arrow.triangle.2.circlepath.circle`  
**Type:** Destructive Action (with confirmation)  
**Color:** Red

**Function:** Purges all position data from the Triangle Patch / Rigid Body calibration era. Required before Zone Corner bilinear calibration migration.

**What it clears:**
- All canonical positions
- All AR history records

**What it preserves:**
- 2D coordinates
- Triangle topology

**Purpose:** Migration utility for transitioning from Triangle Patch to Zone Corner calibration system.

**Confirmation:** Shows detailed alert with counts of data to be purged.

---

## User Position Tracking

### 📍 PiP Follow
**Icon:** `location` / `location.fill`  
**Type:** Toggle  
**Color:** Green when enabled, Gray when disabled

**Function:** Toggles whether the Picture-in-Picture (PiP) map view follows the user's position.

**Setting:** `AppSettings.followUserInPiP`

---

### 🗺️ Map Follow
**Icon:** `map` / `map.fill`  
**Type:** Toggle  
**Color:** Green when enabled, Gray when disabled

**Function:** Toggles whether the main map view follows the user's position.

**Setting:** `AppSettings.followUserInMainMap`

---

## Feature Flags

### 📋 Map Log Panel
**Icon:** `list.bullet.rectangle` / `list.bullet.rectangle.fill`  
**Type:** Toggle  
**Color:** Green when enabled, Gray when disabled

**Function:** Shows/hides the Map Point Log Panel drawer in the main UI.

**Setting:** `FeatureFlags.showMapPointLogPanel`

---

## Logging & Export

### 📄 Export Log
**Icon:** `doc.text`  
**Type:** Action (opens share sheet)  
**Color:** Blue

**Function:** Exports the internal console log file for sharing/debugging.

**Output:** Opens iOS share sheet with log file URL.

**Source:** `FileLogger.shared.exportFileURL`

---

### 🗑️ Clear Log
**Icon:** `trash`  
**Type:** Action  
**Color:** Orange

**Function:** Clears the internal console log file.

**Console Output:** `Internal Log Cleared`

**Haptic Feedback:** Medium impact

---

### 📊 Storage Audit
**Icon:** `doc.badge.gearshape`  
**Type:** Action (opens share sheet)  
**Color:** Blue

**Function:** Generates and exports a comprehensive storage audit report for the current location.

**Contents:**
- MapPoint counts and storage sizes
- UserDefaults key analysis
- Data structure validation
- Storage location details

**Output:** Opens iOS share sheet with audit file URL.

**Function:** `UserDefaultsDiagnostics.exportStorageAudit()`

---

### 💾 Raw Export
**Icon:** `externaldrive`  
**Type:** Action (opens share sheet)  
**Color:** Purple

**Function:** Exports raw UserDefaults data as JSON for inspection.

**Output:** Opens iOS share sheet with UserDefaults dump file.

**Function:** `UserDefaultsDiagnostics.exportRawUserDefaults()`

---

### 🗺️ Export Map SVG
**Icon:** `map`  
**Type:** Action (opens share sheet)  
**Color:** Blue

**Function:** Exports the current map with MapPoints as an SVG file.

**Contents:**
- Map background image
- MapPoint positions and labels
- Triangle mesh overlay (if applicable)

**Output:** Opens iOS share sheet with SVG file URL.

---

## MapPoint Maintenance

### 🔍 Scan Duplicates
**Icon:** `magnifyingglass`  
**Type:** Action  
**Color:** Blue

**Function:** Scans for duplicate MapPoints and logs findings to console.

**Process:**
- Compares MapPoint positions
- Identifies points that are too close together
- Prints detailed report to console

**Console Output:** List of duplicate candidates with positions and IDs.

**Function:** `mapPointStore.logDuplicateMapPoints()`

**Haptic Feedback:** Medium impact

---

### 🔀 Merge Duplicates
**Icon:** `arrow.triangle.merge`  
**Type:** Action  
**Color:** Orange

**Function:** Automatically merges duplicate MapPoints found by the scan.

**Process:**
- Identifies duplicates
- Merges sessions and data
- Updates triangle references
- Removes duplicate points

**Returns:** Count of removed duplicates.

**Function:** `mapPointStore.mergeDuplicateMapPoints(triangleStore:)`

**Haptic Feedback:** Medium impact

---

### 🗑️ Clear Morgue History
**Icon:** `trash.slash`  
**Type:** Action  
**Color:** Orange

**Function:** Clears history from all morgue items and purges ephemeral items.

**Process:**
- Clears history from all beacon list items
- Purges ephemeral morgue entries

**Console Output:** `🧹 Morgue cleanup: cleared history from X items, purged Y ephemeral items`

**Haptic Feedback:** Medium impact

---

### 🗑️ Purge Surveys
**Icon:** `trash`  
**Type:** Action  
**Color:** Red

**Function:** Permanently deletes all survey point data.

**Function:** `surveyPointStore.purgeAll()`

**Haptic Feedback:** Medium impact

**Warning:** Cannot be undone.

---

## KBeacon Management

### 📡 Beacon Report
**Icon:** `antenna.radiowaves.left.and.right` / `antenna.radiowaves.left.and.right.circle.fill`  
**Type:** Action  
**Color:** Green when scanning, Blue when idle

**Function:** Generates a comprehensive report of discovered KBeacons.

**Process:**
- Scans for KBeacons
- Connects to each beacon sequentially
- Reads configuration and status
- Prints detailed report to console

**Console Output:** 
- Beacon discovery list
- Connection status for each beacon
- Configuration details (MAC address, model, firmware, etc.)
- Signal strength and battery status

**Function:** `runBeaconReport()`

**Haptic Feedback:** Medium impact

---

### ⚙️ Beacon Settings
**Icon:** `antenna.radiowaves.left.and.right.circle`  
**Type:** Action (opens panel)  
**Color:** Purple

**Function:** Opens the KBeacon Settings panel for detailed beacon configuration.

**Action:** Sets `hudPanels.isBeaconSettingsOpen = true`

**Haptic Feedback:** Medium impact

---

## Data Recovery

### 🔍 Diagnose Dots
**Icon:** `magnifyingglass.circle`  
**Type:** Action  
**Color:** Blue

**Function:** Runs comprehensive diagnostic on beacon dot storage.

**Checks:**
- `dots.json` file existence and contents
- UserDefaults storage (`BeaconDots_v1`, `BeaconDots_v2`)
- BeaconDotStore in-memory state
- Synchronization between storage locations
- Missing or orphaned entries

**Console Output:** Detailed diagnostic report showing:
- File vs UserDefaults comparison
- In-memory vs persisted comparison
- Missing entries in each location
- Sync status

**Function:** `diagnoseBeaconDots()`

---

### 🔄 Recover Dots
**Icon:** `arrow.counterclockwise.circle.fill`  
**Type:** Action  
**Color:** Orange

**Function:** Recovers beacon dot data from UserDefaults and writes to `dots.json` file.

**Process:**
- Reads from `BeaconDots_v1` UserDefaults key
- Writes recovered data to `dots.json`
- Triggers reload in BeaconDotStore

**Console Output:** Recovery report with count of recovered items.

**Function:** `recoverBeaconDotsFromUserDefaults()`

---

### 📋 Dump V2 Data
**Icon:** `doc.text.magnifyingglass`  
**Type:** Action  
**Color:** Cyan

**Function:** Prints all V2 beacon dot data to console in readable format.

**Contents:**
- Beacon ID
- Position (x, y)
- Elevation
- TxPower
- Advertising interval
- Lock status
- MAC address (if available)
- Model and firmware (if available)
- Last configuration read session

**Function:** `dumpV2Data()`

---

### 🔄 Force V2 Re-Migration
**Icon:** `arrow.triangle.2.circlepath`  
**Type:** Action  
**Color:** Orange

**Function:** Forces re-migration of beacon dot data to V2 format.

**Process:**
- Reads from `dots.json` file
- Reads from `BeaconDots_v1` UserDefaults
- Reads elevation and lock data from separate keys
- Combines into V2 structure
- Writes to `BeaconDots_v2` UserDefaults key
- Triggers reload

**Purpose:** Migration utility for updating beacon dot storage format.

**Function:** `forceV2Remigration()`

---

## One-Time Cleanup Utilities

### 👁️ Preview Cleanup
**Icon:** `eye.trianglebadge.exclamationmark`  
**Type:** Action (dry run)  
**Color:** Orange

**Function:** Preview what UserDefaults cleanup would do without making changes.

**Process:**
- Scans UserDefaults for cleanup candidates
- Prints report of what would be cleaned
- Does NOT modify data

**Function:** `UserDefaultsCleanup.preview()`

**Haptic Feedback:** Medium impact

---

### 🗑️ Run Cleanup
**Icon:** `trash.circle.fill`  
**Type:** Destructive Action  
**Color:** Red

**Function:** Executes UserDefaults cleanup (removes obsolete keys, migrates data).

**Process:**
- Removes deprecated keys
- Migrates data to new format
- Cleans up orphaned entries

**Console Output:** Cleanup result summary.

**Function:** `UserDefaultsCleanup.execute()`

**Haptic Feedback:** Heavy impact

**Warning:** Destructive operation. Review preview first.

---

## Panel Behavior

### Layout
- **Grid:** 3 columns, responsive spacing
- **Scrollable:** Vertical scroll for all buttons
- **Header:** "Debug & Settings" with close button (X)
- **Background:** Dark overlay (black with opacity)

### Interaction
- **Map Interaction:** Panel scrolling blocks map panning (`isHUDInteracting`)
- **Gestures:** Drag gesture detection for scroll state
- **Alerts:** Many destructive actions show confirmation alerts
- **Share Sheets:** Export actions open iOS share sheet

### State Management
- **Panel Visibility:** `HUDPanelsState.isDebugSettingsOpen`
- **Toggle Function:** `hudPanels.toggleDebugSettings()`
- **Console Logging:** Panel open/close events logged

---

## Related Files

- **Panel Implementation:** `TapResolver/UI/Root/HUDContainer.swift` (lines 1265-2851)
- **State Management:** `TapResolver/State/HUDPanelsState.swift`
- **Diagnostic Utilities:** `TapResolver/Utils/UserDefaultsDiagnostics.swift`
- **Cleanup Utilities:** `TapResolver/Utils/UserDefaultsCleanup.swift`
- **Feature Flags:** `TapResolver/Utils/FeatureFlags.swift`
- **App Settings:** `TapResolver/Utils/AppSettings.swift`

---

## Notes

- Many destructive operations require confirmation via alerts
- Location-specific operations only affect the current location (`PersistenceContext.shared.locationID`)
- Export functions generate files in the app's Documents directory
- Console logging is extensive - check Xcode console for detailed output
- Some buttons are one-time utilities (cleanup, migration) and may be commented out after use

---

## Version History

This documentation reflects the Debug Settings Panel as of the current codebase. Buttons may be added, removed, or modified in future versions.

