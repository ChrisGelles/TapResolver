# Property Usage & Architecture Audit Report

Generated: 2025-01-XX

---

## PART 1: Current Property Usage Audit

### Property: `bakedCanonicalPosition`

**Type:** `SIMD3<Float>?` (optional 3D position in canonical frame)

#### Files that reference it:

**MapPointStore.swift:**
- **Line 193:** Property declaration: `public var bakedCanonicalPosition: SIMD3<Float>?`
- **Line 215:** Initializer parameter: `bakedCanonicalPosition: SIMD3<Float>? = nil`
- **Line 232:** Initializer assignment: `self.bakedCanonicalPosition = bakedCanonicalPosition`
- **Line 301:** CodingKeys enum case: `case bakedCanonicalPositionArray`
- **Lines 331-336:** Decode logic - reads from `bakedCanonicalPositionArray` JSON key, converts `[Float]` array to `SIMD3<Float>`
- **Lines 365-367:** Encode logic - converts `SIMD3<Float>` to `[Float]` array for JSON
- **Line 764:** MapPointDTO property: `let bakedCanonicalPositionArray: [Float]?`
- **Line 816:** DTO conversion - maps `point.bakedCanonicalPosition` to DTO array
- **Line 952:** DTO to MapPoint conversion - reconstructs `SIMD3<Float>` from array
- **Line 971:** Assignment: `bakedCanonicalPosition: bakedPosition`
- **Line 1921:** Write: `points[index].bakedCanonicalPosition = bakedPosition`
- **Line 1969:** Read (filter): `points.filter { $0.bakedCanonicalPosition != nil }`
- **Line 1982:** Read (access): `if let baked = point.bakedCanonicalPosition`

**ARCalibrationCoordinator.swift:**
- **Line 1385:** Check-nil: `let hasBakedPosition = mapPoint.bakedCanonicalPosition != nil`
- **Line 1389:** Check-nil (logging): `bakedCanonicalPosition: \(hasBakedPosition ? "✅ EXISTS" : "❌ NIL")`
- **Line 1390:** Read: `if let baked = mapPoint.bakedCanonicalPosition`
- **Line 1420:** Check-nil (logging): `Reason: No bakedCanonicalPosition for this MapPoint`
- **Line 1717:** Check-nil (guard): `guard let bakedPosition = targetMapPoint.bakedCanonicalPosition else`
- **Line 1719:** Check-nil (logging): `No bakedCanonicalPosition for \(targetMapPointID)`
- **Line 1775:** Read (logging): `if let baked = targetMP.bakedCanonicalPosition`
- **Line 1778:** Check-nil (logging): `bakedCanonicalPosition: ❌ NIL`
- **Line 2238:** Check-nil: `mapPoint.bakedCanonicalPosition != nil`
- **Line 2265:** Check-nil: `mapPoint.bakedCanonicalPosition != nil`
- **Line 2344:** Check-nil: `mapPoint.bakedCanonicalPosition != nil`
- **Line 2417:** Read: `let bakedPos = mapPoint.bakedCanonicalPosition`
- **Line 3600:** Read: `let currentBaked = safeMapStore.points[index].bakedCanonicalPosition`
- **Line 3641:** Write: `safeMapStore.points[index].bakedCanonicalPosition = newBakedPosition`
- **Line 3699:** Read: `let currentBaked = safeMapStore.points[index].bakedCanonicalPosition`
- **Line 3729:** Write: `safeMapStore.points[index].bakedCanonicalPosition = newBakedPosition`

**ARViewContainer.swift:**
- **Line 287:** Read: `let bakedPos = mapPoint.bakedCanonicalPosition`
- **Line 1068:** Read: `let bakedPos = mapPoint.bakedCanonicalPosition`
- **Line 1497:** Read: `let bakedPos = mapPoint.bakedCanonicalPosition`

**UserDefaultsDiagnostics.swift:**
- **Line 227:** Read (diagnostics): `let bakedArray = pointDict["bakedCanonicalPositionArray"] as? [Double]`

**Access Pattern:**
- Direct property access: `mapPoint.bakedCanonicalPosition`
- No wrapper methods - direct access only
- JSON CodingKey: `bakedCanonicalPositionArray` (stored as `[Float]` array)

---

