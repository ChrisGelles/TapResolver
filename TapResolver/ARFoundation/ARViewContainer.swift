import SwiftUI
import ARKit
import SceneKit
import simd
import CoreImage
import QuartzCore

struct ARViewContainer: UIViewRepresentable {
    @Binding var mode: ARMode
    
    // Calibration mode properties
    var isCalibrationMode: Bool = false
    var selectedTriangle: TrianglePatch? = nil
    var onDismiss: (() -> Void)? = nil
    
    // Plane visualization toggle
    @Binding var showPlaneVisualization: Bool
    
    // Metric square store for map scale
    var metricSquareStore: MetricSquareStore?
    
    // Map point store for survey markers
    var mapPointStore: MapPointStore?

    // AR calibration coordinator for ghost selection
    var arCalibrationCoordinator: ARCalibrationCoordinator?
    
    // Bluetooth scanner for auto-start/stop during survey
    var bluetoothScanner: BluetoothScanner?

    func makeCoordinator() -> ARViewCoordinator {
        let coordinator = ARViewCoordinator()
        coordinator.selectedTriangle = selectedTriangle
        if let triangle = selectedTriangle {
            print("🔍 [SELECTED_TRIANGLE] Set in makeCoordinator: \(String(triangle.id.uuidString.prefix(8)))")
        } else {
            print("🔍 [SELECTED_TRIANGLE] Set in makeCoordinator: nil")
        }
        coordinator.isCalibrationMode = isCalibrationMode
        coordinator.showPlaneVisualization = showPlaneVisualization
        coordinator.metricSquareStore = metricSquareStore
        coordinator.mapPointStore = mapPointStore
        coordinator.arCalibrationCoordinator = arCalibrationCoordinator
        coordinator.bluetoothScanner = bluetoothScanner
        return coordinator
    }

    func makeUIView(context: Context) -> ARSCNView {
        let sceneView = ARSCNView(frame: .zero)
        sceneView.scene = SCNScene()
        
        // Disable automatic occlusion so markers aren't clipped by ground plane
        sceneView.automaticallyUpdatesLighting = false
        sceneView.rendersCameraGrain = false

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]  // Enable both horizontal and vertical plane detection
        sceneView.session.run(config)
        
        // RELOCALIZATION PREP: Start new AR session
        // TODO: Also call this when session is interrupted/reset
        // Hook into session(_:didFailWithError:), sessionWasInterrupted(_:), or session(_:didUpdate:)
        // Note: arWorldMapStore is passed via notification, so we'll call startNewSession() from ARViewWithOverlays
        
        // Set delegate for plane visualization
        sceneView.delegate = context.coordinator
        
        // Set session delegate for tracking state diagnostics
        sceneView.session.delegate = context.coordinator
        
        // Enable ARKit debug visuals
        sceneView.debugOptions = [
            .showFeaturePoints,
            .showWorldOrigin
        ]

        context.coordinator.sceneView = sceneView
        context.coordinator.setMode(mode)
        context.coordinator.setupTapGesture()
        context.coordinator.setupScene()

        return sceneView
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {
        context.coordinator.setMode(mode)
        
        // Debug: Track when selectedTriangle changes
        let oldTriangleID = context.coordinator.selectedTriangle?.id
        context.coordinator.selectedTriangle = selectedTriangle
        let newTriangleID = selectedTriangle?.id
        if oldTriangleID != newTriangleID {
            if let oldID = oldTriangleID {
                print("🔍 [SELECTED_TRIANGLE] Changed in updateUIView: \(String(oldID.uuidString.prefix(8))) → ", terminator: "")
            } else {
                print("🔍 [SELECTED_TRIANGLE] Changed in updateUIView: nil → ", terminator: "")
            }
            if let newID = newTriangleID {
                print("\(String(newID.uuidString.prefix(8)))")
            } else {
                print("nil")
            }
        }
        
        context.coordinator.isCalibrationMode = isCalibrationMode
        context.coordinator.showPlaneVisualization = showPlaneVisualization
        context.coordinator.metricSquareStore = metricSquareStore
        context.coordinator.mapPointStore = mapPointStore
        context.coordinator.arCalibrationCoordinator = arCalibrationCoordinator
        context.coordinator.bluetoothScanner = bluetoothScanner
        
        // Store coordinator reference for world map access
        ARViewContainer.Coordinator.current = context.coordinator
    }

    class ARViewCoordinator: NSObject {
        static var current: ARViewCoordinator?
        
        var sceneView: ARSCNView?
        var currentMode: ARMode = .idle
        var placedMarkers: [UUID: SCNNode] = [:] // Track placed markers by ID
        var ghostMarkers: [UUID: SCNNode] = [:] // Track ghost markers by MapPoint ID
        /// Stores estimated AR positions for ghost markers (mapPointID → estimated position)
        /// Used for distortion calculation when user adjusts a ghost
        var ghostMarkerPositions: [UUID: simd_float3] = [:]
        var surveyMarkers: [UUID: SurveyMarker] = [:]  // markerID -> SurveyMarker instance
        weak var metricSquareStore: MetricSquareStore?
        weak var mapPointStore: MapPointStore?
        /// Reference to calibration coordinator for ghost selection updates
        weak var arCalibrationCoordinator: ARCalibrationCoordinator?
        weak var bluetoothScanner: BluetoothScanner?
        var crosshairNode: GroundCrosshairNode?
        var currentCursorPosition: simd_float3?
        
        /// Last valid cursor position (lingers for 200ms after raycast gaps)
        private var lastValidCursorPosition: simd_float3?
        
        private var lastValidCursorTimestamp: Date?
        
        // Calibration mode state
        var isCalibrationMode: Bool = false
        var selectedTriangle: TrianglePatch? = nil
        
        // Plane visualization toggle
        var showPlaneVisualization: Bool = true  // Default to enabled
        
        // User device height (centralized constant)
        var userDeviceHeight: Float = ARVisualDefaults.userDeviceHeight
        
        // Track which survey markers have triggered haptic feedback (to prevent continuous firing)
        private var triggeredSurveyMarkers: Set<UUID> = []
        
        /// The survey marker the user's device is currently inside (for inner sphere orientation updates)
        private var currentlyInsideSurveyMarkerID: UUID?
        
        // Timer for updating crosshair
        private var crosshairUpdateTimer: Timer?
        
        // MARK: - Diagnostic Timing
        
        private let sessionStartTime = Date()
        
        private var lastFrameTime: TimeInterval = 0
        
        private var frameDropThreshold: TimeInterval = 0.5 // Log if gap > 500ms
        
        /// Minimum distance from camera to any ghost marker (for proximity gating)
        /// Returns nil if no ghosts exist
        private func distanceToNearestGhost(from cameraPosition: simd_float3) -> Float? {
            guard !ghostMarkerPositions.isEmpty else { return nil }
            
            var minDistance: Float = .greatestFiniteMagnitude
            for (_, ghostPos) in ghostMarkerPositions {
                let distance = simd_distance(cameraPosition, ghostPos)
                if distance < minDistance {
                    minDistance = distance
                }
            }
            return minDistance
        }

        func setMode(_ mode: ARMode) {
            guard mode != currentMode else { return }
            currentMode = mode
            handleModeChange(mode)
        }

        func handleModeChange(_ mode: ARMode) {
            switch mode {
            case .idle:
                print("🚦 AR Mode: idle")
                // Do nothing or reset

            case .calibration(let pointID):
                print("📍 Entering calibration mode for point: \(pointID)")
                // Start calibration logic

            case .triangleCalibration(let triangleID):
                print("🔺 Entering triangle calibration mode for triangle: \(triangleID)")
                // Triangle calibration logic handled via isCalibrationMode and selectedTriangle

            case .interpolation(let first, let second):
                print("📐 Interpolation between \(first) and \(second)")
                // Handle interpolator logic

            case .anchor(let mapPointID):
                print("⚓ Anchoring at map point: \(mapPointID)")
                // Re-anchor based on saved data

            case .metricSquare(let squareID, let sideLength):
                print("📏 Metric square: \(squareID), side: \(sideLength)m")
                // Currently removed; do nothing
                break
            }
        }

        func setupTapGesture() {
            guard let sceneView = sceneView else { return }
            
            // Remove any existing tap gesture recognizers
            sceneView.gestureRecognizers?.forEach { sceneView.removeGestureRecognizer($0) }
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
            sceneView.addGestureRecognizer(tapGesture)
            print("👆 Tap gesture configured")
            
            // Listen for PlaceMarkerAtCursor notification
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handlePlaceMarkerAtCursor),
                name: NSNotification.Name("PlaceMarkerAtCursor"),
                object: nil
            )
            
