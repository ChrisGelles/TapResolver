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
    @Published var includeTriangles: Bool = false
    @Published var includeZones: Bool = false
    
    // MARK: - Format Options
    
    /// When enabled, transforms SVG output to match Adobe Illustrator conventions
    @Published var formatForIllustrator: Bool = true
    
    // Future options (Phase 2+)
    // @Published var includeCompassVectors: Bool = false
    // @Published var includeUserFacingVectors: Bool = false
    
    // MARK: - Export State
    
    @Published var isExporting: Bool = false
    @Published var lastExportURL: URL?
    
    // MARK: - File Naming
    
    private var dailyExportCount: Int = 0
    private var lastExportDate: String = ""
    
    /// Preview the filename without incrementing counter (for UI display)
    func previewFilename(locationID: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        
        // Calculate what the next version number would be
        let nextVersion: Int
        if dateString != lastExportDate {
            nextVersion = 1
        } else {
            nextVersion = dailyExportCount + 1
        }
        
        return buildFilename(locationID: locationID, dateString: dateString, version: nextVersion)
    }
    
    /// Generate filename and increment counter (call only on actual export)
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
        
        return buildFilename(locationID: locationID, dateString: dateString, version: dailyExportCount)
    }
    
    /// Build filename from components
    private func buildFilename(locationID: String, dateString: String, version: Int) -> String {
        var parts: [String] = [locationID]
        
        if includeMapBackground {
            parts.append("map")
        }
        
        if includeCalibrationMesh {
            parts.append("mesh")
        }
        
        if includeRSSIHeatmap {
            parts.append("rssi")
        }
        
        parts.append(dateString)
        parts.append(String(format: "v%02d", version))
        
        return parts.joined(separator: "-") + ".svg"
    }
}