### Property: `bakedConfidence`

**Type:** `Float?` (optional, 0.0-1.0)

#### Files that reference it:

**MapPointStore.swift:**
- **Line 194:** Property declaration: `public var bakedConfidence: Float?`
- **Line 216:** Initializer parameter: `bakedConfidence: Float? = nil`
- **Line 233:** Initializer assignment: `self.bakedConfidence = bakedConfidence`
- **Line 301:** CodingKeys enum case: `case bakedConfidence`
- **Line 337:** Decode: `bakedConfidence = try container.decodeIfPresent(Float.self, forKey: .bakedConfidence)`
- **Line 368:** Encode: `try container.encodeIfPresent(bakedConfidence, forKey: .bakedConfidence)`
- **Line 765:** MapPointDTO property: `let bakedConfidence: Float?`
- **Line 817:** DTO conversion: `bakedConfidence: point.bakedConfidence`
- **Line 972:** DTO to MapPoint: `bakedConfidence: dtoItem.bakedConfidence`
- **Line 1922:** Write: `points[index].bakedConfidence = avgConfidence`
- **Line 1983:** Read: `let confidence = point.bakedConfidence`

**ARCalibrationCoordinator.swift:**
- **Line 1392:** Read (logging): `confidence: \(mapPoint.bakedConfidence != nil ? String(format: "%.2f", mapPoint.bakedConfidence!) : "NIL")`
- **Line 1722:** Read (logging): `bakedConfidence: \(targetMapPoint.bakedConfidence != nil ? String(format: "%.2f", targetMapPoint.bakedConfidence!) : "NIL")`
- **Line 1780:** Read (logging): `bakedConfidence: \(targetMP.bakedConfidence != nil ? String(format: "%.2f", targetMP.bakedConfidence!) : "NIL")`
- **Line 3601:** Read: `let currentConfidence = safeMapStore.points[index].bakedConfidence ?? 0`
- **Line 3642:** Write: `safeMapStore.points[index].bakedConfidence = newConfidence`
- **Line 3700:** Read: `let currentConfidence = safeMapStore.points[index].bakedConfidence ?? 0`
- **Line 3730:** Write: `safeMapStore.points[index].bakedConfidence = newConfidence`

**UserDefaultsDiagnostics.swift:**
- **Line 230:** Read (diagnostics): `bakedAudit["confidence"] = pointDict["bakedConfidence"] ?? NSNull()`

**Access Pattern:**
- Direct property access with nil-coalescing: `bakedConfidence ?? 0`
- JSON CodingKey: `bakedConfidence`

---

### Property: `bakedSampleCount`

**Type:** `Int` (default: 0)

#### Files that reference it:

**MapPointStore.swift:**
- **Line 195:** Property declaration: `public var bakedSampleCount: Int = 0`
- **Line 217:** Initializer parameter: `bakedSampleCount: Int = 0`
- **Line 234:** Initializer assignment: `self.bakedSampleCount = bakedSampleCount`
- **Line 301:** CodingKeys enum case: `case bakedSampleCount`
- **Line 338:** Decode: `bakedSampleCount = try container.decodeIfPresent(Int.self, forKey: .bakedSampleCount) ?? 0`
- **Lines 369-370:** Encode (conditional): `if bakedSampleCount > 0 { try container.encode(bakedSampleCount, forKey: .bakedSampleCount) }`
- **Line 766:** MapPointDTO property: `let bakedSampleCount: Int?`
- **Line 818:** DTO conversion: `bakedSampleCount: point.bakedSampleCount > 0 ? point.bakedSampleCount : nil`
- **Line 973:** DTO to MapPoint: `bakedSampleCount: dtoItem.bakedSampleCount ?? 0`
- **Line 1923:** Write: `points[index].bakedSampleCount = samples.count`
- **Line 1984:** Read (logging): `samples=\(point.bakedSampleCount)`

