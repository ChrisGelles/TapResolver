//
//  MapTransformStore.swift
//  TapResolver
//
//  Rebuilt for centroid-pivot gesture support.
//

import SwiftUI
import CoreGraphics

/// Single source of truth for map transform state and coordinate conversions.
/// Acts as the "transform brain" — analogous to an After Effects null/controller layer.
final class MapTransformStore: ObservableObject {
    
    // MARK: - Published transform state (consumed by SwiftUI)
    
    @Published var totalScale: CGFloat = 1.0
    @Published var totalRotationRadians: CGFloat = 0.0
    @Published var totalOffset: CGSize = .zero  // pan in screen points
    
    // MARK: - Geometry configuration
    
    /// Size of the map image in map-local units (typically image pixels/points).
    @Published private(set) var mapSize: CGSize = .zero
    
    /// Visual center of the screen in screen coordinates.
    @Published private(set) var screenCenter: CGPoint = .zero
    
    // MARK: - Gesture session state
    
    /// Indicates whether a pinch/rotate gesture is active.
    /// Overlays should check this and skip their own drag handling while true.
    @Published var isPinching: Bool = false
    
    /// Indicates whether an overlay element (dot, point, square) is being dragged.
    /// The bridge should skip map pan while this is true.
    @Published var isOverlayDragging: Bool = false
    
    /// Indicates whether a HUD drawer is being interacted with (scrolling, etc).
    /// The bridge should skip map pan while this is true.
    @Published var isHUDInteracting: Bool = false
    
    // Pan session
    private var panInitialOffset: CGSize = .zero
    
    // Pinch/rotate session
    private var pinchInitialScale: CGFloat = 1.0
    private var pinchInitialRotation: CGFloat = 0.0
    private var pinchInitialOffset: CGSize = .zero
    private var pinchAnchorMapPoint: CGPoint = .zero
    
    // MARK: - Scale limits
    
    let minScale: CGFloat = 0.1
    let maxScale: CGFloat = 10.0
    
    // MARK: - Configuration Methods
    
    /// Set the map image size. Call this when loading a new map image.
    func setMapSize(_ size: CGSize) {
        mapSize = size
    }
    
    /// Set the screen center point. Call this on appear and when geometry changes.
    func setScreenCenter(_ point: CGPoint) {
        screenCenter = point
    }
    
    // MARK: - Derived Properties
    
    /// Center point of the map in map-local coordinates.
    private var mapCenter: CGPoint {
        CGPoint(x: mapSize.width / 2.0, y: mapSize.height / 2.0)
    }
    
    // MARK: - Coordinate Conversion
    
    /// Convert a point from map-local coordinates to screen coordinates.
    ///
    /// Transform order: scale around map center → rotate around map center → translate by screenCenter + offset
    func mapToScreen(_ mapPoint: CGPoint) -> CGPoint {
        let dx = mapPoint.x - mapCenter.x
        let dy = mapPoint.y - mapCenter.y
        
        let s = totalScale
        let θ = totalRotationRadians
        let cosθ = cos(θ)
        let sinθ = sin(θ)
        
        // Scale then rotate around map center
        let rx = s * (dx * cosθ - dy * sinθ)
        let ry = s * (dx * sinθ + dy * cosθ)
        
        return CGPoint(
            x: screenCenter.x + totalOffset.width + rx,
            y: screenCenter.y + totalOffset.height + ry
        )
    }
    
    /// Convert a point from screen coordinates to map-local coordinates.
    func screenToMap(_ screenPoint: CGPoint) -> CGPoint {
        let s = max(totalScale, 0.0001)  // Avoid division by zero
        let θ = totalRotationRadians
        let cosθ = cos(θ)
        let sinθ = sin(θ)
        
        // Remove screen center and pan offset
        let ux = screenPoint.x - screenCenter.x - totalOffset.width
        let uy = screenPoint.y - screenCenter.y - totalOffset.height
        
        // Unscale
        let uxPrime = ux / s
        let uyPrime = uy / s
        
        // Rotate by -θ (inverse rotation)
        let dx = cosθ * uxPrime + sinθ * uyPrime
        let dy = -sinθ * uxPrime + cosθ * uyPrime
        
        return CGPoint(
            x: mapCenter.x + dx,
            y: mapCenter.y + dy
        )
    }
    
    /// Convert a screen-space translation delta to a map-local translation delta.
    /// Used by overlays to convert drag gestures to map-space movement.
    func screenTranslationToMap(_ translation: CGSize) -> CGSize {
        let s = max(totalScale, 0.0001)
        let θ = totalRotationRadians
        let cosθ = cos(θ)
        let sinθ = sin(θ)
        
        let ux = translation.width
        let uy = translation.height
        
        // Unscale
        let uxPrime = ux / s
        let uyPrime = uy / s
        
        // Rotate by -θ (inverse rotation)
        let dx = cosθ * uxPrime + sinθ * uyPrime
        let dy = -sinθ * uxPrime + cosθ * uyPrime
        
        return CGSize(width: dx, height: dy)
    }
    
