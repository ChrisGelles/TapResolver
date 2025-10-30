//
//  ARWorldMapStore.swift
//  TapResolver
//
//  Role: Manages ARWorldMap persistence, loading, and metadata tracking
//

import SwiftUI
import ARKit
import Combine

public final class ARWorldMapStore: ObservableObject {
    private let ctx = PersistenceContext.shared
    
    // MARK: - Data Models
    
    public struct WorldMapMetadata: Codable {
        public var exists: Bool
        public var version: Int
        public var fileSize_mb: Double
        public var featurePointCount: Int
        public var planeCount: Int
        public var lastUpdated: String  // ISO8601
        public var scanSessions: [ScanSession]
        
        public struct ScanSession: Codable {
            public let sessionID: String
            public let action: String  // "initial_scan", "extension"
            public let timestamp: String  // ISO8601
            public let duration_s: Double
            public let newFeaturePoints: Int
            public let areaCovered: String
        }
        
        init() {
            self.exists = false
            self.version = 0
            self.fileSize_mb = 0.0
            self.featurePointCount = 0
            self.planeCount = 0
            self.lastUpdated = ISO8601DateFormatter().string(from: Date())
            self.scanSessions = []
        }
    }
    
    // MARK: - Published State
    
    @Published public var metadata: WorldMapMetadata = WorldMapMetadata()
    @Published public var isLoading: Bool = false
    
    // MARK: - Patch-Based System (NEW)

    @Published public var patches: [WorldMapPatch] = []
    @Published public var anchorFeatures: [AnchorFeature] = []
    @Published public var anchorAreaInstances: [AnchorAreaInstance] = []
    
    // MARK: - File Paths
    
    private func worldMapURL() -> URL {
        let locationDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("locations")
            .appendingPathComponent(ctx.locationID)
        
        try? FileManager.default.createDirectory(at: locationDir, withIntermediateDirectories: true)
        
        return locationDir.appendingPathComponent("arWorldMap.data")
    }
    
    private func backupURL(version: Int) -> URL {
        let locationDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("locations")
            .appendingPathComponent(ctx.locationID)
        
        return locationDir.appendingPathComponent("arWorldMap_v\(version).data")
    }
    
    private func metadataURL() -> URL {
        let locationDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("locations")
            .appendingPathComponent(ctx.locationID)
        
        return locationDir.appendingPathComponent("arWorldMapMetadata.json")
    }
    
    // MARK: - Patch-Based File Paths

    private func arSpatialDirectory() -> URL {
        let locationDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("locations")
            .appendingPathComponent(ctx.locationID)
            .appendingPathComponent("ar_spatial")
        
        try? FileManager.default.createDirectory(at: locationDir, withIntermediateDirectories: true)
        return locationDir
    }

    private func patchesDirectory() -> URL {
        let dir = arSpatialDirectory().appendingPathComponent("patches")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func auxiliaryDirectory() -> URL {
        let dir = arSpatialDirectory().appendingPathComponent("auxiliary")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func patchMetadataURL() -> URL {
        return arSpatialDirectory().appendingPathComponent("patch_metadata.json")
    }

    private func anchorRegistryURL() -> URL {
        return arSpatialDirectory().appendingPathComponent("anchor_registry.json")
    }

    private func anchorAreasURL() -> URL {
        return arSpatialDirectory().appendingPathComponent("anchor_areas.json")
    }
    
    // MARK: - Initialization
    
    public init() {
        print("🧠 ARWorldMapStore init")
        loadMetadata()
        loadPatchData()
        
        // Listen for location changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(locationDidChange),
            name: .locationDidChange,
            object: nil
        )
    }
    
    @objc private func locationDidChange() {
        print("📍 ARWorldMapStore: Location changed, reloading metadata")
        loadMetadata()
        loadPatchData()
    }
    
    // MARK: - Metadata Persistence
    
    private func saveMetadata() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        do {
            let data = try encoder.encode(metadata)
            try data.write(to: metadataURL(), options: .atomic)
            print("💾 Saved ARWorldMap metadata:")
            print("   Version: \(metadata.version)")
            print("   Size: \(String(format: "%.1f", metadata.fileSize_mb)) MB")
            print("   Feature Points: \(metadata.featurePointCount)")
        } catch {
            print("❌ Failed to save metadata: \(error)")
        }
    }
    