**ARCalibrationCoordinator.swift:**
- **Line 1393:** Read (logging): `sampleCount: \(mapPoint.bakedSampleCount)`
- **Line 1723:** Read (logging): `bakedSampleCount: \(targetMapPoint.bakedSampleCount)`
- **Line 1781:** Read (logging): `bakedSampleCount: \(targetMP.bakedSampleCount)`
- **Line 3602:** Read: `let currentSampleCount = safeMapStore.points[index].bakedSampleCount`
- **Line 3643:** Write: `safeMapStore.points[index].bakedSampleCount = newSampleCount`
- **Line 3701:** Read: `let currentSampleCount = safeMapStore.points[index].bakedSampleCount`
- **Line 3731:** Write: `safeMapStore.points[index].bakedSampleCount = newSampleCount`

**UserDefaultsDiagnostics.swift:**
- **Line 231:** Read (diagnostics): `bakedAudit["sampleCount"] = pointDict["bakedSampleCount"] ?? 0`

**Access Pattern:**
- Direct property access
- JSON CodingKey: `bakedSampleCount`
- Only encoded if `> 0` (optimization)

---

### Property: `arPositionHistory`

**Type:** `[ARPositionRecord]` (array of position records)

#### Files that reference it:

**MapPointStore.swift:**
- **Line 187:** Property declaration: `public var arPositionHistory: [ARPositionRecord] = []`
- **Line 214:** Initializer parameter: `arPositionHistory: [ARPositionRecord] = []`
- **Line 231:** Initializer assignment: `self.arPositionHistory = arPositionHistory`
- **Line 243:** Read (check empty): `guard !arPositionHistory.isEmpty else { return nil }`
- **Line 246:** Read (count check): `if arPositionHistory.count == 1`
- **Line 247:** Read (access): `return arPositionHistory[0].position`
- **Line 252:** Read (iteration): `for record in arPositionHistory`
- **Line 255:** Read (count): `Float(arPositionHistory.count)`
- **Line 258:** Read (filter): `arPositionHistory.filter { record in ... }`
- **Line 264:** Read (fallback): `let recordsToUse = inliers.isEmpty ? arPositionHistory : inliers`
- **Line 281:** Read (logging count): `arPositionHistory.count`
- **Line 282:** Read (check empty): `if arPositionHistory.isEmpty`
- **Line 285:** Read (iteration): `for record in arPositionHistory`
- **Line 300:** CodingKeys enum case: `case arPositionHistory`
- **Line 328:** Decode: `arPositionHistory = try container.decodeIfPresent([ARPositionRecord].self, forKey: .arPositionHistory) ?? []`
- **Lines 360-361:** Encode (conditional): `if !arPositionHistory.isEmpty { try container.encode(arPositionHistory, forKey: .arPositionHistory) }`
- **Line 692:** Write (append): `points[index].arPositionHistory.append(record)`
- **Lines 695-696:** Write (removeFirst): `if points[index].arPositionHistory.count > maxHistoryRecords { let removed = points[index].arPositionHistory.removeFirst() }`
- **Line 700:** Read (logging count): `points[index].arPositionHistory.count`
- **Line 708:** Read (filter): `points.filter { !$0.arPositionHistory.isEmpty }`
- **Line 761:** MapPointDTO property: `let arPositionHistory: [ARPositionRecord]?`
- **Line 814:** DTO conversion: `arPositionHistory: point.arPositionHistory.isEmpty ? nil : point.arPositionHistory`
- **Line 853:** Read (count): `let recordCount = points[i].arPositionHistory.count`
- **Line 857:** Write (clear): `points[i].arPositionHistory = []`
- **Line 969:** DTO to MapPoint: `arPositionHistory: dtoItem.arPositionHistory ?? []`
- **Line 1009:** Read (reduce): `points.reduce(0) { $0 + $1.arPositionHistory.count }`
- **Line 1010:** Read (flatMap): `points.flatMap { $0.arPositionHistory.map { $0.sessionID } }`
- **Line 1011:** Read (filter): `points.filter { !$0.arPositionHistory.isEmpty }.count`
- **Line 1611:** Read (check empty): `if !point.arPositionHistory.isEmpty`
- **Line 1613:** Read (count): `totalRecords += point.arPositionHistory.count`
- **Line 1616:** Read (map): `point.arPositionHistory.map { record in ... }`
- **Line 1631:** Read (count): `"recordCount": point.arPositionHistory.count`
- **Line 1661:** Read (check empty): `if !points[i].arPositionHistory.isEmpty`
- **Line 1662:** Write (clear): `points[i].arPositionHistory = []`
- **Line 1682:** Read (flatMap): `.flatMap { $0.arPositionHistory }`
- **Line 1734:** Read (iteration): `for record in point.arPositionHistory`
- **Line 1751:** Read (iteration): `for record in point.arPositionHistory`
- **Line 1970:** Read (filter): `points.filter { !$0.arPositionHistory.isEmpty }`
- **Line 2009:** Read (count): `point.sessions.count + point.arPositionHistory.count`
- **Line 2064:** Read (count): `group.keeper.arPositionHistory.count`
- **Line 2068:** Read (count): `dup.arPositionHistory.count`
- **Line 2103:** Write (append contents): `points[keeperIndex].arPositionHistory.append(contentsOf: duplicate.arPositionHistory)`

