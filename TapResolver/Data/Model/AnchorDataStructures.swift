//
//  AnchorDataStructures.swift
//  TapResolver
//
//  Created by GPT-5 Codex on 11/8/25.
//

import Foundation
import CoreGraphics
import simd

// MARK: - Milestone 4: Floor Marker Precision

/// Captures the floor marker image with user-calibrated coordinates
struct FloorMarkerCapture: Codable {
    let imageData: Data
    let markerCoordinates: CGPoint       // Normalized (0.0-1.0, 0.0-1.0)
    let imageSize: CGSize                // Original dimensions for reference
    let captureTimestamp: Date
    
    init(imageData: Data, markerCoordinates: CGPoint, imageSize: CGSize) {
        self.imageData = imageData
        self.markerCoordinates = markerCoordinates
        self.imageSize = imageSize
        self.captureTimestamp = Date()
    }
}

// MARK: - Milestone 5: Wide-Angle Context (PLACEHOLDER)

/// FUTURE: Wide-angle context images for area recognition
/// Will be implemented in Milestone 5 as optional enhancement
struct WideAngleCapture: Codable {
    let imageData: Data
    let cameraPosition: simd_float3      // Relative to anchor
    let cameraOrientation: simd_quatf
    let distanceFromAnchor: Float
    let captureTimestamp: Date
    
    // NOTE: Not implementing capture UI yet - placeholder only
}

// MARK: - Milestone 7: RSSI Beacon Integration (PLACEHOLDER)

/// FUTURE: Bluetooth beacon references for proximity filtering
/// Will be implemented in Milestone 7 in next project phase
struct BeaconReference: Codable {
    let beaconID: String
    let expectedRSSI: Int
    let proximityZone: String            // e.g., "South Gallery"
    
    // NOTE: Not implementing beacon scanning yet - placeholder only
}

// MARK: - Codable Support for simd types

extension simd_float3: Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let x = try container.decode(Float.self)
        let y = try container.decode(Float.self)
        let z = try container.decode(Float.self)
        self.init(x, y, z)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(x)
        try container.encode(y)
        try container.encode(z)
    }
}

extension simd_quatf: Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let x = try container.decode(Float.self)
        let y = try container.decode(Float.self)
        let z = try container.decode(Float.self)
        let w = try container.decode(Float.self)
        self.init(ix: x, iy: y, iz: z, r: w)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(imag.x)
        try container.encode(imag.y)
        try container.encode(imag.z)
        try container.encode(real)
    }
}

