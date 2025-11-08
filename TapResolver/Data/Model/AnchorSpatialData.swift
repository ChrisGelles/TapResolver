//
//  AnchorSpatialData.swift
//  TapResolver
//
//  Created by Chris Gelles on 11/6/25.
//
//  Role: Portable 3D spatial data for anchor points
//

import Foundation
import ARKit
import simd

// MARK: - Complete Anchor Point Package

struct AnchorPointPackage: Codable {
    let id: UUID
    let mapPointID: UUID
    let mapCoordinates: CGPoint
    let anchorPosition: simd_float3
    let anchorSessionTransform: simd_float4x4
    let captureDate: Date
    var spatialData: AnchorSpatialData
    var referenceImages: [AnchorReferenceImage]
    var visualDescription: String?
    
    // Milestone 4: Precision floor marker
    var floorMarker: FloorMarkerCapture?
    
    // Spatial relationship between floor marker and anchor
    var floorMarkerToAnchorOffset: simd_float3?
    
    // Milestone 5: Wide-angle context (placeholder)
    var contextCaptures: [WideAngleCapture] = []
    
    // Milestone 7: Beacon proximity (placeholder)
    var proximityBeacons: [BeaconReference] = []
    
    init(mapPointID: UUID, mapCoordinates: CGPoint, anchorPosition: simd_float3, anchorSessionTransform: simd_float4x4, visualDescription: String? = nil) {
        self.id = UUID()
        self.mapPointID = mapPointID
        self.mapCoordinates = mapCoordinates
        self.anchorPosition = anchorPosition
        self.anchorSessionTransform = anchorSessionTransform
        self.captureDate = Date()
        self.spatialData = AnchorSpatialData(featureCloud: AnchorFeatureCloud(points: [], anchorPosition: anchorPosition, captureRadius: 0), planes: [])
        self.referenceImages = []
        self.visualDescription = visualDescription
        self.floorMarker = nil
        self.floorMarkerToAnchorOffset = nil
        self.contextCaptures = []
        self.proximityBeacons = []
    }
}

// MARK: - Reference Image

struct AnchorReferenceImage: Codable {
    let id: UUID
    let captureType: CaptureType
    let imageData: Data  // JPEG compressed
    let captureDate: Date
    
    enum CaptureType: String, Codable {
        case floorFar = "floor_far"
        case floorClose = "floor_close"
        case wallNorth = "wall_north"
        case wallSouth = "wall_south"
        case wallEast = "wall_east"
        case wallWest = "wall_west"
        case signature = "signature"
    }
    
    init(captureType: CaptureType, imageData: Data) {
        self.id = UUID()
        self.captureType = captureType
        self.imageData = imageData
        self.captureDate = Date()
    }
}

// MARK: - Spatial Data Container

struct AnchorSpatialData: Codable {
    var featureCloud: AnchorFeatureCloud
    var planes: [AnchorPlaneData]
    
    var totalDataSize: Int {
        let featureSize = featureCloud.points.count * MemoryLayout<simd_float3>.size
        let planeSize = planes.count * MemoryLayout<AnchorPlaneData>.size
        return featureSize + planeSize
    }
}

// MARK: - Feature Point Cloud

struct AnchorFeatureCloud: Codable {
    let points: [simd_float3]  // Raw 3D feature points
    let anchorPosition: simd_float3  // Center of capture
    let captureRadius: Float  // Meters
    
    var pointCount: Int { points.count }
}

// MARK: - Plane Anchor Data

struct AnchorPlaneData: Codable {
    let planeID: UUID
    let transform: simd_float4x4
    let extent: PlaneExtent
    let alignment: PlaneAlignment
    
    struct PlaneExtent: Codable {
        let width: Float
        let height: Float
    }
    
    enum PlaneAlignment: String, Codable {
        case horizontal
        case vertical
    }
}

// MARK: - Codable Support for simd Types

extension AnchorPointPackage {
    enum CodingKeys: String, CodingKey {
        case id, mapPointID, mapCoordinates, anchorPosition, anchorSessionTransform
        case captureDate, spatialData, referenceImages, visualDescription
        case floorMarker, floorMarkerToAnchorOffset, contextCaptures, proximityBeacons
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        mapPointID = try container.decode(UUID.self, forKey: .mapPointID)
        
        let coordArray = try container.decode([CGFloat].self, forKey: .mapCoordinates)
        mapCoordinates = CGPoint(x: coordArray[0], y: coordArray[1])
        
        let posArray = try container.decode([Float].self, forKey: .anchorPosition)
        anchorPosition = simd_float3(posArray[0], posArray[1], posArray[2])
        
        if let transformArray = try container.decodeIfPresent([Float].self, forKey: .anchorSessionTransform), transformArray.count == 16 {
            anchorSessionTransform = simd_float4x4(
                simd_float4(transformArray[0], transformArray[1], transformArray[2], transformArray[3]),
                simd_float4(transformArray[4], transformArray[5], transformArray[6], transformArray[7]),
                simd_float4(transformArray[8], transformArray[9], transformArray[10], transformArray[11]),
                simd_float4(transformArray[12], transformArray[13], transformArray[14], transformArray[15])
            )
        } else {
            anchorSessionTransform = matrix_identity_float4x4
        }
        
