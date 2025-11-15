//
//  TrianglePatch.swift
//  TapResolver
//
//  Triangular calibration patch for piecewise map-to-AR transform
//

import Foundation
import CoreGraphics
import simd
import SwiftUI

// MARK: - Triangle Leg Measurement

struct TriangleLegMeasurement: Codable {
    let vertexA: UUID
    let vertexB: UUID
    let mapDistance: Float     // meters, 2D map distance
    let arDistance: Float      // meters, 3D AR distance
    
    var distortionRatio: Float {
        mapDistance == 0 ? 0 : arDistance / mapDistance
    }
}

struct TrianglePatch: Codable, Identifiable {
    let id: UUID
    let vertexIDs: [UUID]  // Exactly 3 MapPoint IDs (must have triangle-edge role)
    var isCalibrated: Bool
    var calibrationQuality: Float  // 0.0 (red) to 1.0 (green)
    var transform: Similarity2D?  // Map → AR floor plane transform (nil until calibrated)
    let createdAt: Date
    var lastCalibratedAt: Date?
    var arMarkerIDs: [String] = []  // AR marker IDs for the 3 vertices (matches order of vertexIDs)
    var userPositionWhenCalibrated: simd_float3?  // User's AR position when final marker placed
    var legMeasurements: [TriangleLegMeasurement] = []  // Leg distance measurements for quality computation
    var worldMapFilename: String?  // Legacy: Filename of saved ARWorldMap patch (deprecated - use worldMapFilesByStrategy)
    var worldMapFilesByStrategy: [String: String] = [:]  // [strategyName: filename] - Multiple world maps per strategy
    
    init(vertexIDs: [UUID]) {
        self.id = UUID()
        self.vertexIDs = vertexIDs
        self.isCalibrated = false
        self.calibrationQuality = 0.0
        self.transform = nil
        self.createdAt = Date()
        self.lastCalibratedAt = nil
    }
    
    /// Returns vertices in consistent order (sorted by ID for deterministic rendering)
    var sortedVertexIDs: [UUID] {
        vertexIDs.sorted { $0.uuidString < $1.uuidString }
    }
    
    /// Color based on calibration status
    var statusColor: Color {
        if !isCalibrated {
            return .gray
        } else if calibrationQuality >= 0.8 {
            return .green
        } else if calibrationQuality >= 0.5 {
            return .yellow
        } else {
            return .orange
        }
    }
}

// MARK: - Custom Codable Support for Backward Compatibility
extension TrianglePatch {
    enum CodingKeys: String, CodingKey {
        case id, vertexIDs, arMarkerIDs, calibrationQuality, isCalibrated, createdAt, lastCalibratedAt
        case transform, userPositionWhenCalibrated, legMeasurements, worldMapFilename, worldMapFilesByStrategy
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        vertexIDs = try container.decode([UUID].self, forKey: .vertexIDs)
        arMarkerIDs = try container.decodeIfPresent([String].self, forKey: .arMarkerIDs) ?? []
        calibrationQuality = try container.decodeIfPresent(Float.self, forKey: .calibrationQuality) ?? 0.0
        isCalibrated = try container.decode(Bool.self, forKey: .isCalibrated)
        transform = try container.decodeIfPresent(Similarity2D.self, forKey: .transform)
        
        // Backward compatibility for lastCalibratedAt: accept ISO8601 String or Unix timestamp
        if container.contains(.lastCalibratedAt) {
            if let dateString = try? container.decode(String.self, forKey: .lastCalibratedAt),
               let date = ISO8601DateFormatter().date(from: dateString) {
                lastCalibratedAt = date
            } else if let timestamp = try? container.decode(Double.self, forKey: .lastCalibratedAt) {
                lastCalibratedAt = Date(timeIntervalSince1970: timestamp)
            } else if let timeInterval = try? container.decode(TimeInterval.self, forKey: .lastCalibratedAt) {
                lastCalibratedAt = Date(timeIntervalSince1970: timeInterval)
            } else {
                lastCalibratedAt = nil
            }
        } else {
            lastCalibratedAt = nil
        }
        
        // Decode userPositionWhenCalibrated (simd_float3 as array)
        if let posArray = try? container.decode([Float].self, forKey: .userPositionWhenCalibrated),
           posArray.count == 3 {
            userPositionWhenCalibrated = simd_float3(posArray[0], posArray[1], posArray[2])
        } else {
            userPositionWhenCalibrated = nil
        }
        
