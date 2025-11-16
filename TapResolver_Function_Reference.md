# TapResolver Function/Method Reference

This document provides a comprehensive list of every function and method in the TapResolver codebase, organized by file, with 2-3 sentence descriptions of each.

---

## TapResolverApp.swift

**`init()`** - Initializes the main app entry point, creating temporary store references for `ARCalibrationCoordinator` that are later updated in `onAppear` to point to actual `@StateObject` instances. Sets up the app's core environment objects and prepares for location migration.

**`body`** - Defines the main `WindowGroup` structure, injecting all environment objects (`MapTransformStore`, `BeaconDotStore`, `MapPointStore`, `ARWorldMapStore`, `ARCalibrationCoordinator`) into the view hierarchy. Includes `onAppear` for post-initialization setup and presents `AuthorNamePromptView` as a sheet when needed.

**`migrateLegacyLocations()`** - Iterates through predefined location IDs ("home", "museum", "default") and calls `LocationImportUtils.migrateLocationMetadata` to update their `location.json` files with new metadata fields. Ensures backward compatibility by enriching older location data with fields like `originalID`, `createdBy`, `lastModifiedBy`, `beaconCount`, and `sessionCount`.

---

## AppBootstrap.swift

**`body(content: Content)`** - The main `ViewModifier` method that performs one-time app-level bootstrapping when `ContentView` appears. Ensures bootstrap logic runs only once via an `onAppear` block, calling `createLocationStubIfNeeded()`, configuring scanner and scan utility closures, starting beacon state monitoring, and initiating continuous Bluetooth scanning.

**`configureScanUtilityClosures()`** - Sets up various closures for `MapPointScanUtility`, including `isExcluded` (filters beacons not in `BeaconListsStore`), `resolveBeaconMeta` (provides beacon metadata from `BeaconDotStore` and `BluetoothScanner`), `getPixelsPerMeter` (from `MetricSquareStore`), `getFusedHeadingDegrees` (from `CompassOrientationManager`), and orientation-related closures from `SquareMetrics`.

**`createLocationStubIfNeeded()`** - Creates a `location.json` stub file for the current location if it doesn't already exist. The stub contains basic metadata like ID, name, and creation/update timestamps, ensuring every location has a valid configuration file.

**`extension View.appBootstrap(...)`** - Convenience extension method that allows any `View` to apply the `AppBootstrap` modifier with necessary environment objects. Simplifies the application of bootstrap logic across the app.

---

## ARViewWithOverlays.swift

**`init(isPresented: Binding<Bool>, isCalibrationMode: Bool = false, selectedTriangle: TrianglePatch? = nil)`** - Initializes the AR view wrapper, setting up bindings and injecting a temporary `ARWorldMapStore` into `RelocalizationCoordinator` which is updated in `onAppear`. Configures the view for either generic AR mode or triangle calibration mode.

**`body`** - Contains a `ZStack` that layers the `ARViewContainer` with various UI elements like exit button, `ARPiPMapView`, `ARReferenceImageView`, and "Place Marker" buttons, depending on `currentMode` and `isCalibrationMode`. Manages the overall AR experience UI.

**`.onAppear`** - Updates the `relocalizationCoordinator` with the actual `arWorldMapStore` and sets the `currentMode` based on whether it's in calibration mode for a specific triangle. Initializes the `arCalibrationCoordinator` for the selected triangle.

**`.onDisappear`** - Resets the `currentMode` to `.idle` and calls `arCalibrationCoordinator.reset()` for cleanup. Ensures proper state management when leaving the AR view.

**`.onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ARMarkerPlaced")))`** - Handles the notification when an AR marker is placed. In calibration mode, registers the marker with `arCalibrationCoordinator`, potentially auto-captures and replaces outdated photos for the linked `MapPoint`, and updates the `MapPointStore`.

**`.onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UpdateMapPointPhoto")))`** - Handles requests to update a `MapPoint`'s photo, currently logging the request and serving as a placeholder for future photo capture UI integration.

**`PiPMapTransform.identity`** - Returns an identity transform for the Picture-in-Picture map, representing no scaling, rotation, or translation.

**`PiPMapTransform.centered(on imageSize: CGSize, in frameSize: CGSize)`** - Creates a transform to center the map image within a given frame size. Calculates appropriate scale and offset to display the full map centered in the available space.

**`PiPMapTransform.focused(on point: CGPoint, imageSize: CGSize, frameSize: CGSize, targetZoom: CGFloat = 16.0)`** - Creates a transform to zoom and center the map on a specific point, using logic similar to `MapTransformStore.centerOnPoint()`. Applies a target zoom level to focus on a particular map coordinate.

**`ARPiPMapView.loadMapImage()`** - Loads the map image for the current location, first attempting to load from the Documents directory, then falling back to bundled assets. Handles image loading failures gracefully.

**`ARPiPMapView.setupPiPTransform(image: UIImage, frameSize: CGSize)`** - Binds the `pipProcessor` to `pipTransform` and sets the map and screen sizes. Prepares the Picture-in-Picture map for display.

**`ARPiPMapView.calculateTargetTransform(image: UIImage, frameSize: CGSize)`** - Determines the appropriate scale and offset for the PiP map based on whether a single point is focused, a triangle is being calibrated, or the full map should be shown. Returns a tuple with scale and offset values.

**`ARPiPMapView.calculateFullMapTransform(frameSize: CGSize, imageSize: CGSize)`** - Calculates the transform to display the entire map within the frame. Ensures the full map is visible with appropriate scaling.

**`ARPiPMapView.calculateFittingTransform(points: [CGPoint], frameSize: CGSize, imageSize: CGSize, padding: CGFloat = 40)`** - Calculates the transform to fit multiple points (e.g., a triangle) within the frame with padding. Ensures all specified points are visible with a comfortable margin.

**`ARPiPMapView.calculateScale(pointA: CGPoint, pointB: CGPoint, frameSize: CGSize, imageSize: CGSize)`** - Calculates the scaling factor to fit a region defined by two points. Determines the zoom level needed to show the area between two map coordinates.

**`ARPiPMapView.calculateOffset(pointA: CGPoint, pointB: CGPoint, frameSize: CGSize, imageSize: CGSize)`** - Calculates the offset to center a region defined by two points. Computes the translation needed to center the area between two map coordinates.

**`ARPiPMapView.startUserPositionTracking()`** - Initiates a timer to periodically update the user's position on the PiP map during calibration. Enables real-time position visualization.

**`ARPiPMapView.stopUserPositionTracking()`** - Invalidates the timer and clears user position data. Stops position tracking when calibration is complete or cancelled.

**`ARPiPMapView.updateUserPosition()`** - Retrieves the current AR camera position, smooths it using a ring buffer, and projects it onto the 2D map. Updates the displayed user position indicator.

**`ARPiPMapView.projectARPositionToMap(arPosition: simd_float3)`** - Projects a 3D AR world position to 2D map coordinates using barycentric or linear interpolation based on the placed AR markers for the selected triangle. Returns the projected map point or nil if projection fails.

**`ARPiPMapView.projectUsingBarycentric(userARPos: simd_float3, arPositions: [simd_float3], mapPositions: [CGPoint])`** - Performs barycentric interpolation for 3 points to project a user's AR position to the 2D map. Uses triangle-based interpolation for accurate 2D projection.

**`ARPiPMapView.projectUsingLinear(userARPos: simd_float3, arPositions: [simd_float3], mapPositions: [CGPoint])`** - Performs linear interpolation for 2 points to project a user's AR position to the 2D map. Uses simpler linear interpolation when only two calibration points are available.

---

## ARViewContainer.swift

**`makeCoordinator() -> ARViewCoordinator`** - Creates and returns an `ARViewCoordinator` instance, passing `selectedTriangle` and `isCalibrationMode` to configure it. Sets up the coordinator that manages AR session interactions.

**`makeUIView(context: Context) -> ARSCNView`** - Configures and returns an `ARSCNView` for display. Sets up the AR session with `ARWorldTrackingConfiguration`, enables debug options, and sets the coordinator as the delegate. Initializes the AR experience.

**`updateUIView(_ uiView: ARSCNView, context: Context)`** - Updates the coordinator's mode and stores a static reference to the current coordinator. Ensures the coordinator reflects the current AR view state.

**`ARViewCoordinator.setMode(_ mode: ARMode)`** - Updates the current AR mode and calls `handleModeChange`. Changes the operational mode of the AR view (idle, calibration, interpolation, etc.).

**`ARViewCoordinator.handleModeChange(_ mode: ARMode)`** - Logs the current AR mode for debugging purposes. Provides visibility into mode transitions.

**`ARViewCoordinator.setupTapGesture()`** - Configures a `UITapGestureRecognizer` for the `sceneView` and adds an observer for the "PlaceMarkerAtCursor" notification. Enables tap-to-place marker functionality.

**`ARViewCoordinator.handlePlaceMarkerAtCursor()`** - Places an AR marker at the current `currentCursorPosition` when the "PlaceMarkerAtCursor" notification is received. Allows programmatic marker placement.

**`ARViewCoordinator.handleTapGesture(_ sender: UITapGestureRecognizer)`** - Handles tap gestures, performing a hit test to find a world position and then calling `placeMarker(at:)`. Tap-to-place is disabled in idle and triangle calibration modes for safety.

