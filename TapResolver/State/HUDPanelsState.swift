//
//  HUDPanelsState.swift
//  TapResolver
//
//  Created by restructuring on 9/19/25.
//

import SwiftUI

// MARK: - HUD panel state (unchanged except for isMorgueOpen you added)
final class HUDPanelsState: ObservableObject {
    @Published var isBeaconOpen: Bool = false
    @Published var isSquareOpen: Bool = false
    @Published var isMorgueOpen: Bool = false
    @Published var isMapPointOpen: Bool = false
    @Published var isZoneOpen: Bool = false
    @Published var isMapPointLogOpen = false
    @Published var isDebugSettingsOpen = false
    @Published var surveyThreadTraceEnabled = false
    @Published var isCalibratingNorth: Bool = false
    @Published var showFacingOverlay: Bool = true
    
    /// When true, show the UserFacing calibration overlay (tools layer).
    @Published var isCalibratingFacing: Bool = false
    @Published var isSVGExportOpen: Bool = false

    func openBeacon() { isBeaconOpen = true; isSquareOpen = false; isMorgueOpen = false; isMapPointOpen = false; isZoneOpen = false }
    func openSquares() { isSquareOpen = true; isBeaconOpen = false; isMorgueOpen = false; isMapPointOpen = false; isZoneOpen = false }
    func openMorgue() { isMorgueOpen = true; isBeaconOpen = false; isSquareOpen = false; isMapPointOpen = false; isZoneOpen = false }
    func openMapPoint() { isMapPointOpen = true; isBeaconOpen = false; isSquareOpen = false; isMorgueOpen = false; isZoneOpen = false }
    func openZone() {
        isBeaconOpen = false
        isSquareOpen = false
        isMorgueOpen = false
        isMapPointOpen = false
        isZoneOpen = true
        print("🔷 Zone Drawer: OPEN")
    }
    func closeAll() { isBeaconOpen = false; isSquareOpen = false; isMorgueOpen = false; isMapPointOpen = false; isZoneOpen = false }
    
    func toggleMapPointLog() {
        isMapPointLogOpen.toggle()
        print("🗂️ Map Point Log: \(isMapPointLogOpen ? "OPEN" : "CLOSED")")
    }
    
    func toggleDebugSettings() {
        isDebugSettingsOpen.toggle()
        print("⚙️ Debug Settings Panel: \(isDebugSettingsOpen ? "OPEN" : "CLOSED")")
    }
    
    func toggleSurveyThreadTrace() {
        surveyThreadTraceEnabled.toggle()
        UserDefaults.standard.set(surveyThreadTraceEnabled, forKey: "debug.surveyThreadTrace")
        print("🔍 Survey Thread Trace: \(surveyThreadTraceEnabled ? "ON" : "OFF")")
    }
    
    func toggleSVGExport() {
        isSVGExportOpen.toggle()
        if isSVGExportOpen {
            print("📤 SVG Export Panel: OPEN")
        }
    }
    
    init() {
        self.surveyThreadTraceEnabled = UserDefaults.standard.bool(forKey: "debug.surveyThreadTrace")
    }
}
