//
//  AnimatedRandomNumber.swift
//  TapResolver
//
//  Created by restructuring on 9/23/25.
//

import SwiftUI
import Combine

// MARK: - Animated Random Number Generator
@MainActor
final class AnimatedRandomNumber: ObservableObject {
    @Published var value: Float = 0.0
    
    private let minValue: Float
    private let maxValue: Float
    private let updateInterval: TimeInterval
    private let animationDuration: TimeInterval
    
    private var updateTimer: Timer?
    private var animationTimer: Timer?
    private var currentTarget: Float = 0.0
    private var animationStartValue: Float = 0.0
    private var animationStartTime: Date = Date()
    
    init(min: Float, max: Float, updateInterval: TimeInterval, animationDuration: TimeInterval) {
        self.minValue = min
        self.maxValue = max
        self.updateInterval = Swift.max(updateInterval, 0.01) // Minimum 10ms
        self.animationDuration = Swift.min(animationDuration, updateInterval) // Cap at update interval
        
        // Initialize with random value
        self.value = Float.random(in: min...max)
        self.currentTarget = self.value
        
        startUpdateTimer()
    }
    
    deinit {
        Task { @MainActor in
            stopTimers()
        }
    }
    
    // MARK: - Public Interface
    
    func start() {
        startUpdateTimer()
    }
    
    func stop() {
        stopTimers()
    }
    
    func reset() {
        stopTimers()
        value = Float.random(in: minValue...maxValue)
        currentTarget = value
        startUpdateTimer()
    }
    
    // MARK: - Private Methods
    
    private func startUpdateTimer() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.generateNewTarget()
            }
        }
    }
    
    private func stopTimers() {
        updateTimer?.invalidate()
        updateTimer = nil
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    private func generateNewTarget() {
        let newTarget = Float.random(in: minValue...maxValue)
        animateToValue(newTarget)
    }
    
    private func animateToValue(_ target: Float) {
        currentTarget = target
        animationStartValue = value
        animationStartTime = Date()
        
        // If animation duration is very small, just set the value immediately
        if animationDuration < 0.01 {
            value = target
            return
        }
        
        // Start animation timer
        animationTimer?.invalidate()
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1/60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateAnimation()
            }
        }
    }
    
    private func updateAnimation() {
        let elapsed = Date().timeIntervalSince(animationStartTime)
        let progress = min(elapsed / animationDuration, 1.0)
        
        // Use ease-out curve for smooth animation
        let easedProgress = 1.0 - pow(1.0 - progress, 3.0)
        
        value = animationStartValue + (currentTarget - animationStartValue) * Float(easedProgress)
        
        // Stop animation when complete
        if progress >= 1.0 {
            animationTimer?.invalidate()
            animationTimer = nil
            value = currentTarget
        }
    }
}

// MARK: - Convenience Function
@MainActor
func variedNumber(_ min: Float, _ max: Float, _ updateInterval: TimeInterval, _ animationDuration: TimeInterval) -> AnimatedRandomNumber {
    return AnimatedRandomNumber(min: min, max: max, updateInterval: updateInterval, animationDuration: animationDuration)
}
