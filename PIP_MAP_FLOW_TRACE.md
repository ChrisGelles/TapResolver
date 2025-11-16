# PiP Map Display Flow Trace

Complete trace of how the PiP (Picture-in-Picture) Map is displayed in AR View, starting from Map Point selection.

## Flow Overview

1. **Map Point Selection** → Triangle Selection → AR View Launch → PiP Map Display
2. **OR**: Generic AR View Launch → PiP Map Display (no calibration)

---

## Step-by-Step Flow

### STEP 1: Map Point Selection & Triangle Creation

**File**: `TapResolver/UI/Overlays/MapPointOverlay.swift`
- User taps a Map Point dot on the map
- Map Point becomes selected
- Triangles are created from groups of 3 Map Points

**File**: `TapResolver/UI/Overlays/TriangleOverlay.swift`
- Triangles are rendered on the map
- User can **tap** to select a triangle (line 29-32)
- User can **long-press** (0.5s) to start calibration (line 33-45)

**Key Code**:
```swift
// Line 39-43: Long-press triggers calibration
NotificationCenter.default.post(
    name: NSNotification.Name("StartTriangleCalibration"),
    object: nil,
    userInfo: ["triangleID": triangle.id]
)
```

---

### STEP 2: AR View Launch Request

**File**: `TapResolver/UI/Root/MapNavigationView.swift`
- Listens for `StartTriangleCalibration` notification (line 63)
- Extracts triangle from notification
- Calls `arViewLaunchContext.launchTriangleCalibration(triangle:)` (line 69)

**Key Code**:
```swift
// Line 63-69: Notification handler
.onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("StartTriangleCalibration"))) { notification in
    if let triangleID = notification.userInfo?["triangleID"] as? UUID,
       let triangle = triangleStore.triangles.first(where: { $0.id == triangleID }) {
        arViewLaunchContext.launchTriangleCalibration(triangle: triangle)
    }
}
```

---

### STEP 3: AR View Launch Context

**File**: `TapResolver/State/ARViewLaunchContext.swift`
- Sets `isCalibrationMode = true` (line 29)
- Sets `selectedTriangle = triangle` (line 30)
- Sets `isPresented = true` (line 31)

**Key Code**:
```swift
// Line 27-34: Launch triangle calibration
func launchTriangleCalibration(triangle: TrianglePatch) {
    DispatchQueue.main.async {
        self.isCalibrationMode = true
        self.selectedTriangle = triangle
        self.isPresented = true
    }
}
```

---

### STEP 4: ContentView Presents AR View

**File**: `TapResolver/UI/Root/ContentView.swift`
- Monitors `arViewLaunchContext.isPresented` (line 39)
- Presents `ARViewWithOverlays` as fullScreenCover (line 38-54)
- Passes `isCalibrationMode` and `selectedTriangle` (line 51-52)

**Key Code**:
```swift
// Line 38-54: Full screen cover presentation
.fullScreenCover(isPresented: Binding(
    get: { arViewLaunchContext.isPresented },
    set: { newValue in
        if !newValue {
            arViewLaunchContext.dismiss()
        }
    }
)) {
    ARViewWithOverlays(
        isPresented: Binding(...),
        isCalibrationMode: arViewLaunchContext.isCalibrationMode,
        selectedTriangle: arViewLaunchContext.selectedTriangle
    )
}
```

---

### STEP 5: ARViewWithOverlays Initialization

**File**: `TapResolver/ARFoundation/ARViewWithOverlays.swift`

**Line 14-38**: View struct initialization
- Receives `isCalibrationMode` and `selectedTriangle` as parameters
- Creates `RelocalizationCoordinator` instance

**Line 40-79**: View body setup
- Creates `ARViewContainer` (line 43-50)
- Sets `currentMode` based on calibration mode (line 60-72)
- If calibration mode: `currentMode = .triangleCalibration(triangleID: triangle.id)` (line 61)
- Initializes `arCalibrationCoordinator` (line 65)
- Sets vertices for legacy compatibility (line 67)

