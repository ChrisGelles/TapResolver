import SwiftUI
import ARKit
import SceneKit
import simd
import CoreImage

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
        var surveyMarkers: [UUID: SCNNode] = [:]  // markerID -> node
        weak var metricSquareStore: MetricSquareStore?
        weak var mapPointStore: MapPointStore?
        /// Reference to calibration coordinator for ghost selection updates
        weak var arCalibrationCoordinator: ARCalibrationCoordinator?
        private var crosshairNode: GroundCrosshairNode?
        var currentCursorPosition: simd_float3?
        
        // Calibration mode state
        var isCalibrationMode: Bool = false
        var selectedTriangle: TrianglePatch? = nil
        
        // Plane visualization toggle
        var showPlaneVisualization: Bool = true  // Default to enabled
        
        // User device height (centralized constant)
        var userDeviceHeight: Float = ARVisualDefaults.userDeviceHeight
        
        // Survey marker collision tracking
        private var lastHapticTriggerTime: [UUID: TimeInterval] = [:]  // Debounce haptics per marker
        private let hapticCooldown: TimeInterval = 0.5  // 500ms between haptics for same marker
        private let collisionRadius: Float = 0.03  // Match sphere radius from ARMarkerRenderer
        
        // Timer for updating crosshair
        private var crosshairUpdateTimer: Timer?

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
                           let bakedPos = mapPoint.bakedCanonicalPosition,
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
            
            guard let position = currentCursorPosition else {
                print("⚠️ [PLACE_MARKER_CROSSHAIR] No cursor position available")
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
            
            // Remove the ghost marker node from scene
            if let ghostNode = ghostMarkers[ghostMapPointID] {
                ghostNode.removeFromParentNode()
                ghostMarkers.removeValue(forKey: ghostMapPointID)
                ghostMarkerPositions.removeValue(forKey: ghostMapPointID)
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
            print("🔍 [TAP_TRACE] Tap detected")
            print("   Current mode: \(currentMode)")
            
            // Disable tap-to-place in idle mode - use Place AR Marker button instead
            guard currentMode != .idle else {
                print("👆 [TAP_TRACE] Tap ignored in idle mode — use Place AR Marker button")
                return
            }
            
            // Disable tap-to-place in triangle calibration mode - use Place Marker button instead
            if case .triangleCalibration = currentMode {
                print("👆 [TAP_TRACE] Tap ignored in triangle calibration mode — use Place Marker button")
                return
            }
            
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
            
            // Start updating crosshair position
            crosshairUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                self?.updateCrosshair()
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
                       let bakedPos = mapPoint.bakedCanonicalPosition,
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
            
            print("👻 Ghost marker notification listener registered")
            
            print("➕ Ground crosshair configured")
        }
        
        /// Check if a 3D position is visible in the camera's field of view
        /// - Parameters:
        ///   - position: The 3D world position to check
        ///   - margin: Screen margin in points (default 50) - positions near edges are considered not visible
        /// - Returns: true if the position projects to a point within the screen bounds
        func isPositionInCameraView(_ position: simd_float3, margin: CGFloat = 50) -> Bool {
            guard let sceneView = sceneView else { return false }
            
            let screenPoint = sceneView.projectPoint(SCNVector3(position))
            
            // Check if point is behind camera (z > 1.0 means behind)
            if screenPoint.z > 1.0 {
                return false
            }
            
            let screenBounds = sceneView.bounds
            let insetBounds = screenBounds.insetBy(dx: margin, dy: margin)
            let point2D = CGPoint(x: CGFloat(screenPoint.x), y: CGFloat(screenPoint.y))
            
            return insetBounds.contains(point2D)
        }
        
        func updateCrosshair() {
            guard let sceneView = sceneView,
                  let crosshair = crosshairNode else { return }
            
            let screenCenter = CGPoint(x: sceneView.bounds.midX, y: sceneView.bounds.midY)
            
            guard let query = sceneView.raycastQuery(from: screenCenter, allowing: .estimatedPlane, alignment: .horizontal) else {
                crosshair.hide()
                currentCursorPosition = nil
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
                
                crosshair.update(position: snappedPosition, snapped: isSnapped, confident: isConfident)
                currentCursorPosition = snappedPosition
                
                if isSnapped {
                    print("📍 Crosshair snapped to corner")
                }
            } else {
                crosshair.hide()
                currentCursorPosition = nil
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
            // Clear existing survey markers
            clearSurveyMarkers()
            
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
                   let bakedPos = mapPoint.bakedCanonicalPosition,
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
            
            // STEP 4: Generate fill points for entire region
            let fillPoints = generateFillPointsForRegion(
                region: region,
                spacingMeters: spacing,
                pxPerMeter: pxPerMeter,
                triangleVertices: triangleVertices_px
            )
            
            print("📍 [REGION_SURVEY] Generated \(fillPoints.count) survey points at \(spacing)m spacing")
            
            // STEP 5: Interpolate and place markers
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
                
                // Place marker - get a MapPoint from the containing triangle for logging
                if let containingTriangle = region.triangles.first(where: { $0.id == fillPoint.containingTriangleID }),
                   let firstVertexID = containingTriangle.vertexIDs.first,
                   let mapPoint = mapPointStore.points.first(where: { $0.id == firstVertexID }) {
                    if placeSurveyMarkerOnly(at: groundPosition, mapPoint: mapPoint) != nil {
                        placedCount += 1
                    }
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
        func clearSurveyMarkers() {
            for (_, node) in surveyMarkers {
                node.removeFromParentNode()
            }
            surveyMarkers.removeAll()
            lastHapticTriggerTime.removeAll()  // Clear collision tracking state
            print("🧹 Cleared survey markers")
        }
        
        /// Places a survey marker WITHOUT calling registerMarker (no photo, no MapPoint updates)
        func placeSurveyMarkerOnly(at position: simd_float3, mapPoint: MapPointStore.MapPoint) -> UUID? {
            guard let sceneView = sceneView else {
                print("⚠️ ARView not available for survey marker placement")
                return nil
            }
            
            let markerID = UUID()
            
            print("📍 Survey Marker placed at \(String(format: "(%.2f, %.2f, %.2f)", position.x, position.y, position.z))")
            
            // Create marker using centralized renderer with red color for survey
            let options = MarkerOptions(
                color: UIColor.red,
                markerID: markerID,
                userDeviceHeight: userDeviceHeight,
                radius: 0.035,  // Larger radius for survey markers
                animateOnAppearance: false
            )
            let markerNode = ARMarkerRenderer.createNode(at: position, options: options)
            markerNode.name = "surveyMarker_\(markerID.uuidString)"
            
            sceneView.scene.rootNode.addChildNode(markerNode)
            
            // Store in surveyMarkers, NOT in placedMarkers (to avoid MapPoint updates)
            surveyMarkers[markerID] = markerNode
            
            print("📍 Placed survey marker at map(\(String(format: "%.1f, %.1f", mapPoint.mapPoint.x, mapPoint.mapPoint.y))) → AR\(String(format: "(%.2f, %.2f, %.2f)", position.x, position.y, position.z))")
            
            return markerID
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
        
        /// Check for camera collisions with survey marker spheres
        private func checkSurveyMarkerCollisions() {
            guard !surveyMarkers.isEmpty else { return }
            
            // Get current camera position
            guard let cameraPosition = getCurrentCameraPosition() else { return }
            
            let currentTime = CACurrentMediaTime()
            
            // Check distance to each survey marker
            for (markerID, markerNode) in surveyMarkers {
                let markerPosition = markerNode.simdPosition
                let distance = simd_distance(cameraPosition, markerPosition)
                
                // Check if camera is inside sphere volume
                if distance < collisionRadius {
                    // Check cooldown
                    let lastTrigger = lastHapticTriggerTime[markerID] ?? 0
                    let timeSinceLastTrigger = currentTime - lastTrigger
                    
                    if timeSinceLastTrigger >= hapticCooldown {
                        // Trigger haptic feedback
                        triggerCollisionHaptic()
                        lastHapticTriggerTime[markerID] = currentTime
                        
                        print("💥 Camera collision with survey marker \(String(markerID.uuidString.prefix(8))) at distance \(String(format: "%.3f", distance))m")
                    }
                }
            }
        }
        
        /// Trigger haptic feedback for survey marker collision
        private func triggerCollisionHaptic() {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
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
            lastHapticTriggerTime.removeAll()
            crosshairUpdateTimer?.invalidate()
            NotificationCenter.default.removeObserver(self)
        }
    }
}

// MARK: - ARSCNViewDelegate for Plane Visualization
extension ARViewContainer.ARViewCoordinator: ARSCNViewDelegate {
    
    // MARK: - Ghost Proximity Selection (per-frame updates)
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // MARK: - Ghost Proximity Selection
        
        // Throttle logging to once per second to avoid spam
        let now = Date().timeIntervalSince1970
        let shouldLog = (Int(now) % 5 == 0) && (Int(now * 10) % 10 == 0)  // Log roughly every 5 seconds
        
        if ghostMarkerPositions.isEmpty {
            if shouldLog {
                print("👻 [GHOST_PROXIMITY] No ghost positions tracked (ghostMarkerPositions is empty)")
            }
            return
        }
        
        guard let sceneView = sceneView else {
            if shouldLog {
                print("👻 [GHOST_PROXIMITY] sceneView is nil")
            }
            return
        }
        
        guard let cameraTransform = sceneView.session.currentFrame?.camera.transform else {
            if shouldLog {
                print("👻 [GHOST_PROXIMITY] No camera transform available")
            }
            return
        }
        
        let cameraPosition = simd_float3(
            cameraTransform.columns.3.x,
            cameraTransform.columns.3.y,
            cameraTransform.columns.3.z
        )
        
        // Log ghost check status periodically
        if shouldLog {
            print("👻 [GHOST_PROXIMITY] Checking \(ghostMarkerPositions.count) ghost(s), camera at (\(String(format: "%.2f", cameraPosition.x)), \(String(format: "%.2f", cameraPosition.y)), \(String(format: "%.2f", cameraPosition.z)))")
            for (mapPointID, ghostPos) in ghostMarkerPositions {
                let horizontalDistance = simd_distance(
                    simd_float2(cameraPosition.x, cameraPosition.z),
                    simd_float2(ghostPos.x, ghostPos.z)
                )
                print("   Ghost \(String(mapPointID.uuidString.prefix(8))): \(String(format: "%.2f", horizontalDistance))m away (horizontal)")
            }
        }
        
        // Calculate which ghosts are visible in camera view
        var visibleGhostIDs = Set<UUID>()
        for (ghostID, ghostPosition) in ghostMarkerPositions {
            if isPositionInCameraView(ghostPosition) {
                visibleGhostIDs.insert(ghostID)
            }
        }
        
        // Update ghost selection on main thread (touches @Published properties)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                print("👻 [GHOST_PROXIMITY] self is nil in async block")
                return
            }
            guard let coordinator = self.arCalibrationCoordinator else {
                if shouldLog {
                    print("👻 [GHOST_PROXIMITY] arCalibrationCoordinator is nil!")
                }
                return
            }
            coordinator.updateGhostSelection(
                cameraPosition: cameraPosition,
                ghostPositions: self.ghostMarkerPositions,
                visibleGhostIDs: visibleGhostIDs
            )
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
