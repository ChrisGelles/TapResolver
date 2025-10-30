//
//  AnchorFeature.swift
//  TapResolver
//
//  Role: Represents a semantic landmark (e.g., "Cat Painting", "Carpet Corner")
//        that can appear in multiple world map patches
//

import Foundation

public struct AnchorFeature: Identifiable, Codable {
    public let id: UUID
    public var name: String                           // "Cat Painting"
    public var semanticDescription: String            // "Large painting of orange tabby cat, gold frame"
    public var visualSnapshot: Data?                  // Photo for user reference
    public let createdDate: Date
    
    // All places where this feature appears across patches
    public var instanceIDs: [UUID]                    // AnchorAreaInstance IDs
    
    public init(id: UUID = UUID(),
         name: String,
         semanticDescription: String = "",
         visualSnapshot: Data? = nil) {
        self.id = id
        self.name = name
        self.semanticDescription = semanticDescription
        self.visualSnapshot = visualSnapshot
        self.createdDate = Date()
        self.instanceIDs = []
    }
}