**`ARViewCoordinator.placeMarker(at position: simd_float3)`** - Creates and adds an `ARMarkerRenderer` node to the scene at the specified 3D position. Determines the marker's color and animation based on the `currentMode` and posts an "ARMarkerPlaced" notification.

**`ARViewCoordinator.setupScene()`** - Configures the AR scene by adding a `GroundCrosshairNode` and starting a timer to update its position. Sets up visual feedback for plane detection.

**`ARViewCoordinator.updateCrosshair()`** - Performs a raycast from the screen center to detect horizontal planes, updates the `GroundCrosshairNode`'s position and confidence, and sets `currentCursorPosition`. Provides real-time visual feedback for marker placement.

**`ARViewCoordinator.isPlaneConfident(_ result: ARRaycastResult) -> Bool`** - Checks if a detected plane is confident enough based on its extent. Validates plane quality before allowing marker placement.

**`ARViewCoordinator.findNearbyCorner(from position: simd_float3) -> simd_float3?`** - Placeholder for future corner detection logic (currently returns `nil`). Reserved for advanced marker placement features.

**`ARViewCoordinator.getCurrentWorldMap(completion: @escaping (ARWorldMap?, Error?) -> Void)`** - Asynchronously retrieves the current `ARWorldMap` from the AR session. Captures the spatial understanding of the environment for persistence.

**`ARViewCoordinator.captureARFrame(completion: @escaping (UIImage?) -> Void)`** - Captures the current AR camera frame as a `UIImage`. Enables photo capture from the AR view.

**`ARViewCoordinator.getCurrentCameraPosition() -> simd_float3?`** - Returns the current AR camera's world position. Provides the user's location in AR space.

**`ARViewCoordinator.teardownSession()`** - Invalidates timers, removes notification observers, and pauses the AR session. Performs cleanup when the AR view is dismissed.

---

## ARReferenceImageView.swift

**`body`** - Displays the reference image with an overlay indicating if it's `isOutdated`. Includes a "Retake Photo" button if the image is outdated and allows tapping to show a full-screen version. Provides visual feedback about photo currency.

**`FullImageView.body`** - Presents the reference image in full screen, also indicating if it's outdated and offering a "Retake Photo" option. Allows users to view and update reference images.

---

## ARMarkerRenderer.swift

**`createNode(at position: simd_float3, options: MarkerOptions) -> SCNNode`** - Creates a composite `SCNNode` representing an AR marker. The node consists of a floor ring, a fill, a vertical rod, and a sphere at the top. Applies animation if `animateOnAppearance` is true.

**`animateMarkerPlacement(...)`** - Handles the animation sequence for marker placement, including scaling the ring, growing the rod, and moving/scaling the sphere with an overshoot and settle effect. Provides visual feedback when markers are placed.

---

## ARMode.swift

**`enum ARMode`** - Defines the different operational modes for the AR view. Cases include `idle`, `calibration(mapPointID:)`, `triangleCalibration(triangleID:)`, `interpolation(firstID:secondID:)`, `anchor(mapPointID:)`, and `metricSquare(squareID:sideLength:)` (currently removed).

---

## UIColor+ARPalette.swift

**`ARPalette`** - Contains static `UIColor` properties for AR markers and other AR-related UI elements. Defines colors for `markerBase`, `markerRing`, `markerFill`, `markerLine`, `badge`, and mode-specific colors like `calibration` (orange) and `anchor` (cyan). Provides a centralized color palette.

---

## ARSurveyCoordinator.swift

**`init(arWorldMapStore: ARWorldMapStore)`** - Initializes with an `ARWorldMapStore` and sets itself as the delegate for its `ARSession`. Prepares the coordinator for AR world map capture.

**`startSurvey()`** - Configures and runs an `ARWorldTrackingConfiguration` with plane detection and optional scene reconstruction. Begins the AR survey process for capturing a world map.

**`stopSurvey()`** - Pauses the AR session. Stops the survey process.

**`captureMap(center2D: CGPoint? = nil, patchName: String? = nil, completion: @escaping (Result<Void, Error>) -> Void)`** - Captures the current `ARWorldMap` from the session. If `center2D` is provided, saves it as a `WorldMapPatch` with associated metadata; otherwise, saves it as a global map.

**`extension ARSurveyCoordinator: ARSCNViewDelegate, ARSessionDelegate`** - Implements delegate methods for visualizing detected planes and updating published properties (`trackingState`, `featurePointCount`, `planeCount`, `isReadyToSave`) based on `ARFrame` updates. Provides real-time AR session feedback.

---

## RelocalizationCoordinator.swift

**`init(arStore: ARWorldMapStore)`** - Initializes with an `ARWorldMapStore` and registers available strategies. Sets up the relocalization system.

**`updateARStore(_ newStore: ARWorldMapStore)`** - Updates the internal `ARWorldMapStore` reference and re-registers strategies. Allows dynamic store updates.

**`registerStrategies()`** - Populates `availableStrategies` with `WorldMapRelocalizer` and `DummyRelocalizer`. Registers all available relocalization methods.

**`selectedStrategy`** - Computed property that returns the currently selected `RelocalizationStrategy`. Provides access to the active strategy.

**`attemptRelocalization(for triangle: TrianglePatch, session: ARSession, completion: ((RelocalizationResult) -> Void)? = nil)`** - Attempts relocalization using the `selectedStrategy`. Coordinates the relocalization process for a triangle.

**`attemptRelocalization(for triangle: TrianglePatch, session: ARSession, strategyID: String, completion: ((RelocalizationResult) -> Void)? = nil)`** - Attempts relocalization using a specific strategy identified by `strategyID`. Allows strategy selection for testing or advanced use cases.

---

## RelocalizationStrategy.swift

**`struct RelocalizationResult`** - Encapsulates the outcome of a relocalization attempt, including success status, confidence score, notes, strategy ID, timestamp, and the filename of the world map used. Provides detailed feedback about relocalization attempts.

**`protocol RelocalizationStrategy`** - Requires conforming types to provide an `id`, `displayName`, and an `attemptRelocalization` method. Defines the interface for relocalization strategies.

---

## WorldMapRelocalizer.swift

**`init(arStore: ARWorldMapStore)`** - Initializes with an `ARWorldMapStore`. Sets up the world map-based relocalizer.

**`attemptRelocalization(for triangle: TrianglePatch, session: ARSession, completion: @escaping (RelocalizationResult) -> Void)`** - Loads the `ARWorldMap` associated with the given `TrianglePatch` from a strategy-specific folder, applies it to the `ARSession`, and evaluates the match quality. Performs actual relocalization using saved world maps.

**`loadWorldMap(for triangle: TrianglePatch) -> (ARWorldMap?, String?)`** - Loads an `ARWorldMap` from disk for a specific triangle and strategy. Retrieves persisted spatial data.

**`evaluateMatchQuality(worldMap: ARWorldMap) -> Float`** - Computes a confidence score based on the number of feature points and anchors in the `ARWorldMap`. Provides quality assessment for relocalization.

---

## WorldMapPatch.swift

**`struct WorldMapPatchMeta`** - Stores metadata for a single world map patch, including ID, name, capture date, feature count, byte size, 2D center coordinates, radius, and version. Provides information about saved AR world maps.

**`struct WorldMapPatchIndex`** - Maintains an index of all `WorldMapPatchMeta` objects for a given location, providing methods to find the nearest patch to a map point. Manages multiple world map patches per location.

**`WorldMapPatchIndex.nearestPatch(to point: CGPoint) -> WorldMapPatchMeta?`** - Finds the `WorldMapPatchMeta` whose `center2D` is closest to the given `CGPoint`. Enables efficient patch selection for relocalization.

**`WorldMapPatchIndex.distance(from: CGPoint, to: CGPoint) -> CGFloat`** - Calculates the Euclidean distance between two `CGPoint`s. Helper for nearest patch calculation.

---

## DummyRelocalizer.swift

**`attemptRelocalization(for triangle: TrianglePatch, session: ARSession, completion: @escaping (RelocalizationResult) -> Void)`** - Prints a debug message, simulates a delay, and returns a `RelocalizationResult` indicating failure. Placeholder implementation for testing and development.

---

## BluetoothScanner.swift

**`init()`** - Initializes `CBCentralManager` with `self` as the delegate. Sets up Bluetooth Low Energy scanning.

**`snapshotScan(duration: TimeInterval, onComplete: @escaping () -> Void)`** - Performs a timed scan, clears previous device data, starts scanning, and schedules a stop and completion callback. Defers scanning if Bluetooth is not powered on.

**`start()`** - Starts scanning for Bluetooth peripherals. Begins continuous device discovery.

**`stop()`** - Stops the Bluetooth scan, unless in continuous mode. Halts device discovery.

**`startContinuous()`** - Starts continuous scanning that does not auto-stop. Enables persistent beacon monitoring.

**`stopContinuous()`** - Stops continuous scanning. Disables persistent beacon monitoring.

**`parseIBeaconData(_ manufacturerData: Data) -> (uuid: String, major: Int, minor: Int, measuredPower: Int)?`** - Parses iBeacon-specific data from raw manufacturer advertisement data. Extracts Apple iBeacon protocol information.

