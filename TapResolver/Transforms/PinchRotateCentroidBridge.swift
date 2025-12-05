//
//  PinchRotateCentroidBridge.swift
//  TapResolver
//
//  Window-level gesture recognizers for centroid-pivot pinch/rotate.
//  Attaches to window so SwiftUI overlays can still receive taps.
//

import SwiftUI
import UIKit

/// Two-finger pinch+rotate bridge that reports:
///  - cumulative scale (1.0 at .began)
///  - cumulative rotationRadians (0.0 at .began)
///  - centroidInScreen (CGPoint in screen coords)
/// Recognizers attach to WINDOW, not a blocking UIView.
struct PinchRotateCentroidBridge: UIViewRepresentable {
    struct State {
        enum Phase { case began, changed, ended, cancelled }
        var phase: Phase
        var scale: CGFloat
        var rotationRadians: CGFloat
        var centroidInScreen: CGPoint
    }

    let onUpdate: (State) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onUpdate: onUpdate) }

    func makeUIView(context: Context) -> UIView {
        // Non-interactive anchor view — only used to access the window
        let v = UIView()
        v.backgroundColor = .clear
        v.isUserInteractionEnabled = false  // Critical: don't intercept ANY touches
        context.coordinator.anchorView = v
        return v
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Attach recognizers to window once view is in hierarchy
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
        private weak var attachedWindow: UIWindow?

        init(onUpdate: @escaping (State) -> Void) {
            self.onUpdate = onUpdate
        }

        func attachToWindow(_ window: UIWindow) {
            guard pinch == nil else { return }  // Already attached
            
            let p = UIPinchGestureRecognizer(target: self, action: #selector(onPinch(_:)))
            let r = UIRotationGestureRecognizer(target: self, action: #selector(onRotate(_:)))
            
            p.delegate = self
            r.delegate = self
            p.cancelsTouchesInView = false
            r.cancelsTouchesInView = false
            
            window.addGestureRecognizer(p)
            window.addGestureRecognizer(r)
            
            self.pinch = p
            self.rotate = r
            self.attachedWindow = window
            
            print("🤏 [BRIDGE] Attached recognizers to window")
        }

        func detachFromWindow() {
            if let p = pinch, let window = attachedWindow {
                window.removeGestureRecognizer(p)
            }
            if let r = rotate, let window = attachedWindow {
                window.removeGestureRecognizer(r)
            }
            pinch = nil
            rotate = nil
            attachedWindow = nil
            print("🤏 [BRIDGE] Detached recognizers from window")
        }

        func gestureRecognizer(_ g1: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith g2: UIGestureRecognizer) -> Bool { true }

        @objc func onPinch(_ g: UIPinchGestureRecognizer)  { emit() }
        @objc func onRotate(_ g: UIRotationGestureRecognizer) { emit() }

        private func emit() {
            guard let p = pinch, let r = rotate, let window = attachedWindow else { return }

            // Phase (prefer .changed if either is changing)
            let phase: State.Phase = {
                let states = [p.state, r.state]
                if states.contains(.began)     { return .began }
                if states.contains(.changed)   { return .changed }
                if states.contains(.ended)     { return .ended }
                if states.contains(.cancelled) { return .cancelled }
                return .changed
            }()

            // Centroid in window (screen) coordinates
            let centroid: CGPoint
            if p.state != .possible && p.numberOfTouches >= 2 {
                centroid = p.location(in: window)
            } else if r.state != .possible && r.numberOfTouches >= 2 {
                centroid = r.location(in: window)
            } else if p.state != .possible {
                centroid = p.location(in: window)
            } else {
                centroid = r.location(in: window)
            }

            print("🤏 [BRIDGE] phase:\(phase) scale:\(String(format: "%.3f", p.scale)) rot:\(String(format: "%.3f", r.rotation)) centroid:(\(Int(centroid.x)),\(Int(centroid.y)))")

            onUpdate(State(
                phase: phase,
                scale: max(p.scale, 0.0001),
                rotationRadians: r.rotation,
                centroidInScreen: centroid
            ))
        }
    }
}
