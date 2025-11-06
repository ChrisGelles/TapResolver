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
        
        // Enable LiDAR if available
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
        }
        
        // Load saved world map if it exists
        if let worldMap = worldMapStore.loadWorldMap() {
            configuration.initialWorldMap = worldMap
            context.coordinator.isRelocalizing = true
            context.coordinator.relocalizationStartTime = Date()
            print("🗺️ Loading saved AR World Map for marker placement")
        } else {
            print("⚠️ No saved AR World Map - starting fresh tracking")
            context.coordinator.isRelocalized = true  // No relocalization needed
        }
        
        // Run the session with proper initialization
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
    
    class Coordinator: NSObject, ARSCNViewDelegate, ARSessionDelegate {
        
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
        
        // MARK: - AR Marker Creation Helper
        
        /// Create a complete AR marker node with floor circle, vertical line, and topping sphere
        /// - Parameters:
        ///   - position: 3D position in AR space
        ///   - sphereColor: Color for the topping sphere
        ///   - markerID: UUID for node naming
        ///   - userHeight: Height of the vertical line (meters)
        /// - Returns: Configured SCNNode ready to add to scene
        private func createARMarkerNode(at position: simd_float3, 
                                         sphereColor: UIColor,
                                         markerID: UUID,
                                         userHeight: Float) -> SCNNode {
            let markerNode = SCNNode()
            markerNode.simdPosition = position
            markerNode.name = "arMarker_\(markerID.uuidString)"
            
            // Floor circle (10cm diameter)
            let circleRadius: CGFloat = 0.1 // 5cm radius = 10cm diameter
            let circle = SCNTorus(ringRadius: circleRadius, pipeRadius: 0.002)
            
            let circleMaterial = SCNMaterial()
            circleMaterial.diffuse.contents = UIColor(red: 71/255, green: 199/255, blue: 239/255, alpha: 0.7)
            circle.materials = [circleMaterial]
            
            let circleNode = SCNNode(geometry: circle)
            circleNode.eulerAngles = SCNVector3Zero
            markerNode.addChildNode(circleNode)
            
            // Circle fill
            let circleFill = SCNCylinder(radius: circleRadius, height: 0.001)
            let fillMaterial = SCNMaterial()
            fillMaterial.diffuse.contents = UIColor.white.withAlphaComponent(0.15)
            circleFill.materials = [fillMaterial]
            
            let fillNode = SCNNode(geometry: circleFill)
            fillNode.eulerAngles.x = .pi
            markerNode.addChildNode(fillNode)
            
            // Vertical line (to user height)
            let lineHeight = CGFloat(userHeight)
            let line = SCNCylinder(radius: 0.00125, height: lineHeight) // 0.25cm = 2.5mm
            let lineMaterial = SCNMaterial()
            lineMaterial.diffuse.contents = UIColor(red: 0/255, green: 50/255, blue: 98/255, alpha: 0.95)
            line.materials = [lineMaterial]
            
            let lineNode = SCNNode(geometry: line)
            lineNode.position = SCNVector3(0, Float(lineHeight / 2), 0)
            markerNode.addChildNode(lineNode)
            
            // Sphere at top (color specified by parameter) - 6cm diameter
            let sphere = SCNSphere(radius: 0.03) // 3cm radius = 6cm diameter
            let sphereMaterial = SCNMaterial()
            sphereMaterial.diffuse.contents = sphereColor
            sphereMaterial.specular.contents = UIColor.white
            sphereMaterial.shininess = 0.8
            sphere.materials = [sphereMaterial]
            
            let sphereNode = SCNNode(geometry: sphere)
            sphereNode.position = SCNVector3(0, Float(lineHeight), 0)
            sphereNode.name = "arMarkerSphere_\(markerID.uuidString)"
            markerNode.addChildNode(sphereNode)
            
            // Add distinctive badge for anchor markers
            if let mapPointStore = mapPointStore {
                let isAnchorMarker = mapPointStore.arMarkers.first { $0.id == markerID }?.isAnchor ?? false
                
                if isAnchorMarker {
                    let badge = SCNNode()
                    let badgeGeometry = SCNSphere(radius: 0.05)
                    badgeGeometry.firstMaterial?.diffuse.contents = UIColor.systemTeal
                    badge.geometry = badgeGeometry
                    badge.position = SCNVector3(0, 0.15, 0)
                    sphereNode.addChildNode(badge)
                }
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
            
            print("✅ Detected \(planeAnchor.alignment == .horizontal ? "horizontal" : "vertical") plane")
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
        func placeMarkerAt(mapPointID: UUID, mapPoint: MapPointStore.MapPoint, color: UIColor) {
            guard let arView = arView else {
                print("❌ ARView not available")
                return
            }
            
            // Perform raycast from center of screen
            let screenCenter = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)
            let raycastQuery = arView.raycastQuery(from: screenCenter, allowing: .estimatedPlane, alignment: .any)
            
            guard let query = raycastQuery,
                  let result = arView.session.raycast(query).first else {
                print("❌ No surface detected at crosshair - point at a surface")
                return
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
            
            print("✅ Marker placed for \(mapPointID) at \(arPosition)")
            
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
                    userHeight: userHeight
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
                userHeight: userHeight
            )
            markerNode.name = "arMarker_\(marker.id)"
            arView.scene.rootNode.addChildNode(markerNode)
            
            print("✅ Placed anchor marker at \(position)")
            print("🔶 Anchor marker for MapPoint: \(selectedID)")
            
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
        uiView.session.pause()
        print("⏸️ AR Camera session paused")
        
        // Clear session markers
        coordinator.sessionMarkerA = nil
        coordinator.sessionMarkerB = nil
        print("🧹 Cleared session markers")
    }
}

