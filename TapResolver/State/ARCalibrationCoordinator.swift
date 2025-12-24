//
//  ARCalibrationCoordinator.swift
//  TapResolver
//
//  Coordinates triangle calibration workflow with AR marker placement
//

import SwiftUI
import Combine
import simd
import ARKit
import SceneKit

/// Represents the distinct phases of triangle calibration
enum CalibrationState: Equatable {
    case placingVertices(currentIndex: Int)  // Placing vertex AR markers (0, 1, or 2)
    case readyToFill                          // All 3 vertices placed, awaiting Fill Triangle
    case surveyMode                           // Placing survey grid markers
    case idle                                 // No active calibration
}

/// Information about a blocked marker placement (too far from ghost)
struct BlockedPlacementInfo {
    let mapPointID: UUID
    let attemptedPosition: simd_float3
    let ghostPosition: simd_float3
    let distance: Float
    let marker: ARMarker  // The marker that was blocked, for override recording
}

final class ARCalibrationCoordinator: ObservableObject {
    @Published var activeTriangleID: UUID?
    @Published var placedMarkers: [UUID] = []  // MapPoint IDs that have been calibrated
    
    /// Triangles that have achieved full calibration (3 vertices) this session
    /// These remain "ready to fill" even when user moves on to calibrate adjacent triangles
    @Published var sessionCalibratedTriangles: Set<UUID> = []
    
    /// Maps marker ID strings to their AR positions for the current session
    /// (mirrors placedMarkers in ARViewContainer.Coordinator for ghost planting)
    private var sessionMarkerPositions: [String: simd_float3] = [:]
    
    /// Maps MapPoint ID to AR position for current session (for ghost calculation)
    var mapPointARPositions: [UUID: simd_float3] = [:]
    
    /// MapPoints whose ghosts were adjusted to AR markers this session (prevents re-planting)
    var adjustedGhostMapPoints: Set<UUID> = []
    
    /// Ghost marker positions tracked by the coordinator (set by ARViewContainer)
    var ghostMarkerPositions: [UUID: simd_float3] = [:]
    
    // MARK: - Preloaded Historical Position Index
    
    // Structure: [sessionID: [mapPointID: position]]
    // Built at AR session start to avoid iteration during ghost calculation
    private var historicalPositionsBySession: [UUID: [UUID: simd_float3]] = [:]
    private var historicalSessionIDs: Set<UUID> = []
    
    // Session origin markers (white spheres showing where historical sessions originated)
    private var sessionOriginNodes: [UUID: SCNNode] = [:]
    
    @Published var statusText: String = ""
    @Published var progressDots: (Bool, Bool, Bool) = (false, false, false)
    
    // MILESTONE 3: Blocked placement state
    @Published var blockedPlacement: BlockedPlacementInfo? = nil
    
    /// Currently selected ghost marker (user is within proximity range)
    @Published var selectedGhostMapPointID: UUID? = nil
    
    /// Estimated position of the selected ghost (for distortion calculation)
    @Published var selectedGhostEstimatedPosition: simd_float3? = nil
    
    /// Ghost marker that is nearby (<2m) but not visible in camera view
    /// When set, UI should show "Unconfirmed Marker Nearby" instead of action buttons
    @Published var nearbyButNotVisibleGhostID: UUID? = nil
    
    /// Tracks MapPoint IDs that were demoted from confirmed markers
    /// These require re-confirmation flow, not adjacent triangle activation
    @Published var demotedGhostMapPointIDs: Set<UUID> = []
    
    /// When true, ghost selection is preserved even when user walks away from the ghost
    /// This allows the user to reposition a marker at any distance from the original ghost location
    @Published var repositionModeActive: Bool = false
    
    // Legacy compatibility properties
    @Published var isActive: Bool = false
    @Published var currentTriangleID: UUID?
    @Published var currentVertexIndex: Int = 0
    @Published var referencePhotoData: Data?
    @Published var completedMarkerCount: Int = 0
    @Published var calibrationState: CalibrationState = .idle
    
    // User position tracking (updated from ARPiPMapView)
    @Published private(set) var lastKnownUserPosition: CGPoint? = nil
    
    // Update user position from PiP map
    func updateUserPosition(_ position: CGPoint?) {
        self.lastKnownUserPosition = position
    }
    
    private var triangleVertices: [UUID] = []
    private var lastPrintedVertexIndex: Int? = nil  // Track last printed vertex to prevent spam
    
    // MARK: - Store References (configured via configure() method)
    private weak var arStore: ARWorldMapStore?
    private weak var mapStore: MapPointStore?
    private weak var triangleStore: TrianglePatchStore?
    private weak var metricSquareStore: MetricSquareStore?
    
    // MARK: - Baked Position Session Transform (Milestone 5 - Step 4)
    
    /// Cached transform from canonical frame to current AR session
    /// Computed once when 2 markers are planted, used for all ghost placements
    private var cachedCanonicalToSessionTransform: SessionToCanonicalTransform?
    
    /// Map size for canonical frame (cached from bake trigger)
    private var cachedMapSize: CGSize?
    
    /// Meters per pixel for canonical frame (cached from MetricSquare)
    private var cachedMetersPerPixel: Float?
    
    // MARK: - Drift Detection
    
    /// Maximum acceptable drift (in meters) before requiring marker adjustment
    private let driftThreshold: Float = 0.06  // 6cm
    
    /// Markers that need drift correction (converted from AR markers to ghosts)
    var markersPendingDriftCorrection: [UUID] = []  // MapPoint IDs
    
    /// Original AR positions for markers being drift-corrected (for replacement, not append)
    var originalMarkerPositions: [UUID: simd_float3] = [:]  // MapPoint ID → original AR position
    
    /// Maps marker ID (UUID string) to MapPoint ID for drift detection
    var sessionMarkerToMapPoint: [String: UUID] = [:]
    
    // MARK: - Session Transform
    
    /// Represents the rigid body transform from an AR session's coordinate frame to the canonical frame
    struct SessionToCanonicalTransform {
        let rotationY: Float           // Radians, Y-axis rotation
        let translation: SIMD3<Float>  // Translation vector
        let scale: Float               // Scale factor (AR meters / canonical meters)
        
        /// Transforms a position from session coordinates to canonical coordinates
        func apply(to sessionPosition: SIMD3<Float>) -> SIMD3<Float> {
            // Apply scale
            let scaled = sessionPosition * scale
            
            // Apply rotation around Y axis
            let cosR = cos(rotationY)
            let sinR = sin(rotationY)
            let rotated = SIMD3<Float>(
                scaled.x * cosR - scaled.z * sinR,
                scaled.y,
                scaled.x * sinR + scaled.z * cosR
            )
            
            // Apply translation
            return rotated + translation
        }
    }
    
    // MARK: - Initialization
    
    init() {
        print("🎯 [ARCalibrationCoordinator] Initialized (unconfigured)")
    }
    
    /// Configure the coordinator with required store references.
    /// MUST be called before any operations that access stores.
    /// This replaces the old pattern of passing stores to init().
    func configure(
        arStore: ARWorldMapStore,
        mapStore: MapPointStore,
        triangleStore: TrianglePatchStore,
        metricSquareStore: MetricSquareStore
    ) {
        self.arStore = arStore
        self.mapStore = mapStore
        self.triangleStore = triangleStore
        self.metricSquareStore = metricSquareStore
        print("🎯 [ARCalibrationCoordinator] Configured with stores")
        
        // Listen for DemoteMarkerToGhost requests
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("DemoteMarkerToGhost"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let markerID = notification.userInfo?["markerID"] as? UUID,
                  let positionArray = notification.userInfo?["currentPosition"] as? [Float],
                  positionArray.count == 3 else {
                print("⚠️ [DEMOTE] Missing required data in notification")
                return
            }
            
            let position = simd_float3(positionArray[0], positionArray[1], positionArray[2])
            self.handleDemoteRequest(markerID: markerID, currentPosition: position)
        }
    }
    
    // MARK: - Public Store Access (for external code that needs read-only access)
    
    /// Public read-only access to the triangle store.
    /// External code (like ARViewWithOverlays) can use this to query triangles.
    public var triangleStoreAccess: TrianglePatchStore {
        return safeTriangleStore
    }
    
    /// Public read-only access to the AR world map store.
    /// External code can use this to access AR session data.
    public var arStoreAccess: ARWorldMapStore {
        return safeARStore
    }
    
    // MARK: - Safe Store Accessors
    // These provide clear crash messages if stores are accessed before configure() is called.
    // In Step 4, all internal usages of mapStore/arStore/triangleStore will use these instead.
    
    private var safeMapStore: MapPointStore {
        guard let store = mapStore else {
            fatalError("❌ [ARCalibrationCoordinator] mapStore accessed before configure() called")
        }
        return store
    }
    
    private var safeARStore: ARWorldMapStore {
        guard let store = arStore else {
            fatalError("❌ [ARCalibrationCoordinator] arStore accessed before configure() called")
        }
        return store
    }
    
    private var safeTriangleStore: TrianglePatchStore {
        guard let store = triangleStore else {
            fatalError("❌ [ARCalibrationCoordinator] triangleStore accessed before configure() called")
        }
        return store
    }
    
    private var safeMetricSquareStore: MetricSquareStore? {
        // This one was already optional, so we just return it as-is
        return metricSquareStore
    }
    
    /// Get pixels per meter conversion factor from MetricSquareStore
    private func getPixelsPerMeter() -> Float? {
        guard let squareStore = metricSquareStore else { return nil }
        
        // Use first locked square, or any square if none are locked
        let lockedSquares = squareStore.squares.filter { $0.isLocked }
        let squaresToUse = lockedSquares.isEmpty ? squareStore.squares : lockedSquares
        
        guard let square = squaresToUse.first, square.meters > 0 else { return nil }
        
        // pixels per meter = side_pixels / side_meters
        let pixelsPerMeter = Float(square.side) / Float(square.meters)
        return pixelsPerMeter > 0 ? pixelsPerMeter : nil
    }
    
    // MARK: - 2-Point Rigid Body Transformation
    
    /// Calculates a rigid body transformation (rotation + translation) between two coordinate frames
    /// using two corresponding point pairs. Rotation is constrained to Y-axis (horizontal plane).
    ///
    /// - Parameters:
    ///   - oldPoints: Two positions from the historical/consensus coordinate frame
    ///   - newPoints: Two positions from the current session coordinate frame
    /// - Returns: A tuple of (rotationAngle, translation) or nil if calculation fails
    ///
    /// The transform converts old positions to new positions via:
    ///   newPosition = rotate(oldPosition - oldCentroid, angle) + newCentroid
    private func calculate2PointRigidTransform(
        oldPoints: (simd_float3, simd_float3),
        newPoints: (simd_float3, simd_float3)
    ) -> (rotationY: Float, translation: simd_float3)? {
        
        // Extract XZ plane vectors (Y is up, we rotate around Y)
        let oldEdge2D = simd_float2(
            oldPoints.1.x - oldPoints.0.x,
            oldPoints.1.z - oldPoints.0.z
        )
        let newEdge2D = simd_float2(
            newPoints.1.x - newPoints.0.x,
            newPoints.1.z - newPoints.0.z
        )
        
        // Check for degenerate edges
        let oldLength = simd_length(oldEdge2D)
        let newLength = simd_length(newEdge2D)
        
        guard oldLength > 0.01, newLength > 0.01 else {
            print("⚠️ [RIGID_TRANSFORM] Degenerate edge - points too close")
            return nil
        }
        
        // Calculate rotation angle around Y-axis
        let oldAngle = atan2(oldEdge2D.y, oldEdge2D.x)
        let newAngle = atan2(newEdge2D.y, newEdge2D.x)
        let rotationY = newAngle - oldAngle
        
        // Validate rotation is reasonable (not NaN or infinite)
        guard rotationY.isFinite else {
            print("⚠️ [RIGID_TRANSFORM] Invalid rotation angle: \(rotationY)")
            return nil
        }
        
        // Calculate translation:
        // After rotating oldPoints.0 around origin by rotationY, where does it need to move to reach newPoints.0?
        let cosR = cos(rotationY)
        let sinR = sin(rotationY)
        
        // Rotate old point 0 around origin (in XZ plane)
        let rotatedOld0 = simd_float3(
            oldPoints.0.x * cosR - oldPoints.0.z * sinR,
            oldPoints.0.y,  // Y unchanged
            oldPoints.0.x * sinR + oldPoints.0.z * cosR
        )
        
        // Translation is difference between new position and rotated old position
        let translation = newPoints.0 - rotatedOld0
        
        // Validate translation is reasonable
        guard translation.x.isFinite, translation.y.isFinite, translation.z.isFinite else {
            print("⚠️ [RIGID_TRANSFORM] Invalid translation: \(translation)")
            return nil
        }
        
        // Sanity check: transformed oldPoints.1 should be close to newPoints.1
        let rotatedOld1 = simd_float3(
            oldPoints.1.x * cosR - oldPoints.1.z * sinR,
            oldPoints.1.y,
            oldPoints.1.x * sinR + oldPoints.1.z * cosR
        )
        let transformedOld1 = rotatedOld1 + translation
        let verificationError = simd_distance(transformedOld1, newPoints.1)
        
        if verificationError > 0.5 {
            print("⚠️ [RIGID_TRANSFORM] High verification error: \(String(format: "%.2f", verificationError))m")
            print("   This may indicate scale difference between sessions")
        }
        
        print("📐 [RIGID_TRANSFORM] Calculated transform:")
        print("   Rotation: \(String(format: "%.1f", rotationY * 180 / .pi))°")
        print("   Translation: (\(String(format: "%.2f", translation.x)), \(String(format: "%.2f", translation.y)), \(String(format: "%.2f", translation.z)))")
        print("   Verification error: \(String(format: "%.3f", verificationError))m")
        
        return (rotationY: rotationY, translation: translation)
    }
    
    /// Applies a Y-axis rotation + translation transform to a 3D position
    private func applyRigidTransform(
        position: simd_float3,
        rotationY: Float,
        translation: simd_float3
    ) -> simd_float3 {
        let cosR = cos(rotationY)
        let sinR = sin(rotationY)
        
        // Rotate around Y-axis (in XZ plane)
        let rotated = simd_float3(
            position.x * cosR - position.z * sinR,
            position.y,
            position.x * sinR + position.z * cosR
        )
        
        // Apply translation
        return rotated + translation
    }
    
    func startCalibration(for triangleID: UUID) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        print("🚀 [CALIBRATION] startCalibration() BEGIN: \(formatter.string(from: Date()))")
        
        guard let triangle = safeTriangleStore.triangle(withID: triangleID) else {
            print("❌ Cannot start calibration: Triangle \(triangleID) not found")
            return
        }
        
        // REFACTOR CANDIDATE: clearExistingMarkersFromScene()
        // Clear any existing calibration markers from scene - we're re-calibrating from scratch
        if let coordinator = ARViewContainer.Coordinator.current {
            coordinator.clearCalibrationMarkers()  // Remove old marker nodes from scene
        }
        
        // Triangle-specific state (not needed for Swath anchoring)
        activeTriangleID = triangleID
        currentTriangleID = triangleID
        
        // Rotate starting vertex to distribute ghost/anchor roles across sessions
        let lastIndex = triangle.lastStartingVertexIndex ?? -1
        let newStartIndex = (lastIndex + 1) % 3

        // Rotate vertexIDs so newStartIndex becomes position 0
        var rotatedVertices = triangle.vertexIDs
        for i in 0..<3 {
            rotatedVertices[i] = triangle.vertexIDs[(newStartIndex + i) % 3]
        }
        triangleVertices = rotatedVertices

        print("🔄 [VERTEX_ROTATION] Starting vertex rotated:")
        print("   Last starting index: \(triangle.lastStartingVertexIndex.map { String($0) } ?? "nil")")
        print("   New starting index: \(newStartIndex)")
        print("   Original order: \(triangle.vertexIDs.map { String($0.uuidString.prefix(8)) })")
        print("   Rotated order: \(rotatedVertices.map { String($0.uuidString.prefix(8)) })")
        
        // REFACTOR CANDIDATE: resetCalibrationState()
        // Clear any existing markers - we're re-calibrating from scratch
        placedMarkers = []
        completedMarkerCount = 0
        currentVertexIndex = 0  // Start with first vertex - ensure proper photo selection
        lastPrintedVertexIndex = nil  // Reset print tracking
        calibrationState = .placingVertices(currentIndex: 0)
        print("🎯 CalibrationState → \(stateDescription)")
        
        // Triangle-specific: Clear marker IDs in TriangleStore
        print("🔄 Re-calibrating triangle - clearing ALL existing markers")
        print("   Old arMarkerIDs: \(triangle.arMarkerIDs)")
        safeTriangleStore.clearAllMarkers(for: triangleID)
        if let updatedTriangle = safeTriangleStore.triangle(withID: triangleID) {
            print("   New arMarkerIDs: \(updatedTriangle.arMarkerIDs)")
        }
        
        // REFACTOR CANDIDATE: validateVertexCount() -> Bool
        // Validate triangleVertices is set correctly
        guard triangleVertices.count == 3 else {
            print("❌ Invalid triangle: expected 3 vertices, got \(triangleVertices.count)")
            return
        }
        
        print("📍 Starting calibration with vertices: \(triangleVertices.map { String($0.uuidString.prefix(8)) })")
        
        // Triangle-specific logging
        if !triangle.arMarkerIDs.isEmpty && triangle.arMarkerIDs.contains(where: { !$0.isEmpty }) {
            print("🔄 Re-calibrating triangle - clearing \(triangle.arMarkerIDs.filter { !$0.isEmpty }.count) existing markers")
        }
        
        // REFACTOR CANDIDATE: loadReferencePhotoForCurrentVertex()
        // Update reference photo for the current vertex (first vertex, index 0)
        if let currentVertexID = getCurrentVertexID(),
           let mapPoint = safeMapStore.points.first(where: { $0.id == currentVertexID }) {
            let photoData: Data? = {
                if let diskData = safeMapStore.loadPhotoFromDisk(for: currentVertexID) {
                    return diskData
                } else {
                    return mapPoint.locationPhotoData
                }
            }()
            setReferencePhoto(photoData)
            
            // Log map point guidance
            print("🎯 Guiding user to Map Point (\(String(format: "%.1f", mapPoint.mapPoint.x)), \(String(format: "%.1f", mapPoint.mapPoint.y)))")
        } else {
            print("⚠️ Could not load reference photo for first vertex")
        }
        
        // REFACTOR CANDIDATE: initializeUIState(statusText:)
        // Update UI state
        progressDots = (false, false, false)
        statusText = "Place AR markers for triangle (0/3)"
        isActive = true
        
        print("🎯 ARCalibrationCoordinator: Starting calibration for triangle \(String(triangleID.uuidString.prefix(8)))")
        
        print("🚀 [CALIBRATION] startCalibration() ready for markers: \(formatter.string(from: Date()))")
        
