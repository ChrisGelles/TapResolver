# TapResolver Diagnostic Tools

## Overview
Comprehensive diagnostic system to investigate why only 26 of 54 map points are being exported.

---

## Implemented Diagnostic Tools

### 1. **MapPointStore Diagnostics** 
**File:** `State/MapPointStore.swift`

#### Functions Added:
- `printUserDefaultsDiagnostic()` - Shows complete UserDefaults state
- `forceReload()` - Forces reload from UserDefaults

**What it checks:**
- ✅ How many points are loaded in memory
- ✅ How many points are stored in UserDefaults
- ✅ Data size in bytes/KB
- ✅ Decoding errors if any
- ✅ All UserDefaults keys containing "map", "point", or "location"
- ✅ Discrepancies between memory and storage

---

### 2. **Storage Diagnostics Utility**
**File:** `Utils/StorageDiagnostics.swift`

#### Functions:
- `printAllMapPointStorageLocations()` - Scans all possible storage keys
- `scanAllUserDefaultsKeys()` - Complete UserDefaults scan

**What it checks:**
- ✅ Multiple location IDs (home, museum, default)
- ✅ Different key patterns (with/without location prefix)
- ✅ Data sizes for all map point related keys
- ✅ Point counts and session counts per key
- ✅ Total UserDefaults usage

---

### 3. **Export Logging**
**File:** `State/MapPointLogManager.swift`

**Added logging to `exportMasterJSON()`:**
- ✅ Location ID being exported
- ✅ Total points in store
- ✅ Total sessions across all points
- ✅ Per-point processing with session counts
- ✅ Final export count confirmation

---

### 4. **UI Diagnostic Buttons**
**File:** `UI/MapPointLog/MapPointLogView.swift`

**Three new buttons in the header:**

1. **🔍 Storage Scan** (Orange) - `doc.text.magnifyingglass`
   - Runs `printAllMapPointStorageLocations()`
   - Runs `scanAllUserDefaultsKeys()`

2. **🩺 Diagnostic** (Yellow) - `stethoscope`
   - Runs `printUserDefaultsDiagnostic()`

3. **📤 Export** (White) - `square.and.arrow.up`
   - Existing export with new logging

---

## How to Use

### Step 1: Run Storage Scan
1. Open TapResolver app
2. Navigate to **Map Point Log** view (bottom drawer)
3. Tap the **orange magnifying glass button** (🔍)
4. Check Xcode console output

**Expected output sections:**
```
🗄️  ALL POSSIBLE MAP POINT STORAGE LOCATIONS
📍 Location: museum
   ✅ MapPoints_v1: 245678 bytes
      → 54 points, 87 sessions
```

### Step 2: Run MapPointStore Diagnostic
1. Tap the **yellow stethoscope button** (🩺)
2. Check Xcode console output

**Expected output:**
```
📊 MAP POINT STORE - USERDEFAULTS DIAGNOSTIC
📱 IN-MEMORY STATE:
   Points loaded: 26
💾 USERDEFAULTS RAW DATA:
   ✅ Successfully decoded 54 map points from UserDefaults
⚠️  DISCREPANCY DETECTED!
   UserDefaults has: 54 points
   Memory has: 26 points
   Missing: 28 points
```

### Step 3: Try Export with Logging
1. Tap the **export button** (📤)
2. Check console for detailed processing log

**Expected output:**
```
📤 EXPORT MASTER JSON - START
Location: museum
Points in store: 26
  Processing point 1/26: a1b2c3d4... - 2 sessions
  Processing point 2/26: e5f6g7h8... - 1 sessions
  ...
✅ Export complete: 26 points exported
```

---

## Possible Scenarios & Solutions

### Scenario 1: Data in Different Key
**Symptoms:**
- Storage scan finds 54 points under `locations.museum.mapPoints.v1`
- MapPointStore is reading from `MapPoints_v1`

**Solution:**
- Update `MapPointStore.pointsKey` to use correct key pattern

---

### Scenario 2: Partial Data Load
**Symptoms:**
- UserDefaults has 54 points
- Memory has 26 points
- Discrepancy detected

**Possible causes:**
- Decoding error during load
- Data corruption
- Size limit exceeded

**Solution:**
- Check for decoding errors in diagnostic output
- Implement chunked loading
- Migrate to file-based storage

---

### Scenario 3: Multiple Storage Locations
**Symptoms:**
- Data split across multiple keys
- Different location IDs have different data

**Solution:**
- Merge data from multiple keys
- Standardize on single storage location
- Migrate old data

---

### Scenario 4: UserDefaults Size Limit
**Symptoms:**
- Data size exceeds ~1MB
- Silent truncation or corruption

**Solution:**
- Migrate to file-based storage (Documents directory)
- Use plist files instead of UserDefaults

---

## Console Output Reference

### Good State:
```
📊 MAP POINT STORE - USERDEFAULTS DIAGNOSTIC
Current locationID: museum
Points key: MapPoints_v1

📱 IN-MEMORY STATE:
   Points loaded: 54
   
💾 USERDEFAULTS RAW DATA:
   Data size: 245678 bytes (239.92 KB)
   ✅ Successfully decoded 54 map points from UserDefaults
   Total sessions across all points: 87
```

### Problem State:
```
⚠️  DISCREPANCY DETECTED!
   UserDefaults has: 54 points
   Memory has: 26 points
   Missing: 28 points
```

### Decoding Error:
```
❌ Failed to decode UserDefaults data
   Error: keyNotFound(CodingKeys...
   Missing key: sessions, context: ...
```

---

## Next Steps After Diagnosis

1. **Collect console output** from all three buttons
2. **Identify which scenario** matches your situation
3. **Share the complete output** for analysis
4. **Implement the appropriate fix** based on findings

---

## File Locations

```
TapResolver/
├── State/
│   ├── MapPointStore.swift          (diagnostic functions)
│   └── MapPointLogManager.swift     (export logging)
├── Utils/
│   └── StorageDiagnostics.swift    (storage scan utility)
└── UI/
    └── MapPointLog/
        └── MapPointLogView.swift     (diagnostic buttons)
```

---

## Commit Reference

**Branch:** `ui-refinements-mappoint-log`
**Commit:** Diagnostic tools for investigating incomplete data export

All changes are backed up to GitHub.

