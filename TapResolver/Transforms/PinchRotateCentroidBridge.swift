//
//  PinchRotateCentroidBridge.swift
//  TapResolver
//
//  Created by Chris Gelles on 10/4/25.
//


import SwiftUI
import UIKit

/// Two-finger pinch+rotate bridge that reports:
///  - cumulative scale (1.0 at .began)
///  - cumulative rotationRadians (0.0 at .began)
///  - centroidInScreen (CGPoint in screen coords)
/// NOTE: Does NOT block single-finger touches (one-finger pan still works).
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
        let v = PassThroughWhenSingleTouchView()
        v.backgroundColor = .clear

        let pinch = UIPinchGestureRecognizer(target: context.coordinator,
                                             action: #selector(Coordinator.onPinch(_:)))
        let rot   = UIRotationGestureRecognizer(target: context.coordinator,
                                                action: #selector(Coordinator.onRotate(_:)))
        pinch.delegate = context.coordinator
        rot.delegate   = context.coordinator

        // Do not block SwiftUI’s single-finger gestures.
        pinch.cancelsTouchesInView = false
        rot.cancelsTouchesInView   = false

        v.addGestureRecognizer(pinch)
        v.addGestureRecognizer(rot)
        context.coordinator.pinch  = pinch
        context.coordinator.rotate = rot
        return v
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        let onUpdate: (State) -> Void
        weak var pinch: UIPinchGestureRecognizer?
        weak var rotate: UIRotationGestureRecognizer?

        init(onUpdate: @escaping (State) -> Void) {
            self.onUpdate = onUpdate
        }

        func gestureRecognizer(_ g1: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith g2: UIGestureRecognizer) -> Bool { true }

        @objc func onPinch(_ g: UIPinchGestureRecognizer)  { emit() }
        @objc func onRotate(_ g: UIRotationGestureRecognizer) { emit() }

        private func emit() {
            guard let p = pinch, let r = rotate, let view = p.view else { return }

            // Phase (prefer .changed if either is changing)
            let phase: State.Phase = {
                let states = [p.state, r.state]
                if states.contains(.began)     { return .began }
                if states.contains(.changed)   { return .changed }
                if states.contains(.ended)     { return .ended }
                if states.contains(.cancelled) { return .cancelled }
                return .changed
            }()

            // Prefer pinch location if active; else rotation location
            let centroidLocal: CGPoint = (p.state != .possible) ? p.location(in: view)
                                                                : r.location(in: view)
            // Convert to screen coords (nil = window base)
            let centroidInScreen = view.convert(centroidLocal, to: nil)

            onUpdate(State(
                phase: phase,
                scale: max(p.scale, 0.0001),
                rotationRadians: r.rotation,
                centroidInScreen: centroidInScreen
            ))
        }
    }

    /// Transparent view that receives all touches.
    /// Single-finger touches pass through via cancelsTouchesInView = false on recognizers.
    /// Pinch/rotate recognizers naturally require 2+ fingers to activate.
    private final class PassThroughWhenSingleTouchView: UIView {
        // No hitTest override — let all touches reach the gesture recognizers.
        // The recognizers themselves filter for 2+ finger gestures.
    }
}
