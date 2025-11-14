//
//  ARCalibrationCoordinator.swift
//  TapResolver
//
//  Coordinates sequential AR marker placement for triangle calibration
//

import SwiftUI
import Combine

class ARCalibrationCoordinator: ObservableObject {
    @Published var isActive: Bool = false
    @Published var currentTriangleID: UUID?
    @Published var currentVertexIndex: Int = 0  // 0, 1, or 2
    @Published var referencePhotoData: Data?
    @Published var completedMarkerCount: Int = 0
    
    private var triangleVertices: [UUID] = []
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Listen for calibration start notifications
        NotificationCenter.default.publisher(for: NSNotification.Name("StartTriangleCalibration"))
            .sink { [weak self] notification in
                guard let triangleID = notification.userInfo?["triangleID"] as? UUID else { return }
                self?.startCalibration(triangleID: triangleID)
            }
            .store(in: &cancellables)
        
        // Listen for marker placement notifications
        NotificationCenter.default.publisher(for: NSNotification.Name("ARMarkerPlaced"))
            .sink { [weak self] notification in
                self?.handleMarkerPlaced()
            }
            .store(in: &cancellables)
    }
    
    func startCalibration(triangleID: UUID) {
        print("🎯 Starting calibration for triangle: \(triangleID)")
        
        // This will be populated by the view that presents the AR session
        currentTriangleID = triangleID
        currentVertexIndex = 0
        completedMarkerCount = 0
        isActive = true
        
        // Notification will be caught by the main view to present AR session
        NotificationCenter.default.post(
            name: NSNotification.Name("PresentARCalibration"),
            object: nil,
            userInfo: ["triangleID": triangleID]
        )
    }
    
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
    
    private func handleMarkerPlaced() {
        completedMarkerCount += 1
        print("✅ Marker \(completedMarkerCount)/3 placed")
        
        if completedMarkerCount >= 3 {
            // All markers placed - calibration complete
            completeCalibration()
        } else {
            // Advance to next vertex
            currentVertexIndex += 1
        }
    }
    
    private func completeCalibration() {
        print("🎉 Triangle calibration complete!")
        
        // Post completion notification with marker IDs
        NotificationCenter.default.post(
            name: NSNotification.Name("TriangleCalibrationComplete"),
            object: nil,
            userInfo: [
                "triangleID": currentTriangleID as Any,
                "vertices": triangleVertices as Any
            ]
        )
        
        // Trigger ghost marker generation for adjacent triangles
        NotificationCenter.default.post(
            name: NSNotification.Name("GenerateGhostMarkers"),
            object: nil,
            userInfo: ["triangleID": currentTriangleID as Any]
        )
        
        reset()
    }
    
    func reset() {
        isActive = false
        currentTriangleID = nil
        currentVertexIndex = 0
        triangleVertices = []
        referencePhotoData = nil
        completedMarkerCount = 0
        
        // Reset coordinator calibration mode
        // TODO: Re-enable after Phase 4 coordinator integration
        // if let coordinator = ARViewContainer.Coordinator.current {
        //     coordinator.isCalibrationMode = false
        //     coordinator.calibrationTargetPointID = nil
        // }
    }
}