**Key Code**:
```swift
// Line 60-72: Mode setup
if isCalibrationMode, let triangle = selectedTriangle {
    currentMode = .triangleCalibration(triangleID: triangle.id)
    arCalibrationCoordinator.startCalibration(for: triangle.id)
    arCalibrationCoordinator.setVertices(triangle.vertexIDs)
} else {
    currentMode = .idle
}
```

---

### STEP 6: PiP Map View Creation

**File**: `TapResolver/ARFoundation/ARViewWithOverlays.swift`

**Line 168-181**: PiP Map View placement
- Creates `ARPiPMapView` (line 170-174)
- Positioned at top-right: `x: geo.size.width - 100, y: 110` (line 180)
- Frame size: `width: 180, height: 180` (line 178)
- Z-index: `998` (line 181)

**Key Code**:
```swift
// Line 170-181: PiP Map View
ARPiPMapView(
    focusedPointID: isCalibrationMode ? arCalibrationCoordinator.getCurrentVertexID() : nil,
    isCalibrationMode: isCalibrationMode,
    selectedTriangle: selectedTriangle
)
    .environmentObject(mapPointStore)
    .environmentObject(locationManager)
    .environmentObject(arCalibrationCoordinator)
    .frame(width: 180, height: 180)
    .cornerRadius(12)
    .position(x: geo.size.width - 100, y: 110)
    .zIndex(998)
```

**Numbers Explained**:
- **Position X**: `geo.size.width - 100` = Screen width minus 100 points (half of 180px width + margin)
- **Position Y**: `110` = Top margin (50 for exit button) + spacing
- **Frame**: `180x180` = Fixed PiP size
- **Corner Radius**: `12` = Rounded corners

---

### STEP 7: ARPiPMapView Initialization

**File**: `TapResolver/ARFoundation/ARViewWithOverlays.swift`

**Line 413-543**: ARPiPMapView struct

**Line 425-432**: State variables
- `mapImage: UIImage?` - The map image to display
- `currentTransform: PiPMapTransform` - Current zoom/pan transform (starts as `.identity`)
- `userMapPosition: CGPoint?` - User's position on map (for calibration mode)
- `positionUpdateTimer: Timer?` - Timer for position updates (1 second interval)
- `positionSamples: [simd_float3]` - Ring buffer for smoothing (max 5 samples)

**Line 498-503**: onAppear
- Calls `loadMapImage()` (line 499)
- If calibration mode: calls `startUserPositionTracking()` (line 500-501)

**Key Code**:
```swift
// Line 498-503: Initialization
.onAppear {
    loadMapImage()
    if isCalibrationMode {
        startUserPositionTracking()
    }
}
```

---

### STEP 8: Map Image Loading

**File**: `TapResolver/ARFoundation/ARViewWithOverlays.swift`

**Line 545-567**: `loadMapImage()` function

**Flow**:
1. Gets `locationID` from `locationManager.currentLocationID` (line 546)
2. Tries loading from Documents: `LocationImportUtils.loadDisplayImage(locationID:)` (line 549)
3. Falls back to bundled assets based on locationID:
   - `"home"` → `"myFirstFloor_v03-metric"` (line 558)
   - `"museum"` → `"MuseumMap-8k"` (line 560)

**Key Code**:
```swift
// Line 545-567: Map loading
private func loadMapImage() {
    let locationID = locationManager.currentLocationID
    
    // Try Documents first
    if let image = LocationImportUtils.loadDisplayImage(locationID: locationID) {
        mapImage = image
        return
    }
    
    // Fallback to bundled assets
    let assetName: String
    switch locationID {
    case "home": assetName = "myFirstFloor_v03-metric"
    case "museum": assetName = "MuseumMap-8k"
    default: mapImage = nil; return
    }
    
    mapImage = UIImage(named: assetName)
}
```

---

### STEP 9: Transform Initialization

**File**: `TapResolver/ARFoundation/ARViewWithOverlays.swift`

**Line 513-535**: `onChange(of: mapImage)`

