//
//  ARWorldMapStore.swift
//  TapResolver
//
//  ARWorldMap-first persistence: survey → plant → relocalize
//

import Foundation
import ARKit
import Combine
import simd
import UIKit
import CoreGraphics

public final class ARWorldMapStore: ObservableObject {
    private let ctx = PersistenceContext.shared
    
    // MARK: - Published state
    
    @Published public var globalMapExists: Bool = false
    @Published public var globalMapVersion: Int = 1
    @Published public var globalMapMeta: GlobalMapMetadata?
    @Published public var markers: [ARMarker] = []
    @Published public var isLoading: Bool = false
    
    // MARK: - Debounce helpers
    
    private var lastConfigSig: String = ""
    private var lastConfigRunAt: Date = .distantPast
    
    // MARK: - Data models
    
    public struct GlobalMapMetadata: Codable {
        public let version: Int
        public let featurePointCount: Int
        public let anchorCount: Int
        public let capturedAt: Date
        public let deviceModel: String
        public let iOSVersion: String
        public let fileSize_bytes: Int
    }
    
    public struct ARMarker: Codable, Identifiable {
        public let id: String
        public let mapPointID: String
        public let worldTransform: CodableTransform
        public let createdAt: Date
        public var observations: MarkerObservations?
    }
    
    public struct MarkerObservations: Codable {
        public let distances_m: [Float]
        public let yawCoverage_deg: [Float]
        public let trackingQuality: [String]
        public let jitterStdDev_m: Float?
    }
    
    public struct CodableTransform: Codable {
        public let columns: [[Float]]
        
        public init(from transform: simd_float4x4) {
            columns = [
                [transform.columns.0.x, transform.columns.0.y, transform.columns.0.z, transform.columns.0.w],
                [transform.columns.1.x, transform.columns.1.y, transform.columns.1.z, transform.columns.1.w],
                [transform.columns.2.x, transform.columns.2.y, transform.columns.2.z, transform.columns.2.w],
                [transform.columns.3.x, transform.columns.3.y, transform.columns.3.z, transform.columns.3.w]
            ]
        }
        
        public func toSimd() -> simd_float4x4 {
            simd_float4x4(
                SIMD4<Float>(columns[0][0], columns[0][1], columns[0][2], columns[0][3]),
                SIMD4<Float>(columns[1][0], columns[1][1], columns[1][2], columns[1][3]),
                SIMD4<Float>(columns[2][0], columns[2][1], columns[2][2], columns[2][3]),
                SIMD4<Float>(columns[3][0], columns[3][1], columns[3][2], columns[3][3])
            )
        }
    }
    
    // MARK: - Directory helpers
    