**`summarize(_ ad: [String: Any]) -> String`** - Helper to create a human-readable summary of advertisement data. Formats BLE advertisement information for display.

**`dumpSummaryTable()`** - Prints a formatted table of currently known devices for diagnostic purposes. Provides debugging output.

**`snapshotOnce()`** - Runs a brief snapshot scan on app launch to populate the Morgue. Performs initial device discovery.

**`displayName(from advertisementData: [String: Any], peripheral: CBPeripheral) -> String`** - Determines the display name for a discovered device. Extracts or generates a human-readable device name.

**`extension BluetoothScanner: CBCentralManagerDelegate`** - Implements delegate methods for `centralManagerDidUpdateState` (handling Bluetooth power states) and `centralManager(_:didDiscover:advertisementData:rssi:)` (processing discovered peripherals, updating `devices` array, parsing iBeacon data, and forwarding to `scanUtility` and `beaconLists`). Handles all Bluetooth discovery events.

---

## MapPointStore.swift

**`init()`** - Initializes the store, loads existing data, and sets up observers for `scanSessionSaved` and `locationDidChange` notifications. Prepares the store for use.

**`reloadForActiveLocation()`** - Clears and reloads all map points for the currently active location. Refreshes data when switching locations.

**`clearAndReloadForActiveLocation()`** - Performs a hard clear and reload of map points for the active location, preventing data loss during reload. Ensures clean state when switching locations.

**`clearAllPoints()`** - Explicitly removes all map points for the current location and saves the empty state. Clears all points while maintaining persistence.

**`flush()`** - Clears in-memory map points without saving. Provides temporary state clearing.

**`addPoint(at mapPoint: CGPoint) -> Bool`** - Adds a new map point at the specified coordinates, preventing duplicates within a tolerance. Returns true if the point was added successfully.

**`removePoint(id: UUID)`** - Removes a map point by its ID. Deletes a specific point and updates persistence.

**`updatePoint(id: UUID, to newPosition: CGPoint)`** - Updates a map point's position, marking its photo as outdated if the position changes significantly. Maintains photo currency tracking.

**`clear()`** - Removes all map points and saves the empty state. Clears all points.

**`toggleActive(id: UUID)`** - Toggles the active state of a map point. Changes selection state.

**`deactivateAll()`** - Deactivates all map points. Clears all selections.

**`isActive(_ id: UUID) -> Bool`** - Checks if a map point is active. Returns selection state.

**`toggleLock(id: UUID)`** - Toggles the lock state of a map point. Prevents accidental modification.

**`isLocked(_ id: UUID) -> Bool`** - Checks if a map point is locked. Returns lock state.

**`coordinateString(for point: MapPoint) -> String`** - Returns a formatted coordinate string for display. Formats map coordinates for UI.

**`save()`** - Persists the current `points` array to `UserDefaults`, handling photo data storage (either in-memory or by filename). Includes critical guards to prevent data loss during reloads or accidental empty saves.

**`load()`** - Loads `MapPoint` data from `UserDefaults`, reconstructing `MapPoint` objects from `MapPointDTO`s, loading photos from disk if specified by filename, and performing data migrations. Also calls `loadARMarkers()` and `loadAnchorPackages()`.

**`loadARMarkers()`** - Loads legacy AR markers from `UserDefaults` for diagnostic purposes, but notes that new markers are session-only. Provides backward compatibility.

**`addSession(pointID: UUID, session: ScanSession)`** - Adds a `ScanSession` to a specific `MapPoint`. Associates scan data with a point.

**`getSessions(pointID: UUID) -> [ScanSession]`** - Retrieves all scan sessions for a given map point. Returns historical scan data.

**`removeSession(pointID: UUID, sessionID: String)`** - Removes a specific scan session from a map point. Deletes scan history.

**`totalSessionCount() -> Int`** - Returns the total number of scan sessions across all map points. Provides statistics.

**`assignRole(_ role: MapPointRole, to pointID: UUID) -> String?`** - Assigns a role to a map point, with validation for unique roles like `directionalNorth` and `directionalSouth`. Returns an error message if assignment fails.

**`removeRole(_ role: MapPointRole, from pointID: UUID)`** - Removes a role from a map point. Clears role assignment.

**`printUserDefaultsDiagnostic()`** - A diagnostic function that prints the in-memory state of map points and attempts to read/decode raw data from `UserDefaults` for debugging persistence issues. Helps troubleshoot data problems.

**`forceReload()`** - Forces a reload of map points from `UserDefaults`. Refreshes data from persistence.

**`deleteScansDirectory()`** - One-time cleanup function to delete legacy "Scans" directories (old V1 session JSON files). Removes obsolete data.

**`purgeAllSessions()`** - Removes all session data from all map points, keeping the points themselves. Clears scan history while preserving points.

**`saveARMarkers()`** - Saves AR markers (legacy, now session-only). Maintains backward compatibility.

**`saveAnchorPackages()`** - Saves `AnchorPointPackage`s to `UserDefaults`. Persists anchor data.

**`loadAnchorPackages()`** - Loads `AnchorPointPackage`s from `UserDefaults`. Restores anchor data.

**`createAnchorPackage(mapPointID: UUID, patchID: UUID?, mapCoordinates: CGPoint, anchorPosition: simd_float3, anchorSessionTransform: simd_float4x4, spatialData: AnchorSpatialData)`** - Creates and saves a new `AnchorPointPackage`. Stores anchor point data.

**`deleteAnchorPackage(_ packageID: UUID)`** - Deletes a specific `AnchorPointPackage`. Removes anchor data.

**`deleteAllAnchorPackagesForMapPoint(_ mapPointID: UUID)`** - Deletes all `AnchorPointPackage`s associated with a given map point. Clears all anchor data for a point.

**`anchorPackages(forPatchID patchID: UUID) -> [AnchorPointPackage]`** - Filters and returns `AnchorPointPackage`s for a specific patch ID. Retrieves patch-specific anchors.

**`createARMarker(linkedMapPointID: UUID, arPosition: simd_float3, mapCoordinates: CGPoint)`** - Creates an `ARMarker` and links it to a `MapPoint`. Associates AR markers with map points.

**`deleteARMarker(_ markerID: UUID)`** - Deletes an `ARMarker` and unlinks it from its `MapPoint`. Removes AR marker associations.

**`getARMarker(for mapPointID: UUID) -> ARMarker?`** - Retrieves an `ARMarker` linked to a specific `MapPoint`. Gets AR marker for a point.

**`getAllARMarkersForLocation() -> [ARMarker]`** - Returns all AR markers for the current location. Provides all AR markers.

**`startInterpolationMode(firstPointID: UUID)`** - Initiates interpolation mode with a first selected point. Begins interpolation workflow.

**`selectSecondPoint(secondPointID: UUID)`** - Selects the second point for interpolation. Completes interpolation point selection.

**`cancelInterpolationMode()`** - Cancels interpolation mode. Aborts interpolation workflow.

**`canStartInterpolation() -> Bool`** - Checks if interpolation can be started (two points selected). Validates interpolation readiness.

**`savePhotoToDisk(for pointID: UUID, photoData: Data) -> Bool`** - Saves a photo to disk for a map point and updates the point's metadata. Moves photos from UserDefaults to disk storage.

**`loadPhotoFromDisk(for pointID: UUID) -> Data?`** - Loads a photo from disk for a map point. Retrieves photos from disk storage.

---

## TrianglePatchStore.swift

**`init()`** - Initializes the store and loads existing triangles. Prepares triangle management.

**`startCreatingTriangle()`** - Initiates the triangle creation workflow. Begins triangle creation process.

**`cancelCreatingTriangle()`** - Cancels the triangle creation workflow. Aborts triangle creation.

**`addCreationVertex(_ pointID: UUID, mapPointStore: MapPointStore) -> String?`** - Adds a `MapPoint` ID as a vertex for a new triangle, validating its role and uniqueness. If three vertices are added, it attempts to `finishCreatingTriangle`. Returns an error message if validation fails.

**`finishCreatingTriangle(mapPointStore: MapPointStore) -> String?`** - Completes the triangle creation process, performing validation (collinearity, overlap) and then creating and saving the `TrianglePatch`. Also updates `MapPoint` memberships. Returns an error message if validation fails.

**`deleteTriangle(_ triangleID: UUID, mapPointStore: MapPointStore)`** - Deletes a `TrianglePatch` and removes its ID from associated `MapPoint` memberships. Cleans up triangle data.

**`getVertexPositions(_ vertexIDs: [UUID], mapPointStore: MapPointStore) -> [CGPoint]?`** - Retrieves the 2D map positions for a given set of vertex IDs. Gets triangle vertex coordinates.

**`areCollinear(_ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint, tolerance: CGFloat = 1.0) -> Bool`** - Checks if three points are collinear. Validates triangle geometry.

**`hasInteriorOverlap(with newVertices: [UUID], mapPointStore: MapPointStore) -> Bool`** - Checks if a new triangle's interior overlaps with any existing triangles, allowing for edge-sharing. Prevents invalid triangle tessellation.

