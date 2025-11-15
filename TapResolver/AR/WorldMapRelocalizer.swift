//
//  WorldMapRelocalizer.swift
//  TapResolver
//
//  WorldMap-based relocalization strategy implementation
//

import Foundation
import ARKit

/// Relocalization strategy using ARWorldMap
final class WorldMapRelocalizer: RelocalizationStrategy {
    let id: String = "worldmap"
    let displayName: String = "ARWorldMap"
    
    private let arStore: ARWorldMapStore
    
    init(arStore: ARWorldMapStore) {
        self.arStore = arStore
    }
    
    func attemptRelocalization(
        for triangle: TrianglePatch,
        session: ARSession,
        completion: @escaping (RelocalizationResult) -> Void
    ) {
        // Load the .armap file for this triangle
        let (worldMap, filename) = loadWorldMap(for: triangle)
        
        guard let worldMap = worldMap else {
            let result = RelocalizationResult(
                success: false,
                confidence: 0.0,
                notes: "No ARWorldMap file found for triangle \(String(triangle.id.uuidString.prefix(8)))",
                strategyID: id,
                usedWorldMapFilename: nil
            )
            completion(result)
            return
        }
        
        // Apply the world map to the session
        let config = ARWorldTrackingConfiguration()
        config.initialWorldMap = worldMap
        config.planeDetection = [.horizontal]
        
        session.run(config, options: [.resetTracking, .removeExistingAnchors])
        
        // Evaluate the match quality
        // Note: ARKit doesn't provide immediate feedback, so we use heuristics
        let confidence = evaluateMatchQuality(worldMap: worldMap)
        
        let result = RelocalizationResult(
            success: confidence > 0.3,  // Threshold for "success"
            confidence: confidence,
            notes: "Applied ARWorldMap with \(worldMap.rawFeaturePoints.points.count) feature points",
            strategyID: id,
            usedWorldMapFilename: filename
        )
        
        // Small delay to allow ARKit to process
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion(result)
        }
    }
    
    /// Load ARWorldMap for a triangle from strategy-specific folder
    /// - Returns: Tuple of (ARWorldMap?, filename: String?)
    private func loadWorldMap(for triangle: TrianglePatch) -> (ARWorldMap?, String?) {
        // Use the strategy-specific path helper
        let url = ARWorldMapStore.strategyWorldMapURL(for: triangle.id, strategyID: id)
        let filename = url.lastPathComponent
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("⚠️ No ARWorldMap found at: \(url.path)")
            return (nil, nil)
        }
        
        do {
            let data = try Data(contentsOf: url)
            let map = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data)
            print("📂 Loaded ARWorldMap for triangle \(String(triangle.id.uuidString.prefix(8)))")
            return (map, filename)
        } catch {
            print("❌ Failed to load ARWorldMap: \(error)")
            return (nil, nil)
        }
    }
    
    /// Evaluate match quality based on world map characteristics
    private func evaluateMatchQuality(worldMap: ARWorldMap) -> Float {
        // Heuristic: more feature points = higher confidence
        let featureCount = worldMap.rawFeaturePoints.points.count
        let anchorCount = worldMap.anchors.count
        
        // Normalize feature count (typical range: 0-10000)
        let featureScore = min(1.0, Float(featureCount) / 5000.0)
        
        // Anchors provide spatial structure
        let anchorScore = min(1.0, Float(anchorCount) / 10.0)
        
        // Weighted combination
        let confidence = (featureScore * 0.7) + (anchorScore * 0.3)
        
        return confidence
    }
}