    public func loadMetadata() {
        do {
            let data = try Data(contentsOf: metadataURL())
            metadata = try JSONDecoder().decode(WorldMapMetadata.self, from: data)
            print("📂 Loaded ARWorldMap metadata: v\(metadata.version), \(metadata.featurePointCount) points")
        } catch {
            // No metadata file exists yet
            metadata = WorldMapMetadata()
            
            // Check if world map file exists anyway
            if FileManager.default.fileExists(atPath: worldMapURL().path) {
                metadata.exists = true
                print("⚠️ ARWorldMap file exists but no metadata")
            } else {
                print("📂 No ARWorldMap found for location '\(ctx.locationID)'")
            }
        }
    }
    
    // MARK: - Save World Map
    
    public func saveWorldMap(_ worldMap: ARWorldMap,
                            action: String = "initial_scan",
                            duration_s: Double = 0.0,
                            areaCovered: String = "Unknown area") {
        
        // Backup existing map if it exists
        if metadata.exists && metadata.version > 0 {
            do {
                let currentURL = worldMapURL()
                let backup = backupURL(version: metadata.version)
                try FileManager.default.copyItem(at: currentURL, to: backup)
                print("💾 Backed up v\(metadata.version) to \(backup.lastPathComponent)")
            } catch {
                print("⚠️ Failed to backup: \(error)")
            }
        }
        
        // Save new world map
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true)
            try data.write(to: worldMapURL(), options: .atomic)
            
            // Update metadata
            let fileSize = Double(data.count) / 1_048_576.0  // Convert to MB
            let newVersion = metadata.version + 1
            
            let session = WorldMapMetadata.ScanSession(
                sessionID: "scan_\(ISO8601DateFormatter().string(from: Date()))",
                action: action,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                duration_s: duration_s,
                newFeaturePoints: worldMap.rawFeaturePoints.points.count,
                areaCovered: areaCovered
            )
            
            metadata.exists = true
            metadata.version = newVersion
            metadata.fileSize_mb = fileSize
            metadata.featurePointCount = worldMap.rawFeaturePoints.points.count
            metadata.planeCount = worldMap.anchors.filter { $0 is ARPlaneAnchor }.count
            metadata.lastUpdated = ISO8601DateFormatter().string(from: Date())
            metadata.scanSessions.append(session)
            
            saveMetadata()
            
