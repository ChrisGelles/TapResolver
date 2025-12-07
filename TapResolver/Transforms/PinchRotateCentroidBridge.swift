//
//  PinchRotateCentroidBridge.swift
//  TapResolver
//
//  Window-level gesture recognizers for centroid-pivot pinch/rotate/pan.
//  Attaches to window so SwiftUI overlays can still receive taps.
//

import SwiftUI
import UIKit

/// Unified gesture bridge that reports pinch/rotate AND pan from UIKit.
/// Handles finger count transitions (2→1→2) seamlessly.
struct PinchRotateCentroidBridge: UIViewRepresentable {
    struct State {
        enum Phase { case began, changed, ended, cancelled }
        enum GestureMode { case pinchRotate, pan }
        
        var phase: Phase
        var gestureMode: GestureMode
        
        // Pinch/rotate data (valid when gestureMode == .pinchRotate)
        var scale: CGFloat
        var rotationRadians: CGFloat
        var centroidInScreen: CGPoint
        
        // Pan data (valid when gestureMode == .pan)
        var panTranslation: CGSize
        
        /// True while any finger remains in contact during map navigation.
        var isNavigationSessionActive: Bool
    }
    let onUpdate: (State) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(onUpdate: onUpdate) }

    func makeUIView(context: Context) -> UIView {
        let v = UIView()
        v.backgroundColor = .clear
        v.isUserInteractionEnabled = false
        context.coordinator.anchorView = v
        return v
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if context.coordinator.pinch == nil, let window = uiView.window {
            context.coordinator.attachToWindow(window)
        }
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.detachFromWindow()
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        let onUpdate: (State) -> Void
        weak var anchorView: UIView?
        var pinch: UIPinchGestureRecognizer?
        var rotate: UIRotationGestureRecognizer?
        var pan: UIPanGestureRecognizer?
        private weak var attachedWindow: UIWindow?
        
        // Touch tracking
        private var previousTouchCount: Int = 0
        private var lastValidCentroid: CGPoint = .zero
        
        // Session state
        private var isPinchActive: Bool = false
        private var isPanActive: Bool = false
        private var isNavigationSessionActive: Bool = false
        
        // Pan tracking
        private var panStartOffset: CGSize = .zero
        
        // Debounce rapid transitions
        private var lastTransitionTime: CFAbsoluteTime = 0
        private let transitionDebounceInterval: CFAbsoluteTime = 0.05 // 50ms
        
        // Session start time for logging
        private var sessionStartTime: CFAbsoluteTime = 0
        
        init(onUpdate: @escaping (State) -> Void) {
            self.onUpdate = onUpdate
            self.sessionStartTime = CFAbsoluteTimeGetCurrent()
        }
        
        private func timestamp() -> String {
            let elapsed = (CFAbsoluteTimeGetCurrent() - sessionStartTime) * 1000
            return String(format: "%.1fms", elapsed)
        }

        func attachToWindow(_ window: UIWindow) {
            guard pinch == nil else { return }
            
            let p = UIPinchGestureRecognizer(target: self, action: #selector(onPinch(_:)))
            let r = UIRotationGestureRecognizer(target: self, action: #selector(onRotate(_:)))
            
            p.delegate = self
            r.delegate = self
            
            p.cancelsTouchesInView = false
            r.cancelsTouchesInView = false
            
            window.addGestureRecognizer(p)
            window.addGestureRecognizer(r)
            
            let pan = UIPanGestureRecognizer(target: self, action: #selector(onPan(_:)))
            pan.delegate = self
            pan.cancelsTouchesInView = false
            pan.minimumNumberOfTouches = 1
            pan.maximumNumberOfTouches = 2
            window.addGestureRecognizer(pan)
            
            self.pinch = p
            self.rotate = r
            self.pan = pan
            self.attachedWindow = window
            
            // print("🎛️ [\(timestamp())] Bridge attached to window (pinch + rotate + pan)")
        }

        func detachFromWindow() {
            if let p = pinch, let window = attachedWindow {
                window.removeGestureRecognizer(p)
            }
            if let r = rotate, let window = attachedWindow {
                window.removeGestureRecognizer(r)
            }
            if let pan = pan, let window = attachedWindow {
                window.removeGestureRecognizer(pan)
            }
            pinch = nil
            rotate = nil
            pan = nil
            attachedWindow = nil
        }

        func gestureRecognizer(_ g1: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith g2: UIGestureRecognizer) -> Bool { true }

        @objc func onPinch(_ g: UIPinchGestureRecognizer) { handleGestureUpdate() }
        @objc func onRotate(_ g: UIRotationGestureRecognizer) { handleGestureUpdate() }
        @objc func onPan(_ g: UIPanGestureRecognizer) { handlePanUpdate(g) }
        
        private func handlePanUpdate(_ g: UIPanGestureRecognizer) {
            // Ignore pan while pinching (2+ fingers)
            guard !isPinchActive else { return }
            
            let translation = g.translation(in: attachedWindow)
            
            switch g.state {
            case .began:
                isPanActive = true
                isNavigationSessionActive = true
                // print("🖐️ [\(timestamp())] Pan BEGAN (UIKit)")
                onUpdate(State(
                    phase: .began,
                    gestureMode: .pan,
                    scale: 1.0,
                    rotationRadians: 0,
                    centroidInScreen: .zero,
                    panTranslation: .zero,
                    isNavigationSessionActive: true
                ))
                
            case .changed:
                onUpdate(State(
                    phase: .changed,
                    gestureMode: .pan,
                    scale: 1.0,
                    rotationRadians: 0,
                    centroidInScreen: .zero,
                    panTranslation: CGSize(width: translation.x, height: translation.y),
                    isNavigationSessionActive: true
                ))
                
            case .ended:
                isPanActive = false
                isNavigationSessionActive = false
                // print("🖐️ [\(timestamp())] Pan ENDED (UIKit)")
                onUpdate(State(
                    phase: .ended,
                    gestureMode: .pan,
                    scale: 1.0,
                    rotationRadians: 0,
                    centroidInScreen: .zero,
                    panTranslation: CGSize(width: translation.x, height: translation.y),
                    isNavigationSessionActive: false
                ))
                
            case .cancelled, .failed:
                isPanActive = false
                isNavigationSessionActive = false
                // print("🖐️ [\(timestamp())] Pan CANCELLED (UIKit)")
                onUpdate(State(
                    phase: .cancelled,
                    gestureMode: .pan,
                    scale: 1.0,
                    rotationRadians: 0,
                    centroidInScreen: .zero,
                    panTranslation: .zero,
                    isNavigationSessionActive: false
                ))
                
            default:
                break
            }
        }

        private func handleGestureUpdate() {
            guard let p = pinch, let r = rotate, let window = attachedWindow else { return }
            
            let currentTouchCount = max(p.numberOfTouches, r.numberOfTouches)
            let wasTwo = previousTouchCount >= 2
            let isTwo = currentTouchCount >= 2
            
            let now = CFAbsoluteTimeGetCurrent()
            
            defer { previousTouchCount = currentTouchCount }
            
            // TRANSITION: 2 fingers → 1 finger
            if wasTwo && !isTwo && isPinchActive {
                isPinchActive = false
                // Keep isNavigationSessionActive = true so pan can continue
                // print("✌️→☝️ [\(timestamp())] Pinch ENDED (2→1), pan will continue")
                
                // End pinch with last valid centroid (prevents jump)
                onUpdate(State(
                    phase: .ended,
                    gestureMode: .pinchRotate,
                    scale: max(p.scale, 0.0001),
                    rotationRadians: r.rotation,
                    centroidInScreen: lastValidCentroid,
                    panTranslation: .zero,
                    isNavigationSessionActive: true  // Pan continues
                ))
                
                // Reset pan recognizer translation so pan starts fresh from current position
                if let pan = pan {
                    pan.setTranslation(.zero, in: attachedWindow)
                    isPanActive = true
                    
                    // CRITICAL: Send .began so store.beginPan() captures current offset
                    // print("🖐️ [\(timestamp())] Pan BEGAN (after 2→1 transition)")
                    onUpdate(State(
                        phase: .began,
                        gestureMode: .pan,
                        scale: 1.0,
                        rotationRadians: 0,
                        centroidInScreen: .zero,
                        panTranslation: .zero,
                        isNavigationSessionActive: true
                    ))
                }
                
                return
            }
            
            // TRANSITION: 1 finger → 2 fingers
            if !wasTwo && isTwo {
                // Debounce rapid transitions
                if now - lastTransitionTime < transitionDebounceInterval {
                    // print("⚡ [\(timestamp())] Debounced 1→2 transition")
                    return
                }
                lastTransitionTime = now
                
                // End any active pan before starting pinch
                if isPanActive {
                    isPanActive = false
                    // print("🖐️→✌️ [\(timestamp())] Pan ended, switching to pinch")
                    onUpdate(State(
                        phase: .ended,
                        gestureMode: .pan,
                        scale: 1.0,
                        rotationRadians: 0,
                        centroidInScreen: .zero,
                        panTranslation: .zero,
                        isNavigationSessionActive: true  // Session continues with pinch
                    ))
                }
                
                // Reset recognizer values for fresh pinch
                p.scale = 1.0
                r.rotation = 0
                
                // Compute fresh centroid
                let centroid: CGPoint
                if p.numberOfTouches >= 2 {
                    centroid = p.location(in: window)
                } else {
                    centroid = r.location(in: window)
                }
                lastValidCentroid = centroid
                
                isPinchActive = true
                isNavigationSessionActive = true
                // print("☝️→✌️ [\(timestamp())] Pinch BEGAN (1→2) at (\(Int(centroid.x)), \(Int(centroid.y)))")
                
                onUpdate(State(
                    phase: .began,
                    gestureMode: .pinchRotate,
                    scale: 1.0,
                    rotationRadians: 0,
                    centroidInScreen: centroid,
                    panTranslation: .zero,
                    isNavigationSessionActive: true
                ))
                return
            }
            
            // Only process pinch/rotate when we have 2+ touches
            guard isTwo else { return }
            
            // CONTINUING: 2+ fingers, ongoing pinch/rotate
            let centroid: CGPoint
            if p.state != .possible && p.numberOfTouches >= 2 {
                centroid = p.location(in: window)
            } else {
                centroid = r.location(in: window)
            }
            lastValidCentroid = centroid
            
            // Determine phase
            let phase: State.Phase
            if p.state == .ended || r.state == .ended {
                isPinchActive = false
                isNavigationSessionActive = false
                phase = .ended
                // print("✌️ [\(timestamp())] Pinch ENDED (lift both)")
            } else if p.state == .cancelled || r.state == .cancelled {
                isPinchActive = false
                isNavigationSessionActive = false
                phase = .cancelled
                // print("✌️ [\(timestamp())] Pinch CANCELLED")
            } else if !isPinchActive {
                // Fresh 2-finger start (0→2)
                isPinchActive = true
                isNavigationSessionActive = true
                p.scale = 1.0
                r.rotation = 0
                phase = .began
                // print("✌️ [\(timestamp())] Pinch BEGAN (fresh) at (\(Int(centroid.x)), \(Int(centroid.y)))")
            } else {
                phase = .changed
            }
            
            onUpdate(State(
                phase: phase,
                gestureMode: .pinchRotate,
                scale: max(p.scale, 0.0001),
                rotationRadians: r.rotation,
                centroidInScreen: centroid,
                panTranslation: .zero,
                isNavigationSessionActive: isNavigationSessionActive
            ))
        }
    }
}

// Helper extension
private extension CGPoint {
    var asSize: CGSize { CGSize(width: x, height: y) }
}
