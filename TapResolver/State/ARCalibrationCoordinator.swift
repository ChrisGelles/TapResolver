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

final class ARCalibrationCoordinator: ObservableObject {
    @Published var activeTriangleID: UUID?
    @Published var placedMarkers: [UUID] = []  // MapPoint IDs that have been calibrated
    @Published var statusText: String = ""
    @Published var progressDots: (Bool, Bool, Bool) = (false, false, false)
    
    // Legacy compatibility properties
    @Published var isActive: Bool = false
    @Published var currentTriangleID: UUID?
    @Published var currentVertexIndex: Int = 0
    @Published var referencePhotoData: Data?
    @Published var completedMarkerCount: Int = 0
    
    private var triangleVertices: [UUID] = []
    
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
    
    func startCalibration(for triangleID: UUID) {
        guard let triangle = triangleStore.triangle(withID: triangleID) else {
            print("❌ Cannot start calibration: Triangle \(triangleID) not found")
            return
        }
        
        activeTriangleID = triangleID
        currentTriangleID = triangleID
        placedMarkers = []
        progressDots = (false, false, false)
        statusText = "Place AR markers for triangle (0/3)"
        isActive = true
        currentVertexIndex = 0
        completedMarkerCount = 0
        
        print("🎯 ARCalibrationCoordinator: Starting calibration for triangle \(String(triangleID.uuidString.prefix(8)))")
    }
    
    // MARK: - Legacy Compatibility Methods
    
    func setVertices(_ vertices: [UUID]) {
        triangleVertices = vertices
        print("📍 Calibration vertices set: \(vertices.map { String($0.uuidString.prefix(8)) })")
    }
    
    func getCurrentVertexID() -> UUID? {
        guard currentVertexIndex < triangleVertices.count else { return nil }
        return triangleVertices[currentVertexIndex]
    }
    
    func setReferencePhoto(_ photoData: Data?) {
        referencePhotoData = photoData
    }
    
    func registerMarker(mapPointID: UUID, marker: ARMarker) {
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
        do {
            let worldMapMarker = convertToWorldMapMarker(marker)
            try arStore.saveMarker(worldMapMarker)
        } catch {
            print("❌ Failed to save marker to ARWorldMapStore: \(error)")
            return
        }
        
        // Update triangle with marker ID
        triangleStore.addMarker(mapPointID: mapPointID, markerID: marker.id)
        
        // Track placed marker
        placedMarkers.append(mapPointID)
        updateProgressDots()
        
        // Advance to next vertex if not all placed
        if placedMarkers.count < 3 {
            // Find next unplaced vertex
            for vertexID in triangle.vertexIDs {
                if !placedMarkers.contains(vertexID) {
                    // Update currentVertexIndex to point to this vertex
                    if let index = triangle.vertexIDs.firstIndex(of: vertexID) {
                        currentVertexIndex = index
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
                        }
                        break
                    }
                }
            }
        }
        
        let count = placedMarkers.count
        statusText = "Place AR markers for triangle (\(count)/3)"
        
        print("✅ ARCalibrationCoordinator: Registered marker for MapPoint \(String(mapPointID.uuidString.prefix(8))) (\(count)/3)")
        
        if placedMarkers.count == 3 {
            finalizeCalibration(for: triangle)
        }
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
        
        // Find and suggest next adjacent uncalibrated triangle for crawling
        if let nextTriangle = findAdjacentUncalibratedTriangle(to: triangle.id) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.startCalibration(for: nextTriangle.id)
                self.statusText = "➡️ Continue: Calibrate adjacent triangle"
                print("🔄 ARCalibrationCoordinator: Auto-starting calibration for adjacent triangle \(String(nextTriangle.id.uuidString.prefix(8)))")
            }
        } else {
            // No adjacent triangles found - reset
            reset()
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
    private func findAdjacentUncalibratedTriangle(to triangleID: UUID) -> TrianglePatch? {
        guard let triangle = triangleStore.triangle(withID: triangleID) else {
            return nil
        }
        
        let vertexSet = Set(triangle.vertexIDs)
        
        // Find triangles that:
        // 1. Are not calibrated
        // 2. Are not the current triangle
        // 3. Share at least one vertex with the current triangle (adjacent)
        return triangleStore.triangles.first { candidate in
            !candidate.isCalibrated &&
            candidate.id != triangleID &&
            !Set(candidate.vertexIDs).intersection(vertexSet).isEmpty
        }
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
    
    func reset() {
        activeTriangleID = nil
        currentTriangleID = nil
        placedMarkers = []
        statusText = ""
        progressDots = (false, false, false)
        isActive = false
        currentVertexIndex = 0
        triangleVertices = []
        referencePhotoData = nil
        completedMarkerCount = 0
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
        
        // Use memberwise initializer (all properties are let)
        return ARWorldMapStore.ARMarker(
            id: markerIDString,
            mapPointID: mapPointIDString,
            worldTransform: codableTransform,
            createdAt: marker.createdAt,
            observations: nil
        )
    }
}
