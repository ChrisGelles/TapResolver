//
//  ZoneDTO.swift
//  TapResolver
//
//  Data Transfer Object for Zone persistence via UserDefaults.
//

import Foundation

/// DTO for persisting Zone to UserDefaults
public struct ZoneDTO: Codable {
    public let id: String
    public var displayName: String
    public var cornerMapPointIDs: [String]
    public var groupID: String?
    public var memberTriangleIDs: [String]
    public var lastStartingCornerIndex: Int?
    public var isLocked: Bool
    public var createdAt: Date
    public var modifiedAt: Date
    
    /// Convert Zone model to DTO for persistence
    public init(from zone: Zone) {
        self.id = zone.id
        self.displayName = zone.displayName
        self.cornerMapPointIDs = zone.cornerMapPointIDs
        self.groupID = zone.groupID
        self.memberTriangleIDs = zone.memberTriangleIDs
        self.lastStartingCornerIndex = zone.lastStartingCornerIndex
        self.isLocked = zone.isLocked
        self.createdAt = zone.createdAt
        self.modifiedAt = zone.modifiedAt
    }
    
    /// Convert DTO back to Zone model
    public func toZone() -> Zone {
        Zone(
            id: id,
            displayName: displayName,
            cornerMapPointIDs: cornerMapPointIDs,
            groupID: groupID,
            memberTriangleIDs: memberTriangleIDs,
            lastStartingCornerIndex: lastStartingCornerIndex,
            isLocked: isLocked,
            createdAt: createdAt,
            modifiedAt: modifiedAt
        )
    }
}
