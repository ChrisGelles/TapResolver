//
//  RelocalizationStrategy.swift
//  TapResolver
//
//  Protocol-driven architecture for plug-and-play relocalization strategies
//

import Foundation
import ARKit

/// Result of a relocalization attempt
public struct RelocalizationResult {
    public let success: Bool
    public let confidence: Float  // 0.0-1.0 scale
    public let notes: String?
    public let strategyID: String
    public let attemptedAt: Date
    public let usedWorldMapFilename: String?  // Filename of the world map used (if applicable)
    
    public init(
        success: Bool,
        confidence: Float,
        notes: String? = nil,
        strategyID: String,
        attemptedAt: Date = Date(),
        usedWorldMapFilename: String? = nil
    ) {
        self.success = success
        self.confidence = max(0.0, min(1.0, confidence))  // Clamp to 0.0-1.0
        self.notes = notes
        self.strategyID = strategyID
        self.attemptedAt = attemptedAt
        self.usedWorldMapFilename = usedWorldMapFilename
    }
}

/// Protocol for relocalization strategies
protocol RelocalizationStrategy {
    /// Unique identifier for this strategy
    var id: String { get }
    
    /// Human-readable display name
    var displayName: String { get }
    
    /// Attempt to relocalize using this strategy
    /// - Parameters:
    ///   - triangle: The triangle patch to relocalize for
    ///   - session: The AR session to apply relocalization to
    ///   - completion: Callback with the result
    func attemptRelocalization(
        for triangle: TrianglePatch,
        session: ARSession,
        completion: @escaping (RelocalizationResult) -> Void
    )
}

// Note: TrianglePatch is internal, so implementations should be internal as well
// The protocol remains public for SwiftUI @StateObject support