        // Decode legMeasurements (optional for backward compatibility)
        legMeasurements = try container.decodeIfPresent([TriangleLegMeasurement].self, forKey: .legMeasurements) ?? []
        
        // Decode worldMapFilename (optional for backward compatibility)
        worldMapFilename = try container.decodeIfPresent(String.self, forKey: .worldMapFilename)
        
        // Decode worldMapFilesByStrategy (optional for backward compatibility)
        worldMapFilesByStrategy = try container.decodeIfPresent([String: String].self, forKey: .worldMapFilesByStrategy) ?? [:]
        
        // Backward compatibility: accept both ISO8601 String or Unix timestamp (Double) for createdAt
        if let dateString = try? container.decode(String.self, forKey: .createdAt),
           let date = ISO8601DateFormatter().date(from: dateString) {
            createdAt = date
        } else if let timestamp = try? container.decode(Double.self, forKey: .createdAt) {
            createdAt = Date(timeIntervalSince1970: timestamp)
        } else {
            // Fallback: try as TimeInterval (Float/Double) if Double failed
            if let timeInterval = try? container.decode(TimeInterval.self, forKey: .createdAt) {
                createdAt = Date(timeIntervalSince1970: timeInterval)
            } else {
                throw DecodingError.dataCorruptedError(
                    forKey: .createdAt,
                    in: container,
                    debugDescription: "Expected ISO8601 string or timestamp number for createdAt"
                )
            }
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(vertexIDs, forKey: .vertexIDs)
        try container.encode(arMarkerIDs, forKey: .arMarkerIDs)
        try container.encode(calibrationQuality, forKey: .calibrationQuality)
        try container.encode(isCalibrated, forKey: .isCalibrated)
        try container.encodeIfPresent(transform, forKey: .transform)
        try container.encodeIfPresent(lastCalibratedAt, forKey: .lastCalibratedAt)
        
        // Encode createdAt as ISO8601 string (new format)
        let formatter = ISO8601DateFormatter()
        try container.encode(formatter.string(from: createdAt), forKey: .createdAt)
        
        // Encode userPositionWhenCalibrated as array
        if let pos = userPositionWhenCalibrated {
            try container.encode([pos.x, pos.y, pos.z], forKey: .userPositionWhenCalibrated)
        }
        
        // Encode legMeasurements
        try container.encode(legMeasurements, forKey: .legMeasurements)
        
        // Encode worldMapFilename (legacy)
        try container.encodeIfPresent(worldMapFilename, forKey: .worldMapFilename)
        
        // Encode worldMapFilesByStrategy
        if !worldMapFilesByStrategy.isEmpty {
            try container.encode(worldMapFilesByStrategy, forKey: .worldMapFilesByStrategy)
        }
    }
}

// MARK: - Similarity2D Transform (placeholder for future implementation)
struct Similarity2D: Codable {
    var rotation: simd_float2x2  // Rotation matrix
    var scale: Float  // Uniform scale
    var translation: simd_float2  // Translation vector
    
    init(rotation: simd_float2x2 = matrix_identity_float2x2, 
         scale: Float = 1.0, 
         translation: simd_float2 = simd_float2(0, 0)) {
        self.rotation = rotation
        self.scale = scale
        self.translation = translation
    }
}

// MARK: - Codable Support for simd Types
extension Similarity2D {
    enum CodingKeys: String, CodingKey {
        case rotation, scale, translation
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let rotArray = try container.decode([Float].self, forKey: .rotation)
        rotation = simd_float2x2(columns: (
            simd_float2(rotArray[0], rotArray[1]),
            simd_float2(rotArray[2], rotArray[3])
        ))
        
        scale = try container.decode(Float.self, forKey: .scale)
        
        let transArray = try container.decode([Float].self, forKey: .translation)
        translation = simd_float2(transArray[0], transArray[1])
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        let rotArray: [Float] = [
            rotation.columns.0.x, rotation.columns.0.y,
            rotation.columns.1.x, rotation.columns.1.y
        ]
        try container.encode(rotArray, forKey: .rotation)
        
        try container.encode(scale, forKey: .scale)
        
        let transArray: [Float] = [translation.x, translation.y]
        try container.encode(transArray, forKey: .translation)
    }
}

extension Color {
    // Helper for triangle colors
    static let triangleUncalibrated = Color.gray.opacity(0.15)
    static let triangleCalibrating = Color.blue.opacity(0.15)
    static let trianglePoor = Color.orange.opacity(0.15)
    static let triangleFair = Color.yellow.opacity(0.15)
    static let triangleGood = Color.green.opacity(0.15)
}