When map image loads:
1. Creates frame size: `CGSize(width: 180, height: 180)` (line 516)
2. Calls `PiPMapTransform.centered()` to create initial transform (line 517)
3. Animates transform with `easeInOut(duration: 0.5)` (line 526-528)
4. If `focusedPointID` exists, calls `updateFocus()` (line 531-532)

**Key Code**:
```swift
// Line 513-535: Transform initialization
.onChange(of: mapImage) { _ in
    if let mapImage = mapImage {
        let frameSize = CGSize(width: 180, height: 180)
        let centeredTransform = PiPMapTransform.centered(on: mapImage.size, in: frameSize)
        
        withAnimation(.easeInOut(duration: 0.5)) {
            currentTransform = centeredTransform
        }
        
        if focusedPointID != nil {
            updateFocus(on: focusedPointID)
        }
    }
}
```

---

### STEP 10: PiPMapTransform.centered() Calculation

**File**: `TapResolver/ARFoundation/ARViewWithOverlays.swift`

**Line 357-361**: `centered()` static function

**Calculation**:
```swift
static func centered(on imageSize: CGSize, in frameSize: CGSize) -> PiPMapTransform {
    // .scaledToFit() already handles fitting, so scale should be 4.0 (zoomed in)
    return PiPMapTransform(scale: 16.0, offset: .zero)
}
```

**Numbers Explained**:
- **Scale**: `16.0` = Zoom level (16x zoom into the map)
- **Offset**: `.zero` = No pan offset (centered)

**Note**: The comment says "4.0" but code uses `16.0`. This is the zoom level applied AFTER `.scaledToFit()`.

---

### STEP 11: PiPMapTransform.focused() Calculation (When Point Selected)

**File**: `TapResolver/ARFoundation/ARViewWithOverlays.swift`

**Line 363-408**: `focused()` static function

**Called when**: A Map Point is selected and we want to zoom to it

**Parameters**:
- `point: CGPoint` - The Map Point coordinates (in map image space)
- `imageSize: CGSize` - Map image dimensions
- `frameSize: CGSize` - PiP frame size (180x180)
- `targetZoom: CGFloat = 16.0` - Desired zoom level

**Step-by-Step Calculation**:

1. **Calculate map center** (line 370):
   ```swift
   let Cmap = CGPoint(x: imageSize.width / 2, y: imageSize.height / 2)
   ```
   - Example: If map is 2000x1500, `Cmap = (1000, 750)`

2. **Calculate vector from center to point** (line 371):
   ```swift
   let v = CGPoint(x: point.x - Cmap.x, y: point.y - Cmap.y)
   ```
   - Example: If point is at (1200, 900), `v = (200, 150)`

3. **Calculate base scale** (line 375):
   ```swift
   let baseScale = min(frameSize.width / imageSize.width, frameSize.height / imageSize.height)
   ```
   - Example: `frameSize = (180, 180)`, `imageSize = (2000, 1500)`
   - `baseScale = min(180/2000, 180/1500) = min(0.09, 0.12) = 0.09`
   - This is the scale to fit entire map in frame

4. **Calculate total scale** (line 376):
   ```swift
   let totalScale = baseScale * targetZoom
   ```
   - Example: `totalScale = 0.09 * 16.0 = 1.44`
   - This is the final scale after zoom

5. **Scale the vector** (line 379):
   ```swift
   let vScaled = CGPoint(x: v.x * totalScale, y: v.y * totalScale)
   ```
   - Example: `vScaled = (200 * 1.44, 150 * 1.44) = (288, 216)`

6. **Rotation** (line 382-388):
   ```swift
   let theta: CGFloat = 0.0  // No rotation for PiP Map
   let c = cos(theta)  // = 1.0
   let ss = sin(theta)  // = 0.0
   let vRot = CGPoint(
       x: c * vScaled.x - ss * vScaled.y,  // = vScaled.x
       y: ss * vScaled.x + c * vScaled.y   // = vScaled.y
   )
   ```
   - Since theta = 0, `vRot = vScaled` (no rotation)

7. **Calculate offset** (line 391):
   ```swift
   let newOffset = CGSize(width: -vRot.x, height: -vRot.y)
   ```
   - Example: `newOffset = (-288, -216)`
   - Negative because we offset the image to bring the point to center