            print("✅ Saved ARWorldMap v\(newVersion):")
            print("   Size: \(String(format: "%.1f", fileSize)) MB")
            print("   Feature Points: \(worldMap.rawFeaturePoints.points.count)")
            print("   Planes: \(metadata.planeCount)")
            
        } catch {
            print("❌ Failed to save ARWorldMap: \(error)")
        }
    }
    
    // MARK: - Load World Map
    
    public func loadWorldMap() -> ARWorldMap? {
        guard metadata.exists else {
            print("📂 No ARWorldMap to load")
            return nil
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let data = try Data(contentsOf: worldMapURL())
            guard let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data) else {
                print("❌ Failed to decode ARWorldMap")
                return nil
            }
            
            print("✅ Loaded ARWorldMap v\(metadata.version)")
            print("   Feature Points: \(worldMap.rawFeaturePoints.points.count)")
            print("   Anchors: \(worldMap.anchors.count)")
            
            return worldMap
            
        } catch {
            print("❌ Failed to load ARWorldMap: \(error)")
            return nil
        }
    }
    
    // MARK: - Delete World Map
    
    public func deleteWorldMap() {
        do {
            if FileManager.default.fileExists(atPath: worldMapURL().path) {
                try FileManager.default.removeItem(at: worldMapURL())
                print("🗑️ Deleted ARWorldMap")
            }
            
            // Delete backups
            let locationDir = worldMapURL().deletingLastPathComponent()
            let backups = try FileManager.default.contentsOfDirectory(at: locationDir, includingPropertiesForKeys: nil)
                .filter { $0.lastPathComponent.hasPrefix("arWorldMap_v") }
            
            for backup in backups {
                try FileManager.default.removeItem(at: backup)
                print("🗑️ Deleted backup: \(backup.lastPathComponent)")
            }
            
            // Reset metadata
            metadata = WorldMapMetadata()
            saveMetadata()
            
        } catch {
            print("❌ Failed to delete ARWorldMap: \(error)")
        }
    }
    
    // MARK: - Patch-Based Persistence

    public func loadPatchData() {
        // Load patches
        do {
            let data = try Data(contentsOf: patchMetadataURL())
            patches = try JSONDecoder().decode([WorldMapPatch].self, from: data)
            print("📂 Loaded \(patches.count) world map patches")
        } catch {
            patches = []
            print("📂 No patch metadata found (starting fresh)")
        }
        
        // Load anchor features
        do {
            let data = try Data(contentsOf: anchorRegistryURL())
            anchorFeatures = try JSONDecoder().decode([AnchorFeature].self, from: data)
            print("📂 Loaded \(anchorFeatures.count) anchor features")
        } catch {
            anchorFeatures = []
            print("📂 No anchor registry found (starting fresh)")
        }
        
        // Load anchor area instances
        do {
            let data = try Data(contentsOf: anchorAreasURL())
            anchorAreaInstances = try JSONDecoder().decode([AnchorAreaInstance].self, from: data)
            print("📂 Loaded \(anchorAreaInstances.count) anchor area instances")
        } catch {
            anchorAreaInstances = []
            print("📂 No anchor areas found (starting fresh)")
        }
    }

    public func savePatchData() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        // Save patches
        do {
            let data = try encoder.encode(patches)
            try data.write(to: patchMetadataURL(), options: .atomic)
            print("💾 Saved \(patches.count) patches")
        } catch {
            print("❌ Failed to save patches: \(error)")
        }
        
        // Save anchor features
        do {
            let data = try encoder.encode(anchorFeatures)
            try data.write(to: anchorRegistryURL(), options: .atomic)
            print("💾 Saved \(anchorFeatures.count) anchor features")
        } catch {
            print("❌ Failed to save anchor features: \(error)")
        }
        
        // Save anchor area instances
        do {
            let data = try encoder.encode(anchorAreaInstances)
            try data.write(to: anchorAreasURL(), options: .atomic)
            print("💾 Saved \(anchorAreaInstances.count) anchor area instances")
        } catch {
            print("❌ Failed to save anchor area instances: \(error)")
        }
    }

    // OPTION B: Raw feature data persistence (ready to activate)
    // private func saveRawFeatureData(_ data: Data, for zoneID: UUID) {
    //     let url = auxiliaryDirectory().appendingPathComponent("zone_\(zoneID.uuidString)_features.bin")
    //     try? data.write(to: url)
    //     print("💾 Saved raw feature data for zone \(zoneID)")
    // }
    
    // MARK: - Utilities
    
    public func hasWorldMap() -> Bool {
        return metadata.exists
    }
    
    public func getVersionHistory() -> [Int] {
        let locationDir = worldMapURL().deletingLastPathComponent()
        guard let files = try? FileManager.default.contentsOfDirectory(at: locationDir, includingPropertiesForKeys: nil) else {
            return []
        }
        
        let versions = files
            .filter { $0.lastPathComponent.hasPrefix("arWorldMap_v") }
            .compactMap { url -> Int? in
                let name = url.deletingPathExtension().lastPathComponent
                let versionString = name.replacingOccurrences(of: "arWorldMap_v", with: "")
                return Int(versionString)
            }
            .sorted()
        
        return versions
    }
}
