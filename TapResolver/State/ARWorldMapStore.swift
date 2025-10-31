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
    
    // MARK: - Save Patch

    public func savePatch(_ worldMap: ARWorldMap,
                         patchName: String,
                         action: String = "initial_scan",
                         duration_s: Double = 0.0,
                         areaCovered: String = "Unknown area") {
        
        let patchID = UUID()
        let filename = "patch_\(patchID.uuidString).ardata"
        let patchURL = patchesDirectory().appendingPathComponent(filename)
        
        print("💾 Saving new world map patch: '\(patchName)'")
        
        // Save ARWorldMap file
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true)
            try data.write(to: patchURL, options: .atomic)
            
            let fileSize = Double(data.count) / 1_048_576.0  // Convert to MB
            
            // Create patch metadata
            let patch = WorldMapPatch(
                id: patchID,
                name: patchName,
                worldMapFilename: filename,
                featurePointCount: worldMap.rawFeaturePoints.points.count,
                planeCount: worldMap.anchors.filter { $0 is ARPlaneAnchor }.count,
                areaCoveredDescription: areaCovered,
                scanDuration_s: duration_s
            )
            
            // Update patch with file size
            var mutablePatch = patch
            mutablePatch.fileSize_mb = fileSize
            
            // Add to patches array
            patches.append(mutablePatch)
            
            // Save patches metadata
            savePatchData()
            
            print("✅ Saved patch '\(patchName)':")
            print("   ID: \(patchID)")
            print("   File: \(filename)")
            print("   Size: \(String(format: "%.1f", fileSize)) MB")
            print("   Feature Points: \(worldMap.rawFeaturePoints.points.count)")
            print("   Planes: \(mutablePatch.planeCount)")
            
        } catch {
            print("❌ Failed to save patch: \(error)")
        }
    }

    // MARK: - Update Existing Patch

    public func updatePatch(_ patchID: UUID,
                           with worldMap: ARWorldMap,
                           duration_s: Double = 0.0,
                           areaCovered: String = "Extended area") {
        
        guard let existingPatchIndex = patches.firstIndex(where: { $0.id == patchID }) else {
            print("❌ Cannot update: Patch not found")
            return
        }
        
        var patch = patches[existingPatchIndex]
        let patchURL = patchesDirectory().appendingPathComponent(patch.worldMapFilename)
        
        print("💾 Updating existing patch: '\(patch.name)' (v\(patch.version))")
        
        // Backup current version before overwriting
        if FileManager.default.fileExists(atPath: patchURL.path) {
            let backupFilename = "patch_\(patchID.uuidString)_v\(patch.version).ardata"
            let backupURL = patchesDirectory().appendingPathComponent(backupFilename)
            
            do {
                try FileManager.default.copyItem(at: patchURL, to: backupURL)
                print("💾 Backed up v\(patch.version) to \(backupFilename)")
            } catch {
                print("⚠️ Failed to backup: \(error)")
            }
        }
        
        // Save updated world map (overwrite)
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true)
            try data.write(to: patchURL, options: .atomic)
            
            let fileSize = Double(data.count) / 1_048_576.0
            let newVersion = patch.version + 1
            
            // Update metadata
            patch.version = newVersion
            patch.fileSize_mb = fileSize
            patch.featurePointCount = worldMap.rawFeaturePoints.points.count
            patch.planeCount = worldMap.anchors.filter { $0 is ARPlaneAnchor }.count
            patch.lastExtendedDate = Date()
            patch.scanDuration_s += duration_s
            
            // Update in array
            patches[existingPatchIndex] = patch
            
            // Save metadata
            savePatchData()
            
            print("✅ Updated patch '\(patch.name)' to v\(newVersion):")
            print("   Size: \(String(format: "%.1f", fileSize)) MB")
            print("   Feature Points: \(worldMap.rawFeaturePoints.points.count)")
            print("   Planes: \(patch.planeCount)")
            
        } catch {
            print("❌ Failed to update patch: \(error)")
        }
    }

    // MARK: - Load Patch

    public func loadPatch(_ patchID: UUID) -> ARWorldMap? {
        guard let patch = patches.first(where: { $0.id == patchID }) else {
            print("❌ Patch not found: \(patchID)")
            return nil
        }
        
        let patchURL = patchesDirectory().appendingPathComponent(patch.worldMapFilename)
        
        do {
            let data = try Data(contentsOf: patchURL)
            guard let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data) else {
                print("❌ Failed to decode patch world map")
                return nil
            }
            
            print("✅ Loaded patch '\(patch.name)'")
            print("   Feature Points: \(worldMap.rawFeaturePoints.points.count)")
            print("   Anchors: \(worldMap.anchors.count)")
            
            return worldMap
            
        } catch {
            print("❌ Failed to load patch: \(error)")
            return nil
        }
    }
    
    // MARK: - Anchor Feature Management

    /// Get or create an anchor feature by name
    public func getOrCreateFeature(named name: String) -> AnchorFeature {
        if let existing = anchorFeatures.first(where: { $0.name == name }) {
            return existing
        }
        
        let newFeature = AnchorFeature(id: UUID(), name: name)
        anchorFeatures.append(newFeature)
        savePatchData()
        print("✅ Created new anchor feature: '\(name)'")
        return newFeature
    }

    /// Add an anchor area instance
    public func addAnchorArea(featureName: String,
                             patchID: UUID,
                             arAnchorID: UUID,
                             localPosition: SIMD3<Float>,
                             rawFeaturePoints: [RawFeaturePoint]) {
        
        // Get or create the feature
        var feature = getOrCreateFeature(named: featureName)
        
        // Create instance
        let instance = AnchorAreaInstance(
            id: UUID(),
            featureID: feature.id,
            patchID: patchID,
            centerPosition: localPosition,
            surfaceNormal: SIMD3<Float>(0, 1, 0),
            radius: 0.5,
            transform: simd_float4x4(1),
            arAnchorID: arAnchorID
        )
        
        // Add to collections
        anchorAreaInstances.append(instance)
        
        // Update feature's instance list
        if !feature.instanceIDs.contains(instance.id) {
            feature.instanceIDs.append(instance.id)
            if let index = anchorFeatures.firstIndex(where: { $0.id == feature.id }) {
                anchorFeatures[index] = feature
            }
        }
        
        // Save
        savePatchData()
        
        // Save raw features to binary file
        saveRawFeatures(instance.id, points: rawFeaturePoints)
        
        print("✅ Added anchor area '\(featureName)' to patch")
        print("   Instance ID: \(instance.id)")
        print("   Archived \(rawFeaturePoints.count) raw feature points")
    }

    /// Get all anchor areas for a specific patch
    public func anchorAreas(forPatch patchID: UUID) -> [AnchorAreaInstance] {
        return anchorAreaInstances.filter { $0.patchID == patchID }
    }

    /// Get feature name for an instance
    public func featureName(for instanceID: UUID) -> String? {
        guard let instance = anchorAreaInstances.first(where: { $0.id == instanceID }),
              let feature = anchorFeatures.first(where: { $0.id == instance.featureID }) else {
            return nil
        }
        return feature.name
    }

    /// Check if feature name already exists in patch
    public func featureExists(named name: String, inPatch patchID: UUID) -> Bool {
        return anchorAreaInstances.contains { area in
            guard let feature = anchorFeatures.first(where: { $0.id == area.featureID }) else {
                return false
            }
            return feature.name == name && area.patchID == patchID
        }
    }

    /// Get all existing feature names
    public func existingFeatureNames() -> [String] {
        return anchorFeatures.map { $0.name }.sorted()
    }

    /// Delete anchor area instance
    public func deleteAnchorArea(_ instanceID: UUID) {
        guard let instance = anchorAreaInstances.first(where: { $0.id == instanceID }) else {
            print("❌ Anchor area not found")
            return
        }
        
        let featureID = instance.featureID
        
        // Remove instance
        anchorAreaInstances.removeAll { $0.id == instanceID }
        
        // Update feature's instance list
        if let featureIndex = anchorFeatures.firstIndex(where: { $0.id == featureID }) {
            var feature = anchorFeatures[featureIndex]
            feature.instanceIDs.removeAll { $0 == instanceID }
            
            // If no more instances, delete the feature
            if feature.instanceIDs.isEmpty {
                anchorFeatures.remove(at: featureIndex)
                print("🗑️ Deleted anchor feature '\(feature.name)' (last instance)")
            } else {
                anchorFeatures[featureIndex] = feature
            }
        }
        
        // Delete raw feature file
        deleteRawFeatures(instanceID)
        
        // Save
        savePatchData()
        
        print("✅ Deleted anchor area instance")
    }

    /// Check if feature is linked across patches
    public func isFeatureLinked(_ featureID: UUID) -> Bool {
        guard let feature = anchorFeatures.first(where: { $0.id == featureID }) else {
            return false
        }
        
        let uniquePatches = Set(anchorAreaInstances
            .filter { $0.featureID == featureID }
            .map { $0.patchID })
        
        return uniquePatches.count > 1
    }

    // MARK: - Raw Feature Point Persistence

    private func saveRawFeatures(_ instanceID: UUID, points: [RawFeaturePoint]) {
        let filename = "anchor_\(instanceID.uuidString)_features.bin"
        let fileURL = auxiliaryDirectory().appendingPathComponent(filename)
        
        do {
            let data = try JSONEncoder().encode(points)
            try data.write(to: fileURL, options: .atomic)
            
            let sizeMB = Double(data.count) / 1_048_576.0
            print("💾 Saved \(points.count) raw features (\(String(format: "%.1f", sizeMB)) MB)")
            
        } catch {
            print("❌ Failed to save raw features: \(error)")
        }
    }

    private func deleteRawFeatures(_ instanceID: UUID) {
        let filename = "anchor_\(instanceID.uuidString)_features.bin"
        let fileURL = auxiliaryDirectory().appendingPathComponent(filename)
        
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
                print("🗑️ Deleted raw features file")
            }
        } catch {
            print("❌ Failed to delete raw features: \(error)")
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
