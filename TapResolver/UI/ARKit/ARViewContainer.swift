//
//  ARViewContainer.swift
//  TapResolver
//
//  Created by Chris Gelles on 10/20/25.
//


//
//  ARViewContainer.swift
//  TapResolver
//
//  Role: UIKit ARSCNView wrapper for SwiftUI
//

import SwiftUI
import ARKit
import SceneKit
import UIKit

enum RelocalizationState {
    case idle
    case searching
    case imageTracking
    case featureMatching
    case validating
    case success
    case failed
    
    var displayMessage: String {
        switch self {
        case .idle: return ""
        case .searching: return "Scanning for ground plane..."
        case .imageTracking: return "Looking for anchor point..."
        case .featureMatching: return "Matching spatial features..."
        case .validating: return "Validating position..."
        case .success: return "✓ Found! Tap where marker should be for comparison"
        case .failed: return "Unable to find anchor point"
        }
        
    }
}

enum DetectionPhase {
    case idle
    case longRange      // Wall targets only (1.2m)
    case approaching    // Wall + floor mid (0.8m)
    case precision      // All targets
    
    var displayName: String {
        switch self {
        case .idle: return "Idle"
        case .longRange: return "Long-Range Detection"
        case .approaching: return "Approaching Target"
        case .precision: return "Precision Mode"
        }
    }
}

// MARK: - AR Marker Data

struct ARMarkerData {
    let position: simd_float3
    let userHeight: Float
}

// MARK: - Square Placement State

enum SquarePlacementState {
    case idle
    case corner1Placed(position: simd_float3)
    case corner2Placed(corner1: simd_float3, corner2: simd_float3)
    case completed
}

struct ARViewContainer: UIViewRepresentable {
    
    let mapPointID: UUID
    let userHeight: Float  // From MapPoint's latest session
    @Binding var markerPlaced: Bool
    
    // Metric Square mode (optional)
    let metricSquareID: UUID?
    let squareColor: UIColor?
    let squareSideMeters: Double?
    
    let worldMapStore: ARWorldMapStore
    @Binding var relocalizationStatus: String
    let mapPointStore: MapPointStore
    @Binding var selectedMarkerID: UUID?
    
    // Interpolation mode (optional - defaults to false/nil for backward compatibility)
    var isInterpolationMode: Bool = false
    var interpolationFirstPointID: UUID? = nil
    var interpolationSecondPointID: UUID? = nil
    
    // Anchor mode (optional)
    var isAnchorMode: Bool = false
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView()
        
        // Set the delegate
        arView.delegate = context.coordinator
        arView.session.delegate = context.coordinator
        
        // Create and set an empty scene
        arView.scene = SCNScene()
        