    private func baseDirectory() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs
            .appendingPathComponent("locations")
            .appendingPathComponent(ctx.locationID)
            .appendingPathComponent("ARSpatial", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    private func globalMapURL(version: Int) -> URL {
        baseDirectory().appendingPathComponent("global_v\(version).armap")
    }
    
    private func globalMapMetaURL(version: Int) -> URL {
        baseDirectory().appendingPathComponent("global_v\(version)_meta.json")
    }
    
    private func markersDirectory() -> URL {
        let dir = baseDirectory().appendingPathComponent("Markers", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    private func markerDirectory(markerID: String) -> URL {
        let dir = markersDirectory().appendingPathComponent(markerID, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    private func markerMetaURL(markerID: String) -> URL {
        markerDirectory(markerID: markerID).appendingPathComponent("marker.json")
    }
    
    private func markerPatchURL(markerID: String) -> URL {
        markerDirectory(markerID: markerID).appendingPathComponent("patch.armap")
    }
    
    private func markerObservationsURL(markerID: String) -> URL {
        markerDirectory(markerID: markerID).appendingPathComponent("observations.json")
    }

    private func patchesDirectory() -> URL {
        let dir = baseDirectory().appendingPathComponent("Patches", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func patchURL(for id: UUID) -> URL {
        patchesDirectory().appendingPathComponent("\(id.uuidString).armap")
    }

    private func patchIndexURL() -> URL {
        patchesDirectory().appendingPathComponent("patch_index.json")
    }
    
    // MARK: - Lifecycle
    
    public init() {
        print("🧠 ARWorldMapStore init (ARWorldMap-first architecture)")
        loadGlobalMapMetadata()
        loadMarkers()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(locationDidChange),
            name: .locationDidChange,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func locationDidChange() {
        print("📍 ARWorldMapStore: Location changed → \(ctx.locationID)")
        DispatchQueue.main.async {
            self.loadGlobalMapMetadata()
            self.loadMarkers()
        }
    }
    
    // MARK: - Global map persistence
    
    public func saveGlobalMap(_ map: ARWorldMap, version: Int? = nil) throws {
        let targetVersion = version ?? globalMapVersion
        let url = globalMapURL(version: targetVersion)
        
        let data = try NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
        try data.write(to: url, options: .atomic)
        
        let meta = GlobalMapMetadata(
            version: targetVersion,
            featurePointCount: map.rawFeaturePoints.points.count,
            anchorCount: map.anchors.count,
            capturedAt: Date(),
            deviceModel: UIDevice.current.model,
            iOSVersion: UIDevice.current.systemVersion,
            fileSize_bytes: data.count
        )
        
        let metaData = try JSONEncoder().encode(meta)
        try metaData.write(to: globalMapMetaURL(version: targetVersion), options: .atomic)
        
        DispatchQueue.main.async {
            self.globalMapExists = true
            self.globalMapVersion = targetVersion
            self.globalMapMeta = meta
        }
        
        print("📦 Saved GlobalMap v\(targetVersion)")
        print("   Feature points: \(meta.featurePointCount)")
        print("   Size: \(String(format: "%.1f", Double(meta.fileSize_bytes) / 1_048_576)) MB")
    }
    
    public func loadGlobalMap(version: Int? = nil) throws -> ARWorldMap? {
        let targetVersion = version ?? globalMapVersion
        let url = globalMapURL(version: targetVersion)
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("⚠️ No GlobalMap found at v\(targetVersion)")
            return nil
        }
        
        let data = try Data(contentsOf: url)
        let map = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data)
        print("📂 Loaded GlobalMap v\(targetVersion)")
        return map
    }

    @discardableResult
    public func loadWorldMap(version: Int? = nil) -> ARWorldMap? {
        do {
            return try loadGlobalMap(version: version)
        } catch {
            print("❌ Failed to load GlobalMap: \(error)")
            return nil
        }
    }

    // MARK: - Multi-Patch Support

    /// Save a patch with metadata
    public func savePatch(_ map: ARWorldMap, meta: WorldMapPatchMeta) throws {
        let data = try NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
        let patchFile = patchURL(for: meta.id)
        try data.write(to: patchFile, options: .atomic)
        
        let finalMeta = WorldMapPatchMeta(
            id: meta.id,
            name: meta.name,
            captureDate: meta.captureDate,
            featureCount: meta.featureCount,
            byteSize: data.count,
            center2D: meta.center2D,
            radiusM: meta.radiusM,
            version: meta.version
        )
        
        var index = loadPatchIndex() ?? WorldMapPatchIndex(locationID: ctx.locationID)
        index.patches.removeAll { $0.id == meta.id }
        index.patches.append(finalMeta)
        index.updated = Date()
        try savePatchIndex(index)
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        let sizeString = formatter.string(fromByteCount: Int64(finalMeta.byteSize))
        
        print("📦 Saved patch '\(finalMeta.name)'")
        print("   Features: \(finalMeta.featureCount)")
        print("   Size: \(sizeString)")
        print("   Center: (\(Int(finalMeta.center2D.x)), \(Int(finalMeta.center2D.y)))")
        print("   Total patches for location: \(index.patches.count)")
    }

    /// Load a specific patch by ID
    public func loadPatch(id: UUID) -> ARWorldMap? {
        let patchFile = patchURL(for: id)
        guard FileManager.default.fileExists(atPath: patchFile.path) else {
            print("⚠️ No patch found with ID: \(id)")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: patchFile)
            let map = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data)
            print("📂 Loaded patch: \(id)")
            return map
        } catch {
            print("❌ Failed to decode patch: \(error)")
            return nil
        }
    }

    /// Load patch index
    public func loadPatchIndex() -> WorldMapPatchIndex? {
        let indexFile = patchIndexURL()
        guard FileManager.default.fileExists(atPath: indexFile.path) else { return nil }
        
        do {
            let data = try Data(contentsOf: indexFile)
            let index = try JSONDecoder().decode(WorldMapPatchIndex.self, from: data)
            return index
        } catch {
            print("❌ Failed to decode patch index: \(error)")
            return nil
        }
    }

    /// Save patch index
    private func savePatchIndex(_ index: WorldMapPatchIndex) throws {
        let indexFile = patchIndexURL()
        let data = try JSONEncoder().encode(index)
        try data.write(to: indexFile, options: .atomic)
    }

    /// Choose best patch for a map point
    public func chooseBestPatch(for mapPoint: CGPoint) -> (meta: WorldMapPatchMeta, map: ARWorldMap)? {
        guard let index = loadPatchIndex(), let nearest = index.nearestPatch(to: mapPoint) else {
            print("⚠️ No patches available")
            return nil
        }
        
        guard let map = loadPatch(id: nearest.id) else {
            print("⚠️ Failed to load nearest patch")
            return nil
        }
        
        let dx = nearest.center2D.x - mapPoint.x
        let dy = nearest.center2D.y - mapPoint.y
        let distance = sqrt(dx * dx + dy * dy)
        
        print("🎯 Selected patch '\(nearest.name)'")
        print("   Distance: \(String(format: "%.1f", distance)) map units")
        print("   Features: \(nearest.featureCount)")
        
        return (nearest, map)
    }
    
    private func loadGlobalMapMetadata() {
        let url = globalMapMetaURL(version: globalMapVersion)
        guard FileManager.default.fileExists(atPath: url.path) else {
            DispatchQueue.main.async {
                self.globalMapExists = false
                self.globalMapMeta = nil
            }
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let meta = try JSONDecoder().decode(GlobalMapMetadata.self, from: data)
            DispatchQueue.main.async {
                self.globalMapExists = true
                self.globalMapMeta = meta
            }
        } catch {
            print("❌ Failed to load GlobalMap metadata: \(error)")
            DispatchQueue.main.async {
                self.globalMapExists = false
                self.globalMapMeta = nil
            }
        }
    }
    
    // MARK: - Marker persistence
    
    public func saveMarker(_ marker: ARMarker, patch: ARWorldMap? = nil) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let markerData = try encoder.encode(marker)
        try markerData.write(to: markerMetaURL(markerID: marker.id), options: .atomic)
        
        if let patch = patch {
            let patchData = try NSKeyedArchiver.archivedData(withRootObject: patch, requiringSecureCoding: true)
            try patchData.write(to: markerPatchURL(markerID: marker.id), options: .atomic)
            print("   💾 Saved patch: \(String(format: "%.1f", Double(patchData.count) / 1_048_576)) MB")
        }
        
        if let observations = marker.observations {
            let obsData = try encoder.encode(observations)
            try obsData.write(to: markerObservationsURL(markerID: marker.id), options: .atomic)
        }
        
        DispatchQueue.main.async {
            if let index = self.markers.firstIndex(where: { $0.id == marker.id }) {
                self.markers[index] = marker
            } else {
                self.markers.append(marker)
            }
        }
        
        print("📍 Saved marker \(marker.id) (MapPoint: \(marker.mapPointID))")
    }
    
    public func loadMarkerPatch(markerID: String) throws -> ARWorldMap? {
        let url = markerPatchURL(markerID: markerID)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        return try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data)
    }
    
    private func loadMarkers() {
        let dir = markersDirectory()
        guard let entries = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else {
            DispatchQueue.main.async { self.markers = [] }
            return
        }
        
        var loaded: [ARMarker] = []
        for entry in entries where entry.hasDirectoryPath {
            let markerID = entry.lastPathComponent
            let metaURL = markerMetaURL(markerID: markerID)
            guard FileManager.default.fileExists(atPath: metaURL.path) else { continue }
            do {
                let data = try Data(contentsOf: metaURL)
                let marker = try JSONDecoder().decode(ARMarker.self, from: data)
                loaded.append(marker)
            } catch {
                print("❌ Failed to load marker \(markerID): \(error)")
            }
        }
        
        DispatchQueue.main.async {
            self.markers = loaded.sorted { $0.createdAt < $1.createdAt }
        }
        
        print("📍 Loaded \(loaded.count) marker(s)")
    }
    
    // MARK: - Config preservation
    
    public func preserveAndRun(
        _ mutate: (ARWorldTrackingConfiguration) -> Void,
        session: ARSession
    ) {
        guard let current = session.configuration as? ARWorldTrackingConfiguration else {
            print("❌ Cannot preserve config - not ARWorldTrackingConfiguration")
            return
        }
        
        let cfg = ARWorldTrackingConfiguration()
        cfg.worldAlignment = current.worldAlignment
        cfg.planeDetection = current.planeDetection
        cfg.environmentTexturing = current.environmentTexturing
        cfg.sceneReconstruction = current.sceneReconstruction
        cfg.maximumNumberOfTrackedImages = current.maximumNumberOfTrackedImages
        
        mutate(cfg)
        
        let sig = "di:\(cfg.detectionImages?.count ?? 0)|mt:\(cfg.maximumNumberOfTrackedImages)|pd:\(cfg.planeDetection.rawValue)|sr:\(cfg.sceneReconstruction.rawValue)"
        let now = Date()
        if sig == lastConfigSig, now.timeIntervalSince(lastConfigRunAt) < 0.30 {
            print("⏱️ Skipping config run (debounced & identical)")
            return
        }
        lastConfigSig = sig
        lastConfigRunAt = now
        
        session.run(cfg, options: [])
        
        print("🔧 Config updated:")
        print("   Detection images: \(cfg.detectionImages?.count ?? 0)")
        print("   Max tracked: \(cfg.maximumNumberOfTrackedImages)")
    }
    
    // MARK: - Diagnostics
    
    public func printDiagnostic() {
        print("\n📊 ARWorldMapStore Diagnostic")
        print("Location: \(ctx.locationID)")
        print("GlobalMap exists: \(globalMapExists)")
        if let meta = globalMapMeta {
            print("  Version: \(meta.version)")
            print("  Feature points: \(meta.featurePointCount)")
            print("  Anchors: \(meta.anchorCount)")
            print("  Size: \(String(format: "%.1f", Double(meta.fileSize_bytes) / 1_048_576)) MB")
            print("  Captured: \(meta.capturedAt)")
        }
        print("Markers: \(markers.count)")
        for marker in markers {
            print("  • \(marker.id)")
            print("    MapPoint: \(marker.mapPointID)")
            print("    Created: \(marker.createdAt)")
        }
        print()
    }
}