**ARCalibrationCoordinator.swift:**
- **Line 531:** Read (iteration): `for record in mapPoint.arPositionHistory`
- **Line 1433:** Read (assignment): `let targetHistory = mapPoint.arPositionHistory`
- **Line 1443:** Read (iteration): `for record in vertexMapPoint.arPositionHistory`
- **Line 1724:** Read (count): `arPositionHistory: \(targetMapPoint.arPositionHistory.count) record(s)`
- **Line 1725:** Read (check empty): `if !targetMapPoint.arPositionHistory.isEmpty`
- **Line 1727:** Read (map): `targetMapPoint.arPositionHistory.map { $0.sessionID }`
- **Line 1729:** Read (filter): `targetMapPoint.arPositionHistory.filter { $0.sessionID == sid }.count`
- **Line 1782:** Read (count): `arPositionHistory count: \(targetMP.arPositionHistory.count)`
- **Line 3607:** Read (last): `if let latestRecord = safeMapStore.points[index].arPositionHistory.last`

**HUDContainer.swift:**
- **Line 1658:** Read (reduce): `mapPointStore.points.reduce(0) { $0 + $1.arPositionHistory.count }`

**UserDefaultsDiagnostics.swift:**
- **Line 276:** Read (diagnostics): `let history = (pointDict["arPositionHistory"] as? [[String: Any]]) ?? []`

**Access Pattern:**
- **Reads:** Iteration (`for record in`), count checks, filtering, mapping, accessing last element
- **Writes:** `append()`, `removeFirst()`, assignment (`= []`), `append(contentsOf:)`
- **Processing for baking:** `bakeDownHistoricalData()` (MapPointStore.swift line 1713) iterates through all records to build session-based position index

---

### Property: `consensusPosition`

**Type:** `SIMD3<Float>?` (computed property)

#### Files that reference it:

**MapPointStore.swift:**
- **Line 242:** Computed property declaration: `var consensusPosition: SIMD3<Float>?`
- **Line 243:** Read (check empty): `guard !arPositionHistory.isEmpty else { return nil }`
- **Line 246:** Read (count check): `if arPositionHistory.count == 1`
- **Line 247:** Read (access): `return arPositionHistory[0].position`
- **Lines 250-276:** Computation logic - weighted average with outlier rejection
- **Line 289:** Read (logging): `if let consensus = consensusPosition`

**ARCalibrationCoordinator.swift:**
- **Line 1807:** Read (logging): `This path uses consensusPosition which may average incompatible`
- **Line 1832:** Read: `if let consensus = thirdMapPoint.consensusPosition`
- **Line 1833:** Read: `let firstConsensus = firstMapPoint.consensusPosition`
- **Line 1834:** Read: `let secondConsensus = secondMapPoint.consensusPosition`
- **Line 1889:** Read (check nil): `if thirdMapPoint.consensusPosition == nil`
- **Line 1891:** Read (check nil): `else if firstMapPoint.consensusPosition == nil || secondMapPoint.consensusPosition == nil`

**Access Pattern:**
- **Computed property** - not stored, calculated on-demand from `arPositionHistory`
- **Dependencies:** `arPositionHistory` array
- **Algorithm:** Weighted average with outlier rejection (threshold: `outlierThresholdMeters`)

---

## PART 2: CodingKeys Audit

### MapPoint CodingKeys

**Location:** `MapPointStore.swift` lines 296-302

