//
//  SurveyExportOptions.swift
//  TapResolver
//
//  Configuration and filename generation for .mapsurvey exports.
//

import Foundation

/// Configuration options for survey data export
class SurveyExportOptions: ObservableObject {
    
    // MARK: - Export State
    
    @Published var isExporting: Bool = false
    @Published var lastExportURL: URL?
    @Published var helperInitials: String = ""
    
    // MARK: - Daily Version Counter
    
    private var dailyExportCount: Int = 0
    private var lastExportDate: String = ""
    private var lastExportTime: String = ""
    
    /// Generate filename for survey export
    /// Format: SurveyData-yyyyMMdd-HHmm-vXX-ab.mapsurvey
    func generateFilename(initials: String) -> String {
        let now = Date()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateString = dateFormatter.string(from: now)
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HHmm"
        let timeString = timeFormatter.string(from: now)
        
        // Reset counter if new day or new time block
        if dateString != lastExportDate || timeString != lastExportTime {
            dailyExportCount = 0
            lastExportDate = dateString
            lastExportTime = timeString
        }
        dailyExportCount += 1
        
        let sanitizedInitials = initials.lowercased().filter { $0.isLetter }
        let initialsTag = sanitizedInitials.isEmpty ? "xx" : String(sanitizedInitials.prefix(3))
        
        return "SurveyData-\(dateString)-\(timeString)-v\(String(format: "%02d", dailyExportCount))-\(initialsTag).mapsurvey"
    }
    
    /// Preview filename (for UI display)
    func previewFilename(initials: String) -> String {
        let now = Date()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateString = dateFormatter.string(from: now)
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HHmm"
        let timeString = timeFormatter.string(from: now)
        
        let nextVersion: Int
        if dateString != lastExportDate || timeString != lastExportTime {
            nextVersion = 1
        } else {
            nextVersion = dailyExportCount + 1
        }
        
        let sanitizedInitials = initials.lowercased().filter { $0.isLetter }
        let initialsTag = sanitizedInitials.isEmpty ? "xx" : String(sanitizedInitials.prefix(3))
        
        return "SurveyData-\(dateString)-\(timeString)-v\(String(format: "%02d", nextVersion))-\(initialsTag).mapsurvey"
    }
}

