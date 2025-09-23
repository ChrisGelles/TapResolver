//
//  GestureHandler.swift
//  TapResolver
//
//  Extracted gesture/state controller for map interactions.
//  Keeps Views lean and makes transforms reusable.
//  Created by Chris Gelles on 9/14/25.
//

import SwiftUI

@MainActor
final class MapGestureHandler: ObservableObject {
    // Config
    private let minScale: CGFloat
    private let maxScale: CGFloat
    private let zoomStep: CGFloat

    // Persistent (steady) state
    @Published var steadyScale: CGFloat = 1.0
    @Published var steadyRotation: Angle = .degrees(0)
    @Published var steadyOffset: CGSize = .zero

    // In-gesture (transient) state
    @Published var gestureScale: CGFloat = 1.0
    @Published var gestureRotation: Angle = .degrees(0)
    @Published var gestureTranslation: CGSize = .zero

    // Notify listeners when totals change (optional external wiring)
    var onTotalsChanged: ((CGFloat, Double, CGSize) -> Void)?

    init(minScale: CGFloat = 0.5, maxScale: CGFloat = 4.0, zoomStep: CGFloat = 1.25) {
        self.minScale = minScale
        self.maxScale = maxScale
        self.zoomStep = zoomStep
    }

    // Derived totals
    var totalScale: CGFloat {
        clamp(steadyScale * gestureScale, minScale, maxScale)
    }

    var totalRotation: Angle {
        steadyRotation + gestureRotation
    }

    var totalOffset: CGSize {
        CGSize(
            width: steadyOffset.width + gestureTranslation.width,
            height: steadyOffset.height + gestureTranslation.height
        )
    }

    // MARK: - Public actions

    func doubleTapZoom() {
        steadyScale = clamp(steadyScale * zoomStep, minScale, maxScale)
        emitTotals()
    }

    func resetTransform() {
        steadyScale = 1.0
        gestureScale = 1.0
        steadyRotation = .degrees(0)
        gestureRotation = .degrees(0)
        steadyOffset = .zero
        gestureTranslation = .zero
        emitTotals()
    }

    // MARK: - Gestures

    var combinedGesture: some Gesture {
        panGesture()
            .simultaneously(with: pinchGesture())
            .simultaneously(with: rotateGesture())
    }

    private func panGesture() -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { [weak self] value in
                guard let self else { return }
                self.gestureTranslation = value.translation
                self.emitTotals()
            }
            .onEnded { [weak self] value in
                guard let self else { return }
                self.steadyOffset.width += value.translation.width
                self.steadyOffset.height += value.translation.height
                self.gestureTranslation = .zero
                self.emitTotals()
            }
    }

    private func pinchGesture() -> some Gesture {
        MagnificationGesture()
            .onChanged { [weak self] value in
                guard let self else { return }
                self.gestureScale = value
                self.emitTotals()
            }
            .onEnded { [weak self] value in
                guard let self else { return }
                self.steadyScale = clamp(self.steadyScale * value, self.minScale, self.maxScale)
                self.gestureScale = 1.0
                self.emitTotals()
            }
    }

    private func rotateGesture() -> some Gesture {
        RotationGesture()
            .onChanged { [weak self] angle in
                guard let self else { return }
                self.gestureRotation = angle
                self.emitTotals()
            }
            .onEnded { [weak self] angle in
                guard let self else { return }
                self.steadyRotation += angle
                self.gestureRotation = .degrees(0)
                self.emitTotals()
            }
    }

    // MARK: - Utils

    private func clamp<T: Comparable>(_ x: T, _ a: T, _ b: T) -> T { min(max(x, a), b) }

    private func emitTotals() {
        onTotalsChanged?(totalScale, totalRotation.radians, totalOffset)
    }
}
