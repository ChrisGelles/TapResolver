//
//  ARViewLaunchContext.swift
//  TapResolver
//
//  Unified AR View launch context - single source of truth for AR presentation
//

import SwiftUI
import Combine

final class ARViewLaunchContext: ObservableObject {
    @Published var isPresented: Bool = false
    @Published var isCalibrationMode: Bool = false
    @Published var selectedTriangle: TrianglePatch? = nil
    
    /// Launch AR view in generic mode
    func launchGeneric() {
        DispatchQueue.main.async {
            self.isCalibrationMode = false
            self.selectedTriangle = nil
            self.isPresented = true
            print("🚀 ARViewLaunchContext: Launching generic AR view")
        }
    }
    
    /// Launch AR view in triangle calibration mode
    func launchTriangleCalibration(triangle: TrianglePatch) {
        DispatchQueue.main.async {
            self.isCalibrationMode = true
            self.selectedTriangle = triangle
            self.isPresented = true
            print("🚀 ARViewLaunchContext: Launching triangle calibration AR view for triangle \(String(triangle.id.uuidString.prefix(8)))")
        }
    }
    
    /// Dismiss AR view and clean up state
    func dismiss() {
        DispatchQueue.main.async {
            self.isPresented = false
            self.isCalibrationMode = false
            self.selectedTriangle = nil
            print("🚀 ARViewLaunchContext: Dismissed AR view")
        }
    }
}