**`trianglesIntersect(_ tri1: [CGPoint], _ tri2: [CGPoint], sharedVertexPositions: Set<CGPoint> = []) -> Bool`** - Determines if two triangles have overlapping interiors, excluding shared vertices. Validates triangle geometry.

**`pointInTriangle(_ p: CGPoint, _ vertices: [CGPoint]) -> Bool`** - Checks if a point lies inside a triangle using barycentric coordinates. Performs point-in-triangle tests.

**`edgesIntersect(_ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint, _ p4: CGPoint) -> Bool`** - Checks if two line segments intersect (not just touch at endpoints). Validates edge intersections.

**`findAdjacentTriangles(_ triangleID: UUID) -> [TrianglePatch]`** - Finds triangles that share an edge (2 vertices) with a given triangle. Identifies neighboring triangles.

**`getFarVertex(adjacentTriangle: TrianglePatch, sourceTriangle: TrianglePatch) -> UUID?`** - Returns the vertex of an adjacent triangle that is not shared with the source triangle. Finds the "far" vertex for calibration crawling.

**`populateAllMapPointMarkers(calibratedTriangle: TrianglePatch, mapPointStore: MapPointStore, arCoordinator: Any)`** - (Temporarily disabled) Intended to project all map points into AR space using a calibrated triangle and create AR markers for them. Reserved for future implementation.

**`projectMapPointToAR(mapPoint: CGPoint, calibrationPairs: [(mapPoint: CGPoint, arPosition: simd_float3)]) -> simd_float3`** - Projects a 2D map point to 3D AR space using barycentric interpolation based on calibration pairs. Performs 2D-to-3D projection.

**`triangle(withID id: UUID) -> TrianglePatch?`** - Finds a triangle by its ID. Retrieves triangle by identifier.

**`addMarker(mapPointID: UUID, markerID: UUID)`** - Adds an AR marker ID to a specific vertex of a triangle. Associates markers with triangle vertices.

**`markCalibrated(_ id: UUID, quality: Float)`** - Marks a triangle as calibrated and sets its quality score. Updates calibration status.

**`setLegMeasurements(for triangleID: UUID, measurements: [TriangleLegMeasurement])`** - Stores leg distance measurements for a triangle. Saves calibration quality data.

**`setWorldMapFilename(for triangleID: UUID, filename: String)`** - Sets the legacy world map filename for a triangle. Maintains backward compatibility.

**`setWorldMapFilename(for triangleID: UUID, strategyName: String, filename: String)`** - Sets the world map filename for a specific strategy for a triangle. Stores strategy-specific world maps.

**`save()`** - Persists the `triangles` array to `UserDefaults`. Saves triangle data.

**`load()`** - Loads the `triangles` array from `UserDefaults`. Restores triangle data.

---

## TrianglePatch.swift

**`init(vertexIDs: [UUID])`** - Initializes a new `TrianglePatch` with three vertex IDs. Creates a triangle patch.

**`sortedVertexIDs`** - Returns vertex IDs sorted for deterministic rendering. Provides consistent vertex ordering.

**`statusColor`** - Computed property to determine the color based on calibration status and quality. Provides visual status indication.

**`extension TrianglePatch: Codable`** - Provides custom `Codable` conformance for backward compatibility, handling different date formats and optional properties. Ensures data migration support.

---

## ARCalibrationCoordinator.swift

**`init(arStore: ARWorldMapStore, mapStore: MapPointStore, triangleStore: TrianglePatchStore, metricSquareStore: MetricSquareStore? = nil)`** - Initializes with references to various stores. Sets up the calibration coordinator.

**`getPixelsPerMeter() -> Float?`** - Retrieves the pixels-per-meter conversion factor from `MetricSquareStore`. Gets metric conversion data.

**`startCalibration(for triangleID: UUID)`** - Initiates the calibration process for a specific triangle, resetting state and setting the initial status text. Begins triangle calibration.

**`setVertices(_ vertices: [UUID])`** - Sets the vertex IDs for the triangle being calibrated (legacy compatibility). Configures triangle vertices.

**`getCurrentVertexID() -> UUID?`** - Returns the ID of the current vertex being calibrated. Gets current calibration target.

**`setReferencePhoto(_ photoData: Data?)`** - Sets the reference photo data for the current vertex. Stores reference images.

**`registerMarker(mapPointID: UUID, marker: ARMarker)`** - Registers a newly placed AR marker with the coordinator. Validates the marker against the active triangle, saves it to `ARWorldMapStore`, updates the `TrianglePatch`, and advances the calibration to the next vertex.

**`updateProgressDots()`** - Updates the visual progress indicators (three dots) based on how many markers have been placed. Provides UI feedback.

**`finalizeCalibration(for triangle: TrianglePatch)`** - Called when all three markers are placed. Computes the calibration quality, marks the triangle as calibrated, saves the `ARWorldMap` for the triangle, and suggests the next adjacent uncalibrated triangle for "crawling."

**`saveWorldMapForTriangle(_ triangle: TrianglePatch)`** - Captures the current `ARWorldMap` from the AR session, calculates metadata (center, radius), and saves it as a strategy-specific patch in `ARWorldMapStore`. Also updates the `TrianglePatch` with the filename.

**`findAdjacentUncalibratedTriangle(to triangleID: UUID) -> TrianglePatch?`** - Finds an uncalibrated triangle that shares at least one vertex with the given triangle, for sequential calibration. Enables calibration "crawling."

**`computeCalibrationQuality(_ triangle: TrianglePatch) -> Float`** - Calculates a quality score for the calibration based on the distortion ratios of the triangle's legs (comparing 2D map distances to 3D AR distances). Also stores `TriangleLegMeasurement`s.

**`reset()`** - Resets all calibration-related state variables. Clears calibration state.

**`convertToWorldMapMarker(_ marker: ARMarker) -> ARWorldMapStore.ARMarker`** - Helper to convert the local `ARMarker` struct to the `ARWorldMapStore.ARMarker` format for persistence. Performs data format conversion.

---

## ARWorldMapStore.swift

**`baseDirectory() -> URL`** - Returns the base directory for AR spatial data for the current location. Gets location-specific storage path.

**`globalMapURL(version: Int) -> URL`** - Returns the URL for a global AR world map file. Gets global map file path.

**`globalMapMetaURL(version: Int) -> URL`** - Returns the URL for global map metadata. Gets metadata file path.

**`markersDirectory() -> URL`** - Returns the directory for AR markers. Gets marker storage directory.

**`markerDirectory(markerID: String) -> URL`** - Returns the directory for a specific AR marker. Gets marker-specific directory.

**`markerMetaURL(markerID: String) -> URL`** - Returns the URL for AR marker metadata. Gets marker metadata file path.

**`markerPatchURL(markerID: String) -> URL`** - Returns the URL for an AR world map patch associated with a marker. Gets marker patch file path.

**`markerObservationsURL(markerID: String) -> URL`** - Returns the URL for marker observations. Gets observations file path.

**`patchesDirectory() -> URL`** - Returns the directory for world map patches. Gets patch storage directory.

**`patchURL(for id: UUID) -> URL`** - Returns the URL for a specific world map patch. Gets patch file path.

**`patchIndexURL() -> URL`** - Returns the URL for the world map patch index. Gets index file path.

**`strategiesDirectory() -> URL`** - Returns the base directory for relocalization strategies. Gets strategy storage directory.

**`strategyDirectory(strategyID: String) -> URL`** - Returns the directory for a specific strategy. Gets strategy-specific directory.

**`strategyWorldMapURL(for triangleID: UUID, strategyID: String) -> URL`** - Static helper to get the URL for a strategy-specific world map. Gets strategy world map file path.

**`init()`** - Initializes the store, loads global map metadata, and sets up an observer for `locationDidChange` notifications. Prepares the store.

**`locationDidChange()`** - Reloads global map metadata when the location changes. Refreshes data on location switch.

**`saveGlobalMap(_ map: ARWorldMap, version: Int? = nil) throws`** - Saves an `ARWorldMap` as a global map and its metadata. Persists global world maps.

**`loadGlobalMap(version: Int? = nil) throws -> ARWorldMap?`** - Loads a global `ARWorldMap`. Restores global world maps.

**`loadWorldMap(version: Int? = nil) -> ARWorldMap?`** - Convenience wrapper for `loadGlobalMap`. Provides simplified access.

**`savePatch(_ map: ARWorldMap, meta: WorldMapPatchMeta) throws`** - Saves a world map as a patch with metadata (legacy). Maintains backward compatibility.

**`savePatchForStrategy(_ map: ARWorldMap, triangleID: UUID, strategyID: String) throws`** - Saves an `ARWorldMap` to a strategy-specific folder. Persists strategy-specific world maps.

**`loadPatch(id: UUID) -> ARWorldMap?`** - Loads a specific world map patch. Restores patch data.

**`loadPatchIndex() -> WorldMapPatchIndex?`** - Loads the world map patch index. Restores patch index.

**`savePatchIndex(_ index: WorldMapPatchIndex) throws`** - Saves the world map patch index. Persists patch index.

**`chooseBestPatch(for mapPoint: CGPoint) -> (meta: WorldMapPatchMeta, map: ARWorldMap)?`** - Selects the best world map patch for a given map point. Finds optimal patch for relocalization.

