//
//  MapPointDebugTool.swift
//  TapResolver
//
//  Diagnostic tool for inspecting MapPoint persistence data
//

import Foundation
import SwiftUI

struct MapPointDebugTool {
    
    /// Storage structure matching MapPointStore's persistence format
    private struct MapPointStorage: Codable {
        let id: UUID
        let x: CGFloat
        let y: CGFloat
        let name: String?
        let createdDate: Date
        let sessions: [MapPointStore.ScanSession]
        let linkedARMarkerID: UUID?
        let arMarkerID: String?
        let roles: [MapPointRole]?
        let locationPhotoData: Data?
        let photoFilename: String?
        let photoOutdated: Bool?
        let photoCapturedAtPositionX: CGFloat?
        let photoCapturedAtPositionY: CGFloat?
        let triangleMemberships: [UUID]?
        let isLocked: Bool?
    }
    
    static func runDiagnostic() async {
        print("\n" + "=".repeating(80))
        print("🔍 MAP POINT DIAGNOSTIC TOOL")
        print("=".repeating(80) + "\n")
        
        let locations = ["home", "museum"]
        let context = PersistenceContext.shared
        let currentLocationID = context.locationID
        
        print("📍 Current active locationID: '\(currentLocationID)'\n")
        
        for location in locations {
            let key = "locations.\(location).MapPoints_v1"
            
            print("─".repeating(80))
            print("🔍 ANALYZING LOCATION: '\(location)'")
            print("   Full key: \(key)")
            print("─".repeating(80))
            
            guard let data = context.readRaw(key: key) else {
                print("❌ No data found for location '\(location)'")
                print("   Key '\(key)' does not exist in UserDefaults\n")
                continue
            }
            
            print("✅ Raw data found: \(data.count) bytes (\(String(format: "%.2f", Double(data.count) / 1024.0)) KB)")
            
            do {
                let decoder = JSONDecoder()
                let points = try decoder.decode([MapPointStorage].self, from: data)
                
                print("📦 Decoded \(points.count) map point(s) for location '\(location)'\n")
                
                if points.isEmpty {
                    print("   ⚠️ WARNING: Location '\(location)' has empty array stored\n")
                } else {
                    print("   Point Details:")
                    for (index, point) in points.enumerated() {
                        print("   [\(index+1)] ID: \(point.id.uuidString.prefix(8))...")
                        print("       Position: (\(Int(point.x)), \(Int(point.y)))")
                        print("       Name: \(point.name ?? "nil")")
                        print("       Created: \(point.createdDate)")
                        print("       Sessions: \(point.sessions.count)")
                        print("       Roles: \(point.roles?.map { $0.rawValue }.joined(separator: ", ") ?? "none")")
                        print("       Photo: \(point.photoFilename ?? (point.locationPhotoData != nil ? "data present" : "none"))")
                        print("       Locked: \(point.isLocked ?? true)")
                        print("")
                    }
                }
                
                // Check for potential data corruption
                if location == "home" && points.count > 0 {
                    // Museum map is typically larger (4096x4096 or 8192x8192)
                    // Home map is typically smaller
                    let maxX = points.map(\.x).max() ?? 0
                    let maxY = points.map(\.y).max() ?? 0
                    
                    if maxX > 5000 || maxY > 5000 {
                        print("   ⚠️⚠️⚠️ SUSPICIOUS: Points have very large coordinates!")
                        print("       Max X: \(Int(maxX)), Max Y: \(Int(maxY))")
                        print("       These coordinates suggest MUSEUM map data in HOME location!\n")
                    }
                }
                
            } catch {
                print("❌ Failed to decode map points for location '\(location)':")
                print("   Error: \(error)")
                
                // Try to show raw JSON snippet for debugging
                if let jsonString = String(data: data, encoding: .utf8) {
                    let preview = String(jsonString.prefix(200))
                    print("   Raw data preview: \(preview)...\n")
                }
            }
            
            print("")
        }
        
        print("=".repeating(80))
        print("✅ DIAGNOSTIC COMPLETE")
        print("=".repeating(80) + "\n")
    }
}

// Helper extension for string repetition
extension String {
    func repeating(_ count: Int) -> String {
        return String(repeating: self, count: count)
    }
}

