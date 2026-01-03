//
//  SVGExportOptions.swift
//  TapResolver
//
//  Observable state for SVG export configuration.
//

import Foundation

/// Configuration options for SVG export
class SVGExportOptions: ObservableObject {
    
    // MARK: - Export Toggles
    
    @Published var includeMapBackground: Bool = true
    @Published var includeCalibrationMesh: Bool = false  // Phase 2
    @Published var includeRSSIHeatmap: Bool = false      // Phase 3
    
    // Future options (Phase 2+)
    // @Published var includeCompassVectors: Bool = false
    // @Published var includeUserFacingVectors: Bool = false
    
    // MARK: - Export State
    
    @Published var isExporting: Bool = false
    @Published var lastExportURL: URL?
    
    // MARK: - File Naming
    
    private var dailyExportCount: Int = 0
    private var lastExportDate: String = ""
    
    /// Generate filename based on selected options
    func generateFilename(locationID: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        
        // Reset counter if new day
        if dateString != lastExportDate {
            dailyExportCount = 0
            lastExportDate = dateString
        }
        dailyExportCount += 1
        
        // Build descriptor parts
        var parts: [String] = [locationID]
        
        if includeCalibrationMesh {
            parts.append("mesh")
        }
        if includeRSSIHeatmap {
            parts.append("rssi")
        }
        
        // If nothing selected, just call it "map"
        if parts.count == 1 {
            parts.append("map")
        }
        
        parts.append(dateString)
        parts.append(String(format: "v%02d", dailyExportCount))
        
        return parts.joined(separator: "-") + ".svg"
    }
}