```swift
enum CodingKeys: String, CodingKey {
    case id, position, name, createdDate, sessions
    case linkedARMarkerID, arMarkerID, roles
    case locationPhotoData, photoFilename, photoOutdated, photoCapturedAtPosition
    case triangleMemberships, isLocked, arPositionHistory
    case bakedCanonicalPositionArray, bakedConfidence, bakedSampleCount
}
```

**Mapping:**
- `bakedCanonicalPosition` → `bakedCanonicalPositionArray` (stored as `[Float]`)
- `bakedConfidence` → `bakedConfidence` (direct)
- `bakedSampleCount` → `bakedSampleCount` (direct)
- `arPositionHistory` → `arPositionHistory` (direct array)

**Encode/Decode:**
- **Decode (lines 304-339):** Reads `bakedCanonicalPositionArray` as `[Float]`, converts to `SIMD3<Float>`
- **Encode (lines 341-372):** Converts `SIMD3<Float>` to `[Float]` array

### MapPointDTO Properties

**Location:** `MapPointStore.swift` lines 744-767

**Properties:**
- `bakedCanonicalPositionArray: [Float]?` - corresponds to `bakedCanonicalPosition`
- `bakedConfidence: Float?` - direct mapping
- `bakedSampleCount: Int?` - direct mapping
- `arPositionHistory: [ARPositionRecord]?` - optional for migration

**DTO ↔ MapPoint Conversion:**
- **MapPoint → DTO (lines 786-819):** Maps `point.bakedCanonicalPosition` to array, includes all baked fields
- **DTO → MapPoint (lines 952-973):** Reconstructs `SIMD3<Float>` from array, assigns all fields

### ARPositionRecord CodingKeys

**Location:** `MapPointStore.swift` lines 54-57

```swift
enum CodingKeys: String, CodingKey {
    case id, sessionID, timestamp, sourceType, confidenceScore
    case positionArray, distortionArray
}
```

**JSON Keys:**
- `sessionID` → `sessionID` (UUID string)
- `timestamp` → `timestamp` (Date, ISO8601)
- `position` → `positionArray` (stored as `[Float]`)

**Encode/Decode:**
- **Decode (lines 59-75):** Reads `positionArray` as `[Float]`, converts to `SIMD3<Float>`
- **Encode (lines 77-89):** Converts `SIMD3<Float>` to `[Float]` array

---

## PART 3: Function Signature Audit

### Functions with "baked" in name:

1. **`calculateGhostPositionFromBakedData(for:)`**
   - **Location:** `ARCalibrationCoordinator.swift` line 1667
   - **Signature:** `func calculateGhostPositionFromBakedData(for targetMapPointID: UUID) -> SIMD3<Float>?`
   - **Returns:** `SIMD3<Float>?` (AR position in current session coordinates)

2. **`calculateGhostPositionFromBakedDataInternal(...)`**
   - **Location:** `ARCalibrationCoordinator.swift` line 1704
   - **Signature:** `private func calculateGhostPositionFromBakedDataInternal(...)`
   - **Purpose:** Internal helper for baked ghost calculation

3. **`triangleHasBakedVertices(_:)`**
   - **Location:** `ARCalibrationCoordinator.swift` line 2230
   - **Signature:** `public func triangleHasBakedVertices(_ triangleID: UUID) -> Bool`
   - **Returns:** `Bool` (checks if triangle vertices have baked positions)

4. **`getFillableTriangleIDsBaked()`**
   - **Location:** `ARCalibrationCoordinator.swift` line 2333
   - **Signature:** `func getFillableTriangleIDsBaked() -> [UUID]`
   - **Returns:** `[UUID]` (triangle IDs with baked vertices)

5. **`countFillableTrianglesBaked()`**
   - **Location:** `ARCalibrationCoordinator.swift` line 2361
   - **Signature:** `func countFillableTrianglesBaked() -> Int`
   - **Returns:** `Int` (count of fillable triangles)

6. **`projectBakedToSession(_:)`**
   - **Location:** `ARCalibrationCoordinator.swift` line 2372
   - **Signature:** `public func projectBakedToSession(_ bakedPosition: SIMD3<Float>) -> SIMD3<Float>?`
   - **Parameters:** `bakedPosition: SIMD3<Float>` (canonical position)
   - **Returns:** `SIMD3<Float>?` (session position)

