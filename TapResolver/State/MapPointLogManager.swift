//
//  MapPointLogManager.swift
//  TapResolver
//
//  Created on 10/12/2025
//
//  Role: Manages lightweight session index (pointID -> [sessionID])
//  - Scans filesystem to build index
//  - Reloads automatically when location changes
//  - Provides session counts and lists for UI
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class MapPointLogManager: ObservableObject {
    
    // MARK: - Published State
    
    /// Lightweight index: pointID -> [sessionID]
    @Published private(set) var sessionIndex: [String: [String]] = [:]
    
    // MARK: - Dependencies
    
    private let ctx = PersistenceContext.shared
    private var bag = Set<AnyCancellable>()
    private weak var mapPointStore: MapPointStore?
    
    // MARK: - Initialization
    
    init() {
        // Reload when location changes
        NotificationCenter.default.publisher(for: .locationDidChange)
            .sink { [weak self] _ in
                Task { @MainActor in
                    print("📍 MapPointLogManager: Location changed, rebuilding session index...")
                    await self?.buildSessionIndex()
                }
            }
            .store(in: &bag)
        
        // Rebuild when map points reload
        NotificationCenter.default.publisher(for: .mapPointsDidReload)
            .sink { [weak self] _ in
                Task { @MainActor in
                    print("🗺️ MapPointLogManager: Map points reloaded, rebuilding session index...")
                    await self?.buildSessionIndex()
                }
            }
            .store(in: &bag)
    }
    
    /// Wire up dependency to MapPointStore (call from AppBootstrap)
    func setMapPointStore(_ store: MapPointStore) {
        self.mapPointStore = store
    }
    
    // MARK: - Public API
    
    /// Get session count for a specific map point
    func sessionCount(for pointID: String) -> Int {
        return sessionIndex[pointID]?.count ?? 0
    }
    
    /// Get session IDs for a specific map point
    func sessions(for pointID: String) -> [String] {
        return sessionIndex[pointID] ?? []
    }
    
    /// Build session index from MapPoint's session file arrays
    /// Maps each Map Point ID to its session IDs
    func buildSessionIndex() async {
        print("🔍 Building session index from MapPoint data...")
        
        guard let store = mapPointStore else {
            print("⚠️ MapPointStore not available")
            sessionIndex = [:]
            return
        }
        
        var index: [String: [String]] = [:]
        
        for point in store.points {
            let pointID = point.id.uuidString
            let filePaths = point.sessionFilePaths
            
            // Extract session IDs from file paths
            var sessionIDs: [String] = []
            
            for filePath in filePaths {
                let fileURL = URL(fileURLWithPath: filePath)
                
                // Read the sessionID from the file
                if let data = try? Data(contentsOf: fileURL),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let sessionID = json["sessionID"] as? String {
                    sessionIDs.append(sessionID)
                }
            }
            
            if !sessionIDs.isEmpty {
                index[pointID] = sessionIDs
            }
        }
        
        sessionIndex = index
        
        let totalSessions = index.values.flatMap { $0 }.count
        print("✅ Built session index: \(index.count) points, \(totalSessions) sessions")
        
        for (pointID, sessionIDs) in index.prefix(3) {
            print("   \(pointID): \(sessionIDs.count) sessions")
        }
    }
    
    /// Delete a specific scan session
    func deleteSession(pointID: String, sessionID: String) async throws {
        guard let store = mapPointStore,
              let pointUUID = UUID(uuidString: pointID),
              let pointIndex = store.points.firstIndex(where: { $0.id == pointUUID }) else {
            return
        }
        
        var point = store.points[pointIndex]
        
        // Find and delete the file
        for (index, filePath) in point.sessionFilePaths.enumerated() {
            let fileURL = URL(fileURLWithPath: filePath)
            
            if let data = try? Data(contentsOf: fileURL),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let fileSessionID = json["sessionID"] as? String,
               fileSessionID == sessionID {
                
                // Delete the file
                try FileManager.default.removeItem(at: fileURL)
                print("🗑️ Deleted session: \(sessionID)")
                
                // Remove from map point's array
                point.sessionFilePaths.remove(at: index)
                store.points[pointIndex] = point
                
                // Trigger save through objectWillChange
                store.objectWillChange.send()
                
                // Rebuild index
                await buildSessionIndex()
                break
            }
        }
    }
    
    /// Load full scan data for a specific session
    func loadSessionData(sessionID: String) async -> [String: Any]? {
        guard let store = mapPointStore else { return nil }
        
        // Find the file path in any map point's session arrays
        for point in store.points {
            for filePath in point.sessionFilePaths {
                let fileURL = URL(fileURLWithPath: filePath)
                
                if let data = try? Data(contentsOf: fileURL),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let fileSessionID = json["sessionID"] as? String,
                   fileSessionID == sessionID {
                    return json
                }
            }
        }
        
        return nil
    }
    
    /// Generate master export JSON
    func exportMasterJSON() async throws -> Data {
        var mapPointsData: [[String: Any]] = []
        
        for (pointID, sessionIDs) in sessionIndex {
            // Get coordinates from MapPointStore
            var coords: [Double] = [0, 0]
            if let point = mapPointStore?.points.first(where: { $0.id.uuidString == pointID }) {
                coords = [Double(point.mapPoint.x), Double(point.mapPoint.y)]
            }
            
            // Load full scan data for each session
            var scans: [[String: Any]] = []
            for sessionID in sessionIDs {
                if let scanData = await loadSessionData(sessionID: sessionID) {
                    scans.append(scanData)
                }
            }
            
            mapPointsData.append([
                "pointID": pointID,
                "coordinates": coords,
                "sessions": scans
            ])
        }
        
        let masterExport: [String: Any] = [
            "exportDate": ISO8601DateFormatter().string(from: Date()),
            "locationID": ctx.locationID,
            "metadata": [
                "appVersion": appVersion(),
                "totalMapPoints": sessionIndex.count,
                "totalSessions": sessionIndex.values.flatMap { $0 }.count
            ],
            "mapPoints": mapPointsData
        ]
        
        return try JSONSerialization.data(withJSONObject: masterExport, options: [.prettyPrinted, .sortedKeys])
    }
    
    // MARK: - Diagnostic
    
    /// Diagnostic: Print all scan files found on disk
    func printFilesystemDiagnostic() {
        print("\n" + String(repeating: "=", count: 80))
        print("📂 FILESYSTEM DIAGNOSTIC - SCAN FILES")
        print(String(repeating: "=", count: 80))
        
        let locationID = ctx.locationID
        print("Current locationID: \(locationID)")
        
        do {
            let baseDir = try PathProvider.baseDir()
            print("\n📁 Base directory: \(baseDir.path)")
            
            let locationsDir = baseDir.appendingPathComponent("Locations")
            print("📁 Locations directory: \(locationsDir.path)")
            print("   Exists: \(FileManager.default.fileExists(atPath: locationsDir.path))")
            
            let locationDir = locationsDir.appendingPathComponent(locationID)
            print("📁 Location directory: \(locationDir.path)")
            print("   Exists: \(FileManager.default.fileExists(atPath: locationDir.path))")
            
            let scansDir = locationDir.appendingPathComponent("Scans")
            print("📁 Scans directory: \(scansDir.path)")
            print("   Exists: \(FileManager.default.fileExists(atPath: scansDir.path))")
            
            if FileManager.default.fileExists(atPath: scansDir.path) {
                let monthDirs = try FileManager.default.contentsOfDirectory(at: scansDir, includingPropertiesForKeys: nil)
                print("\n📅 Month directories found: \(monthDirs.count)")
                
                for monthDir in monthDirs.sorted(by: { $0.path < $1.path }) {
                    let jsonFiles = try FileManager.default.contentsOfDirectory(at: monthDir, includingPropertiesForKeys: nil)
                        .filter { $0.pathExtension == "json" }
                        .sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
                    
                    print("\n\(monthDir.path)/")
                    print("Files: \(jsonFiles.count)\n")
                    
                    var isFirstFile = true
                    
                    for file in jsonFiles {
                        print("\(file.lastPathComponent)")
                        
                        if let data = try? Data(contentsOf: file),
                           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            let pointID = json["pointID"] as? String ?? "missing"
                            let sessionID = json["sessionID"] as? String ?? "missing"
                            print("          pointID: \(pointID)")
                            print("          sessionID: \(sessionID)")
                            
                            // Display full contents of first file
                            if isFirstFile {
                                print("\n" + String(repeating: "~", count: 80))
                                print("📄 DISPLAYING FIRST FILE CONTENTS:")
                                print(String(repeating: "~", count: 80))
                                JSONFileViewer.displayFile(at: file, maxDepth: 10, truncateArrays: 10)
                                isFirstFile = false
                            }
                        } else {
                            print("          ⚠️ Could not read file")
                        }
                        print("")
                    }
                }
            } else {
                print("   ⚠️ Scans directory does not exist!")
            }
            
            print("\n🔍 Testing PersistenceService.listScans():")
            let urls = try PersistenceService.listScans(locationID: locationID)
            print("   Found \(urls.count) files via PersistenceService")
            
            for (index, url) in urls.prefix(3).enumerated() {
                print("   [\(index + 1)] \(url.lastPathComponent)")
            }
            
        } catch {
            print("❌ Error during diagnostic: \(error)")
        }
        
        print(String(repeating: "=", count: 80) + "\n")
    }
    
    /// Diagnostic: Print all files in Documents/locations directory
    func printDocumentsDiagnostic() {
        print("\n" + String(repeating: "=", count: 80))
        print("📂 DOCUMENTS DIAGNOSTIC - SCAN SUMMARIES")
        print(String(repeating: "=", count: 80))
        
        let locationID = ctx.locationID
        print("Current locationID: \(locationID)")
        
        do {
            // Get Documents directory
            guard let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                print("❌ Could not access Documents directory")
                return
            }
            
            print("\n📁 Documents directory: \(documentsDir.path)")
            print("   Exists: \(FileManager.default.fileExists(atPath: documentsDir.path))")
            
            let locationsDir = documentsDir.appendingPathComponent("locations")
            print("📁 locations directory: \(locationsDir.path)")
            print("   Exists: \(FileManager.default.fileExists(atPath: locationsDir.path))")
            
            let locationDir = locationsDir.appendingPathComponent(locationID)
            print("📁 location directory: \(locationDir.path)")
            print("   Exists: \(FileManager.default.fileExists(atPath: locationDir.path))")
            
            let scanSummariesDir = locationDir.appendingPathComponent("scan_summaries")
            print("📁 scan_summaries directory: \(scanSummariesDir.path)")
            print("   Exists: \(FileManager.default.fileExists(atPath: scanSummariesDir.path))")
            
            if FileManager.default.fileExists(atPath: scanSummariesDir.path) {
                let jsonFiles = try FileManager.default.contentsOfDirectory(at: scanSummariesDir, includingPropertiesForKeys: nil)
                    .filter { $0.pathExtension == "json" }
                    .sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
                
                print("\n\(scanSummariesDir.path)/")
                print("Files: \(jsonFiles.count)\n")
                
                var isFirstFile = true
                
                for file in jsonFiles {
                    print("\(file.lastPathComponent)")
                    
                    if let data = try? Data(contentsOf: file),
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        let pointID = json["mapPointID"] as? String ?? "missing"
                        let sessionID = json["sessionID"] as? String ?? "missing"
                        print("          mapPointID: \(pointID)")
                        print("          sessionID: \(sessionID)")
                        
                        // Show other fields present
                        let keys = json.keys.sorted()
                        print("          fields: \(keys.joined(separator: ", "))")
                        
                        // Display full contents of first file
                        if isFirstFile {
                            print("\n" + String(repeating: "~", count: 80))
                            print("📄 DISPLAYING FIRST FILE CONTENTS:")
                            print(String(repeating: "~", count: 80))
                            JSONFileViewer.displayFile(at: file, maxDepth: 10, truncateArrays: 10)
                            isFirstFile = false
                        }
                    } else {
                        print("          ⚠️ Could not read file")
                    }
                    print("")
                }
            } else {
                print("   ⚠️ scan_summaries directory does not exist!")
            }
            
        } catch {
            print("❌ Error during Documents diagnostic: \(error)")
        }
        
        print(String(repeating: "=", count: 80) + "\n")
    }
    
    // MARK: - Private Helpers
    
    private func appVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }
    
    // MARK: - TEMPORARY DEBUG FUNCTION - REMOVE AFTER DEBUGGING
    
    /// ⚠️ TEMPORARY: Delete all scan files from both locations
    /// This will delete:
    /// 1. All files in Documents/locations/{locationID}/scan_summaries/
    /// 2. All files in Application Support/TapResolver/Locations/{locationID}/Scans/
    func deleteAllScanFiles() {
        print("\n" + String(repeating: "⚠️", count: 40))
        print("🗑️ DELETING ALL SCAN FILES")
        print(String(repeating: "⚠️", count: 40))
        
        let locationID = ctx.locationID
        var totalDeleted = 0
        
        // 1. Delete from Documents/locations/home/scan_summaries/
        do {
            if let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let scanSummariesDir = documentsDir
                    .appendingPathComponent("locations")
                    .appendingPathComponent(locationID)
                    .appendingPathComponent("scan_summaries")
                
                if FileManager.default.fileExists(atPath: scanSummariesDir.path) {
                    let files = try FileManager.default.contentsOfDirectory(at: scanSummariesDir, includingPropertiesForKeys: nil)
                        .filter { $0.pathExtension == "json" }
                    
                    print("\n📂 Documents/scan_summaries/")
                    print("   Found \(files.count) files")
                    
                    for file in files {
                        try FileManager.default.removeItem(at: file)
                        print("   ✓ Deleted: \(file.lastPathComponent)")
                        totalDeleted += 1
                    }
                } else {
                    print("\n📂 Documents/scan_summaries/ - does not exist")
                }
            }
        } catch {
            print("❌ Error deleting from Documents: \(error)")
        }
        
        // 2. Delete from Application Support/TapResolver/Locations/home/Scans/
        do {
            let baseDir = try PathProvider.baseDir()
            let scansDir = baseDir
                .appendingPathComponent("Locations")
                .appendingPathComponent(locationID)
                .appendingPathComponent("Scans")
            
            if FileManager.default.fileExists(atPath: scansDir.path) {
                let monthDirs = try FileManager.default.contentsOfDirectory(at: scansDir, includingPropertiesForKeys: nil)
                
                print("\n📂 Application Support/Scans/")
                print("   Found \(monthDirs.count) month directories")
                
                for monthDir in monthDirs {
                    let files = try FileManager.default.contentsOfDirectory(at: monthDir, includingPropertiesForKeys: nil)
                        .filter { $0.pathExtension == "json" }
                    
                    print("\n   📅 \(monthDir.lastPathComponent)/")
                    print("      Found \(files.count) files")
                    
                    for file in files {
                        try FileManager.default.removeItem(at: file)
                        print("      ✓ Deleted: \(file.lastPathComponent)")
                        totalDeleted += 1
                    }
                }
            } else {
                print("\n📂 Application Support/Scans/ - does not exist")
            }
        } catch {
            print("❌ Error deleting from Application Support: \(error)")
        }
        
        print("\n" + String(repeating: "-", count: 80))
        print("✅ TOTAL DELETED: \(totalDeleted) files")
        print(String(repeating: "⚠️", count: 40) + "\n")
        
        // Clear the session index
        sessionIndex = [:]
        print("🔄 Cleared session index")
    }
}
