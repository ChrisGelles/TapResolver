//
//  AnchorAreaInstance.swift
//  TapResolver
//
//  Role: A specific spray-painted area in a specific world map patch
//        Links to an AnchorFeature (the semantic landmark)
//

import Foundation
import simd

public struct AnchorAreaInstance: Identifiable, Codable {
    public let id: UUID
    public let featureID: UUID                        // → AnchorFeature (what landmark is here)
    public let patchID: UUID                          // → WorldMapPatch (which patch is this in)
    
    // Spatial properties (in the patch's coordinate system)
    public var centerPosition: SIMD3<Float>           // [x, y, z] in meters
    public var surfaceNormal: SIMD3<Float>            // Which way the surface faces
    public var radius: Float                          // Spray-painted extent (e.g., 0.3m)
    public var transform: simd_float4x4               // Full position + orientation matrix
    
    // ARKit integration
    public var arAnchorID: UUID                       // The ARAnchor UUID in the ARWorldMap
    
    // Metadata
    public let createdDate: Date
    public var snapshotCount: Int                     // How many reinforcement snapshots
    public var lastSnapshotTime: Date?
    
    // OPTION B: Raw feature data captured in this area (READY FOR ACTIVATION)
    public var rawFeaturePoints: [RawFeaturePoint]?   // = nil
    
    public init(id: UUID = UUID(),
         featureID: UUID,
         patchID: UUID,
         centerPosition: SIMD3<Float>,
         surfaceNormal: SIMD3<Float>,
         radius: Float,
         transform: simd_float4x4,
         arAnchorID: UUID) {
        self.id = id
        self.featureID = featureID
        self.patchID = patchID
        self.centerPosition = centerPosition
        self.surfaceNormal = surfaceNormal
        self.radius = radius
        self.transform = transform
        self.arAnchorID = arAnchorID
        self.createdDate = Date()
        self.snapshotCount = 0
        self.lastSnapshotTime = nil
        self.rawFeaturePoints = nil
    }
}

// OPTION B: Raw feature point storage (infrastructure ready)
public struct RawFeaturePoint: Codable {
    public let position: SIMD3<Float>
    public let timestamp: Date
    public var observationCount: Int                  // Increments each time re-observed
    
    public init(position: SIMD3<Float>, timestamp: Date = Date(), observationCount: Int = 1) {
        self.position = position
        self.timestamp = timestamp
        self.observationCount = observationCount
    }
    
    // OPTION B FUTURE: Additional data (commented out for now)
    // var confidence: Float? = nil
    // var normalVector: SIMD3<Float>? = nil
}

// MARK: - Codable Conformance for simd types

extension AnchorAreaInstance {
    enum CodingKeys: String, CodingKey {
        case id, featureID, patchID
        case centerPosition, surfaceNormal, radius, transform
        case arAnchorID, createdDate, snapshotCount, lastSnapshotTime
        case rawFeaturePoints
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        featureID = try container.decode(UUID.self, forKey: .featureID)
        patchID = try container.decode(UUID.self, forKey: .patchID)
        
        // Decode SIMD3<Float> as [Float]
        let posArray = try container.decode([Float].self, forKey: .centerPosition)
        guard posArray.count == 3 else {
            throw DecodingError.dataCorruptedError(forKey: .centerPosition, in: container,
                                                   debugDescription: "Expected 3 elements")
        }
        centerPosition = SIMD3<Float>(posArray[0], posArray[1], posArray[2])
        
        let normalArray = try container.decode([Float].self, forKey: .surfaceNormal)
        guard normalArray.count == 3 else {
            throw DecodingError.dataCorruptedError(forKey: .surfaceNormal, in: container,
                                                   debugDescription: "Expected 3 elements")
        }
        surfaceNormal = SIMD3<Float>(normalArray[0], normalArray[1], normalArray[2])
        
        radius = try container.decode(Float.self, forKey: .radius)
        
        // Decode simd_float4x4 as flat [Float] array (16 elements)
        let matrixArray = try container.decode([Float].self, forKey: .transform)
        guard matrixArray.count == 16 else {
            throw DecodingError.dataCorruptedError(forKey: .transform, in: container,
                                                   debugDescription: "Expected 16 elements")
        }
        transform = simd_float4x4(
            SIMD4<Float>(matrixArray[0], matrixArray[1], matrixArray[2], matrixArray[3]),
            SIMD4<Float>(matrixArray[4], matrixArray[5], matrixArray[6], matrixArray[7]),
            SIMD4<Float>(matrixArray[8], matrixArray[9], matrixArray[10], matrixArray[11]),
            SIMD4<Float>(matrixArray[12], matrixArray[13], matrixArray[14], matrixArray[15])
        )
        
        arAnchorID = try container.decode(UUID.self, forKey: .arAnchorID)
        createdDate = try container.decode(Date.self, forKey: .createdDate)
        snapshotCount = try container.decode(Int.self, forKey: .snapshotCount)
        lastSnapshotTime = try container.decodeIfPresent(Date.self, forKey: .lastSnapshotTime)
        rawFeaturePoints = try container.decodeIfPresent([RawFeaturePoint].self, forKey: .rawFeaturePoints)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(featureID, forKey: .featureID)
        try container.encode(patchID, forKey: .patchID)
        try container.encode([centerPosition.x, centerPosition.y, centerPosition.z], forKey: .centerPosition)
        try container.encode([surfaceNormal.x, surfaceNormal.y, surfaceNormal.z], forKey: .surfaceNormal)
        try container.encode(radius, forKey: .radius)
        
        // Encode simd_float4x4 as flat array
        let matrixArray: [Float] = [
            transform.columns.0.x, transform.columns.0.y, transform.columns.0.z, transform.columns.0.w,
            transform.columns.1.x, transform.columns.1.y, transform.columns.1.z, transform.columns.1.w,
            transform.columns.2.x, transform.columns.2.y, transform.columns.2.z, transform.columns.2.w,
            transform.columns.3.x, transform.columns.3.y, transform.columns.3.z, transform.columns.3.w
        ]
        try container.encode(matrixArray, forKey: .transform)
        
        try container.encode(arAnchorID, forKey: .arAnchorID)
        try container.encode(createdDate, forKey: .createdDate)
        try container.encode(snapshotCount, forKey: .snapshotCount)
        try container.encodeIfPresent(lastSnapshotTime, forKey: .lastSnapshotTime)
        try container.encodeIfPresent(rawFeaturePoints, forKey: .rawFeaturePoints)
    }
}

extension RawFeaturePoint {
    enum CodingKeys: String, CodingKey {
        case position, timestamp, observationCount
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let posArray = try container.decode([Float].self, forKey: .position)
        guard posArray.count == 3 else {
            throw DecodingError.dataCorruptedError(forKey: .position, in: container,
                                                   debugDescription: "Expected 3 elements")
        }
        position = SIMD3<Float>(posArray[0], posArray[1], posArray[2])
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        observationCount = try container.decode(Int.self, forKey: .observationCount)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode([position.x, position.y, position.z], forKey: .position)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(observationCount, forKey: .observationCount)
    }
}

