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
    public var name: String
    public var cornerIDs: [String]
    public var triangleIDs: [String]
    public var lastStartingCornerIndex: Int?
    public var isLocked: Bool
    public var createdAt: Date
    public var modifiedAt: Date
    
    /// Convert Zone model to DTO for persistence
    public init(from zone: Zone) {
        self.id = zone.id.uuidString
        self.name = zone.name
        self.cornerIDs = zone.cornerIDs.map { $0.uuidString }
        self.triangleIDs = zone.triangleIDs.map { $0.uuidString }
        self.lastStartingCornerIndex = zone.lastStartingCornerIndex
        self.isLocked = zone.isLocked
        self.createdAt = zone.createdAt
        self.modifiedAt = zone.modifiedAt
    }
    
    /// Convert DTO back to Zone model
    /// Returns nil if UUID parsing fails
    public func toZone() -> Zone? {
        guard let zoneID = UUID(uuidString: id) else {
            print("⚠️ [ZoneDTO] Failed to parse zone ID: \(id)")
            return nil
        }
        
        let parsedCornerIDs = cornerIDs.compactMap { UUID(uuidString: $0) }
        let parsedTriangleIDs = triangleIDs.compactMap { UUID(uuidString: $0) }
        
        // Warn if any IDs failed to parse
        if parsedCornerIDs.count != cornerIDs.count {
            print("⚠️ [ZoneDTO] Some corner IDs failed to parse: expected \(cornerIDs.count), got \(parsedCornerIDs.count)")
        }
        if parsedTriangleIDs.count != triangleIDs.count {
            print("⚠️ [ZoneDTO] Some triangle IDs failed to parse: expected \(triangleIDs.count), got \(parsedTriangleIDs.count)")
        }
        
        return Zone(
            id: zoneID,
            name: name,
            cornerIDs: parsedCornerIDs,
            triangleIDs: parsedTriangleIDs,
            lastStartingCornerIndex: lastStartingCornerIndex,
            isLocked: isLocked,
            createdAt: createdAt,
            modifiedAt: modifiedAt
        )
    }
}

