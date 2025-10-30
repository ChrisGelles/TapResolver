//
//  WorldMapPatch.swift
//  TapResolver
//
//  Role: Represents a section of AR world map with overlapping coverage
//

import Foundation
import simd

public struct WorldMapPatch: Identifiable, Codable {
    public let id: UUID
    public var name: String                           // "Entrance Hall - West"
    public let createdDate: Date
    public var lastExtendedDate: Date?
    
    // File reference
    public var worldMapFilename: String               // "patch_{UUID}.ardata"
    
    // Spatial linkage
    public var anchorAreaInstanceIDs: [UUID]          // AnchorAreaInstances in this patch
    public var adjacentPatchIDs: [UUID]               // Neighboring patches (via shared anchors)
    
    // Metadata
    public var featurePointCount: Int
    public var planeCount: Int
    public var areaCoveredDescription: String
    public var scanDuration_s: Double
    
    // Version tracking
    public var version: Int
    public var fileSize_mb: Double
    
    public init(id: UUID = UUID(),
         name: String,
         worldMapFilename: String,
         featurePointCount: Int = 0,
         planeCount: Int = 0,
         areaCoveredDescription: String = "",
         scanDuration_s: Double = 0.0) {
        self.id = id
        self.name = name
        self.createdDate = Date()
        self.lastExtendedDate = nil
        self.worldMapFilename = worldMapFilename
        self.anchorAreaInstanceIDs = []
        self.adjacentPatchIDs = []
        self.featurePointCount = featurePointCount
        self.planeCount = planeCount
        self.areaCoveredDescription = areaCoveredDescription
        self.scanDuration_s = scanDuration_s
        self.version = 1
        self.fileSize_mb = 0.0
    }
}