**`loadGlobalMapMetadata()`** - Loads the metadata for the global AR world map. Restores global map metadata.

**`saveMarker(_ marker: ARMarker, patch: ARWorldMap? = nil) throws`** - Saves an AR marker and optionally an associated world map patch. Persists marker data.

**`loadMarkerPatch(markerID: String) throws -> ARWorldMap?`** - Loads a world map patch associated with a marker. Restores marker patches.

**`loadMarkersForDiagnostics() -> [ARMarker]`** - Loads legacy AR markers for diagnostic purposes. Provides debugging data.

**`marker(withID id: UUID) -> ARMarker?`** - Finds an AR marker by its ID. Retrieves marker by identifier.

**`inspectMarkers()`** - Prints a diagnostic summary of persisted AR markers. Provides debugging output.

**`deleteAllMarkers()`** - Deletes all persisted AR marker metadata files. Clears marker data.

**`preserveAndRun(_ mutate: (ARWorldTrackingConfiguration) -> Void, session: ARSession)`** - Applies mutations to an `ARWorldTrackingConfiguration` and runs the AR session, with debouncing. Manages AR session configuration safely.

**`printDiagnostic()`** - Prints a diagnostic summary of the ARWorldMapStore. Provides debugging information.

---

## ARViewLaunchContext.swift

**`launchGeneric()`** - Sets `isPresented` to `true` for a generic AR view. Launches generic AR mode.

**`launchTriangleCalibration(triangle: TrianglePatch)`** - Sets `isPresented` to `true` and configures the AR view for triangle calibration with a specific `TrianglePatch`. Launches calibration mode.

**`dismiss()`** - Sets `isPresented` to `false` and resets the calibration-related state. Closes the AR view.

---

## LocationManager.swift

**`init()`** - Initializes with the last opened location from `UserDefaults` and sets up a Combine pipeline to update `PersistenceContext.shared.locationID` and post `locationDidChange` notifications when `currentLocationID` changes. Manages location state.

**`setCurrentLocation(_ id: String)`** - Sets the `currentLocationID`. Changes the active location.

---

## ARMarker.swift

**`init(id: UUID = UUID(), linkedMapPointID: UUID, arPosition: simd_float3, mapCoordinates: CGPoint, isAnchor: Bool = false)`** - Initializes an `ARMarker` with a link to a map point and 3D/2D coordinates. Creates an AR marker.

**`extension ARMarker: Codable`** - Provides custom `Codable` conformance to handle `simd_float3` and `CGPoint` as arrays of `Float`/`CGFloat`. Enables persistence.

---

## AnchorAreaInstance.swift

**`init(...)`** - Initializes an `AnchorAreaInstance` representing a specific spray-painted area in a world map patch, linking to an `AnchorFeature` (semantic landmark). Creates anchor area data.

**`extension AnchorAreaInstance: Codable`** - Provides custom `Codable` conformance for `SIMD3<Float>` and `simd_float4x4`. Enables persistence.

---

## AnchorFeature.swift

**`init(...)`** - Initializes an `AnchorFeature` representing a semantic landmark (e.g., "Cat Painting") that can appear in multiple world map patches. Creates anchor feature data.

---

## BeaconDotStore.swift

**`init()`** - Loads locks, elevations, TX power, advertising intervals, and dots from disk. Prepares the beacon dot store.

**`dot(for beaconID: String) -> Dot?`** - Retrieves a `Dot` for a given beacon ID. Gets beacon dot data.

**`toggleDot(for beaconID: String, mapPoint: CGPoint, color: Color)`** - Adds or removes a dot for a beacon. Manages beacon dot placement.

**`updateDot(id: UUID, to newPoint: CGPoint)`** - Updates a dot's map-local position. Moves beacon dots.

**`clear()`** - Removes all dots. Clears all beacon dots.

**`clearUnlockedDots()`** - Removes dots only for unlocked beacons. Clears non-locked dots.

**`lockedDots()`** - Returns only the locked beacon dots. Gets locked dots.

**`setElevation(for beaconID: String, elevation: Double)`** - Sets the elevation for a beacon. Stores beacon elevation.

**`getElevation(for beaconID: String) -> Double`** - Retrieves the elevation for a beacon. Gets beacon elevation.

**`startElevationEdit(for beaconID: String)`** - Initiates elevation editing. Begins elevation editing workflow.

**`commitElevationText(_ text: String, for beaconID: String)`** - Commits the entered elevation text. Saves elevation changes.

**`displayElevationText(for beaconID: String) -> String`** - Returns a formatted elevation string. Formats elevation for display.

**`setTxPower(for beaconID: String, dbm: Int?)`** - Sets the TX power for a beacon. Stores TX power setting.

**`getTxPower(for beaconID: String) -> Int?`** - Retrieves the TX power for a beacon. Gets TX power setting.

**`setAdvertisingInterval(for beaconID: String, ms: Double?)`** - Sets the advertising interval for a beacon. Stores advertising interval.

**`getAdvertisingInterval(for beaconID: String) -> Double`** - Retrieves the advertising interval for a beacon, with diagnostic output. Gets advertising interval.

**`displayAdvertisingInterval(for beaconID: String) -> String`** - Returns a formatted advertising interval string. Formats interval for display.

**`reloadForActiveLocation()`** - Clears and reloads all data for the active location. Refreshes data on location switch.

**`clearAndReloadForActiveLocation()`** - Performs a hard flush and reload for location switching. Ensures clean state.

**`lockedBeaconIDs()`** - Returns a list of beacon IDs that are currently locked. Gets locked beacon list.

**`isLocked(_ beaconID: String) -> Bool`** - Checks if a beacon is locked. Returns lock state.

**`toggleLock(_ beaconID: String)`** - Toggles the lock state of a beacon. Changes lock state.

**`save()`** - Saves dots to disk and locks to `UserDefaults`. Persists beacon dot data.

**`saveLocks()`** - Saves locked beacon IDs to `UserDefaults`. Persists lock state.

**`load()`** - Loads all persistence data. Restores beacon dot data.

**`loadLocks()`** - Loads locked beacon IDs from `UserDefaults`. Restores lock state.

**`saveElevations()`** - Saves beacon elevations to `UserDefaults`. Persists elevation data.

**`loadElevations()`** - Loads beacon elevations from `UserDefaults`. Restores elevation data.

**`loadTxPower()`** - Loads beacon TX power settings from `UserDefaults`. Restores TX power data.

**`saveTxPower()`** - Saves beacon TX power settings to `UserDefaults`. Persists TX power data.

**`saveAdvertisingIntervals()`** - Saves beacon advertising intervals to `UserDefaults`. Persists interval data.

**`loadAdvertisingIntervals()`** - Loads beacon advertising intervals from `UserDefaults`. Restores interval data.

**`dotsFileURL(_ ctx: PersistenceContext = .shared) -> URL`** - Returns the file URL for dots data. Gets dots file path.

**`saveDotsToDisk()`** - Saves dot coordinates to a JSON file on disk. Persists dots to disk.

**`loadDotsFromDisk()`** - Loads dot coordinates from a JSON file on disk. Restores dots from disk.

**`beaconColor(for beaconID: String) -> Color`** - Generates a color for a beacon based on its ID hash. Provides consistent beacon colors.

---

## BeaconListsStore.swift

**`sortedMorgue`** - Computed property that sorts the `morgue` list for display. Provides sorted excluded devices.

**`init()`** - Loads `beacons` and `morgue` from `UserDefaults` and sets up an observer for `locationDidChange` notifications. Prepares the store.

**`save()`** - Saves the `beacons` list to `UserDefaults`. Persists beacon list.

**`saveMorgue()`** - Saves the `morgue` list to `UserDefaults`. Persists morgue list.

**`load()`** - Loads the `beacons` list from `UserDefaults`. Restores beacon list.

**`reloadMorgue()`** - Reloads the `morgue` list from `UserDefaults` for the current location. Refreshes morgue data.

**`ingest(deviceName: String)`** - Processes a new device name, adding it to `beacons` if it matches the pattern, or to `morgue` otherwise. Also handles de-duplication. Manages device classification.

**`ingest(deviceName: String, id: UUID)`** - Overloaded `ingest` method that takes a `UUID` and formats the device name. Processes devices with UUIDs.

**`isBeaconName(_ name: String) -> Bool`** - Checks if a given name matches the beacon name regex pattern. Validates beacon names.

**`demoteToMorgue(_ name: String)`** - Moves a beacon name from the `beacons` list to the `morgue`. Removes beacon from active list.

**`promoteToBeacons(_ name: String)`** - Moves a beacon name from the `morgue` to the `beacons` list. Adds beacon to active list.

**`clearUnlockedBeacons(lockedBeaconNames: [String])`** - Removes beacons from the `beacons` list that are not in the provided `lockedBeaconNames`. Cleans up unlocked beacons.

**`reloadForActiveLocation()`** - Clears and reloads both lists for the active location. Refreshes data on location switch.

**`flush()`** - Clears in-memory lists without saving. Provides temporary state clearing.

**`loadOnly()`** - Loads `beacons` and `morgue` from persistence without clearing. Restores data without clearing.