            // Listen for FillTriangleWithSurveyMarkers notification
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleFillTriangleWithSurveyMarkers),
                name: NSNotification.Name("FillTriangleWithSurveyMarkers"),
                object: nil
            )
            
            // Listen for PlaceTestSurveyMarker notification (generic AR view testing)
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handlePlaceTestSurveyMarker),
                name: NSNotification.Name("PlaceTestSurveyMarker"),
                object: nil
            )
            
            // Fill Swath notification observer
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("FillSwathWithSurveyMarkers"),
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let self = self else { return }
                
                print("🟢 [FILL_SWATH] Notification received")
                
                guard let spacing = notification.userInfo?["spacing"] as? Float,
                      let triangleStore = notification.userInfo?["triangleStore"] as? TrianglePatchStore else {
                    print("⚠️ [FILL_SWATH] Missing required userInfo")
                    return
                }
                
                // Collect all triangles with valid vertex positions
                var fillableTriangles: [TrianglePatch] = []
                var skippedTriangles: [UUID] = []
                
                for triangle in triangleStore.triangles {
                    var allVerticesValid = true
                    
                    for vertexID in triangle.vertexIDs {
                        // Check session position
                        if self.arCalibrationCoordinator?.mapPointARPositions[vertexID] != nil {
                            continue
                        }
                        
                        // Check ghost position
                        if self.ghostMarkerPositions[vertexID] != nil {
                            continue
                        }
                        
                        // Check baked position
                        if let mapPoint = self.mapPointStore?.points.first(where: { $0.id == vertexID }),
                           let bakedPos = mapPoint.canonicalPosition,
                           self.arCalibrationCoordinator?.projectBakedToSession(bakedPos) != nil {
                            continue
                        }
                        
                        // No valid position for this vertex
                        allVerticesValid = false
                        break
                    }
                    
                    if allVerticesValid {
                        fillableTriangles.append(triangle)
                    } else {
                        skippedTriangles.append(triangle.id)
                    }
                }
                
                print("🟢 [FILL_SWATH] Found \(fillableTriangles.count) fillable triangle(s), skipped \(skippedTriangles.count)")
                
                guard !fillableTriangles.isEmpty else {
                    print("⚠️ [FILL_SWATH] No fillable triangles found")
                    self.arCalibrationCoordinator?.exitSurveyMode()
                    return
                }
                
                // Create swath region and fill
                let region = SurveyableRegion.swath(fillableTriangles)
                
                print("🟢 [FILL_SWATH] Filling swath with \(region.triangleCount) triangle(s)")
                
                self.generateSurveyMarkersForRegion(
                    region,
                    spacing: spacing,
                    arWorldMapStore: self.arCalibrationCoordinator?.arStoreAccess ?? ARWorldMapStore()
                )
            }
            
            // Clear Triangle Markers notification observer
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleClearTriangleMarkers(_:)),
                name: NSNotification.Name("ClearTriangleMarkers"),
                object: nil
            )
            
            // Fill Known Triangles notification observer
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleFillKnownTriangles),
                name: NSNotification.Name("FillKnownTriangles"),
                object: nil
            )
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleFillMapWithSurveyMarkers),
                name: NSNotification.Name("FillMapWithSurveyMarkers"),
                object: nil
            )
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleClearAllSurveyMarkers),
                name: NSNotification.Name("ClearAllSurveyMarkers"),
                object: nil
            )
            
            // Listen for triangle calibration complete
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("TriangleCalibrationComplete"),
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let self = self,
                      let triangleID = notification.userInfo?["triangleID"] as? UUID else { return }
                print("📐 Triangle calibration complete - drawing lines for \(String(triangleID.uuidString.prefix(8)))")
                self.drawTriangleLines(triangleID: triangleID)
            }
        }
        
        @objc func handlePlaceMarkerAtCursor(_ notification: Notification) {
            print("🔍 [PLACE_MARKER_CROSSHAIR] Called")
            
            // Use live position, or fall back to lingered position within 200ms window
            let lingerDuration: TimeInterval = 0.2
            let position: simd_float3
            if let livePosition = currentCursorPosition {
                position = livePosition
            } else if let lingeredPosition = lastValidCursorPosition,
                      let timestamp = lastValidCursorTimestamp,
                      Date().timeIntervalSince(timestamp) < lingerDuration {
                position = lingeredPosition
                print("📍 [PLACE_MARKER_CROSSHAIR] Using lingered position (age: \(String(format: "%.0f", Date().timeIntervalSince(timestamp) * 1000))ms)")
            } else {
                print("⚠️ [PLACE_MARKER_CROSSHAIR] No cursor position available (live: nil, lingered: expired)")
                return
            }
            
            // Check if this is crawl mode (adjusting ghost position)
            let isCrawlMode = notification.userInfo?["isCrawlMode"] as? Bool ?? false
            
            if isCrawlMode,
               let ghostMapPointID = notification.userInfo?["ghostMapPointID"] as? UUID,
               let currentTriangleID = notification.userInfo?["currentTriangleID"] as? UUID {
                
                print("🔗 [CRAWL_CROSSHAIR] Crawl mode adjustment detected")
                print("   Ghost MapPoint: \(String(ghostMapPointID.uuidString.prefix(8)))")
                print("   Current Triangle: \(String(currentTriangleID.uuidString.prefix(8)))")
                print("   Crosshair Position: (\(String(format: "%.2f", position.x)), \(String(format: "%.2f", position.y)), \(String(format: "%.2f", position.z)))")
                
                // Remove the ghost marker from scene
                NotificationCenter.default.post(
                    name: NSNotification.Name("RemoveGhostMarker"),
                    object: nil,
                    userInfo: ["mapPointID": ghostMapPointID]
                )
                
                // Place the real marker at crosshair position
                let markerID = placeMarker(at: position)
                print("📍 [CRAWL_CROSSHAIR] Placed adjustment marker \(String(markerID.uuidString.prefix(8)))")
                
                // Register marker→MapPoint association for demote support
                arCalibrationCoordinator?.sessionMarkerToMapPoint[markerID.uuidString] = ghostMapPointID
                print("📍 [CRAWL_CROSSHAIR] Registered marker \(String(markerID.uuidString.prefix(8))) → MapPoint \(String(ghostMapPointID.uuidString.prefix(8)))")
                
                // Activate the adjacent triangle (wasAdjusted: true = placed at crosshair, not ghost position)
                if let coordinator = arCalibrationCoordinator {
                    if let newTriangleID = coordinator.activateAdjacentTriangle(
                        ghostMapPointID: ghostMapPointID,
                        ghostPosition: position,
                        currentTriangleID: currentTriangleID,
                        wasAdjusted: true
                    ) {
                        print("✅ [CRAWL_CROSSHAIR] Successfully activated adjacent triangle \(String(newTriangleID.uuidString.prefix(8)))")
                    } else {
                        print("⚠️ [CRAWL_CROSSHAIR] Failed to activate adjacent triangle")
                    }
                } else {
                    print("⚠️ [CRAWL_CROSSHAIR] No arCalibrationCoordinator reference available")
                }
            } else {
                // Normal marker placement
                let _ = placeMarker(at: position)
            }
        }
        
        @objc func handlePlaceTestSurveyMarker(_ notification: Notification) {
            print("🧪 [TEST_SURVEY_MARKER] Button tapped")
            
            guard let sceneView = sceneView else {
                print("⚠️ [TEST_SURVEY_MARKER] No sceneView available")
                return
            }
            
            // Use live position, or fall back to lingered position within 200ms window
            let lingerDuration: TimeInterval = 0.2
            let position: simd_float3
            if let livePosition = currentCursorPosition {
                position = livePosition
            } else if let lingeredPosition = lastValidCursorPosition,
                      let timestamp = lastValidCursorTimestamp,
                      Date().timeIntervalSince(timestamp) < lingerDuration {
                position = lingeredPosition
                print("🧪 [TEST_SURVEY_MARKER] Using lingered position (age: \(String(format: "%.0f", Date().timeIntervalSince(timestamp) * 1000))ms)")
            } else {
                print("⚠️ [TEST_SURVEY_MARKER] No cursor position available (live: nil, lingered: expired)")
                return
            }
            
            // Create survey marker using consolidated class
            let marker = SurveyMarker(
                at: position,
                userDeviceHeight: userDeviceHeight,
                mapCoordinate: nil,  // Test markers don't have map coordinates
                animated: true
            )
            
            sceneView.scene.rootNode.addChildNode(marker.node)
            surveyMarkers[marker.id] = marker
            
            print("🧪 [TEST_SURVEY_MARKER] Placed at (\(String(format: "%.2f, %.2f, %.2f", position.x, position.y, position.z)))")
            print("   Total survey markers in scene: \(surveyMarkers.count)")
        }
        
        @objc func handleFillTriangleWithSurveyMarkers(notification: Notification) {
            guard let triangleID = notification.userInfo?["triangleID"] as? UUID,
                  let spacing = notification.userInfo?["spacing"] as? Float,
                  let triangleStore = notification.userInfo?["triangleStore"] as? TrianglePatchStore,
                  let arWorldMapStore = notification.userInfo?["arWorldMapStore"] as? ARWorldMapStore else {
                print("⚠️ [FILL_TRIANGLE] Invalid notification data:")
                print("   triangleID: \(notification.userInfo?["triangleID"] != nil)")
                print("   spacing: \(notification.userInfo?["spacing"] != nil)")
                print("   triangleStore: \(notification.userInfo?["triangleStore"] != nil)")
                print("   arWorldMapStore: \(notification.userInfo?["arWorldMapStore"] != nil)")
                return
            }
            
            // CRITICAL: Look up triangle by ID from triangleStore, don't rely on selectedTriangle
            // selectedTriangle might be stale or point to wrong triangle
            guard let triangle = triangleStore.triangle(withID: triangleID) else {
                print("❌ [FILL_TRIANGLE] Triangle \(String(triangleID.uuidString.prefix(8))) not found in triangleStore")
                print("   Available triangles: \(triangleStore.triangles.map { String($0.id.uuidString.prefix(8)) })")
                if let selected = selectedTriangle {
                    print("   selectedTriangle ID: \(String(selected.id.uuidString.prefix(8)))")
                } else {
                    print("   selectedTriangle: nil")
                }
                return
            }
            
            print("✅ [FILL_TRIANGLE] Found triangle \(String(triangleID.uuidString.prefix(8)))")
            print("   arMarkerIDs: \(triangle.arMarkerIDs)")
            print("   vertexIDs: \(triangle.vertexIDs.map { String($0.uuidString.prefix(8)) })")
            
            generateSurveyMarkers(for: triangle, spacing: spacing, arWorldMapStore: arWorldMapStore)
        }
        
        @objc func handleFillSwathWithSurveyMarkers(notification: Notification) {
            print("📬 [ARViewContainer] Received FillSwathWithSurveyMarkers notification")
            
            guard let userInfo = notification.userInfo,
                  let triangleIDs = userInfo["triangleIDs"] as? [UUID],
                  let spacing = userInfo["spacing"] as? Float,
                  let triangleStore = userInfo["triangleStore"] as? TrianglePatchStore,
                  let arWorldMapStore = userInfo["arWorldMapStore"] as? ARWorldMapStore else {
                print("⚠️ [ARViewContainer] FillSwathWithSurveyMarkers missing required data")
                return
            }
            
            print("🔍 [ARViewContainer] Processing Swath: \(triangleIDs.count) triangles, spacing: \(spacing)m")
            
            let triangles = triangleStore.triangles.filter { triangleIDs.contains($0.id) }
            guard !triangles.isEmpty else {
                print("⚠️ [ARViewContainer] No valid triangles found for swath")
                return
            }
            
            let region = SurveyableRegion.swath(triangles)
            generateSurveyMarkersForRegion(region, spacing: spacing, arWorldMapStore: arWorldMapStore)
        }
        
        @objc func handleFillKnownTriangles(notification: Notification) {
            print("📬 [ARViewContainer] Received FillKnownTriangles notification")
            
            guard let userInfo = notification.userInfo,
                  let triangleIDs = userInfo["triangleIDs"] as? [UUID],
                  let spacing = userInfo["spacing"] as? Float,
                  let triangleStore = userInfo["triangleStore"] as? TrianglePatchStore else {
                print("⚠️ [ARViewContainer] FillKnownTriangles missing required data")
                return
            }
            
            print("🔍 [ARViewContainer] Processing Fill Known: \(triangleIDs.count) triangles, spacing: \(spacing)m")
            
            guard let arWorldMapStore = arCalibrationCoordinator?.arStoreAccess else {
                print("⚠️ [ARViewContainer] ARWorldMapStore not available")
                return
            }
            
            let triangles = triangleStore.triangles.filter { triangleIDs.contains($0.id) }
            guard !triangles.isEmpty else {
                print("⚠️ [ARViewContainer] No valid triangles found")
                return
            }
            
            let region = SurveyableRegion.swath(triangles)
            generateSurveyMarkersForRegion(region, spacing: spacing, arWorldMapStore: arWorldMapStore)
        }
        
        @objc func handleFillMapWithSurveyMarkers(notification: Notification) {
            print("📬 [ARViewContainer] Received FillMapWithSurveyMarkers notification")
            
            guard let userInfo = notification.userInfo,
                  let triangleIDs = userInfo["triangleIDs"] as? [UUID],
                  let spacing = userInfo["spacing"] as? Float,
                  let triangleStore = userInfo["triangleStore"] as? TrianglePatchStore else {
                print("⚠️ [ARViewContainer] FillMapWithSurveyMarkers missing required data")
                return
            }
            
            // Check if we should clear first
            let clearFirst = userInfo["clearFirst"] as? Bool ?? false
            if clearFirst {
                print("🧹 [FILL_MAP] Clearing existing markers first")
                clearSurveyMarkers()
            }
            
            print("🗺️ [ARViewContainer] Processing Fill Map: \(triangleIDs.count) triangles, spacing: \(spacing)m")
            
            guard let arWorldMapStore = arCalibrationCoordinator?.arStoreAccess else {
                print("⚠️ [ARViewContainer] ARWorldMapStore not available")
                return
            }
            
            let triangles = triangleStore.triangles.filter { triangleIDs.contains($0.id) }
            guard !triangles.isEmpty else {
                print("⚠️ [ARViewContainer] No valid triangles found")
                return
            }
            
            let region = SurveyableRegion.swath(triangles)
            generateSurveyMarkersForRegion(region, spacing: spacing, arWorldMapStore: arWorldMapStore)
        }
        
        @objc func handleClearAllSurveyMarkers(_ notification: Notification) {
            print("🧹 [CLEAR_ALL] Clearing all survey markers")
            clearSurveyMarkers()
        }
        
        @objc func handleClearTriangleMarkers(_ notification: Notification) {
            guard let triangleID = notification.userInfo?["triangleID"] as? UUID else {
                print("⚠️ [CLEAR_TRIANGLE] No triangleID provided")
                return
            }
            
            print("🧹 [CLEAR_TRIANGLE] Clearing markers for triangle \(String(triangleID.uuidString.prefix(8)))")
            clearSurveyMarkersForTriangle(triangleID)
        }
        
        @objc func handlePlaceGhostMarker(notification: Notification) {
            guard let mapPointID = notification.userInfo?["mapPointID"] as? UUID,
                  let position = notification.userInfo?["position"] as? simd_float3 else {
                print("⚠️ [GHOST_RENDER] Invalid PlaceGhostMarker notification data")
                return
            }
            
            let sceneStart = Date()
            print("👻 [GHOST_RENDER] Placing ghost marker for MapPoint \(String(mapPointID.uuidString.prefix(8)))")
            
            // Check if ghost already exists for this MapPoint
            if ghostMarkers[mapPointID] != nil {
                print("⚠️ [GHOST_RENDER] Ghost already exists for MapPoint \(String(mapPointID.uuidString.prefix(8))) - skipping")
                return
            }
            
            // Create ghost marker node (REUSE existing ARMarkerRenderer)
            let ghostNode = ARMarkerRenderer.createNode(
                at: position,
                options: MarkerOptions(
                    color: .orange,  // User-specified color for ghosts
                    markerID: UUID(),  // Temporary ID for ghost
                    userDeviceHeight: userDeviceHeight,
                    badgeColor: nil,
                    radius: 0.03,
                    animateOnAppearance: true,  // Smooth appearance animation
                    animationOvershoot: 0.04,
                    isGhost: true  // CRITICAL: Enables pulsing animation and transparency
                )
            )
            
            ghostNode.name = "ghostMarker_\(mapPointID.uuidString)"
            
            // Store in ghostMarkers dictionary (REUSE existing storage)
            ghostMarkers[mapPointID] = ghostNode
            ghostMarkerPositions[mapPointID] = position
            
            // Also track in coordinator for fillable triangle counting
            arCalibrationCoordinator?.ghostMarkerPositions[mapPointID] = position
            
            // Add to scene
            sceneView?.scene.rootNode.addChildNode(ghostNode)
            
            let sceneDuration = Date().timeIntervalSince(sceneStart) * 1000
            print("✅ [GHOST_RENDER] Ghost marker rendered for MapPoint \(String(mapPointID.uuidString.prefix(8)))")
            print("   ⏱️ SceneKit creation: \(String(format: "%.1f", sceneDuration))ms")
        }
        
        /// Create a ghost marker at the specified position for the given MapPoint ID
        func createGhostMarker(at position: simd_float3, for mapPointID: UUID) {
            // Check if ghost already exists for this MapPoint
            if ghostMarkers[mapPointID] != nil {
                print("⚠️ [GHOST_CREATE] Ghost already exists for MapPoint \(String(mapPointID.uuidString.prefix(8))) - skipping")
                return
            }
            
            // Create ghost marker node
            let ghostNode = ARMarkerRenderer.createNode(
                at: position,
                options: MarkerOptions(
                    color: .orange,
                    markerID: UUID(),
                    userDeviceHeight: userDeviceHeight,
                    badgeColor: nil,
                    radius: 0.03,
                    animateOnAppearance: true,
                    animationOvershoot: 0.04,
                    isGhost: true
                )
            )
            
            ghostNode.name = "ghostMarker_\(mapPointID.uuidString)"
            
            // Store in ghostMarkers dictionary
            ghostMarkers[mapPointID] = ghostNode
            ghostMarkerPositions[mapPointID] = position
            
            // Also track in coordinator for fillable triangle counting
            arCalibrationCoordinator?.ghostMarkerPositions[mapPointID] = position
            
            // Add to scene
            sceneView?.scene.rootNode.addChildNode(ghostNode)
            
            print("✅ [GHOST_CREATE] Created ghost marker for MapPoint \(String(mapPointID.uuidString.prefix(8)))")
        }
        
        /// Remove a ghost marker from the scene
        func removeGhostMarker(mapPointID: UUID) {
            guard let ghostNode = ghostMarkers[mapPointID] else {
                print("⚠️ [GHOST_REMOVE] No ghost found for MapPoint \(String(mapPointID.uuidString.prefix(8)))")
                return
            }
            
            ghostNode.removeFromParentNode()
            ghostMarkers.removeValue(forKey: mapPointID)
            ghostMarkerPositions.removeValue(forKey: mapPointID)
            arCalibrationCoordinator?.ghostMarkerPositions.removeValue(forKey: mapPointID)
            print("🗑️ [GHOST_REMOVE] Removed ghost for MapPoint \(String(mapPointID.uuidString.prefix(8)))")
        }
        
        @objc func handleRemoveGhostMarker(_ notification: Notification) {
            guard let mapPointID = notification.userInfo?["mapPointID"] as? UUID else {
                print("⚠️ [GHOST_REMOVE] No mapPointID in notification")
                return
            }
            
            print("👻 [GHOST_REMOVE] Removing ghost marker for MapPoint \(String(mapPointID.uuidString.prefix(8)))")
            
            // Remove from tracking dictionary
            ghostMarkerPositions.removeValue(forKey: mapPointID)
            arCalibrationCoordinator?.ghostMarkerPositions.removeValue(forKey: mapPointID)
            
            // Find and remove the ghost node from scene
            let nodeName = "ghostMarker_\(mapPointID.uuidString)"
            if let ghostNode = ghostMarkers[mapPointID] {
                ghostNode.removeFromParentNode()
                ghostMarkers.removeValue(forKey: mapPointID)
                print("✅ [GHOST_REMOVE] Removed ghost node '\(nodeName)' from scene")
            } else {
                // Try finding by name as fallback
                if let ghostNode = sceneView?.scene.rootNode.childNode(withName: nodeName, recursively: true) {
                    ghostNode.removeFromParentNode()
                    print("✅ [GHOST_REMOVE] Removed ghost node '\(nodeName)' from scene (found by name)")
                } else {
                    print("⚠️ [GHOST_REMOVE] Could not find ghost node '\(nodeName)' in scene")
                }
            }
        }
        
        @objc func handleConfirmGhostMarker(_ notification: Notification) {
            print("🎯 [GHOST_CONFIRM] Confirm ghost marker notification received")
            
            // Accept either "ghostMapPointID" or "mapPointID" key (crawl mode uses mapPointID)
            guard let ghostMapPointID = (notification.userInfo?["ghostMapPointID"] as? UUID) 
                    ?? (notification.userInfo?["mapPointID"] as? UUID) else {
                print("⚠️ [GHOST_CONFIRM] No mapPointID in notification")
                return
            }
            
            // Get position from ghostMarkerPositions OR from notification payload (crawl mode)
            let estimatedPosition: simd_float3
            if let cachedPosition = ghostMarkerPositions[ghostMapPointID] {
                estimatedPosition = cachedPosition
            } else if let positionArray = notification.userInfo?["position"] as? [Float],
                      positionArray.count == 3 {
                estimatedPosition = simd_float3(positionArray[0], positionArray[1], positionArray[2])
                print("📍 [GHOST_CONFIRM] Using position from notification payload (crawl mode)")
            } else {
                print("⚠️ [GHOST_CONFIRM] No position available for ghost")
                return
            }
            
            print("🎯 [GHOST_CONFIRM] Confirming ghost for MapPoint \(String(ghostMapPointID.uuidString.prefix(8)))")
            print("   Estimated position: (\(String(format: "%.2f", estimatedPosition.x)), \(String(format: "%.2f", estimatedPosition.y)), \(String(format: "%.2f", estimatedPosition.z)))")
            
            // Create marker at the ghost's estimated position
            let markerID = UUID()
            
            // Get map coordinates for the MapPoint
            guard let mapPoint = mapPointStore?.points.first(where: { $0.id == ghostMapPointID }) else {
                print("⚠️ [GHOST_CONFIRM] Could not find MapPoint for ghost")
                return
            }
            
            // Create visual marker at ghost position
            let markerNode = ARMarkerRenderer.createNode(
                at: estimatedPosition,
                options: MarkerOptions(
                    color: .orange,  // Standard calibration marker color
                    markerID: markerID,
                    userDeviceHeight: userDeviceHeight,
                    badgeColor: nil,
                    radius: 0.03,
                    animateOnAppearance: true,
                    animationOvershoot: 0.04,
                    isGhost: false
                )
            )
            
            markerNode.name = "arMarker_\(markerID.uuidString)"
            sceneView?.scene.rootNode.addChildNode(markerNode)
            placedMarkers[markerID] = markerNode
            
            print("🎯 [GHOST_CONFIRM] Created marker \(String(markerID.uuidString.prefix(8))) at ghost position")
            
            // Register marker→MapPoint association for demote support (especially for demote reconfirm)
            let isDemoteReconfirm = notification.userInfo?["isDemoteReconfirm"] as? Bool ?? false
            if isDemoteReconfirm {
                arCalibrationCoordinator?.sessionMarkerToMapPoint[markerID.uuidString] = ghostMapPointID
                print("📍 [CONFIRM_GHOST] Registered demote reconfirm marker \(String(markerID.uuidString.prefix(8))) → MapPoint \(String(ghostMapPointID.uuidString.prefix(8)))")
            }
            
            // Remove the ghost marker node from scene
            if let ghostNode = ghostMarkers[ghostMapPointID] {
                ghostNode.removeFromParentNode()
                ghostMarkers.removeValue(forKey: ghostMapPointID)
                ghostMarkerPositions.removeValue(forKey: ghostMapPointID)
                arCalibrationCoordinator?.ghostMarkerPositions.removeValue(forKey: ghostMapPointID)
                print("🎯 [GHOST_CONFIRM] Removed ghost node from scene")
            }
            
            // Post ARMarkerPlaced notification with ghost confirm flag
            NotificationCenter.default.post(
                name: NSNotification.Name("ARMarkerPlaced"),
                object: nil,
                userInfo: [
                    "markerID": markerID,
                    "position": [estimatedPosition.x, estimatedPosition.y, estimatedPosition.z],
                    "isGhostConfirm": true,
                    "ghostMapPointID": ghostMapPointID
                ]
            )
            
            print("✅ [GHOST_CONFIRM] Posted ARMarkerPlaced notification with ghost confirm flag")
        }

        @objc func handleTapGesture(_ sender: UITapGestureRecognizer) {
            // DIAGNOSTIC: Log every tap
            let tapLocation = sender.location(in: sceneView ?? sender.view)
            print("👆 [TAP_DIAG] ═══════════════════════════════════════")
            print("👆 [TAP_DIAG] Tap received at screen position: \(tapLocation)")
            print("👆 [TAP_DIAG] Current mode: \(currentMode)")
            print("👆 [TAP_DIAG] Calibration state: \(arCalibrationCoordinator?.stateDescription ?? "nil coordinator")")
            
            print("🔍 [TAP_TRACE] Tap detected")
            print("   Current mode: \(currentMode)")
            
            // Disable tap-to-place in idle mode - use Place AR Marker button instead
            guard currentMode != .idle else {
                print("👆 [TAP_TRACE] Tap ignored in idle mode — use Place AR Marker button")
                return
            }
            
            // Disable tap-to-place in triangle calibration mode - use Place Marker button instead
            // But allow tapping on existing AR markers to demote them to ghosts
            if case .triangleCalibration = currentMode {
                print("👆 [TAP_DIAG] Mode is .triangleCalibration - checking for AR marker tap")
                guard let sceneView = sceneView else {
                    print("👆 [TAP_DIAG] ⚠️ sceneView is nil!")
                    return
                }
                
                // Check if user tapped on an existing AR marker for re-adjustment
                // Note: tapLocation already captured at function entry for diagnostics
                let markerTapLocation = sender.location(in: sceneView)
                print("👆 [TAP_DIAG] Calling hitTestARMarker at \(markerTapLocation)")
                if let tappedMarkerID = hitTestARMarker(at: markerTapLocation, in: sceneView) {
                    print("👆 [TAP_MARKER] Tapped AR marker \(String(tappedMarkerID.uuidString.prefix(8))) - demoting to ghost")
                    demoteMarkerToGhost(markerID: tappedMarkerID)
                    return
                }
                
                print("👆 [TAP_TRACE] Tap ignored in triangle calibration mode — use Place Marker button or tap an AR marker to adjust")
                return
            }
            
            // DIAGNOSTIC: Log if we're in a different mode
            print("👆 [TAP_DIAG] Not in .triangleCalibration mode - current mode: \(currentMode)")
            
            guard let sceneView = sceneView else { return }
            
            let location = sender.location(in: sceneView)
            
            // Perform hit test to find world position
            let hitTestResults = sceneView.hitTest(location, types: [.featurePoint, .estimatedHorizontalPlane])
            
            guard let result = hitTestResults.first else {
                print("⚠️ No hit test result at tap location")
                return
            }
            
            // Extract world position from transform matrix
            let worldTransform = result.worldTransform
            let position = simd_float3(
                worldTransform.columns.3.x,
                worldTransform.columns.3.y,
                worldTransform.columns.3.z
            )
            
            print("👆 Tap detected at screen: \(location), world: \(position)")
            placeMarker(at: position)
        }
        
        /// Hit-test to find if tap intersects an AR marker's sphere topper
        /// - Parameters:
        ///   - point: Screen point of tap
        ///   - sceneView: The AR scene view
        /// - Returns: The marker UUID if hit, nil otherwise
        private func hitTestARMarker(at point: CGPoint, in sceneView: ARSCNView) -> UUID? {
            print("🎯 [HIT_TEST_DIAG] ───────────────────────────────")
            print("🎯 [HIT_TEST_DIAG] Testing point: \(point)")
            
            let hitResults = sceneView.hitTest(point, options: [
                .searchMode: SCNHitTestSearchMode.all.rawValue,
                .ignoreHiddenNodes: false
            ])
            
            print("🎯 [HIT_TEST_DIAG] Total hit results: \(hitResults.count)")
            
            if hitResults.isEmpty {
                print("🎯 [HIT_TEST_DIAG] ⚠️ No nodes hit at all - tap missed all geometry")
                return nil
            }
            
            for (index, result) in hitResults.enumerated() {
                print("🎯 [HIT_TEST_DIAG] Hit[\(index)]: node='\(result.node.name ?? "unnamed")' geometry=\(type(of: result.node.geometry as Any))")
                
                // Check if we hit a marker node (sphere topper or pole)
                var node: SCNNode? = result.node
                var depth = 0
                
                // Walk up the hierarchy to find the marker root
                while let current = node {
                    let nodeName = current.name ?? "unnamed"
                    print("🎯 [HIT_TEST_DIAG]   ↳ depth[\(depth)]: '\(nodeName)'")
                    
                    if let name = current.name {
                        // Check for marker root node: "arMarker_<UUID>"
                        if name.hasPrefix("arMarker_") && !name.hasPrefix("arMarkerSphere_") {
                            let uuidString = String(name.dropFirst("arMarker_".count))
                            print("🎯 [HIT_TEST_DIAG]   Found arMarker_ prefix, UUID string: '\(uuidString)'")
                            if let uuid = UUID(uuidString: uuidString) {
                                print("🎯 [HIT_TEST_DIAG] ✅ SUCCESS: Hit AR marker \(String(uuid.uuidString.prefix(8)))")
                                return uuid
                            } else {
                                print("🎯 [HIT_TEST_DIAG] ⚠️ UUID parse failed for: '\(uuidString)'")
                            }
                        }
                        // Check for sphere node: "arMarkerSphere_<UUID>"
                        if name.hasPrefix("arMarkerSphere_") {
                            let uuidString = String(name.dropFirst("arMarkerSphere_".count))
                            print("🎯 [HIT_TEST_DIAG]   Found arMarkerSphere_ prefix, UUID string: '\(uuidString)'")
                            if let uuid = UUID(uuidString: uuidString) {
                                print("🎯 [HIT_TEST_DIAG] ✅ SUCCESS: Hit AR marker sphere \(String(uuid.uuidString.prefix(8)))")
                                return uuid
                            } else {
                                print("🎯 [HIT_TEST_DIAG] ⚠️ UUID parse failed for: '\(uuidString)'")
                            }
                        }
                        // Check for ghost marker tap
                        if name.hasPrefix("ghostMarker_") {
                            let uuidString = String(name.dropFirst("ghostMarker_".count))
                            print("🎯 [HIT_TEST_DIAG]   Found ghostMarker_ prefix, UUID string: '\(uuidString)'")
                            if let uuid = UUID(uuidString: uuidString) {
                                print("🎯 [HIT_TEST_DIAG] ✅ SUCCESS: Hit ghost marker \(String(uuid.uuidString.prefix(8)))")
                                // Select this ghost instead of returning marker UUID
                                if let coordinator = self.arCalibrationCoordinator {
                                    // Find the MapPoint ID from the ghost node name (ghost nodes use MapPoint ID)
                                    coordinator.selectedGhostMapPointID = uuid
                                    // Get position from the ghost node
                                    let ghostPosition = current.simdWorldPosition
                                    coordinator.selectedGhostEstimatedPosition = ghostPosition
                                    print("👻 [GHOST_TAP] Selected ghost \(String(uuid.uuidString.prefix(8))) via tap at position \(ghostPosition)")
                                }
                                return nil  // Return nil since this isn't an AR marker demote
                            } else {
                                print("🎯 [HIT_TEST_DIAG] ⚠️ UUID parse failed for ghost marker: '\(uuidString)'")
                            }
                        }
                    }
                    node = current.parent
                    depth += 1
                }
            }
            
            print("🎯 [HIT_TEST_DIAG] ❌ No AR marker found in any hit result")
            return nil
        }
        
        /// Demote an AR marker to a ghost marker for re-adjustment
        /// - Parameter markerID: The AR marker's UUID
        private func demoteMarkerToGhost(markerID: UUID) {
            guard let sceneView = sceneView else {
                print("⚠️ [DEMOTE] sceneView is nil")
                return
            }
            
            // Find the marker node - check placedMarkers dictionary first
            let markerNode: SCNNode?
            if let node = placedMarkers[markerID] {
                markerNode = node
            } else {
                // Fallback: search scene for node with matching name
                markerNode = sceneView.scene.rootNode.childNodes.first(where: {
                    $0.name == "arMarker_\(markerID.uuidString)"
                })
            }
            
            guard let node = markerNode else {
                print("⚠️ [DEMOTE] Could not find marker node for \(String(markerID.uuidString.prefix(8)))")
                return
            }
            
            // Get the marker's current position
            let currentPosition = node.simdWorldPosition
            
            // Post notification with marker ID and let coordinator resolve
            print("🔄 [DEMOTE] Posting DemoteMarkerToGhost notification")
            NotificationCenter.default.post(
                name: NSNotification.Name("DemoteMarkerToGhost"),
                object: nil,
                userInfo: [
                    "markerID": markerID,
                    "currentPosition": [Float(currentPosition.x), Float(currentPosition.y), Float(currentPosition.z)]
                ]
            )
        }

        @discardableResult
        func placeMarker(at position: simd_float3) -> UUID {
            guard let sceneView = sceneView else { return UUID() }
            
            let markerID = UUID()
            
            // Determine color based on current mode
            let markerColor: UIColor
            let shouldAnimate: Bool
            switch currentMode {
            case .calibration:
                markerColor = UIColor.ARPalette.calibration
                shouldAnimate = false
            case .triangleCalibration(_):
                markerColor = UIColor.ARPalette.calibration  // Orange for triangle calibration
                shouldAnimate = true
            case .anchor:
                markerColor = UIColor.ARPalette.anchor
                shouldAnimate = false
            default:
                markerColor = UIColor.ARPalette.markerBase
                shouldAnimate = false
            }
            
            // Create marker using centralized renderer
            let options = MarkerOptions(
                color: markerColor,
                markerID: markerID,
                userDeviceHeight: userDeviceHeight,
                animateOnAppearance: shouldAnimate
            )
            let markerNode = ARMarkerRenderer.createNode(at: position, options: options)
            
            sceneView.scene.rootNode.addChildNode(markerNode)
            
            // Track the marker
            placedMarkers[markerID] = markerNode
            
            print("📍 Placed marker \(String(markerID.uuidString.prefix(8))) at AR(\(String(format: "%.2f", position.x)), \(String(format: "%.2f", position.y)), \(String(format: "%.2f", position.z))) meters")
            
            // Post notification for marker placement
            NotificationCenter.default.post(
                name: NSNotification.Name("ARMarkerPlaced"),
                object: nil,
                userInfo: [
                    "markerID": markerID,
                    "position": [position.x, position.y, position.z] // Convert simd_float3 to array
                ]
            )
            
            return markerID
        }

        func setupScene() {
            guard let sceneView = sceneView else { return }
            
            // Setup modular crosshair
            crosshairNode = GroundCrosshairNode()
            if let node = crosshairNode {
                sceneView.scene.rootNode.addChildNode(node)
            }
            
            // Start updating crosshair position and checking collisions
            crosshairUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                self?.updateCrosshair()
                self?.checkSurveyMarkerCollisions()
            }
            
            // Listen for PlaceGhostMarker notification
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handlePlaceGhostMarker),
                name: NSNotification.Name("PlaceGhostMarker"),
                object: nil
            )
            
            // Listen for ConfirmGhostMarker notification
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleConfirmGhostMarker),
                name: NSNotification.Name("ConfirmGhostMarker"),
                object: nil
            )
            
            // Listen for RefreshAdjacentGhosts notification
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("RefreshAdjacentGhosts"),
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let self = self,
                      let triangleID = notification.userInfo?["triangleID"] as? UUID,
                      let placedMapPointID = notification.userInfo?["placedMapPointID"] as? UUID else {
                    print("⚠️ [REFRESH_GHOSTS] Missing required data in notification")
                    return
                }
                
                print("👻 [REFRESH_GHOSTS] Creating ghosts for triangle \(String(triangleID.uuidString.prefix(8)))")
                
                guard let triangle = self.arCalibrationCoordinator?.triangleStoreAccess.triangle(withID: triangleID) else {
                    print("⚠️ [REFRESH_GHOSTS] Triangle not found")
                    return
                }
                
                // Find vertices that don't have markers yet
                for vertexID in triangle.vertexIDs {
                    // Skip the vertex we just placed
                    guard vertexID != placedMapPointID else { continue }
                    
                    // Skip if already has a position in this session
                    guard self.arCalibrationCoordinator?.mapPointARPositions[vertexID] == nil else {
                        print("   Vertex \(String(vertexID.uuidString.prefix(8))): Already has session position")
                        continue
                    }
                    
                    // Skip if ghost already exists
                    if self.ghostMarkerPositions[vertexID] != nil {
                        print("   Vertex \(String(vertexID.uuidString.prefix(8))): Ghost already exists")
                        continue
                    }
                    
                    // Try to create ghost from baked position
                    if let coordinator = self.arCalibrationCoordinator,
                       coordinator.hasValidSessionTransform,
                       let mapPoint = self.mapPointStore?.points.first(where: { $0.id == vertexID }),
                       let bakedPos = mapPoint.canonicalPosition,
                       let sessionPos = coordinator.projectBakedToSession(bakedPos) {
                        
                        self.createGhostMarker(at: sessionPos, for: vertexID)
                        print("   Vertex \(String(vertexID.uuidString.prefix(8))): Created ghost from baked position")
                    } else {
                        print("   Vertex \(String(vertexID.uuidString.prefix(8))): No baked position available")
                    }
                }
            }
            
            // Listen for RemoveGhostMarker notification (crawl mode cleanup)
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleRemoveGhostMarker),
                name: NSNotification.Name("RemoveGhostMarker"),
                object: nil
            )
            
            // Listen for DemoteMarkerResponse (coordinator tells us which MapPoint to convert)
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("DemoteMarkerResponse"),
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let self = self,
                      let markerID = notification.userInfo?["markerID"] as? UUID,
                      let mapPointID = notification.userInfo?["mapPointID"] as? UUID,
                      let positionArray = notification.userInfo?["position"] as? [Float],
                      positionArray.count == 3 else {
                    print("⚠️ [DEMOTE_RESPONSE] Missing required data in notification")
                    return
                }
                
                let position = simd_float3(positionArray[0], positionArray[1], positionArray[2])
                
                print("🔄 [DEMOTE_RESPONSE] Converting marker \(String(markerID.uuidString.prefix(8))) for MapPoint \(String(mapPointID.uuidString.prefix(8)))")
                
                // Remove AR marker visual
                if let markerNode = self.placedMarkers[markerID] {
                    markerNode.removeFromParentNode()
                    self.placedMarkers.removeValue(forKey: markerID)
                }
                
                // Create ghost marker at same position
                self.createGhostMarker(at: position, for: mapPointID)
                
                // Store in ghostMarkerPositions for proximity detection
                self.ghostMarkerPositions[mapPointID] = position
                
                print("✅ [DEMOTE] AR marker demoted to ghost - ready for adjustment")
            }
            
            print("👻 Ghost marker notification listener registered")
            
            print("➕ Ground crosshair configured")
        }
        
        /// Check if a 3D position is visible in the camera's field of view
        /// Thread-safe implementation using only ARKit camera matrices (no UIKit)
        /// - Parameters:
        ///   - position: The 3D world position to check
        ///   - margin: NDC margin (0.0 to 1.0) - e.g., 0.1 means 10% inset from edges
        /// - Returns: true if the position is in front of camera and within the field of view
        func isPositionInCameraView(_ position: simd_float3, margin: Float = 0.1) -> Bool {
            guard let sceneView = sceneView,
                  let frame = sceneView.session.currentFrame else { return false }
            
            let camera = frame.camera
            
            // Get camera matrices
            let viewMatrix = camera.viewMatrix(for: .portrait)
            let projectionMatrix = camera.projectionMatrix(for: .portrait, 
                                                            viewportSize: CGSize(width: 1, height: 1), 
                                                            zNear: 0.001, 
                                                            zFar: 1000)
            
            // Create homogeneous world position
            let worldPos = simd_float4(position.x, position.y, position.z, 1.0)
            
            // Transform to view space, then to clip space
            let viewPos = viewMatrix * worldPos
            let clipPos = projectionMatrix * viewPos
            
            // Check if point is behind camera (w <= 0 means behind or at camera plane)
            if clipPos.w <= 0 {
                return false
            }
            
            // Convert to normalized device coordinates (NDC): [-1, 1] range
            let ndcX = clipPos.x / clipPos.w
            let ndcY = clipPos.y / clipPos.w
            
            // Check if within bounds (with margin)
            // NDC range is -1 to 1, so threshold is (1 - margin)
            let threshold = 1.0 - margin
            
            return abs(ndcX) < threshold && abs(ndcY) < threshold
        }
        
        func updateCrosshair() {
            // Skip crosshair updates when inside survey marker sphere
            guard currentlyInsideSurveyMarkerID == nil else { return }
            
            guard let sceneView = sceneView,
                  let crosshair = crosshairNode else { return }
            
            let screenCenter = CGPoint(x: sceneView.bounds.midX, y: sceneView.bounds.midY)
            let lingerDuration: TimeInterval = 0.2  // 200ms linger window
            
            guard let query = sceneView.raycastQuery(from: screenCenter, allowing: .estimatedPlane, alignment: .horizontal) else {
                // Raycast query failed - check if we should linger
                currentCursorPosition = nil
                
                if let lastPos = lastValidCursorPosition,
                   let lastTime = lastValidCursorTimestamp {
                    let staleness = Date().timeIntervalSince(lastTime)
                    if staleness < lingerDuration {
                        // Linger: keep crosshair visible but fade opacity
                        let opacity = CGFloat(1.0 - (staleness / lingerDuration))
                        crosshair.opacity = opacity
                        crosshair.update(position: lastPos, snapped: false, confident: false)
                    } else {
                        // Linger expired
                        crosshair.hide()
                        crosshair.opacity = 1.0
                    }
                } else {
                    crosshair.hide()
                }
                return
            }
            
            let results = sceneView.session.raycast(query)
            
            if let result = results.first {
                let rawPosition = simd_float3(
                    result.worldTransform.columns.3.x,
                    result.worldTransform.columns.3.y,
                    result.worldTransform.columns.3.z
                )
                
                // Check for corner snapping (optional - can be enhanced later)
                let snappedPosition = findNearbyCorner(from: rawPosition) ?? rawPosition
                let isSnapped = snappedPosition != rawPosition
                let isConfident = isPlaneConfident(result)
                
                // Update live position and linger cache
                currentCursorPosition = snappedPosition
                lastValidCursorPosition = snappedPosition
                lastValidCursorTimestamp = Date()
                
                // Full opacity for live position
                crosshair.opacity = 1.0
                crosshair.update(position: snappedPosition, snapped: isSnapped, confident: isConfident)
                
                if isSnapped {
                    print("📍 Crosshair snapped to corner")
                }
            } else {
                // Raycast returned no results - check if we should linger
                currentCursorPosition = nil
                
                if let lastPos = lastValidCursorPosition,
                   let lastTime = lastValidCursorTimestamp {
                    let staleness = Date().timeIntervalSince(lastTime)
                    if staleness < lingerDuration {
                        // Linger: keep crosshair visible but fade opacity
                        let opacity = CGFloat(1.0 - (staleness / lingerDuration))
                        crosshair.opacity = opacity
                        crosshair.update(position: lastPos, snapped: false, confident: false)
                    } else {
                        // Linger expired
                        crosshair.hide()
                        crosshair.opacity = 1.0
                    }
                } else {
                    crosshair.hide()
                }
            }
            
            // Check for survey marker collisions
            checkSurveyMarkerCollisions()
        }
        
        private func isPlaneConfident(_ result: ARRaycastResult) -> Bool {
            guard let planeAnchor = result.anchor as? ARPlaneAnchor else { return false }
            let extent = planeAnchor.planeExtent
            return (extent.width * extent.height) > 0.5
        }
        
        private func findNearbyCorner(from position: simd_float3) -> simd_float3? {
            // TODO: Implement corner detection logic if needed
            // For now, return nil to disable snapping
            return nil
        }

        /// Get the current ARWorldMap from the session (async)
        func getCurrentWorldMap(completion: @escaping (ARWorldMap?, Error?) -> Void) {
            guard let session = sceneView?.session else {
                completion(nil, NSError(domain: "ARViewContainer", code: -1, userInfo: [NSLocalizedDescriptionKey: "No AR session available"]))
                return
            }
            
            session.getCurrentWorldMap { map, error in
                completion(map, error)
            }
        }
        
        /// Capture current AR camera frame as UIImage
        func captureARFrame(completion: @escaping (UIImage?) -> Void) {
            guard let sceneView = sceneView else {
                completion(nil)
                return
            }
            
            // Get current ARFrame from session
            guard let frame = sceneView.session.currentFrame else {
                print("⚠️ No current ARFrame available")
                completion(nil)
                return
            }
            
            // Convert ARFrame's capturedImage (CVPixelBuffer) to UIImage
            let pixelBuffer = frame.capturedImage
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext()
            
            guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
                print("⚠️ Failed to create CGImage from ARFrame")
                completion(nil)
                return
            }
            
            // Convert to UIImage, accounting for camera orientation
            let image = UIImage(cgImage: cgImage, scale: 1.0, orientation: .right)
            completion(image)
        }
        
        /// Get current AR camera world position
        func getCurrentCameraPosition() -> simd_float3? {
            guard let sceneView = sceneView,
                  let frame = sceneView.session.currentFrame else {
                return nil
            }
            
            let cameraTransform = frame.camera.transform
            let position = simd_float3(
                cameraTransform.columns.3.x,
                cameraTransform.columns.3.y,
                cameraTransform.columns.3.z
            )
            return position
        }
        
        /// Get current AR camera pose (position + orientation) for survey capture
        func getCurrentPose() -> SurveyDevicePose? {
            guard let sceneView = sceneView,
                  let frame = sceneView.session.currentFrame else {
                return nil
            }
            
            let transform = frame.camera.transform
            
            // Position from translation column
            let x = transform.columns.3.x
            let y = transform.columns.3.y
            let z = transform.columns.3.z
            
            // Quaternion from rotation matrix
            let quat = simd_quatf(transform)
            
            return SurveyDevicePose(
                x: x,
                y: y,
                z: z,
                qx: quat.imag.x,
                qy: quat.imag.y,
                qz: quat.imag.z,
                qw: quat.real
            )
        }
        
        // MARK: - DEPRECATED
        /// DO NOT USE - Legacy function with incorrect interpolation.
        /// Use plantGhostMarkers(calibratedTriangle:, triangleStore:, filter:) instead.
        func estimateWorldPosition(for mapPoint: CGPoint, using triangle: TrianglePatch?) -> simd_float3? {
            print("⚠️ [DEPRECATED] Function \(#function) was called. Refactor needed.")
            if let symbol = Thread.callStackSymbols.dropFirst(1).first {
                print("🔍 Called by: \(symbol)")
            }
            return nil
            
            /* OLD LOGIC COMMENTED OUT
            guard let sceneView = sceneView,
                  let frame = sceneView.session.currentFrame else {
                return nil
            }
            
            // If triangle has a transform, use it to project map coordinates to AR space
            if let triangle = triangle,
               let transform = triangle.transform {
                // Convert map point to AR space using Similarity2D transform
                let mapPointFloat = simd_float2(Float(mapPoint.x), Float(mapPoint.y))
                let transformed = transform.rotation * (mapPointFloat * transform.scale) + transform.translation
                // Use device height to place on ground
                let groundY = userDeviceHeight > 0 ? -userDeviceHeight : -1.0
                return simd_float3(transformed.x, groundY, transformed.y)
            }
            
            // Fallback: Place in front of camera on ground plane
            let cameraTransform = frame.camera.transform
            let cameraPosition = simd_float3(
                cameraTransform.columns.3.x,
                cameraTransform.columns.3.y,
                cameraTransform.columns.3.z
            )
            
            // Forward vector (negative Z in camera space)
            let forward = simd_float3(
                -cameraTransform.columns.2.x,
                -cameraTransform.columns.2.y,
                -cameraTransform.columns.2.z
            )
            
            // Place 1 meter in front of camera, on ground plane
            let estimatedPosition = cameraPosition + forward * 1.0
            let groundY = userDeviceHeight > 0 ? -userDeviceHeight : -1.0
            return simd_float3(estimatedPosition.x, groundY, estimatedPosition.z)
            */ // END OLD LOGIC
        }
        
        // MARK: - DEPRECATED
        /// DO NOT USE - Calls deprecated estimateWorldPosition().
        /// Use plantGhostMarkers(calibratedTriangle:, triangleStore:, filter:) instead.
        func addGhostMarker(mapPointID: UUID, mapPoint: CGPoint, using triangle: TrianglePatch?) {
            print("⚠️ [DEPRECATED] Function \(#function) was called. Refactor needed.")
            if let symbol = Thread.callStackSymbols.dropFirst(1).first {
                print("🔍 Called by: \(symbol)")
            }
            return
            
            /* OLD LOGIC COMMENTED OUT
            guard let sceneView = sceneView else { return }
            
            // Don't add if already has a real marker
            if placedMarkers.values.contains(where: { $0.name?.contains(mapPointID.uuidString) ?? false }) {
                return
            }
            
            // Don't add if already has a ghost marker
            if ghostMarkers[mapPointID] != nil {
                return
            }
            
            guard let estimatedPosition = estimateWorldPosition(for: mapPoint, using: triangle) else {
                print("⚠️ Could not estimate world position for ghost marker")
                return
            }
            
            let ghostMarkerID = UUID()
            let options = MarkerOptions(
                color: UIColor.systemGray.withAlphaComponent(0.6),
                markerID: ghostMarkerID,
                userDeviceHeight: userDeviceHeight,
                radius: 0.025,  // Slightly smaller than regular markers
                animateOnAppearance: false,
                isGhost: true
            )
            
            let ghostNode = ARMarkerRenderer.createNode(at: estimatedPosition, options: options)
            ghostNode.name = "ghostMarker_\(mapPointID.uuidString)"
            
            sceneView.scene.rootNode.addChildNode(ghostNode)
            ghostMarkers[mapPointID] = ghostNode
            
            print("👻 Planted ghost marker for MapPoint \(String(mapPointID.uuidString.prefix(8))) at \(estimatedPosition)")
            */ // END OLD LOGIC
        }
        
        func teardownSession() {
            crosshairUpdateTimer?.invalidate()
            crosshairUpdateTimer = nil
            NotificationCenter.default.removeObserver(self)
            sceneView?.session.pause()
            print("🔧 AR session paused and torn down.")
        }
        
        // MARK: - Survey Marker Generation
        
        // MARK: - Region-Based Survey Marker Generation
        /// Generate survey markers for a SurveyableRegion (single triangle or multi-triangle Swath)
        /// This is the core implementation; single-triangle calls are routed through here.
        private func generateSurveyMarkersForRegion(
            _ region: SurveyableRegion,
            spacing: Float,
            arWorldMapStore: ARWorldMapStore
        ) {
            guard let mapPointStore = mapPointStore else {
                print("⚠️ [REGION_SURVEY] MapPointStore not available")
                return
            }
            
            print("🔍 [REGION_SURVEY] Processing region with \(region.triangleCount) triangle(s)")
            print("   Unique vertices: \(region.allVertexIDs.count)")
            print("   Current session ID: \(arWorldMapStore.currentSessionID)")
            
            // STEP 1: Validate all vertices have positions
            var vertexPositions3D: [UUID: simd_float3] = [:]
            var validationFailures: [UUID] = []
            
            for vertexID in region.allVertexIDs {
                // Priority 1: Session position (confirmed marker placed this session)
                if let coordinator = self.arCalibrationCoordinator,
                   let sessionPos = coordinator.mapPointARPositions[vertexID] {
                    vertexPositions3D[vertexID] = sessionPos
                    print("📍 [REGION_SURVEY] Vertex \(String(vertexID.uuidString.prefix(8))): session position")
                    continue
                }
                
                // Priority 2: Ghost position (predicted position from session-level transform)
                if let ghostPos = ghostMarkerPositions[vertexID] {
                    vertexPositions3D[vertexID] = ghostPos
                    print("👻 [REGION_SURVEY] Vertex \(String(vertexID.uuidString.prefix(8))): ghost position")
                    continue
                }
                
                // Priority 3: Baked position (historical consensus projected to session)
                if let mapPoint = mapPointStore.points.first(where: { $0.id == vertexID }),
                   let bakedPos = mapPoint.canonicalPosition,
                   let sessionPos = arCalibrationCoordinator?.projectBakedToSession(bakedPos) {
                    vertexPositions3D[vertexID] = sessionPos
                    print("🧱 [REGION_SURVEY] Vertex \(String(vertexID.uuidString.prefix(8))): baked position")
                    continue
                }
                
                // No position available
                validationFailures.append(vertexID)
                print("❌ [REGION_SURVEY] Vertex \(String(vertexID.uuidString.prefix(8))): NO POSITION")
            }
            
            // Check validation
            if !validationFailures.isEmpty {
                print("❌ [REGION_SURVEY] Validation failed: \(validationFailures.count) vertices without positions")
                arCalibrationCoordinator?.exitSurveyMode()
                return
            }
            
            let sessionCount = vertexPositions3D.filter { arCalibrationCoordinator?.mapPointARPositions[$0.key] != nil }.count
            let ghostCount = vertexPositions3D.filter { arCalibrationCoordinator?.mapPointARPositions[$0.key] == nil && ghostMarkerPositions[$0.key] != nil }.count
            let bakedCount = vertexPositions3D.count - sessionCount - ghostCount
            print("✅ [REGION_SURVEY] All \(region.allVertexIDs.count) vertices validated")
            print("   Sources: \(sessionCount) session, \(ghostCount) ghost, \(bakedCount) baked")
            
            // STEP 2: Build triangle vertex lookup (pixels)
            var triangleVertices_px: [UUID: [CGPoint]] = [:]
            var triangleVertices_3D: [UUID: [simd_float3]] = [:]
            
            for triangle in region.triangles {
                var verts_px: [CGPoint] = []
                var verts_3D: [simd_float3] = []
                
                for vid in triangle.vertexIDs {
                    if let mp = mapPointStore.points.first(where: { $0.id == vid }) {
                        verts_px.append(mp.mapPoint)
                    }
                    if let pos = vertexPositions3D[vid] {
                        verts_3D.append(pos)
                    }
                }
                
                if verts_px.count == 3 && verts_3D.count == 3 {
                    triangleVertices_px[triangle.id] = verts_px
                    triangleVertices_3D[triangle.id] = verts_3D
                } else {
                    print("⚠️ [REGION_SURVEY] Triangle \(triangle.id) incomplete vertices")
                }
            }
            
            // STEP 3: Get pixels per meter
            guard let pxPerMeter = getPixelsPerMeter() else {
                print("⚠️ [REGION_SURVEY] No map scale available")
                return
            }
            
            // STEP 4: Collect existing marker positions for distance-based deduplication
            var existingMarkerPositions_m: [CGPoint] = []
            for (_, marker) in surveyMarkers {
                if let mapCoord = marker.mapCoordinate {
                    // Convert from pixels to meters
                    let pos_m = CGPoint(
                        x: mapCoord.x / CGFloat(pxPerMeter),
                        y: mapCoord.y / CGFloat(pxPerMeter)
                    )
                    existingMarkerPositions_m.append(pos_m)
                }
            }
            
            if !existingMarkerPositions_m.isEmpty {
                print("📍 [REGION_SURVEY] Found \(existingMarkerPositions_m.count) existing markers for distance filtering")
            }
            
            // STEP 5: Generate fill points for entire region (with distance-based deduplication)
            let fillPoints = generateFillPointsForRegion(
                region: region,
                spacingMeters: spacing,
                pxPerMeter: pxPerMeter,
                triangleVertices: triangleVertices_px,
                existingMarkerPositions_m: existingMarkerPositions_m
            )
            
            print("📍 [REGION_SURVEY] Generated \(fillPoints.count) survey points at \(spacing)m spacing")
            
            // STEP 6: Interpolate and place markers
            var placedCount = 0
            
            for fillPoint in fillPoints {
                guard let tri_px = triangleVertices_px[fillPoint.containingTriangleID],
                      let tri_3D = triangleVertices_3D[fillPoint.containingTriangleID] else {
                    print("⚠️ [REGION_SURVEY] Missing triangle data for \(fillPoint.coordinateKey)")
                    continue
                }
                
                guard let position3D = interpolateARPosition(
                    fromMapPoint: fillPoint.mapPosition_px,
                    triangle2D: tri_px,
                    triangle3D: tri_3D
                ) else {
                    print("⚠️ [REGION_SURVEY] Could not interpolate \(fillPoint.coordinateKey)")
                    continue
                }
                
                // Use average ground Y from containing triangle
                let groundY = (tri_3D[0].y + tri_3D[1].y + tri_3D[2].y) / 3.0
                let groundPosition = simd_float3(position3D.x, groundY, position3D.z)
                
                // Place marker using the actual fill point's map position
                if placeSurveyMarkerOnly(at: groundPosition, mapCoordinate: fillPoint.mapPosition_px, triangleID: fillPoint.containingTriangleID) != nil {
                    placedCount += 1
                }
            }
            
            print("✅ [REGION_SURVEY] Placed \(placedCount) survey markers")
        }
        
        /// Generate survey markers inside a calibrated triangle
        /// This is a convenience wrapper around generateSurveyMarkersForRegion
        private func generateSurveyMarkers(for triangle: TrianglePatch, spacing: Float, arWorldMapStore: ARWorldMapStore) {
            print("🔍 [SURVEY] Single triangle mode - routing to region generator")
            let region = SurveyableRegion.single(triangle)
            generateSurveyMarkersForRegion(region, spacing: spacing, arWorldMapStore: arWorldMapStore)
        }
        
        /// Clear all survey markers from scene
        /// Clear all survey markers from scene
        func clearSurveyMarkers() {
            for (_, marker) in surveyMarkers {
                marker.removeFromScene()
            }
            surveyMarkers.removeAll()
            triggeredSurveyMarkers.removeAll()
            print("🧹 Cleared survey markers")
        }
        
        /// Clear survey markers for a specific triangle only
        /// Markers on shared edges with adjacent filled triangles are reassigned, not removed
        func clearSurveyMarkersForTriangle(_ triangleID: UUID) {
            // Get map scale for distance calculations
            guard let pxPerMeter = getPixelsPerMeter() else {
                // Fallback: remove all markers for this triangle without edge detection
                print("⚠️ [CLEAR_TRIANGLE] No map scale available, removing all markers without edge detection")
                var removedCount = 0
                for (markerID, marker) in surveyMarkers {
                    if marker.triangleID == triangleID {
                        marker.removeFromScene()
                        surveyMarkers.removeValue(forKey: markerID)
                        triggeredSurveyMarkers.remove(markerID)
                        removedCount += 1
                    }
                }
                print("🧹 Cleared \(removedCount) survey marker(s) from triangle \(String(triangleID.uuidString.prefix(8)))")
                return
            }
            
            // Minimum separation in pixels (0.8m * pxPerMeter)
            let minSeparationPx = CGFloat(0.3 * pxPerMeter)
            
            // Collect markers from OTHER triangles (potential neighbors)
            var otherTriangleMarkers: [(triangleID: UUID, position: CGPoint)] = []
            for (_, marker) in surveyMarkers {
                if let otherTriangleID = marker.triangleID,
                   otherTriangleID != triangleID,
                   let pos = marker.mapCoordinate {
                    otherTriangleMarkers.append((otherTriangleID, pos))
                }
            }
            
            var removedCount = 0
            var reassignedCount = 0
            var markersToRemove: [UUID] = []
            
            for (markerID, marker) in surveyMarkers {
                if marker.triangleID == triangleID {
                    // Check if this marker is on a shared edge with another filled triangle
                    var nearestAdjacentTriangleID: UUID? = nil
                    var nearestDistance: CGFloat = .greatestFiniteMagnitude
                    
                    if let markerPos = marker.mapCoordinate {
                        for (otherTriangleID, otherPos) in otherTriangleMarkers {
                            let dx = markerPos.x - otherPos.x
                            let dy = markerPos.y - otherPos.y
                            let distance = sqrt(dx * dx + dy * dy)
                            
                            if distance < minSeparationPx && distance < nearestDistance {
                                nearestDistance = distance
                                nearestAdjacentTriangleID = otherTriangleID
                            }
                        }
                    }
                    
                    if let adjacentTriangleID = nearestAdjacentTriangleID {
                        // Reassign to adjacent triangle instead of removing
                        marker.triangleID = adjacentTriangleID
                        reassignedCount += 1
                        print("🔄 [CLEAR_TRIANGLE] Reassigned marker to adjacent triangle \(String(adjacentTriangleID.uuidString.prefix(8)))")
                    } else {
                        // No adjacent triangle - safe to remove
                        marker.removeFromScene()
                        markersToRemove.append(markerID)
                        triggeredSurveyMarkers.remove(markerID)
                        removedCount += 1
                    }
                }
            }
            
            for markerID in markersToRemove {
                surveyMarkers.removeValue(forKey: markerID)
            }
            
            print("🧹 [CLEAR_TRIANGLE] Triangle \(String(triangleID.uuidString.prefix(8))): removed \(removedCount), reassigned \(reassignedCount) edge marker(s)")
        }
        
        /// Places a survey marker WITHOUT calling registerMarker (no photo, no MapPoint updates)
        func placeSurveyMarkerOnly(at position: simd_float3, mapCoordinate: CGPoint, triangleID: UUID? = nil) -> UUID? {
            guard let sceneView = sceneView else {
                print("⚠️ ARView not available for survey marker placement")
                return nil
            }
            
            // Create survey marker using consolidated class
            let marker = SurveyMarker(
                at: position,
                userDeviceHeight: userDeviceHeight,
                mapCoordinate: mapCoordinate,
                triangleID: triangleID,
                animated: false
            )
            
            sceneView.scene.rootNode.addChildNode(marker.node)
            surveyMarkers[marker.id] = marker
            
            print("📍 Placed survey marker at map(\(String(format: "%.1f, %.1f", mapCoordinate.x, mapCoordinate.y))) → AR\(String(format: "(%.2f, %.2f, %.2f)", position.x, position.y, position.z))")
            
            return marker.id
        }
        
        /// Clear all calibration AR markers from scene
        func clearCalibrationMarkers() {
            guard let sceneView = sceneView else { return }
            
            // Remove all calibration markers (orange markers used during triangle calibration)
            var markersToRemove: [UUID] = []
            for (markerID, node) in placedMarkers {
                // Check if this is a calibration marker by checking its color
                if let sphereNode = node.childNode(withName: "arMarkerSphere_\(markerID.uuidString)", recursively: true),
                   let sphere = sphereNode.geometry as? SCNSphere,
                   let material = sphere.firstMaterial,
                   let color = material.diffuse.contents as? UIColor {
                    // Check if it's calibration orange color (ARPalette.calibration)
                    if color == UIColor.ARPalette.calibration {
                        node.removeFromParentNode()
                        markersToRemove.append(markerID)
                    }
                }
            }
            
            // Remove from dictionary
            for markerID in markersToRemove {
                placedMarkers.removeValue(forKey: markerID)
            }
            
            if !markersToRemove.isEmpty {
                print("🧹 Cleared \(markersToRemove.count) calibration marker(s) from scene")
            }
        }
        
        /// Draw yellow lines connecting triangle vertices
        func drawTriangleLines(triangleID: UUID) {
            guard let sceneView = sceneView else { return }
            
            // Remove existing triangle lines
            sceneView.scene.rootNode.enumerateChildNodes { node, _ in
                if node.name?.hasPrefix("triangleLine_") == true {
                    node.removeFromParentNode()
                }
            }
            
            // Get triangle from selectedTriangle or use triangleID to look it up
            // We'll use the selectedTriangle if it matches, otherwise we need to access via coordinator
            guard let triangle = selectedTriangle, triangle.id == triangleID else {
                print("⚠️ Triangle \(String(triangleID.uuidString.prefix(8))) not found in selectedTriangle")
                return
            }
            
            // Get AR marker positions
            guard triangle.arMarkerIDs.count == 3 else {
                print("⚠️ Triangle doesn't have 3 AR markers yet")
                return
            }
            
            var vertices: [simd_float3] = []
            for markerIDString in triangle.arMarkerIDs {
                guard let markerUUID = UUID(uuidString: markerIDString),
                      let markerNode = placedMarkers[markerUUID] else {
                    print("⚠️ Could not find marker node for \(markerIDString)")
                    return
                }
                vertices.append(markerNode.simdPosition)
            }
            
            guard vertices.count == 3 else { return }
            
            // Create lines for each edge
            let edges = [
                (vertices[0], vertices[1], "triangleLine_01"),
                (vertices[1], vertices[2], "triangleLine_12"),
                (vertices[2], vertices[0], "triangleLine_20")
            ]
            
            for (start, end, name) in edges {
                let vector = end - start
                let distance = simd_length(vector)
                
                let cylinder = SCNCylinder(radius: 0.01, height: CGFloat(distance))
                cylinder.firstMaterial?.diffuse.contents = UIColor.yellow.withAlphaComponent(0.8)
                
                let lineNode = SCNNode(geometry: cylinder)
                lineNode.name = name
                
                // Position and orient
                let midpoint = (start + end) / 2
                lineNode.simdPosition = midpoint
                
                // Orient cylinder along edge
                let direction = simd_normalize(vector)
                let defaultUp = simd_float3(0, 1, 0)
                
                let angle = acos(simd_dot(defaultUp, direction))
                let axis = simd_cross(defaultUp, direction)
                
                if simd_length(axis) > 0.001 {
                    lineNode.simdOrientation = simd_quatf(angle: angle, axis: simd_normalize(axis))
                }
                
                sceneView.scene.rootNode.addChildNode(lineNode)
            }
            
            print("📐 Drew triangle lines connecting 3 vertices")
        }
        
        /// Updates inner sphere orientation for the survey marker the user is currently inside
        /// Orients the pole toward the camera so the orange equator band appears at the periphery
        func updateActiveInnerSphereOrientation() {
            guard let markerID = currentlyInsideSurveyMarkerID,
                  let surveyMarker = surveyMarkers[markerID],
                  let sceneView = sceneView,
                  let frame = sceneView.session.currentFrame else { return }
            
            let innerSphereName = "arMarkerInnerSphere_\(markerID.uuidString)"
            guard let innerSphereNode = surveyMarker.node.childNode(withName: innerSphereName, recursively: false) else {
                return
            }
            
            let cameraPosition = simd_float3(
                frame.camera.transform.columns.3.x,
                frame.camera.transform.columns.3.y,
                frame.camera.transform.columns.3.z
            )
            
            let sphereWorldPos = innerSphereNode.simdWorldPosition
            let toCamera = cameraPosition - sphereWorldPos
            let distance = simd_length(toCamera)
            
            guard distance > 0.001 else { return }
            
            let direction = simd_normalize(toCamera)
            let defaultPole = simd_float3(0, 1, 0)
            let rotation = simd_quatf(from: defaultPole, to: direction)
            
            innerSphereNode.simdOrientation = rotation
        }
        
        /// Check for camera collisions with survey markers
        private func checkSurveyMarkerCollisions() {
            let collisionStart = CACurrentMediaTime()
            
            guard let sceneView = sceneView,
                  let frame = sceneView.session.currentFrame else { return }
            
            // Get camera position from transform matrix (translation component)
            let cameraTransform = frame.camera.transform
            let cameraPosition = simd_float3(
                cameraTransform.columns.3.x,
                cameraTransform.columns.3.y,
                cameraTransform.columns.3.z
            )
            
            // Use config constants
            let sphereRadius = SurveyMarkerConfig.sphereRadius
            let deadZoneRadius = SurveyMarkerConfig.deadZoneRadius
            
            // OPTIMIZATION: If inside a sphere, only check that one marker for exit detection
            // Otherwise, filter to markers within 2m radius for entry detection
            let proximityRadius: Float = 0.6
            let markersToCheck: [(UUID, SurveyMarker)]
            if let insideMarkerID = currentlyInsideSurveyMarkerID,
               let insideMarker = surveyMarkers[insideMarkerID] {
                // Inside a sphere - only check this one marker
                markersToCheck = [(insideMarkerID, insideMarker)]
            } else {
                // Outside all spheres - check only nearby markers (within 2m)
                markersToCheck = surveyMarkers.compactMap { (markerID, marker) in
                    let distance = simd_distance(cameraPosition, marker.sphereCenter)
                    return distance <= proximityRadius ? (markerID, marker) : nil
                }
            }
            
            for (markerID, marker) in markersToCheck {
                // Use marker's computed sphere center
                let sphereCenterPosition = marker.sphereCenter
                
                let distance = simd_distance(cameraPosition, sphereCenterPosition)
                let wasInside = triggeredSurveyMarkers.contains(markerID)
                let isInside = distance < sphereRadius
                
                if isInside && !wasInside {
                    // ENTERED sphere - knock + start buzz
                    triggeredSurveyMarkers.insert(markerID)
                    
                    bluetoothScanner?.startContinuous()
                    
                    // Calculate initial intensity for buzz
                    let initialIntensity: Float
                    if distance < deadZoneRadius {
                        initialIntensity = 0.0
                    } else {
                        initialIntensity = (distance - deadZoneRadius) / (sphereRadius - deadZoneRadius)
                    }
                    
                    let timestamp = String(format: "%.3f", Date().timeIntervalSince1970.truncatingRemainder(dividingBy: 1000))
                    print("💥 [SURVEY_COLLISION] ENTERED marker \(String(markerID.uuidString.prefix(8))) at distance \(String(format: "%.3f", distance))m, intensity \(String(format: "%.2f", initialIntensity)) [t=\(timestamp)]")
                    
                    currentlyInsideSurveyMarkerID = markerID
                    
                    // Orient inner sphere toward camera once at entry (frozen during dwell)
                    updateActiveInnerSphereOrientation()
                    
                    NotificationCenter.default.post(
                        name: NSNotification.Name("SurveyMarkerEntered"),
                        object: nil,
                        userInfo: [
                            "markerID": markerID,
                            "distance": distance,
                            "radius": sphereRadius,
                            "intensity": initialIntensity,
                            "mapCoordinate": marker.mapCoordinate as Any
                        ]
                    )
                } else if !isInside && wasInside {
                    // EXITED sphere - knock + stop buzz
                    triggeredSurveyMarkers.remove(markerID)
                    let exitTimestamp = String(format: "%.3f", Date().timeIntervalSince1970.truncatingRemainder(dividingBy: 1000))
                    print("💥 [SURVEY_COLLISION] EXITED marker \(String(markerID.uuidString.prefix(8))) [t=\(exitTimestamp)]")
                    
                    bluetoothScanner?.stopContinuous()
                    
                    if currentlyInsideSurveyMarkerID == markerID {
                        currentlyInsideSurveyMarkerID = nil
                    }
                    
                    NotificationCenter.default.post(
                        name: NSNotification.Name("SurveyMarkerExited"),
                        object: nil,
                        userInfo: [
                            "markerID": markerID,
                            "mapCoordinate": marker.mapCoordinate as Any
                        ]
                    )
                } else if isInside {
                    // INSIDE sphere - update buzz intensity based on distance
                    // Dead zone at center: intensity = 0 within deadZoneRadius
                    // Then ramps from 0 to 1.0 as distance approaches edge
                    let intensity: Float
                    if distance < deadZoneRadius {
                        intensity = 0.0  // Silent dead zone
                    } else {
                        // Remap: deadZone edge → 0, sphere edge → 1.0
                        intensity = (distance - deadZoneRadius) / (sphereRadius - deadZoneRadius)
                    }
                    
                    NotificationCenter.default.post(
                        name: NSNotification.Name("SurveyMarkerProximity"),
                        object: nil,
                        userInfo: ["markerID": markerID, "distance": distance, "intensity": intensity]
                    )
                }
            }
            
            let collisionDuration = (CACurrentMediaTime() - collisionStart) * 1000
            if collisionDuration > 2.0 {
                print("⚠️ [PERF] Collision detection took \(String(format: "%.1f", collisionDuration))ms")
            }
        }
        
        /// Draw lines connecting triangle vertices on the ground
        func drawTriangleLines(vertices: [simd_float3]) {
            guard vertices.count == 3 else { return }
            
            // Remove any existing triangle lines
            sceneView?.scene.rootNode.enumerateChildNodes { node, _ in
                if node.name?.hasPrefix("triangleLine_") == true {
                    node.removeFromParentNode()
                }
            }
            
            // Create lines for each edge
            let edges = [
                (vertices[0], vertices[1], "triangleLine_01"),
                (vertices[1], vertices[2], "triangleLine_12"),
                (vertices[2], vertices[0], "triangleLine_20")
            ]
            
            for (start, end, name) in edges {
                // Create cylinder to represent line
                let vector = end - start
                let distance = simd_length(vector)
                
                let cylinder = SCNCylinder(radius: 0.005, height: CGFloat(distance))
                cylinder.firstMaterial?.diffuse.contents = UIColor.yellow.withAlphaComponent(0.7)
                
                let lineNode = SCNNode(geometry: cylinder)
                lineNode.name = name
                
                // Position at midpoint
                let midpoint = (start + end) / 2
                lineNode.simdPosition = midpoint
                
                // Orient cylinder along the edge (cylinder default axis is Y, we want it along the edge)
                let direction = simd_normalize(vector)
                let up = simd_float3(0, 1, 0) // Default cylinder axis
                
                // Calculate rotation to align Y-axis with edge direction
                let rotation = rotationBetweenVectors(from: up, to: direction)
                lineNode.simdOrientation = rotation
                
                // Lower the line slightly below ground level for visibility
                lineNode.simdPosition.y = midpoint.y - 0.01
                
                sceneView?.scene.rootNode.addChildNode(lineNode)
            }
            
            print("📐 Drew triangle lines connecting vertices")
        }
        
        /// Helper: Calculate rotation between two vectors
        private func rotationBetweenVectors(from: simd_float3, to: simd_float3) -> simd_quatf {
            let normalizedFrom = simd_normalize(from)
            let normalizedTo = simd_normalize(to)
            
            let dot = simd_dot(normalizedFrom, normalizedTo)
            let clampedDot = max(-1.0, min(1.0, dot)) // Clamp to avoid NaN from acos
            
            // If vectors are parallel or anti-parallel
            if abs(clampedDot - 1.0) < 0.001 {
                return simd_quatf(angle: 0, axis: simd_float3(0, 1, 0))
            }
            
            let axis = simd_cross(normalizedFrom, normalizedTo)
            let axisLength = simd_length(axis)
            
            if axisLength < 0.001 {
                // Vectors are parallel
                return simd_quatf(angle: 0, axis: simd_float3(0, 1, 0))
            }
            
            let angle = acos(clampedDot)
            return simd_quatf(angle: angle, axis: simd_normalize(axis))
        }
        
        /// Get pixels per meter from MetricSquareStore (same logic as ARCalibrationCoordinator)
        private func getPixelsPerMeter() -> Float? {
            guard let squareStore = metricSquareStore else { return nil }
            
            // Use first locked square, or any square if none are locked
            let lockedSquares = squareStore.squares.filter { $0.isLocked }
            let squaresToUse = lockedSquares.isEmpty ? squareStore.squares : lockedSquares
            
            guard let square = squaresToUse.first, square.meters > 0 else { return nil }
            
            // pixels per meter = side_pixels / side_meters
            let pixelsPerMeter = Float(square.side) / Float(square.meters)
            if pixelsPerMeter > 0 {
                print("📏 Map scale set: \(pixelsPerMeter) pixels per meter (1 meter = \(pixelsPerMeter) pixels)")
            }
            return pixelsPerMeter > 0 ? pixelsPerMeter : nil
        }

        deinit {
            clearSurveyMarkers()
            crosshairUpdateTimer?.invalidate()
            NotificationCenter.default.removeObserver(self)
        }
    }
}