7. **`getTriangleVertexPositionsFromBaked(_:)`**
   - **Location:** `ARCalibrationCoordinator.swift` line 2399
   - **Signature:** `public func getTriangleVertexPositionsFromBaked(_ triangleID: UUID) -> [UUID: SIMD3<Float>]?`
   - **Returns:** `[UUID: SIMD3<Float>]?` (map of vertex ID to baked position)

8. **`setMapParametersForBakedData(mapSize:metersPerPixel:)`**
   - **Location:** `ARCalibrationCoordinator.swift` line 3397
   - **Signature:** `public func setMapParametersForBakedData(mapSize: CGSize, metersPerPixel: Float)`
   - **Purpose:** Sets cached map parameters for baked data projection

9. **`computeSessionTransformForBakedData(mapSize:metersPerPixel:)`**
   - **Location:** `ARCalibrationCoordinator.swift` line 3413
   - **Signature:** `func computeSessionTransformForBakedData(mapSize: CGSize, metersPerPixel: Float) -> Bool`
   - **Returns:** `Bool` (success/failure)

10. **`bakeDownCalibrationSession(mapSize:metersPerPixel:)`**
    - **Location:** `ARCalibrationCoordinator.swift` line 3529
    - **Signature:** `func bakeDownCalibrationSession(mapSize: CGSize, metersPerPixel: Float) -> Int?`
    - **Returns:** `Int?` (number of positions baked)

11. **`updateBakedPositionIncrementally(mapPointID:sessionPosition:confidence:)`**
    - **Location:** `ARCalibrationCoordinator.swift` line 3665
    - **Signature:** `func updateBakedPositionIncrementally(mapPointID: UUID, sessionPosition: SIMD3<Float>, confidence: Float)`
    - **Parameters:** 
      - `mapPointID: UUID`
      - `sessionPosition: SIMD3<Float>` (current session AR position)
      - `confidence: Float` (0.0-1.0)
    - **Purpose:** Incrementally updates baked position with weighted average

12. **`debugBakedPositions()`**
    - **Location:** `ARCalibrationCoordinator.swift` line 3739
    - **Signature:** `func debugBakedPositions()`
    - **Purpose:** Debug output of baked positions

13. **`bakeDownHistoricalData(mapSize:metersPerPixel:)`**
    - **Location:** `MapPointStore.swift` line 1713
    - **Signature:** `func bakeDownHistoricalData(mapSize: CGSize, metersPerPixel: Float) -> Int?`
    - **Returns:** `Int?` (number of positions baked)
    - **Purpose:** Retrospective bake-down of all historical sessions

14. **`debugBakedPositionSummary()`**
    - **Location:** `MapPointStore.swift` line 1968
    - **Signature:** `func debugBakedPositionSummary()`
    - **Purpose:** Debug output of baked position summary

### Functions that process position history:

1. **`updateBakedPositionIncrementally(...)`**
   - **Full signature:** `func updateBakedPositionIncrementally(mapPointID: UUID, sessionPosition: SIMD3<Float>, confidence: Float)`
   - **File:** `ARCalibrationCoordinator.swift` line 3665
   - **Reads from:** `arPositionHistory.last` (line 3607) - checks latest record's sessionID
   - **Writes to:** `bakedCanonicalPosition`, `bakedConfidence`, `bakedSampleCount`

2. **`bakeDownHistoricalData(...)`**
   - **Full signature:** `func bakeDownHistoricalData(mapSize: CGSize, metersPerPixel: Float) -> Int?`
   - **File:** `MapPointStore.swift` line 1713
   - **Reads from:** `arPositionHistory` - iterates all records (lines 1734, 1751)
   - **Writes to:** `bakedCanonicalPosition`, `bakedConfidence`, `bakedSampleCount` (line 1921-1923)

3. **`consensusPosition` (computed property)**
   - **Location:** `MapPointStore.swift` line 242
   - **Reads from:** `arPositionHistory` - iterates and filters records
   - **Returns:** Weighted average position

---

## PART 4: Timestamp Audit

### Current timestamp usage:

