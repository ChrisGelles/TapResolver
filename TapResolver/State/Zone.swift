//
//  Zone.swift
//  TapResolver
//
//  A calibration zone defined by exactly 4 corner MapPoints.
//  Corners are stored in counter-clockwise order for bilinear interpolation.
//

import Foundation
import CoreGraphics

/// A calibration zone defined by 4 corner MapPoints.
/// Corners are stored in counter-clockwise order as selected by the user.
/// The 4-corner constraint is required for bilinear corner-pin interpolation.
public struct Zone: Identifiable, Codable, Equatable {
    /// Unique identifier (human-readable string or UUID string)
    public let id: String
    
    /// Display name for the zone (e.g., "Dunk Theater")
    public var displayName: String
    
    /// 4 MapPoint IDs in CCW order for bilinear interpolation
    public var cornerMapPointIDs: [String]
    
    /// Group membership (nil if ungrouped)
    public var groupID: String?
    
    /// Triangles with any area inside zone
    public var memberTriangleIDs: [String]
    
    /// For rotation feature (0-3), nil if never calibrated
    public var lastStartingCornerIndex: Int?
    
    /// Prevents deletion when true
    public var isLocked: Bool
    
    /// IDs of zones whose boundaries overlap with this zone (computed, not persisted)
    public var neighborZoneIDs: [String] = []
    
    public var createdAt: Date
    public var modifiedAt: Date
    
    /// Zone is valid if it has exactly 4 corners (required for bilinear interpolation)
    public var isValid: Bool {
        cornerMapPointIDs.count == 4
    }
    
    /// Initialize a new zone with corner MapPoints
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID string)
    ///   - displayName: Display name for the zone
    ///   - cornerMapPointIDs: Array of 4 MapPoint ID strings in CCW order
    ///   - groupID: Optional group membership
    ///   - memberTriangleIDs: Array of triangle ID strings (defaults to empty)
    public init(
        id: String = UUID().uuidString,
        displayName: String,
        cornerMapPointIDs: [String],
        groupID: String? = nil,
        memberTriangleIDs: [String] = [],
        lastStartingCornerIndex: Int? = nil,
        isLocked: Bool = false,
        neighborZoneIDs: [String] = [],
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.displayName = displayName
        self.cornerMapPointIDs = cornerMapPointIDs
        self.groupID = groupID
        self.memberTriangleIDs = memberTriangleIDs
        self.lastStartingCornerIndex = lastStartingCornerIndex
        self.isLocked = isLocked
        self.neighborZoneIDs = neighborZoneIDs
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
    
    /// Legacy convenience: name property for backward compatibility
    public var name: String {
        get { displayName }
        set { displayName = newValue }
    }
}