8. **Return transform** (line 404-407):
   ```swift
   return PiPMapTransform(
       scale: targetZoom,      // 16.0
       offset: newOffset       // (-288, -216)
   )
   ```

**Numbers Summary**:
- **targetZoom**: `16.0` (constant)
- **baseScale**: `min(frameWidth/imageWidth, frameHeight/imageHeight)` ≈ `0.09` for typical map
- **totalScale**: `baseScale * targetZoom` ≈ `1.44`
- **offset**: `-vScaled` (negative of scaled vector)

---

### STEP 12: Image Rendering with Transform

**File**: `TapResolver/ARFoundation/ARViewWithOverlays.swift`

**Line 436-487**: View body rendering

**Line 439-444**: Image with transforms
```swift
Image(uiImage: mapImage)
    .resizable()
    .scaledToFit()
    .frame(width: geo.size.width, height: geo.size.height)
    .scaleEffect(currentTransform.scale, anchor: .center)
    .offset(currentTransform.offset)
```

**Transform Application Order**:
1. `.scaledToFit()` - Fits image to 180x180 frame (maintains aspect ratio)
2. `.scaleEffect(scale, anchor: .center)` - Applies zoom (16.0x)
3. `.offset(offset)` - Applies pan offset

**Numbers Explained**:
- **Frame**: `180x180` points (fixed PiP size)
- **Scale**: `16.0` (zoom level)
- **Offset**: Calculated to center on selected point (e.g., `(-288, -216)`)

---

### STEP 13: User Position Tracking (Calibration Mode Only)

**File**: `TapResolver/ARFoundation/ARViewWithOverlays.swift`

**Line 614-661**: User position tracking functions

**Line 616-630**: `startUserPositionTracking()`
- Sets `isAnimating = true` (line 620)
- Creates timer: `Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true)` (line 624)
- Calls `updateUserPosition()` immediately (line 629)

**Line 640-661**: `updateUserPosition()`
- Gets camera position from `ARViewContainer.Coordinator.current.getCurrentCameraPosition()` (line 642-643)
- Adds to ring buffer (max 5 samples) (line 649-652)
- Averages samples for smoothing (line 655)
- Projects AR position to map coordinates via `projectARPositionToMap()` (line 658)

**Numbers Explained**:
- **Timer interval**: `1.0` second (updates once per second)
- **Ring buffer size**: `5` samples (for smoothing)
- **Smoothing**: Average of last 5 samples

---

### STEP 14: AR Position to Map Projection

**File**: `TapResolver/ARFoundation/ARViewWithOverlays.swift`

**Line 663-725**: `projectARPositionToMap()` function

**Requirements**:
- Need at least 2 placed markers (line 673)
- Uses barycentric interpolation for 3 points (line 711-716)
- Uses linear interpolation for 2 points (line 718-723)

**Line 727-780**: `projectUsingBarycentric()` - For 3 markers
- Projects AR positions to 2D plane (XZ plane, ignoring Y height) (line 739-742)
- Calculates barycentric coordinates (u, v, w) (line 744-752)
- Checks if point is inside triangle (line 755)
- Interpolates map positions using barycentric weights (line 757-776)

**Line 782-813**: `projectUsingLinear()` - For 2 markers
- Projects to 2D plane (XZ) (line 794)
- Calculates interpolation parameter `t` (line 800)
- Linearly interpolates map positions (line 807-810)

**Numbers Explained**:
- **Plane**: XZ plane (ignoring Y/height)
- **Minimum markers**: 2 for linear, 3 for barycentric
- **Barycentric check**: `u >= 0 && v >= 0 && (u + v) <= 1`

---

### STEP 15: User Position Dot Rendering

**File**: `TapResolver/ARFoundation/ARViewWithOverlays.swift`

**Line 446-481**: User position dot overlay

