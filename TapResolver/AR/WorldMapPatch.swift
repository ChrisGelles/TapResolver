//
//  WorldMapPatch.swift
//  TapResolver
//
//  Data structures for managing multiple ARWorldMap patches per location
//

import Foundation
import CoreGraphics

/// Metadata for a single world map patch
public struct WorldMapPatchMeta: Codable, Identifiable {
    public let id: UUID
    let name: String                    // e.g. "Gallery A - North"
    let captureDate: Date
    let featureCount: Int               // from ARWorldMap.rawFeaturePoints
    let byteSize: Int                   // compressed size
    let center2D: CGPoint               // map coordinates
    let radiusM: Float                  // coverage radius in meters
    let version: Int                    // for future migrations
    
    public init(id: UUID = UUID(),
         name: String,
         captureDate: Date = Date(),
         featureCount: Int,
         byteSize: Int,
         center2D: CGPoint,
         radiusM: Float = 15.0,
         version: Int = 1) {
        self.id = id
        self.name = name
        self.captureDate = captureDate
        self.featureCount = featureCount
        self.byteSize = byteSize
        self.center2D = center2D
        self.radiusM = radiusM
        self.version = version
    }
}

/// Index of all world map patches for a location
public struct WorldMapPatchIndex: Codable {
    var schema: Int = 1
    var locationID: String
    var patches: [WorldMapPatchMeta]
    var created: Date
    var updated: Date
    
    public init(locationID: String, patches: [WorldMapPatchMeta] = []) {
        self.locationID = locationID
        self.patches = patches
        self.created = Date()
        self.updated = Date()
    }
    
    /// Find nearest patch to a map point
    func nearestPatch(to point: CGPoint) -> WorldMapPatchMeta? {
        guard !patches.isEmpty else { return nil }
        
        return patches.min(by: { patch1, patch2 in
            let dist1 = distance(from: patch1.center2D, to: point)
            let dist2 = distance(from: patch2.center2D, to: point)
            return dist1 < dist2
        })
    }
    
    private func distance(from: CGPoint, to: CGPoint) -> CGFloat {
        let dx = from.x - to.x
        let dy = from.y - to.y
        return sqrt(dx * dx + dy * dy)
    }
}
