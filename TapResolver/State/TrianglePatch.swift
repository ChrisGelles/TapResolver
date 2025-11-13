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