**Line 448-459**: Coordinate conversion
```swift
let mapSize = mapImage.size
let scaleToFit = min(geo.size.width / mapSize.width, geo.size.height / mapSize.height)
let mapCenter = CGPoint(x: mapSize.width / 2, y: mapSize.height / 2)
let offsetFromMapCenter = CGPoint(
    x: userPos.x - mapCenter.x,
    y: userPos.y - mapCenter.y
)
let scaledX = offsetFromMapCenter.x * scaleToFit * currentTransform.scale + currentTransform.offset.width + geo.size.width / 2
let scaledY = offsetFromMapCenter.y * scaleToFit * currentTransform.scale + currentTransform.offset.height + geo.size.height / 2
```

**Step-by-Step Conversion**:
1. **scaleToFit**: Scale to fit map in frame (e.g., `0.09`)
2. **offsetFromMapCenter**: User position relative to map center
3. **Apply scaleToFit**: `offsetFromMapCenter * scaleToFit`
4. **Apply zoom**: `* currentTransform.scale` (16.0)
5. **Apply pan**: `+ currentTransform.offset`
6. **Center in view**: `+ geo.size.width/2` and `+ geo.size.height/2`

**Line 460-480**: Dot rendering
- Base dot: `Circle()` with `frame(width: 15, height: 15)` (line 464-465)
- Pulse ring: `Circle()` with `stroke()` (line 468-470)
- Animation: Scales from `1.0` to `22.0/15.0` (1.47x) (line 471)
- Opacity: Fades from `0.5` to `0.0` (line 472)
- Duration: `1.0` second, repeats forever (line 475)

**Numbers Explained**:
- **Dot size**: `15x15` points
- **Pulse scale**: `22.0/15.0 = 1.47` (grows 47% larger)
- **Animation duration**: `1.0` second
- **Colors**: 
  - Base: `RGB(103, 31, 121)` - Purple
  - Ring: `RGB(73, 206, 248)` - Cyan

---

### STEP 16: Focus Update (When Point Changes)

**File**: `TapResolver/ARFoundation/ARViewWithOverlays.swift`

**Line 510-512**: `onChange(of: focusedPointID)`
- Calls `updateFocus(on: newPointID)` when focused point changes

**Line 569-612**: `updateFocus()` function

**When focusedPointID is set** (line 578-598):
1. Gets MapPoint from store (line 579)
2. Calls `PiPMapTransform.focused()` with point coordinates (line 581-586)
3. Animates transform with `easeInOut(duration: 0.5)` (line 596-598)

**When focusedPointID is nil** (line 599-611):
1. Calls `PiPMapTransform.centered()` (line 601)
2. Animates back to full map view (line 608-610)

**Numbers Explained**:
- **Animation duration**: `0.5` seconds
- **Easing**: `.easeInOut` (smooth acceleration/deceleration)

---

## Summary of Key Numbers

### PiP Map Dimensions
- **Frame Size**: `180 x 180` points
- **Position**: Top-right (`screenWidth - 100, 110`)
- **Corner Radius**: `12` points
- **Z-Index**: `998`

### Transform Values
- **Default Zoom**: `16.0x`
- **baseScale**: `min(180/mapWidth, 180/mapHeight)` ≈ `0.09` (for 2000x1500 map)
- **totalScale**: `baseScale * zoom` ≈ `1.44`
- **Offset**: Calculated to center on selected point

### User Position Tracking
- **Update Interval**: `1.0` second
- **Smoothing Buffer**: `5` samples
- **Dot Size**: `15x15` points
- **Pulse Scale**: `1.47x` (22/15)
- **Animation Duration**: `1.0` second

### Animation Timings
- **Transform Animation**: `0.5` seconds (`.easeInOut`)
- **Initial Load Animation**: `0.5` seconds

---

## File Reference

1. **TriangleOverlay.swift** - Triangle selection & calibration trigger
2. **MapNavigationView.swift** - Notification handler & AR launch
3. **ARViewLaunchContext.swift** - AR view state management
4. **ContentView.swift** - AR view presentation
5. **ARViewWithOverlays.swift** - Main AR view with PiP map (lines 14-815)
   - PiP Map View: Lines 170-181, 413-814
   - Transform calculations: Lines 348-409
   - User position tracking: Lines 614-813