        // Configure AR session
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        
        // Enable LiDAR scene reconstruction for improved raycasting accuracy
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
            print("✅ LiDAR scene reconstruction enabled")
            print("   Raycasts will use mesh geometry when available")
        } else {
            print("⚠️ Device does not support scene reconstruction")
            print("   Raycasts will use plane detection only")
            print("   Accuracy may be reduced on low-texture surfaces")
        }
        
        // Use gravity alignment for stable indoor tracking
        configuration.worldAlignment = .gravity
        
        // Choose best patch if available, fallback to legacy GlobalMap
        if let activePoint = mapPointStore.activePoint,
           let (meta, map) = worldMapStore.chooseBestPatch(for: activePoint.mapPoint) {
            configuration.initialWorldMap = map
            context.coordinator.isRelocalizing = true
            context.coordinator.relocalizationStartTime = Date()
            context.coordinator.activePatch = meta
            context.coordinator.didEnableImageDetection = false
            print("🌍 Seeding AR session with patch '\(meta.name)'")
        } else if let worldMap = worldMapStore.loadWorldMap() {
            configuration.initialWorldMap = worldMap
            context.coordinator.isRelocalizing = true
            context.coordinator.relocalizationStartTime = Date()
            context.coordinator.activePatch = nil
            context.coordinator.didEnableImageDetection = false
            print("🌍 Seeding AR session with legacy GlobalMap")
        } else {
            print("⚠️ No patches or GlobalMap available")
            context.coordinator.isRelocalized = true  // No relocalization needed
            context.coordinator.activePatch = nil
        }
        
        // Defer image detection until relocalization succeeds
        configuration.detectionImages = []
        configuration.maximumNumberOfTrackedImages = 0
        print("⏳ Image detection paused until relocalization completes")
        
        // Run the session with proper initialization
        print("🎬 AR Session starting - markers will be created on-demand")
        print("   Persisted AR Markers are ignored (ephemeral session only)")
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        // Show feature points for debugging
        arView.debugOptions = [.showFeaturePoints]
        
        // Add crosshair reticle
        let crosshair = context.coordinator.createCrosshair()
        arView.scene.rootNode.addChildNode(crosshair)
        context.coordinator.crosshairNode = crosshair
        
        // Add tap gesture for placing markers
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        context.coordinator.arView = arView
        context.coordinator.userHeight = userHeight
        context.coordinator.markerPlaced = markerPlaced
        context.coordinator.metricSquareID = metricSquareID
        context.coordinator.squareColor = squareColor
        context.coordinator.squareSideMeters = squareSideMeters
        context.coordinator.mapPointStore = mapPointStore
        context.coordinator.mapPointID = mapPointID
        context.coordinator.isAnchorMode = isAnchorMode
        context.coordinator.worldMapStore = worldMapStore
        
        // Listen for delete notifications
        context.coordinator.deleteNotificationObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("DeleteARMarker"),
            object: nil,
            queue: .main
        ) { [weak coordinator = context.coordinator] notification in
            if let markerID = notification.userInfo?["markerID"] as? UUID {
                print("📥 Coordinator received delete notification for \(markerID)")
                
                // Set the selected marker ID if needed
                if coordinator?.selectedMarkerID == nil {
                    coordinator?.selectedMarkerID = markerID
                }
                
                coordinator?.deleteSelectedMarker()
            }
        }
        
        
        print("📷 AR Camera session started")
        
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        // No updates needed for now
    }
    
    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator()
        coordinator.relocalizationStatus = $relocalizationStatus
        coordinator.selectedMarkerIDBinding = $selectedMarkerID
        coordinator.isInterpolationMode = isInterpolationMode
        coordinator.interpolationFirstPointID = interpolationFirstPointID
        coordinator.interpolationSecondPointID = interpolationSecondPointID
        
        // Set static reference for button access
        Coordinator.current = coordinator
        
        return coordinator
    }
    
    class Coordinator: NSObject, ObservableObject, ARSCNViewDelegate, ARSessionDelegate {
        
        // Static reference for button access
        static weak var current: Coordinator? = nil
        
        weak var arView: ARSCNView?
        var crosshairNode: SCNNode?
        var userHeight: Float = 1.05
        var markerPlaced: Bool = false
        var markerNode: SCNNode?
        var lastPlacedPosition: simd_float3? = nil
        
        private var detectedPlanes: [UUID: SCNNode] = [:]
        
        // Metric Square placement
        var metricSquareID: UUID?
        var squareColor: UIColor?
        var squareSideMeters: Double?
        var squarePlacementState: SquarePlacementState = .idle
        var squareNodes: [SCNNode] = []
        
        // Relocalization tracking
        var isRelocalizing: Bool = false
        var relocalizationStatus: Binding<String>?
        private var lastTrackingState: ARCamera.TrackingState?
        var isRelocalized: Bool = false
        var relocalizationStartTime: Date?
        
        // MapPointStore reference
        var mapPointStore: MapPointStore?
        var worldMapStore: ARWorldMapStore?
        var activePatch: WorldMapPatchMeta?
        var mapPointID: UUID = UUID()
        var selectedMarkerID: UUID?
        var selectionRingNode: SCNNode?
        var selectedMarkerIDBinding: Binding<UUID?>?
        
        // Interpolation mode
        var isInterpolationMode: Bool = false
        var interpolationFirstPointID: UUID?
        var interpolationSecondPointID: UUID?
        var deleteNotificationObserver: NSObjectProtocol?
        
        // Session-temporary markers for interpolation visualization
        var sessionMarkerA: (position: simd_float3, mapPointID: UUID)? = nil
        var sessionMarkerB: (position: simd_float3, mapPointID: UUID)? = nil
        
        // Anchor mode tracking
        var isAnchorMode: Bool = false
        
        // Anchor capture state
        @Published var isCapturingAnchor = false
        @Published var anchorQualityScore = 0
        @Published var anchorInstruction = "Move device slowly to detect surfaces"
        @Published var anchorCountdown: Int? = nil
        @Published var signatureImageCaptured = false
        @Published var showFloorMarkerPositioning = false
        private var qualityUpdateTimer: Timer?
        private var countdownTimer: Timer?
        var currentCaptureMapPointID: UUID? = nil
        var currentCapturePosition: simd_float3? = nil
        
        // Accumulated data during anchor capture session
        var accumulatedFeaturePoints: [simd_float3] = []
        var accumulatedPlanes: [UUID: ARPlaneAnchor] = [:]  // Dictionary to track unique planes
        var accumulatedReferenceImages: [AnchorReferenceImage] = []
        var captureStartTime: Date? = nil
        
        // Quality thresholds for auto-capture (track what we've captured)
        var capturedFloorFar = false
        var capturedFloorClose = false
        var capturedWalls = false
        
        // Milestone 4: Floor marker capture state
        var isCapturingFloorMarker: Bool = false
        var capturedFloorImage: UIImage?
        var pendingFloorMarker: FloorMarkerCapture?
        var pendingFloorMarkerPackageID: UUID?
        private var capturedFloorMarkerOffset: simd_float3? = nil
        private var capturedFloorMarkerTransform: simd_float4x4? = nil
        
        // Diagnostic flag to log scene reconstruction status once
        private var hasLoggedSceneReconstruction = false
        private var isTrackingReady: Bool = false
        private var trackingReadyTimestamp: Date?
        
        // Relocalization mode
        var isRelocalizationMode = false
        var relocalizationState: RelocalizationState = .idle
        var foundAnchorTransforms: [UUID: simd_float4x4] = [:]  // Anchor ID -> transform matrix
        var activeRelocalizationPackages: [AnchorPointPackage] = []
        
        // DEBUG: Track auto-placed marker position for tap comparison
        private var autoPlacedMarkerPosition: simd_float3?
        
        var placedAnchorMarkers: Set<UUID> = []  // Track which anchor packages have markers placed
        var anchorDetectionCounts: [UUID: Int] = [:]  // Track how many times each anchor detected
        var pendingAnchorDetections: [UUID: (anchor: ARImageAnchor, captureType: String)] = [:]  // Anchors detected but waiting for ground plane
        
        // Coordinate system transform (2D map -> 3D AR)
        var mapToARTransform: simd_float4x4? = nil
        
        // Config debouncing
        private var lastConfigSig: String = ""
        private var lastConfigRunAt: Date = .distantPast
        
        // Progressive detection
        private var currentDetectionPhase: DetectionPhase = .idle
        private var detectionPhaseStartTime: Date?
        private var lastDetectedImagePosition: simd_float3?
        private var detectionStabilityCheckTimer: Timer?
        var didEnableImageDetection = false
        
        // Survey state
        var isSurveying: Bool = false
        var surveyFeatures: Int = 0
        var surveyPlanes: Int = 0
        var surveyQuality: Int = 0
        private var surveyCenter: CGPoint?
        
        // Stability tracking for phase transitions
        private var stabilityPositions: [simd_float3] = []
        private let maxStabilityPositions = 10  // Track last 10 positions
        
        /// Preserve all config settings when making changes
        /// ARWorldTrackingConfiguration is a class (reference type), so we need proper cloning
        private func preserveAndRun(
            _ mutate: (ARWorldTrackingConfiguration) -> Void,
            session: ARSession
        ) {
            guard let current = session.configuration as? ARWorldTrackingConfiguration else {
                print("❌ Cannot preserve config - not ARWorldTrackingConfiguration")
                return
            }
            
            let cfg = ARWorldTrackingConfiguration()
            cfg.worldAlignment = current.worldAlignment
            cfg.planeDetection = current.planeDetection
            cfg.environmentTexturing = current.environmentTexturing
            cfg.sceneReconstruction = current.sceneReconstruction
            cfg.maximumNumberOfTrackedImages = current.maximumNumberOfTrackedImages
            
            mutate(cfg)
            
            print("🔧 Config updated:")
            print("   Detection images: \(cfg.detectionImages?.count ?? 0)")
            print("   Max tracked: \(cfg.maximumNumberOfTrackedImages)")
            
            session.run(cfg, options: [])
        }
        
        /// Calculate viewing angle relative to image plane normal
        /// Returns angle in degrees (0° = perpendicular view, 90° = edge-on view)
        private func calculateAngleToNormal(
            imageAnchor: ARImageAnchor,
            frame: ARFrame
        ) -> Float {
            let r = imageAnchor.transform
            let planeNormal = simd_normalize(
                simd_float3(r.columns.2.x, r.columns.2.y, r.columns.2.z)
            )
            
            let camPos = simd_make_float3(frame.camera.transform.columns.3)
            let imgPos = simd_make_float3(r.columns.3)
            let camToImage = simd_normalize(imgPos - camPos)
            
            let dot = max(-1.0 as Float, min(1.0 as Float, simd_dot(planeNormal, camToImage)))
            let angleRad = acos(dot)
            let angleDeg = abs(angleRad * (180.0 as Float) / Float.pi)
            
            return angleDeg
        }
        
        /// Extract yaw angle from 4x4 transform (in degrees)
        /// Handles ARKit's coordinate system (Y-up, Z-forward)
        private func yawDegrees(from transform: simd_float4x4) -> Float {
            let r = simd_float3x3(
                simd_make_float3(transform.columns.0),
                simd_make_float3(transform.columns.1),
                simd_make_float3(transform.columns.2)
            )
            
            let yaw = atan2f(r.columns.2.x, r.columns.2.z)
            return yaw * (180.0 as Float) / Float.pi
        }
        
        /// Calculate yaw coverage across observations (wrap-around safe)
        /// Returns coverage in degrees (0-360)
        private func calculateYawCoverage(_ yaws: [Float]) -> Float {
            guard yaws.count >= 2 else { return 0 }
            
            let normalized = yaws.map { fmodf(($0 + 360.0 as Float), 360.0 as Float) }.sorted()
            
            var maxGap: Float = 0
            for i in 0..<normalized.count {
                let next = (i + 1) % normalized.count
                let gap = fmodf((normalized[next] - normalized[i] + 360.0 as Float), 360.0 as Float)
                maxGap = max(maxGap, gap)
            }
            
            return 360 - maxGap
        }
        
        /// Check if an image anchor has been stable for the required duration
        private func checkStability(
            position: simd_float3,
            duration: TimeInterval,
            maxJitterCm: Float
        ) -> Bool {
            stabilityPositions.append(position)
            
            if stabilityPositions.count > maxStabilityPositions {
                stabilityPositions.removeFirst()
            }
            
            guard let startTime = detectionPhaseStartTime else {
                detectionPhaseStartTime = Date()
                return false
            }
            
            let elapsed = Date().timeIntervalSince(startTime)
            guard elapsed >= duration else {
                return false
            }
            
            guard stabilityPositions.count >= 3 else { return false }
            
            var maxJitter: Float = 0
            for i in 0..<stabilityPositions.count - 1 {
                let delta = simd_distance(stabilityPositions[i], stabilityPositions[i + 1])
                maxJitter = max(maxJitter, delta)
            }
            
            let isStable = (maxJitter * 100) <= maxJitterCm
            
            if isStable {
                print("✅ Stability check passed: \(String(format: "%.2f", Double(maxJitter * 100)))cm jitter over \(String(format: "%.1f", Double(elapsed)))s")
            }
            
            return isStable
        }
        
        private func resetStabilityTracking() {
            stabilityPositions.removeAll()
            detectionPhaseStartTime = nil
            lastDetectedImagePosition = nil
        }
        
        /// Check if SLAM is ready for image tracking
        private func slamIsReady(_ session: ARSession) -> Bool {
            guard let frame = session.currentFrame else { return false }
            guard case .normal = frame.camera.trackingState else { return false }
            
            let planes = frame.anchors.compactMap { $0 as? ARPlaneAnchor }
                .filter { $0.alignment == .horizontal }
            return planes.contains { $0.planeExtent.width * $0.planeExtent.height > 0.5 }
        }
        
        /// Escalate to more images if no lock detected
        private func escalateDetectionIfNoLock(
            after seconds: TimeInterval,
            categorizedImages: [String: Set<ARReferenceImage>]
        ) {
            DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { [weak self] in
                guard let self = self,
                      self.relocalizationState == .imageTracking,
                      let arView = self.arView else { return }
                
                let hasAnchorMarker = arView.scene.rootNode.childNodes
                    .contains(where: { $0.name == "AnchorMarker" })
                guard !hasAnchorMarker else {
                    print("✅ Anchor already placed - skipping escalation")
                    return
                }
                
                switch self.currentDetectionPhase {
                case .precision:
                    let all = (categorizedImages["floor_near"] ?? [])
                        .union(categorizedImages["floor_mid"] ?? [])
                        .union(categorizedImages["wall"] ?? [])
                    
                    self.preserveAndRun({ config in
                        config.detectionImages = all
                        config.maximumNumberOfTrackedImages = 2
                    }, session: arView.session)
                    
                    print("⬆️ Escalating to ALL targets (no near-floor lock)")
                    print("   Total images: \(all.count)")
                    
                case .longRange:
                    let next = (categorizedImages["wall"] ?? [])
                        .union(categorizedImages["floor_mid"] ?? [])
                    
                    self.preserveAndRun({ config in
                        config.detectionImages = next
                        config.maximumNumberOfTrackedImages = 2
                    }, session: arView.session)
                    
                    print("⬆️ Escalating to wall + floor_mid")
                    print("   Total images: \(next.count)")
                    
                default:
                    break
                }
            }
        }
        
        private func advanceDetectionPhase(
            to newPhase: DetectionPhase,
            categorizedImages: [String: Set<ARReferenceImage>]
        ) {
            guard let arView = arView else {
                print("❌ Cannot advance phase - no AR session view")
                return
            }
            
            let session = arView.session
            
            print("🎯 Advancing detection phase: \(currentDetectionPhase.displayName) → \(newPhase.displayName)")
            
            var detectionImages = Set<ARReferenceImage>()
            var maxTracked = 1
            
            switch newPhase {
            case .idle:
                break
            case .longRange:
                if let wallImages = categorizedImages["wall"] {
                    detectionImages = wallImages
                }
                maxTracked = 1
            case .approaching:
                if let wallImages = categorizedImages["wall"] {
                    detectionImages.formUnion(wallImages)
                }
                if let floorMid = categorizedImages["floor_mid"] {
                    detectionImages.formUnion(floorMid)
                }
                maxTracked = 2
            case .precision:
                if let wallImages = categorizedImages["wall"] {
                    detectionImages.formUnion(wallImages)
                }
                if let floorMid = categorizedImages["floor_mid"] {
                    detectionImages.formUnion(floorMid)
                }
                if let floorNear = categorizedImages["floor_near"] {
                    detectionImages.formUnion(floorNear)
                }
                maxTracked = 2
            }
            
            preserveAndRun({ config in
                config.detectionImages = detectionImages
                config.maximumNumberOfTrackedImages = maxTracked
            }, session: session)
            
            currentDetectionPhase = newPhase
            resetStabilityTracking()
            
            print("   Images: \(detectionImages.count), Max tracked: \(maxTracked)")
        }
        
        private func handlePhaseTransitionDetection(
            _ imageAnchor: ARImageAnchor,
            categorizedImages: [String: Set<ARReferenceImage>]
        ) {
            // Phase transitions now handled by escalation logic
        }
        
        // MARK: - Crosshair Creation
        
        func createCrosshair() -> SCNNode {
            let crosshairNode = SCNNode()
            
            // Create circle
            let circle = SCNTorus(ringRadius: 0.1, pipeRadius: 0.002)
            let circleMaterial = SCNMaterial()
            circleMaterial.diffuse.contents = UIColor.white.withAlphaComponent(0.8)
            circle.materials = [circleMaterial]
            
            let circleNode = SCNNode(geometry: circle)
            //circleNode.eulerAngles.x = .pi / 2
            crosshairNode.addChildNode(circleNode)
            
            // Outer confidence ring (hidden by default, shown when surface is stable)
            let outerCircle = SCNTorus(ringRadius: 0.18, pipeRadius: 0.002) // 15cm radius (30cm diameter)
            let outerMaterial = SCNMaterial()
            outerMaterial.diffuse.contents = UIColor.white.withAlphaComponent(0.5)
            outerCircle.materials = [outerMaterial]
            
            let outerCircleNode = SCNNode(geometry: outerCircle)
            //outerCircleNode.eulerAngles.x = .pi / 2
            outerCircleNode.isHidden = true
            outerCircleNode.name = "outerConfidenceRing"
            crosshairNode.addChildNode(outerCircleNode)
            
            // Create crosshair lines
            let lineLength: CGFloat = 0.1
            let lineThickness: CGFloat = 0.001
            
            // Horizontal line
            let hLine = SCNBox(width: lineLength, height: lineThickness, length: lineThickness, chamferRadius: 0)
            hLine.materials = [circleMaterial]
            let hLineNode = SCNNode(geometry: hLine)
            crosshairNode.addChildNode(hLineNode)
            
            // Perpendicular horizontal line (rotated 90° on Y-axis)
            let hLine2Node = SCNNode(geometry: hLine)
            hLine2Node.eulerAngles.y = .pi / 2
            crosshairNode.addChildNode(hLine2Node)
            
            // Vertical line
            let vLine = SCNBox(width: lineThickness, height: lineLength, length: lineThickness, chamferRadius: 0)
            vLine.materials = [circleMaterial]
            let vLineNode = SCNNode(geometry: vLine)
            crosshairNode.addChildNode(vLineNode)
            
            crosshairNode.isHidden = true
            return crosshairNode
        }
        
        // MARK: - Raycast Update
        
        func updateCrosshair() {
            guard let arView = arView,
                  let crosshair = crosshairNode else { return }
            
            let screenCenter = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)
            
            guard let query = arView.raycastQuery(from: screenCenter, allowing: .estimatedPlane, alignment: .horizontal) else {
                crosshair.isHidden = true
                return
            }
            
            let results = arView.session.raycast(query)
            
            if let result = results.first {
                // Only update position, force horizontal orientation
                crosshair.simdPosition = simd_make_float3(result.worldTransform.columns.3)
                //crosshair.simdWorldOrientation = simd_quatf(angle: 0, axis: simd_float3(0, 1, 0))
                crosshair.isHidden = false
                
                // Check surface confidence
                updateSurfaceConfidence(for: result, crosshair: crosshair)
                
                // Check for corner snapping
                if let snappedPosition = findNearbyCorner(from: result.worldTransform.columns.3) {
                    crosshair.simdPosition = snappedPosition
                    // Change color to indicate snap
                    if let circle = crosshair.childNodes.first?.geometry as? SCNTorus {
                        circle.materials.first?.diffuse.contents = UIColor.green.withAlphaComponent(0.9)
                    }
                } else {
                    // Normal white color
                    if let circle = crosshair.childNodes.first?.geometry as? SCNTorus {
                        circle.materials.first?.diffuse.contents = UIColor.white.withAlphaComponent(0.8)
                    }
                }
            } else {
                crosshair.isHidden = true
            }
        }
        
        private func updateSurfaceConfidence(for result: ARRaycastResult, crosshair: SCNNode) {
            guard let arView = arView,
                  let outerRing = crosshair.childNode(withName: "outerConfidenceRing", recursively: false) else { return }
            
            // Get the plane anchor if available
            if let planeAnchor = result.anchor as? ARPlaneAnchor,
               planeAnchor.alignment == .horizontal {
                let planeExtent = planeAnchor.planeExtent
                let planeArea = planeExtent.width * planeExtent.height
                
                // Consider plane "confident" if it's larger than 0.5 square meters
                let isConfident = planeArea > 0.5
                
                outerRing.isHidden = !isConfident
                
                // Optionally pulse the outer ring when confident
                if isConfident && outerRing.opacity == 1.0 {
                    let pulse = SCNAction.sequence([
                        SCNAction.fadeOpacity(to: 0.3, duration: 0.8),
                        SCNAction.fadeOpacity(to: 1.0, duration: 0.8)
                    ])
                    outerRing.runAction(SCNAction.repeatForever(pulse))
                }
            } else {
                outerRing.isHidden = true
            }
        }
        
        // MARK: - Corner Detection
        
        private func findNearbyCorner(from position: simd_float4) -> simd_float3? {
            let testPosition = simd_float3(position.x, position.y, position.z)
            let snapDistance: Float = 0.08 // 4cm
            let angleThreshold: Float = 25.0 * .pi / 180.0 // 25 degrees in radians
            
            // Check all plane combinations for corners
            let planeArray = Array(detectedPlanes.values)
            
            for i in 0..<planeArray.count {
                for j in (i+1)..<planeArray.count {
                    if let corner = findCornerBetweenPlanes(planeArray[i], planeArray[j], angleThreshold: angleThreshold) {
                        let distance = simd_distance(testPosition, corner)
                        if distance < snapDistance {
                            return corner
                        }
                    }
                }
            }
            
            return nil
        }
        
        private func findCornerBetweenPlanes(_ plane1: SCNNode, _ plane2: SCNNode, angleThreshold: Float) -> simd_float3? {
            // Get plane normals
            let normal1 = plane1.simdWorldTransform.columns.1
            let normal2 = plane2.simdWorldTransform.columns.1
            
            // Calculate angle between planes
            let dotProduct = simd_dot(simd_normalize(simd_float3(normal1.x, normal1.y, normal1.z)),
                                       simd_normalize(simd_float3(normal2.x, normal2.y, normal2.z)))
            let angle = acos(dotProduct)
            
            // Check if planes are roughly perpendicular
            if abs(angle - .pi / 2) < angleThreshold {
                
                // Find intersection point (simplified - use plane centers for now)
                let pos1 = simd_float3(plane1.simdWorldPosition)
                let pos2 = simd_float3(plane2.simdWorldPosition)
                return (pos1 + pos2) / 2
            }
            
            return nil
        }
        
        // MARK: - Marker Placement
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = arView else { return }
            
            if relocalizationState == .success,
               let autoPosition = autoPlacedMarkerPosition {
                let tapLocation = gesture.location(in: arView)
                handleDebugTapComparison(at: tapLocation, autoPlacedAt: autoPosition)
                return
            }
            
            if relocalizationState != .idle {
                print("⚠️ Tap ignored - in relocalization mode (\(relocalizationState))")
                return
            }
            
            print("🔵 TAP DETECTED - isAnchorMode: \(isAnchorMode)")
            
            // Handle anchor mode placement
            if isAnchorMode {
                print("🟢 Routing to anchor mode handler")
                handleAnchorModeTap(gesture.location(in: arView))
                return
            }
            
            // Don't handle taps in interpolation mode - buttons handle placement
            guard !isInterpolationMode else {
                print("👆 Tap ignored - use buttons to place markers in interpolation mode")
                return
            }
            
            // Get tap location
            let tapLocation = gesture.location(in: arView)
            
            // Check if we tapped an existing AR marker
            // Use more generous hit test options for better detection
            let hitTestOptions: [SCNHitTestOption: Any] = [
                .boundingBoxOnly: false,
                .searchMode: SCNHitTestSearchMode.all.rawValue
            ]
            let hitResults = arView.hitTest(tapLocation, options: hitTestOptions)
            
            // Search through all hit nodes (including parent nodes)
            for hit in hitResults {
                var currentNode: SCNNode? = hit.node
                
                // Check this node and all parents for sphere marker
                while currentNode != nil {
                    if let nodeName = currentNode?.name,
                       nodeName.hasPrefix("arMarkerSphere_") {
                        // Extract marker UUID from node name
                        let uuidString = nodeName.replacingOccurrences(of: "arMarkerSphere_", with: "")
                        if let markerUUID = UUID(uuidString: uuidString) {
                            print("🎯 Hit detected on marker sphere: \(markerUUID)")
                            handleMarkerSelection(markerUUID, sphereNode: currentNode!)
                            return
                        }
                    }
                    
                    // Also check parent marker node
                    if let nodeName = currentNode?.name,
                       nodeName.hasPrefix("arMarker_") {
                        let uuidString = nodeName.replacingOccurrences(of: "arMarker_", with: "")
                        if let markerUUID = UUID(uuidString: uuidString) {
                            print("🎯 Hit detected on marker node: \(markerUUID)")
                            // Find the sphere child node
                            if let sphereNode = currentNode?.childNodes.first(where: { $0.geometry is SCNSphere }) {
                                handleMarkerSelection(markerUUID, sphereNode: sphereNode)
                                return
                            }
                        }
                    }
                    
                    currentNode = currentNode?.parent
                }
            }
            
            print("📍 No marker hit - checking for surface to place new marker")
            
            // Not tapping a marker - proceed with marker placement
            guard let crosshair = crosshairNode,
                  !crosshair.isHidden else { return }
            
            // Block placement until relocalized
            guard isRelocalized else {
                print("⚠️ Cannot place marker - waiting for relocalization")
                return
            }
            
            // Block placement if this map point already has an AR marker
            if let mapPointStore = mapPointStore {
                let existingMarker = mapPointStore.arMarkers.first { $0.linkedMapPointID == mapPointID }
                if existingMarker != nil {
                    showBlockedPlacementMessage("Cannot place marker - this map point already has an AR marker. Delete it first.")
                    return
                }
            }
            
            let position = crosshair.simdPosition
            
            // Metric Square mode
            if metricSquareID != nil {
                handleSquarePlacement(at: position)
                return
            }
            
            // MapPoint marker mode
            guard !markerPlaced else { return }
            placeMarker(at: position)
            markerPlaced = true
        }

        private func handleDebugTapComparison(at _: CGPoint, autoPlacedAt autoPosition: simd_float3) {
            guard let arView = arView,
                  arView.session.currentFrame != nil else {
                print("❌ No AR frame available for tap comparison")
                return
            }
            
            print("\n═══ DEBUG TAP COMPARISON ═══")
            print("📍 Auto-placed marker position: \(autoPosition)")
            
            let centerPoint = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)
            guard let raycastQuery = arView.raycastQuery(from: centerPoint, allowing: .existingPlaneGeometry, alignment: .horizontal) else {
                print("❌ Raycast query failed - could not build query from crosshairs")
                print("═══════════════════════════\n")
                return
            }
            
            let raycastResults = arView.session.raycast(raycastQuery)
            
            if let result = raycastResults.first {
                let tappedPosition = simd_make_float3(result.worldTransform.columns.3)
                
                print("👆 User indicated position (crosshairs): \(tappedPosition)")
                
                let offset = tappedPosition - autoPosition
                let distance = simd_length(offset)
                let floorDistance = simd_length(simd_float2(offset.x, offset.z))
                
                print("📊 Offset Analysis:")
                print("   X offset: \(offset.x * 100) cm")
                print("   Y offset: \(offset.y * 100) cm (vertical)")
                print("   Z offset: \(offset.z * 100) cm")
                print("   Total distance: \(distance * 100) cm")
                print("   2D floor distance: \(floorDistance * 100) cm")
                
                if distance < 0.05 {
                    print("✅ EXCELLENT: Within 5cm accuracy")
                } else if distance < 0.10 {
                    print("✓ GOOD: Within 10cm accuracy")
                } else if distance < 0.20 {
                    print("⚠️ ACCEPTABLE: Within 20cm accuracy")
                } else {
                    print("❌ POOR: >20cm offset - needs investigation")
                }
                
                arView.scene.rootNode.childNodes
                    .filter { $0.name == "debug_tap_marker" }
                    .forEach { $0.removeFromParentNode() }
                
                placeDebugMarker(at: tappedPosition, label: "TAP")
                
                print("═══════════════════════════\n")
            } else {
                print("❌ Raycast failed - couldn't find ground at crosshairs")
                print("═══════════════════════════\n")
            }
        }
        
        private func placeDebugMarker(at position: simd_float3, label: String) {
            guard let arView = arView else { return }
            
            let sphere = SCNSphere(radius: 0.03)
            sphere.firstMaterial?.diffuse.contents = UIColor.cyan
            sphere.firstMaterial?.emission.contents = UIColor.cyan
            
            let debugNode = SCNNode(geometry: sphere)
            debugNode.position = SCNVector3(position.x, position.y, position.z)
            debugNode.name = "debug_tap_marker"
            
            let text = SCNText(string: label, extrusionDepth: 0.5)
            text.font = UIFont.systemFont(ofSize: 5)
            text.firstMaterial?.diffuse.contents = UIColor.white
            
            let textNode = SCNNode(geometry: text)
            textNode.scale = SCNVector3(0.01, 0.01, 0.01)
            textNode.position = SCNVector3(0, 0.05, 0)
            
            debugNode.addChildNode(textNode)
            arView.scene.rootNode.addChildNode(debugNode)
            
            print("🔵 Placed debug marker '\(label)' at \(position)")
        }
        
        // MARK: - AR Marker Creation Helper
        
        /// Create a complete AR marker node with floor circle, vertical line, and topping sphere
        /// - Parameters:
        ///   - position: 3D position in AR space
        ///   - sphereColor: Color for the topping sphere
        ///   - markerID: UUID for node naming
        ///   - userHeight: Height of the vertical line (meters)
        /// - Returns: Configured SCNNode ready to add to scene
        private func createARMarkerNode(at position: simd_float3, sphereColor: UIColor, markerID: UUID, userHeight: Float, badgeColor: UIColor? = nil) -> SCNNode {
            let markerNode = SCNNode()
            markerNode.simdPosition = position
            markerNode.name = "arMarker_\(markerID.uuidString)"
            
            let circle = SCNTorus(ringRadius: 0.1, pipeRadius: 0.002)
            circle.firstMaterial?.diffuse.contents = UIColor(red: 71/255, green: 199/255, blue: 239/255, alpha: 0.7)
            let circleNode = SCNNode(geometry: circle)
            markerNode.addChildNode(circleNode)
            
            let circleFill = SCNCylinder(radius: 0.1, height: 0.001)
            circleFill.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0.15)
            let fillNode = SCNNode(geometry: circleFill)
            fillNode.eulerAngles.x = .pi
            markerNode.addChildNode(fillNode)
            
            let line = SCNCylinder(radius: 0.00125, height: CGFloat(userHeight))
            line.firstMaterial?.diffuse.contents = UIColor(red: 0/255, green: 50/255, blue: 98/255, alpha: 0.95)
            let lineNode = SCNNode(geometry: line)
            lineNode.position = SCNVector3(0, Float(line.height/2), 0)
            markerNode.addChildNode(lineNode)
            
            let sphere = SCNSphere(radius: 0.03)
            sphere.firstMaterial?.diffuse.contents = sphereColor
            sphere.firstMaterial?.specular.contents = UIColor.white
            sphere.firstMaterial?.shininess = 0.8
            let sphereNode = SCNNode(geometry: sphere)
            sphereNode.position = SCNVector3(0, Float(line.height), 0)
            sphereNode.name = "arMarkerSphere_\(markerID.uuidString)"
            markerNode.addChildNode(sphereNode)
            
            if let badgeColor = badgeColor {
                let badge = SCNNode()
                let badgeGeometry = SCNSphere(radius: 0.05)
                badgeGeometry.firstMaterial?.diffuse.contents = badgeColor
                badge.geometry = badgeGeometry
                badge.position = SCNVector3(0, 0.5, 0)
                badge.name = "badge_\(markerID.uuidString)"
                sphereNode.addChildNode(badge)
            }
            
            return markerNode
        }
        
        // MARK: - Marker Placement
        
        func placeMarker(at position: simd_float3) {
            guard let arView = arView else { return }
            
            // Blue sphere color for manually placed markers
            let sphereColor = UIColor(red: 0/255, green: 125/255, blue: 184/255, alpha: 0.98)
            
            // Create marker node using helper
            let markerNode = createARMarkerNode(
                at: position,
                sphereColor: sphereColor,
                markerID: mapPointID,
                userHeight: userHeight
            )
            
            arView.scene.rootNode.addChildNode(markerNode)
            self.markerNode = markerNode
            
            // Hide crosshair after placement
            crosshairNode?.isHidden = true
            
            print("✅ Marker placed at height: \(userHeight)m")
            
            // Save AR Marker
            if let mapPointStore = mapPointStore,
               let mapPoint = mapPointStore.points.first(where: { $0.id == mapPointID }) {
                mapPointStore.createARMarker(
                    linkedMapPointID: mapPointID,
                    arPosition: position,
                    mapCoordinates: mapPoint.mapPoint
                )
                
                // Post notification for interpolation mode tracking
                NotificationCenter.default.post(
                    name: NSNotification.Name("ARMarkerPlaced"),
                    object: nil,
                    userInfo: ["position": position]
                )
            }
        }
        
        // MARK: - Metric Square Placement
        
        private func handleSquarePlacement(at position: simd_float3) {
            switch squarePlacementState {
            case .idle:
                placeCorner1(at: position)
            case .corner1Placed(let corner1):
                placeCorner2(at: position, corner1: corner1)
            case .corner2Placed(let corner1, let corner2):
                completeSquare(corner1: corner1, corner2: corner2, directionPoint: position)
            case .completed:
                break // Already completed
            }
        }
        
        private func placeCorner1(at position: simd_float3) {
            let cornerNode = createCornerMarker(at: position)
            squareNodes.append(cornerNode)
            arView?.scene.rootNode.addChildNode(cornerNode)
            
            squarePlacementState = .corner1Placed(position: position)
            print("📍 Corner 1 placed at: \(position)")
        }
        
        private func placeCorner2(at position: simd_float3, corner1: simd_float3) {
            let cornerNode = createCornerMarker(at: position)
            squareNodes.append(cornerNode)
            arView?.scene.rootNode.addChildNode(cornerNode)
            
            // Create line between corners
            let lineNode = createLine(from: corner1, to: position)
            squareNodes.append(lineNode)
            arView?.scene.rootNode.addChildNode(lineNode)
            
            squarePlacementState = .corner2Placed(corner1: corner1, corner2: position)
            
            let distance = simd_distance(corner1, position)
            print("📍 Corner 2 placed at: \(position)")
            print("📏 Edge length: \(String(format: "%.3f", distance))m")
        }
        
        private func completeSquare(corner1: simd_float3, corner2: simd_float3, directionPoint: simd_float3) {
            // Calculate edge vector
            let edge = corner2 - corner1
            let edgeLength = simd_length(edge)
            let edgeDir = simd_normalize(edge)
            
            // Calculate perpendicular direction
            let up = simd_float3(0, 1, 0)
            let perpDir = simd_normalize(simd_cross(edgeDir, up))
            
            // Determine which side of the edge the direction point is on
            let toPoint = directionPoint - corner1
            let side = simd_dot(toPoint, perpDir)
            let squareDir = side > 0 ? perpDir : -perpDir
            
            // Calculate other two corners
            let corner3 = corner2 + squareDir * edgeLength
            let corner4 = corner1 + squareDir * edgeLength
            
            // Create square outline
            createSquareOutline(corner1: corner1, corner2: corner2, corner3: corner3, corner4: corner4)
            
            squarePlacementState = .completed
            crosshairNode?.isHidden = true
            
            print("✅ Metric Square completed")
            print("   Edge length (AR): \(String(format: "%.3f", edgeLength))m")
            if let configured = squareSideMeters {
                let diff = abs(Double(edgeLength) - configured)
                let percentDiff = (diff / configured) * 100
                print("   Configured: \(String(format: "%.3f", configured))m")
                print("   Difference: \(String(format: "%.3f", diff))m (\(String(format: "%.1f", percentDiff))%)")
            }
        }
        
        private func createCornerMarker(at position: simd_float3) -> SCNNode {
            let sphere = SCNSphere(radius: 0.01) // 1cm diameter
            let material = SCNMaterial()
            material.diffuse.contents = squareColor ?? UIColor.red
            sphere.materials = [material]
            
            let node = SCNNode(geometry: sphere)
            node.simdPosition = position
            return node
        }
        
        private func createLine(from start: simd_float3, to end: simd_float3) -> SCNNode {
            let vector = end - start
            let length = simd_length(vector)
            let direction = simd_normalize(vector)
            
            let cylinder = SCNCylinder(radius: 0.002, height: CGFloat(length)) // 2mm thick
            let material = SCNMaterial()
            material.diffuse.contents = (squareColor ?? UIColor.red).withAlphaComponent(0.6)
            cylinder.materials = [material]
            
            let node = SCNNode(geometry: cylinder)
            
            // Position at midpoint
            let midpoint = (start + end) / 2
            node.simdPosition = midpoint
            
            // Orient along the vector
            let up = simd_float3(0, 1, 0)
            let rotationAxis = simd_normalize(simd_cross(up, direction))
            let angle = acos(simd_dot(up, direction))
            node.simdRotation = simd_float4(rotationAxis.x, rotationAxis.y, rotationAxis.z, angle)
            
            return node
        }
        
        private func createSquareOutline(corner1: simd_float3, corner2: simd_float3, corner3: simd_float3, corner4: simd_float3) {
            // Create four edges
            let edge1 = createLine(from: corner1, to: corner2)
            let edge2 = createLine(from: corner2, to: corner3)
            let edge3 = createLine(from: corner3, to: corner4)
            let edge4 = createLine(from: corner4, to: corner1)
            
            squareNodes.append(contentsOf: [edge1, edge2, edge3, edge4])
            
            arView?.scene.rootNode.addChildNode(edge1)
            arView?.scene.rootNode.addChildNode(edge2)
            arView?.scene.rootNode.addChildNode(edge3)
            arView?.scene.rootNode.addChildNode(edge4)
            
            // Create fill plane
            let edgeLength = simd_distance(corner1, corner2)
            let plane = SCNPlane(width: CGFloat(edgeLength), height: CGFloat(edgeLength))
            let material = SCNMaterial()
            material.diffuse.contents = (squareColor ?? UIColor.red).withAlphaComponent(0.15)
            material.isDoubleSided = false
            plane.materials = [material]
            
            let fillNode = SCNNode(geometry: plane)
            
            // Position at center of square
            let center = (corner1 + corner2 + corner3 + corner4) / 4
            fillNode.simdPosition = center
            
            // Orient parallel to ground (horizontal plane)
            fillNode.eulerAngles.x = .pi / 2
            
            squareNodes.append(fillNode)
            arView?.scene.rootNode.addChildNode(fillNode)
        }
        
        // MARK: - Plane Detection
        
        func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
            
            let planeNode = createPlaneNode(for: planeAnchor)
            node.addChildNode(planeNode)
            detectedPlanes[planeAnchor.identifier] = planeNode
            
            // Plane detection logging removed to reduce console noise
        }
        
        func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
            guard let planeAnchor = anchor as? ARPlaneAnchor,
                  let planeNode = detectedPlanes[planeAnchor.identifier],
                  let plane = planeNode.geometry as? SCNPlane else { return }
            
            plane.width = CGFloat(planeAnchor.planeExtent.width)
            plane.height = CGFloat(planeAnchor.planeExtent.height)
            planeNode.simdPosition = planeAnchor.center
        }
        
        func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
            guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
            detectedPlanes.removeValue(forKey: planeAnchor.identifier)
        }
        
        func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
            DispatchQueue.main.async { [weak self] in
                self?.updateCrosshair()
            }
        }
        
        private func createPlaneNode(for planeAnchor: ARPlaneAnchor) -> SCNNode {
            let plane = SCNPlane(
                width: CGFloat(planeAnchor.planeExtent.width),
                height: CGFloat(planeAnchor.planeExtent.height)
            )
            
            let material = SCNMaterial()
            if planeAnchor.alignment == .horizontal {
                material.diffuse.contents = UIColor.blue.withAlphaComponent(0.3)
            } else {
                material.diffuse.contents = UIColor.green.withAlphaComponent(0.3)
            }
            plane.materials = [material]
            
            let planeNode = SCNNode(geometry: plane)
            planeNode.simdPosition = planeAnchor.center
            planeNode.eulerAngles.x = -.pi/2
            
            return planeNode
        }
        
        func session(_ session: ARSession, didFailWithError error: Error) {
            print("❌ AR Session failed: \(error.localizedDescription)")
        }
        
        func sessionWasInterrupted(_ session: ARSession) {
            print("⚠️ AR Session interrupted")
        }
        
        func sessionInterruptionEnded(_ session: ARSession) {
            print("✅ AR Session interruption ended")
        }
        
        // MARK: - ARSessionDelegate
        
        func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
            guard isRelocalizing else { return }
            
            // Check for relocalization timeout (15 seconds)
            if let startTime = relocalizationStartTime,
               Date().timeIntervalSince(startTime) > 15.0,
               !isRelocalized {
                relocalizationStatus?.wrappedValue = "⚠️ Relocalization failed"
                print("⚠️ Relocalization timeout - unable to match saved map")
                return
            }
            
            if lastTrackingState != camera.trackingState {
                lastTrackingState = camera.trackingState
                
                switch camera.trackingState {
                case .notAvailable:
                    relocalizationStatus?.wrappedValue = "Relocalization: Camera not available"
                case .limited(let reason):
                    let reasonText: String
                    switch reason {
                    case .initializing:
                        relocalizationStatus?.wrappedValue = "Relocalization: Initializing..."
                    case .relocalizing:
                        relocalizationStatus?.wrappedValue = "Relocalization: Matching saved map..."
                    case .excessiveMotion:
                        relocalizationStatus?.wrappedValue = "Relocalization: Move slower"
                    case .insufficientFeatures:
                        relocalizationStatus?.wrappedValue = "Relocalization: Look around slowly"
                    @unknown default:
                        relocalizationStatus?.wrappedValue = "Relocalization: Limited"
                    }
                case .normal:
                    relocalizationStatus?.wrappedValue = "✅ Tracking locked"
                    print("✅ Relocalization successful - tracking locked to saved map")
                    
                    // Mark as relocalized and load markers
                    isRelocalized = true
                    loadAllARMarkers()
                    enableImageDetectionIfPossible()
                    
                    // Stop showing relocalization status after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.isRelocalizing = false
                        self.relocalizationStatus?.wrappedValue = ""
                    }
                @unknown default:
                    relocalizationStatus?.wrappedValue = "Relocalization: Unknown"
                }
            }
        }
        
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            // Check if any new horizontal planes were added
            let newHorizontalPlanes = anchors.compactMap { $0 as? ARPlaneAnchor }
                .filter { $0.alignment == .horizontal }

            if !newHorizontalPlanes.isEmpty && !pendingAnchorDetections.isEmpty {
                print("✅ Ground plane detected - processing \(pendingAnchorDetections.count) pending anchor(s)")

                // Process all pending anchor detections now that we have ground
                for (packageID, pendingData) in pendingAnchorDetections {
                    if let package = activeRelocalizationPackages.first(where: { $0.id == packageID }) {
                        print("   Placing pending anchor: \(packageID)")
                        validateAndCalculateTransform(
                            package: package,
                            detectedTransform: pendingData.anchor.transform,
                            imageAnchor: pendingData.anchor
                        )
                    }
                }

                // Clear pending
                pendingAnchorDetections.removeAll()
            }

            if !newHorizontalPlanes.isEmpty && relocalizationState == .searching {
                print("✅ Ground plane detected during relocalization - transitioning to image tracking")
                relocalizationState = .imageTracking
            }

            let imageAnchors = anchors.compactMap { $0 as? ARImageAnchor }
            
            if !imageAnchors.isEmpty {
                print("📸 ARKit detected \(imageAnchors.count) image anchor(s)")
                let categorizedImages = isRelocalizationMode ? prepareReferenceImages() : [:]
                for imageAnchor in imageAnchors {
                    guard let frame = session.currentFrame else { continue }
                    
                    let camPos = simd_make_float3(frame.camera.transform.columns.3)
                    let imgPos = simd_make_float3(imageAnchor.transform.columns.3)
                    let distance = simd_length(imgPos - camPos)
                    let imageSize = imageAnchor.referenceImage.physicalSize
                    
                    print("   Image: \(imageAnchor.referenceImage.name ?? "unknown")")
                    print("   Physical size: \(imageSize.width)m x \(imageSize.height)m")
                    print("   Distance from camera: \(String(format: "%.2f", Double(distance)))m (camera-relative)")
                    
                    if isRelocalizationMode {
                        handlePhaseTransitionDetection(imageAnchor, categorizedImages: categorizedImages)
                    }
                    
                    handleDetectedImage(imageAnchor)
                }
            }
        }
        
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            // Log scene reconstruction status once
            if !hasLoggedSceneReconstruction && frame.camera.trackingState == .normal {
                if let config = session.configuration as? ARWorldTrackingConfiguration {
                    let meshEnabled = config.sceneReconstruction == .mesh
                    print("\n📊 AR Session Configuration:")
                    print("   Scene reconstruction: \(meshEnabled ? "✅ ENABLED (LiDAR mesh)" : "❌ Disabled (plane only)")")
                    print("   Plane detection: \(config.planeDetection)")
                    print("   World alignment: \(config.worldAlignment)")
                    if isRelocalizationMode {
                        print("   Detection phase: \(currentDetectionPhase.displayName)")
                    }
                    print("")
                    hasLoggedSceneReconstruction = true
                }
            }
            
            let points = frame.rawFeaturePoints?.points.count ?? 0
            let planes = frame.anchors.compactMap { $0 as? ARPlaneAnchor }.count
            
            if isSurveying {
                let featureScore = min(points / 50, 100)
                let planeScore = min(planes * 20, 100)
                let quality = max(min((featureScore + planeScore) / 2, 100), 0)
                
                DispatchQueue.main.async {
                    self.surveyFeatures = points
                    self.surveyPlanes = planes
                    self.surveyQuality = quality
                }
            }
            
            let trackingState = frame.camera.trackingState
            
            if case .normal = trackingState {
                if trackingReadyTimestamp == nil {
                    trackingReadyTimestamp = Date()
                    print("⏱️ Tracking stabilizing...")
                } else if let timestamp = trackingReadyTimestamp,
                          Date().timeIntervalSince(timestamp) >= 1.0,
                          !isTrackingReady {
                    isTrackingReady = true
                    print("✅ Tracking ready - stable for 1+ second")
                }
            } else {
                if isTrackingReady {
                    print("⚠️ Tracking degraded - waiting to stabilize")
                }
                trackingReadyTimestamp = nil
                isTrackingReady = false
            }
        }
        
        // MARK: - Marker Selection
        
        private func handleMarkerSelection(_ markerID: UUID, sphereNode: SCNNode) {
            // Toggle selection
            if selectedMarkerID == markerID {
                // Deselect
                deselectMarker()
                print("🔵 Deselected AR Marker \(markerID)")
            } else {
                // Select this marker
                deselectMarker() // Clear previous selection first
                selectedMarkerID = markerID
                addSelectionRing(to: sphereNode)
                
                // Update binding to show delete button
                DispatchQueue.main.async {
                    self.selectedMarkerIDBinding?.wrappedValue = markerID
                }
                
                print("🎯 Selected AR Marker \(markerID)")
            }
        }
        
        private func deselectMarker() {
            // Restore blue color to previously selected sphere
            if let selectedID = selectedMarkerID,
               let arView = arView,
               let markerNode = arView.scene.rootNode.childNode(withName: "arMarker_\(selectedID.uuidString)", recursively: false),
               let sphereNode = markerNode.childNodes.first(where: { $0.name?.hasPrefix("arMarkerSphere_") ?? false }),
               let geometry = sphereNode.geometry,
               let material = geometry.materials.first {
                
                // Restore blue color
                material.diffuse.contents = UIColor(red: 0/255, green: 125/255, blue: 184/255, alpha: 0.98)
                material.emission.contents = UIColor.clear
                
                print("🔵 Restored sphere to blue (deselected)")
            }
            
            selectedMarkerID = nil
            
            // Clear binding to hide delete button
            DispatchQueue.main.async {
                self.selectedMarkerIDBinding?.wrappedValue = nil
            }
        }
        
        private func addSelectionRing(to sphereNode: SCNNode) {
            // Change sphere color to orange for selection
            if let geometry = sphereNode.geometry,
               let material = geometry.materials.first {
                material.diffuse.contents = UIColor.orange
                material.emission.contents = UIColor.orange.withAlphaComponent(0.3)
            }
            
            print("🟠 Changed sphere to orange (selected)")
        }
        
        // MARK: - AR Marker Management
        
        private func loadAllARMarkers() {
            guard let mapPointStore = mapPointStore,
                  let arView = arView else {
                return
            }
            
            print("📍 Loading AR Markers into scene...")
            
            let allMarkers = mapPointStore.arMarkers
            guard !allMarkers.isEmpty else {
                print("   No AR Markers to load")
                return
            }
            
            for marker in allMarkers {
                let isActiveMarker = marker.linkedMapPointID == mapPointID
                let markerNode = createMarkerNode(
                    at: marker.arPosition,
                    isActive: isActiveMarker
                )
                markerNode.name = "arMarker_\(marker.id.uuidString)"
                
                // Name the sphere node for hit detection
                if let sphereNode = markerNode.childNodes.first(where: { $0.geometry is SCNSphere }) {
                    sphereNode.name = "arMarkerSphere_\(marker.id.uuidString)"
                }
                
                arView.scene.rootNode.addChildNode(markerNode)
                
                print("   ✅ Loaded AR Marker for MapPoint \(marker.linkedMapPointID)")
            }
            
            print("📍 Loaded \(allMarkers.count) AR Marker(s)")
        }
        
        private func enableImageDetectionIfPossible() {
            guard !didEnableImageDetection else { return }
            guard let arView = arView else { return }
            
            let categorizedImages = prepareReferenceImages()
            let allImages = categorizedImages.values.reduce(into: Set<ARReferenceImage>()) { partialResult, set in
                partialResult.formUnion(set)
            }
            
            guard !allImages.isEmpty else {
                print("⚠️ No reference images available to enable image detection")
                return
            }
            
            preserveAndRun({ config in
                config.detectionImages = allImages
                config.maximumNumberOfTrackedImages = min(2, allImages.count)
            }, session: arView.session)
            
            didEnableImageDetection = true
            print("🔍 Image detection ENABLED - \(allImages.count) reference image(s)")
        }
        
        private func createMarkerNode(at position: simd_float3, isActive: Bool) -> SCNNode {
            let markerNode = SCNNode()
            markerNode.simdPosition = position
            
            // Vertical line (post)
            let lineHeight = Double(userHeight) - 0.03
            let line = SCNCylinder(radius: 0.001, height: lineHeight)
            let lineMaterial = SCNMaterial()
            lineMaterial.diffuse.contents = UIColor(red: 0/255, green: 125/255, blue: 184/255, alpha: isActive ? 0.95 : 0.85)
            line.materials = [lineMaterial]
            
            let lineNode = SCNNode(geometry: line)
            lineNode.position = SCNVector3(0, Float(lineHeight / 2), 0)
            markerNode.addChildNode(lineNode)
            
            // Sphere at top
            let sphere = SCNSphere(radius: 0.015)
            let sphereMaterial = SCNMaterial()
            sphereMaterial.diffuse.contents = UIColor(red: 0/255, green: 125/255, blue: 184/255, alpha: isActive ? 0.98 : 0.88)
            sphereMaterial.specular.contents = UIColor.white
            sphereMaterial.shininess = 0.8
            sphere.materials = [sphereMaterial]
            
            let sphereNode = SCNNode(geometry: sphere)
            sphereNode.position = SCNVector3(0, Float(lineHeight), 0)
            markerNode.addChildNode(sphereNode)
            
            print("🔨 Created marker node - will be named by caller")
            
            return markerNode
        }
        
        func beginSurvey(center: CGPoint) {
            guard !isSurveying else { return }
            DispatchQueue.main.async {
                self.surveyCenter = center
                self.isSurveying = true
                self.surveyFeatures = 0
                self.surveyPlanes = 0
                self.surveyQuality = 0
            }
            print("🔍 Starting survey mode for patch centered at (\(Int(center.x)), \(Int(center.y)))")
        }
        
        func endSurvey() {
            DispatchQueue.main.async {
                self.isSurveying = false
                self.surveyCenter = nil
                self.surveyFeatures = 0
                self.surveyPlanes = 0
                self.surveyQuality = 0
            }
            print("⏹️ Survey mode ended")
        }
        
        func saveSurvey(patchName: String, completion: @escaping (Result<Void, Error>) -> Void) {
            guard let arView = arView,
                  let center = surveyCenter,
                  let worldMapStore = worldMapStore else {
                let error = NSError(domain: "ARSurvey", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing survey context"])
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            arView.session.getCurrentWorldMap { [weak self] map, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Failed to capture map: \(error)")
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }
                
                guard let map = map else {
                    let err = NSError(domain: "ARSurvey", code: -2, userInfo: [NSLocalizedDescriptionKey: "No map returned"])
                    DispatchQueue.main.async {
                        completion(.failure(err))
                    }
                    return
                }
                
                do {
                    let data = try NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                    let featureCount = map.rawFeaturePoints.points.count
                    let meta = WorldMapPatchMeta(
                        name: patchName,
                        featureCount: featureCount,
                        byteSize: data.count,
                        center2D: center,
                        radiusM: 15.0
                    )
                    try worldMapStore.savePatch(map, meta: meta)
                    DispatchQueue.main.async {
                        self.isSurveying = false
                        self.surveyCenter = nil
                        completion(.success(()))
                    }
                    print("📦 Saved patch '\(patchName)' centered at (\(Int(center.x)), \(Int(center.y)))")
                } catch {
                    print("❌ Failed to save patch: \(error)")
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
        }
        
        // MARK: - User Feedback
        
        private func showBlockedPlacementMessage(_ message: String) {
            // This will show in console for now
            // Could add visual overlay in future
            print("🚫 \(message)")
        }
        
        // MARK: - Marker Deletion
        
        func deleteSelectedMarker() {
            guard let markerID = selectedMarkerID,
                  let mapPointStore = mapPointStore,
                  let arView = arView else {
                print("⚠️ Cannot delete: missing requirements")
                return
            }
            
            print("🗑️ Coordinator: Deleting AR Marker \(markerID)")
            
            // Remove from scene
            if let markerNode = arView.scene.rootNode.childNode(withName: "arMarker_\(markerID.uuidString)", recursively: false) {
                markerNode.removeFromParentNode()
                print("   ✅ Removed from AR scene")
            } else {
                print("   ⚠️ Marker node not found in scene")
            }
            
            // Deselect first
            deselectMarker()
            
            // Remove from store
            mapPointStore.deleteARMarker(markerID)
            
            print("✅ Coordinator: AR Marker deletion complete")
        }
        
        // MARK: - Interpolation Marker Placement
        
        /// Called by buttons to place markers in interpolation mode
        func placeMarkerAt(mapPointID: UUID, mapPoint: MapPointStore.MapPoint, color: UIColor) -> UUID {
            guard let arView = arView else {
                print("❌ ARView not available")
                return UUID()  // Return dummy ID on failure
            }
            
            // Perform raycast from center of screen
            let screenCenter = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)
            let raycastQuery = arView.raycastQuery(from: screenCenter, allowing: .estimatedPlane, alignment: .any)
            
            guard let query = raycastQuery,
                  let result = arView.session.raycast(query).first else {
                print("❌ No surface detected at crosshair - point at a surface")
                return UUID()  // Return dummy ID on failure
            }
            
            let position = result.worldTransform.columns.3
            let arPosition = simd_float3(position.x, position.y, position.z)
            
            // Session markers are temporary - don't persist during interpolation
            // (Future: persistent AR Markers will be for visual feature anchors)
            // mapPointStore?.createARMarker(
            //     linkedMapPointID: mapPointID,
            //     arPosition: arPosition,
            //     mapCoordinates: mapPoint.mapPoint
            // )
            
            // Use existing marker placement function (creates circle + post + sphere)
            placeMarker(at: arPosition)
            
            // THEN update the sphere color to match button
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let markerNode = arView.scene.rootNode.childNodes.last {
                    // Find the sphere child node
                    for child in markerNode.childNodes {
                        if let sphere = child.geometry as? SCNSphere {
                            sphere.firstMaterial?.diffuse.contents = color.withAlphaComponent(0.98)
                            sphere.firstMaterial?.emission.contents = color.withAlphaComponent(0.2)
                        }
                    }
                }
            }
            
            // Store position
            lastPlacedPosition = arPosition
            
            // Generate unique marker ID for this node
            let markerID = UUID()
            
            // Set the marker node name with this ID (find last added node)
            if let markerNode = arView.scene.rootNode.childNodes.last {
                markerNode.name = "arMarker_\(markerID.uuidString)"
            }
            
            print("✅ Marker placed for \(mapPointID) at \(arPosition)")
            print("🔶 Session-temporary marker (not persisted)")
            print("   Node ID: \(markerID)")
            
            // Track session markers in interpolation mode
            if isInterpolationMode {
                if mapPointID == interpolationFirstPointID {
                    sessionMarkerA = (position: arPosition, mapPointID: mapPointID)
                    print("✅ Session Marker A stored at \(arPosition)")
                } else if mapPointID == interpolationSecondPointID {
                    sessionMarkerB = (position: arPosition, mapPointID: mapPointID)
                    print("✅ Session Marker B stored at \(arPosition)")
                }
                
                // If both session markers are now placed, draw connecting line
                if let markerA = sessionMarkerA, let markerB = sessionMarkerB {
                    print("🎯 Both session markers placed - drawing line")
                    drawConnectingLine(from: markerA.position, to: markerB.position)
                }
            }
            
            return markerID
        }
        
        // MARK: - Generated Marker Rendering
        
        /// Render all generated AR markers using shared marker creation logic
        func renderGeneratedMarkers(from mapPointStore: MapPointStore, calibrationIDs: [UUID]) {
            guard let arView = self.arView else {
                print("❌ No AR view available for rendering")
                return
            }
            
            print("🎨 Rendering \(mapPointStore.arMarkers.count) generated markers...")
            
            // Remove any existing generated marker nodes
            arView.scene.rootNode.childNodes
                .filter { $0.name?.hasPrefix("generated_marker_") == true }
                .forEach { $0.removeFromParentNode() }
            
            // Get the actual marker IDs from the calibration points
            let calibrationMarkerIDs = mapPointStore.calibrationPoints.map { $0.id }
            
            // Explicitly remove the 3 calibration marker nodes by their marker IDs
            for markerID in calibrationMarkerIDs {
                if let calibrationNode = arView.scene.rootNode.childNode(withName: "arMarker_\(markerID.uuidString)", recursively: false) {
                    calibrationNode.removeFromParentNode()
                    print("🧹 Removed calibration marker node: \(markerID)")
                }
            }
            
            // Create full AR marker for each generated marker
            for marker in mapPointStore.arMarkers {
                // Determine color: orange for calibration points, red for others
                let isCalibrationPoint = calibrationIDs.contains(marker.linkedMapPointID)
                let sphereColor = isCalibrationPoint 
                    ? UIColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 0.98)  // Orange
                    : UIColor(red: 0.8, green: 0.05, blue: 0.1, alpha: 0.98)  // Red
                
                let markerNode = createARMarkerNode(
                    at: marker.arPosition,
                    sphereColor: sphereColor,
                    markerID: marker.id,
                    userHeight: userHeight,
                    badgeColor: marker.isAnchor ? .systemTeal : nil
                )
                
                // Override name for generated markers
                markerNode.name = "generated_marker_\(marker.id.uuidString)"
                
                arView.scene.rootNode.addChildNode(markerNode)
            }
            
            let calibrationCount = mapPointStore.arMarkers.filter { calibrationIDs.contains($0.linkedMapPointID) }.count
            print("✅ Rendered \(mapPointStore.arMarkers.count) AR markers (\(calibrationCount) orange calibration, \(mapPointStore.arMarkers.count - calibrationCount) red)")
        }
        
        /// Draw line connecting two markers on ground plane
        func drawConnectingLine(from positionA: simd_float3, to positionB: simd_float3) {
            guard let arView = arView else { return }
            
            // Remove any existing line
            arView.scene.rootNode.childNode(withName: "interpolation_line", recursively: true)?.removeFromParentNode()
            
            // Calculate line geometry
            let direction = positionB - positionA
            let distance = simd_length(direction)
            
            // Create line as thin cylinder on ground
            let line = SCNCylinder(radius: 0.001, height: CGFloat(distance))
            line.firstMaterial?.diffuse.contents = UIColor.white
            
            let lineNode = SCNNode(geometry: line)
            lineNode.name = "interpolation_line"
            
            // Position line at midpoint (at marker ground level)
            let midpoint = (positionA + positionB) / 2
            lineNode.position = SCNVector3(midpoint.x, midpoint.y + 0.005, midpoint.z)
            
            // Calculate full 3D rotation to align cylinder with direction vector
            // Cylinder's default orientation is along Y-axis, so rotate Y-axis to align with direction
            let upVector = simd_normalize(direction)
            let defaultUp = simd_float3(0, 1, 0)
            
            // Calculate rotation needed using quaternion from two vectors
            let rotationAxis = simd_cross(defaultUp, upVector)
            let rotationAngle = acos(simd_dot(defaultUp, upVector))
            
            if simd_length(rotationAxis) > 0.0001 {
                let normalizedAxis = simd_normalize(rotationAxis)
                lineNode.simdOrientation = simd_quatf(angle: rotationAngle, axis: normalizedAxis)
            } else if simd_dot(defaultUp, upVector) < 0 {
                // Vectors are opposite (180° rotation)
                lineNode.simdOrientation = simd_quatf(angle: .pi, axis: simd_float3(1, 0, 0))
            }
            
            arView.scene.rootNode.addChildNode(lineNode)
            
            print("📏 Drew connecting line: \(String(format: "%.2f", distance))m")
            print("🔍 LINE DEBUG:")
            print("   Position: \(lineNode.position)")
            print("   Rotation: \(lineNode.eulerAngles)")
            print("   Geometry: radius=\(line.radius), height=\(line.height)")
            print("   Parent: \(lineNode.parent?.name ?? "nil")")
            print("   Scene has \(arView.scene.rootNode.childNodes.count) nodes")
        }
        
        // MARK: - Spatial Data Capture
        
        /// Extract feature points and planes around anchor position
        func captureSpatialData(at anchorPosition: simd_float3, captureRadius: Float = 5.0) -> AnchorSpatialData? {
            guard let arView = arView,
                  let frame = arView.session.currentFrame else {
                print("❌ Cannot capture spatial data - no AR frame available")
                return nil
            }
            
            print("📸 Capturing spatial data at \(anchorPosition)")
            print("   Capture radius: \(captureRadius)m")
            
            // Extract feature points
            let featureCloud = extractFeaturePoints(
                from: frame,
                around: anchorPosition,
                radius: captureRadius
            )
            
            // Extract plane anchors
            let planes = extractPlaneAnchors(
                from: frame,
                around: anchorPosition,
                radius: captureRadius
            )
            
            let spatialData = AnchorSpatialData(
                featureCloud: featureCloud,
                planes: planes
            )
            
            print("✅ Captured spatial data:")
            print("   Feature points: \(featureCloud.pointCount)")
            print("   Planes: \(planes.count)")
            print("   Total size: \(spatialData.totalDataSize) bytes")
            
            return spatialData
        }
        
        /// Extract raw feature points within radius
        private func extractFeaturePoints(from frame: ARFrame, around center: simd_float3, radius: Float) -> AnchorFeatureCloud {
            guard let rawFeaturePoints = frame.rawFeaturePoints else {
                print("⚠️ No raw feature points available")
                return AnchorFeatureCloud(points: [], anchorPosition: center, captureRadius: radius)
            }
            
            // Filter points within radius
            var nearbyPoints: [simd_float3] = []
            
            for i in 0..<rawFeaturePoints.points.count {
                let point = rawFeaturePoints.points[i]
                let distance = simd_distance(point, center)
                
                if distance <= radius {
                    nearbyPoints.append(point)
                }
            }
            
            print("   Filtered \(nearbyPoints.count) feature points within \(radius)m")
            
            return AnchorFeatureCloud(
                points: nearbyPoints,
                anchorPosition: center,
                captureRadius: radius
            )
        }
        
        /// Extract plane anchors within radius
        private func extractPlaneAnchors(from frame: ARFrame, around center: simd_float3, radius: Float) -> [AnchorPlaneData] {
            var planes: [AnchorPlaneData] = []
            
            for anchor in frame.anchors {
                guard let planeAnchor = anchor as? ARPlaneAnchor else { continue }
                
                let planePosition = simd_float3(
                    planeAnchor.transform.columns.3.x,
                    planeAnchor.transform.columns.3.y,
                    planeAnchor.transform.columns.3.z
                )
                
                let distance = simd_distance(planePosition, center)
                
                if distance <= radius {
                    let planeData = AnchorPlaneData(
                        planeID: planeAnchor.identifier,
                        transform: planeAnchor.transform,
                        extent: AnchorPlaneData.PlaneExtent(
                            width: planeAnchor.planeExtent.width,
                            height: planeAnchor.planeExtent.height
                        ),
                        alignment: planeAnchor.alignment == .horizontal ? .horizontal : .vertical
                    )
                    
                    planes.append(planeData)
                    
                    print("   Found \(planeData.alignment.rawValue) plane: \(planeData.extent.width)m x \(planeData.extent.height)m")
                }
            }
            
            return planes
        }
        
        // MARK: - Anchor Quality Calculation
        
        /// Calculate anchor quality score (0-100)
        func calculateAnchorQuality() -> (score: Int, instruction: String) {
            guard let arView = arView,
                  let frame = arView.session.currentFrame else {
                return (0, "Initializing AR tracking...")
            }
            
            var score = 0
            var instruction = "Move device slowly to detect surfaces"
            
            // Feature points (0-40 points)
            if let featurePoints = frame.rawFeaturePoints {
                let pointCount = featurePoints.points.count
                // Use accumulated count instead of current frame count
                let accumulatedCount = max(accumulatedFeaturePoints.count, pointCount)
                let featureScore = min(40, Int(Float(accumulatedCount) / 200.0 * 40.0))
                score += featureScore
            }
            
            // Planes detected (0-30 points)
            let planeCount = frame.anchors.filter { $0 is ARPlaneAnchor }.count
            // Use accumulated plane count
            let accumulatedPlaneCount = max(accumulatedPlanes.count, planeCount)
            let planeScore = min(30, accumulatedPlaneCount * 10)
            score += planeScore
            
            // Tracking quality (0-30 points)
            switch frame.camera.trackingState {
            case .normal:
                score += 30
            case .limited(.initializing):
                score += 10
            case .limited(.relocalizing):
                score += 15
            case .limited(.excessiveMotion):
                score += 5
                instruction = "Slow down - move device more slowly"
            case .limited(.insufficientFeatures):
                score += 5
                instruction = "Point at surfaces with more detail"
            default:
                break
            }
            
            // Update instruction based on score
            if score > 70 {
                instruction = "✓ Excellent anchor data captured!"
            } else if score > 40 {
                instruction = "Good! Keep moving to capture more detail"
            }
            
            return (score, instruction)
        }
        
        private func startQualityMonitoring(mapPointID: UUID, position: simd_float3) {
            // Clear accumulated data for new capture session
            accumulatedFeaturePoints.removeAll()
            accumulatedPlanes.removeAll()
            accumulatedReferenceImages.removeAll()
            captureStartTime = Date()
            capturedFloorFar = false
            capturedFloorClose = false
            capturedWalls = false
            isCapturingFloorMarker = false
            showFloorMarkerPositioning = false
            capturedFloorImage = nil
            pendingFloorMarkerPackageID = nil
            pendingFloorMarker = nil
            
            print("🔄 Started new accumulation session")
            
            // Reset state
            signatureImageCaptured = false
            anchorCountdown = nil
            
            // Update quality every 0.5 seconds
            qualityUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                
                let (score, instruction) = self.calculateAnchorQuality()
                
                DispatchQueue.main.async {
                    self.anchorQualityScore = score
                    self.anchorInstruction = self.signatureImageCaptured ? "Key Image Captured" : instruction
                    
                    // Accumulate feature points and planes
                    self.accumulateARData(at: position, captureRadius: 5.0)
                    
                    // Auto-capture reference images at quality thresholds
                    if score >= 70 && !self.capturedFloorFar {
                        self.captureReferenceImage(type: .floorFar)
                        self.capturedFloorFar = true
                    }
                    
                    if score >= 80 && !self.capturedFloorClose {
                        self.captureReferenceImage(type: .floorClose)
                        self.capturedFloorClose = true
                    }
                    
                    if score >= 85 && !self.capturedWalls {
                        // Capture 4 wall directions
                        self.captureReferenceImage(type: .wallNorth)
                        self.captureReferenceImage(type: .wallSouth)
                        self.captureReferenceImage(type: .wallEast)
                        self.captureReferenceImage(type: .wallWest)
                        self.capturedWalls = true
                    }
                    
                    print("📊 Quality: \(score)% - \(instruction) [Points: \(self.accumulatedFeaturePoints.count), Planes: \(self.accumulatedPlanes.count), Images: \(self.accumulatedReferenceImages.count)]")
                }
            }
        }
        
        func accumulateARData(at position: simd_float3, captureRadius: Float) {
            guard let arView = arView,
                  let frame = arView.session.currentFrame else { return }
            
            // Accumulate feature points within radius
            let rawPoints = frame.rawFeaturePoints?.points ?? []
            for point in rawPoints {
                let distance = simd_distance(point, position)
                if distance <= captureRadius {
                    // Only add if not too close to existing points (deduplicate)
                    let isDuplicate = accumulatedFeaturePoints.contains { existing in
                        simd_distance(existing, point) < 0.05  // 5cm threshold
                    }
                    if !isDuplicate {
                        accumulatedFeaturePoints.append(point)
                    }
                }
            }
            
            // Accumulate plane anchors (automatically deduplicates via dictionary)
            for anchor in frame.anchors {
                if let planeAnchor = anchor as? ARPlaneAnchor {
                    let planeCenter = simd_make_float3(planeAnchor.transform.columns.3)
                    let distance = simd_distance(planeCenter, position)
                    if distance <= captureRadius {
                        accumulatedPlanes[planeAnchor.identifier] = planeAnchor
                    }
                }
            }
        }
        
        func captureReferenceImage(type: AnchorReferenceImage.CaptureType) {
            guard let arView = arView,
                  let frame = arView.session.currentFrame else {
                print("❌ Cannot capture reference image - no AR frame")
                return
            }
            
            // Convert AR frame to JPEG
            let image = CIImage(cvPixelBuffer: frame.capturedImage)
            let context = CIContext()
            
            guard let cgImage = context.createCGImage(image, from: image.extent) else {
                print("❌ Failed to create CGImage for \(type.rawValue)")
                return
            }
            
            let uiImage = UIImage(cgImage: cgImage)
            
            guard let jpegData = uiImage.jpegData(compressionQuality: 0.7) else {
                print("❌ Failed to create JPEG for \(type.rawValue)")
                return
            }
            
            let referenceImage = AnchorReferenceImage(captureType: type, imageData: jpegData)
            accumulatedReferenceImages.append(referenceImage)
            
            print("📸 Auto-captured \(type.rawValue) reference image (\(jpegData.count / 1024) KB)")
        }
        
        private func startCountdown(mapPointID: UUID, position: simd_float3) {
            anchorCountdown = 10
            
            countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
                guard let self = self else {
                    timer.invalidate()
                    return
                }
                
                if let count = self.anchorCountdown, count > 1 {
                    self.anchorCountdown = count - 1
                } else {
                    timer.invalidate()
                    self.completeAnchorCapture(mapPointID: mapPointID, position: position)
                }
            }
        }
        
        private func completeAnchorCapture(mapPointID: UUID, position: simd_float3) {
            qualityUpdateTimer?.invalidate()
            countdownTimer?.invalidate()
            
            guard let arView = arView,
                  let currentFrame = arView.session.currentFrame else {
                print("❌ Cannot finalize anchor capture - missing AR frame")
                return
            }
            
            // Capture spatial data
            if let spatialData = captureSpatialData(at: position, captureRadius: 5.0),
               let mapPointStore = mapPointStore,
               let mapPoint = mapPointStore.points.first(where: { $0.id == mapPointID }) {
                
                mapPointStore.createAnchorPackage(
                    mapPointID: mapPointID,
                    patchID: activePatch?.id,
                    mapCoordinates: mapPoint.mapPoint,
                    anchorPosition: position,
                    anchorSessionTransform: currentFrame.camera.transform,
                    spatialData: spatialData
                )
            }
            
            // Reset capture state
            isCapturingAnchor = false
            anchorQualityScore = 0
            anchorInstruction = "Move device slowly to detect surfaces"
        }
        
        func captureSignatureImage(mapPointID: UUID, position: simd_float3) {
            guard let arView = arView,
                  let frame = arView.session.currentFrame else {
                print("❌ Cannot capture signature image - no AR frame")
                return
            }
            
            print("📸 Finalizing anchor package with signature image")
            
            let anchorSessionTransform = frame.camera.transform
            print("📊 Anchor created in session with camera transform:")
            print("   Position: \(simd_make_float3(anchorSessionTransform.columns.3))")
            
            // Capture signature image
            let image = CIImage(cvPixelBuffer: frame.capturedImage)
            let context = CIContext()
            
            guard let cgImage = context.createCGImage(image, from: image.extent) else {
                print("❌ Failed to create CGImage for signature")
                return
            }
            
            let uiImage = UIImage(cgImage: cgImage)
            
            guard let jpegData = uiImage.jpegData(compressionQuality: 0.8) else {
                print("❌ Failed to create JPEG for signature")
                return
            }
            
            let signatureImage = AnchorReferenceImage(captureType: .signature, imageData: jpegData)
            accumulatedReferenceImages.append(signatureImage)
            signatureImageCaptured = true
            
            print("✅ Signature image captured (\(jpegData.count / 1024) KB)")
            
            // Milestone 4: Prompt for floor marker capture
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isCapturingFloorMarker = true
                self.showFloorCapturePrompt()
            }
            
            // Build spatial data from accumulated data
            let featureCloud = AnchorFeatureCloud(
                points: accumulatedFeaturePoints,
                anchorPosition: position,
                captureRadius: 5.0
            )
            
            let planeData = accumulatedPlanes.values.map { planeAnchor in
                AnchorPlaneData(
                    planeID: planeAnchor.identifier,
                    transform: planeAnchor.transform,
                    extent: AnchorPlaneData.PlaneExtent(
                        width: planeAnchor.planeExtent.width,
                        height: planeAnchor.planeExtent.height
                    ),
                    alignment: planeAnchor.alignment == .horizontal ? .horizontal : .vertical
                )
            }
            
            let spatialData = AnchorSpatialData(
                featureCloud: featureCloud,
                planes: planeData
            )
            
            print("📊 Final accumulated data:")
            print("   Feature points: \(accumulatedFeaturePoints.count)")
            print("   Planes: \(planeData.count)")
            print("   Reference images: \(accumulatedReferenceImages.count)")
            print("   Total spatial data: \(spatialData.totalDataSize / 1024) KB")
            
            // Create anchor package with accumulated data
            guard let mapPointStore = mapPointStore,
                  let mapPoint = mapPointStore.points.first(where: { $0.id == mapPointID }) else {
                print("❌ Cannot find map point")
                return
            }
            
            var package = AnchorPointPackage(
                mapPointID: mapPointID,
                mapCoordinates: mapPoint.mapPoint,
                anchorPosition: position,
                anchorSessionTransform: anchorSessionTransform
            )
            
            package.spatialData = spatialData
            package.referenceImages = accumulatedReferenceImages
            
            // Add to store
            mapPointStore.anchorPackages.append(package)
            mapPointStore.saveAnchorPackages()
            pendingFloorMarkerPackageID = package.id
            pendingFloorMarker = nil
            
            print("✅ Created Anchor Package \(package.id) for MapPoint \(mapPointID)")
            print("   Complete with \(accumulatedReferenceImages.count) reference images")
            print("\n🔍 CAPTURE RELATIONSHIP CHECK:")
            print("   Anchor position: \(position)")
            if let floorMarker = package.floorMarker {
                print("   Floor marker captured: YES")
                print("   Floor marker coords on image: \(floorMarker.markerCoordinates)")
                print("   ⚠️ Need to add: Floor marker world position at capture time")
                print("   ⚠️ Need to calculate: offset = anchor_position - floor_marker_position")
                print("   ⚠️ This offset should be stored in AnchorPointPackage")
            } else {
                print("   Floor marker: NOT CAPTURED")
            }
            print("")
            
            // Stop quality monitoring
            qualityUpdateTimer?.invalidate()
            isCapturingAnchor = false
            anchorQualityScore = 0
            anchorInstruction = "Move device slowly to detect surfaces"
            
            // Clear accumulated data
            accumulatedFeaturePoints.removeAll()
            accumulatedPlanes.removeAll()
            accumulatedReferenceImages.removeAll()
            
            print("✅ Anchor package complete with signature image")
        }
        
        // MARK: - Milestone 4: Floor Marker Capture
        
        func showFloorCapturePrompt() {
            print("📸 FLOOR MARKER: Ready to capture floor reference")
            print("   Point camera straight down at the floor beneath anchor marker")
            
            // Future UI integration hook
            // UI should present instructions and capture button
        }
        
        func captureFloorMarkerImage() {
            guard let arView = arView,
                  let currentFrame = arView.session.currentFrame else {
                print("❌ No current frame available for floor capture")
                return
            }
            
            let pixelBuffer = currentFrame.capturedImage
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext()
            
            guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
                print("❌ Failed to convert floor capture to CGImage")
                return
            }
            
            let uiImage = UIImage(cgImage: cgImage)
            capturedFloorImage = uiImage
            
            print("📸 Floor marker image captured")
            print("   Image size: \(uiImage.size)")
            print("📐 Calculating floor marker 3D position...")
            
            if let anchorPosition = currentCapturePosition {
                
                let centerPoint = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)
                
                // Use scene mesh if available (LiDAR), fallback to plane geometry
                let meshEnabled = (arView.session.configuration as? ARWorldTrackingConfiguration)?.sceneReconstruction == .mesh
                
                let raycastTarget: ARRaycastQuery.Target = meshEnabled ? .existingPlaneGeometry : .existingPlaneGeometry
                
                if let raycastQuery = arView.raycastQuery(from: centerPoint,
                                                          allowing: raycastTarget,
                                                          alignment: .horizontal) {
                    let raycastResults = arView.session.raycast(raycastQuery)
                    
                    if let result = raycastResults.first {
                        let method = meshEnabled ? "LiDAR mesh" : "plane detection"
                        print("   ✅ Raycast successful using \(method)")
                        let floorMarkerPosition = simd_make_float3(result.worldTransform.columns.3)
                        let offset = anchorPosition - floorMarkerPosition
                        
                        print("   Floor marker 3D position: \(floorMarkerPosition)")
                        print("   Anchor position: \(anchorPosition)")
                        print("   Calculated offset (anchor - floor): \(offset)")
                        print("   Offset magnitude: \(simd_length(offset) * 100) cm")
                        
                        var transform = matrix_identity_float4x4
                        transform.columns.3 = simd_float4(offset.x, offset.y, offset.z, 1.0)
                        capturedFloorMarkerOffset = offset
                        capturedFloorMarkerTransform = transform
                    } else {
                        print("   ⚠️ Could not determine floor marker position via raycast")
                        print("   Package will be saved without spatial relationship data")
                        capturedFloorMarkerOffset = nil
                        capturedFloorMarkerTransform = nil
                    }
                } else {
                    print("   ⚠️ Could not build raycast query for floor marker")
                    print("   Package will be saved without spatial relationship data")
                    capturedFloorMarkerOffset = nil
                    capturedFloorMarkerTransform = nil
                }
            } else {
                print("   ⚠️ Missing required data to calculate floor marker position")
                capturedFloorMarkerOffset = nil
                capturedFloorMarkerTransform = nil
            }
            
            print("   Ready for position calibration")
            
            isCapturingFloorMarker = false
            showFloorMarkerPositioning = true
        }
        
        func finalizeFloorMarkerCapture(coordinates: CGPoint) {
            guard let image = capturedFloorImage else {
                print("❌ No floor image available to finalize")
                return
            }
            
            guard let jpegData = image.jpegData(compressionQuality: 0.9) else {
                print("❌ Failed to encode floor marker image")
                return
            }
            
            let floorMarker = FloorMarkerCapture(
                imageData: jpegData,
                markerCoordinates: coordinates,
                imageSize: image.size
            )
            
            pendingFloorMarker = floorMarker
            capturedFloorImage = nil
            showFloorMarkerPositioning = false
            
            guard let packageID = pendingFloorMarkerPackageID else {
                print("⚠️ Floor marker captured but no pending package to attach")
                capturedFloorMarkerOffset = nil
                capturedFloorMarkerTransform = nil
                return
            }
            
            guard let mapPointStore = mapPointStore else {
                print("❌ No MapPointStore available to store floor marker")
                capturedFloorMarkerOffset = nil
                capturedFloorMarkerTransform = nil
                return
            }
            
            if let index = mapPointStore.anchorPackages.firstIndex(where: { $0.id == packageID }) {
                mapPointStore.anchorPackages[index].floorMarker = floorMarker
                mapPointStore.anchorPackages[index].floorMarkerToAnchorTransform = capturedFloorMarkerTransform
                mapPointStore.saveAnchorPackages()
                print("📐 Floor marker included in anchor package")
                print("   Package ID: \(packageID)")
                print("   Marker coordinates: \(coordinates)")
                if let transform = capturedFloorMarkerTransform {
                    let offset = simd_make_float3(transform.columns.3)
                    print("   ✅ Stored floor marker transform")
                    print("      Translation: \(offset)")
                    print("      Magnitude: \(simd_length(offset) * 100) cm")
                } else {
                    print("   ⚠️ No spatial transform stored - precision will be limited")
                }
                pendingFloorMarkerPackageID = nil
                pendingFloorMarker = nil
                capturedFloorMarkerOffset = nil
                capturedFloorMarkerTransform = nil
            } else {
                print("⚠️ Could not find anchor package \(packageID) to attach floor marker")
                capturedFloorMarkerOffset = nil
                capturedFloorMarkerTransform = nil
            }
        }
        
        func cancelFloorMarkerCapture() {
            capturedFloorImage = nil
            isCapturingFloorMarker = false
            showFloorMarkerPositioning = false
            capturedFloorMarkerOffset = nil
            capturedFloorMarkerTransform = nil
            print("⚠️ Floor marker capture canceled")
        }
        
        func startRelocalization() {
            guard let mapPointStore = mapPointStore else {
                print("❌ No MapPointStore available")
                return
            }
            
            print("🔍 Starting relocalization mode")
            didEnableImageDetection = false
            placedAnchorMarkers.removeAll()
            
            let availablePackages: [AnchorPointPackage]
            if let patch = activePatch {
                availablePackages = mapPointStore.anchorPackages(forPatchID: patch.id)
                print("   Filtering anchor packages for patch \(patch.id)")
            } else {
                availablePackages = mapPointStore.anchorPackages
                print("   Using all anchor packages (legacy/global map)")
            }
            
            print("   Anchor packages available: \(availablePackages.count)")
            
            // Load anchor packages for this session
            activeRelocalizationPackages = availablePackages
            
            if activeRelocalizationPackages.isEmpty {
                print("⚠️ No anchor packages available for relocalization")
                relocalizationState = .failed
                return
            }
            
            // Enter relocalization mode
            isRelocalizationMode = true
            relocalizationState = .searching
            
            let categorizedImages = prepareReferenceImages()
            let totalImageCount = categorizedImages.values.reduce(0) { $0 + $1.count }
            if totalImageCount == 0 {
                print("⚠️ No reference images available for image detection - will rely on spatial relocalization only")
            }
            
            var groundPlaneReady = false
            if let arView = arView {
                let allAnchors = arView.session.currentFrame?.anchors ?? []
                let horizontalPlanes = allAnchors.compactMap { $0 as? ARPlaneAnchor }
                    .filter { $0.alignment == .horizontal }
                
                if horizontalPlanes.isEmpty {
                    print("⚠️ No ground planes detected yet")
                    print("   (AR session running - planes may be detected soon)")
                    groundPlaneReady = false
                } else {
                    print("✅ \(horizontalPlanes.count) ground plane(s) already detected and ready")
                    print("   Using existing AR session data for anchor placement")
                    groundPlaneReady = true
                }
            }
            
            if let arView = arView {
                if slamIsReady(arView.session) {
                    if groundPlaneReady {
                        let floorSet = (categorizedImages["floor_near"] ?? [])
                            .union(categorizedImages["floor_mid"] ?? [])
                        
                        if !floorSet.isEmpty {
                            preserveAndRun({ config in
                                config.detectionImages = floorSet
                                config.maximumNumberOfTrackedImages = 2
                            }, session: arView.session)
                        }
                        
                        currentDetectionPhase = .precision
                        print("🎯 SLAM + Ground ready - starting FLOOR targets (precision-first)")
                        print("   Floor images: \(floorSet.count), Max tracked: 2")
                        
                        if totalImageCount > 0 {
                            escalateDetectionIfNoLock(after: 2.0, categorizedImages: categorizedImages)
                        }
                        
                        relocalizationState = .imageTracking
                    } else {
                        let wallSet = categorizedImages["wall"] ?? []
                        
                        if !wallSet.isEmpty {
                            preserveAndRun({ config in
                                config.detectionImages = wallSet
                                config.maximumNumberOfTrackedImages = min(1, wallSet.count)
                            }, session: arView.session)
                        }
                        
                        currentDetectionPhase = .longRange
                        print("🎯 SLAM ready, Ground not ready - starting WALL targets")
                        print("   Wall images: \(wallSet.count), Max tracked: 1")
                        
                        if totalImageCount > 0 {
                            escalateDetectionIfNoLock(after: 2.0, categorizedImages: categorizedImages)
                        }
                        
                        relocalizationState = .imageTracking
                    }
                } else {
                    print("⏳ Waiting for SLAM readiness before image tracking")
                    relocalizationState = .searching
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                        guard let self = self, self.relocalizationState == .searching else { return }
                        print("🔄 Retrying detection start...")
                        self.startRelocalization()
                    }
                }
            }
            
            print("✅ Relocalization mode active")
            print("   Loaded \(activeRelocalizationPackages.count) anchor package(s)")
        
        for package in activeRelocalizationPackages {
            print("\n🔍 FLOOR MARKER DATA CHECK for package \(package.id.uuidString.prefix(8)):")
            if let floorMarker = package.floorMarker {
                print("   ✅ Floor marker exists")
                print("      Image size: \(Int(floorMarker.imageSize.width)) x \(Int(floorMarker.imageSize.height)) pixels")
                print("      Image data: \(floorMarker.imageData.count) bytes")
                print("      Calibrated coords: (\(floorMarker.markerCoordinates.x), \(floorMarker.markerCoordinates.y))")
                if let transform = package.floorMarkerToAnchorTransform {
                    let offset = simd_make_float3(transform.columns.3)
                    print("      ✅ Spatial transform stored")
                    print("         Translation: \(offset)")
                    print("         Magnitude: \(simd_length(offset) * 100) cm")
                } else {
                    print("      ❌ NO spatial transform - precision limited")
                }
            } else {
                print("   ❌ NO FLOOR MARKER - package was created before floor marker feature")
                print("      This package needs to be recaptured to include floor marker")
            }
            
            print("   Anchor point data:")
            print("      MapPoint ID: \(package.mapPointID.uuidString)")
            print("      Map coordinates: \(package.mapCoordinates)")
            print("      Anchor position (old session): \(package.anchorPosition)")
            print("      Session transform available: \(package.anchorSessionTransform != matrix_identity_float4x4)")
        }
        print("")
            
        }
        
        /// Clean up all AR markers from the scene
        func cleanupAllARMarkers() {
            guard let arView = arView else { return }
            let markerNodes = arView.scene.rootNode.childNodes.filter { node in
                node.name?.starts(with: "arMarker_") == true
            }
            let count = markerNodes.count
            if count > 0 {
                print("🧹 Cleaning up AR marker nodes from scene")
            }
            for node in markerNodes {
                node.removeFromParentNode()
            }
            if count > 0 {
                print("   Removed \(count) AR marker node(s)")
            }
        }

        func stopRelocalization() {
            cleanupAllARMarkers()
            guard relocalizationState != .idle else {
                print("⚠️ Relocalization already idle")
                return
            }
            currentDetectionPhase = .idle
            resetStabilityTracking()
            detectionStabilityCheckTimer?.invalidate()
            detectionStabilityCheckTimer = nil
            
            print("🛑 Stopping relocalization mode")
            isRelocalizationMode = false
            relocalizationState = .idle
            
            // Log detection statistics
            for (packageID, count) in anchorDetectionCounts {
                if count > 1 {
                    print("📊 Anchor \(packageID.uuidString.prefix(8))... detected \(count) times (but only placed once)")
                }
            }
            anchorDetectionCounts.removeAll()
            
            if !pendingAnchorDetections.isEmpty {
                print("🧹 Cleared \(pendingAnchorDetections.count) pending anchor detection(s)")
            }
            pendingAnchorDetections.removeAll()
            
            placedAnchorMarkers.removeAll()
            activeRelocalizationPackages.removeAll()
        }
        
        private func createReferenceImage(from imageData: Data,
                                          named name: String,
                                          imageType: String) -> ARReferenceImage? {
            guard let uiImage = UIImage(data: imageData),
                  let cgImage = uiImage.cgImage else {
                print("⚠️ Failed to convert image '\(name)' for ARReferenceImage creation")
                return nil
            }
            
            // Physical width based on image type for optimal detection range
            let physicalWidth: CGFloat
            switch imageType {
            case "wall_north", "wall_south", "wall_east", "wall_west":
                physicalWidth = 1.2  // 1.2m - detectable from 3-5 meters
                print("   Creating wall image '\(name)' with physical width: \(physicalWidth)m (long-range)")
            case "floor_far":
                physicalWidth = 0.8  // 0.8m - detectable from 2-3 meters
                print("   Creating floor_far image '\(name)' with physical width: \(physicalWidth)m (mid-range)")
            case "floor_close":
                physicalWidth = 0.6  // 0.6m - detectable from 1-2 meters
                print("   Creating floor_close image '\(name)' with physical width: \(physicalWidth)m (approach)")
            case "floor_marker":
                physicalWidth = 0.4  // 0.4m - precision placement
                print("   Creating floor_marker image '\(name)' with physical width: \(physicalWidth)m (precision)")
            default:
                physicalWidth = 0.4  // fallback
                print("   Creating image '\(name)' with default physical width: \(physicalWidth)m")
            }
            
            let referenceImage = ARReferenceImage(cgImage,
                                                  orientation: .up,
                                                  physicalWidth: physicalWidth)
            referenceImage.name = name
            return referenceImage
        }
        
        func prepareReferenceImages() -> [String: Set<ARReferenceImage>] {
            guard arView != nil else { return [:] }
            
            print("🖼️ Preparing reference images for ARKit tracking...")
            
            var categorized: [String: Set<ARReferenceImage>] = [
                "wall": Set(),
                "floor_mid": Set(),
                "floor_near": Set()
            ]
            
            let maxImages = 6
            var totalImageCount = 0
            var imageCapReached = false
            
            for package in activeRelocalizationPackages {
                if imageCapReached { break }
                
                if let floorMarker = package.floorMarker,
                   let markerImage = createReferenceImage(
                    from: floorMarker.imageData,
                    named: "floor_marker_\(package.id.uuidString)",
                    imageType: "floor_marker"
                   ) {
                    categorized["floor_near"]?.insert(markerImage)
                    totalImageCount += 1
                    print("   ✓ Floor marker: physical width \(markerImage.physicalSize.width)m (\(totalImageCount)/\(maxImages))")
                    
                    if totalImageCount >= maxImages {
                        print("   ⚠️ Hit image cap (\(maxImages)) - skipping remaining images")
                        imageCapReached = true
                        break
                    }
                }
                
                for refImage in package.referenceImages {
                    if totalImageCount >= maxImages {
                        print("   ⚠️ Hit image cap (\(maxImages)) - skipping remaining images")
                        imageCapReached = true
                        break
                    }
                    
                    let imageType = refImage.captureType.rawValue
                    let imageName = "\(package.id.uuidString)-\(imageType)"
                    
                    if let referenceImage = createReferenceImage(
                        from: refImage.imageData,
                        named: imageName,
                        imageType: imageType
                    ) {
                        switch imageType {
                        case "wall_north", "wall_south", "wall_east", "wall_west":
                            categorized["wall"]?.insert(referenceImage)
                        case "floor_far":
                            categorized["floor_mid"]?.insert(referenceImage)
                        case "floor_close":
                            categorized["floor_near"]?.insert(referenceImage)
                        default:
                            break
                        }
                        
                        totalImageCount += 1
                        print("   ✓ \(imageType): physical width \(referenceImage.physicalSize.width)m (\(totalImageCount)/\(maxImages))")
                    }
                }
            }
            
            print("✅ Prepared \(totalImageCount) reference images")
            print("   Wall images: \(categorized["wall"]?.count ?? 0)")
            print("   Floor mid images: \(categorized["floor_mid"]?.count ?? 0)")
            print("   Floor near images: \(categorized["floor_near"]?.count ?? 0)")
            
            return categorized
        }
        
        func handleDetectedImage(_ imageAnchor: ARImageAnchor) {
            guard let imageName = imageAnchor.referenceImage.name else { return }
            
            guard let packageID = extractPackageID(from: imageName) else {
                print("⚠️ Could not extract package ID from image name: \(imageName)")
                return
            }
            
            // Track detection count for diagnostics
            anchorDetectionCounts[packageID, default: 0] += 1
            let detectionCount = anchorDetectionCounts[packageID]!
            print("🎯 Detected reference image for package: \(packageID) (detection #\(detectionCount))")
            
            // Find matching anchor package
            guard let package = activeRelocalizationPackages.first(where: { $0.id == packageID }) else {
                print("⚠️ Could not find anchor package for detected image")
                return
            }
            
            // NEW: Check if already placed - do this BEFORE validation
            if placedAnchorMarkers.contains(packageID) {
                // Already placed this anchor - silently ignore subsequent detections
                // This prevents drift from multiple position calculations
                return
            }
            
            print("✅ Matched to anchor package for MapPoint: \(package.mapPointID)")
            print("   This is the FIRST detection - will place marker")
            
            // Store transform for validation
            foundAnchorTransforms[packageID] = imageAnchor.transform
            
            relocalizationState = .validating
            
            // Validate and calculate coordinate transform
            validateAndCalculateTransform(
                package: package,
                detectedTransform: imageAnchor.transform,
                imageAnchor: imageAnchor
            )
        }
        
        func extractPackageID(from imageName: String) -> UUID? {
            print("🔍 Extracting package ID from: \(imageName)")
            
            if imageName.starts(with: "floor_marker_") {
                let uuidString = String(imageName.dropFirst("floor_marker_".count))
                print("   Floor marker detected, UUID string: \(uuidString)")
                if let uuid = UUID(uuidString: uuidString) {
                    print("   ✓ Successfully parsed floor marker UUID: \(uuid.uuidString.prefix(8))")
                    return uuid
                } else {
                    print("   ✗ Failed to parse UUID from: \(uuidString)")
                    return nil
                }
            }
            
            let parts = imageName.components(separatedBy: "-")
            if parts.count >= 5 {
                let uuidString = parts[0...4].joined(separator: "-")
                print("   Regular image, reconstructed UUID: \(uuidString)")
                if let uuid = UUID(uuidString: uuidString) {
                    print("   ✓ Successfully parsed UUID: \(uuid.uuidString.prefix(8))")
                    return uuid
                }
            }
            
            print("   ✗ Could not parse UUID from image name")
            return nil
        }
        
        func validateAndCalculateTransform(package: AnchorPointPackage, detectedTransform: simd_float4x4, imageAnchor: ARImageAnchor? = nil) {
            print("🔍 Validation details:")
            
            // Extract positions
            let detectedImagePosition = simd_make_float3(detectedTransform.columns.3)
            let savedAnchorPosition = package.anchorPosition
            
            print("   Detected image at (current session): \(detectedImagePosition)")
            print("   Saved anchor position (old session): \(savedAnchorPosition)")
            
            if let anchor = imageAnchor,
               isFloorMarkerImage(anchor),
               let floorMarker = package.floorMarker {
                print("📐 PRECISION MODE: Floor marker detected!")
                placePreciseAnchorMarker(
                    package: package,
                    floorTransform: detectedTransform,
                    floorMarker: floorMarker,
                    imageAnchor: anchor
                )
                return
            } else if let anchor = imageAnchor,
                      isFloorMarkerImage(anchor) {
                print("⚠️ Floor marker image detected, but package has no floor marker data!")
                print("   This should not happen - indicates data corruption")
            }
            
            guard let arView = arView,
                  let currentFrame = arView.session.currentFrame else {
                print("❌ No AR session available")
                relocalizationState = .failed
                return
            }
            
            // CRITICAL: Check ALL anchors in the session (not just current frame)
            // Planes persist across frames once detected
            let allAnchors = arView.session.currentFrame?.anchors ?? []
            let horizontalPlanes = allAnchors.compactMap { $0 as? ARPlaneAnchor }
                .filter { $0.alignment == .horizontal }
            
            print("   Session tracking \(allAnchors.count) anchor(s), \(horizontalPlanes.count) horizontal plane(s)")
            
            if horizontalPlanes.isEmpty {
                print("⏳ Waiting for ground plane detection...")
                print("   Image detected but cannot place marker without ground reference")
                
                // Store for later placement when ground is detected
                if let anchor = imageAnchor {
                    let captureName = anchor.referenceImage.name ?? ""
                    pendingAnchorDetections[package.id] = (anchor: anchor, captureType: captureName)
                }
                relocalizationState = .imageTracking  // Still searching
                return
            }
            
            print("✅ Ground plane available - proceeding with placement")
            
            // Use the detected image position as reference point
            // Project down to ground to find where anchor should be
            let rayOrigin = detectedImagePosition
            let rayDirection = simd_float3(0, -1, 0)  // Straight down
            
            // Create raycast query for ground
            let query = ARRaycastQuery(
                origin: rayOrigin,
                direction: rayDirection,
                allowing: .estimatedPlane,
                alignment: .horizontal
            )
            
            let results = arView.session.raycast(query)
            
            guard let firstResult = results.first else {
                print("⚠️ Could not raycast to ground from detected image")
                print("   Using closest horizontal plane as fallback")
                
                // Fallback: use closest horizontal plane
                if let closestPlane = horizontalPlanes.min(by: { plane1, plane2 in
                    let dist1 = simd_distance(detectedImagePosition, simd_make_float3(plane1.transform.columns.3))
                    let dist2 = simd_distance(detectedImagePosition, simd_make_float3(plane2.transform.columns.3))
                    return dist1 < dist2
                }) {
                    let planeY = closestPlane.transform.columns.3.y
                    let groundPosition = simd_float3(detectedImagePosition.x, planeY, detectedImagePosition.z)
                    
                    print("   Using plane at y=\(planeY)")
                    print("   Ground position: \(groundPosition)")
                    
                    relocalizationState = .success
                    placeFoundAnchorMarker(package: package, transformedPosition: groundPosition)
                    return
                }
                
                print("❌ No suitable ground plane found")
                relocalizationState = .failed
                return
            }
            
            // Use the ground intersection point
            let groundPosition = simd_make_float3(firstResult.worldTransform.columns.3)
            
            print("   Transformed to ground position: \(groundPosition)")
            print("✅ Anchor position transformed to current session!")
            
            relocalizationState = .success
            placeFoundAnchorMarker(package: package, transformedPosition: groundPosition)
        }
        
        func placePreciseAnchorMarker(package: AnchorPointPackage,
                                      floorTransform: simd_float4x4,
                                      floorMarker: FloorMarkerCapture,
                                      imageAnchor: ARImageAnchor) {
            print("\n═══ FLOOR MARKER DATA ACCESS ═══")
            print("   Package ID: \(package.id.uuidString.prefix(8))")
            print("   Floor marker available: YES")
            print("   Image dimensions: \(Int(floorMarker.imageSize.width)) x \(Int(floorMarker.imageSize.height))")
            print("   Calibrated crosshairs position:")
            print("      X: \(floorMarker.markerCoordinates.x) (0.0=left, 1.0=right)")
            print("      Y: \(floorMarker.markerCoordinates.y) (0.0=top, 1.0=bottom)")
            print("   Anchor point position (when captured): \(package.anchorPosition)")
            print("═══════════════════════════════════\n")
            let imagePosition = simd_make_float3(floorTransform.columns.3)
            let imageRotation = simd_quatf(floorTransform)
            let calibratedX = Float(floorMarker.markerCoordinates.x)
            let calibratedY = Float(floorMarker.markerCoordinates.y)
            
            print("📐 Calculating precise position from floor marker")
            print("   Image detected at: \(imagePosition)")
            print("   Image rotation (quat): \(imageRotation)")
            print("   Calibrated coords: (\(calibratedX), \(calibratedY))")
            
            // Get physical dimensions of the detected floor image
            // This should match what we told ARKit when creating the reference image
            let physicalWidth: Float = 0.4  // 40cm width (set when creating ARReferenceImage)
            
            // Calculate height maintaining aspect ratio
            let aspectRatio = Float(floorMarker.imageSize.height / floorMarker.imageSize.width)
            let physicalHeight = physicalWidth * aspectRatio
            
            print("   Floor marker image size: \(Int(floorMarker.imageSize.width)) x \(Int(floorMarker.imageSize.height)) pixels")
            print("   Aspect ratio: \(aspectRatio)")
            print("   Physical size: \(physicalWidth)m x \(physicalHeight)m")
            
            // Verify detected image physical size matches what we set
            let detectedPhysicalWidth = imageAnchor.referenceImage.physicalSize.width
            print("   ARKit detected physical width: \(detectedPhysicalWidth)m")
            if abs(Float(detectedPhysicalWidth) - physicalWidth) > 0.01 {
                print("   ⚠️ Size mismatch! Expected \(physicalWidth)m, detected \(detectedPhysicalWidth)m")
            }
            
            // Calculate offset from image center to calibrated position
            // Image coordinates: (0,0) = top-left, (1,1) = bottom-right
            // Offset in normalized space relative to center (0.5, 0.5)
            let normalizedOffsetX = calibratedX - 0.5  // Positive = right in image
            let normalizedOffsetY = calibratedY - 0.5  // Positive = down in image
            
            // Scale by physical dimensions
            let physicalOffsetX = normalizedOffsetX * physicalWidth
            let physicalOffsetY = normalizedOffsetY * physicalHeight
            
            print("   Normalized offset: (\(normalizedOffsetX), \(normalizedOffsetY))")
            print("   Physical offset: X=\(physicalOffsetX)m, Y=\(physicalOffsetY)m")
            
            // Use image anchor's transform to get local coordinate axes
            // The transform columns give us the image's orientation in world space
            let imageTransform = floorTransform
            let imageRight = simd_make_float3(imageTransform.columns.0)    // X-axis: right in image
            let imageUp = simd_make_float3(imageTransform.columns.1)       // Y-axis: up from image plane
            let imageForward = simd_make_float3(imageTransform.columns.2)  // Z-axis: forward (into/out of image)
            
            print("   Image axes:")
            print("      Right: \(imageRight)")
            print("      Up: \(imageUp)")
            print("      Forward: \(imageForward)")
            
            // For a floor image lying flat:
            // - imageRight = right direction in the real world
            // - imageUp = normal to the surface (should point up)
            // - imageForward = forward direction in the real world
            
            // Calculate world-space offset using image's actual orientation
            // X offset: move along the image's right direction
            // Y offset: move along the image's forward direction (since image is flat)
            let worldOffset = imageRight * physicalOffsetX + imageForward * physicalOffsetY
            
            print("   World-space offset: \(worldOffset)")
            
            let precisePositionBeforeGroundProjection = imagePosition + worldOffset
            print("\n🔍 RELATIONSHIP ANALYSIS:")
            print("   Floor marker detected at: \(imagePosition)")
            print("   Crosshairs offset applied: \(worldOffset)")
            print("   Precise floor marker position: \(precisePositionBeforeGroundProjection)")
            
            let upDotY = simd_dot(imageUp, simd_float3(0, 1, 0))
            print("   Image orientation check:")
            print("      Up vector alignment with world Y: \(upDotY)")
            
            if abs(upDotY) < 0.7 {
                print("   ⚠️ Warning: Floor marker not horizontal (dot product: \(upDotY))")
                print("      Expected ~1.0 for horizontal surface")
            }
            
            print("   Precise position (before ground projection): \(precisePositionBeforeGroundProjection)")
            
            if let transform = package.floorMarkerToAnchorTransform {
                let offset = simd_make_float3(transform.columns.3)
                print("\n✅ USING STORED SPATIAL RELATIONSHIP:")
                print("   Stored transform translation: \(offset)")
                print("   Floor marker now at: \(precisePositionBeforeGroundProjection)")
                
                var floorMarkerWorld = floorTransform
                floorMarkerWorld.columns.3 = simd_float4(
                    precisePositionBeforeGroundProjection.x,
                    precisePositionBeforeGroundProjection.y,
                    precisePositionBeforeGroundProjection.z,
                    1.0
                )
                
                let anchorTransform = floorMarkerWorld * transform
                let calculatedAnchorPosition = simd_make_float3(anchorTransform.columns.3)
                print("   Calculated anchor position: \(calculatedAnchorPosition)")
                print("   Offset magnitude: \(simd_length(offset) * 100) cm")
                
                guard let arView = arView else {
                    print("❌ No ARView available")
                    relocalizationState = .failed
                    return
                }
                
                let allAnchors = arView.session.currentFrame?.anchors ?? []
                let horizontalPlanes = allAnchors.compactMap { $0 as? ARPlaneAnchor }
                    .filter { $0.alignment == .horizontal }
                
                if let groundPlane = horizontalPlanes.min(by: { plane1, plane2 in
                    let dist1 = abs(calculatedAnchorPosition.y - plane1.transform.columns.3.y)
                    let dist2 = abs(calculatedAnchorPosition.y - plane2.transform.columns.3.y)
                    return dist1 < dist2
                }) {
                    let groundY = groundPlane.transform.columns.3.y
                    let finalPosition = simd_float3(calculatedAnchorPosition.x, groundY, calculatedAnchorPosition.z)
                    
                    print("   Projected to ground plane at y=\(groundY)")
                    print("   Final precise position: \(finalPosition)")
                    print("✅ HIGH PRECISION PLACEMENT using spatial relationship + crosshairs")
                    
                    relocalizationState = .success
                    placeFoundAnchorMarker(package: package, transformedPosition: finalPosition)
                    return
                } else {
                    print("⚠️ No ground plane, using calculated position")
                    relocalizationState = .success
                    placeFoundAnchorMarker(package: package, transformedPosition: calculatedAnchorPosition)
                    return
                }
            } else {
                print("\n⚠️ NO SPATIAL RELATIONSHIP DATA:")
                print("   Package was created before spatial transform feature")
                print("   OR floor marker position couldn't be determined at capture")
                print("   Using floor marker position directly (will be inaccurate)")
                print("   Need to recapture package to get precision")
                
                relocalizationState = .success
                placeFoundAnchorMarker(package: package, transformedPosition: precisePositionBeforeGroundProjection)
                return
            }
        }
        
        func isFloorMarkerImage(_ imageAnchor: ARImageAnchor) -> Bool {
            guard let imageName = imageAnchor.referenceImage.name else {
                return false
            }
            
            return imageName.starts(with: "floor_marker_")
        }
        
        func placeFoundAnchorMarker(package: AnchorPointPackage, transformedPosition: simd_float3) {
            guard let arView = arView else { return }
            
            // Mark as placed IMMEDIATELY to prevent any race conditions
            placedAnchorMarkers.insert(package.id)
            
            print("🔶 Placing visual marker for found Anchor Point")
            print("   MapPoint ID: \(package.mapPointID)")
            print("   Transformed position (current session): \(transformedPosition)")
            
            let markerNode = createARMarkerNode(
                at: transformedPosition,
                sphereColor: .systemOrange,
                markerID: package.id,
                userHeight: 1.05,  // Standard AR Marker height
                badgeColor: .systemYellow
            )
            
            if let badgeNode = markerNode.childNode(withName: "badge_\(package.id.uuidString)", recursively: true) {
                let scaleUp = SCNAction.scale(to: 1.3, duration: 0.8)
                let scaleDown = SCNAction.scale(to: 1.0, duration: 0.8)
                let pulse = SCNAction.sequence([scaleUp, scaleDown])
                let repeatPulse = SCNAction.repeatForever(pulse)
                badgeNode.runAction(repeatPulse)
            }
            
            arView.scene.rootNode.addChildNode(markerNode)
            
            print("✅ Found Anchor Point marker placed at SAVED position (ground-aligned)")
            autoPlacedMarkerPosition = transformedPosition
            print("   [DEBUG] Stored auto-placed position for comparison")
            print("═══ AUTO-PLACEMENT COORDINATES ═══")
            print("   Position: \(transformedPosition)")
            print("   X: \(transformedPosition.x)m")
            print("   Y: \(transformedPosition.y)m (height)")
            print("   Z: \(transformedPosition.z)m")
            print("═══════════════════════════════════")
        }
        
        func updateInterpolationCrossMarks(count: Int) {
            guard let arView = arView,
                  let lineNode = arView.scene.rootNode.childNode(withName: "interpolation_line", recursively: true),
                  let cylinder = lineNode.geometry as? SCNCylinder else {
                print("⚠️ Cannot update cross-marks: line not found")
                return
            }
            
            // Remove existing cross-marks from line
            lineNode.childNodes
                .filter { $0.name?.hasPrefix("cross_mark_") ?? false }
                .forEach { $0.removeFromParentNode() }
            
            guard count > 0 else {
                print("✏️ Cleared cross-marks (count = 0)")
                return
            }
            
            // Calculate line direction for perpendicular alignment
            guard let markerA = sessionMarkerA?.position,
                  let markerB = sessionMarkerB?.position else {
                print("⚠️ Session markers not available")
                return
            }
            let direction = markerB - markerA
            let lineDirection = simd_normalize(direction)
            
            let lineLength = Float(cylinder.height)
            
            for i in 1...count {
                let t = Float(i) / Float(count + 1)
                
                // Position along line's local Y-axis (cylinder's height dimension)
                // Line is centered at origin, so map [0,1] to [-length/2, +length/2]
                let yPosition = (t - 0.5) * lineLength
                
                // Create cross-mark perpendicular to line
                let crossLength: Float = 0.15
                let crossLine = SCNCylinder(radius: 0.001, height: CGFloat(crossLength))
                crossLine.firstMaterial?.diffuse.contents = UIColor.white
                
                let crossNode = SCNNode(geometry: crossLine)
                crossNode.name = "cross_mark_\(i)"
                
                // Position in line's local coordinate system (along Y-axis)
                crossNode.position = SCNVector3(0, yPosition, 0)
                
                // Add as child of line FIRST (inherits line's world transform)
                lineNode.addChildNode(crossNode)
                
                // AFTER adding as child, override rotation to be ground-relative
                // Calculate world position to get the actual AR coordinates
                let worldPos = lineNode.convertPosition(SCNVector3(0, yPosition, 0), to: nil)
                
                // Calculate perpendicular direction in XZ plane (ground plane)
                // Project line direction onto ground by zeroing Y component
                let lineDir2D = simd_float3(lineDirection.x, 0, lineDirection.z)
                let lineDirNormalized = simd_normalize(lineDir2D)
                
                // Perpendicular is 90° rotation in XZ plane
                let perpAngle = atan2(lineDirNormalized.x, lineDirNormalized.z)
                
                // Set world-space rotation: lie flat and perpendicular to line
                crossNode.eulerAngles = SCNVector3(Float.pi / 2, perpAngle, 0)
                
                print("  ✏️ Cross-mark \(i) at t=\(String(format: "%.2f", t)), y=\(String(format: "%.2f", yPosition))")
            }
            
            print("✏️ Drew \(count) cross-mark(s) on interpolation line")
        }
        
        // MARK: - Anchor Mode Handlers
        
        func handleAnchorModeTap(_ location: CGPoint) {
            guard let selectedID = mapPointStore?.activePointID else {
                print("🚫 No map point selected for anchor")
                return
            }
            
            guard let arView = arView else {
                print("🚫 AR view not available")
                return
            }
            
            // Check if anchor already exists
            if let mapPointStore = mapPointStore,
               mapPointStore.arMarkers.contains(where: { $0.linkedMapPointID == selectedID && $0.isAnchor }) {
                print("🚫 Anchor marker already exists for this point")
                return
            }
            
            // Raycast to find surface
            let raycastQuery = arView.raycastQuery(from: location, allowing: .estimatedPlane, alignment: .any)
            guard let query = raycastQuery,
                  let result = arView.session.raycast(query).first else {
                print("🚫 No surface detected")
                return
            }
            
            let transform = result.worldTransform
            let position = simd_float3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
            
            // Get map point coordinates
            guard let mapPoint = mapPointStore?.points.first(where: { $0.id == selectedID }) else {
                print("🚫 Map point not found")
                return
            }
            
            // Create anchor marker
            let marker = ARMarker(
                linkedMapPointID: selectedID,
                arPosition: position,
                mapCoordinates: mapPoint.mapPoint,
                isAnchor: true
            )
            
            mapPointStore?.arMarkers.append(marker)
            
            // Create and add node to scene
            let markerNode = createARMarkerNode(
                at: position,
                sphereColor: .cyan,
                markerID: marker.id,
                userHeight: userHeight,
                badgeColor: marker.isAnchor ? .systemTeal : nil
            )
            markerNode.name = "arMarker_\(marker.id)"
            arView.scene.rootNode.addChildNode(markerNode)
            
            print("✅ Placed anchor marker at \(position)")
            print("🔶 Anchor marker for MapPoint: \(selectedID)")
            
            // Start quality monitoring for anchor capture
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.isCapturingAnchor = true
                self.currentCaptureMapPointID = selectedID
                self.currentCapturePosition = position
                self.startQualityMonitoring(mapPointID: selectedID, position: position)
                print("🎯 Started quality monitoring for anchor")
            }
            
            // Exit anchor mode
            isAnchorMode = false
        }
        
        deinit {
            if let observer = deleteNotificationObserver {
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
    
    static func dismantleUIView(_ uiView: ARSCNView, coordinator: Coordinator) {
        print("👋 AR View dismissing - cleaning up resources")
        coordinator.cleanupAllARMarkers()
        if coordinator.isRelocalizationMode || coordinator.relocalizationState != .idle {
            coordinator.stopRelocalization()
        }
        uiView.session.pause()
        print("⏸️ AR Camera session paused")
        coordinator.sessionMarkerA = nil
        coordinator.sessionMarkerB = nil
        print("🧹 Cleared session markers")
    }
}