**ARWorldMapStore.currentSessionStartTime:**
- **Set at:** `ARWorldMapStore.swift` line 741: `currentSessionStartTime = Date()` (in `startNewSession()`)
- **Read at:**
  - `ARCalibrationCoordinator.swift` line 736: Logging
  - `ARCalibrationCoordinator.swift` line 3320: `sessionTimestamp: safeARStore.currentSessionStartTime` (passed to ARMarker init)

**ARWorldMapStore.currentSessionID:**
- **Set at:** `ARWorldMapStore.swift` line 740: `currentSessionID = UUID()` (in `startNewSession()`)
- **Read at:**
  - `ARCalibrationCoordinator.swift` line 735: Logging
  - `ARCalibrationCoordinator.swift` lines 796, 1027, 2916, 3126: Passed to `ARPositionRecord` creation
  - `ARViewContainer.swift` line 1473: Logging

**Session END time:**
- **NOT CURRENTLY CAPTURED** - No `currentSessionEndTime` property exists
- Exit paths:
  - `ARCalibrationCoordinator.reset()` - no session end tracking
  - `ARViewContainer` dismiss/abort - no session end tracking
  - Calibration completion - no session end tracking

**ARPositionRecord.timestamp:**
- **JSON CodingKey:** `timestamp` (line 55)
- **Type:** `Date` (ISO8601 format)
- **Set at:** Default `Date()` in initializer (line 38), or explicit parameter
- **Used for:** Debug logging, chronological ordering

### AR Marker timestamps:

**ARMarker.createdAt:**
- **Location:** `ARWorldMapStore.swift` line 64
- **Type:** `Date`
- **Set at:** Initializer parameter (line 91), defaults to `Date()`
- **JSON CodingKey:** `createdAt` (line 107)

**ARMarker.sessionTimestamp:**
- **Location:** `ARWorldMapStore.swift` line 72
- **Type:** `Date`
- **Set at:** Initializer parameter (line 98), passed from `currentSessionStartTime`
- **JSON CodingKey:** `sessionTimestamp` (line 109)
- **Purpose:** Tracks which AR session created the marker

**ARMarker "last updated" timestamp:**
- **NOT CURRENTLY TRACKED** - No `lastUpdatedAt` or `modifiedAt` property

### Drift detection:

**Location:** `ARCalibrationCoordinator.swift` line 1091

**Function:** `detectDriftedMarkers(sceneView:sessionMarkerPositions:) -> [(mapPointID: UUID, recordedPosition: simd_float3, currentPosition: simd_float3, drift: Float)]`

**Data logged:**
- MapPoint ID
- Recorded position (from `sessionMarkerPositions`)
- Current position (from scene node)
- Drift amount (3D distance in meters)

**Timestamp captured:**
- **NO** - Drift detection does not capture timestamp
- Only logs positions and drift amount

**Camera pose available:**
- **YES** - `sceneView.session.currentFrame` is available (line 1096)
- But camera pose is not currently logged or stored

---

## PART 5: Session Lifecycle Audit

### Session start:

**Where `currentSessionID` is generated:**
- **Location:** `ARWorldMapStore.startNewSession()` line 740
- **Code:** `currentSessionID = UUID()`
- **Also sets:** `currentSessionStartTime = Date()`

**What else happens at session start:**
- Logging: Session ID and timestamp printed (lines 742-743)
- Relocalization TODO comments (lines 745-750) - future feature

**Hook opportunities:**
- `startNewSession()` is the single entry point
- Could add session tracking struct creation here

### Session end:

**Single "session ended" function:**
- **NO** - No dedicated session end function exists

**Multiple exit paths:**

1. **Calibration abort/reset:**
   - `ARCalibrationCoordinator.reset()` (line ~524)
   - Clears coordinator state but doesn't track session end

2. **ARViewContainer dismiss:**
   - No explicit session end tracking
   - Scene cleanup happens but no session record

3. **Calibration complete:**
   - `finalizeCalibration(for:)` (line 2456)
   - Marks triangle as calibrated
   - Adds to `sessionCalibratedTriangles` set
   - But doesn't create session record

**Cleanup at each exit path:**
- `reset()` clears: `activeTriangleID`, `placedMarkers`, `triangleVertices`, etc.
- No session-level cleanup or recording

### Session data that should be captured:

**Triangles calibrated during session:**
- **Currently tracked:** `sessionCalibratedTriangles: Set<UUID>` (line ~2461)
- **Stored:** In-memory only, not persisted
- **Cleared:** On `reset()` or new session start

