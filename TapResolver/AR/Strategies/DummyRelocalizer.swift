//
//  DummyRelocalizer.swift
//  TapResolver
//
//  Dummy strategy for testing and placeholder purposes
//

import Foundation
import ARKit

/// Dummy relocalization strategy for testing
final class DummyRelocalizer: RelocalizationStrategy {
    let id: String = "dummy"
    let displayName: String = "Dummy Strategy"
    
    func attemptRelocalization(
        for triangle: TrianglePatch,
        session: ARSession,
        completion: @escaping (RelocalizationResult) -> Void
    ) {
        print("🧪 Dummy strategy used for triangle \(String(triangle.id.uuidString.prefix(8)))")
        
        // Simulate a delay to mimic real relocalization
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let result = RelocalizationResult(
                success: false,
                confidence: 0.0,
                notes: "Dummy strategy - no actual relocalization performed",
                strategyID: self.id
            )
            completion(result)
        }
    }
}

