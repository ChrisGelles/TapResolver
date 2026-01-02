//
//  Zone.swift
//  TapResolver
//
//  A calibration zone defined by 4 corner MapPoints forming a quadrilateral.
//  Zones own their corner references and track which triangles have area inside.
//

import Foundation

/// A calibration zone defined by four corner MapPoints.
/// Corners are stored in counter-clockwise order as selected by the user.
public struct Zone: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var cornerIDs: [UUID]              // 4 MapPoint IDs in CCW order
    public var triangleIDs: [UUID]            // Triangles with any area inside zone
    public var lastStartingCornerIndex: Int?  // For rotation feature (0-3), nil if never calibrated
    public var isLocked: Bool                  // Prevents deletion when true
    public var createdAt: Date
    public var modifiedAt: Date
    
    /// Zone is valid if it has exactly 4 corners
    public var isValid: Bool {
        cornerIDs.count == 4
    }
    
    /// Initialize a new zone with corner MapPoints
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - name: Display name for the zone
    ///   - cornerIDs: Array of 4 MapPoint UUIDs in CCW order
    ///   - triangleIDs: Array of triangle UUIDs with area inside zone (defaults to empty)
    public init(
        id: UUID = UUID(),
        name: String,
        cornerIDs: [UUID],
        triangleIDs: [UUID] = [],
        lastStartingCornerIndex: Int? = nil,
        isLocked: Bool = false,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.cornerIDs = cornerIDs
        self.triangleIDs = triangleIDs
        self.lastStartingCornerIndex = lastStartingCornerIndex
        self.isLocked = isLocked
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