**MapPoints that received new positions:**
- **Currently tracked:** Via `arPositionHistory` records with `sessionID`
- **Can query:** `points.filter { $0.arPositionHistory.contains { $0.sessionID == sessionID } }`
- **Not aggregated:** No session-level summary

**Other session data:**
- **NOT CURRENTLY TRACKED:**
  - Session duration
  - Session end time
  - Number of triangles calibrated
  - Number of MapPoints updated
  - Drift events during session
  - Camera poses at key moments

---

## PART 6: Proposed New Fields — Impact Assessment

### If we add to ARPositionRecord:

**`placementTimestamp: Date`**
- **Clarification needed:** Existing `timestamp` field (line 29) appears to be placement time already
- **Current usage:** `timestamp` defaults to `Date()` in initializer (line 38)
- **Impact:** Low - would be redundant unless we need separate "recorded" vs "placed" times

**Recommendation:** Keep existing `timestamp` as placement time, document clearly

### If we add to MapPoint:

**`lastDriftDetectedAt: Date?`**
- **Impact:** Medium
- **Write locations needed:**
  - `detectDriftedMarkers()` (line 1091) - when drift detected
- **Read locations:** Diagnostic/debug functions
- **CodingKey:** `lastDriftDetectedAt` (add to CodingKeys enum)

**`lastDriftAmount: Float?`**
- **Impact:** Medium
- **Write locations:** Same as `lastDriftDetectedAt`
- **Read locations:** Diagnostic/debug functions
- **CodingKey:** `lastDriftAmount`

**`lastDriftCameraPose: simd_float4x4?`**
- **Impact:** High (new type)
- **Write locations:** `detectDriftedMarkers()` - need to extract camera pose from `currentFrame`
- **Read locations:** Diagnostic/debug functions
- **CodingKey:** `lastDriftCameraPoseArray` (encode as 16-element Float array)
- **Storage:** ~64 bytes per MapPoint (if non-nil)

### If we add ARCalibrationSession struct:

**Storage location:**
- **Option 1:** New `ARCalibrationSessionStore` (similar to `MapPointStore`, `TrianglePatchStore`)
- **Option 2:** Inside `ARWorldMapStore` as `@Published var sessions: [ARCalibrationSession]`
- **Recommendation:** Option 1 (separate store) for better separation of concerns

**Trigger creation:**
- **Session start:** `ARWorldMapStore.startNewSession()` - create session record
- **Session end:** New `endSession()` function called from:
  - `ARCalibrationCoordinator.reset()` (abort)
  - `ARViewContainer` dismiss handler
  - Calibration completion handler

**Fields to populate:**
- `id: UUID` (from `currentSessionID`)
- `startTime: Date` (from `currentSessionStartTime`)
- `endTime: Date?` (set on session end)
- `trianglesCalibrated: [UUID]` (from `sessionCalibratedTriangles`)
- `mapPointsUpdated: [UUID]` (derived from `arPositionHistory` filtering)
- `driftEvents: [DriftEvent]` (new struct: `{ mapPointID, timestamp, amount, cameraPose }`)

---

## Summary: Key Findings

### Timestamp Opportunities:

**Session start:** ✅ `ARWorldMapStore.startNewSession()` line 740
**Session end:** ❌ NOT CURRENTLY CAPTURED - exit paths at:
- `ARCalibrationCoordinator.reset()` line ~524 (abort)
- `ARViewContainer` dismiss (no explicit handler found)
- `finalizeCalibration()` line 2456 (completion)

### Property Access Patterns:

- **`bakedCanonicalPosition`:** Direct access, no wrappers, stored as array in JSON
- **`bakedConfidence`:** Direct access, nil-coalescing common
- **`bakedSampleCount`:** Direct access, only encoded if > 0
- **`arPositionHistory`:** Heavy read/write usage, append/remove operations
- **`consensusPosition`:** Computed property, depends on `arPositionHistory`

### Critical Gaps:

1. **No session end tracking** - sessions start but never formally end
2. **No drift event logging** - drift detected but not persisted
3. **No camera pose capture** - available but not stored
4. **No session-level aggregation** - data exists but not summarized per session