**`reconcileWithLockedDots(_ lockedBeaconNames: [String]? = nil)`** - Ensures that all locked beacon IDs from `BeaconDotRegistry` are present in the `beacons` list. Maintains consistency.

**`clearAndReloadForActiveLocation()`** - Wrapper for `reloadForActiveLocation()`. Provides convenience method.

---

## BeaconStateManager.swift

**`init()`** - Default initializer. Creates the beacon state manager.

**`startMonitoring(scanner: BluetoothScanner)`** - Starts a timer to periodically call `updateLiveBeacons()` and performs an initial update. Begins beacon state monitoring.

**`deinit`** - Invalidates the update timer. Cleans up on deallocation.

**`updateLiveBeacons()`** - The core update loop. Iterates through `BluetoothScanner.devices`, calculates `isActive` based on `stalenessWindow`, and updates the `liveBeacons` dictionary and `activeBeaconIDs` set. Maintains unified beacon state.

**`beacon(named beaconID: String) -> LiveBeacon?`** - Retrieves a specific `LiveBeacon` by its ID. Gets beacon state.

**`isActive(_ beaconID: String) -> Bool`** - Checks if a beacon is currently active. Returns active state.

**`activeBeacons() -> [LiveBeacon]`** - Returns an array of all currently active beacons. Gets all active beacons.

---

## HUDPanelsState.swift

**`openBeacon()`** - Opens the Beacon List drawer and closes all other panels. Manages panel visibility.

**`openSquares()`** - Opens the Metric Squares drawer and closes all other panels. Manages panel visibility.

**`openMorgue()`** - Opens the Morgue drawer and closes all other panels. Manages panel visibility.

**`openMapPoint()`** - Opens the Map Points drawer and closes all other panels. Manages panel visibility.

**`closeAll()`** - Closes all panels. Clears all panel states.

**`toggleMapPointLog()`** - Toggles the visibility of the Map Point Log. Changes log visibility.

---

## MetricSquareStore.swift

**`init()`** - Initializes the store and loads existing squares. Prepares metric square management.

**`add(at mapPoint: CGPoint, color: Color)`** - Adds a new square at a given map point. Creates a metric square.

**`remove(id: UUID)`** - Removes a square by its ID. Deletes a metric square.

**`reset(id: UUID)`** - Resets a square's side length to a default. Restores default size.

**`updateCenter(id: UUID, to newCenter: CGPoint)`** - Updates a square's center position. Moves metric squares.

**`updateSideAndCenter(id: UUID, side: CGFloat, center: CGPoint)`** - Updates a square's side length and center. Modifies square geometry.

**`toggleLock(id: UUID)`** - Toggles the lock state of a square. Prevents accidental modification.

**`updateMeters(for id: UUID, meters: Double)`** - Updates the real-world meter value for a square. Sets metric calibration.

**`save()`** - Persists the `squares` array to `UserDefaults`. Saves square data.

**`load()`** - Loads the `squares` array from `UserDefaults`. Restores square data.

**`reloadForActiveLocation()`** - Clears and reloads all squares for the active location. Refreshes data on location switch.

**`clearAndReloadForActiveLocation()`** - Performs a hard flush and reload for location switching. Ensures clean state.

**`flush()`** - Clears in-memory squares without saving. Provides temporary state clearing.

**`toggleSelection(id: UUID)`** - Toggles the active selection state of a square. Changes selection state.

**`isActive(_ id: UUID) -> Bool`** - Checks if a square is active. Returns selection state.

**`deactivateAll()`** - Deactivates all squares. Clears all selections.

---

## SquareMetrics.swift

**`init()`** - Loads per-location values from `UserDefaults` and sets up an observer for `locationDidChange` notifications. Prepares metric settings.

**`updatePixelSide(for id: UUID, side: CGFloat)`** - (Commented out) Placeholder, as this is handled by `MetricSquareStore`. Reserved for future use.

**`entry(for id: UUID) -> (pixelSide: CGFloat, meters: Double)?`** - Retrieves pixel side and meter values for a square from `MetricSquareStore`. Gets square metrics.

**`displayMetersText(for id: UUID) -> String`** - Returns a formatted meter string for a square. Formats meters for display.

**`commitMetersText(_ text: String, for id: UUID)`** - Commits the entered meter text to `MetricSquareStore`. Saves meter changes.

**`setMetricSquareStore(_ store: MetricSquareStore)`** - Sets the reference to the `MetricSquareStore`. Configures store reference.

**`reloadNorthOffset()`** - Loads `northOffsetDeg` from `UserDefaults`. Restores north offset.

**`saveNorthOffset()`** - Saves `northOffsetDeg` to `UserDefaults`. Persists north offset.

**`setNorthOffset(_ deg: Double)`** - Sets and saves `northOffsetDeg`. Updates north offset.

**`setFacingFineTune(_ deg: Double)`** - Sets and saves `facingFineTuneDeg`. Updates facing fine-tune.

**`setMapBaseOrientation(_ deg: Double)`** - Sets and saves `mapBaseOrientation`. Updates map base orientation.

---

## ScanQualityViewModel.swift

**`countOnly(btScanner: BluetoothScanner, beaconLists: BeaconListsStore, beaconDotStore: BeaconDotStore) -> ScanQualityViewModel`** - (Legacy) Provides a view model with only beacon counts. Provides simplified view model.

**`fromRealData(beaconState: BeaconStateManager, beaconDotStore: BeaconDotStore, scanUtility: MapPointScanUtility) -> ScanQualityViewModel`** - The primary method for building the view model from live data. Queries `BeaconStateManager` for active beacons, `BeaconDotStore` for dot information, and `MapPointScanUtility` for scan records to determine signal quality and stability.

**`qualityFromRSSI(_ rssi: Int) -> Quality`** - Maps an RSSI value to a `Quality` category. Classifies signal strength.

**`stabilityFromMAD(beaconID: String, scanRecord: MapPointScanUtility.ScanRecord?) -> Double`** - Calculates a stability percentage based on the Median Absolute Deviation (MAD) from a scan record. Measures signal stability.

---

## MapPointStore+Quality.swift

**`scanQuality(for pointID: UUID) -> ScanQuality`** - Calculates the overall scan quality for a map point by evaluating all its sessions and returning the worst quality found. Provides quality assessment.

**`evaluateSessionQuality(_ session: ScanSession) -> ScanQuality`** - Evaluates the quality of a single scan session based on the number of beacons with good RSSI values. Assesses session quality.

---

## MapPointStore+Export.swift

**`exportMasterJSON() async throws -> Data`** - Generates a JSON `Data` object containing all map points, their coordinates, and their scan sessions. Includes metadata like export date, location ID, app version, and total counts.

**`appVersion() -> String`** - Retrieves the app's version and build number. Gets app version info.

---

## MapTransformStore.swift

**`init()`** - Default initializer. Creates the transform store.

**`_setTotals(scale: CGFloat, rotationRadians: Double, offset: CGSize)`** - Internal setter for updating all transform components. Updates transform state.

**`_setMapSize(_ size: CGSize)`** - Internal setter for updating the map size. Updates map dimensions.

**`_setScreenCenter(_ point: CGPoint)`** - Internal setter for updating the screen center. Updates screen center.

**`centerOnPoint(_ mapPoint: CGPoint, animated: Bool = true)`** - Centers the map view on a specific map-local point, optionally with animation. Focuses map on a point.

**`screenToMap(_ G: CGPoint) -> CGPoint`** - Converts a global (screen) coordinate to a map-local coordinate. Performs coordinate transformation.

**`screenTranslationToMap(_ dG: CGSize) -> CGPoint`** - Converts a global (screen) translation to a map-local translation. Transforms translation vectors.

**`mapToScreen(_ M: CGPoint) -> CGPoint`** - Converts a map-local coordinate to a global (screen) coordinate. Performs coordinate transformation.

---

## GestureHandler.swift

**`init(minScale: CGFloat = 0.5, maxScale: CGFloat = 4.0, zoomStep: CGFloat = 1.25)`** - Initializes with configurable scale limits and zoom step. Creates gesture handler.

**`doubleTapZoom()`** - Increases the `steadyScale` by `zoomStep`. Handles double-tap zoom.

**`resetTransform()`** - Resets all transform components to their initial values. Resets map transform.

**`combinedGesture`** - A `Gesture` that combines pan, pinch, and rotate gestures. Provides unified gesture handling.

**`panOnlyGesture`** - A `Gesture` for pan gestures only. Provides pan-only gesture.

**`panGesture() -> some Gesture`** - Defines the `DragGesture` logic, updating `gestureTranslation` and then `steadyOffset` on end. Handles pan gestures.

**`pinchGesture() -> some Gesture`** - Defines the `MagnificationGesture` logic, updating `gestureScale` and then `steadyScale` on end. Handles pinch gestures.

**`rotateGesture() -> some Gesture`** - Defines the `RotationGesture` logic, updating `gestureRotation` and then `steadyRotation` on end. Handles rotation gestures.

**`clamp<T: Comparable>(_ x: T, _ a: T, _ b: T) -> T`** - Utility function to clamp a value within a range. Constrains values.