// MARK: - ARSCNViewDelegate for Plane Visualization
extension ARViewContainer.ARViewCoordinator: ARSCNViewDelegate {
    
    // MARK: - Ghost Proximity Selection (per-frame updates)
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        let frameStart = CACurrentMediaTime()
        var insideSphereWork = false
        
        // Frame timing diagnostic
        let currentTime = time
        if lastFrameTime > 0 {
            let frameDelta = currentTime - lastFrameTime
            if frameDelta > frameDropThreshold {
                let timestamp = String(format: "%.3f", Date().timeIntervalSince(sessionStartTime))
                print("🎥 [ARKIT] [\(timestamp)s] 🐌 FRAME GAP DETECTED: \(String(format: "%.2f", frameDelta))s (threshold: \(frameDropThreshold)s)")
            }
        }
        lastFrameTime = currentTime
        
        // DISABLED: Origin reset heuristic fires too frequently near origin - needs improvement
        // World origin monitoring (detect coordinate frame resets)
        // if let frame = sceneView?.session.currentFrame {
        //     let cameraPos = frame.camera.transform.columns.3
        //     let distanceFromOrigin = sqrt(cameraPos.x * cameraPos.x + cameraPos.z * cameraPos.z)
        //     let elapsedTime = Date().timeIntervalSince(sessionStartTime)
        //     
        //     // If camera suddenly appears very close to origin after being far away, origin may have reset
        //     // This is a heuristic - adjust threshold based on your space
        //     if distanceFromOrigin < 0.5 && elapsedTime > 5.0 {
        //         // Only log this once per potential reset (use a flag if needed)
        //         let timestamp = String(format: "%.3f", elapsedTime)
        //         print("🎥 [ARKIT] [\(timestamp)s] 🔄 POSSIBLE ORIGIN RESET: Camera at (\(String(format: "%.2f", cameraPos.x)), \(String(format: "%.2f", cameraPos.z))) - very close to origin after \(String(format: "%.1f", elapsedTime))s")
        //     }
        // }
        
