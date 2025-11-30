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
    
    /// Maps marker ID strings to their AR positions for the current session
    /// (mirrors placedMarkers in ARViewContainer.Coordinator for ghost planting)
    private var sessionMarkerPositions: [String: simd_float3] = [:]
    
    /// Maps MapPoint ID to AR position for current session (for ghost calculation)
    private var mapPointARPositions: [UUID: simd_float3] = [:]
    
    @Published var statusText: String = ""
    @Published var progressDots: (Bool, Bool, Bool) = (false, false, false)
    
    // MILESTONE 3: Blocked placement state
    @Published var blockedPlacement: BlockedPlacementInfo? = nil
    
    /// Currently selected ghost marker (user is within proximity range)
    @Published var selectedGhostMapPointID: UUID? = nil
    
    /// Estimated position of the selected ghost (for distortion calculation)
    @Published var selectedGhostEstimatedPosition: simd_float3? = nil
    
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
    
    var arStore: ARWorldMapStore
    var mapStore: MapPointStore
    var triangleStore: TrianglePatchStore
    var metricSquareStore: MetricSquareStore?
    
    init(arStore: ARWorldMapStore, mapStore: MapPointStore, triangleStore: TrianglePatchStore, metricSquareStore: MetricSquareStore? = nil) {
        self.arStore = arStore
        self.mapStore = mapStore
        self.triangleStore = triangleStore
        self.metricSquareStore = metricSquareStore
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
        guard let triangle = triangleStore.triangle(withID: triangleID) else {
            print("❌ Cannot start calibration: Triangle \(triangleID) not found")
            return
        }
        
        // Clear any existing calibration markers from scene - we're re-calibrating from scratch
        if let coordinator = ARViewContainer.Coordinator.current {
            coordinator.clearCalibrationMarkers()  // Remove old marker nodes from scene
        }
        
        activeTriangleID = triangleID
        currentTriangleID = triangleID
        triangleVertices = triangle.vertexIDs
        
        // Clear any existing markers - we're re-calibrating from scratch
        placedMarkers = []
        completedMarkerCount = 0
        currentVertexIndex = 0  // Start with first vertex - ensure proper photo selection
        lastPrintedVertexIndex = nil  // Reset print tracking
        calibrationState = .placingVertices(currentIndex: 0)
        print("🎯 CalibrationState → \(stateDescription)")
        
        // Clear ALL marker IDs for re-calibration
        print("🔄 Re-calibrating triangle - clearing ALL existing markers")
        print("   Old arMarkerIDs: \(triangle.arMarkerIDs)")
        triangleStore.clearAllMarkers(for: triangleID)
        if let updatedTriangle = triangleStore.triangle(withID: triangleID) {
            print("   New arMarkerIDs: \(updatedTriangle.arMarkerIDs)")
        }
        
        // Validate triangleVertices is set correctly
        guard triangleVertices.count == 3 else {
            print("❌ Invalid triangle: expected 3 vertices, got \(triangleVertices.count)")
            return
        }
        
        print("📍 Starting calibration with vertices: \(triangleVertices.map { String($0.uuidString.prefix(8)) })")
        
        // If triangle had previous markers, log them but don't use them
        if !triangle.arMarkerIDs.isEmpty && triangle.arMarkerIDs.contains(where: { !$0.isEmpty }) {
            print("🔄 Re-calibrating triangle - clearing \(triangle.arMarkerIDs.filter { !$0.isEmpty }.count) existing markers")
        }
        
        // Update reference photo for the current vertex (first vertex, index 0)
        if let currentVertexID = getCurrentVertexID(),
           let mapPoint = mapStore.points.first(where: { $0.id == currentVertexID }) {
            let photoData: Data? = {
                if let diskData = mapStore.loadPhotoFromDisk(for: currentVertexID) {
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
        
        // Update UI state
        progressDots = (false, false, false)
        statusText = "Place AR markers for triangle (0/3)"
        isActive = true
        
        print("🎯 ARCalibrationCoordinator: Starting calibration for triangle \(String(triangleID.uuidString.prefix(8)))")
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
        // MARK: Photo verification on marker placement
        print("📍 registerMarker called for MapPoint \(String(mapPointID.uuidString.prefix(8)))")
        if let mapPoint = mapStore.points.first(where: { $0.id == mapPointID }) {
            if let photoFilename = mapPoint.photoFilename {
                print("🖼 Photo '\(photoFilename)' linked to MapPoint \(String(mapPoint.id.uuidString.prefix(8)))")
            } else {
                print("⚠️ No photo for MapPoint \(String(mapPoint.id.uuidString.prefix(8)))")
            }
        }
        
        guard let triangleID = activeTriangleID,
              let triangle = triangleStore.triangle(withID: triangleID) else {
            print("❌ Cannot register marker: No active triangle")
            return
        }
        
        // Validate this mapPointID is a vertex of the active triangle
        guard triangle.vertexIDs.contains(mapPointID) else {
            print("❌ MapPoint \(String(mapPointID.uuidString.prefix(8))) is not a vertex of triangle \(String(triangleID.uuidString.prefix(8)))")
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
            try arStore.saveMarker(worldMapMarker)
            print("💾 Saving AR Marker with session context:")
            print("   Marker ID: \(marker.id)")
            print("   Session ID: \(arStore.currentSessionID)")
            print("   Session Time: \(arStore.currentSessionStartTime)")
            print("   Storage Key: ARWorldMapStore (saved successfully)")
            
            // Track this marker's position for current session (used by ghost planting)
            sessionMarkerPositions[marker.id.uuidString] = marker.arPosition
            mapPointARPositions[mapPointID] = marker.arPosition  // Key by MapPoint ID for easy lookup
            print("📍 [SESSION_MARKERS] Stored position for \(String(marker.id.uuidString.prefix(8))) → MapPoint \(String(mapPointID.uuidString.prefix(8)))")
            
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
            let record = ARPositionRecord(
                position: marker.arPosition,
                sessionID: arStore.currentSessionID,
                sourceType: sourceType,
                distortionVector: distortionVector,
                confidenceScore: sourceType == .ghostConfirm ? 1.0 : (sourceType == .ghostAdjust ? 0.8 : 0.95)
            )
            mapStore.addPositionRecord(mapPointID: mapPointID, record: record)
        } catch {
            print("❌ Failed to save marker to ARWorldMapStore: \(error)")
            return
        }
        
        // Update triangle with marker ID
        triangleStore.addMarkerToTriangle(
            triangleID: triangleID,
            vertexMapPointID: mapPointID,
            markerID: marker.id
        )
        
        // Track placed marker
        placedMarkers.append(mapPointID)
        updateProgressDots()
        
        // MILESTONE 3: After 2nd marker, plant ghost for 3rd vertex
        if placedMarkers.count == 2 {
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
                        if let mapPoint = mapStore.points.first(where: { $0.id == vertexID }) {
                            let photoData: Data? = {
                                if let diskData = mapStore.loadPhotoFromDisk(for: vertexID) {
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
            finalizeCalibration(for: triangle)
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
    }
    
    /// Calculate 3D AR position for a MapPoint using barycentric interpolation from a calibrated triangle
    private func calculateGhostPosition(
        mapPoint: MapPointStore.MapPoint,
        calibratedTriangleID: UUID,
        triangleStore: TrianglePatchStore,
        mapPointStore: MapPointStore,
        arWorldMapStore: ARWorldMapStore
    ) -> simd_float3? {
        
        // Re-fetch triangle to ensure we have the latest arMarkerIDs (fixes stale struct issue)
        guard let calibratedTriangle = triangleStore.triangles.first(where: { $0.id == calibratedTriangleID }) else {
            print("⚠️ [GHOST_CALC] Could not find triangle \(String(calibratedTriangleID.uuidString.prefix(8)))")
            return nil
        }
        
        print("🔍 [GHOST_CALC] Fresh triangle fetch - arMarkerIDs: \(calibratedTriangle.arMarkerIDs)")
        
        // Validate all marker IDs are populated
        guard calibratedTriangle.arMarkerIDs.allSatisfy({ !$0.isEmpty }) else {
            print("⚠️ [GHOST_CALC] Incomplete marker ID list: \(calibratedTriangle.arMarkerIDs)")
            return nil
        }
        
        // STEP 1: Get triangle's 3 vertex MapPoints (2D positions)
        guard calibratedTriangle.vertexIDs.count == 3 else {
            print("⚠️ [GHOST_CALC] Triangle has invalid vertex count: \(calibratedTriangle.vertexIDs.count)")
            return nil
        }
        
        let vertexMapPoints = calibratedTriangle.vertexIDs.compactMap { vertexID in
            mapPointStore.points.first { $0.id == vertexID }
        }
        
        guard vertexMapPoints.count == 3 else {
            print("⚠️ [GHOST_CALC] Could not find all 3 vertex MapPoints")
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
            return nil
        }
        
        let w2 = (v2.x * v1.y - v1.x * v2.y) / denom
        let w3 = (v0.x * v2.y - v2.x * v0.y) / denom
        let w1 = 1.0 - w2 - w3
        
        print("📐 [GHOST_CALC] Barycentric weights: w1=\(String(format: "%.3f", w1)), w2=\(String(format: "%.3f", w2)), w3=\(String(format: "%.3f", w3))")
        
        // STEP 3: Get triangle's 3 vertex AR marker positions (3D positions)
        guard calibratedTriangle.arMarkerIDs.count == 3 else {
            print("⚠️ [GHOST_CALC] Triangle does not have 3 AR markers yet")
            return nil
        }
        
        var arPositions: [simd_float3] = []
        for markerIDString in calibratedTriangle.arMarkerIDs {
            guard !markerIDString.isEmpty else {
                print("⚠️ [GHOST_CALC] Empty marker ID string in triangle's arMarkerIDs")
                return nil
            }
            
            var foundPosition: simd_float3?
            var foundSource: String = ""
            
            // PRIORITY 1: Check current session's marker positions (just placed markers)
            if let sessionPosition = sessionMarkerPositions[markerIDString] {
                foundPosition = sessionPosition
                foundSource = "current session"
                print("✅ [GHOST_CALC] Found marker \(String(markerIDString.prefix(8))) in session cache at position (\(String(format: "%.2f", sessionPosition.x)), \(String(format: "%.2f", sessionPosition.y)), \(String(format: "%.2f", sessionPosition.z)))")
            }
            // PRIORITY 2: Check by prefix in case arMarkerIDs has short 8-char versions
            else if let sessionPosition = sessionMarkerPositions.first(where: { $0.key.hasPrefix(markerIDString) || markerIDString.hasPrefix($0.key) })?.value {
                foundPosition = sessionPosition
                foundSource = "current session (prefix match)"
                print("✅ [GHOST_CALC] Found marker \(String(markerIDString.prefix(8))) via prefix in session cache")
            }
            // PRIORITY 3: Fall back to ARWorldMapStore
            else if let marker = arWorldMapStore.markers.first(where: { $0.id.hasPrefix(markerIDString) || markerIDString.hasPrefix($0.id) }) {
                foundPosition = marker.positionInSession
                foundSource = "ARWorldMapStore"
                print("✅ [GHOST_CALC] Found marker \(String(marker.id.prefix(8))) in store at position (\(String(format: "%.2f", marker.positionInSession.x)), \(String(format: "%.2f", marker.positionInSession.y)), \(String(format: "%.2f", marker.positionInSession.z)))")
            }
            
            guard let position = foundPosition else {
                print("⚠️ [GHOST_CALC] Could not find AR marker with ID: \(markerIDString)")
                print("   Session markers: \(sessionMarkerPositions.keys.map { String($0.prefix(8)) }.joined(separator: ", "))")
                print("   Store markers: \(arWorldMapStore.markers.map { String($0.id.prefix(8)) }.joined(separator: ", "))")
                return nil
            }
            
            arPositions.append(position)
        }
        
        guard arPositions.count == 3 else {
            print("⚠️ [GHOST_CALC] Could not get all 3 AR marker positions")
            return nil
        }
        
        // STEP 4: Apply barycentric weights to 3D AR positions
        let m1_3D = arPositions[0]
        let m2_3D = arPositions[1]
        let m3_3D = arPositions[2]
        
        let ghostPosition = simd_float3(
            Float(w1) * m1_3D.x + Float(w2) * m2_3D.x + Float(w3) * m3_3D.x,
            Float(w1) * m1_3D.y + Float(w2) * m2_3D.y + Float(w3) * m3_3D.y,
            Float(w1) * m1_3D.z + Float(w2) * m2_3D.z + Float(w3) * m3_3D.z
        )
        
        print("👻 [GHOST_CALC] Calculated ghost position: (\(String(format: "%.2f", ghostPosition.x)), \(String(format: "%.2f", ghostPosition.y)), \(String(format: "%.2f", ghostPosition.z)))")
        
        return ghostPosition
    }
    
    /// Calculate ghost position for 3rd vertex when only 2 markers are placed
    /// Uses hierarchical approach: consensus history first, then 2D map geometry
    private func calculateGhostPositionForThirdVertex(
        thirdVertexID: UUID,
        placedVertexIDs: [UUID],
        placedARPositions: [simd_float3]
    ) -> simd_float3? {
        guard placedVertexIDs.count == 2, placedARPositions.count == 2 else {
            print("⚠️ [GHOST_3RD] Need exactly 2 placed markers")
            return nil
        }
        
        // Get MapPoints for all 3 vertices
        guard let thirdMapPoint = mapStore.points.first(where: { $0.id == thirdVertexID }),
              let firstMapPoint = mapStore.points.first(where: { $0.id == placedVertexIDs[0] }),
              let secondMapPoint = mapStore.points.first(where: { $0.id == placedVertexIDs[1] }) else {
            print("⚠️ [GHOST_3RD] Could not find MapPoints for vertices")
            return nil
        }
        
        // PRIORITY 1: Check if 3rd vertex has consensus position from history
        // AND both placed markers have consensus positions (required for rigid transform)
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
        
        return ghostPosition
    }
    
    /// Plant ghost markers for far vertices of triangles adjacent to the calibrated triangle
    private func plantGhostsForAdjacentTriangles(
        calibratedTriangle: TrianglePatch,
        triangleStore: TrianglePatchStore,
        mapPointStore: MapPointStore,
        arWorldMapStore: ARWorldMapStore
    ) {
        print("🔍 [GHOST_PLANT] Finding adjacent triangles to \(String(calibratedTriangle.id.uuidString.prefix(8)))")
        
        // STEP 1: Find triangles sharing an edge with calibrated triangle (REUSE existing function)
        let adjacentTriangles = triangleStore.findAdjacentTriangles(calibratedTriangle.id)
        
        print("🔍 [GHOST_PLANT] Found \(adjacentTriangles.count) adjacent triangle(s)")
        
        guard !adjacentTriangles.isEmpty else {
            print("ℹ️ [GHOST_PLANT] No adjacent triangles found - calibrated triangle may be isolated")
            return
        }
        
        // STEP 2: For each adjacent triangle, plant ghost at far vertex
        var ghostsPlanted = 0
        for adjacentTriangle in adjacentTriangles {
            // Get the far vertex (REUSE existing function)
            guard let farVertexID = triangleStore.getFarVertex(adjacentTriangle: adjacentTriangle, sourceTriangle: calibratedTriangle) else {
                print("⚠️ [GHOST_PLANT] Could not find far vertex for triangle \(String(adjacentTriangle.id.uuidString.prefix(8)))")
                continue
            }
            
            // Get MapPoint for far vertex
            guard let farVertexMapPoint = mapPointStore.points.first(where: { $0.id == farVertexID }) else {
                print("⚠️ [GHOST_PLANT] Could not find MapPoint for far vertex \(String(farVertexID.uuidString.prefix(8)))")
                continue
            }
            
            // Skip if this MapPoint already has a real marker in the current session
            let hasMarkerInCurrentSession = arWorldMapStore.markers.contains { marker in
                marker.mapPointID == farVertexID.uuidString &&
                marker.sessionID == arWorldMapStore.currentSessionID
            }
            if hasMarkerInCurrentSession {
                print("⏭️ [GHOST_PLANT] Skipping MapPoint \(String(farVertexID.uuidString.prefix(8))) - already has real marker in current session")
                continue
            }
            
            // Calculate ghost position using barycentric interpolation
            guard let ghostPosition = calculateGhostPosition(
                mapPoint: farVertexMapPoint,
                calibratedTriangleID: calibratedTriangle.id,
                triangleStore: triangleStore,
                mapPointStore: mapPointStore,
                arWorldMapStore: arWorldMapStore
            ) else {
                print("⚠️ [GHOST_PLANT] Could not calculate ghost position for MapPoint \(String(farVertexID.uuidString.prefix(8)))")
                continue
            }
            
            // Post notification to coordinator to render ghost
            NotificationCenter.default.post(
                name: NSNotification.Name("PlaceGhostMarker"),
                object: nil,
                userInfo: [
                    "mapPointID": farVertexID,
                    "position": ghostPosition
                ]
            )
            
            ghostsPlanted += 1
            print("👻 [GHOST_PLANT] Planted ghost for MapPoint \(String(farVertexID.uuidString.prefix(8))) at position \(ghostPosition)")
        }
        
        print("✅ [GHOST_PLANT] Planted \(ghostsPlanted) ghost marker(s) for adjacent triangle vertices (including previously-calibrated triangles)")
    }
    
    /// Check if the active triangle has all 3 markers placed (calibration complete)
    func isTriangleComplete(_ triangleID: UUID) -> Bool {
        guard let triangle = triangleStore.triangle(withID: triangleID) else { return false }
        return placedMarkers.count == 3 && triangle.vertexIDs.allSatisfy { placedMarkers.contains($0) }
    }
    
    private func updateProgressDots() {
        guard let triangleID = activeTriangleID,
              let triangle = triangleStore.triangle(withID: triangleID) else {
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
        triangleStore.markCalibrated(triangle.id, quality: quality)
        
        // Verify triangle state
        if let updatedTriangle = triangleStore.triangle(withID: triangle.id) {
            print("🔍 Triangle \(String(triangle.id.uuidString.prefix(8))) state after marking:")
            print("   isCalibrated: \(updatedTriangle.isCalibrated)")
            print("   arMarkerIDs count: \(updatedTriangle.arMarkerIDs.count)")
            print("   arMarkerIDs: \(updatedTriangle.arMarkerIDs.map { String($0.prefix(8)) })")
        } else {
            print("⚠️ Could not retrieve triangle after marking as calibrated")
        }
        
        statusText = "✅ Triangle calibrated with quality \(Int(quality * 100))%"
        
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
        guard let freshTriangle = triangleStore.triangles.first(where: { $0.id == triangle.id }) else {
            print("⚠️ [FINALIZE] Could not re-fetch triangle for ghost planting")
            currentVertexIndex = 0
            return
        }
        print("🔍 [FINALIZE] Fresh triangle for ghost planting - arMarkerIDs: \(freshTriangle.arMarkerIDs)")
        
        // Plant ghost markers for adjacent triangles
        plantGhostsForAdjacentTriangles(
            calibratedTriangle: freshTriangle,
            triangleStore: triangleStore,
            mapPointStore: mapStore,
            arWorldMapStore: arStore
        )
        
        // Reset index for next calibration
        currentVertexIndex = 0
        print("🔄 Reset currentVertexIndex to 0 for next calibration")
        
        // Don't auto-start next triangle - let user decide
        print("✅ Calibration complete. Ghost markers planted for adjacent triangles.")
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
                self.mapStore.points.first(where: { $0.id == vertexID })
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
                try self.arStore.savePatchForStrategy(worldMap, triangleID: triangle.id, strategyID: strategyID)
                
                // Store filename in triangle (format: "{triangleID}.armap")
                let filename = "\(triangle.id.uuidString).armap"
                
                // Update legacy worldMapFilename for backward compatibility
                self.triangleStore.setWorldMapFilename(for: triangle.id, filename: filename)
                
                // Update worldMapFilesByStrategy dictionary
                self.triangleStore.setWorldMapFilename(for: triangle.id, strategyName: strategyDisplayName, filename: filename)
                
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
        guard let triangle = triangleStore.triangle(withID: triangleID) else {
            return nil
        }
        
        // Get all adjacent uncalibrated triangles (share an edge = 2 vertices)
        let adjacentCandidates = triangleStore.findAdjacentTriangles(triangleID)
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
            guard let farVertexA = triangleStore.getFarVertex(adjacentTriangle: candidateA, sourceTriangle: triangle),
                  let farVertexB = triangleStore.getFarVertex(adjacentTriangle: candidateB, sourceTriangle: triangle),
                  let pointA = mapStore.points.first(where: { $0.id == farVertexA }),
                  let pointB = mapStore.points.first(where: { $0.id == farVertexB }) else {
                return false
            }
            
            let distA = distance(userPos, pointA.mapPoint)
            let distB = distance(userPos, pointB.mapPoint)
            
            return distA < distB
        }
        
        if let next = closestTriangle,
           let farVertex = triangleStore.getFarVertex(adjacentTriangle: next, sourceTriangle: triangle),
           let farPoint = mapStore.points.first(where: { $0.id == farVertex }) {
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
        let remainingPoints = mapStore.points.filter { !alreadyPlacedIDs.contains($0.id) }
        
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
            return arStore.marker(withID: markerUUID)
        }
        
        guard arMarkers.count == 3 else {
            print("⚠️ Cannot compute quality: Only found \(arMarkers.count)/3 AR markers")
            return 0.0
        }
        
        // Get MapPoints for the 3 vertices
        let vertexIDs = triangle.vertexIDs
        let mapPoints = vertexIDs.compactMap { vertexID in
            mapStore.points.first(where: { $0.id == vertexID })
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
        triangleStore.setLegMeasurements(for: triangle.id, measurements: measurements)
        
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
            try arStore.saveMarker(worldMapMarker)
            
            sessionMarkerPositions[marker.id.uuidString] = marker.arPosition
            
            // Record with LOW confidence (0.1) so consensus ignores this outlier
            let record = ARPositionRecord(
                position: marker.arPosition,
                sessionID: arStore.currentSessionID,
                sourceType: .calibration,
                distortionVector: marker.arPosition - blocked.ghostPosition,
                confidenceScore: 0.1  // LOW confidence for override
            )
            mapStore.addPositionRecord(mapPointID: mapPointID, record: record)
            print("📍 [OVERRIDE] Recorded with confidence 0.1 (outlier)")
            
        } catch {
            print("❌ [OVERRIDE] Failed to save marker: \(error)")
            return
        }
        
        // Update triangle with marker ID
        guard let triangleID = activeTriangleID else { return }
        triangleStore.addMarkerToTriangle(
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
            if let triangle = triangleStore.triangle(withID: triangleID) {
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
        print("🎯 CalibrationState → \(stateDescription) (reset)")
        print("🔄 ARCalibrationCoordinator: Reset complete - all markers cleared")
    }
    
    /// Updates ghost selection based on user proximity
    /// - Parameters:
    ///   - cameraPosition: Current AR camera position
    ///   - ghostPositions: Dictionary of mapPointID → estimated ghost position
    ///   - proximityThreshold: Distance in meters to trigger selection (default 2.0m, horizontal distance only)
    func updateGhostSelection(
        cameraPosition: simd_float3,
        ghostPositions: [UUID: simd_float3],
        proximityThreshold: Float = 2.0  // meters (horizontal distance only)
    ) {
        // Only process during active calibration states where ghosts may be visible
        let isValidState: Bool
        switch calibrationState {
        case .placingVertices:
            isValidState = true  // Ghost for 3rd vertex appears during placement
        case .readyToFill:
            isValidState = true  // Ghosts for adjacent triangles after completion
        default:
            isValidState = false
        }
        
        guard isValidState else {
            // Clear selection if not in correct state
            if selectedGhostMapPointID != nil {
                print("👻 [GHOST_SELECT] Cleared selection - not in valid calibration state")
                selectedGhostMapPointID = nil
                selectedGhostEstimatedPosition = nil
            }
            return
        }
        
        // Find nearest ghost within threshold
        var nearestGhostID: UUID? = nil
        var nearestDistance: Float = Float.greatestFiniteMagnitude
        var nearestPosition: simd_float3? = nil
        
        for (mapPointID, ghostPosition) in ghostPositions {
            let distance = simd_distance(
                simd_float2(cameraPosition.x, cameraPosition.z),
                simd_float2(ghostPosition.x, ghostPosition.z)
            )
            if distance < proximityThreshold && distance < nearestDistance {
                nearestGhostID = mapPointID
                nearestDistance = distance
                nearestPosition = ghostPosition
            }
        }
        
        // Update selection if changed
        if nearestGhostID != selectedGhostMapPointID {
            if let ghostID = nearestGhostID, let position = nearestPosition {
                print("👻 [GHOST_SELECT] Selected ghost \(String(ghostID.uuidString.prefix(8))) at \(String(format: "%.2f", nearestDistance))m")
                selectedGhostMapPointID = ghostID
                selectedGhostEstimatedPosition = position
            } else if selectedGhostMapPointID != nil {
                print("👻 [GHOST_SELECT] Deselected ghost - moved out of range")
                selectedGhostMapPointID = nil
                selectedGhostEstimatedPosition = nil
            }
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
            sessionID: arStore.currentSessionID,
            sessionTimestamp: arStore.currentSessionStartTime
        )
    }
}
