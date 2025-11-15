//
//  RelocalizationCoordinator.swift
//  TapResolver
//
//  Coordinates relocalization attempts using plug-and-play strategies
//

import Foundation
import ARKit
import Combine

/// Coordinates relocalization attempts using multiple strategies
final class RelocalizationCoordinator: ObservableObject {
    @Published public var availableStrategies: [RelocalizationStrategy] = []
    @Published public var selectedStrategyID: String?
    @Published public var selectedStrategyName: String = "ARWorldMap"  // For picker binding
    @Published public var lastResult: RelocalizationResult?
    @Published public var isRelocalizing: Bool = false
    
    private var arStore: ARWorldMapStore
    
    public init(arStore: ARWorldMapStore) {
        self.arStore = arStore
        
        // Register available strategies
        registerStrategies()
    }
    
    /// Update the AR store reference (useful when stores are initialized after coordinator)
    public func updateARStore(_ newStore: ARWorldMapStore) {
        self.arStore = newStore
        // Re-register strategies with new store
        registerStrategies()
    }
    
    /// Register all available relocalization strategies
    private func registerStrategies() {
        availableStrategies = [
            WorldMapRelocalizer(arStore: arStore),
            DummyRelocalizer()
            // Future strategies can be added here:
            // ImageAnchorRelocalizer(arStore: arStore),
            // MeshRelocalizer(arStore: arStore),
            // ManualRelocalizer(arStore: arStore)
        ]
        
        // Default to first strategy
        if let firstStrategy = availableStrategies.first {
            selectedStrategyID = firstStrategy.id
            selectedStrategyName = firstStrategy.displayName
        }
    }
    
    /// Get the currently selected strategy
    public var selectedStrategy: RelocalizationStrategy? {
        guard let strategyID = selectedStrategyID else { return nil }
        return availableStrategies.first { $0.id == strategyID }
    }
    
    /// Attempt relocalization for a triangle using the selected strategy
    /// - Parameters:
    ///   - triangle: The triangle to relocalize for
    ///   - session: The AR session to apply relocalization to
    ///   - completion: Optional callback with the result
    func attemptRelocalization(
        for triangle: TrianglePatch,
        session: ARSession,
        completion: ((RelocalizationResult) -> Void)? = nil
    ) {
        guard let strategy = selectedStrategy else {
            let result = RelocalizationResult(
                success: false,
                confidence: 0.0,
                notes: "No strategy selected",
                strategyID: "none"
            )
            DispatchQueue.main.async {
                self.lastResult = result
                completion?(result)
            }
            return
        }
        
        isRelocalizing = true
        
        strategy.attemptRelocalization(for: triangle, session: session) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isRelocalizing = false
                self.lastResult = result
                completion?(result)
            }
        }
    }
    
    /// Attempt relocalization using a specific strategy
    /// - Parameters:
    ///   - triangle: The triangle to relocalize for
    ///   - session: The AR session to apply relocalization to
    ///   - strategyID: The ID of the strategy to use
    ///   - completion: Optional callback with the result
    func attemptRelocalization(
        for triangle: TrianglePatch,
        session: ARSession,
        strategyID: String,
        completion: ((RelocalizationResult) -> Void)? = nil
    ) {
        guard let strategy = availableStrategies.first(where: { $0.id == strategyID }) else {
            let result = RelocalizationResult(
                success: false,
                confidence: 0.0,
                notes: "Strategy '\(strategyID)' not found",
                strategyID: strategyID
            )
            DispatchQueue.main.async {
                self.lastResult = result
                completion?(result)
            }
            return
        }
        
        isRelocalizing = true
        
        strategy.attemptRelocalization(for: triangle, session: session) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isRelocalizing = false
                self.lastResult = result
                completion?(result)
            }
        }
    }
}