        // MARK: - Ghost Proximity Selection
        // OPTIMIZATION: Skip ghost proximity entirely when inside a survey sphere
        if currentlyInsideSurveyMarkerID != nil {
            // Inside survey sphere - no need to check ghosts
            return
        }
        
        // Early exit if no ghosts to check
        if ghostMarkerPositions.isEmpty {
            return
        }
        
        guard let sceneView = sceneView,
              let cameraTransform = sceneView.session.currentFrame?.camera.transform else {
            return
        }
        
        let cameraPosition = simd_float3(
            cameraTransform.columns.3.x,
            cameraTransform.columns.3.y,
            cameraTransform.columns.3.z
        )
        
        // OPTIMIZATION: Skip ghost proximity if camera is >3m from all ghosts
        let ghostProximityThreshold: Float = 3.0
        if let nearestDistance = distanceToNearestGhost(from: cameraPosition),
           nearestDistance > ghostProximityThreshold {
            // Too far from any ghost - skip proximity check
            return
        }
        
        let ghostStart = CACurrentMediaTime()
        
        // Calculate which ghosts are visible in camera view
        var visibleGhostIDs = Set<UUID>()
        for (ghostID, ghostPosition) in ghostMarkerPositions {
            if isPositionInCameraView(ghostPosition) {
                visibleGhostIDs.insert(ghostID)
            }
        }
        