**`emitTotals()`** - Calls the `onTotalsChanged` closure with the current total transform values. Notifies listeners of changes.

---

## TransformProcessing.swift

**`handlePinchRotate(phase: PinchPhase, scaleFromStart ds: CGFloat, rotationFromStart dθ: CGFloat, centroidInScreen a_scr: CGPoint)`** - Processes pinch and rotate gesture updates, calculating new scale, rotation, and offset while preserving the anchor point. Manages gesture processing.

**`bind(to store: MapTransformStore)`** - Binds the processor to a `MapTransformStore` instance. Connects processor to store.

**`setMapSize(_ size: CGSize)`** - Sets the map size in the `MapTransformStore`. Updates map dimensions.

**`setScreenCenter(_ point: CGPoint)`** - Sets the screen center in the `MapTransformStore`. Updates screen center.

**`enqueueCandidate(scale: CGFloat, rotationRadians: Double, offset: CGSize)`** - Receives raw gesture updates and either immediately pushes them (if `passThrough` is true) or schedules a debounced push. Queues transform updates.

**`schedulePushIfNeeded()`** - Schedules a `pushIfMeaningful()` call on the main queue if not already scheduled. Manages update scheduling.

**`pushIfMeaningful()`** - Checks if the pending transform values are significantly different from the last-pushed values (using `scaleEpsilon`, `rotEpsilon`, `offEpsilon`) and, if so, updates the `MapTransformStore`. Applies thresholded updates.

---

## PinchRotateCentroidBridge.swift

**`makeCoordinator() -> Coordinator`** - Creates a `Coordinator` instance. Sets up gesture coordinator.

**`makeUIView(context: Context) -> UIView`** - Creates a `PassThroughWhenSingleTouchView`, adds `UIPinchGestureRecognizer` and `UIRotationGestureRecognizer` to it, and sets the coordinator as their delegate. Sets up UIKit gesture recognizers.

**`updateUIView(_ uiView: UIView, context: Context)`** - Empty, as no updates are needed. Placeholder for updates.

**`Coordinator.gestureRecognizer(_:shouldRecognizeSimultaneouslyWith:)`** - Allows simultaneous recognition of gestures. Enables multi-gesture support.

**`Coordinator.onPinch(_:)`** - Objective-C selector that calls `emit()` when pinch gesture changes. Handles pinch events.

**`Coordinator.onRotate(_:)`** - Objective-C selector that calls `emit()` when rotation gesture changes. Handles rotation events.

**`Coordinator.emit()`** - Gathers the current state from the pinch and rotation gestures and calls the `onUpdate` closure. Reports gesture state.

**`PassThroughWhenSingleTouchView.hitTest(_:with:)`** - Overrides `hitTest` to only intercept multi-touch gestures (2 or more fingers), allowing single-finger touches to pass through to underlying SwiftUI views. Enables gesture pass-through.

---

## MapPointScanUtility.swift

**`startScan(pointID: String, mapX_m: Double, mapY_m: Double, userHeight_m: Double, sessionID: String? = nil, durationSeconds: TimeInterval)`** - Initiates a timed scan, resets internal state, captures the user's facing direction, and starts a countdown timer. Begins beacon scanning at a map point.

**`cancelScan()`** - Cancels the current scan. Aborts scanning.

**`ingest(beaconID: String, name: String?, rssiDbm: Int, txPowerDbm: Int?, timestamp: TimeInterval)`** - Ingests a single BLE advertisement, filtering excluded beacons, adding RSSI to an `Obin` histogram, and storing raw samples. Processes beacon data.

**`finishScan()`** - Completes the scan, calculates duration, builds `BeaconScanAggregate`s, updates `runningAggregates`, creates and publishes a `ScanRecord`, saves it using `saveScanRecordV1`, and generates a `ScanSummary`. Finalizes scan data.

**`updateRunningAggregate(pointID: String, beaconID: String, obin newObin: Obin, duration: TimeInterval)`** - Updates the in-memory running aggregate for a specific map point and beacon. Maintains cumulative statistics.

**`saveScanRecordV1(record: ScanRecord, start: Date, end: Date)`** - Converts the `ScanRecord` to the `MapPointStore.ScanSession` format and posts a `.scanSessionSaved` notification, allowing `MapPointStore` to persist it. Saves scan data.

**`Obin.add(_ rssi: Int)`** - Adds an RSSI sample to the histogram. Updates RSSI distribution.

**`Obin.quantileDbm(_ q: Double) -> Int?`** - Calculates a quantile value from the RSSI histogram. Computes percentile values.

**`Obin.madDb(relativeTo median: Int?) -> Double?`** - Calculates the Median Absolute Deviation (MAD) relative to a median value. Measures signal stability.

---

## CompassOrientationManager.swift

**`init()`** - Initializes `CLLocationManager` and `CMMotionManager`, setting `self` as the delegate for location. Sets up sensor fusion.

**`start()`** - Requests location authorization, starts updating heading, and starts `deviceMotion` updates using `.xTrueNorthZVertical` reference frame if available. Begins sensor data collection.

**`stop()`** - Stops location and motion updates. Halts sensor data collection.

**`resetFilter()`** - Resets internal filter state. Clears filter state.

**`handleDeviceMotion(_ dm: CMDeviceMotion)`** - Processes `CMDeviceMotion` data, calculates yaw, pitch, and roll, and performs complementary filtering with `CLHeading` to produce `fusedHeadingDegrees`. Performs sensor fusion.

**`alphaForAccuracy(_ acc: Double, fallback: Double) -> Double`** - Determines the blending factor for sensor fusion based on heading accuracy. Calculates fusion weights.

**`qualityForAccuracy(_ acc: Double) -> HeadingQuality`** - Maps heading accuracy to a `HeadingQuality` enum. Classifies heading quality.

**`mixAngles(_ prev: Double, _ motionYaw: Double, _ absolute: Double, alpha: Double) -> Double`** - Performs complementary filtering to blend motion yaw with absolute heading. Combines sensor data.

**`extension CompassOrientationManager: CLLocationManagerDelegate`** - Implements delegate methods for `locationManagerShouldDisplayHeadingCalibration` (to show system calibration UI) and `locationManager(_:didUpdateHeading:)` (to update `trueHeadingDegrees`, `magneticHeadingDegrees`, and `headingAccuracyDegrees`). Handles location updates.

**Angle helper functions** - `degreesToRadians`, `radiansToDegrees`, `normalizeAngle`, `shortestDelta`, `closestAngle`, `wrapDegrees`, `wrapSignedDegrees` - Utility functions for angle manipulation and normalization.

---

## PersistenceContext.swift

**`key(_ base: String) -> String`** - Generates a namespaced `UserDefaults` key (e.g., "locations.home.MapPoints_v1"). Creates location-scoped keys.

**`write<T: Encodable>(_ base: String, value: T)`** - Encodes an `Encodable` value to `Data` and writes it to `UserDefaults` using the namespaced key. Includes error logging. Persists data.

**`read<T: Decodable>(_ base: String, as type: T.Type) -> T?`** - Reads `Data` from `UserDefaults` using the namespaced key and attempts to decode it into the specified `Decodable` type. Includes logging for `MapPoints` related keys. Restores data.

**`docs`** - Returns the URL for the app's Documents directory. Gets documents path.

**`locationDir`** - Returns the URL for the current location's directory within Documents. Gets location directory.

**`assetsDir`** - Returns the URL for the current location's assets directory. Gets assets directory.

**`scansDir`** - Returns the URL for the current location's scans directory. Gets scans directory.

---

## PathProvider.swift

**`baseDir() throws -> URL`** - Returns the base "locations" directory within Documents. Gets base locations directory.

**`locationDir(_ id: String) throws -> URL`** - Returns the directory for a specific location ID. Gets location-specific directory.

**`locationConfigURL(_ id: String) throws -> URL`** - Returns the URL for a location's `location.json` configuration file. Gets location config file path.

**`scansMonthDir(_ id: String, year: Int, month: Int) throws -> URL`** - Returns the directory for scan summaries within a specific year and month for a location. Gets scan directory for time period.

**`scanURL(_ id: String, date: Date, scanID: String) throws -> URL`** - Returns the full URL for a specific scan record JSON file, including year-month subdirectories. Gets scan file path.

---

## PersistenceService.swift

**`writeLocation(_ dto: LocationConfigV1) throws`** - Writes a `LocationConfigV1` object to its `location.json` file. Persists location configuration.

**`readLocation(_ id: String) throws -> LocationConfigV1`** - Reads a `LocationConfigV1` object from its `location.json` file. Restores location configuration.

**`writeScan(_ dto: ScanRecordV1, at date: Date) throws -> URL`** - Writes a `ScanRecordV1` object to a JSON file in the appropriate scan directory. Persists scan records.

**`listScans(locationID: String) throws -> [URL]`** - Lists all scan JSON files for a given location. Enumerates scan files.

**`readScan(_ url: URL) throws -> ScanRecordV1`** - Reads a `ScanRecordV1` object from a given URL. Restores scan records.

---

## ScanPersistence.swift

**`saveSession(_ session: BeaconLogSession)`** - Encodes a `BeaconLogSession` to JSON and writes it to a file named after its `sessionID` (or timestamp) in the current location's `scansDir`. Persists beacon log sessions.

