# UserDefaults Data Model Map

## Namespace Pattern

All location-specific data is namespaced using the pattern:
```
locations.<locationID>.<baseKey>
```

Where `locationID` is set by `PersistenceContext.shared.locationID` (e.g., "home", "museum")

---

## Global Keys (Not Namespaced)

### `locations.lastOpened.v1`
- **Type:** `String`
- **Purpose:** Tracks the last opened location ID
- **Used by:** `LocationManager`, `LocationImportUtils`
- **Example:** `"museum"`

---

## Location-Specific Keys (Namespaced)

All keys below are prefixed with `locations.<locationID>.` (e.g., `locations.museum.MapPoints_v1`)

### 1. MapPoints

#### `locations.<id>.MapPoints_v1`
- **Type:** `Data` (JSON-encoded array of `MapPointDTO`)
- **Purpose:** Stores all map points for a location
- **Used by:** `MapPointStore`
- **Structure:**
```swift
[MapPointDTO] where MapPointDTO = {
    id: String (UUID)
    x: Double
    y: Double
    name: String?
    isLocked: Bool
    roles: [String]  // Array of role names (e.g., "triangleEdge")
    locationPhotoData: String?  // Base64-encoded image data
    sessions: [ScanSessionDTO]
    triangleMemberships: [String]  // Array of UUID strings
    createdDate: String  // ISO8601 date
    arMarkerID: String?  // Links to ARWorldMapStore marker
}
```

**ScanSessionDTO Structure:**
```swift
{
    scanID: String
    sessionID: String
    pointID: String
    locationID: String
    timingStartISO: String
    timingEndISO: String
    duration_s: Double
    deviceHeight_m: Double?
    facing_deg: Double?
    beacons: [BeaconDataDTO]
}
```

**BeaconDataDTO Structure:**
```swift
{
    beaconID: String
    stats: {
        median_dbm: Double
        mad_db: Double
        mean_dbm: Double
        stddev_db: Double
        min_dbm: Double
        max_dbm: Double
        sampleCount: Int
    }
    hist: {
        binMin_dbm: Double
        binMax_dbm: Double
        bins: [Int]  // Histogram counts
    }
    samples: [[Double]]?  // Optional raw samples [rssi, timestamp]
    meta: {
        name: String
        model: String
        txPower: Int?
        msInt: Int
    }
}
```

**Size:** Typically 12+ MB for locations with photos (photos stored as base64 strings in `locationPhotoData`)

---

#### `locations.<id>.MapPointsActive_v1`
- **Type:** `Data` (JSON-encoded UUID string)
- **Purpose:** Stores the currently active map point ID
- **Used by:** `MapPointStore`
- **Structure:** `String` (UUID)

---

### 2. Beacon Data

#### `locations.<id>.BeaconLocks_v1`
- **Type:** `Data` (JSON-encoded dictionary)
- **Purpose:** Stores which beacons are locked (cannot be moved/deleted)
- **Used by:** `BeaconDotStore`
- **Structure:**
```swift
{
    locks: [String: Bool]  // beaconID -> isLocked
}
```

---

#### `locations.<id>.BeaconElevations_v1`
- **Type:** `Data` (JSON-encoded dictionary)
- **Purpose:** Stores elevation (height) for each beacon in meters
- **Used by:** `BeaconDotStore`
- **Structure:**
```swift
{
    elevations: [String: Double]  // beaconID -> elevation in meters
}
```

---

#### `locations.<id>.BeaconTxPower_v1`
- **Type:** `Data` (JSON-encoded dictionary)
- **Purpose:** Stores transmit power (dBm) for each beacon
- **Used by:** `BeaconDotStore`
- **Structure:**
```swift
{
    txPower: [String: Int]  // beaconID -> txPower in dBm
}
```

---

#### `locations.<id>.advertisingIntervals`
- **Type:** `[String: Double]` (direct array, not JSON-encoded)
- **Purpose:** Stores advertising interval (ms) for each beacon
- **Used by:** `BeaconDotStore`
- **Structure:**
```swift
[String: Double]  // beaconID -> interval in milliseconds
```

**Note:** This is stored directly as an array, not JSON-encoded Data

---

#### `locations.<id>.BeaconDots_v1`
- **Type:** `Data` (JSON-encoded array, optional fallback)
- **Purpose:** Fallback storage for beacon dot positions (primary storage is `dots.json` file)
- **Used by:** `BeaconDotStore`
- **Structure:**
```swift
[DotDTO] where DotDTO = {
    beaconID: String
    x: Double
    y: Double
    elevation: Double
    txPower: Int?
}
```

**Note:** Primary storage is `Documents/locations/<id>/dots.json` file. This UserDefaults key is a fallback.

---

### 3. Beacon Lists

#### `locations.<id>.BeaconLists_beacons_v1`
- **Type:** `Data` (JSON-encoded array)
- **Purpose:** Stores the list of known beacon IDs
- **Used by:** `BeaconListsStore`
- **Structure:**
```swift
[String]  // Array of beacon IDs (e.g., ["02-brightFalcon", "03-angryBeaver"])
```

---

#### `locations.<id>.beaconLists.morgue.v1`
- **Type:** `[String]` (direct array, not JSON-encoded)
- **Purpose:** Stores "morgue" list of devices that were seen but aren't beacons
- **Used by:** `BeaconListsStore`
- **Structure:**
```swift
[String]  // Array of device names/IDs
```

**Note:** This is stored directly as an array, not JSON-encoded Data

---

### 4. Metric Squares