        // Update ghost selection on main thread (touches @Published properties)
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let coordinator = self.arCalibrationCoordinator else { return }
            coordinator.updateGhostSelection(
                cameraPosition: cameraPosition,
                ghostPositions: self.ghostMarkerPositions,
                visibleGhostIDs: visibleGhostIDs
            )
        }
        
        let ghostDuration = (CACurrentMediaTime() - ghostStart) * 1000
        if ghostDuration > 2.0 {
            print("⚠️ [PERF] Ghost proximity took \(String(format: "%.1f", ghostDuration))ms")
        }
        
        if currentlyInsideSurveyMarkerID != nil {
            let frameDuration = (CACurrentMediaTime() - frameStart) * 1000
            if frameDuration > 16.0 { // Flag frames taking longer than 16ms (60fps budget)
                print("⚠️ [PERF] Frame took \(String(format: "%.1f", frameDuration))ms while inside sphere")
            }
        }
    }
    
    // MARK: - Plane Visualization
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard showPlaneVisualization else { return }
        
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        let plane = SCNPlane(
            width: CGFloat(planeAnchor.planeExtent.width),
            height: CGFloat(planeAnchor.planeExtent.height)
        )
        
        let material = SCNMaterial()
        // Purple for horizontal, Green for vertical
        if planeAnchor.alignment == .horizontal {
            material.diffuse.contents = UIColor.purple.withAlphaComponent(0.3)
        } else {
            material.diffuse.contents = UIColor.green.withAlphaComponent(0.3)
        }
        material.isDoubleSided = true
        plane.materials = [material]
        
        let planeNode = SCNNode(geometry: plane)
        
        // Position and rotate based on plane alignment
        if planeAnchor.alignment == .horizontal {
            // Horizontal planes: position at ground level (y=0), rotate to lie flat
            planeNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
            planeNode.eulerAngles.x = -.pi / 2
        } else {
            // Vertical planes: use actual center position, no rotation needed
            planeNode.position = SCNVector3(planeAnchor.center.x, planeAnchor.center.y, planeAnchor.center.z)
            planeNode.eulerAngles.x = -.pi / 2
        }
        
        planeNode.name = "planeVisualization"  // Tag for easy removal
        
        node.addChildNode(planeNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard showPlaneVisualization else {
            // Remove plane visualization if toggle is off
            node.childNodes.first(where: { $0.name == "planeVisualization" })?.removeFromParentNode()
            return
        }
        
        guard let planeAnchor = anchor as? ARPlaneAnchor,
              let planeNode = node.childNodes.first(where: { $0.name == "planeVisualization" }),
              let plane = planeNode.geometry as? SCNPlane else { return }
        
        plane.width = CGFloat(planeAnchor.planeExtent.width)
        plane.height = CGFloat(planeAnchor.planeExtent.height)
        
        // Update position based on plane alignment
        if planeAnchor.alignment == .horizontal {
            planeNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
        } else {
            planeNode.position = SCNVector3(planeAnchor.center.x, planeAnchor.center.y, planeAnchor.center.z)
        }
    }
}