        // Preload historical position data for fast ghost calculations
        preloadHistoricalPositions()
    }
    
    /// Start Swath Survey anchoring workflow
    /// Similar to startCalibration but uses provided anchor IDs instead of triangle vertices
    /// - Parameter anchorIDs: The 3 MapPoint IDs to use as anchors (from SurveySelectionCoordinator.suggestedAnchorIDs)
    func startSwathAnchoring(anchorIDs: [UUID]) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        print("🚀 [SWATH_ANCHOR] startSwathAnchoring() BEGIN: \(formatter.string(from: Date()))")
        
        // REFACTOR CANDIDATE: clearExistingMarkersFromScene()
        // Clear any existing calibration markers from scene
        if let coordinator = ARViewContainer.Coordinator.current {
            coordinator.clearCalibrationMarkers()
        }
        
        // Swath-specific: No triangle state, just set vertices directly
        activeTriangleID = nil
        currentTriangleID = nil
        triangleVertices = anchorIDs
        
        // REFACTOR CANDIDATE: resetCalibrationState()
        // Clear any existing markers
        placedMarkers = []
        completedMarkerCount = 0
        currentVertexIndex = 0
        lastPrintedVertexIndex = nil
        calibrationState = .placingVertices(currentIndex: 0)
        print("🎯 CalibrationState → \(stateDescription)")
        
        // REFACTOR CANDIDATE: validateVertexCount() -> Bool
        guard triangleVertices.count == 3 else {
            print("❌ Invalid swath anchors: expected 3 anchor IDs, got \(triangleVertices.count)")
            return
        }
        
        print("📍 Starting swath anchoring with vertices: \(triangleVertices.map { String($0.uuidString.prefix(8)) })")
        
        // REFACTOR CANDIDATE: loadReferencePhotoForCurrentVertex()
        if let currentVertexID = getCurrentVertexID(),
           let mapPoint = safeMapStore.points.first(where: { $0.id == currentVertexID }) {
            let photoData: Data? = {
                if let diskData = safeMapStore.loadPhotoFromDisk(for: currentVertexID) {
                    return diskData
                } else {
                    return mapPoint.locationPhotoData
                }
            }()
            setReferencePhoto(photoData)
            
            print("🎯 Guiding user to anchor MapPoint (\(String(format: "%.1f", mapPoint.mapPoint.x)), \(String(format: "%.1f", mapPoint.mapPoint.y)))")
        } else {
            print("⚠️ Could not load reference photo for first anchor")
        }
        
        // REFACTOR CANDIDATE: initializeUIState(statusText:)
        progressDots = (false, false, false)
        statusText = "Place AR markers for swath anchors (0/3)"
        isActive = true
        
        print("🎯 ARCalibrationCoordinator: Starting swath anchoring with \(anchorIDs.count) anchors")
        
        print("🚀 [SWATH_ANCHOR] startSwathAnchoring() ready for markers: \(formatter.string(from: Date()))")
        
        // Preload historical position data for fast ghost calculations
        preloadHistoricalPositions()
    }
    
    /// Builds an indexed lookup of historical positions by session
    /// Called at AR session start to avoid iteration during ghost calculation
    private func preloadHistoricalPositions() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        let startTime = Date()
        print("📦 [PRELOAD] Position History Start: \(formatter.string(from: startTime))")
        
        historicalPositionsBySession.removeAll()
        historicalSessionIDs.removeAll()
        
        var totalRecords = 0
        
        for mapPoint in safeMapStore.points {
            for record in mapPoint.arPositionHistory {
                let sessionID = record.sessionID
                historicalSessionIDs.insert(sessionID)
                
                if historicalPositionsBySession[sessionID] == nil {
                    historicalPositionsBySession[sessionID] = [:]
                }
                historicalPositionsBySession[sessionID]![mapPoint.id] = record.position
                totalRecords += 1
            }
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime) * 1000 // milliseconds
        print("📦 [PRELOAD] Position History Complete: \(formatter.string(from: endTime))")
        print("📦 [PRELOAD] Duration: \(String(format: "%.1f", duration))ms")
        print("📦 [PRELOAD] Summary:")
        print("   Sessions: \(historicalSessionIDs.count)")
        print("   Total position records: \(totalRecords)")
        for (sessionID, mapPoints) in historicalPositionsBySession {
            print("   📍 Session \(String(sessionID.uuidString.prefix(8))): \(mapPoints.count) MapPoint(s)")
        }
    }
    
    // MARK: - Session Origin Visualization
    
    private func renderSessionOrigin(sessionID: UUID, origin: simd_float3, in sceneView: ARSCNView) {
        // Skip if already rendered
        guard sessionOriginNodes[sessionID] == nil else { return }
        
        let axisLength: Float = 0.15  // 0.15m in each direction = 0.3m total
        let axisThickness: CGFloat = 0.005
        let opacity: CGFloat = 0.8
        
        let parentNode = SCNNode()
        parentNode.position = SCNVector3(origin.x, origin.y, origin.z)
        
        // White material
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.white.withAlphaComponent(opacity)
        material.lightingModel = .constant
        
        // X axis line
        let xGeometry = SCNBox(width: CGFloat(axisLength * 2), height: axisThickness, length: axisThickness, chamferRadius: 0)
        xGeometry.materials = [material]
        let xNode = SCNNode(geometry: xGeometry)
        parentNode.addChildNode(xNode)
        
        // Y axis line
        let yGeometry = SCNBox(width: axisThickness, height: CGFloat(axisLength * 2), length: axisThickness, chamferRadius: 0)
        yGeometry.materials = [material]
        let yNode = SCNNode(geometry: yGeometry)
        parentNode.addChildNode(yNode)
        
        // Z axis line
        let zGeometry = SCNBox(width: axisThickness, height: axisThickness, length: CGFloat(axisLength * 2), chamferRadius: 0)
        zGeometry.materials = [material]
        let zNode = SCNNode(geometry: zGeometry)
        parentNode.addChildNode(zNode)
        
        // Session ID label above Y axis
        let labelNode = createSessionLabel(sessionID: sessionID)
        labelNode.position = SCNVector3(0, axisLength + 0.03, 0)  // Above the Y axis
        parentNode.addChildNode(labelNode)
        
        sceneView.scene.rootNode.addChildNode(parentNode)
        sessionOriginNodes[sessionID] = parentNode
        
        print("🎯 [SESSION_ORIGIN] Rendered origin for session \(String(sessionID.uuidString.prefix(6))) at (\(String(format: "%.2f", origin.x)), \(String(format: "%.2f", origin.y)), \(String(format: "%.2f", origin.z)))")
    }
    
    private func createSessionLabel(sessionID: UUID) -> SCNNode {
        let labelText = String(sessionID.uuidString.prefix(6))
        
        let text = SCNText(string: labelText, extrusionDepth: 0.001)
        text.font = UIFont.monospacedSystemFont(ofSize: 0.02, weight: .medium)
        text.flatness = 0.1
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.white.withAlphaComponent(0.8)
        material.lightingModel = .constant
        text.materials = [material]
        
        let textNode = SCNNode(geometry: text)
        
        // Center the text
        let (min, max) = text.boundingBox
        textNode.pivot = SCNMatrix4MakeTranslation(
            (max.x - min.x) / 2 + min.x,
            (max.y - min.y) / 2 + min.y,
            0
        )
        
        // Billboard constraint - always face camera
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = .all
        textNode.constraints = [billboardConstraint]
        
        return textNode
    }
    
    func clearSessionOriginMarkers() {
        for (sessionID, node) in sessionOriginNodes {
            node.removeFromParentNode()
            print("🧹 [SESSION_ORIGIN] Cleared origin marker for session \(String(sessionID.uuidString.prefix(6)))")
        }
        sessionOriginNodes.removeAll()
    }
    
    // MARK: - Legacy Compatibility Methods
    
    func setVertices(_ vertices: [UUID]) {
        triangleVertices = vertices
        print("📍 Calibration vertices set: \(vertices.map { String($0.uuidString.prefix(8)) })")
    }
    
    func getCurrentVertexID() -> UUID? {
        // Ensure triangleVertices is set and currentVertexIndex is valid
        guard !triangleVertices.isEmpty else {
            print("⚠️ getCurrentVertexID: triangleVertices is empty")
            return nil
        }
        guard currentVertexIndex >= 0 && currentVertexIndex < triangleVertices.count else {
            print("⚠️ getCurrentVertexID: currentVertexIndex (\(currentVertexIndex)) out of bounds (0..<\(triangleVertices.count))")
            // Reset to first vertex if out of bounds
            currentVertexIndex = 0
            return triangleVertices.isEmpty ? nil : triangleVertices[0]
        }
        let vertexID = triangleVertices[currentVertexIndex]
        
        // Only print if vertex index changed (prevent spam)
        if lastPrintedVertexIndex != currentVertexIndex {
            print("📍 getCurrentVertexID: returning vertex[\(currentVertexIndex)] = \(String(vertexID.uuidString.prefix(8)))")
            lastPrintedVertexIndex = currentVertexIndex
        }
        
        // Debug moved to registerMarker() to avoid spam
        return vertexID
    }
    
    func setReferencePhoto(_ photoData: Data?) {
        referencePhotoData = photoData
    }
    
    func registerMarker(mapPointID: UUID, marker: ARMarker, sourceType: SourceType = .calibration, distortionVector: simd_float3? = nil) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        let registerStartTime = Date()
        print("📍 [REGISTER] BEGIN: \(formatter.string(from: registerStartTime)) - MapPoint \(String(mapPointID.uuidString.prefix(8)))")
        
        // MARK: Photo verification on marker placement
        print("📍 registerMarker called for MapPoint \(String(mapPointID.uuidString.prefix(8)))")
        if let mapPoint = safeMapStore.points.first(where: { $0.id == mapPointID }) {
            if let photoFilename = mapPoint.photoFilename {
                print("🖼 Photo '\(photoFilename)' linked to MapPoint \(String(mapPoint.id.uuidString.prefix(8)))")
            } else {
                print("⚠️ No photo for MapPoint \(String(mapPoint.id.uuidString.prefix(8)))")
            }
        }
        
        // Find which triangle contains this MapPoint
        let triangleID: UUID?
        let triangle: TrianglePatch?
        
        // Determine triangle context
        let triangleContext: (id: UUID, triangle: TrianglePatch)?
        
        if let activeID = activeTriangleID,
           let activeTriangle = safeTriangleStore.triangle(withID: activeID) {
            // Normal mode - use active triangle
            triangleContext = (activeID, activeTriangle)
        } else if adjustedGhostMapPoints.contains(mapPointID) {
            // Swath mode - find any triangle containing this MapPoint
            if let foundTriangle = safeTriangleStore.triangles.first(where: { $0.vertexIDs.contains(mapPointID) }) {
                triangleContext = (foundTriangle.id, foundTriangle)
                print("📍 [SWATH_REGISTER] Found triangle \(String(foundTriangle.id.uuidString.prefix(8))) for swath MapPoint \(String(mapPointID.uuidString.prefix(8)))")
            } else {
                print("❌ Cannot register marker: No triangle contains MapPoint \(String(mapPointID.uuidString.prefix(8)))")
                return
            }
        } else {
            print("❌ Cannot register marker: No active triangle and MapPoint not in adjustedGhostMapPoints")
            return
        }
        
        triangleID = triangleContext?.id
        triangle = triangleContext?.triangle
        
        // Validate this mapPointID is a vertex of the triangle
        guard let tri = triangle, tri.vertexIDs.contains(mapPointID) else {
            print("❌ MapPoint \(String(mapPointID.uuidString.prefix(8))) is not a vertex of triangle \(String(triangleID?.uuidString.prefix(8) ?? "unknown"))")
            return
        }
        
        // Ensure we have a valid triangle for marker storage
        guard let finalTriangleID = triangleID, let finalTriangle = triangle else {
            print("❌ Cannot register marker: No valid triangle found")
            return
        }
        
        // Check if this mapPoint already has a marker (only 1 marker per MapPoint)
        guard !placedMarkers.contains(mapPointID) else {
            print("⚠️ MapPoint \(String(mapPointID.uuidString.prefix(8))) already has a marker")
            return
        }
        
        // Save marker to ARWorldMapStore (convert to ARWorldMapStore.ARMarker format)
        // Log marker persistence details
        print("💾 Saving AR Marker:")
        print("   Marker ID: \(marker.id)")
        print("   Linked Map Point: \(marker.linkedMapPointID)")
        print("   AR Position: (\(String(format: "%.2f", marker.arPosition.x)), \(String(format: "%.2f", marker.arPosition.y)), \(String(format: "%.2f", marker.arPosition.z))) meters")
        print("   Map Coordinates: (\(String(format: "%.1f", marker.mapCoordinates.x)), \(String(format: "%.1f", marker.mapCoordinates.y))) pixels")
        
        do {
            let worldMapMarker = convertToWorldMapMarker(marker)
            try safeARStore.saveMarker(worldMapMarker)
            print("💾 Saving AR Marker with session context:")
            print("   Marker ID: \(marker.id)")
            print("   Session ID: \(safeARStore.currentSessionID)")
            print("   Session Time: \(safeARStore.currentSessionStartTime)")
            print("   Storage Key: ARWorldMapStore (saved successfully)")
            
            // Track this marker's position for current session (used by ghost planting)
            sessionMarkerPositions[marker.id.uuidString] = marker.arPosition
            mapPointARPositions[mapPointID] = marker.arPosition  // Key by MapPoint ID for easy lookup
            
            // ALWAYS track marker → MapPoint mapping (for demote-to-ghost feature)
            // This must be set for ALL markers: initial placements AND ghost confirmations
            sessionMarkerToMapPoint[marker.id.uuidString] = mapPointID  // Map marker ID to MapPoint ID for drift detection
            
            if sourceType == .ghostConfirm || sourceType == .ghostAdjust {
                print("🔗 [MARKER_TRACK] Registered ghost-confirmed marker \(String(marker.id.uuidString.prefix(8))) → MapPoint \(String(mapPointID.uuidString.prefix(8)))")
            } else {
                print("📍 [SESSION_MARKERS] Stored position for \(String(marker.id.uuidString.prefix(8))) → MapPoint \(String(mapPointID.uuidString.prefix(8)))")
            }
            
            // MILESTONE 3: Validate placement against ghost (if exists)
            if let coordinator = ARViewContainer.Coordinator.current,
               let ghostNode = coordinator.ghostMarkers[mapPointID] {
                let ghostPosition = ghostNode.simdPosition
                let distance = simd_distance(marker.arPosition, ghostPosition)
                
                print("📏 [PLACEMENT_CHECK] Distance from ghost: \(String(format: "%.2f", distance))m")
                // Log expected vs actual for debugging transform accuracy
                print("   Ghost position: (\(String(format: "%.2f", ghostPosition.x)), \(String(format: "%.2f", ghostPosition.y)), \(String(format: "%.2f", ghostPosition.z)))")
                print("   Actual position: (\(String(format: "%.2f", marker.arPosition.x)), \(String(format: "%.2f", marker.arPosition.y)), \(String(format: "%.2f", marker.arPosition.z)))")
                
                if distance > 0.5 {
                    // BLOCK placement - too far from expected position
                    print("🚫 [PLACEMENT_BLOCKED] Marker is \(String(format: "%.2f", distance))m from ghost (threshold: 0.5m)")
                    
                    blockedPlacement = BlockedPlacementInfo(
                        mapPointID: mapPointID,
                        attemptedPosition: marker.arPosition,
                        ghostPosition: ghostPosition,
                        distance: distance,
                        marker: marker
                    )
                    
                    // Post notification for AR warning UI
                    NotificationCenter.default.post(
                        name: NSNotification.Name("PlacementBlocked"),
                        object: nil,
                        userInfo: [
                            "mapPointID": mapPointID,
                            "attemptedPosition": marker.arPosition,
                            "ghostPosition": ghostPosition,
                            "distance": distance
                        ]
                    )
                    
                    return  // Do not record marker
                }
            }
            
            // MARK: - Record position in history (Milestone 2)
            // Determine source type for swath adjustments
            let effectiveSourceType: SourceType
            if adjustedGhostMapPoints.contains(mapPointID) && sourceType == .calibration {
                // This is a swath ghost adjustment, treat as ghostAdjust
                effectiveSourceType = .ghostAdjust
                print("📍 [SWATH_REGISTER] Treating as ghostAdjust for position history")
            } else {
                effectiveSourceType = sourceType
            }
            
            let confidence: Float = effectiveSourceType == .ghostConfirm ? 1.0 : (effectiveSourceType == .ghostAdjust ? 0.8 : 0.95)
            let record = ARPositionRecord(
                position: marker.arPosition,
                sessionID: safeARStore.currentSessionID,
                sourceType: effectiveSourceType,
                distortionVector: distortionVector,
                confidenceScore: confidence
            )
            safeMapStore.addPositionRecord(mapPointID: mapPointID, record: record)
            
            // MILESTONE 5: Update baked position incrementally for ghost confirm/adjust
            if sourceType == .ghostConfirm || sourceType == .ghostAdjust {
                updateBakedPositionIncrementally(
                    mapPointID: mapPointID,
                    sessionPosition: marker.arPosition,
                    confidence: confidence
                )
            }
        } catch {
            print("❌ Failed to save marker to ARWorldMapStore: \(error)")
            return
        }
        
        // Update ALL triangles containing this MapPoint (handles shared vertices)
        // Determine preferred triangle based on context
        // Normal placement - use activeTriangleID as preferred
        var preferredTriangleID: UUID? = activeTriangleID
        
        // Update all triangles and get primary triangle
        let updatedPrimaryTriangle = updateAllTrianglesContainingVertex(
            mapPointID: mapPointID,
            markerID: marker.id,
            preferredTriangleID: preferredTriangleID
        )
        
        // Update finalTriangle reference to primary triangle for completion checks
        if let primary = updatedPrimaryTriangle {
            // Update finalTriangleID and finalTriangle for subsequent code
            // Note: We can't reassign finalTriangleID/finalTriangle directly, but we'll use primary.id where needed
            if let index = primary.vertexIDs.firstIndex(of: mapPointID) {
                print("✅ Added marker \(String(marker.id.uuidString.prefix(8))) to triangle \(String(primary.id.uuidString.prefix(8))) vertex \(index)")
            }
        }
        
        // Track placed marker
        placedMarkers.append(mapPointID)
        updateProgressDots()
        
        // MILESTONE 3: After 2nd marker, plant ghost for 3rd vertex
        if placedMarkers.count == 2 {
            // MILESTONE 5: Compute and cache session transform for baked ghost positions
            // Try to get map parameters for transform computation
            if let pixelsPerMeter = getPixelsPerMeter() {
                let metersPerPixel = 1.0 / pixelsPerMeter
                // Try to get map size from notification or use a reasonable default
                // If mapSize is not available, transform computation will be skipped
                // and ghost calculation will fall back to legacy method
                if let mapSize = cachedMapSize {
                    computeSessionTransformForBakedData(mapSize: mapSize, metersPerPixel: metersPerPixel)
                } else {
                    // Map size not cached yet - will be computed on first ghost calculation if needed
                    print("📐 [SESSION_TRANSFORM] Map size not cached, will compute transform on first ghost if needed")
                }
            }
            
            // Find the unplaced vertex
            let unplacedVertices = triangleVertices.filter { !placedMarkers.contains($0) }
            if let thirdVertexID = unplacedVertices.first {
                // Get AR positions of placed markers using MapPoint-keyed dictionary
                let orderedPositions: [simd_float3] = placedMarkers.compactMap { mapPointARPositions[$0] }
                
                if orderedPositions.count == 2 {
                    print("📍 [GHOST_3RD] Found AR positions for 2 placed markers")
                    print("   Marker 1 (\(String(placedMarkers[0].uuidString.prefix(8)))): \(orderedPositions[0])")
                    print("   Marker 2 (\(String(placedMarkers[1].uuidString.prefix(8)))): \(orderedPositions[1])")
                    
                    if let ghostPosition = calculateGhostPositionForThirdVertex(
                        thirdVertexID: thirdVertexID,
                        placedVertexIDs: Array(placedMarkers),
                        placedARPositions: orderedPositions
                    ) {
                        // Post notification to render ghost
                        NotificationCenter.default.post(
                            name: NSNotification.Name("PlaceGhostMarker"),
                            object: nil,
                            userInfo: [
                                "mapPointID": thirdVertexID,
                                "position": ghostPosition
                            ]
                        )
                        print("👻 [GHOST_3RD] Planted ghost for 3rd vertex \(String(thirdVertexID.uuidString.prefix(8)))")
                    }
                } else {
                    print("⚠️ [GHOST_3RD] Could not get AR positions for placed markers")
                    print("   placedMarkers: \(placedMarkers.map { String($0.uuidString.prefix(8)) })")
                    print("   mapPointARPositions keys: \(mapPointARPositions.keys.map { String($0.uuidString.prefix(8)) })")
                }
            }
            
            // Plant origin marker at canonical (0,0,0) projected to session, grounded to floor
            let canonicalOrigin = simd_float3(0, 0, 0)
            if var sessionOrigin = projectBakedToSession(canonicalOrigin) {
                // Ground the marker: use Y from first placed marker (which is on the floor)
                if let firstPlacedID = placedMarkers.first,
                   let groundY = mapPointARPositions[firstPlacedID]?.y {
                    sessionOrigin.y = groundY
                    print("🎯 [ORIGIN_MARKER] Grounded to Y=\(String(format: "%.2f", groundY)) from first placed marker")
                }
                
                print("🎯 [ORIGIN_MARKER] Canonical (0,0,0) → Session (\(String(format: "%.2f", sessionOrigin.x)), \(String(format: "%.2f", sessionOrigin.y)), \(String(format: "%.2f", sessionOrigin.z)))")
                
                NotificationCenter.default.post(
                    name: NSNotification.Name("PlaceOriginMarker"),
                    object: nil,
                    userInfo: ["position": [sessionOrigin.x, sessionOrigin.y, sessionOrigin.z]]
                )
            } else {
                print("⚠️ [ORIGIN_MARKER] Could not project canonical origin - transform not available")
            }
        }
        
        // Advance to next vertex if not all placed
        if placedMarkers.count < 3 {
            // Find next unplaced vertex - use triangleVertices to ensure consistency
            for vertexID in triangleVertices {
                if !placedMarkers.contains(vertexID) {
                    // Update currentVertexIndex to point to this vertex in triangleVertices
                    if let index = triangleVertices.firstIndex(of: vertexID) {
                        currentVertexIndex = index
                        print("📍 Advanced to next vertex: index=\(index), vertexID=\(String(vertexID.uuidString.prefix(8)))")
                        
                        // Update reference photo for next vertex
                        if let mapPoint = safeMapStore.points.first(where: { $0.id == vertexID }) {
                            let photoData: Data? = {
                                if let diskData = safeMapStore.loadPhotoFromDisk(for: vertexID) {
                                    return diskData
                                } else {
                                    return mapPoint.locationPhotoData
                                }
                            }()
                            setReferencePhoto(photoData)
                            
                            // Log map point guidance for next vertex
                            print("🎯 Guiding user to Map Point (\(String(format: "%.1f", mapPoint.mapPoint.x)), \(String(format: "%.1f", mapPoint.mapPoint.y)))")
                        } else {
                            print("⚠️ Could not find MapPoint for vertexID \(String(vertexID.uuidString.prefix(8)))")
                        }
                        break
                    } else {
                        print("⚠️ VertexID \(String(vertexID.uuidString.prefix(8))) not found in triangleVertices")
                    }
                }
            }
        }
        
        let count = placedMarkers.count
        statusText = "Place AR markers for triangle (\(count)/3)"
        
        print("✅ ARCalibrationCoordinator: Registered marker for MapPoint \(String(mapPointID.uuidString.prefix(8))) (\(count)/3)")
        
        if placedMarkers.count == 3 {
            // DRIFT DETECTION: Check if earlier markers have drifted
            if let coordinator = ARViewContainer.Coordinator.current,
               let sceneView = coordinator.sceneView {
                let driftedMarkers = detectDriftedMarkers(
                    sceneView: sceneView,
                    sessionMarkerPositions: sessionMarkerPositions
                )
                
                if !driftedMarkers.isEmpty {
                    print("⚠️ [DRIFT_DETECTED] \(driftedMarkers.count) marker(s) have drifted beyond \(driftThreshold * 100)cm threshold")
                    initiateDriftCorrection(driftedMarkers: driftedMarkers)
                    // Return early - don't finalize calibration until drift is corrected
                    return
                }
            }
            
            // Use primary triangle for completion check (handles shared vertices correctly)
            let triangleForCompletion = updatedPrimaryTriangle ?? finalTriangle
            finalizeCalibration(for: triangleForCompletion)
            calibrationState = .readyToFill
            print("🎯 CalibrationState → \(stateDescription)")
            print("✅ Calibration complete. Triangle ready to fill.")
        } else {
            // Update state to reflect current vertex index
            if let index = triangleVertices.firstIndex(of: mapPointID) {
                calibrationState = .placingVertices(currentIndex: index)
                print("🎯 CalibrationState → \(stateDescription)")
            }
        }
        
        // Placement accuracy diagnostic
        if let coordinator = ARViewContainer.Coordinator.current,
           let ghostNode = coordinator.ghostMarkers[mapPointID] {
            let expectedPosition = ghostNode.simdPosition
            let actualPosition = marker.arPosition
            let delta = simd_distance(expectedPosition, actualPosition)
            print("📏 [PLACEMENT_ACCURACY] Marker \(String(mapPointID.uuidString.prefix(8))) placed \(String(format: "%.2f", delta))m from expected ghost location")
            print("   Expected: (\(String(format: "%.2f", expectedPosition.x)), \(String(format: "%.2f", expectedPosition.y)), \(String(format: "%.2f", expectedPosition.z)))")
            print("   Actual:   (\(String(format: "%.2f", actualPosition.x)), \(String(format: "%.2f", actualPosition.y)), \(String(format: "%.2f", actualPosition.z)))")
        }
        
        let registerEndTime = Date()
        let registerDuration = registerEndTime.timeIntervalSince(registerStartTime) * 1000
        print("📍 [REGISTER] END: \(formatter.string(from: registerEndTime)) (duration: \(String(format: "%.1f", registerDuration))ms)")
    }
    
    /// Register an anchor marker during Swath Survey anchoring workflow
    /// This is a simplified version of registerMarker that doesn't require triangle validation
    /// REFACTOR NOTE: This function shares significant code with registerMarker().
    /// Consider extracting shared logic into helper methods:
    ///   - saveMarkerToStore()
    ///   - trackMarkerPosition()
    ///   - recordPositionHistory()
    ///   - advanceToNextVertex()
    /// - Parameters:
    ///   - mapPointID: The MapPoint ID for this anchor
    ///   - marker: The AR marker that was placed
    func registerSwathAnchor(mapPointID: UUID, marker: ARMarker) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        print("📍 [SWATH_ANCHOR] registerSwathAnchor BEGIN: \(formatter.string(from: Date()))")
        print("   MapPoint: \(String(mapPointID.uuidString.prefix(8)))")
        print("   Position: (\(String(format: "%.2f", marker.arPosition.x)), \(String(format: "%.2f", marker.arPosition.y)), \(String(format: "%.2f", marker.arPosition.z)))")
        
        // Validate this is one of our target anchors
        guard triangleVertices.contains(mapPointID) else {
            print("❌ [SWATH_ANCHOR] MapPoint \(String(mapPointID.uuidString.prefix(8))) is not a swath anchor vertex")
            return
        }
        
        // Check if already placed
        guard !placedMarkers.contains(mapPointID) else {
            print("⚠️ [SWATH_ANCHOR] MapPoint \(String(mapPointID.uuidString.prefix(8))) already has a marker")
            return
        }
        
        // REFACTOR CANDIDATE: saveMarkerToStore() - shared with registerMarker
        // Save to ARWorldMapStore
        do {
            let worldMapMarker = convertToWorldMapMarker(marker)
            try safeARStore.saveMarker(worldMapMarker)
            print("💾 [SWATH_ANCHOR] Saved marker to ARWorldMapStore")
            
            // REFACTOR CANDIDATE: trackMarkerPosition() - shared with registerMarker
            // Track position for transform computation
            sessionMarkerPositions[marker.id.uuidString] = marker.arPosition
            mapPointARPositions[mapPointID] = marker.arPosition
            sessionMarkerToMapPoint[marker.id.uuidString] = mapPointID  // Map marker ID to MapPoint ID for drift detection
            print("📍 [SWATH_ANCHOR] Stored position for MapPoint \(String(mapPointID.uuidString.prefix(8)))")
            
            // REFACTOR CANDIDATE: recordPositionHistory() - shared with registerMarker
            // Record in position history
            let record = ARPositionRecord(
                position: marker.arPosition,
                sessionID: safeARStore.currentSessionID,
                sourceType: .calibration,
                distortionVector: nil,
                confidenceScore: 0.95
            )
            safeMapStore.addPositionRecord(mapPointID: mapPointID, record: record)
            
        } catch {
            print("❌ [SWATH_ANCHOR] Failed to save marker: \(error)")
            return
        }
        
        // REFACTOR CANDIDATE: updatePlacementProgress() - shared with registerMarker
        // Track placed marker and update UI
        placedMarkers.append(mapPointID)
        completedMarkerCount = placedMarkers.count
        updateProgressDots()
        
        print("📊 [SWATH_ANCHOR] Progress: \(placedMarkers.count)/3 anchors placed")
        
        // REFACTOR CANDIDATE: computeTransformAfterSecondMarker() - shared with registerMarker
        // After 2 markers, compute session transform for baked data
        if placedMarkers.count == 2 {
            if let pixelsPerMeter = getPixelsPerMeter() {
                let metersPerPixel = 1.0 / pixelsPerMeter
                if let mapSize = cachedMapSize {
                    computeSessionTransformForBakedData(mapSize: mapSize, metersPerPixel: metersPerPixel)
                }
            }
        }
        
        // REFACTOR CANDIDATE: advanceToNextVertex() - shared with registerMarker
        // Advance to next anchor or complete
        if placedMarkers.count < 3 {
            // Move to next vertex
            currentVertexIndex += 1
            calibrationState = .placingVertices(currentIndex: currentVertexIndex)
            statusText = "Place AR markers for swath anchors (\(placedMarkers.count)/3)"
            
            // Load reference photo for next anchor
            if let nextVertexID = getCurrentVertexID(),
               let mapPoint = safeMapStore.points.first(where: { $0.id == nextVertexID }) {
                let photoData: Data? = safeMapStore.loadPhotoFromDisk(for: nextVertexID) ?? mapPoint.locationPhotoData
                setReferencePhoto(photoData)
                print("🎯 [SWATH_ANCHOR] Advancing to anchor \(currentVertexIndex + 1): MapPoint \(String(nextVertexID.uuidString.prefix(8)))")
                print("   Position: (\(String(format: "%.1f", mapPoint.mapPoint.x)), \(String(format: "%.1f", mapPoint.mapPoint.y)))")
            }
        } else {
            // All 3 anchors placed - ready for Fill Swath
            calibrationState = .readyToFill
            statusText = "Swath anchors complete - ready to fill"
            print("✅ [SWATH_ANCHOR] All 3 anchors placed - hasValidSessionTransform: \(hasValidSessionTransform)")
        }
        
        print("📍 [SWATH_ANCHOR] registerSwathAnchor END: \(formatter.string(from: Date()))")
    }
    
    // MARK: - Drift Detection
    
    /// Check if previously-planted markers have drifted from their recorded positions
    /// - Parameters:
    ///   - sceneView: The AR scene view to check marker positions
    ///   - sessionMarkerPositions: Dictionary of marker ID (UUID string) to recorded AR position
    /// - Returns: Array of MapPoint IDs that have drifted beyond threshold
    func detectDriftedMarkers(
        sceneView: ARSCNView,
        sessionMarkerPositions: [String: simd_float3]  // markerID → recorded AR position
    ) -> [(mapPointID: UUID, recordedPosition: simd_float3, currentPosition: simd_float3, drift: Float)] {
        
        guard let frame = sceneView.session.currentFrame else {
            print("⚠️ [DRIFT_CHECK] No current frame available")
            return []
        }
        
        var driftedMarkers: [(mapPointID: UUID, recordedPosition: simd_float3, currentPosition: simd_float3, drift: Float)] = []
        
        // Get the markers we placed earlier in this session (excluding the one just placed)
        // sessionMarkerPositions maps markerID → AR position
        // We need to map back to MapPoint IDs
        
        for (markerIDString, recordedPosition) in sessionMarkerPositions {
            // Find the corresponding MapPoint ID
            guard let mapPointID = sessionMarkerToMapPoint[markerIDString] else {
                continue
            }
            
            // Skip the most recently placed marker (it's our reference point)
            if mapPointID == triangleVertices.last {
                continue
            }
            
            // Find the marker node in the scene
            guard let markerUUID = UUID(uuidString: markerIDString),
                  let markerNode = sceneView.scene.rootNode.childNodes.first(where: { 
                $0.name == "arMarker_\(markerUUID.uuidString)" || $0.name?.contains(markerUUID.uuidString.prefix(8).description) == true
            }) else {
                print("⚠️ [DRIFT_CHECK] Could not find node for marker \(String(markerIDString.prefix(8)))")
                continue
            }
            
            // Get current world position of the marker node
            let currentPosition = markerNode.simdWorldPosition
            
            // Calculate drift (3D distance)
            let drift = simd_distance(recordedPosition, currentPosition)
            
            print("🔍 [DRIFT_CHECK] Marker \(String(mapPointID.uuidString.prefix(8))): recorded=(\(String(format: "%.2f", recordedPosition.x)), \(String(format: "%.2f", recordedPosition.z))) current=(\(String(format: "%.2f", currentPosition.x)), \(String(format: "%.2f", currentPosition.z))) drift=\(String(format: "%.3f", drift))m")
            
            if drift > driftThreshold {
                driftedMarkers.append((mapPointID: mapPointID, recordedPosition: recordedPosition, currentPosition: currentPosition, drift: drift))
            }
        }
        
        return driftedMarkers
    }
    
    /// Convert drifted AR markers to ghost markers for user adjustment
    func initiateDriftCorrection(
        driftedMarkers: [(mapPointID: UUID, recordedPosition: simd_float3, currentPosition: simd_float3, drift: Float)]
    ) {
        guard !driftedMarkers.isEmpty else { return }
        
        print("🔄 [DRIFT_CORRECTION] Initiating drift correction for \(driftedMarkers.count) marker(s)")
        
        for marker in driftedMarkers {
            print("   ⚠️ MapPoint \(String(marker.mapPointID.uuidString.prefix(8))): drifted \(String(format: "%.1f", marker.drift * 100))cm")
            
            // Store original position for potential replacement
            originalMarkerPositions[marker.mapPointID] = marker.recordedPosition
            
            // Add to pending correction list
            markersPendingDriftCorrection.append(marker.mapPointID)
        }
        
        // Notify UI to convert these markers to ghosts
        NotificationCenter.default.post(
            name: NSNotification.Name("ConvertMarkersToGhosts"),
            object: nil,
            userInfo: [
                "mapPointIDs": markersPendingDriftCorrection,
                "originalPositions": originalMarkerPositions
            ]
        )
        
        print("🔄 [DRIFT_CORRECTION] Posted ConvertMarkersToGhosts notification")
    }
    
    /// Handle a drift-corrected marker position (replaces original, doesn't append)
    func recordDriftCorrectedPosition(mapPointID: UUID, correctedPosition: simd_float3) {
        print("✅ [DRIFT_CORRECTION] Recording corrected position for \(String(mapPointID.uuidString.prefix(8)))")
        print("   Original: \(originalMarkerPositions[mapPointID].map { "(\(String(format: "%.2f", $0.x)), \(String(format: "%.2f", $0.z)))" } ?? "unknown")")
        print("   Corrected: (\(String(format: "%.2f", correctedPosition.x)), \(String(format: "%.2f", correctedPosition.z)))")
        
        // Update the session marker position (replace, not append)
        if let markerIDString = sessionMarkerToMapPoint.first(where: { $0.value == mapPointID })?.key {
            // Update in sessionMarkerPositions
            sessionMarkerPositions[markerIDString] = correctedPosition
            // Update in mapPointARPositions
            mapPointARPositions[mapPointID] = correctedPosition
        }
        
        // Remove from pending list
        markersPendingDriftCorrection.removeAll { $0 == mapPointID }
        
        // Clear original position
        originalMarkerPositions.removeValue(forKey: mapPointID)
        
        print("   Remaining pending corrections: \(markersPendingDriftCorrection.count)")
        
        // If all corrections complete, notify to proceed
        if markersPendingDriftCorrection.isEmpty {
            print("✅ [DRIFT_CORRECTION] All markers corrected - ready to proceed")
            NotificationCenter.default.post(
                name: NSNotification.Name("DriftCorrectionComplete"),
                object: nil
            )
        }
    }
    
    /// Handle request to demote an AR marker to ghost for re-adjustment
    func handleDemoteRequest(markerID: UUID, currentPosition: simd_float3) {
        // Look up which MapPoint this marker belongs to
        let markerIDString = markerID.uuidString
        guard let mapPointID = sessionMarkerToMapPoint[markerIDString] else {
            print("⚠️ [DEMOTE] No MapPoint found for marker \(String(markerID.uuidString.prefix(8)))")
            return
        }
        
        print("🔄 [DEMOTE] Demoting marker for MapPoint \(String(mapPointID.uuidString.prefix(8)))")
        
        // Store original position for potential replacement (not append)
        originalMarkerPositions[mapPointID] = currentPosition
        
        // Mark this MapPoint as pending adjustment
        if !markersPendingDriftCorrection.contains(mapPointID) {
            markersPendingDriftCorrection.append(mapPointID)
        }
        
        // Remove from session tracking (will be re-added when confirmed)
        sessionMarkerToMapPoint.removeValue(forKey: markerIDString)
        
        // Mark this as a demoted ghost (requires re-confirmation, not crawl expansion)
        demotedGhostMapPointIDs.insert(mapPointID)
        print("🔄 [DEMOTE] Added \(String(mapPointID.uuidString.prefix(8))) to demotedGhostMapPointIDs")
        
        // Set activeTriangleID to a calibrated triangle containing this MapPoint
        if let triangleStore = triangleStore {
            let containingTriangles = triangleStore.triangles.filter { triangle in
                triangle.vertexIDs.contains(mapPointID)
            }
            
            // Prefer a calibrated triangle, fall back to any containing triangle
            let calibratedContaining = containingTriangles.first { triangle in
                sessionCalibratedTriangles.contains(triangle.id)
            }
            
            if let targetTriangle = calibratedContaining ?? containingTriangles.first {
                activeTriangleID = targetTriangle.id
                print("🔄 [DEMOTE] Set activeTriangleID to \(String(targetTriangle.id.uuidString.prefix(8))) (contains demoted MapPoint)")
            }
        }
        
        // Post response to trigger visual conversion
        NotificationCenter.default.post(
            name: NSNotification.Name("DemoteMarkerResponse"),
            object: nil,
            userInfo: [
                "markerID": markerID,
                "mapPointID": mapPointID,
                "position": [Float(currentPosition.x), Float(currentPosition.y), Float(currentPosition.z)]
            ]
        )
        
        // Update calibration state to indicate adjustment in progress
        // This will show the ghost confirm/adjust UI
        print("✅ [DEMOTE] MapPoint \(String(mapPointID.uuidString.prefix(8))) ready for re-adjustment")
    }
    
    // MARK: - Shared Vertex Helper
    
    /// Updates arMarkerIDs for ALL triangles containing the specified MapPoint.
    /// Returns the primary triangle (preferredTriangleID if found, otherwise first match).
    /// - Parameters:
    ///   - mapPointID: The MapPoint that was marked
    ///   - markerID: The AR marker ID to record
    ///   - preferredTriangleID: Optional triangle ID to prioritize (e.g., activeTriangleID)
    /// - Returns: The primary triangle that was updated, or nil if no triangle contains this MapPoint
    private func updateAllTrianglesContainingVertex(
        mapPointID: UUID,
        markerID: UUID,
        preferredTriangleID: UUID?
    ) -> TrianglePatch? {
        // Find ALL triangles containing this MapPoint
        let matchingTriangles = safeTriangleStore.triangles.filter { $0.vertexIDs.contains(mapPointID) }
        
        guard !matchingTriangles.isEmpty else {
            print("⚠️ [SHARED_VERTEX] No triangles contain MapPoint \(String(mapPointID.uuidString.prefix(8)))")
            return nil
        }
        
        // Determine which triangle is "primary" (for calibration completion checks)
        let primaryTriangle: TrianglePatch
        if let preferredID = preferredTriangleID,
           let preferred = matchingTriangles.first(where: { $0.id == preferredID }) {
            primaryTriangle = preferred
        } else {
            primaryTriangle = matchingTriangles[0]
        }
        
        print("📐 [SHARED_VERTEX] Updating \(matchingTriangles.count) triangle(s) for MapPoint \(String(mapPointID.uuidString.prefix(8)))")
        print("   Primary triangle: \(String(primaryTriangle.id.uuidString.prefix(8)))")
        
        // Update ALL matching triangles
        for triangle in matchingTriangles {
            guard let vertexIndex = triangle.vertexIDs.firstIndex(of: mapPointID) else { continue }
            
            // Use the existing addMarkerToTriangle method which handles array sizing
            safeTriangleStore.addMarkerToTriangle(
                triangleID: triangle.id,
                vertexMapPointID: mapPointID,
                markerID: markerID
            )
            
            let isPrimary = triangle.id == primaryTriangle.id
            print("   \(isPrimary ? "★" : "○") Triangle \(String(triangle.id.uuidString.prefix(8))) vertex \(vertexIndex) → marker \(String(markerID.uuidString.prefix(8)))")
        }
        
        // Note: save() is already called by addMarkerToTriangle() for each triangle
        // No need to call save() again here
        
        // Return fresh copy of primary triangle
        return safeTriangleStore.triangles.first(where: { $0.id == primaryTriangle.id })
    }
    
    /// Calculate 3D AR position for a MapPoint using barycentric interpolation from a calibrated triangle
    private func calculateGhostPosition(
        mapPoint: MapPointStore.MapPoint,
        calibratedTriangleID: UUID,
        triangleStore: TrianglePatchStore,
        mapPointStore: MapPointStore,
        arWorldMapStore: ARWorldMapStore
    ) -> simd_float3? {
        print("═══════════════════════════════════════════════════════════")
        print("👻 [GHOST_CALC] Calculating ghost for MapPoint \(String(mapPoint.id.uuidString.prefix(8)))")
        if let triangleID = activeTriangleID {
            print("   Triangle: \(String(triangleID.uuidString.prefix(8)))")
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        let calcStartTime = Date()
        print("👻 [GHOST_CALC] BEGIN: \(formatter.string(from: calcStartTime))")
        
        // Re-fetch triangle to ensure we have the latest arMarkerIDs (fixes stale struct issue)
        guard let calibratedTriangle = safeTriangleStore.triangles.first(where: { $0.id == calibratedTriangleID }) else {
            print("⚠️ [GHOST_CALC] Could not find triangle \(String(calibratedTriangleID.uuidString.prefix(8)))")
            let calcEndTime = Date()
            let calcDuration = calcEndTime.timeIntervalSince(calcStartTime) * 1000
            print("👻 [GHOST_CALC] END: \(formatter.string(from: calcEndTime)) (duration: \(String(format: "%.1f", calcDuration))ms) - FAILED")
            return nil
        }
        
        print("🔍 [GHOST_CALC] Fresh triangle fetch - arMarkerIDs: \(calibratedTriangle.arMarkerIDs)")
        
        // Validate all marker IDs are populated - log warning but don't block (will fall back to mapPointARPositions)
        if !calibratedTriangle.arMarkerIDs.allSatisfy({ !$0.isEmpty }) {
            print("⚠️ [GHOST_CALC] Incomplete marker ID list: \(calibratedTriangle.arMarkerIDs) - will attempt fallback to mapPointARPositions")
        }
        
        // STEP 1: Get triangle's 3 vertex MapPoints (2D positions)
        guard calibratedTriangle.vertexIDs.count == 3 else {
            print("⚠️ [GHOST_CALC] Triangle has invalid vertex count: \(calibratedTriangle.vertexIDs.count)")
            let calcEndTime = Date()
            let calcDuration = calcEndTime.timeIntervalSince(calcStartTime) * 1000
            print("👻 [GHOST_CALC] END: \(formatter.string(from: calcEndTime)) (duration: \(String(format: "%.1f", calcDuration))ms) - FAILED")
            return nil
        }
        
        let vertexMapPoints = calibratedTriangle.vertexIDs.compactMap { vertexID in
            mapPointStore.points.first { $0.id == vertexID }
        }
        
        guard vertexMapPoints.count == 3 else {
            print("⚠️ [GHOST_CALC] Could not find all 3 vertex MapPoints")
            let calcEndTime = Date()
            let calcDuration = calcEndTime.timeIntervalSince(calcStartTime) * 1000
            print("👻 [GHOST_CALC] END: \(formatter.string(from: calcEndTime)) (duration: \(String(format: "%.1f", calcDuration))ms) - FAILED")
            return nil
        }
        
        let p1_2D = vertexMapPoints[0].position
        let p2_2D = vertexMapPoints[1].position
        let p3_2D = vertexMapPoints[2].position
        let p_target_2D = mapPoint.position
        
        // STEP 2: Calculate barycentric weights in 2D map space
        // Using the formula: P = w1*P1 + w2*P2 + w3*P3 where w1+w2+w3=1
        let v0 = CGPoint(x: p2_2D.x - p1_2D.x, y: p2_2D.y - p1_2D.y)
        let v1 = CGPoint(x: p3_2D.x - p1_2D.x, y: p3_2D.y - p1_2D.y)
        let v2 = CGPoint(x: p_target_2D.x - p1_2D.x, y: p_target_2D.y - p1_2D.y)
        
        let denom = v0.x * v1.y - v1.x * v0.y
        guard abs(denom) > 0.001 else {
            print("⚠️ [GHOST_CALC] Degenerate triangle - vertices are collinear")
            let calcEndTime = Date()
            let calcDuration = calcEndTime.timeIntervalSince(calcStartTime) * 1000
            print("👻 [GHOST_CALC] END: \(formatter.string(from: calcEndTime)) (duration: \(String(format: "%.1f", calcDuration))ms) - FAILED")
            return nil
        }
        
        let w2 = (v2.x * v1.y - v1.x * v2.y) / denom
        let w3 = (v0.x * v2.y - v2.x * v0.y) / denom
        let w1 = 1.0 - w2 - w3
        
        print("📐 [GHOST_CALC] Barycentric weights: w1=\(String(format: "%.3f", w1)), w2=\(String(format: "%.3f", w2)), w3=\(String(format: "%.3f", w3))")
        
        // ═══════════════════════════════════════════════════════════════════════════
        // PRIORITY 0: Baked Canonical Position (fastest, most stable)
        // Uses accumulated canonical position projected to current session
        // ═══════════════════════════════════════════════════════════════════════════
        print("╔════════════════════════════════════════════════════════════════════════╗")
        print("║ 🔍 [GHOST_CALC] PRIORITY CHECK: Baked Canonical Position              ║")
        print("╠════════════════════════════════════════════════════════════════════════╣")
        
        // Check prerequisites for baked path
        let hasBakedPosition = mapPoint.canonicalPosition != nil
        let hasSessionTransform = cachedCanonicalToSessionTransform != nil
        
        print("║   MapPoint: \(String(mapPoint.id.uuidString.prefix(8)))")
        print("║   canonicalPosition: \(hasBakedPosition ? "✅ EXISTS" : "❌ NIL")")
        if let baked = mapPoint.canonicalPosition {
            print("║     → (\(String(format: "%.2f", baked.x)), \(String(format: "%.2f", baked.y)), \(String(format: "%.2f", baked.z)))")
            print("║     confidence: \(mapPoint.canonicalConfidence != nil ? String(format: "%.2f", mapPoint.canonicalConfidence!) : "NIL")")
            print("║     sampleCount: \(mapPoint.canonicalSampleCount)")
        }
        print("║   cachedCanonicalToSessionTransform: \(hasSessionTransform ? "✅ EXISTS" : "❌ NIL")")
        
        // Task 2: Canonical position diagnostics
        if let canonical = mapPoint.canonicalPosition {
            print("📍 [GHOST_CALC] Canonical position: (\(String(format: "%.3f", canonical.x)), \(String(format: "%.3f", canonical.y)), \(String(format: "%.3f", canonical.z)))")
            print("   Confidence: \(mapPoint.canonicalConfidence ?? 0)")
            print("   Sample count: \(mapPoint.canonicalSampleCount ?? 0)")
        } else {
            print("📍 [GHOST_CALC] No canonical position — using fallback path")
        }
        
        if hasBakedPosition && hasSessionTransform {
            print("║   → Attempting baked projection via calculateGhostPositionFromBakedData()")
            print("╚════════════════════════════════════════════════════════════════════════╝")
            
            if let bakedPosition = calculateGhostPositionFromBakedData(for: mapPoint.id) {
                let calcEndTime = Date()
                let calcDuration = calcEndTime.timeIntervalSince(calcStartTime) * 1000
                print("╔════════════════════════════════════════════════════════════════════════╗")
                print("║ ✅ [GHOST_CALC] BAKED PATH SUCCEEDED                                   ║")
                print("╠════════════════════════════════════════════════════════════════════════╣")
                print("║ Result: (\(String(format: "%.2f", bakedPosition.x)), \(String(format: "%.2f", bakedPosition.y)), \(String(format: "%.2f", bakedPosition.z)))")
                print("║ Duration: \(String(format: "%.2f", calcDuration))ms")
                print("║ Source: Baked canonical → session projection")
                print("╚════════════════════════════════════════════════════════════════════════╝")
                return bakedPosition
            } else {
                print("╔════════════════════════════════════════════════════════════════════════╗")
                print("║ ⚠️ [GHOST_CALC] Baked projection FAILED - falling through to PRIORITY 1║")
                print("╚════════════════════════════════════════════════════════════════════════╝")
            }
        } else {
            print("║   → Prerequisites not met, skipping baked path")
            if !hasBakedPosition {
                print("║     Reason: No canonicalPosition for this MapPoint")
            }
            if !hasSessionTransform {
                print("║     Reason: No cachedCanonicalToSessionTransform (need 2+ markers placed)")
            }
            print("╚════════════════════════════════════════════════════════════════════════╝")
        }
        
        // ═══════════════════════════════════════════════════════════════════════════
        // PRIORITY 1: Session-level rigid transform (legacy path)
        // Instead of using naive consensus (which mixes coordinate frames),
        // we transform each historical session's position individually
        
        let targetHistory = mapPoint.arPositionHistory
        if !targetHistory.isEmpty {
            print("📍 [GHOST_CALC] Target has \(targetHistory.count) historical position(s) - attempting session-level transform")
            
            // Group target positions by session
            let targetSessionIDs = Set(targetHistory.map { $0.sessionID })
            
            // Also collect vertex historical positions indexed by sessionID
            var vertexHistoryBySession: [UUID: [(vertexIndex: Int, position: simd_float3)]] = [:]
            for (index, vertexMapPoint) in vertexMapPoints.enumerated() {
                for record in vertexMapPoint.arPositionHistory {
                    vertexHistoryBySession[record.sessionID, default: []].append((vertexIndex: index, position: record.position))
                }
            }
            
            // Get current session positions for vertices (these are our "anchor points")
            var currentVertexPositions: [Int: simd_float3] = [:]
            for (index, vertexMapPoint) in vertexMapPoints.enumerated() {
                if let currentPos = mapPointARPositions[vertexMapPoint.id] {
                    currentVertexPositions[index] = currentPos
                }
            }
            
            // For each session where target has a position, attempt to build a transform
            var alignedCandidates: [(position: simd_float3, confidence: Float)] = []
            
            for targetRecord in targetHistory {
                let sessionID = targetRecord.sessionID
                
                // Check if this session has positions for 2+ vertices that we also have in current session
                guard let vertexRecords = vertexHistoryBySession[sessionID] else {
                    print("   ⏭️ Session \(String(sessionID.uuidString.prefix(8))): no vertex positions")
                    continue
                }
                
                // Find vertices that have BOTH historical (this session) AND current positions
                var correspondences: [(historical: simd_float3, current: simd_float3)] = []
                for vertexRecord in vertexRecords {
                    if let currentPos = currentVertexPositions[vertexRecord.vertexIndex] {
                        correspondences.append((historical: vertexRecord.position, current: currentPos))
                    }
                }
                
                guard correspondences.count >= 2 else {
                    print("   ⏭️ Session \(String(sessionID.uuidString.prefix(8))): only \(correspondences.count) correspondence(s), need 2")
                    continue
                }
                
                // Compute rigid transform from historical session to current session
                guard let transform = calculate2PointRigidTransform(
                    oldPoints: (correspondences[0].historical, correspondences[1].historical),
                    newPoints: (correspondences[0].current, correspondences[1].current)
                ) else {
                    print("   ⚠️ Session \(String(sessionID.uuidString.prefix(8))): transform calculation failed")
                    continue
                }
                
                // Verify transform quality
                let cosR = cos(transform.rotationY)
                let sinR = sin(transform.rotationY)
                let rotatedHistorical1 = simd_float3(
                    correspondences[1].historical.x * cosR - correspondences[1].historical.z * sinR,
                    correspondences[1].historical.y,
                    correspondences[1].historical.x * sinR + correspondences[1].historical.z * cosR
                )
                let transformedHistorical1 = rotatedHistorical1 + transform.translation
                let verificationError = simd_distance(transformedHistorical1, correspondences[1].current)
                
                if verificationError > 0.5 {
                    print("   ⚠️ Session \(String(sessionID.uuidString.prefix(8))): verification error \(String(format: "%.2f", verificationError))m > 0.5m threshold, skipping")
                    continue
                }
                
                // Render session origin in AR (translation = historical origin in current coordinates)
                // TODO: Render session origin - needs ARSCNView reference
                // renderSessionOrigin(sessionID: sessionID, origin: transform.translation, in: sceneView)
                print("🎯 [SESSION_ORIGIN] Session \(String(sessionID.uuidString.prefix(6))) origin at (\(String(format: "%.2f", transform.translation.x)), \(String(format: "%.2f", transform.translation.y)), \(String(format: "%.2f", transform.translation.z)))")
                
                // Apply transform to target's position from this session
                let transformedPosition = applyRigidTransform(
                    position: targetRecord.position,
                    rotationY: transform.rotationY,
                    translation: transform.translation
                )
                
                print("   ✅ Session \(String(sessionID.uuidString.prefix(8))): transformed to (\(String(format: "%.2f", transformedPosition.x)), \(String(format: "%.2f", transformedPosition.y)), \(String(format: "%.2f", transformedPosition.z))) [error: \(String(format: "%.2f", verificationError))m]")
                
                alignedCandidates.append((position: transformedPosition, confidence: targetRecord.confidenceScore))
            }
            
            // If we have aligned candidates, compute weighted average
            if !alignedCandidates.isEmpty {
                var weightedSum = simd_float3(0, 0, 0)
                var totalWeight: Float = 0
                
                for candidate in alignedCandidates {
                    weightedSum += candidate.position * candidate.confidence
                    totalWeight += candidate.confidence
                }
                
                let alignedConsensus = weightedSum / totalWeight
                print("╔════════════════════════════════════════════════════════════════════════╗")
                print("║ ✅ [GHOST_CALC] PER-SESSION ALIGNMENT SUCCEEDED                        ║")
                print("╠════════════════════════════════════════════════════════════════════════╣")
                print("║ Consensus from \(alignedCandidates.count) session(s): (\(String(format: "%.2f", alignedConsensus.x)), \(String(format: "%.2f", alignedConsensus.y)), \(String(format: "%.2f", alignedConsensus.z)))")
                print("║ Source: Session-level rigid transforms (PRIORITY 1 path)")
                print("╚════════════════════════════════════════════════════════════════════════╝")
                
                // Task 4: Historical distortion vector diagnostics
                let distortionHistory = mapPoint.arPositionHistory.compactMap { $0.distortionVector }
                if !distortionHistory.isEmpty {
                    print("📐 [GHOST_CALC] Historical distortion vectors (\(distortionHistory.count) records):")
                    var avgDistortion = simd_float3(0, 0, 0)
                    for (i, d) in distortionHistory.prefix(5).enumerated() {
                        print("   [\(i)] (\(String(format: "%.3f", d.x)), \(String(format: "%.3f", d.y)), \(String(format: "%.3f", d.z)))")
                        avgDistortion += d
                    }
                    if distortionHistory.count > 5 {
                        print("   ... and \(distortionHistory.count - 5) more")
                        for d in distortionHistory.dropFirst(5) {
                            avgDistortion += d
                        }
                    }
                    avgDistortion /= Float(distortionHistory.count)
                    print("   AVG: (\(String(format: "%.3f", avgDistortion.x)), \(String(format: "%.3f", avgDistortion.y)), \(String(format: "%.3f", avgDistortion.z)))")
                    print("   Magnitude: \(String(format: "%.3f", simd_length(avgDistortion)))m")
                    print("   ⚠️ [NOT APPLIED] This correction is stored but not used in prediction!")
                } else {
                    print("📐 [GHOST_CALC] No historical distortion vectors for this point")
                }
                
                // Task 5: Leg measurements diagnostics
                if let triangleID = activeTriangleID,
                   let triangle = safeTriangleStore.triangle(withID: triangleID),
                   !triangle.legMeasurements.isEmpty {
                    print("📏 [GHOST_CALC] Triangle leg measurements:")
                    for (i, leg) in triangle.legMeasurements.enumerated() {
                        print("   Leg \(i): \(String(leg.vertexA.uuidString.prefix(8)))→\(String(leg.vertexB.uuidString.prefix(8))) map=\(String(format: "%.3f", leg.mapDistance))m AR=\(String(format: "%.3f", leg.arDistance))m ratio=\(String(format: "%.3f", leg.distortionRatio))")
                    }
                    let ratios = triangle.legMeasurements.map { $0.distortionRatio }
                    let avgRatio = ratios.reduce(0, +) / Float(ratios.count)
                    let maxDeviation = ratios.map { abs($0 - 1.0) }.max() ?? 0
                    print("   Avg ratio: \(String(format: "%.3f", avgRatio)) (1.0 = perfect match)")
                    print("   Max deviation: \(String(format: "%.3f", maxDeviation)) (\(String(format: "%.1f", maxDeviation * 100))%)")
                } else {
                    print("📏 [GHOST_CALC] No leg measurements available for this triangle")
                }
                
                let calcEndTime = Date()
                let calcDuration = calcEndTime.timeIntervalSince(calcStartTime) * 1000
                print("👻 [GHOST_CALC] END: \(formatter.string(from: calcEndTime)) (duration: \(String(format: "%.1f", calcDuration))ms)")
                
                // Task 6: Final position diagnostic
                print("👻 [GHOST_CALC] Final ghost position: (\(String(format: "%.3f", alignedConsensus.x)), \(String(format: "%.3f", alignedConsensus.y)), \(String(format: "%.3f", alignedConsensus.z)))")
                print("═══════════════════════════════════════════════════════════")
                
                return alignedConsensus
            } else {
                print("📐 [GHOST_CALC] No sessions could be aligned - falling back to barycentric")
            }
        } else {
            print("📐 [GHOST_CALC] No history for target MapPoint \(String(mapPoint.id.uuidString.prefix(8))) - using barycentric")
        }
        
        // PRIORITY 2: Barycentric interpolation from current session data (existing code follows)
        
        // STEP 3: Get triangle's 3 vertex AR positions (3D positions)
        // Attempt to gather 3 vertex positions from available sources
        var vertexPositions: [simd_float3] = []
        
        // FIRST: Try to use arMarkerIDs if they exist AND are all available in current session
        var foundAllMarkers = false
        if calibratedTriangle.arMarkerIDs.count == 3 && calibratedTriangle.arMarkerIDs.allSatisfy({ !$0.isEmpty }) {
            var markerPositions: [simd_float3] = []
            var allMarkersFound = true
            
            for markerIDString in calibratedTriangle.arMarkerIDs {
                guard !markerIDString.isEmpty else {
                    print("⚠️ [GHOST_CALC] Empty marker ID string in triangle's arMarkerIDs")
                    allMarkersFound = false
                    break
                }
                
                var foundPosition: simd_float3?
                
                // PRIORITY 1: Check current session's marker positions (just placed markers)
                if let sessionPosition = sessionMarkerPositions[markerIDString] {
                    foundPosition = sessionPosition
                    print("✅ [GHOST_CALC] Found marker \(String(markerIDString.prefix(8))) in session cache at position (\(String(format: "%.2f", sessionPosition.x)), \(String(format: "%.2f", sessionPosition.y)), \(String(format: "%.2f", sessionPosition.z)))")
                }
                // PRIORITY 2: Check by prefix in case arMarkerIDs has short 8-char versions
                else if let sessionPosition = sessionMarkerPositions.first(where: { $0.key.hasPrefix(markerIDString) || markerIDString.hasPrefix($0.key) })?.value {
                    foundPosition = sessionPosition
                    print("✅ [GHOST_CALC] Found marker \(String(markerIDString.prefix(8))) via prefix in session cache")
                }
                // PRIORITY 3: Fall back to ARWorldMapStore
                else if let marker = arWorldMapStore.markers.first(where: { $0.id.hasPrefix(markerIDString) || markerIDString.hasPrefix($0.id) }) {
                    foundPosition = marker.positionInSession
                    print("✅ [GHOST_CALC] Found marker \(String(marker.id.prefix(8))) in store at position (\(String(format: "%.2f", marker.positionInSession.x)), \(String(format: "%.2f", marker.positionInSession.y)), \(String(format: "%.2f", marker.positionInSession.z)))")
                }
                
                if let position = foundPosition {
                    markerPositions.append(position)
                } else {
                    print("📐 [GHOST_CALC] Marker \(String(markerIDString.prefix(8))) not in current session cache - will try vertex positions")
                    allMarkersFound = false
                    break
                }
            }
            
            if allMarkersFound && markerPositions.count == 3 {
                vertexPositions = markerPositions
                foundAllMarkers = true
            }
        }
        
        // SECOND: If markers weren't available, try mapPointARPositions (keyed by MapPoint ID)
        if !foundAllMarkers {
            print("📐 [GHOST_CALC] Checking mapPointARPositions for triangle vertices")
            var vertexPosFromActivation: [simd_float3] = []
            var allVerticesFound = true
            
            for vertexID in calibratedTriangle.vertexIDs {
                if let position = mapPointARPositions[vertexID] {
                    print("✅ [GHOST_CALC] Found vertex \(String(vertexID.uuidString.prefix(8))) in mapPointARPositions at (\(String(format: "%.2f", position.x)), \(String(format: "%.2f", position.y)), \(String(format: "%.2f", position.z)))")
                    vertexPosFromActivation.append(position)
                } else {
                    print("⚠️ [GHOST_CALC] Vertex \(String(vertexID.uuidString.prefix(8))) not in mapPointARPositions")
                    allVerticesFound = false
                    break
                }
            }
            
            if allVerticesFound && vertexPosFromActivation.count == 3 {
                vertexPositions = vertexPosFromActivation
            }
        }
        
        // Final check: do we have 3 positions?
        guard vertexPositions.count == 3 else {
            print("⚠️ [GHOST_CALC] Could not find all 3 vertex positions from any source")
            let calcEndTime = Date()
            let calcDuration = calcEndTime.timeIntervalSince(calcStartTime) * 1000
            print("👻 [GHOST_CALC] END: \(formatter.string(from: calcEndTime)) (duration: \(String(format: "%.1f", calcDuration))ms) - FAILED")
            return nil
        }
        
        // STEP 4: Apply barycentric weights to 3D AR positions
        let m1_3D = vertexPositions[0]
        let m2_3D = vertexPositions[1]
        let m3_3D = vertexPositions[2]
        
        let ghostPosition = simd_float3(
            Float(w1) * m1_3D.x + Float(w2) * m2_3D.x + Float(w3) * m3_3D.x,
            Float(w1) * m1_3D.y + Float(w2) * m2_3D.y + Float(w3) * m3_3D.y,
            Float(w1) * m1_3D.z + Float(w2) * m2_3D.z + Float(w3) * m3_3D.z
        )
        
        print("╔════════════════════════════════════════════════════════════════════════╗")
        print("║ ⚠️ [GHOST_CALC] BARYCENTRIC FALLBACK USED                              ║")
        print("╠════════════════════════════════════════════════════════════════════════╣")
        print("║ Position: (\(String(format: "%.2f", ghostPosition.x)), \(String(format: "%.2f", ghostPosition.y)), \(String(format: "%.2f", ghostPosition.z)))")
        print("║ Source: Current session barycentric interpolation (PRIORITY 2 path)")
        print("║ Note: No baked data or session history available for this vertex")
        print("╚════════════════════════════════════════════════════════════════════════╝")
        
        // Task 4: Historical distortion vector diagnostics
        let distortionHistory = mapPoint.arPositionHistory.compactMap { $0.distortionVector }
        if !distortionHistory.isEmpty {
            print("📐 [GHOST_CALC] Historical distortion vectors (\(distortionHistory.count) records):")
            var avgDistortion = simd_float3(0, 0, 0)
            for (i, d) in distortionHistory.prefix(5).enumerated() {
                print("   [\(i)] (\(String(format: "%.3f", d.x)), \(String(format: "%.3f", d.y)), \(String(format: "%.3f", d.z)))")
                avgDistortion += d
            }
            if distortionHistory.count > 5 {
                print("   ... and \(distortionHistory.count - 5) more")
                for d in distortionHistory.dropFirst(5) {
                    avgDistortion += d
                }
            }
            avgDistortion /= Float(distortionHistory.count)
            print("   AVG: (\(String(format: "%.3f", avgDistortion.x)), \(String(format: "%.3f", avgDistortion.y)), \(String(format: "%.3f", avgDistortion.z)))")
            print("   Magnitude: \(String(format: "%.3f", simd_length(avgDistortion)))m")
            print("   ⚠️ [NOT APPLIED] This correction is stored but not used in prediction!")
        } else {
            print("📐 [GHOST_CALC] No historical distortion vectors for this point")
        }
        
        // Task 5: Leg measurements diagnostics
        if let triangleID = activeTriangleID,
           let triangle = safeTriangleStore.triangle(withID: triangleID),
           !triangle.legMeasurements.isEmpty {
            print("📏 [GHOST_CALC] Triangle leg measurements:")
            for (i, leg) in triangle.legMeasurements.enumerated() {
                print("   Leg \(i): \(String(leg.vertexA.uuidString.prefix(8)))→\(String(leg.vertexB.uuidString.prefix(8))) map=\(String(format: "%.3f", leg.mapDistance))m AR=\(String(format: "%.3f", leg.arDistance))m ratio=\(String(format: "%.3f", leg.distortionRatio))")
            }
            let ratios = triangle.legMeasurements.map { $0.distortionRatio }
            let avgRatio = ratios.reduce(0, +) / Float(ratios.count)
            let maxDeviation = ratios.map { abs($0 - 1.0) }.max() ?? 0
            print("   Avg ratio: \(String(format: "%.3f", avgRatio)) (1.0 = perfect match)")
            print("   Max deviation: \(String(format: "%.3f", maxDeviation)) (\(String(format: "%.1f", maxDeviation * 100))%)")
        } else {
            print("📏 [GHOST_CALC] No leg measurements available for this triangle")
        }
        
        let calcEndTime = Date()
        let calcDuration = calcEndTime.timeIntervalSince(calcStartTime) * 1000
        print("👻 [GHOST_CALC] END: \(formatter.string(from: calcEndTime)) (duration: \(String(format: "%.1f", calcDuration))ms)")
        
        // Task 6: Final position diagnostic
        print("👻 [GHOST_CALC] Final ghost position: (\(String(format: "%.3f", ghostPosition.x)), \(String(format: "%.3f", ghostPosition.y)), \(String(format: "%.3f", ghostPosition.z)))")
        print("═══════════════════════════════════════════════════════════")
        
        return ghostPosition
    }
    
    /// Fast ghost position calculation using baked canonical positions
    /// Returns nil if baked data unavailable, caller should fall back to legacy calculation
    ///
    /// - Parameter targetMapPointID: The MapPoint to calculate ghost position for
    /// - Returns: AR position in current session coordinates, or nil if baked data unavailable
    func calculateGhostPositionFromBakedData(for targetMapPointID: UUID) -> SIMD3<Float>? {
        let startTime = Date()
        
        // Check prerequisites
        guard let transform = cachedCanonicalToSessionTransform else {
            print("")
            print("┌─────────────────────────────────────────────────────────────────────┐")
            print("│ 👻 [BAKED_GHOST] No cached transform - attempting to compute...    │")
            print("└─────────────────────────────────────────────────────────────────────┘")
            
            // Try to compute transform if we have the data
            if let mapSize = cachedMapSize, let metersPerPixel = cachedMetersPerPixel {
                print("   ├─ Map params available: \(Int(mapSize.width))×\(Int(mapSize.height)), \(String(format: "%.4f", metersPerPixel)) m/px")
                guard computeSessionTransformForBakedData(mapSize: mapSize, metersPerPixel: metersPerPixel) else {
                    print("   └─ ❌ Transform computation FAILED")
                    print("      Reason: computeSessionTransformForBakedData returned false")
                    return nil
                }
            } else {
                print("   └─ ❌ Cannot compute transform - missing map parameters:")
                print("      cachedMapSize: \(cachedMapSize != nil ? "✅" : "❌ NIL")")
                print("      cachedMetersPerPixel: \(cachedMetersPerPixel != nil ? "✅" : "❌ NIL")")
                return nil
            }
            
            guard let newTransform = cachedCanonicalToSessionTransform else {
                print("   └─ ❌ Transform still nil after computation attempt")
                return nil
            }
            
            print("   └─ ✅ Transform computed successfully")
            return calculateGhostPositionFromBakedDataInternal(for: targetMapPointID, using: newTransform, startTime: startTime)
        }
        
        return calculateGhostPositionFromBakedDataInternal(for: targetMapPointID, using: transform, startTime: startTime)
    }
    
    private func calculateGhostPositionFromBakedDataInternal(
        for targetMapPointID: UUID,
        using transform: SessionToCanonicalTransform,
        startTime: Date
    ) -> SIMD3<Float>? {
        // Look up baked position
        guard let targetMapPoint = safeMapStore.points.first(where: { $0.id == targetMapPointID }) else {
            print("┌─────────────────────────────────────────────────────────────────────┐")
            print("│ ❌ [BAKED_GHOST] MapPoint NOT FOUND: \(String(targetMapPointID.uuidString.prefix(8)))")
            print("└─────────────────────────────────────────────────────────────────────┘")
            return nil
        }
        
        guard let bakedPosition = targetMapPoint.canonicalPosition else {
            print("┌─────────────────────────────────────────────────────────────────────┐")
            print("│ ❌ [BAKED_GHOST] No canonicalPosition for \(String(targetMapPointID.uuidString.prefix(8)))")
            print("├─────────────────────────────────────────────────────────────────────┤")
            print("│ MapPoint exists but has no baked data:")
            print("│   canonicalConfidence: \(targetMapPoint.canonicalConfidence != nil ? String(format: "%.2f", targetMapPoint.canonicalConfidence!) : "NIL")")
            print("│   canonicalSampleCount: \(targetMapPoint.canonicalSampleCount)")
            print("│   arPositionHistory: \(targetMapPoint.arPositionHistory.count) record(s)")
            if !targetMapPoint.arPositionHistory.isEmpty {
                print("│   Sessions in history:")
                let sessions = Set(targetMapPoint.arPositionHistory.map { $0.sessionID })
                for (i, sid) in sessions.enumerated() {
                    let count = targetMapPoint.arPositionHistory.filter { $0.sessionID == sid }.count
                    print("│     [\(i)] \(String(sid.uuidString.prefix(8))): \(count) record(s)")
                }
            }
            print("└─────────────────────────────────────────────────────────────────────┘")
            return nil
        }
        
        // Apply transform: canonical → session
        let sessionPosition = transform.apply(to: bakedPosition)
        
        // Task 3: Transform application diagnostics
        print("🔄 [GHOST_CALC] Global transform applied:")
        print("   Canonical (X,Z): (\(String(format: "%.3f", bakedPosition.x)), \(String(format: "%.3f", bakedPosition.z)))")
        print("   Session (X,Z):   (\(String(format: "%.3f", sessionPosition.x)), \(String(format: "%.3f", sessionPosition.z)))")
        print("   Transform: rot=\(String(format: "%.1f", transform.rotationY * 180 / .pi))° scale=\(String(format: "%.4f", transform.scale))")
        print("   Translation: (\(String(format: "%.3f", transform.translation.x)), \(String(format: "%.3f", transform.translation.z)))")
        
        let duration = Date().timeIntervalSince(startTime) * 1000
        print("👻 [BAKED_GHOST] ✅ \(String(targetMapPointID.uuidString.prefix(8))): baked(\(String(format: "%.2f", bakedPosition.x)), \(String(format: "%.2f", bakedPosition.z))) → session(\(String(format: "%.2f", sessionPosition.x)), \(String(format: "%.2f", sessionPosition.z))) in \(String(format: "%.2f", duration))ms")
        
        // Task 4: Historical distortion vector diagnostics
        let distortionHistory = targetMapPoint.arPositionHistory.compactMap { $0.distortionVector }
        if !distortionHistory.isEmpty {
            print("📐 [GHOST_CALC] Historical distortion vectors (\(distortionHistory.count) records):")
            var avgDistortion = simd_float3(0, 0, 0)
            for (i, d) in distortionHistory.prefix(5).enumerated() {
                print("   [\(i)] (\(String(format: "%.3f", d.x)), \(String(format: "%.3f", d.y)), \(String(format: "%.3f", d.z)))")
                avgDistortion += d
            }
            if distortionHistory.count > 5 {
                print("   ... and \(distortionHistory.count - 5) more")
                for d in distortionHistory.dropFirst(5) {
                    avgDistortion += d
                }
            }
            avgDistortion /= Float(distortionHistory.count)
            print("   AVG: (\(String(format: "%.3f", avgDistortion.x)), \(String(format: "%.3f", avgDistortion.y)), \(String(format: "%.3f", avgDistortion.z)))")
            print("   Magnitude: \(String(format: "%.3f", simd_length(avgDistortion)))m")
            print("   ⚠️ [NOT APPLIED] This correction is stored but not used in prediction!")
        } else {
            print("📐 [GHOST_CALC] No historical distortion vectors for this point")
        }
        
        // Task 5: Leg measurements diagnostics
        if let triangleID = activeTriangleID,
           let triangle = safeTriangleStore.triangle(withID: triangleID),
           !triangle.legMeasurements.isEmpty {
            print("📏 [GHOST_CALC] Triangle leg measurements:")
            for (i, leg) in triangle.legMeasurements.enumerated() {
                print("   Leg \(i): \(String(leg.vertexA.uuidString.prefix(8)))→\(String(leg.vertexB.uuidString.prefix(8))) map=\(String(format: "%.3f", leg.mapDistance))m AR=\(String(format: "%.3f", leg.arDistance))m ratio=\(String(format: "%.3f", leg.distortionRatio))")
            }
            let ratios = triangle.legMeasurements.map { $0.distortionRatio }
            let avgRatio = ratios.reduce(0, +) / Float(ratios.count)
            let maxDeviation = ratios.map { abs($0 - 1.0) }.max() ?? 0
            print("   Avg ratio: \(String(format: "%.3f", avgRatio)) (1.0 = perfect match)")
            print("   Max deviation: \(String(format: "%.3f", maxDeviation)) (\(String(format: "%.1f", maxDeviation * 100))%)")
        } else {
            print("📏 [GHOST_CALC] No leg measurements available for this triangle")
        }
        
        // Task 6: Final position diagnostic
        print("👻 [GHOST_CALC] Final ghost position: (\(String(format: "%.3f", sessionPosition.x)), \(String(format: "%.3f", sessionPosition.y)), \(String(format: "%.3f", sessionPosition.z)))")
        print("═══════════════════════════════════════════════════════════")
        
        return sessionPosition
    }
    
    /// Calculate ghost position for 3rd vertex when only 2 markers are placed
    /// Uses hierarchical approach: consensus history first, then 2D map geometry
    private func calculateGhostPositionForThirdVertex(
        thirdVertexID: UUID,
        placedVertexIDs: [UUID],
        placedARPositions: [simd_float3]
    ) -> simd_float3? {
        // ╔════════════════════════════════════════════════════════════════════════╗
        // ║                    GHOST POSITION DIAGNOSTIC                            ║
        // ╚════════════════════════════════════════════════════════════════════════╝
        let diagStart = Date()
        print("")
        print("╔════════════════════════════════════════════════════════════════════════╗")
        print("║              👻 GHOST POSITION CALCULATION START                       ║")
        print("╠════════════════════════════════════════════════════════════════════════╣")
        print("║ Target vertex: \(String(thirdVertexID.uuidString.prefix(8)))")
        print("║ Placed markers: \(placedVertexIDs.count)")
        for (i, vid) in placedVertexIDs.enumerated() {
            print("║   [\(i)] \(String(vid.uuidString.prefix(8))) → AR pos: (\(String(format: "%.2f", placedARPositions[i].x)), \(String(format: "%.2f", placedARPositions[i].y)), \(String(format: "%.2f", placedARPositions[i].z)))")
        }
        print("╠════════════════════════════════════════════════════════════════════════╣")
        print("║ PREREQUISITES CHECK:")
        print("║   cachedCanonicalToSessionTransform: \(cachedCanonicalToSessionTransform != nil ? "✅ EXISTS" : "❌ NIL")")
        print("║   cachedMapSize: \(cachedMapSize != nil ? "✅ \(Int(cachedMapSize!.width))×\(Int(cachedMapSize!.height))" : "❌ NIL")")
        print("║   cachedMetersPerPixel: \(cachedMetersPerPixel != nil ? "✅ \(String(format: "%.4f", cachedMetersPerPixel!))" : "❌ NIL")")
        
        // Check target MapPoint's baked status
        if let targetMP = safeMapStore.points.first(where: { $0.id == thirdVertexID }) {
            print("║   Target MapPoint baked status:")
            if let baked = targetMP.canonicalPosition {
                print("║     canonicalPosition: ✅ (\(String(format: "%.2f", baked.x)), \(String(format: "%.2f", baked.y)), \(String(format: "%.2f", baked.z)))")
            } else {
                print("║     canonicalPosition: ❌ NIL")
            }
            print("║     canonicalConfidence: \(targetMP.canonicalConfidence != nil ? String(format: "%.2f", targetMP.canonicalConfidence!) : "NIL")")
            print("║     canonicalSampleCount: \(targetMP.canonicalSampleCount)")
            print("║     arPositionHistory count: \(targetMP.arPositionHistory.count)")
        } else {
            print("║   Target MapPoint: ❌ NOT FOUND IN STORE")
        }
        print("╠════════════════════════════════════════════════════════════════════════╣")
        print("║ ATTEMPTING PATH SELECTION...")
        print("╚════════════════════════════════════════════════════════════════════════╝")
        
        // MILESTONE 5: Try baked data first (fast path)
        if let bakedPosition = calculateGhostPositionFromBakedData(for: thirdVertexID) {
            let diagDuration = Date().timeIntervalSince(diagStart) * 1000
            print("")
            print("╔════════════════════════════════════════════════════════════════════════╗")
            print("║ ✅ BAKED PATH SUCCEEDED                                                ║")
            print("╠════════════════════════════════════════════════════════════════════════╣")
            print("║ Result: (\(String(format: "%.2f", bakedPosition.x)), \(String(format: "%.2f", bakedPosition.y)), \(String(format: "%.2f", bakedPosition.z)))")
            print("║ Duration: \(String(format: "%.2f", diagDuration))ms")
            print("╚════════════════════════════════════════════════════════════════════════╝")
            print("")
            return bakedPosition
        }
        print("")
        print("╔════════════════════════════════════════════════════════════════════════╗")
        print("║ ⚠️  LEGACY PATH ACTIVATED (baked data unavailable)                     ║")
        print("╠════════════════════════════════════════════════════════════════════════╣")
        print("║ This path uses consensusPosition which may average incompatible")
        print("║ coordinate frames from different AR sessions.")
        print("╚════════════════════════════════════════════════════════════════════════╝")
        
        let calcStart = Date()
        var timingLog: [(String, TimeInterval)] = []
        
        guard placedVertexIDs.count == 2, placedARPositions.count == 2 else {
            print("⚠️ [GHOST_3RD] Need exactly 2 placed markers")
            return nil
        }
        
        // Get MapPoints for all 3 vertices
        let lookupStart = Date()
        guard let thirdMapPoint = safeMapStore.points.first(where: { $0.id == thirdVertexID }),
              let firstMapPoint = safeMapStore.points.first(where: { $0.id == placedVertexIDs[0] }),
              let secondMapPoint = safeMapStore.points.first(where: { $0.id == placedVertexIDs[1] }) else {
            print("⚠️ [GHOST_3RD] Could not find MapPoints for vertices")
            return nil
        }
        timingLog.append(("MapPoint lookup", Date().timeIntervalSince(lookupStart)))
        
        // PRIORITY 1: Check if 3rd vertex has consensus position from history
        // AND both placed markers have consensus positions (required for rigid transform)
        let consensusStart = Date()
        if let consensus = thirdMapPoint.consensusPosition,
           let firstConsensus = firstMapPoint.consensusPosition,
           let secondConsensus = secondMapPoint.consensusPosition {
            
            print("📍 [GHOST_3RD] Attempting rigid transform for \(String(thirdVertexID.uuidString.prefix(8)))")
            print("   Historical positions: P1=(\(String(format: "%.2f, %.2f, %.2f", firstConsensus.x, firstConsensus.y, firstConsensus.z))), P2=(\(String(format: "%.2f, %.2f, %.2f", secondConsensus.x, secondConsensus.y, secondConsensus.z)))")
            print("   Current positions: P1=(\(String(format: "%.2f, %.2f, %.2f", placedARPositions[0].x, placedARPositions[0].y, placedARPositions[0].z))), P2=(\(String(format: "%.2f, %.2f, %.2f", placedARPositions[1].x, placedARPositions[1].y, placedARPositions[1].z)))")
            
            // Calculate rigid body transform from historical to current coordinate frame
            if let transform = calculate2PointRigidTransform(
                oldPoints: (firstConsensus, secondConsensus),
                newPoints: (placedARPositions[0], placedARPositions[1])
            ) {
                // Verify transform quality before using it
                // Re-calculate verification error here to check threshold
                let cosR = cos(transform.rotationY)
                let sinR = sin(transform.rotationY)
                let rotatedOld1 = simd_float3(
                    secondConsensus.x * cosR - secondConsensus.z * sinR,
                    secondConsensus.y,
                    secondConsensus.x * sinR + secondConsensus.z * cosR
                )
                let transformedOld1 = rotatedOld1 + transform.translation
                let verificationError = simd_distance(transformedOld1, placedARPositions[1])
                
                // If verification error > 1.0m, consensus data is unreliable - fall back to map geometry
                if verificationError > 1.0 {
                    print("⚠️ [GHOST_3RD] Verification error \(String(format: "%.2f", verificationError))m exceeds 1.0m threshold")
                    print("   Historical consensus is unreliable - falling back to map geometry")
                    // Fall through to PRIORITY 2
                } else {
                    // Apply transform to third vertex's consensus position
                    let transformedPosition = applyRigidTransform(
                        position: consensus,
                        rotationY: transform.rotationY,
                        translation: transform.translation
                    )
                    
                    print("👻 [GHOST_3RD] Transformed consensus: (\(String(format: "%.2f", transformedPosition.x)), \(String(format: "%.2f", transformedPosition.y)), \(String(format: "%.2f", transformedPosition.z)))")
                    print("   Original consensus was: (\(String(format: "%.2f", consensus.x)), \(String(format: "%.2f", consensus.y)), \(String(format: "%.2f", consensus.z)))")
                    print("   Verification error: \(String(format: "%.3f", verificationError))m ✓")
                    
                    timingLog.append(("Consensus + transform", Date().timeIntervalSince(consensusStart)))
                    let totalMs = Date().timeIntervalSince(calcStart) * 1000
                    print("⏱️ [GHOST_3RD] Timing breakdown (total: \(String(format: "%.1f", totalMs))ms):")
                    for (label, duration) in timingLog {
                        print("   └─ \(label): \(String(format: "%.1f", duration * 1000))ms")
                    }
                    
                    return transformedPosition
                }
            } else {
                print("⚠️ [GHOST_3RD] Rigid transform failed - falling back to map geometry")
                // Fall through to PRIORITY 2
            }
        } else {
            // Log which consensus positions are missing
            if thirdMapPoint.consensusPosition == nil {
                print("📐 [GHOST_3RD] No consensus for 3rd vertex - using map geometry")
            } else if firstMapPoint.consensusPosition == nil || secondMapPoint.consensusPosition == nil {
                print("📐 [GHOST_3RD] Missing consensus for placed markers - using map geometry")
            }
            // Fall through to PRIORITY 2
        }
        
        // PRIORITY 2: Calculate from 2D map geometry using 2-point affine transformation
        print("📐 [GHOST_3RD] No consensus - calculating from 2D map geometry")
        
        // Get 2D map positions
        let map1 = simd_float2(Float(firstMapPoint.position.x), Float(firstMapPoint.position.y))
        let map2 = simd_float2(Float(secondMapPoint.position.x), Float(secondMapPoint.position.y))
        let map3 = simd_float2(Float(thirdMapPoint.position.x), Float(thirdMapPoint.position.y))
        
        // Get AR positions (XZ plane, Y is height)
        let ar1 = simd_float2(placedARPositions[0].x, placedARPositions[0].z)
        let ar2 = simd_float2(placedARPositions[1].x, placedARPositions[1].z)
        
        // Calculate map edge vector and AR edge vector
        let mapEdge = map2 - map1
        let arEdge = ar2 - ar1
        
        let mapEdgeLength = simd_length(mapEdge)
        let arEdgeLength = simd_length(arEdge)
        
        guard mapEdgeLength > 0.001, arEdgeLength > 0.001 else {
            print("⚠️ [GHOST_3RD] Degenerate edge - markers too close")
            return nil
        }
        
        // Calculate scale factor (AR meters per map pixel)
        let scale = arEdgeLength / mapEdgeLength
        
        // Calculate rotation angle between map and AR coordinate systems
        let mapAngle = atan2(mapEdge.y, mapEdge.x)
        let arAngle = atan2(arEdge.y, arEdge.x)
        let rotation = arAngle - mapAngle
        
        // Transform 3rd point: translate to origin, scale, rotate, translate to AR space
        let map3Relative = map3 - map1  // Relative to first point
        
        // Apply scale
        let scaled = map3Relative * scale
        
        // Apply rotation
        let cosR = cos(rotation)
        let sinR = sin(rotation)
        let rotated = simd_float2(
            scaled.x * cosR - scaled.y * sinR,
            scaled.x * sinR + scaled.y * cosR
        )
        
        // Translate to AR space (add first AR position)
        let ar3_2D = rotated + ar1
        
        // Use average Y height from placed markers
        let averageY = (placedARPositions[0].y + placedARPositions[1].y) / 2
        
        let ghostPosition = simd_float3(ar3_2D.x, averageY, ar3_2D.y)
        
        print("👻 [GHOST_3RD] Calculated from map: (\(String(format: "%.2f", ghostPosition.x)), \(String(format: "%.2f", ghostPosition.y)), \(String(format: "%.2f", ghostPosition.z)))")
        print("   Scale: \(String(format: "%.4f", scale)) AR meters per map pixel")
        print("   Rotation: \(String(format: "%.1f", rotation * 180 / .pi))°")
        
        timingLog.append(("2D geometry fallback", Date().timeIntervalSince(consensusStart)))
        let totalMs = Date().timeIntervalSince(calcStart) * 1000
        print("⏱️ [GHOST_3RD] Timing breakdown (total: \(String(format: "%.1f", totalMs))ms):")
        for (label, duration) in timingLog {
            print("   └─ \(label): \(String(format: "%.1f", duration * 1000))ms")
        }
        
        let calcDuration = Date().timeIntervalSince(calcStart) * 1000
        print("")
        print("╔════════════════════════════════════════════════════════════════════════╗")
        print("║ ⚠️  LEGACY/BARYCENTRIC PATH COMPLETED                                  ║")
        print("╠════════════════════════════════════════════════════════════════════════╣")
        print("║ Final position: (\(String(format: "%.2f", ghostPosition.x)), \(String(format: "%.2f", ghostPosition.y)), \(String(format: "%.2f", ghostPosition.z)))")
        print("║ Duration: \(String(format: "%.1f", calcDuration))ms")
        print("║")
        print("║ ⚡ NOTE: This position was NOT derived from baked canonical data.")
        print("║ Cross-session accuracy may be degraded.")
        print("╚════════════════════════════════════════════════════════════════════════╝")
        print("")
        
        return ghostPosition
    }
    
    /// Plant ghost markers for far vertices of triangles adjacent to the calibrated triangle
    private func plantGhostsForAdjacentTriangles(
        calibratedTriangle: TrianglePatch,
        triangleStore: TrianglePatchStore,
        mapPointStore: MapPointStore,
        arWorldMapStore: ARWorldMapStore
    ) {
        print("🔍 [PLANT_GHOSTS_DEBUG] Function called for triangle \(String(calibratedTriangle.id.uuidString.prefix(8)))")
        print("   Triangle vertices: \(calibratedTriangle.vertexIDs.map { String($0.uuidString.prefix(8)) })")
        
        print("🔍 [GHOST_PLANT] Finding adjacent triangles to \(String(calibratedTriangle.id.uuidString.prefix(8)))")
        
        // STEP 1: Find triangles sharing an edge with calibrated triangle (REUSE existing function)
        let adjacentTriangles = safeTriangleStore.findAdjacentTriangles(calibratedTriangle.id)
        
        print("🔍 [GHOST_PLANT] Found \(adjacentTriangles.count) adjacent triangle(s)")
        
        guard !adjacentTriangles.isEmpty else {
            print("ℹ️ [GHOST_PLANT] No adjacent triangles found - calibrated triangle may be isolated")
            return
        }
        
        // STEP 2: For each adjacent triangle, plant ghost at far vertex
        var ghostsPlanted = 0
        var skippedReasons: [(UUID, String)] = []  // Track why vertices were skipped
        
        for adjacentTriangle in adjacentTriangles {
            // Get the far vertex (REUSE existing function)
            guard let farVertexID = safeTriangleStore.getFarVertex(adjacentTriangle: adjacentTriangle, sourceTriangle: calibratedTriangle) else {
                skippedReasons.append((adjacentTriangle.id, "Could not determine far vertex"))
                print("⚠️ [GHOST_PLANT] Could not find far vertex for triangle \(String(adjacentTriangle.id.uuidString.prefix(8)))")
                continue
            }
            
            // Get MapPoint for far vertex
            guard let farVertexMapPoint = mapPointStore.points.first(where: { $0.id == farVertexID }) else {
                skippedReasons.append((farVertexID, "MapPoint not found in store"))
                print("⚠️ [GHOST_PLANT] Could not find MapPoint for far vertex \(String(farVertexID.uuidString.prefix(8)))")
                continue
            }
            
            // Skip if this ghost was already adjusted to an AR marker
            if adjustedGhostMapPoints.contains(farVertexID) {
                skippedReasons.append((farVertexID, "Already adjusted to AR marker"))
                print("👻 [GHOST_SKIP] Skipping \(String(farVertexID.uuidString.prefix(8))) — already adjusted to AR marker")
                continue
            }
            
            // Skip if this MapPoint already has an AR position established in the current session
            // Uses mapPointARPositions which is updated by BOTH calibration and crawl mode
            let hasPositionInCurrentSession = mapPointARPositions[farVertexID] != nil
            if hasPositionInCurrentSession {
                skippedReasons.append((farVertexID, "Already has AR position in mapPointARPositions"))
                print("⭐️ [GHOST_PLANT] Skipping MapPoint \(String(farVertexID.uuidString.prefix(8))) - already has AR position in current session")
                continue
            }
            
            // Calculate ghost position using barycentric interpolation
            let calcStart = Date()
            guard let ghostPosition = calculateGhostPosition(
                mapPoint: farVertexMapPoint,
                calibratedTriangleID: calibratedTriangle.id,
                triangleStore: triangleStore,
                mapPointStore: mapPointStore,
                arWorldMapStore: arWorldMapStore
            ) else {
                let calcDuration = Date().timeIntervalSince(calcStart) * 1000
                skippedReasons.append((farVertexID, "Ghost position calculation failed (\(String(format: "%.1f", calcDuration))ms)"))
                print("⚠️ [GHOST_PLANT] Could not calculate ghost position for MapPoint \(String(farVertexID.uuidString.prefix(8)))")
                continue
            }
            let calcDuration = Date().timeIntervalSince(calcStart) * 1000
            
            // Post notification to coordinator to render ghost
            let notifyStart = Date()
            NotificationCenter.default.post(
                name: NSNotification.Name("PlaceGhostMarker"),
                object: nil,
                userInfo: [
                    "mapPointID": farVertexID,
                    "position": ghostPosition
                ]
            )
            let notifyDuration = Date().timeIntervalSince(notifyStart) * 1000
            
            ghostsPlanted += 1
            print("👻 [GHOST_PLANT] Planted ghost for MapPoint \(String(farVertexID.uuidString.prefix(8))) at position \(ghostPosition)")
            print("   ⏱️ Calc: \(String(format: "%.1f", calcDuration))ms | Notify: \(String(format: "%.1f", notifyDuration))ms")
        }
        
        print("✅ [GHOST_PLANT] Planted \(ghostsPlanted) ghost marker(s), skipped \(skippedReasons.count)")
        if !skippedReasons.isEmpty {
            print("   Skipped vertices:")
            for (id, reason) in skippedReasons {
                print("   • \(String(id.uuidString.prefix(8))): \(reason)")
            }
        }
    }
    
    // MARK: - Generalized Ghost Planting
    
    /// Defines the scope for ghost marker planting
    enum GhostPlantingScope {
        /// Plant ghosts for far vertices of triangles adjacent to the calibrated triangle
        case adjacentToTriangle(TrianglePatch)
        
        /// Plant ghosts for ALL triangle vertices in the store
        case allTriangles
    }
    
    /// Build the set of candidate vertex IDs for ghost planting based on scope
    /// - Parameters:
    ///   - scope: The scope defining which vertices to consider
    ///   - triangleStore: The store containing all triangle patches
    /// - Returns: Set of MapPoint IDs that are candidates for ghost markers
    private func buildGhostCandidateVertices(
        scope: GhostPlantingScope,
        triangleStore: TrianglePatchStore
    ) -> Set<UUID> {
        
        switch scope {
        case .adjacentToTriangle(let calibratedTriangle):
            // Find far vertices of adjacent triangles
            var candidates = Set<UUID>()
            let adjacentTriangles = safeTriangleStore.findAdjacentTriangles(calibratedTriangle.id)
            
            print("🔍 [GHOST_CANDIDATES] Building candidates for adjacent triangles")
            print("   Source triangle: \(String(calibratedTriangle.id.uuidString.prefix(8)))")
            print("   Found \(adjacentTriangles.count) adjacent triangle(s)")
            
            for adjacent in adjacentTriangles {
                if let farVertexID = safeTriangleStore.getFarVertex(
                    adjacentTriangle: adjacent,
                    sourceTriangle: calibratedTriangle
                ) {
                    candidates.insert(farVertexID)
                    print("   + Far vertex \(String(farVertexID.uuidString.prefix(8))) from triangle \(String(adjacent.id.uuidString.prefix(8)))")
                }
            }
            
            print("   Total candidates: \(candidates.count)")
            return candidates
            
        case .allTriangles:
            // Collect ALL vertices from ALL triangles
            var candidates = Set<UUID>()
            
            print("🔍 [GHOST_CANDIDATES] Building candidates for ALL triangles")
            print("   Total triangles in store: \(triangleStore.triangles.count)")
            
            for triangle in triangleStore.triangles {
                for vertexID in triangle.vertexIDs {
                    candidates.insert(vertexID)
                }
            }
            
            print("   Total unique vertices: \(candidates.count)")
            return candidates
        }
    }
    
    /// Plant ghost markers for vertices based on the specified scope
    /// FUTURE: Swaths will be user-defined collections of triangle patches.
    /// This function will eventually support a .swathTriangles(Set<UUID>) scope
    /// for planting ghosts only within a selected swath region.
    ///
    /// - Parameters:
    ///   - scope: Defines which vertices to consider for ghost planting
    ///   - referenceTriangle: A calibrated triangle with known AR positions (used for ghost position calculation)
    ///   - triangleStore: The store containing all triangle patches
    ///   - mapPointStore: The store containing all map points
    ///   - arWorldMapStore: The AR world map store
    public func plantGhostsForScope(
        scope: GhostPlantingScope,
        referenceTriangle: TrianglePatch,
        triangleStore: TrianglePatchStore,
        mapPointStore: MapPointStore,
        arWorldMapStore: ARWorldMapStore
    ) {
        let scopeDescription: String
        switch scope {
        case .adjacentToTriangle(let tri):
            scopeDescription = "adjacent to \(String(tri.id.uuidString.prefix(8)))"
        case .allTriangles:
            scopeDescription = "all triangles"
        }
        
        print("👻 [PLANT_SCOPE] BEGIN: Planting ghosts for scope: \(scopeDescription)")
        print("   Reference triangle: \(String(referenceTriangle.id.uuidString.prefix(8)))")
        
        // STEP 1: Build candidate vertices based on scope
        let candidates = buildGhostCandidateVertices(scope: scope, triangleStore: triangleStore)
        
        guard !candidates.isEmpty else {
            print("ℹ️ [PLANT_SCOPE] No candidate vertices found")
            return
        }
        
        // STEP 2: Filter candidates
        var ghostsPlanted = 0
        var skippedHasPosition = 0
        var skippedNoMapPoint = 0
        var skippedCalcFailed = 0
        
        for vertexID in candidates {
            // Skip if this ghost was already adjusted to an AR marker
            if adjustedGhostMapPoints.contains(vertexID) {
                print("👻 [GHOST_SKIP] Skipping \(String(vertexID.uuidString.prefix(8))) — already adjusted to AR marker")
                skippedHasPosition += 1
                continue
            }
            
            // Skip if already has AR position in current session
            if mapPointARPositions[vertexID] != nil {
                skippedHasPosition += 1
                continue
            }
            
            // Get the MapPoint
            guard let mapPoint = mapPointStore.points.first(where: { $0.id == vertexID }) else {
                skippedNoMapPoint += 1
                print("⚠️ [PLANT_SCOPE] MapPoint not found for vertex \(String(vertexID.uuidString.prefix(8)))")
                continue
            }
            
            // STEP 3: Calculate ghost position
            // Uses the reference triangle for barycentric/session-transform calculation
            guard let ghostPosition = calculateGhostPosition(
                mapPoint: mapPoint,
                calibratedTriangleID: referenceTriangle.id,
                triangleStore: triangleStore,
                mapPointStore: mapPointStore,
                arWorldMapStore: arWorldMapStore
            ) else {
                skippedCalcFailed += 1
                continue
            }
            
            // STEP 4: Post notification to render ghost
            NotificationCenter.default.post(
                name: NSNotification.Name("PlaceGhostMarker"),
                object: nil,
                userInfo: [
                    "mapPointID": vertexID,
                    "position": ghostPosition
                ]
            )
            
            ghostsPlanted += 1
            print("👻 [PLANT_SCOPE] Planted ghost for \(String(vertexID.uuidString.prefix(8)))")
        }
        
        print("👻 [PLANT_SCOPE] COMPLETE:")
        print("   Planted: \(ghostsPlanted)")
        print("   Skipped (has session pos): \(skippedHasPosition)")
        print("   Skipped (no MapPoint): \(skippedNoMapPoint)")
        print("   Skipped (calc failed): \(skippedCalcFailed)")
    }
    
    /// Check if the active triangle has all 3 markers placed (calibration complete)
    func isTriangleComplete(_ triangleID: UUID) -> Bool {
        guard let triangle = safeTriangleStore.triangle(withID: triangleID) else { return false }
        return placedMarkers.count == 3 && triangle.vertexIDs.allSatisfy { placedMarkers.contains($0) }
    }
    
    /// Check if a triangle has baked canonical positions for all 3 vertices
    public func triangleHasBakedVertices(_ triangleID: UUID) -> Bool {
        guard let triangle = safeTriangleStore.triangle(withID: triangleID),
              triangle.vertexIDs.count == 3 else {
            return false
        }
        
        for vertexID in triangle.vertexIDs {
            guard let mapPoint = safeMapStore.points.first(where: { $0.id == vertexID }),
                  mapPoint.canonicalPosition != nil else {
                return false
            }
        }
        return true
    }
    
    /// Check if a triangle can be filled with survey markers
    /// Returns true if all 3 vertices have EITHER:
    /// - A current session position (from mapPointARPositions), OR
    /// - A baked position that can be projected to session
    /// This is the correct check for Fill Triangle button visibility
    public func triangleCanBeFilled(_ triangleID: UUID) -> Bool {
        guard hasValidSessionTransform,
              let triangle = safeTriangleStore.triangle(withID: triangleID),
              triangle.vertexIDs.count == 3 else {
            return false
        }
        
        for vertexID in triangle.vertexIDs {
            // Check if vertex has current session position
            if mapPointARPositions[vertexID] != nil {
                continue // This vertex is covered
            }
            
            // Check if vertex has baked position
            guard let mapPoint = safeMapStore.points.first(where: { $0.id == vertexID }),
                  mapPoint.canonicalPosition != nil else {
                return false // No position source for this vertex
            }
        }
        return true
    }
    
    /// Count how many triangles can currently be filled (all 3 vertices have positions)
    func countFillableTriangles() -> Int {
        return getFillableTriangleIDs().count
    }
    
    /// Get IDs of all triangles that can be filled (all 3 vertices have known positions)
    /// A vertex has a known position if it's in mapPointARPositions (session), ghostMarkerPositions, or has baked data
    func getFillableTriangleIDs() -> [UUID] {
        let triangleStore = triangleStoreAccess
        
        var fillable: [UUID] = []
        
        for triangle in triangleStore.triangles {
            if triangleCanBeFilled(triangle.id) {
                fillable.append(triangle.id)
            }
        }
        
        return fillable
    }
    
    /// Get IDs of triangles fillable using ONLY session markers and ghost markers (not baked data)
    /// This is for "Fill Known" - triangles where you can see vertices in AR
    func getFillableTriangleIDsSessionAndGhost() -> [UUID] {
        let triangleStore = triangleStoreAccess
        
        var fillable: [UUID] = []
        
        for triangle in triangleStore.triangles {
            var allVerticesHavePosition = true
            
            for vertexID in triangle.vertexIDs {
                // Check session position (AR marker placed this session)
                let hasSessionPosition = mapPointARPositions[vertexID] != nil
                
                // Check ghost position (ghost marker currently rendered)
                // We need to check ghostMarkerPositions which is on ARViewContainer
                // For now, check if coordinator has tracked this via calibration
                let hasGhostPosition = ghostMarkerPositions[vertexID] != nil
                
                if !hasSessionPosition && !hasGhostPosition {
                    allVerticesHavePosition = false
                    break
                }
            }
            
            if allVerticesHavePosition {
                fillable.append(triangle.id)
            }
        }
        
        return fillable
    }
    
    /// Count triangles fillable using session+ghost only
    func countFillableTrianglesSessionAndGhost() -> Int {
        return getFillableTriangleIDsSessionAndGhost().count
    }
    
    /// Get IDs of ALL triangles that can be filled using baked data
    /// This is for "Fill Map" - uses historical calibration data
    func getFillableTriangleIDsBaked() -> [UUID] {
        let triangleStore = triangleStoreAccess
        let mapPointStore = safeMapStore
        
        var fillable: [UUID] = []
        
        for triangle in triangleStore.triangles {
            var allVerticesHaveBaked = true
            
            for vertexID in triangle.vertexIDs {
                if let mapPoint = mapPointStore.points.first(where: { $0.id == vertexID }),
                   mapPoint.canonicalPosition != nil {
                    // Has baked data
                } else {
                    allVerticesHaveBaked = false
                    break
                }
            }
            
            if allVerticesHaveBaked {
                fillable.append(triangle.id)
            }
        }
        
        return fillable
    }
    
    /// Count triangles fillable using baked data
    func countFillableTrianglesBaked() -> Int {
        return getFillableTriangleIDsBaked().count
    }
    
    /// Check if session has a valid canonical→session transform
    public var hasValidSessionTransform: Bool {
        return cachedCanonicalToSessionTransform != nil
    }
    
    /// Project a baked canonical position to current session AR space
    /// Returns nil if no valid transform is cached
    public func projectBakedToSession(_ bakedPosition: SIMD3<Float>) -> SIMD3<Float>? {
        guard let transform = cachedCanonicalToSessionTransform else {
            return nil
        }
        
        // The transform stores canonical→session parameters
        // Apply inverse of the apply() method: scale, rotate, translate
        let cosR = cos(transform.rotationY)
        let sinR = sin(transform.rotationY)
        let scale = transform.scale
        
        // Apply scale first
        let scaled = bakedPosition * scale
        
        // Apply rotation around Y axis (inverse direction)
        let rotated = SIMD3<Float>(
            scaled.x * cosR - scaled.z * sinR,
            scaled.y,
            scaled.x * sinR + scaled.z * cosR
        )
        
        // Apply translation
        return rotated + transform.translation
    }
    
    /// Projects an AR session position to map pixel coordinates using the global session transform
    /// This is less accurate than barycentric interpolation but works outside calibrated triangles
    /// - Parameter sessionPosition: Position in AR session coordinates
    /// - Returns: Map pixel coordinate, or nil if transform not available
    public func projectSessionToMap(_ sessionPosition: SIMD3<Float>) -> CGPoint? {
        guard let transform = cachedCanonicalToSessionTransform,
              let mapSize = cachedMapSize,
              let metersPerPixel = cachedMetersPerPixel else {
            print("⚠️ [PROJECT_SESSION_TO_MAP] Missing transform or map parameters")
            return nil
        }
        
        let pixelsPerMeter = 1.0 / metersPerPixel
        let canonicalOrigin = CGPoint(x: mapSize.width / 2, y: mapSize.height / 2)
        
        // Inverse transform: session → canonical
        // The cached transform is canonical→session, so we invert it
        let inverseRotation = -transform.rotationY
        let inverseScale = 1.0 / transform.scale
        
        // Remove translation, then rotate, then scale
        let translated = sessionPosition - transform.translation
        let cosR = cos(inverseRotation)
        let sinR = sin(inverseRotation)
        let rotated = SIMD3<Float>(
            translated.x * cosR - translated.z * sinR,
            translated.y,
            translated.x * sinR + translated.z * cosR
        )
        let canonicalPosition = rotated * inverseScale
        
        // Canonical → Map pixels
        let mapX = CGFloat(canonicalPosition.x * pixelsPerMeter) + canonicalOrigin.x
        let mapY = CGFloat(canonicalPosition.z * pixelsPerMeter) + canonicalOrigin.y
        
        return CGPoint(x: mapX, y: mapY)
    }
    
    /// Get session-space AR positions for a triangle's vertices using baked data
    /// Returns nil if transform not available or vertices don't have baked positions
    public func getTriangleVertexPositionsFromBaked(_ triangleID: UUID) -> [UUID: SIMD3<Float>]? {
        guard hasValidSessionTransform,
              let triangle = safeTriangleStore.triangle(withID: triangleID),
              triangle.vertexIDs.count == 3 else {
            return nil
        }
        
        var positions: [UUID: SIMD3<Float>] = [:]
        
        for vertexID in triangle.vertexIDs {
            // First check if we have a session-planted position
            if let sessionPos = mapPointARPositions[vertexID] {
                positions[vertexID] = sessionPos
                continue
            }
            
            // Fall back to baked position projected to session
            guard let mapPoint = safeMapStore.points.first(where: { $0.id == vertexID }),
                  let bakedPos = mapPoint.canonicalPosition,
                  let sessionPos = projectBakedToSession(bakedPos) else {
                return nil // Missing data for this vertex
            }
            positions[vertexID] = sessionPos
        }
        
        return positions.count == 3 ? positions : nil
    }
    
    private func updateProgressDots() {
        // SWATH SURVEY MODE: Use triangleVertices (anchor IDs) instead of triangle
        if activeTriangleID == nil && !triangleVertices.isEmpty {
            var states = [false, false, false]
            for (index, vertexID) in triangleVertices.enumerated() {
                if index < 3 {
                    states[index] = placedMarkers.contains(vertexID)
                }
            }
            progressDots = (states[0], states[1], states[2])
            return
        }
        
        // TRIANGLE CALIBRATION MODE: Use active triangle vertices
        guard let triangleID = activeTriangleID,
              let triangle = safeTriangleStore.triangle(withID: triangleID) else {
            progressDots = (false, false, false)
            return
        }
        
        var states = [false, false, false]
        for (index, vertexID) in triangle.vertexIDs.enumerated() {
            if index < 3 {
                states[index] = placedMarkers.contains(vertexID)
            }
        }
        progressDots = (states[0], states[1], states[2])
    }
    
    private func finalizeCalibration(for triangle: TrianglePatch) {
        let quality = computeCalibrationQuality(triangle)
        safeTriangleStore.markCalibrated(triangle.id, quality: quality)
        
        // Record which vertex was the starting anchor for next session's rotation
        if let originalIndex = triangle.vertexIDs.firstIndex(of: triangleVertices[0]) {
            safeTriangleStore.setLastStartingVertexIndex(triangle.id, index: originalIndex)
            print("🔄 [VERTEX_ROTATION] Saved starting index \(originalIndex) for next session")
        }
        
        // Add to session calibrated triangles for crawl mode
        sessionCalibratedTriangles.insert(triangle.id)
        print("📍 [SESSION_CALIBRATED] Added triangle \(String(triangle.id.uuidString.prefix(8))) to session set")
        print("   Session now has \(sessionCalibratedTriangles.count) calibrated triangle(s)")
        
        // Verify triangle state
        if let updatedTriangle = safeTriangleStore.triangle(withID: triangle.id) {
            print("🔍 Triangle \(String(triangle.id.uuidString.prefix(8))) state after marking:")
            print("   isCalibrated: \(updatedTriangle.isCalibrated)")
            print("   arMarkerIDs count: \(updatedTriangle.arMarkerIDs.count)")
            print("   arMarkerIDs: \(updatedTriangle.arMarkerIDs.map { String($0.prefix(8)) })")
        } else {
            print("⚠️ Could not retrieve triangle after marking as calibrated")
        }
        
        statusText = ""
        
        print("🎉 ARCalibrationCoordinator: Triangle \(String(triangle.id.uuidString.prefix(8))) calibration complete (quality: \(Int(quality * 100))%)")
        
        // Save ARWorldMap for this triangle
        saveWorldMapForTriangle(triangle)
        
        // Post completion notification
        NotificationCenter.default.post(
            name: NSNotification.Name("TriangleCalibrationComplete"),
            object: nil,
            userInfo: ["triangleID": triangle.id]
        )
        
        // Re-fetch triangle to get absolutely latest state with all 3 marker IDs
        guard let freshTriangle = safeTriangleStore.triangles.first(where: { $0.id == triangle.id }) else {
            print("⚠️ [FINALIZE] Could not re-fetch triangle for ghost planting")
            currentVertexIndex = 0
            return
        }
        print("🔍 [FINALIZE] Fresh triangle for ghost planting - arMarkerIDs: \(freshTriangle.arMarkerIDs)")
        
        // Plant ghost markers for adjacent triangles
        plantGhostsForAdjacentTriangles(
            calibratedTriangle: freshTriangle,
            triangleStore: safeTriangleStore,
            mapPointStore: safeMapStore,
            arWorldMapStore: safeARStore
        )
        
        // Reset index for next calibration
        currentVertexIndex = 0
        print("🔄 Reset currentVertexIndex to 0 for next calibration")
        
        // Don't auto-start next triangle - let user decide
        print("✅ Calibration complete. Ghost markers planted for adjacent triangles.")
        
        // DEBUG: Manual bake-down trigger - remove after testing
        // To test: complete a calibration crawl and check console for bake-down output
        #if DEBUG
        print("\n🧪 [DEBUG] To manually trigger bake-down, call:")
        print("   calibrationCoordinator.bakeDownCalibrationSession(mapSize: mapSize, metersPerPixel: metersPerPixel)")
        print("   where mapSize and metersPerPixel come from your map context")
        #endif
    }
    
    /// Transitions from readyToFill to surveyMode when Fill Triangle is tapped
    func enterSurveyMode() {
        guard calibrationState == .readyToFill else {
            print("⚠️ Cannot enter survey mode - not in readyToFill state (current: \(stateDescription))")
            return
        }
        
        calibrationState = .surveyMode
        print("🎯 CalibrationState → \(stateDescription)")
    }
    
    public func exitSurveyMode() {
        guard case .surveyMode = calibrationState else {
            print("⚠️ [EXIT_SURVEY] Not in survey mode, current state: \(stateDescription)")
            return
        }
        calibrationState = .readyToFill
        print("🎯 CalibrationState → Ready to Fill (exited survey mode)")
    }
    
    /// Transition to readyToFill state and create ghosts for adjacent triangles
    /// Called after GENERIC_ADJUST to continue the calibration crawl
    public func transitionToReadyToFillAndRefreshGhosts(placedMapPointID: UUID) {
        print("🔄 [REFRESH_GHOSTS] Starting adjacent triangle discovery for MapPoint \(String(placedMapPointID.uuidString.prefix(8)))")
        
        // Find triangles that contain this vertex
        let containingTriangles = safeTriangleStore.triangles.filter { triangle in
            triangle.vertexIDs.contains(placedMapPointID)
        }
        
        print("   Found \(containingTriangles.count) triangle(s) containing this vertex")
        
        // Track how many triangles we process
        var processedCount = 0
        
        // Process ALL adjacent triangles, not just "best candidate"
        for triangle in containingTriangles {
            // Count how many vertices have positions in this session
            let plantedCount = triangle.vertexIDs.filter { mapPointARPositions[$0] != nil }.count
            
            // Skip if already fully planted (3 vertices)
            guard plantedCount < 3 else {
                print("   Triangle \(String(triangle.id.uuidString.prefix(8))): Already fully planted, skipping")
                continue
            }
            
            // Skip if already in sessionCalibratedTriangles
            guard !sessionCalibratedTriangles.contains(triangle.id) else {
                print("   Triangle \(String(triangle.id.uuidString.prefix(8))): Already calibrated this session, skipping")
                continue
            }
            
            print("   Processing Triangle \(String(triangle.id.uuidString.prefix(8))) with \(plantedCount) vertices planted")
            
            // Post notification to create ghosts for unplanted vertices of THIS triangle
            NotificationCenter.default.post(
                name: NSNotification.Name("RefreshAdjacentGhosts"),
                object: nil,
                userInfo: [
                    "triangleID": triangle.id,
                    "placedMapPointID": placedMapPointID
                ]
            )
            
            processedCount += 1
        }
        
        print("👻 [REFRESH_GHOSTS] Processed \(processedCount) adjacent triangle(s)")
        
        // Transition to readyToFill state
        calibrationState = .readyToFill
        print("🎯 CalibrationState → Ready to Fill (from ghost refresh)")
    }
    
    var stateDescription: String {
        switch calibrationState {
        case .idle:
            return "Idle"
        case .placingVertices(let index):
            return "Placing Vertices (index: \(index))"
        case .readyToFill:
            return "Ready to Fill"
        case .surveyMode:
            return "Survey Mode"
        }
    }
    
    /// Returns true if calibration state allows crawl mode continuation
    /// Crawl mode works in both .readyToFill and .surveyMode states
    /// - .readyToFill: Triangle calibrated, awaiting fill or crawl
    /// - .surveyMode: Triangle calibrated with survey markers, crawl can continue
    /// - .placingVertices: Still placing vertices, not eligible
    /// - .idle: No active calibration, not eligible
    var isCrawlEligibleState: Bool {
        switch calibrationState {
        case .readyToFill, .surveyMode:
            return true
        case .placingVertices, .idle:
            return false
        }
    }
    
    /// Save ARWorldMap after successful triangle calibration
    private func saveWorldMapForTriangle(_ triangle: TrianglePatch) {
        // Get the current ARViewCoordinator to access the session
        guard let coordinator = ARViewContainer.Coordinator.current else {
            print("⚠️ Cannot save world map: No ARViewCoordinator available")
            return
        }
        
        // Get the current world map from the AR session
        coordinator.getCurrentWorldMap { [weak self] map, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Failed to get current world map: \(error.localizedDescription)")
                return
            }
            
            guard let worldMap = map else {
                print("⚠️ No world map available to save")
                return
            }
            
            // Calculate center point from triangle vertices
            let vertexIDs = triangle.vertexIDs
            let mapPoints = vertexIDs.compactMap { vertexID in
                self.safeMapStore.points.first(where: { $0.id == vertexID })
            }
            
            guard mapPoints.count == 3 else {
                print("⚠️ Cannot compute center: Only found \(mapPoints.count)/3 MapPoints")
                return
            }
            
            // Calculate center as average of vertex positions
            let centerX = mapPoints.map { $0.mapPoint.x }.reduce(0, +) / CGFloat(mapPoints.count)
            let centerY = mapPoints.map { $0.mapPoint.y }.reduce(0, +) / CGFloat(mapPoints.count)
            let center2D = CGPoint(x: centerX, y: centerY)
            
            // Estimate radius from triangle vertices (max distance from center)
            let maxDistance = mapPoints.map { point in
                let dx = point.mapPoint.x - centerX
                let dy = point.mapPoint.y - centerY
                return sqrt(dx * dx + dy * dy)
            }.max() ?? 0
            
            // Convert pixels to meters (rough estimate)
            guard let pxPerMeter = self.getPixelsPerMeter(), pxPerMeter > 0 else {
                print("⚠️ Cannot convert radius: pxPerMeter not available")
                return
            }
            let radiusM = Float(maxDistance) / pxPerMeter
            
            // Create patch metadata (savePatch will handle archiving and byteSize calculation)
            let featureCount = worldMap.rawFeaturePoints.points.count
            let patchMeta = WorldMapPatchMeta(
                id: triangle.id,  // Use triangle ID as patch ID
                name: "Triangle \(String(triangle.id.uuidString.prefix(8)))",
                captureDate: Date(),
                featureCount: featureCount,
                byteSize: 0,  // savePatch will calculate this internally
                center2D: center2D,
                radiusM: radiusM,
                version: 1
            )
            
            // Save the patch to strategy-specific folder (WorldMap strategy)
            do {
                let strategyID = "worldmap"
                let strategyDisplayName = "ARWorldMap"
                try self.safeARStore.savePatchForStrategy(worldMap, triangleID: triangle.id, strategyID: strategyID)
                
                // Store filename in triangle (format: "{triangleID}.armap")
                let filename = "\(triangle.id.uuidString).armap"
                
                // Update legacy worldMapFilename for backward compatibility
                self.safeTriangleStore.setWorldMapFilename(for: triangle.id, filename: filename)
                
                // Update worldMapFilesByStrategy dictionary
                self.safeTriangleStore.setWorldMapFilename(for: triangle.id, strategyName: strategyDisplayName, filename: filename)
                
                print("✅ Saved ARWorldMap for triangle \(String(triangle.id.uuidString.prefix(8)))")
                print("   Strategy: \(strategyID) (\(strategyDisplayName))")
                print("   Features: \(featureCount)")
                print("   Center: (\(Int(center2D.x)), \(Int(center2D.y)))")
                print("   Radius: \(String(format: "%.2f", radiusM))m")
                print("   Filename: \(filename)")
            } catch {
                print("❌ Failed to save world map patch: \(error)")
            }
        }
    }
    
    /// Find an adjacent uncalibrated triangle to suggest for calibration crawling
    private func findAdjacentUncalibratedTriangle(to triangleID: UUID, userMapPosition: CGPoint?) -> TrianglePatch? {
        guard let triangle = safeTriangleStore.triangle(withID: triangleID) else {
            return nil
        }
        
        // Get all adjacent uncalibrated triangles (share an edge = 2 vertices)
        let adjacentCandidates = safeTriangleStore.findAdjacentTriangles(triangleID)
            .filter { !$0.isCalibrated }
        
        guard !adjacentCandidates.isEmpty else {
            print("🔍 No uncalibrated adjacent triangles found")
            return nil
        }
        
        // If we don't have user position, just return first candidate
        guard let userPos = userMapPosition else {
            print("⚠️ User position unavailable, returning first adjacent triangle")
            return adjacentCandidates.first
        }
        
        // Find closest triangle based on distance to its "far vertex"
        let closestTriangle = adjacentCandidates.min { candidateA, candidateB in
            guard let farVertexA = safeTriangleStore.getFarVertex(adjacentTriangle: candidateA, sourceTriangle: triangle),
                  let farVertexB = safeTriangleStore.getFarVertex(adjacentTriangle: candidateB, sourceTriangle: triangle),
                  let pointA = safeMapStore.points.first(where: { $0.id == farVertexA }),
                  let pointB = safeMapStore.points.first(where: { $0.id == farVertexB }) else {
                return false
            }
            
            let distA = distance(userPos, pointA.mapPoint)
            let distB = distance(userPos, pointB.mapPoint)
            
            return distA < distB
        }
        
        if let next = closestTriangle,
           let farVertex = safeTriangleStore.getFarVertex(adjacentTriangle: next, sourceTriangle: triangle),
           let farPoint = safeMapStore.points.first(where: { $0.id == farVertex }) {
            let dist = distance(userPos, farPoint.mapPoint)
            print("📍 Selected nearest triangle (far vertex distance: \(Int(dist))px)")
        }
        
        return closestTriangle
    }
    
    // Helper: Calculate 2D distance
    private func distance(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        let dx = p1.x - p2.x
        let dy = p1.y - p2.y
        return sqrt(dx * dx + dy * dy)
    }
    
    // MARK: - DEPRECATED
    /// DO NOT USE - Calls deprecated addGhostMarker() with broken logic.
    /// Use ARViewContainer.Coordinator.plantGhostMarkers(calibratedTriangle:, triangleStore:, filter:) instead.
    func plantGhostMarkers(using calibratedTriangle: TrianglePatch) {
        print("⚠️ [DEPRECATED] Function \(#function) was called. Refactor needed.")
        if let symbol = Thread.callStackSymbols.dropFirst(1).first {
            print("🔍 Called by: \(symbol)")
        }
        return
        
        /* OLD LOGIC COMMENTED OUT
        guard let coordinator = ARViewContainer.Coordinator.current else {
            print("⚠️ Cannot plant ghost markers: No ARViewCoordinator available")
            return
        }
        
        // Get all map point IDs that already have markers (from placedMarkers array)
        let alreadyPlacedIDs = Set(placedMarkers)
        
        // Get all remaining map points that don't have markers
        let remainingPoints = safeMapStore.points.filter { !alreadyPlacedIDs.contains($0.id) }
        
        guard !remainingPoints.isEmpty else {
            print("ℹ️ No remaining map points to plant ghost markers for")
            return
        }
        
        print("👻 Planting ghost markers for \(remainingPoints.count) remaining map points...")
        
        // Plant ghost marker for each remaining point
        for point in remainingPoints {
            coordinator.addGhostMarker(
                mapPointID: point.id,
                mapPoint: point.mapPoint,
                using: calibratedTriangle
            )
        }
        
        print("✅ Ghost marker planting complete")
        */ // END OLD LOGIC
    }
    
    private func computeCalibrationQuality(_ triangle: TrianglePatch) -> Float {
        guard triangle.arMarkerIDs.count == 3 else {
            print("⚠️ Cannot compute quality: Need 3 AR marker IDs")
            return 0.0
        }
        
        // Load AR markers from ARWorldMapStore
        let arMarkers = triangle.arMarkerIDs.compactMap { markerIDString -> ARWorldMapStore.ARMarker? in
            guard let markerUUID = UUID(uuidString: markerIDString) else { return nil }
            return safeARStore.marker(withID: markerUUID)
        }
        
        guard arMarkers.count == 3 else {
            print("⚠️ Cannot compute quality: Only found \(arMarkers.count)/3 AR markers")
            return 0.0
        }
        
        // Get MapPoints for the 3 vertices
        let vertexIDs = triangle.vertexIDs
        let mapPoints = vertexIDs.compactMap { vertexID in
            safeMapStore.points.first(where: { $0.id == vertexID })
        }
        
        guard mapPoints.count == 3 else {
            print("⚠️ Cannot compute quality: Only found \(mapPoints.count)/3 MapPoints")
            return 0.0
        }
        
        // Define triangle legs: (0,1), (1,2), (2,0)
        let legs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        var measurements: [TriangleLegMeasurement] = []
        
        for (i, j) in legs {
            // Get 2D map positions
            let mapA = mapPoints[i].mapPoint
            let mapB = mapPoints[j].mapPoint
            
            // Get 3D AR positions from transform matrices
            let arTransformA = arMarkers[i].worldTransform.toSimd()
            let arTransformB = arMarkers[j].worldTransform.toSimd()
            
            let arA = simd_float3(arTransformA.columns.3.x, arTransformA.columns.3.y, arTransformA.columns.3.z)
            let arB = simd_float3(arTransformB.columns.3.x, arTransformB.columns.3.y, arTransformB.columns.3.z)
            
            // Calculate distances
            // Map distance is in pixels - convert to meters using pxPerMeter
            let mapDistPixels = simd_distance(
                simd_float2(Float(mapA.x), Float(mapA.y)),
                simd_float2(Float(mapB.x), Float(mapB.y))
            )
            
            // Convert pixels to meters
            guard let pxPerMeter = getPixelsPerMeter(), pxPerMeter > 0 else {
                print("⚠️ Cannot convert map distance: pxPerMeter not available")
                return 0.0
            }
            
            let mapDist = mapDistPixels / pxPerMeter  // Now in meters
            let arDist = simd_distance(arA, arB)  // Already in meters
            
            // Create measurement
            let measurement = TriangleLegMeasurement(
                vertexA: vertexIDs[i],
                vertexB: vertexIDs[j],
                mapDistance: mapDist,
                arDistance: arDist
            )
            measurements.append(measurement)
            
            print("   Leg \(i)-\(j): Map=\(String(format: "%.3f", mapDist))m, AR=\(String(format: "%.3f", arDist))m, Ratio=\(String(format: "%.3f", measurement.distortionRatio))")
        }
        
        // Compute quality: average of normalized distortion ratios
        // Quality is higher when ratios are closer to 1.0 (perfect match)
        let distortionScores = measurements.map { measurement -> Float in
            let ratio = measurement.distortionRatio
            // Normalize: ratio of 1.0 = perfect (score 1.0), ratios further from 1.0 = lower score
            // Use min(ratio, 1/ratio) to handle both >1 and <1 cases symmetrically
            return min(ratio, 1.0 / ratio)
        }
        
        let quality = distortionScores.reduce(0, +) / Float(distortionScores.count)
        
        // Store measurements in triangle
        safeTriangleStore.setLegMeasurements(for: triangle.id, measurements: measurements)
        
        print("📊 Calibration quality computed: \(String(format: "%.2f", quality)) (avg distortion score)")
        
        return quality
    }
    
    /// Override a blocked placement - records with low confidence
    func overrideBlockedPlacement() {
        guard let blocked = blockedPlacement else {
            print("⚠️ [OVERRIDE] No blocked placement to override")
            return
        }
        
        print("⚠️ [OVERRIDE] User overriding blocked placement for \(String(blocked.mapPointID.uuidString.prefix(8)))")
        print("   Distance from ghost: \(String(format: "%.2f", blocked.distance))m")
        
        // Clear blocked state
        let marker = blocked.marker
        let mapPointID = blocked.mapPointID
        blockedPlacement = nil
        
        // Remove ghost marker from scene
        if let coordinator = ARViewContainer.Coordinator.current {
            coordinator.removeGhostMarker(mapPointID: mapPointID)
        }
        
        // Save marker to ARWorldMapStore
        do {
            let worldMapMarker = convertToWorldMapMarker(marker)
            try safeARStore.saveMarker(worldMapMarker)
            
            sessionMarkerPositions[marker.id.uuidString] = marker.arPosition
            
            // Record with LOW confidence (0.1) so consensus ignores this outlier
            let record = ARPositionRecord(
                position: marker.arPosition,
                sessionID: safeARStore.currentSessionID,
                sourceType: .calibration,
                distortionVector: marker.arPosition - blocked.ghostPosition,
                confidenceScore: 0.1  // LOW confidence for override
            )
            safeMapStore.addPositionRecord(mapPointID: mapPointID, record: record)
            print("📍 [OVERRIDE] Recorded with confidence 0.1 (outlier)")
            
        } catch {
            print("❌ [OVERRIDE] Failed to save marker: \(error)")
            return
        }
        
        // Update triangle with marker ID
        guard let triangleID = activeTriangleID else { return }
        safeTriangleStore.addMarkerToTriangle(
            triangleID: triangleID,
            vertexMapPointID: mapPointID,
            markerID: marker.id
        )
        
        // Continue normal flow
        placedMarkers.append(mapPointID)
        updateProgressDots()
        
        let count = placedMarkers.count
        statusText = "Place AR markers for triangle (\(count)/3)"
        
        print("✅ [OVERRIDE] Marker registered for MapPoint \(String(mapPointID.uuidString.prefix(8))) (\(count)/3)")
        
        if placedMarkers.count == 3 {
            if let triangle = safeTriangleStore.triangle(withID: triangleID) {
                finalizeCalibration(for: triangle)
            }
            calibrationState = .readyToFill
            print("🎯 CalibrationState → \(stateDescription)")
        }
    }
    
    /// Cancel blocked placement - user will re-place marker
    func cancelBlockedPlacement() {
        guard blockedPlacement != nil else { return }
        print("🔄 [CANCEL] User cancelling blocked placement - will re-place")
        blockedPlacement = nil
        
        // Dismiss warning UI via notification
        NotificationCenter.default.post(
            name: NSNotification.Name("PlacementBlockedDismissed"),
            object: nil
        )
    }
    
    func reset() {
        // Clear any existing survey markers and calibration markers
        if let coordinator = ARViewContainer.Coordinator.current {
            coordinator.clearSurveyMarkers()
            coordinator.clearCalibrationMarkers()  // Clear AR marker nodes from scene
        }
        
        activeTriangleID = nil
        currentTriangleID = nil
        placedMarkers = []
        sessionCalibratedTriangles = []
        sessionMarkerPositions = [:]  // Clear current session marker positions
        mapPointARPositions = [:]  // Clear MapPoint position cache
        statusText = ""
        progressDots = (false, false, false)
        isActive = false
        currentVertexIndex = 0
        triangleVertices = []
        referencePhotoData = nil
        completedMarkerCount = 0
        lastPrintedVertexIndex = nil  // Reset print tracking
        calibrationState = .idle
        selectedGhostMapPointID = nil
        selectedGhostEstimatedPosition = nil
        nearbyButNotVisibleGhostID = nil
        demotedGhostMapPointIDs.removeAll()
        adjustedGhostMapPoints.removeAll()
        repositionModeActive = false
        
        // Clear baked data transform cache
        cachedCanonicalToSessionTransform = nil
        cachedMapSize = nil
        cachedMetersPerPixel = nil
        
        print("🎯 CalibrationState → \(stateDescription) (reset)")
        print("🔄 ARCalibrationCoordinator: Reset complete - all markers cleared")
    }
    
    /// Records session as completed if any calibration work occurred
    /// Call this BEFORE reset() when AR view is dismissed normally
    public func recordSessionCompletion() {
        let triangleCount = sessionCalibratedTriangles.count
        let mapPointCount = mapPointARPositions.count
        
        guard triangleCount > 0 || mapPointCount > 0 else {
            print("📍 [SESSION_END] No calibration work to record")
            return
        }
        
        safeARStore.endSession(
            trianglesCalibratedCount: triangleCount,
            mapPointsPlacedCount: mapPointCount,
            exitReason: .completed
        )
    }
    
    /// Activates calibration for an adjacent triangle when user confirms a ghost marker
    /// Pre-populates shared edge vertices from session cache and registers the ghost position
    /// - Parameters:
    ///   - ghostMapPointID: The MapPoint ID of the confirmed ghost
    ///   - ghostPosition: The AR position where the ghost was confirmed/placed
    ///   - currentTriangleID: The triangle we just finished calibrating
    /// - Returns: The ID of the newly activated adjacent triangle, or nil if activation failed
    /// Activates calibration for an adjacent triangle when user confirms/adjusts a ghost marker.
    /// Pre-populates shared edge vertices from session cache, registers the ghost position,
    /// and records the position to arPositionHistory for future ghost prediction improvement.
    /// - Parameters:
    ///   - ghostMapPointID: The MapPoint ID of the confirmed/adjusted ghost
    ///   - ghostPosition: The AR position where the marker was placed (ghost position or crosshair)
    ///   - currentTriangleID: The triangle we just finished calibrating
    ///   - wasAdjusted: True if user placed marker at crosshair (adjusted), false if confirmed at ghost position
    /// - Returns: The ID of the newly activated adjacent triangle, or nil if activation failed
    func activateAdjacentTriangle(
        ghostMapPointID: UUID,
        ghostPosition: simd_float3,
        currentTriangleID: UUID,
        wasAdjusted: Bool = false
    ) -> UUID? {
        print("🔍 [ACTIVATE_ADJACENT_DEBUG] Function called with:")
        print("   ghostMapPointID: \(String(ghostMapPointID.uuidString.prefix(8)))")
        print("   currentTriangleID: \(String(currentTriangleID.uuidString.prefix(8)))")
        print("   wasAdjusted: \(wasAdjusted)")
        
        print("🔗 [ADJACENT_ACTIVATE] Starting adjacent triangle activation")
        print("   Ghost MapPoint: \(String(ghostMapPointID.uuidString.prefix(8)))")
        print("   Ghost Position: (\(String(format: "%.2f", ghostPosition.x)), \(String(format: "%.2f", ghostPosition.y)), \(String(format: "%.2f", ghostPosition.z)))")
        print("   Current Triangle: \(String(currentTriangleID.uuidString.prefix(8)))")
        print("   Was Adjusted: \(wasAdjusted)")
        
        // Find all triangles containing this ghost MapPoint
        let trianglesWithGhost = safeTriangleStore.triangles.filter { triangle in
            triangle.vertexIDs.contains(ghostMapPointID)
        }
        
        print("   Triangles containing ghost: \(trianglesWithGhost.map { String($0.id.uuidString.prefix(8)) })")
        
        // Find adjacent triangle - must share exactly 2 vertices with ANY calibrated triangle from this session
        // This allows crawling in any direction (forward or backtracking)
        var adjacentTriangle: TrianglePatch? = nil
        var sharedVertexIDs: [UUID] = []
        var sourceTriangle: TrianglePatch? = nil  // The calibrated triangle we're adjacent to
        
        // Get all calibrated triangles from this session
        let calibratedTriangles = safeTriangleStore.triangles.filter { sessionCalibratedTriangles.contains($0.id) }
        print("   Session calibrated triangles: \(calibratedTriangles.map { String($0.id.uuidString.prefix(8)) })")
        
        for candidate in trianglesWithGhost {
            // Skip triangles already calibrated this session
            guard !sessionCalibratedTriangles.contains(candidate.id) else { continue }
            
            // Check if this candidate shares exactly 2 vertices with ANY calibrated triangle
            for calibrated in calibratedTriangles {
                let shared = candidate.vertexIDs.filter { calibrated.vertexIDs.contains($0) }
                if shared.count == 2 {
                    adjacentTriangle = candidate
                    sharedVertexIDs = shared
                    sourceTriangle = calibrated
                    print("   Found adjacent: \(String(candidate.id.uuidString.prefix(8))) shares edge with \(String(calibrated.id.uuidString.prefix(8)))")
                    break
                }
            }
            if adjacentTriangle != nil { break }
        }
        
        guard let adjacentTriangle = adjacentTriangle,
              let sourceTriangle = sourceTriangle else {
            print("⚠️ [ADJACENT_ACTIVATE] No uncalibrated triangle shares 2 vertices with any calibrated triangle")
            return nil
        }
        
        print("   Adjacent Triangle: \(String(adjacentTriangle.id.uuidString.prefix(8)))")
        print("   Adjacent vertices: \(adjacentTriangle.vertexIDs.map { String($0.uuidString.prefix(8)) })")
        print("   Shared vertices: \(sharedVertexIDs.map { String($0.uuidString.prefix(8)) })")
        print("   Source (calibrated) triangle: \(String(sourceTriangle.id.uuidString.prefix(8)))")
        
        // Verify we have AR positions for both shared vertices in session cache
        var sharedPositions: [(UUID, simd_float3)] = []
        for vertexID in sharedVertexIDs {
            guard let position = mapPointARPositions[vertexID] else {
                print("⚠️ [ADJACENT_ACTIVATE] Missing AR position for shared vertex \(String(vertexID.uuidString.prefix(8)))")
                return nil
            }
            sharedPositions.append((vertexID, position))
            print("   Shared vertex \(String(vertexID.uuidString.prefix(8))) at AR(\(String(format: "%.2f", position.x)), \(String(format: "%.2f", position.y)), \(String(format: "%.2f", position.z)))")
        }
        
        // Order vertices: shared edge first (indices 0, 1), then ghost (index 2)
        // Match the order in adjacentTriangle.vertexIDs
        var orderedVertexIDs: [UUID] = []
        var orderedPositions: [simd_float3] = []
        
        for vertexID in adjacentTriangle.vertexIDs {
            if vertexID == ghostMapPointID {
                orderedVertexIDs.append(vertexID)
                orderedPositions.append(ghostPosition)
            } else if let sharedPos = sharedPositions.first(where: { $0.0 == vertexID }) {
                orderedVertexIDs.append(vertexID)
                orderedPositions.append(sharedPos.1)
            }
        }
        
        guard orderedVertexIDs.count == 3 else {
            print("⚠️ [ADJACENT_ACTIVATE] Failed to order all 3 vertices")
            return nil
        }
        
        print("🔗 [ADJACENT_ACTIVATE] Ordered vertices for adjacent triangle:")
        for (i, (id, pos)) in zip(orderedVertexIDs, orderedPositions).enumerated() {
            print("   [\(i)] \(String(id.uuidString.prefix(8))) at AR(\(String(format: "%.2f", pos.x)), \(String(format: "%.2f", pos.y)), \(String(format: "%.2f", pos.z)))")
        }
        
        // Task 7: Adjustment diagnostics
        if wasAdjusted {
            // Get the ghost's estimated position before adjustment
            if let originalGhostPos = selectedGhostEstimatedPosition {
                let delta = ghostPosition - originalGhostPos
                print("✏️ [ADJUSTMENT] User adjusted ghost position:")
                print("   Ghost was at:  (\(String(format: "%.3f", originalGhostPos.x)), \(String(format: "%.3f", originalGhostPos.y)), \(String(format: "%.3f", originalGhostPos.z)))")
                print("   User placed:   (\(String(format: "%.3f", ghostPosition.x)), \(String(format: "%.3f", ghostPosition.y)), \(String(format: "%.3f", ghostPosition.z)))")
                print("   Delta (X,Z):   (\(String(format: "%.3f", delta.x)), \(String(format: "%.3f", delta.z)))")
                print("   Distance:      \(String(format: "%.3f", simd_length(delta)))m")
                let angle = atan2(delta.z, delta.x) * 180 / .pi
                print("   Direction:     \(String(format: "%.1f", angle))° (0°=East, 90°=South)")
            }
        }
        
        // Record position to MapPoint's arPositionHistory for future ghost prediction improvement
        // Confirmed positions get higher confidence than adjusted ones
        let confidence: Float = wasAdjusted ? 0.90 : 0.95
        let sourceType: SourceType = .calibration
        
        let positionRecord = ARPositionRecord(
            position: ghostPosition,
            sessionID: safeARStore.currentSessionID,
            sourceType: sourceType,
            confidenceScore: confidence
        )
        safeMapStore.addPositionRecord(mapPointID: ghostMapPointID, record: positionRecord)
        
        // MILESTONE 5: Update baked position incrementally
        updateBakedPositionIncrementally(
            mapPointID: ghostMapPointID,
            sessionPosition: ghostPosition,
            confidence: confidence
        )
        
        let adjustmentNote = wasAdjusted ? "(adjusted)" : "(confirmed)"
        print("📍 [POSITION_HISTORY] crawl \(adjustmentNote) → MapPoint \(String(ghostMapPointID.uuidString.prefix(8)))")
        print("   ↳ pos: (\(String(format: "%.2f", ghostPosition.x)), \(String(format: "%.2f", ghostPosition.y)), \(String(format: "%.2f", ghostPosition.z))) confidence: \(confidence)")
        
        // Add current triangle to session calibrated set before switching
        sessionCalibratedTriangles.insert(currentTriangleID)
        print("✅ [ADJACENT_ACTIVATE] Added \(String(currentTriangleID.uuidString.prefix(8))) to sessionCalibratedTriangles (now \(sessionCalibratedTriangles.count) triangle(s))")
        
        // Start calibration on adjacent triangle
        activeTriangleID = adjacentTriangle.id
        self.currentTriangleID = adjacentTriangle.id
        triangleVertices = orderedVertexIDs
        
        // Register all three vertices with their positions
        for (vertexID, position) in zip(orderedVertexIDs, orderedPositions) {
            mapPointARPositions[vertexID] = position
            if !placedMarkers.contains(vertexID) {
                placedMarkers.append(vertexID)
            }
        }
        
        // Store all 3 vertex positions in mapPointARPositions for future ghost calculations
        // (This is already done above, but adding explicit logging for clarity)
        print("📍 [ADJACENT_ACTIVATE] Stored all 3 vertex positions in mapPointARPositions:")
        for (index, vertexID) in orderedVertexIDs.enumerated() {
            print("   [\(index)] Vertex \(String(vertexID.uuidString.prefix(8))) at position (\(String(format: "%.2f", orderedPositions[index].x)), \(String(format: "%.2f", orderedPositions[index].y)), \(String(format: "%.2f", orderedPositions[index].z)))")
        }
        
        // Set state to readyToFill since all 3 vertices are now calibrated
        calibrationState = .readyToFill
        
        // Add adjacent triangle to session calibrated set
        sessionCalibratedTriangles.insert(adjacentTriangle.id)
        print("✅ [ADJACENT_ACTIVATE] Added \(String(adjacentTriangle.id.uuidString.prefix(8))) to sessionCalibratedTriangles (now \(sessionCalibratedTriangles.count) triangle(s))")
        
        // CRITICAL: Persist calibration to storage (mirrors finalizeCalibration behavior)
        safeTriangleStore.markCalibrated(adjacentTriangle.id, quality: 1.0)
        print("💾 [ADJACENT_ACTIVATE] Persisted calibration for triangle \(String(adjacentTriangle.id.uuidString.prefix(8)))")
        
        // Update status
        statusText = ""
        progressDots = (true, true, true)
        
        // Clear ghost selection state
        selectedGhostMapPointID = nil
        selectedGhostEstimatedPosition = nil
        
        print("✅ [ADJACENT_ACTIVATE] Adjacent triangle \(String(adjacentTriangle.id.uuidString.prefix(8))) now calibrated and ready to fill")
        
        // Plant ghost markers for the newly activated triangle's uncalibrated adjacent triangles
        // This enables continuous crawling across the mesh
        print("🔗 [ADJACENT_ACTIVATE] Planting ghosts for newly activated triangle's neighbors")
        if let freshTriangle = safeTriangleStore.triangle(withID: adjacentTriangle.id) {
            plantGhostsForAdjacentTriangles(
                calibratedTriangle: freshTriangle,
                triangleStore: safeTriangleStore,
                mapPointStore: safeMapStore,
                arWorldMapStore: safeARStore
            )
        }
        
        return adjacentTriangle.id
    }
    
    /// Updates ghost selection based on user proximity
    /// - Parameters:
    ///   - cameraPosition: Current AR camera position
    ///   - ghostPositions: Dictionary of mapPointID → estimated ghost position
    ///   - proximityThreshold: Distance in meters to trigger selection (default 2.0m, horizontal distance only)
    /// Update ghost selection based on proximity and visibility
    /// - Parameters:
    ///   - cameraPosition: Current camera position in AR world
    ///   - ghostPositions: Dictionary of ghost MapPoint IDs to their AR positions
    ///   - visibleGhostIDs: Set of ghost IDs that are currently visible in camera view (optional, defaults to all visible)
    func updateGhostSelection(
        cameraPosition: simd_float3,
        ghostPositions: [UUID: simd_float3],
        visibleGhostIDs: Set<UUID>? = nil
    ) {
        // If in reposition mode, preserve the current selection
        // User can walk away from ghost but it stays "selected" until they place a marker
        if repositionModeActive {
            return
        }
        
        let proximityThreshold: Float = 2.0
        
        // Ghost selection now works in ANY state to allow interaction anytime
        // The UI (shouldShowGhostButtons) will show buttons when a ghost is selected
        
        // Find closest ghost within threshold
        var closestID: UUID? = nil
        var closestDistance: Float = Float.greatestFiniteMagnitude
        
        for (ghostID, ghostPosition) in ghostPositions {
            // Use horizontal distance only (ignore Y)
            let dx = ghostPosition.x - cameraPosition.x
            let dz = ghostPosition.z - cameraPosition.z
            let horizontalDistance = sqrt(dx * dx + dz * dz)
            
            if horizontalDistance < proximityThreshold && horizontalDistance < closestDistance {
                closestDistance = horizontalDistance
                closestID = ghostID
            }
        }
        
        // Determine if closest ghost is visible
        let isVisible: Bool
        if let closestID = closestID {
            // If visibleGhostIDs is provided, check if ghost is in set
            // If nil (legacy behavior), assume visible
            isVisible = visibleGhostIDs?.contains(closestID) ?? true
        } else {
            isVisible = false
        }
        
        // Update state based on proximity and visibility
        if let closestID = closestID {
            if isVisible {
                // Ghost is nearby AND visible → select it
                if selectedGhostMapPointID != closestID {
                    print("👻 [GHOST_SELECT] Selected ghost \(String(closestID.uuidString.prefix(8))) at \(String(format: "%.2f", closestDistance))m")
                    
                    // Notify PiP map to center on this ghost
                    NotificationCenter.default.post(
                        name: NSNotification.Name("CenterPiPOnMapPoint"),
                        object: nil,
                        userInfo: ["mapPointID": closestID]
                    )
                }
                selectedGhostMapPointID = closestID
                selectedGhostEstimatedPosition = ghostPositions[closestID]
                nearbyButNotVisibleGhostID = nil
            } else {
                // Ghost is nearby but NOT visible → show message instead
                if nearbyButNotVisibleGhostID != closestID {
                    print("👻 [GHOST_NEARBY] Ghost \(String(closestID.uuidString.prefix(8))) is \(String(format: "%.2f", closestDistance))m away but not in camera view")
                }
                selectedGhostMapPointID = nil
                selectedGhostEstimatedPosition = nil
                nearbyButNotVisibleGhostID = closestID
            }
        } else {
            // No ghost nearby
            if selectedGhostMapPointID != nil {
                print("👻 [GHOST_SELECT] Deselected ghost - moved out of range")
            }
            if nearbyButNotVisibleGhostID != nil {
                print("👻 [GHOST_NEARBY] No longer near any ghost")
            }
            selectedGhostMapPointID = nil
            selectedGhostEstimatedPosition = nil
            nearbyButNotVisibleGhostID = nil
        }
    }
    
    // MARK: - Helper: Convert ARMarker to ARWorldMapStore.ARMarker
    
    private func convertToWorldMapMarker(_ marker: ARMarker) -> ARWorldMapStore.ARMarker {
        // Convert UUID to String for ARWorldMapStore format
        let markerIDString = marker.id.uuidString
        let mapPointIDString = marker.linkedMapPointID.uuidString
        
        // Convert simd_float3 position to transform matrix (identity rotation, translation from position)
        let transform = simd_float4x4(
            SIMD4<Float>(1, 0, 0, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(0, 0, 1, 0),
            SIMD4<Float>(marker.arPosition.x, marker.arPosition.y, marker.arPosition.z, 1)
        )
        
        let codableTransform = ARWorldMapStore.CodableTransform(from: transform)
        
        // Include session tracking for relocalization prep
        return ARWorldMapStore.ARMarker(
            id: markerIDString,
            mapPointID: mapPointIDString,
            worldTransform: codableTransform,
            createdAt: marker.createdAt,
            observations: nil,
            sessionID: safeARStore.currentSessionID,
            sessionTimestamp: safeARStore.currentSessionStartTime
        )
    }
    
    // MARK: - Bake-Down System (Milestone 5)
    
    /// Computes the transform from current AR session to canonical frame
    /// using two correspondence points (planted markers)
    ///
    /// - Parameters:
    ///   - marker1MapPosition: First marker's position in map pixels
    ///   - marker1ARPosition: First marker's position in current AR session
    ///   - marker2MapPosition: Second marker's position in map pixels
    ///   - marker2ARPosition: Second marker's position in current AR session
    ///   - canonicalFrame: The canonical frame to transform into
    /// - Returns: Transform from session to canonical, or nil if computation fails
    private func computeSessionToCanonicalTransform(
        marker1MapPosition: CGPoint,
        marker1ARPosition: SIMD3<Float>,
        marker2MapPosition: CGPoint,
        marker2ARPosition: SIMD3<Float>,
        canonicalFrame: CanonicalFrame
    ) -> SessionToCanonicalTransform? {
        
        // Convert map positions to canonical 3D positions
        let canonical1 = canonicalFrame.mapToCanonical(marker1MapPosition)
        let canonical2 = canonicalFrame.mapToCanonical(marker2MapPosition)
        
        // Calculate edge vectors in both coordinate systems (XZ plane only)
        let canonicalEdge = SIMD2<Float>(canonical2.x - canonical1.x, canonical2.z - canonical1.z)
        let sessionEdge = SIMD2<Float>(marker2ARPosition.x - marker1ARPosition.x, marker2ARPosition.z - marker1ARPosition.z)
        
        let canonicalLength = simd_length(canonicalEdge)
        let sessionLength = simd_length(sessionEdge)
        
        guard canonicalLength > 0.001, sessionLength > 0.001 else {
            print("⚠️ [BAKE_TRANSFORM] Degenerate edge - markers too close")
            return nil
        }
        
        // Calculate scale: canonical meters per session meter
        // (canonical frame uses real-world scale derived from MetricSquare)
        let scale = canonicalLength / sessionLength
        
        // Calculate rotation: angle from session edge to canonical edge
        let canonicalAngle = atan2(canonicalEdge.y, canonicalEdge.x)
        let sessionAngle = atan2(sessionEdge.y, sessionEdge.x)
        let rotation = canonicalAngle - sessionAngle
        
        // Calculate translation: where session origin lands in canonical space
        // First, rotate and scale the session position of marker 1
        let cosR = cos(rotation)
        let sinR = sin(rotation)
        let scaledSession1 = marker1ARPosition * scale
        let rotatedSession1 = SIMD3<Float>(
            scaledSession1.x * cosR - scaledSession1.z * sinR,
            scaledSession1.y,
            scaledSession1.x * sinR + scaledSession1.z * cosR
        )
        
        // Translation = canonical position - transformed session position
        let translation = canonical1 - rotatedSession1
        
        print("📐 [BAKE_TRANSFORM] Computed session→canonical transform:")
        print("   Scale: \(String(format: "%.4f", scale)) (canonical/session)")
        print("   Rotation: \(String(format: "%.1f", rotation * 180 / .pi))°")
        print("   Translation: (\(String(format: "%.2f", translation.x)), \(String(format: "%.2f", translation.y)), \(String(format: "%.2f", translation.z)))")
        
        return SessionToCanonicalTransform(rotationY: rotation, translation: translation, scale: scale)
    }
    
    /// Sets map parameters needed for baked data transforms
    /// Call this when calibration starts, before any markers are placed
    ///
    /// - Parameters:
    ///   - mapSize: Size of the map image in pixels
    ///   - metersPerPixel: Scale factor (meters per pixel) from MetricSquare calibration
    public func setMapParametersForBakedData(mapSize: CGSize, metersPerPixel: Float) {
        self.cachedMapSize = mapSize
        self.cachedMetersPerPixel = metersPerPixel
        print("📐 [MAP_PARAMS] Cached map parameters for baked data:")
        print("   Map size: \(Int(mapSize.width)) × \(Int(mapSize.height)) pixels")
        print("   Scale: \(String(format: "%.4f", metersPerPixel)) meters/pixel")
    }
    
    /// Computes and caches the transform from canonical frame to current AR session
    /// Call this after 2 markers are planted to enable fast ghost placement
    ///
    /// - Parameters:
    ///   - mapSize: Size of the map image in pixels
    ///   - metersPerPixel: Scale factor from MetricSquare calibration
    /// - Returns: true if transform was computed successfully
    @discardableResult
    func computeSessionTransformForBakedData(mapSize: CGSize, metersPerPixel: Float) -> Bool {
        print("")
        print("┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓")
        print("┃ 🔄 SESSION TRANSFORM COMPUTATION                                      ┃")
        print("┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫")
        print("┃ Input parameters:")
        print("┃   mapSize: \(Int(mapSize.width))×\(Int(mapSize.height)) pixels")
        print("┃   metersPerPixel: \(String(format: "%.4f", metersPerPixel))")
        print("┃   placedMarkers count: \(placedMarkers.count)")
        print("┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛")
        print("📐 [SESSION_TRANSFORM] Computing canonical↔session transform...")
        
        // Cache parameters for later use
        cachedMapSize = mapSize
        cachedMetersPerPixel = metersPerPixel
        
        // Need at least 2 planted markers
        guard placedMarkers.count >= 2 else {
            print("⚠️ [SESSION_TRANSFORM] Need 2+ markers, have \(placedMarkers.count)")
            return false
        }
        
        let marker1ID = placedMarkers[0]
        let marker2ID = placedMarkers[1]
        
        guard let marker1MapPoint = safeMapStore.points.first(where: { $0.id == marker1ID }),
              let marker2MapPoint = safeMapStore.points.first(where: { $0.id == marker2ID }),
              let marker1AR = mapPointARPositions[marker1ID],
              let marker2AR = mapPointARPositions[marker2ID] else {
            print("⚠️ [SESSION_TRANSFORM] Could not find marker data")
            return false
        }
        
        // Create canonical frame
        let pixelsPerMeter = 1.0 / metersPerPixel
        let canonicalOrigin = CGPoint(x: mapSize.width / 2, y: mapSize.height / 2)
        let floorHeight: Float = -1.1
        
        // Convert map positions to canonical
        let marker1Canonical = SIMD3<Float>(
            Float(marker1MapPoint.position.x - canonicalOrigin.x) / pixelsPerMeter,
            floorHeight,
            Float(marker1MapPoint.position.y - canonicalOrigin.y) / pixelsPerMeter
        )
        let marker2Canonical = SIMD3<Float>(
            Float(marker2MapPoint.position.x - canonicalOrigin.x) / pixelsPerMeter,
            floorHeight,
            Float(marker2MapPoint.position.y - canonicalOrigin.y) / pixelsPerMeter
        )
        
        // Compute canonical→session transform (INVERSE of session→canonical)
        // Edge vectors
        let canonicalEdge = SIMD2<Float>(marker2Canonical.x - marker1Canonical.x, marker2Canonical.z - marker1Canonical.z)
        let sessionEdge = SIMD2<Float>(marker2AR.x - marker1AR.x, marker2AR.z - marker1AR.z)
        
        let canonicalLength = simd_length(canonicalEdge)
        let sessionLength = simd_length(sessionEdge)
        
        guard canonicalLength > 0.001, sessionLength > 0.001 else {
            print("⚠️ [SESSION_TRANSFORM] Degenerate edge")
            return false
        }
        
        // Scale: session meters per canonical meter (inverse of bake-down scale)
        let scale = sessionLength / canonicalLength
        
        // Rotation: angle from canonical edge to session edge (inverse direction)
        let canonicalAngle = atan2(canonicalEdge.y, canonicalEdge.x)
        let sessionAngle = atan2(sessionEdge.y, sessionEdge.x)
        let rotation = sessionAngle - canonicalAngle  // Note: reversed from bake-down
        
        // Translation: compute where canonical origin maps to in session space
        let cosR = cos(rotation)
        let sinR = sin(rotation)
        let scaledCanonical1 = marker1Canonical * scale
        let rotatedCanonical1 = SIMD3<Float>(
            scaledCanonical1.x * cosR - scaledCanonical1.z * sinR,
            scaledCanonical1.y,
            scaledCanonical1.x * sinR + scaledCanonical1.z * cosR
        )
        let translation = marker1AR - rotatedCanonical1
        
        // Create and cache the transform
        cachedCanonicalToSessionTransform = SessionToCanonicalTransform(
            rotationY: rotation,
            translation: translation,
            scale: scale
        )
        
        // Verify with second marker
        let transformedMarker2 = cachedCanonicalToSessionTransform!.apply(to: marker2Canonical)
        let verificationError = simd_distance(transformedMarker2, marker2AR)
        
        print("📐 [SESSION_TRANSFORM] Cached canonical→session transform:")
        print("   Scale: \(String(format: "%.4f", scale)) (session/canonical)")
        print("   Rotation: \(String(format: "%.1f", rotation * 180 / .pi))°")
        print("   Translation: (\(String(format: "%.2f", translation.x)), \(String(format: "%.2f", translation.y)), \(String(format: "%.2f", translation.z)))")
        print("   ✅ Verification error: \(String(format: "%.3f", verificationError))m")
        
        // Count how many triangles are now fillable via baked data
        let fillableCount = safeTriangleStore.triangles.filter { triangleHasBakedVertices($0.id) }.count
        print("📐 [SESSION_TRANSFORM] \(fillableCount) triangle(s) now fillable via baked data")
        
        return true
    }
    
    /// Bakes down the current calibration session's position data into canonical positions
    ///
    /// This should be called at the end of a successful calibration crawl.
    /// It transforms all touched MapPoint positions from session coordinates
    /// to canonical coordinates and updates their baked consensus.
    ///
    /// - Parameters:
    ///   - mapSize: Size of the map image in pixels
    ///   - metersPerPixel: Scale factor from MetricSquare calibration
    /// - Returns: Number of MapPoints updated, or nil if bake-down failed
    func bakeDownCalibrationSession(mapSize: CGSize, metersPerPixel: Float) -> Int? {
        print("\n" + String(repeating: "=", count: 60))
        print("🔥 [BAKE_DOWN] Starting calibration bake-down")
        print(String(repeating: "=", count: 60))
        
        // Create canonical frame
        let canonicalFrame = CanonicalFrame.fromMapContext(mapSize: mapSize, metersPerPixel: metersPerPixel)
        print("📐 [BAKE_DOWN] Canonical frame:")
        print("   Origin: (\(Int(canonicalFrame.originMapCoordinate.x)), \(Int(canonicalFrame.originMapCoordinate.y))) pixels (map center)")
        print("   Scale: \(String(format: "%.1f", canonicalFrame.pixelsPerMeter)) pixels/meter")
        
        // We need at least 2 planted markers to compute the transform
        guard placedMarkers.count >= 2 else {
            print("⚠️ [BAKE_DOWN] Need at least 2 planted markers, have \(placedMarkers.count)")
            return nil
        }
        
        // Get the first two planted markers for transform computation
        let marker1ID = placedMarkers[0]
        let marker2ID = placedMarkers[1]
        
        // Find their MapPoints and AR positions
        guard let marker1MapPoint = safeMapStore.points.first(where: { $0.id == marker1ID }),
              let marker2MapPoint = safeMapStore.points.first(where: { $0.id == marker2ID }),
              let marker1ARPos = mapPointARPositions[marker1ID],
              let marker2ARPos = mapPointARPositions[marker2ID] else {
            print("⚠️ [BAKE_DOWN] Could not find marker data for transform computation")
            return nil
        }
        
        print("📍 [BAKE_DOWN] Using markers for transform:")
        print("   Marker 1: \(String(marker1ID.uuidString.prefix(8))) map=(\(Int(marker1MapPoint.position.x)), \(Int(marker1MapPoint.position.y))) AR=(\(String(format: "%.2f", marker1ARPos.x)), \(String(format: "%.2f", marker1ARPos.y)), \(String(format: "%.2f", marker1ARPos.z)))")
        print("   Marker 2: \(String(marker2ID.uuidString.prefix(8))) map=(\(Int(marker2MapPoint.position.x)), \(Int(marker2MapPoint.position.y))) AR=(\(String(format: "%.2f", marker2ARPos.x)), \(String(format: "%.2f", marker2ARPos.y)), \(String(format: "%.2f", marker2ARPos.z)))")
        
        // Compute session→canonical transform
        guard let transform = computeSessionToCanonicalTransform(
            marker1MapPosition: marker1MapPoint.position,
            marker1ARPosition: marker1ARPos,
            marker2MapPosition: marker2MapPoint.position,
            marker2ARPosition: marker2ARPos,
            canonicalFrame: canonicalFrame
        ) else {
            print("⚠️ [BAKE_DOWN] Failed to compute transform")
            return nil
        }
        
        // Verify transform by checking marker 2
        let transformedMarker2 = transform.apply(to: marker2ARPos)
        let expectedCanonical2 = canonicalFrame.mapToCanonical(marker2MapPoint.position)
        let verificationError = simd_distance(transformedMarker2, expectedCanonical2)
        print("✅ [BAKE_DOWN] Transform verification error: \(String(format: "%.3f", verificationError))m")
        
        if verificationError > 0.1 {
            print("⚠️ [BAKE_DOWN] Verification error exceeds 0.1m threshold - transform may be unreliable")
        }
        
        // Now transform all touched MapPoints and update their baked positions
        var updatedCount = 0
        
        print("\n📦 [BAKE_DOWN] Processing \(mapPointARPositions.count) MapPoint(s)...")
        
        for (mapPointID, sessionARPosition) in mapPointARPositions {
            guard let index = safeMapStore.points.firstIndex(where: { $0.id == mapPointID }) else {
                print("   ⚠️ \(String(mapPointID.uuidString.prefix(8))): MapPoint not found in store")
                continue
            }
            
            // Transform session position to canonical
            let canonicalPosition = transform.apply(to: sessionARPosition)
            
            // Get current baked state
            let currentBaked = safeMapStore.points[index].canonicalPosition
            let currentConfidence = safeMapStore.points[index].canonicalConfidence ?? 0
            let currentSampleCount = safeMapStore.points[index].canonicalSampleCount
            
            // Determine confidence for this session's data
            // Use the confidence from position history if available, otherwise default to 0.9
            let sessionConfidence: Float
            if let latestRecord = safeMapStore.points[index].arPositionHistory.last,
               latestRecord.sessionID == safeARStore.currentSessionID {
                sessionConfidence = latestRecord.confidenceScore
            } else {
                sessionConfidence = 0.9  // Default for calibration
            }
            
            // Calculate new baked position as weighted average
            let newBakedPosition: SIMD3<Float>
            let newConfidence: Float
            let newSampleCount: Int
            
            if let existing = currentBaked, currentSampleCount > 0 {
                // Blend with existing: weighted by (confidence × sampleCount) vs new confidence
                let existingWeight = currentConfidence * Float(currentSampleCount)
                let newWeight = sessionConfidence
                let totalWeight = existingWeight + newWeight
                
                newBakedPosition = (existing * existingWeight + canonicalPosition * newWeight) / totalWeight
                newConfidence = totalWeight / Float(currentSampleCount + 1)  // Average confidence
                newSampleCount = currentSampleCount + 1
                
                let delta = simd_distance(existing, newBakedPosition)
                print("   ✅ \(String(mapPointID.uuidString.prefix(8))): blended (Δ=\(String(format: "%.3f", delta))m) → (\(String(format: "%.2f", newBakedPosition.x)), \(String(format: "%.2f", newBakedPosition.y)), \(String(format: "%.2f", newBakedPosition.z))) [samples: \(newSampleCount)]")
            } else {
                // First bake for this MapPoint
                newBakedPosition = canonicalPosition
                newConfidence = sessionConfidence
                newSampleCount = 1
                
                print("   ✅ \(String(mapPointID.uuidString.prefix(8))): NEW → (\(String(format: "%.2f", newBakedPosition.x)), \(String(format: "%.2f", newBakedPosition.y)), \(String(format: "%.2f", newBakedPosition.z))) [samples: 1]")
            }
            
            // Update the MapPoint
            safeMapStore.points[index].canonicalPosition = newBakedPosition
            safeMapStore.points[index].canonicalConfidence = newConfidence
            safeMapStore.points[index].canonicalSampleCount = newSampleCount
            
            updatedCount += 1
        }
        
        // Save changes
        safeMapStore.save()
        
        print("\n" + String(repeating: "=", count: 60))
        print("🔥 [BAKE_DOWN] Complete: \(updatedCount) MapPoint(s) updated")
        print(String(repeating: "=", count: 60) + "\n")
        
        return updatedCount
    }
    
    /// Updates a MapPoint's baked position incrementally when user confirms or adjusts ghost
    /// This keeps baked data fresh without requiring a full re-bake
    ///
    /// - Parameters:
    ///   - mapPointID: The MapPoint to update
    ///   - sessionPosition: The confirmed/adjusted position in current session coordinates
    ///   - confidence: Confidence score for this sample (0.95 for confirm, 0.90 for adjust)
    func updateBakedPositionIncrementally(
        mapPointID: UUID,
        sessionPosition: SIMD3<Float>,
        confidence: Float
    ) {
        guard let transform = cachedCanonicalToSessionTransform,
              let mapSize = cachedMapSize,
              let metersPerPixel = cachedMetersPerPixel else {
            print("⚠️ [BAKE_UPDATE] No cached transform - cannot update baked position")
            return
        }
        
        guard let index = safeMapStore.points.firstIndex(where: { $0.id == mapPointID }) else {
            print("⚠️ [BAKE_UPDATE] MapPoint \(String(mapPointID.uuidString.prefix(8))) not found")
            return
        }
        
        // Compute inverse transform: session → canonical
        // The cached transform is canonical→session, so we need to invert it
        let inverseRotation = -transform.rotationY
        let inverseScale = 1.0 / transform.scale
        
        // Invert: first remove translation, then rotate, then scale
        let translated = sessionPosition - transform.translation
        let cosR = cos(inverseRotation)
        let sinR = sin(inverseRotation)
        let rotated = SIMD3<Float>(
            translated.x * cosR - translated.z * sinR,
            translated.y,
            translated.x * sinR + translated.z * cosR
        )
        let canonicalPosition = rotated * inverseScale
        
        // Get current baked state
        let currentBaked = safeMapStore.points[index].canonicalPosition
        let currentConfidence = safeMapStore.points[index].canonicalConfidence ?? 0
        let currentSampleCount = safeMapStore.points[index].canonicalSampleCount
        
        // Compute new weighted average
        let newBakedPosition: SIMD3<Float>
        let newConfidence: Float
        let newSampleCount: Int
        
        if let existing = currentBaked, currentSampleCount > 0 {
            // Blend with existing
            let existingWeight = currentConfidence * Float(currentSampleCount)
            let newWeight = confidence
            let totalWeight = existingWeight + newWeight
            
            newBakedPosition = (existing * existingWeight + canonicalPosition * newWeight) / totalWeight
            newConfidence = totalWeight / Float(currentSampleCount + 1)
            newSampleCount = currentSampleCount + 1
            
            let delta = simd_distance(existing, newBakedPosition)
            print("🔥 [BAKE_UPDATE] \(String(mapPointID.uuidString.prefix(8))): blended (Δ=\(String(format: "%.3f", delta))m) conf=\(String(format: "%.2f", newConfidence)) samples=\(newSampleCount)")
        } else {
            // First bake for this MapPoint
            newBakedPosition = canonicalPosition
            newConfidence = confidence
            newSampleCount = 1
            print("🔥 [BAKE_UPDATE] \(String(mapPointID.uuidString.prefix(8))): NEW baked position, conf=\(String(format: "%.2f", newConfidence))")
        }
        
        // Update and save
        safeMapStore.points[index].canonicalPosition = newBakedPosition
        safeMapStore.points[index].canonicalConfidence = newConfidence
        safeMapStore.points[index].canonicalSampleCount = newSampleCount
        
        // Update bake timestamp in MapPointStore
        safeMapStore.lastBakeTimestamp = Date()
        safeMapStore.save()
    }
    
    /// Debug function to display current baked positions
    func debugBakedPositions() {
        safeMapStore.debugBakedPositionSummary()
    }
    
    // MARK: - Crawl Coverage Diagnostics
    
    /// Diagnostic: Show coverage of triangle vertices during calibration crawl
    /// Call this at end of calibration to see which vertices were missed
    func debugCrawlCoverage() {
        print("\n" + String(repeating: "=", count: 80))
        print("🔍 [CRAWL_COVERAGE] Calibration Crawl Coverage Analysis")
        print(String(repeating: "=", count: 80))
        
        // Get all triangle-edge MapPoints
        let triangleVertices = safeMapStore.points.filter { $0.roles.contains(.triangleEdge) }
        let totalVertices = triangleVertices.count
        
        // Check which have AR positions
        var covered: [UUID] = []
        var missing: [UUID] = []
        
        for vertex in triangleVertices {
            if mapPointARPositions[vertex.id] != nil {
                covered.append(vertex.id)
            } else {
                missing.append(vertex.id)
            }
        }
        
        print("📊 Summary:")
        print("   Total triangle vertices: \(totalVertices)")
        print("   Covered (have AR position): \(covered.count)")
        print("   Missing (no AR position): \(missing.count)")
        print("")
        
        if !missing.isEmpty {
            print("❌ MISSING VERTICES:")
            for missingID in missing {
                if let point = safeMapStore.points.first(where: { $0.id == missingID }) {
                    // Find which triangles contain this vertex
                    let containingTriangles = safeTriangleStore.triangles.filter { $0.vertexIDs.contains(missingID) }
                    let calibratedTriangles = containingTriangles.filter { sessionCalibratedTriangles.contains($0.id) }
                    
                    print("   • MapPoint \(String(missingID.uuidString.prefix(8))) at (\(Int(point.position.x)), \(Int(point.position.y)))")
                    print("     Member of \(containingTriangles.count) triangle(s), \(calibratedTriangles.count) calibrated this session")
                    
                    // For each containing triangle, explain why this vertex wasn't covered
                    for triangle in containingTriangles {
                        let isCalibrated = sessionCalibratedTriangles.contains(triangle.id)
                        let otherVertices = triangle.vertexIDs.filter { $0 != missingID }
                        let otherVerticesCovered = otherVertices.allSatisfy { mapPointARPositions[$0] != nil }
                        
                        print("       Triangle \(String(triangle.id.uuidString.prefix(8))): calibrated=\(isCalibrated), other vertices covered=\(otherVerticesCovered)")
                    }
                }
            }
        }
        
        print("")
        print("✅ Calibrated triangles this session: \(sessionCalibratedTriangles.count)")
        for triangleID in sessionCalibratedTriangles {
            print("   • \(String(triangleID.uuidString.prefix(8)))")
        }
        
        print(String(repeating: "=", count: 80) + "\n")
    }
}