    // MARK: - Pan Gesture Session
    
    /// Call at the start of a pan gesture.
    func beginPan() {
        panInitialOffset = totalOffset
    }
    
    /// Call during pan gesture with the cumulative translation from gesture start.
    func updatePan(translation: CGSize) {
        totalOffset = CGSize(
            width: panInitialOffset.width + translation.width,
            height: panInitialOffset.height + translation.height
        )
    }
    
    /// Call when pan gesture ends.
    func endPan() {
        // Offset is already baked. No action needed.
        // Could add bounds clamping here if desired.
    }
    
    // MARK: - Pinch/Rotate Gesture Session
    
    /// Call at the start of a pinch/rotate gesture.
    /// - Parameter centroid: The screen-space point between the two fingers.
    func beginPinch(atCentroidScreen centroid: CGPoint) {
        pinchInitialScale = totalScale
        pinchInitialRotation = totalRotationRadians
        pinchInitialOffset = totalOffset
        
        // Capture the map-local point under the centroid — this is our "anchor point"
        pinchAnchorMapPoint = screenToMap(centroid)
        
        isPinching = true
    }
    
    /// Call during pinch/rotate gesture.
    /// - Parameters:
    ///   - pinchScale: Cumulative scale factor from gesture start (1.0 = no change).
    ///   - pinchRotation: Cumulative rotation in radians from gesture start (0.0 = no change).
    ///   - centroidScreen: Current screen-space position of the finger centroid.
    func updatePinch(pinchScale: CGFloat, pinchRotation: CGFloat, centroidScreen: CGPoint) {
        // 1. Apply new scale and rotation
        let newScale = min(max(pinchInitialScale * pinchScale, minScale), maxScale)
        let newRotation = pinchInitialRotation + pinchRotation
        
        totalScale = newScale
        totalRotationRadians = newRotation
        
        // 2. Compute where the anchor point would land with the initial offset
        totalOffset = pinchInitialOffset
        let projectedScreenPos = mapToScreen(pinchAnchorMapPoint)
        
        // 3. Adjust offset so the anchor point stays under the centroid
        let dx = centroidScreen.x - projectedScreenPos.x
        let dy = centroidScreen.y - projectedScreenPos.y
        
        totalOffset = CGSize(
            width: pinchInitialOffset.width + dx,
            height: pinchInitialOffset.height + dy
        )
    }
    
    /// Call when pinch/rotate gesture ends.
    func endPinch() {
        isPinching = false
        
        // Optionally normalize rotation to 0..<2π for tidiness
        // totalRotationRadians = totalRotationRadians.truncatingRemainder(dividingBy: 2 * .pi)
    }
    
    // MARK: - Convenience: Programmatic Zoom
    
    /// Zoom by a factor, centered on a specific screen point.
    /// Useful for double-tap zoom.
    /// - Parameters:
    ///   - factor: Scale multiplier (e.g., 1.5 to zoom in, 0.67 to zoom out).
    ///   - point: Screen-space point to zoom toward/away from.
    func zoom(by factor: CGFloat, aroundScreenPoint point: CGPoint) {
        beginPinch(atCentroidScreen: point)
        updatePinch(pinchScale: factor, pinchRotation: 0.0, centroidScreen: point)
        endPinch()
    }
    
    // MARK: - Reset
    
    /// Reset all transforms to default state.
    func resetTransform() {
        totalScale = 1.0
        totalRotationRadians = 0.0
        totalOffset = .zero
    }
    
    // MARK: - Compatibility Shims (for TransformProcessor bridge)
    
    // These methods exist to maintain compatibility with the old gesture system
    // during the transition. They will be removed in Milestone 6 (cleanup).
    
    /// Internal setter for map size (called by TransformProcessor).
    @MainActor
    internal func _setMapSize(_ size: CGSize) {
        setMapSize(size)
    }
    
    /// Internal setter for screen center (called by TransformProcessor).
    @MainActor
    internal func _setScreenCenter(_ point: CGPoint) {
        setScreenCenter(point)
    }
    