// MARK: - ARSessionDelegate for Tracking State Diagnostics
extension ARViewContainer.ARViewCoordinator: ARSessionDelegate {
    
    // MARK: - ARSession Tracking State Logging
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        let timestamp = String(format: "%.3f", Date().timeIntervalSince(sessionStartTime))
        
        switch camera.trackingState {
        case .notAvailable:
            print("🎥 [ARKIT] [\(timestamp)s] ❌ Tracking NOT AVAILABLE")
            
        case .limited(let reason):
            let reasonString: String
            switch reason {
            case .initializing:
                reasonString = "INITIALIZING"
            case .excessiveMotion:
                reasonString = "EXCESSIVE MOTION"
            case .insufficientFeatures:
                reasonString = "INSUFFICIENT FEATURES"
            case .relocalizing:
                reasonString = "⚠️ RELOCALIZING (world map matching)"
            @unknown default:
                reasonString = "UNKNOWN REASON"
            }
            print("🎥 [ARKIT] [\(timestamp)s] ⚠️ Tracking LIMITED: \(reasonString)")
            
        case .normal:
            print("🎥 [ARKIT] [\(timestamp)s] ✅ Tracking NORMAL")
        }
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        let timestamp = String(format: "%.3f", Date().timeIntervalSince(sessionStartTime))
        print("🎥 [ARKIT] [\(timestamp)s] 🛑 SESSION INTERRUPTED")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        let timestamp = String(format: "%.3f", Date().timeIntervalSince(sessionStartTime))
        print("🎥 [ARKIT] [\(timestamp)s] ▶️ SESSION INTERRUPTION ENDED")
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        let timestamp = String(format: "%.3f", Date().timeIntervalSince(sessionStartTime))
        print("🎥 [ARKIT] [\(timestamp)s] 💥 SESSION FAILED: \(error.localizedDescription)")
        
        if let arError = error as? ARError {
            print("🎥 [ARKIT] [\(timestamp)s]    Error code: \(arError.code.rawValue)")
            print("🎥 [ARKIT] [\(timestamp)s]    Error domain: \(arError.errorCode)")
        }
    }
}
