//
//  ARViewLaunchContext.swift
//  TapResolver
//
//  Unified AR View launch context - single source of truth for AR presentation
//

import SwiftUI
import Combine

enum LaunchMode {
    case generic
    case triangleCalibration
    case swathSurvey
    case zoneCornerCalibration
}

final class ARViewLaunchContext: ObservableObject {
    @Published var isPresented: Bool = false
    @Published var isCalibrationMode: Bool = false
    @Published var selectedTriangle: TrianglePatch? = nil
    @Published var launchMode: LaunchMode = .generic
    /// Selected triangle IDs for Swath Survey mode
    @Published var swathTriangleIDs: [UUID] = []
    /// Suggested anchor vertex IDs for Swath Survey
    @Published var suggestedAnchorIDs: [UUID] = []
    
    /// Zone Corner MapPoint IDs for Zone Corner Calibration
    @Published var zoneCornerIDs: [UUID] = []
    
    /// Launch AR view in generic mode
    func launchGeneric() {
        DispatchQueue.main.async {
            self.launchMode = .generic
            self.isCalibrationMode = false
            self.selectedTriangle = nil
            self.swathTriangleIDs.removeAll()
            self.suggestedAnchorIDs.removeAll()
            self.isPresented = true
            print("🚀 ARViewLaunchContext: Launching generic AR view")
        }
    }
    
    /// Launch AR view in triangle calibration mode
    func launchTriangleCalibration(triangle: TrianglePatch) {
        DispatchQueue.main.async {
            self.launchMode = .triangleCalibration
            self.isCalibrationMode = true
            self.selectedTriangle = triangle
            self.swathTriangleIDs.removeAll()
            self.suggestedAnchorIDs.removeAll()
            self.isPresented = true
            print("🚀 ARViewLaunchContext: Launching triangle calibration AR view for triangle \(String(triangle.id.uuidString.prefix(8)))")
        }
    }
    
    /// Launch AR for Swath Survey
    func launchSwathSurvey(triangleIDs: [UUID], suggestedAnchorIDs: [UUID]) {
        DispatchQueue.main.async {
            self.swathTriangleIDs = triangleIDs
            self.suggestedAnchorIDs = suggestedAnchorIDs
            self.launchMode = .swathSurvey
            self.isCalibrationMode = false
            self.selectedTriangle = nil
            self.isPresented = true
            print("📱 [ARViewLaunchContext] Swath Survey mode: \(triangleIDs.count) triangles")
        }
    }
    
    /// Launch AR for Zone Corner Calibration
    func launchZoneCornerCalibration(zoneCornerIDs: [UUID]) {
        DispatchQueue.main.async {
            self.zoneCornerIDs = zoneCornerIDs
            self.launchMode = .zoneCornerCalibration
            self.isCalibrationMode = true
            self.selectedTriangle = nil
            self.swathTriangleIDs.removeAll()
            self.suggestedAnchorIDs.removeAll()
            self.isPresented = true
            print("📱 [ARViewLaunchContext] Zone Corner Calibration mode: \(zoneCornerIDs.count) corners")
        }
    }
    
    /// Dismiss AR view and clean up state
    func dismiss() {
        DispatchQueue.main.async {
            self.isPresented = false
            self.isCalibrationMode = false
            self.selectedTriangle = nil
            self.swathTriangleIDs.removeAll()
            self.suggestedAnchorIDs.removeAll()
            self.zoneCornerIDs.removeAll()
            print("🚀 ARViewLaunchContext: Dismissed AR view")
        }
    }
}