---

## MapPointScanPersistence.swift

**`saveRecord(_ record: MapPointScanUtility.ScanRecord) -> URL?`** - Encodes a `MapPointScanUtility.ScanRecord` to JSON and writes it to a file named after its `scanID` (or timestamp) in the current location's `scansDir`. Persists scan records.

---

## ScanBuilder.swift

**`makeScan(...) -> ScanRecordV1`** - The main builder method that takes detailed scan data and constructs a `ScanRecordV1` object, performing necessary data transformations and calculations (e.g., converting pixel distances to meters). Builds scan records.

---

## DistanceKit.swift

**`planarPx(from a: CGPoint, to b: CGPoint) -> Double`** - Calculates the 2D planar distance in pixels. Computes pixel distance.

**`planarM(fromPx a: CGPoint, toPx b: CGPoint, ppm: Double) -> Double`** - Calculates the 2D planar distance in meters. Computes meter distance.

**`xyzPx(planar_px: Double, dz_m: Double, ppm: Double) -> Double`** - Calculates the 3D distance in pixels, considering vertical offset. Computes 3D pixel distance.

**`xyzM(planar_m: Double, dz_m: Double) -> Double`** - Calculates the 3D distance in meters, considering vertical offset. Computes 3D meter distance.

---

## MapPointHistory.swift

**`loadAll(locationID: String, pointID: String) throws -> MapPointHistory`** - Loads all `ScanRecordV1` files for a given location, filters them by `pointID`, and sorts them chronologically. Restores historical scan data.

---

## ContentView.swift

**`body`** - Uses a `Group` to conditionally display either `LocationMenuView` or `MapNavigationView` based on `locationManager.showLocationMenu`. Includes an `onAppear` block to bind `transformProcessor` and a `fullScreenCover` to present `ARViewWithOverlays` using `arViewLaunchContext`. Defines the root view structure.

---

## AuthorNamePromptView.swift

**`body`** - Displays a welcome screen prompting the user to enter their name for location exports. Includes a text field, instructions, and a continue button that saves the name and marks onboarding as complete. Provides first-launch onboarding.

**`saveAndDismiss()`** - Saves the entered author name to `AppSettings` and marks onboarding as complete, then dismisses the view. Persists user preferences.

---

## SimpleBeaconLogger.swift

**`startLogging(...)`** - Starts logging beacon data for a map point, initializing session state, capturing device/app context, and starting a countdown timer. Delegates actual scanning to `MapPointScanUtility` and builds a `BeaconLogSession` from the scan record when complete.

**`stopLogging() -> BeaconLogSession?`** - Stops logging and returns the session data. Builds a `BeaconLogSession` from collected obin histograms and statistics, saves it to disk, and cleans up timers and state.

**`startCountdownTimer()`** - Starts a timer to periodically update `secondsRemaining` based on elapsed time. Automatically calls `stopLogging()` when the countdown reaches zero.

**`Obin.add(_ rssi: Int)`** - Adds an RSSI sample to the histogram bin. Updates the distribution of RSSI values.

**`Obin.quantileDbm(_ q: Double) -> Int?`** - Calculates a quantile value from the RSSI histogram using cumulative counts. Returns percentile RSSI values.

**`Obin.madDb(relativeTo median: Int?) -> Double?`** - Calculates the Median Absolute Deviation (MAD) relative to a median value. Measures signal stability and dispersion.

---

## StorageDiagnostics.swift

**`printAllMapPointStorageLocations()`** - Prints all possible storage locations for map points across different location IDs and key patterns. Attempts to decode and count points/sessions for each location to help diagnose persistence issues.

**`scanAllUserDefaultsKeys()`** - Scans ALL UserDefaults keys and reports on data sizes, identifying map point-related keys. Provides a comprehensive overview of UserDefaults usage.

---

## UserDefaultsDiagnostics.swift

**`printInventory()`** - Prints an inventory of all UserDefaults data with sizes, sorted by size (largest first). Includes emoji indicators for data size categories and warns if approaching Apple's 4MB limit.

**`identifyHeavyData() -> [String: Int]`** - Identifies keys that contain heavy data (images, ARWorldMaps, etc.) above a 100KB threshold. Tries to identify the type of data and returns a dictionary of heavy keys with their sizes.

**`inspectMapPointStructure(locationID: String)`** - Inspects the actual structure of MapPoints data without making assumptions, analyzing field sizes and identifying the biggest data consumers. Provides detailed analysis of map point storage.

**`extractPhotos(locationID: String) -> [(index: Int, id: String, base64: String, sizeKB: Double)]`** - Extracts all photos from MapPoints with metadata. Returns an array of photo data including index, ID, base64 string, and size.

**`launchPhotoManager(locationID: String)`** - Posts a notification to launch the photo management interface. Triggers photo management UI.

**`purgePhotosFromUserDefaults(locationID: String, confirmedFilesSaved: [String])`** - Purges photos from UserDefaults after they've been saved to disk, replacing photo data with filename references. Reduces UserDefaults size by moving photos to disk.

**`generatePhotoMigrationPlan()`** - Prints a detailed migration plan for moving photos from UserDefaults to disk storage. Provides step-by-step instructions and impact estimates.

**`removeKeys(_ keys: [String], dryRun: Bool = true)`** - Removes specific keys from UserDefaults, with an optional dry-run mode. Provides safety checks and reports freed space.

**`inspectTriangles(locationID: String)`** - Inspects triangle patch persistence for a given location, decoding triangles and reporting calibration status. Provides diagnostic information about triangle data.

**`validateTriangleVertices(locationID: String, mapPointStore: MapPointStore)`** - Validates that triangle vertex IDs match existing MapPoints, reporting valid and invalid triangles. Helps identify malformed triangle data.

**`deleteMalformedTriangles(locationID: String, mapPointStore: MapPointStore) -> (deletedCount: Int, remainingCount: Int)`** - Deletes triangles with invalid vertex IDs (malformed triangles). Returns counts of deleted and remaining triangles.

**`nukeAllData(confirmation: String)`** - Dangerous function that removes ALL UserDefaults data after confirmation. Requires explicit confirmation string to prevent accidental deletion.

---

## AnchorDataStructures.swift

**`FloorMarkerCapture.init(imageData: Data, markerCoordinates: CGPoint, imageSize: CGSize)`** - Initializes a floor marker capture with image data, normalized coordinates, and image size. Creates floor marker data for Milestone 4.

**`extension simd_float3: Codable`** - Provides custom `Codable` conformance for `simd_float3` by encoding/decoding as an array of three floats. Enables persistence of 3D vectors.

**`extension simd_quatf: Codable`** - Provides custom `Codable` conformance for `simd_quatf` by encoding/decoding as an array of four floats (imaginary xyz + real w). Enables persistence of quaternions.

---

## AnchorSpatialData.swift

**`AnchorPointPackage.init(...)`** - Initializes an anchor point package with map point ID, patch ID, coordinates, anchor position, session transform, and optional visual description. Creates a complete anchor point data structure.

**`AnchorReferenceImage.init(captureType: CaptureType, imageData: Data)`** - Initializes a reference image with capture type and JPEG-compressed image data. Creates reference image data.

**`AnchorSpatialData.totalDataSize`** - Computed property that calculates the total size of spatial data including feature cloud points and planes. Provides data size information.

**`extension AnchorPointPackage: Codable`** - Provides custom `Codable` conformance handling `simd_float3`, `simd_float4x4`, `CGPoint`, and migration of old offset format to transform format. Ensures backward compatibility.

**`extension AnchorFeatureCloud: Codable`** - Provides custom `Codable` conformance for feature cloud, encoding/decoding points as arrays of float arrays. Enables persistence of feature point clouds.

**`extension AnchorPlaneData: Codable`** - Provides custom `Codable` conformance for plane data, encoding/decoding transforms as 16-element float arrays. Enables persistence of plane anchor data.

---

## LocationConfigV1.swift / ScanRecordV1.swift

These files define data structures (`struct LocationConfigV1` and `struct ScanRecordV1`) with their properties. They don't contain functions/methods beyond initializers and computed properties inherent to Swift structs.

---

## Note on UI Views

Many UI view files (e.g., `MapContainer.swift`, `HUDContainer.swift`, `BeaconDrawer.swift`, `MapPointDrawer.swift`, etc.) contain SwiftUI `View` structs with `body` computed properties and helper methods. These follow standard SwiftUI patterns and are not individually listed here, but their key methods are documented in the summary above where relevant.

---

## Summary

This reference covers the major functions and methods across the TapResolver codebase. The app is organized into several key areas:

1. **AR Components**: AR view management, calibration, world map persistence, relocalization
2. **Data Stores**: Map points, triangles, beacons, metric squares, world maps
3. **Bluetooth**: BLE scanning, beacon state management, scan utilities
4. **Persistence**: UserDefaults management, file system operations, data migration
5. **UI/UX**: Map transforms, gesture handling, HUD panels, drawers
6. **Utilities**: Compass/orientation, distance calculations, diagnostics, export

The codebase follows SwiftUI and Combine patterns, with extensive use of `ObservableObject` for state management and dependency injection via environment objects.