        captureDate = try container.decode(Date.self, forKey: .captureDate)
        spatialData = try container.decode(AnchorSpatialData.self, forKey: .spatialData)
        referenceImages = try container.decode([AnchorReferenceImage].self, forKey: .referenceImages)
        visualDescription = try container.decodeIfPresent(String.self, forKey: .visualDescription)
        floorMarker = try container.decodeIfPresent(FloorMarkerCapture.self, forKey: .floorMarker)
        if let offsetArray = try container.decodeIfPresent([Float].self, forKey: .floorMarkerToAnchorOffset),
           offsetArray.count == 3 {
            floorMarkerToAnchorOffset = simd_float3(offsetArray[0], offsetArray[1], offsetArray[2])
        } else {
            floorMarkerToAnchorOffset = nil
        }
        contextCaptures = try container.decodeIfPresent([WideAngleCapture].self, forKey: .contextCaptures) ?? []
        proximityBeacons = try container.decodeIfPresent([BeaconReference].self, forKey: .proximityBeacons) ?? []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(mapPointID, forKey: .mapPointID)
        try container.encode([mapCoordinates.x, mapCoordinates.y], forKey: .mapCoordinates)
        try container.encode([anchorPosition.x, anchorPosition.y, anchorPosition.z], forKey: .anchorPosition)
        let transformArray: [Float] = [
            anchorSessionTransform.columns.0.x, anchorSessionTransform.columns.0.y, anchorSessionTransform.columns.0.z, anchorSessionTransform.columns.0.w,
            anchorSessionTransform.columns.1.x, anchorSessionTransform.columns.1.y, anchorSessionTransform.columns.1.z, anchorSessionTransform.columns.1.w,
            anchorSessionTransform.columns.2.x, anchorSessionTransform.columns.2.y, anchorSessionTransform.columns.2.z, anchorSessionTransform.columns.2.w,
            anchorSessionTransform.columns.3.x, anchorSessionTransform.columns.3.y, anchorSessionTransform.columns.3.z, anchorSessionTransform.columns.3.w
        ]
        try container.encode(transformArray, forKey: .anchorSessionTransform)
        try container.encode(captureDate, forKey: .captureDate)
        try container.encode(spatialData, forKey: .spatialData)
        try container.encode(referenceImages, forKey: .referenceImages)
        try container.encodeIfPresent(visualDescription, forKey: .visualDescription)
        try container.encodeIfPresent(floorMarker, forKey: .floorMarker)
        if let offset = floorMarkerToAnchorOffset {
            try container.encode([offset.x, offset.y, offset.z], forKey: .floorMarkerToAnchorOffset)
        }
        if !contextCaptures.isEmpty {
            try container.encode(contextCaptures, forKey: .contextCaptures)
        }
        if !proximityBeacons.isEmpty {
            try container.encode(proximityBeacons, forKey: .proximityBeacons)
        }
    }
}

extension AnchorFeatureCloud {
    enum CodingKeys: String, CodingKey {
        case points, anchorPosition, captureRadius
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let pointArrays = try container.decode([[Float]].self, forKey: .points)
        points = pointArrays.map { simd_float3($0[0], $0[1], $0[2]) }
        
        let posArray = try container.decode([Float].self, forKey: .anchorPosition)
        anchorPosition = simd_float3(posArray[0], posArray[1], posArray[2])
        
        captureRadius = try container.decode(Float.self, forKey: .captureRadius)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let pointArrays = points.map { [$0.x, $0.y, $0.z] }
        try container.encode(pointArrays, forKey: .points)
        try container.encode([anchorPosition.x, anchorPosition.y, anchorPosition.z], forKey: .anchorPosition)
        try container.encode(captureRadius, forKey: .captureRadius)
    }
}

extension AnchorPlaneData {
    enum CodingKeys: String, CodingKey {
        case planeID, transform, extent, alignment
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        planeID = try container.decode(UUID.self, forKey: .planeID)
        
        let transformArray = try container.decode([Float].self, forKey: .transform)
        transform = simd_float4x4(
            simd_float4(transformArray[0], transformArray[1], transformArray[2], transformArray[3]),
            simd_float4(transformArray[4], transformArray[5], transformArray[6], transformArray[7]),
            simd_float4(transformArray[8], transformArray[9], transformArray[10], transformArray[11]),
            simd_float4(transformArray[12], transformArray[13], transformArray[14], transformArray[15])
        )
        
        extent = try container.decode(PlaneExtent.self, forKey: .extent)
        alignment = try container.decode(PlaneAlignment.self, forKey: .alignment)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(planeID, forKey: .planeID)
        
        let transformArray: [Float] = [
            transform.columns.0.x, transform.columns.0.y, transform.columns.0.z, transform.columns.0.w,
            transform.columns.1.x, transform.columns.1.y, transform.columns.1.z, transform.columns.1.w,
            transform.columns.2.x, transform.columns.2.y, transform.columns.2.z, transform.columns.2.w,
            transform.columns.3.x, transform.columns.3.y, transform.columns.3.z, transform.columns.3.w
        ]
        try container.encode(transformArray, forKey: .transform)
        try container.encode(extent, forKey: .extent)
        try container.encode(alignment, forKey: .alignment)
    }
}