#### `locations.<id>.MetricSquares_v1`
- **Type:** `Data` (JSON-encoded array)
- **Purpose:** Stores metric calibration squares
- **Used by:** `MetricSquareStore`
- **Structure:**
```swift
[SquareDTO] where SquareDTO = {
    id: String (UUID)
    color: [Double]  // RGB components [r, g, b, alpha]
    center: [Double]  // [x, y]
    side: Double
    isLocked: Bool
    meters: Double
}
```

---

### 5. Triangle Patches

#### `locations.<id>.triangles_v1`
- **Type:** `Data` (JSON-encoded array)
- **Purpose:** Stores triangular calibration patches for AR mapping
- **Used by:** `TrianglePatchStore`
- **Structure:**
```swift
[TrianglePatchDTO] where TrianglePatchDTO = {
    id: String (UUID)
    vertexIDs: [String]  // Array of 3 UUID strings
    MA: [Float]  // [x, y] - Map coordinate of vertex A
    MB: [Float]  // [x, y] - Map coordinate of vertex B
    MC: [Float]  // [x, y] - Map coordinate of vertex C
    WA: [Float]  // [x, y, z] - World coordinate of vertex A
    WB: [Float]  // [x, y, z] - World coordinate of vertex B
    WC: [Float]  // [x, y, z] - World coordinate of vertex C
    pxPerMeter: Float
    planeOrigin: [Float]  // [x, y, z]
    planeNormal: [Float]  // [x, y, z]
    mapU: [Float]  // [x, y] - 2D basis vector
    mapV: [Float]  // [x, y] - 2D basis vector
    invUV: [Float]  // [4 floats] - 2x2 inverse matrix
    neighborAB: String?  // UUID of neighbor triangle
    neighborBC: String?  // UUID of neighbor triangle
    neighborCA: String?  // UUID of neighbor triangle
    worldMapFilename: String?  // ARWorldMap filename
    isCalibrated: Bool
    lastCalibratedAt: String?  // ISO8601 date
    calibrationQuality: Float?
    arMarkerIDs: [String]  // Array of AR marker UUID strings
    calibrationPositions: [[Float]]?  // Legacy: 3D positions
    schemaVersion: Int
}
```

---

### 6. AR Markers (Legacy)

#### `locations.<id>.ARMarkers_v1`
- **Type:** `Data` (JSON-encoded array)
- **Purpose:** Legacy AR marker storage (may be deprecated)
- **Used by:** `MapPointStore` (legacy)
- **Structure:** Unknown (legacy format)

---

### 7. Anchor Packages

#### `locations.<id>.AnchorPackages_v1`
- **Type:** `Data` (JSON-encoded array)
- **Purpose:** Stores AR anchor packages
- **Used by:** `MapPointStore`
- **Structure:** Unknown (needs investigation)

---

## File-Based Storage (Not UserDefaults)

These are stored in `Documents/locations/<locationID>/`:

### `dots.json`
- **Purpose:** Primary storage for beacon dot positions
- **Format:** JSON array of `DotDTO` objects
- **Used by:** `BeaconDotStore`

### `location.json`
- **Purpose:** Location metadata (name, map image, etc.)
- **Format:** JSON object
- **Used by:** `LocationImportUtils`

### `Scans/<year-month>/scan_*.json`
- **Purpose:** Individual scan session files
- **Format:** JSON object matching `ScanSessionDTO`
- **Used by:** Scan session persistence

### `assets/`
- **Purpose:** Map images and other assets
- **Format:** Image files (PNG, JPG, etc.)

---

## Data Size Estimates

Based on diagnostic output:

- **MapPoints_v1:** ~12 MB (for museum location with 66 points)
  - Photos: ~11.8 MB (97% of total)
  - Other data: ~0.36 MB (3%)
  - Average: ~184 KB per map point

- **Other keys:** Typically < 100 KB each

---

## Migration Notes

### Photo Storage
- **Current:** Photos stored as base64 strings in `locationPhotoData` field
- **Planned:** Migrate to disk storage at `Documents/locations/<id>/map-points/<uuid>.jpg`
- **Impact:** Will reduce UserDefaults size by ~97% for locations with photos

### Schema Versions
- `TrianglePatch.schemaVersion`: Currently version 2
- Used for backward compatibility during data migrations

---

## Key Naming Conventions

1. **Version Suffix:** All keys end with `_v1` or `.v1` for versioning
2. **CamelCase:** Base keys use PascalCase (e.g., `MapPoints_v1`)
3. **Namespacing:** All location data prefixed with `locations.<id>.`
4. **Global Keys:** Use `locations.` prefix but no location ID (e.g., `locations.lastOpened.v1`)

---

## Access Patterns

### Reading Data
```swift
let ctx = PersistenceContext.shared
ctx.locationID = "museum"  // Set namespace
let points: [MapPointDTO]? = ctx.read("MapPoints_v1", as: [MapPointDTO].self)
// Reads from: locations.museum.MapPoints_v1
```

### Writing Data
```swift
let ctx = PersistenceContext.shared
ctx.locationID = "museum"
ctx.write("MapPoints_v1", value: pointsArray)
// Writes to: locations.museum.MapPoints_v1
```

### Direct Access (Not Recommended)
```swift
let key = "locations.museum.MapPoints_v1"
let data = UserDefaults.standard.data(forKey: key)
```

---

## Backup/Restore

The `UserDataBackup` utility backs up all keys matching the pattern `locations.<locationID>.*`:

**Backed up keys:**
- `MapPoints_v1`
- `BeaconLocks_v1`
- `BeaconElevations_v1`
- `BeaconTxPower_v1`
- `advertisingIntervals`
- `MetricSquares_v1`
- `BeaconLists_v1`

**Not backed up:**
- `locations.lastOpened.v1` (global key)
- File-based storage (`dots.json`, `location.json`, scan files)