    /// Internal setter for transform totals (called by TransformProcessor).
    /// This allows the old GestureHandler → TransformProcessor pipeline to continue working
    /// until we fully transition to the new gesture session methods.
    @MainActor
    internal func _setTotals(scale: CGFloat, rotationRadians: Double, offset: CGSize) {
        // 🔍 DIAGNOSTIC: Check for problematic values and apply fallbacks
        var safeScale = scale
        var safeRotation = rotationRadians
        var safeOffset = offset
        var didApplyFallback = false
        
        // Scale fallback
        if !scale.isFinite || scale <= 0.001 || scale >= 100 {
            safeScale = totalScale  // Keep current value
            didApplyFallback = true
            print("⚠️ [TRANSFORM] Scale fallback: \(scale) → \(safeScale)")
        }
        
        // Rotation fallback (THIS IS THE NaN FIX)
        if !rotationRadians.isFinite {
            safeRotation = Double(totalRotationRadians)  // Keep current value
            didApplyFallback = true
            print("⚠️ [TRANSFORM] Rotation fallback: \(rotationRadians) → \(safeRotation)")
        }
        
        // Offset fallback
        if !offset.width.isFinite || !offset.height.isFinite ||
           abs(offset.width) >= 50000 || abs(offset.height) >= 50000 {
            safeOffset = totalOffset  // Keep current value
            didApplyFallback = true
            print("⚠️ [TRANSFORM] Offset fallback: (\(offset.width), \(offset.height)) → (\(safeOffset.width), \(safeOffset.height))")
        }
        
        // 🔍 DIAGNOSTIC: Log significant changes (only if no fallback applied)
        if !didApplyFallback {
            let scaleDelta = abs(safeScale - totalScale)
            let rotDelta = abs(CGFloat(safeRotation) - totalRotationRadians)
            let offsetDelta = hypot(safeOffset.width - totalOffset.width, safeOffset.height - totalOffset.height)
            
            if scaleDelta > 0.5 || rotDelta > 0.5 || offsetDelta > 200 {
                print("📐 [TRANSFORM] Large change:")
                print("   scale: \(String(format: "%.3f", totalScale)) → \(String(format: "%.3f", safeScale))")
                print("   rotation: \(String(format: "%.3f", totalRotationRadians)) → \(String(format: "%.3f", safeRotation))")
                print("   offset: (\(Int(totalOffset.width)), \(Int(totalOffset.height))) → (\(Int(safeOffset.width)), \(Int(safeOffset.height)))")
            }
        }
        
        // Apply the (possibly fallback) values
        // When isPinching, the bridge is driving scale/rotation — only accept offset from GestureHandler
        if isPinching {
            // Only update offset (pan) during pinch — bridge handles scale/rotation
            print("🚫 [_setTotals] isPinching=true — ignoring scale:\(String(format: "%.3f", safeScale)) rot:\(String(format: "%.3f", safeRotation)), keeping bridge values")
            totalOffset = safeOffset
        } else {
            totalScale = safeScale
            totalRotationRadians = CGFloat(safeRotation)
            totalOffset = safeOffset
        }
    }
    
    // MARK: - Programmatic Navigation (from old store)
    
    /// Centers the map on a specific point with optional animation.
    /// Used by features that need to programmatically pan to a location.
    @MainActor
    public func centerOnPoint(_ mapPoint: CGPoint, animated: Bool = true) {
        let Cmap = CGPoint(x: mapSize.width / 2, y: mapSize.height / 2)
        let v = CGPoint(x: mapPoint.x - Cmap.x, y: mapPoint.y - Cmap.y)
        
        let vScaled = CGPoint(x: v.x * totalScale, y: v.y * totalScale)
        
        let theta = totalRotationRadians
        let c = cos(theta), s = sin(theta)
        let vRot = CGPoint(
            x: c * vScaled.x - s * vScaled.y,
            y: s * vScaled.x + c * vScaled.y
        )
        
        let newOffset = CGSize(width: -vRot.x, height: -vRot.y)
        
        if animated {
            withAnimation(.easeInOut(duration: 0.5)) {
                totalOffset = newOffset
            }
        } else {
            totalOffset = newOffset
        }
        
        print("🎯 Centered map on point: (\(Int(mapPoint.x)), \(Int(mapPoint.y))) → offset: (\(Int(newOffset.width)), \(Int(newOffset.height)))")
    }
    
    // MARK: - Diagnostics
    
    /// Print current transform state for debugging.
    func printDiagnostics(label: String = "STATE") {
        print("🔍 [TRANSFORM \(label)]")
        print("   scale: \(String(format: "%.4f", totalScale))")
        print("   rotation: \(String(format: "%.4f", totalRotationRadians)) rad (\(String(format: "%.1f", totalRotationRadians * 180 / .pi))°)")
        print("   offset: (\(Int(totalOffset.width)), \(Int(totalOffset.height)))")
        print("   mapSize: \(Int(mapSize.width)) × \(Int(mapSize.height))")
        print("   screenCenter: (\(Int(screenCenter.x)), \(Int(screenCenter.y)))")
        print("   isPinching: \(isPinching)")
    }
    
    /// Check if current transform state is valid.
    var isTransformValid: Bool {
        totalScale.isFinite && totalScale > 0.001 && totalScale < 100 &&
        totalRotationRadians.isFinite &&
        totalOffset.width.isFinite && totalOffset.height.isFinite
    }
}
