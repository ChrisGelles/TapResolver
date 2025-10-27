//
//  ARMarker.swift
//  TapResolver
//
//  Role: Represents AR markers that link 3D AR space to 2D map points
//

import Foundation
import simd
import CoreGraphics

struct ARMarker: Identifiable, Codable {
    let id: UUID  // markerID
    let linkedMapPointID: UUID
    var arPosition: simd_float3  // [x, y, z] in AR world space (meters)
    var mapCoordinates: CGPoint  // 2D position matching the linked MapPoint
    let createdAt: Date
    
    init(id: UUID = UUID(),
         linkedMapPointID: UUID,
         arPosition: simd_float3,
         mapCoordinates: CGPoint) {
        self.id = id
        self.linkedMapPointID = linkedMapPointID
        self.arPosition = arPosition
        self.mapCoordinates = mapCoordinates
        self.createdAt = Date()
    }
}

// MARK: - Codable Conformance for simd_float3

extension ARMarker {
    enum CodingKeys: String, CodingKey {
        case id = "markerID"
        case linkedMapPointID
        case arPosition
        case mapCoordinates
        case createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        linkedMapPointID = try container.decode(UUID.self, forKey: .linkedMapPointID)
        
        // Decode arPosition as array
        let posArray = try container.decode([Float].self, forKey: .arPosition)
        guard posArray.count == 3 else {
            throw DecodingError.dataCorruptedError(
                forKey: .arPosition,
                in: container,
                debugDescription: "arPosition must have exactly 3 elements"
            )
        }
        arPosition = simd_float3(posArray[0], posArray[1], posArray[2])
        
        // Decode mapCoordinates
        let coordArray = try container.decode([CGFloat].self, forKey: .mapCoordinates)
        guard coordArray.count == 2 else {
            throw DecodingError.dataCorruptedError(
                forKey: .mapCoordinates,
                in: container,
                debugDescription: "mapCoordinates must have exactly 2 elements"
            )
        }
        mapCoordinates = CGPoint(x: coordArray[0], y: coordArray[1])
        
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(linkedMapPointID, forKey: .linkedMapPointID)
        try container.encode([arPosition.x, arPosition.y, arPosition.z], forKey: .arPosition)
        try container.encode([mapCoordinates.x, mapCoordinates.y], forKey: .mapCoordinates)
        try container.encode(createdAt, forKey: .createdAt)
    }
}
