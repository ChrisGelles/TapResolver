//
//  ZoneGroup.swift
//  TapResolver
//
//  Organizational container for related zones (e.g., "Evolving Life" exhibit).
//

import Foundation
import SwiftUI

/// Organizational container for related zones
/// Example: "Evolving Life" group contains 10 zones
public struct ZoneGroup: Codable, Identifiable, Equatable {
    /// Unique identifier (human-readable, e.g., "evolvingLife-zones")
    public let id: String
    
    /// Display name (e.g., "Evolving Life Zones")
    public var displayName: String
    
    /// Hex color string (e.g., "#3154ff")
    public var colorHex: String
    
    /// Ordered list of zone IDs in this group
    public var zoneIDs: [String]
    
    public var createdAt: Date
    public var modifiedAt: Date
    
    public init(
        id: String,
        displayName: String,
        colorHex: String = "#808080",
        zoneIDs: [String] = [],
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.displayName = displayName
        self.colorHex = colorHex
        self.zoneIDs = zoneIDs
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
    
    /// SwiftUI Color from hex string
    public var color: Color {
        Color(hex: colorHex) ?? .gray
    }
}
