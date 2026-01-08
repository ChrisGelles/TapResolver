//
//  BackupExportOptions.swift
//  TapResolver
//
//  Configuration and filename generation for backup exports.
//

import Foundation

/// Configuration options for backup export
class BackupExportOptions: ObservableObject {
    
    // MARK: - Export State
    
    @Published var isExporting: Bool = false
    @Published var lastExportURL: URL?
    @Published var editableFilename: String = ""
    
    // MARK: - Daily Version Counter
    
    private var dailyExportCount: Int = 0
    private var lastExportDate: String = ""
    
    /// Generate default filename based on location names
    /// - Parameter locationNames: Array of location display names being exported
    /// - Returns: Suggested filename (without extension)
    func generateDefaultFilename(locationNames: [String]) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateString = dateFormatter.string(from: Date())
        
        // Reset counter if new day
        if dateString != lastExportDate {
            dailyExportCount = 0
            lastExportDate = dateString
        }
        dailyExportCount += 1
        
        // Build base name from location(s)
        let baseName: String
        if locationNames.count == 1, let firstName = locationNames.first {
            // Single location: use sanitized location name
            baseName = sanitizeForFilename(firstName)
        } else if locationNames.count > 1, let firstName = locationNames.first {
            // Multiple locations: use first name + count
            baseName = "\(sanitizeForFilename(firstName))+\(locationNames.count - 1)more"
        } else {
            baseName = "TapResolverBackup"
        }
        
        return "\(baseName)-\(dateString)-v\(String(format: "%02d", dailyExportCount))"
    }
    
    /// Preview filename without incrementing counter
    func previewFilename(locationNames: [String]) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateString = dateFormatter.string(from: Date())
        
        let nextVersion: Int
        if dateString != lastExportDate {
            nextVersion = 1
        } else {
            nextVersion = dailyExportCount + 1
        }
        
        let baseName: String
        if locationNames.count == 1, let firstName = locationNames.first {
            baseName = sanitizeForFilename(firstName)
        } else if locationNames.count > 1, let firstName = locationNames.first {
            baseName = "\(sanitizeForFilename(firstName))+\(locationNames.count - 1)more"
        } else {
            baseName = "TapResolverBackup"
        }
        
        return "\(baseName)-\(dateString)-v\(String(format: "%02d", nextVersion))"
    }
    
    /// Remove spaces and invalid filename characters
    private func sanitizeForFilename(_ name: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/\\?%*|\"<>: ")
        let sanitized = name.components(separatedBy: invalidCharacters).joined()
        return sanitized.isEmpty ? "Location" : sanitized
    }
    
    /// Full filename with extension
    func fullFilename() -> String {
        let name = editableFilename.isEmpty ? "TapResolverBackup" : editableFilename
        return name.hasSuffix(".tapmap") ? name : "\(name).tapmap"
    }
}

