//
//  TransformProcessing.swift
//  TapResolver
//
//  Created by Chris Gelles on 9/17/25.
//
//  Coalesces/thresholds gesture totals and publishes stable values to MapTransformStore.
//

import SwiftUI

@MainActor
final class TransformProcessor: ObservableObject {

    enum PinchPhase { case began, changed, ended, cancelled }
    @Published var useAnchorPreservingPivot: Bool = true

    // Fixed at gesture start; do not change mid-gesture
    private var fixedAnchorScreen: CGPoint?
    private var fixedAnchorMap: CGPoint?
    private var originScale: CGFloat = 1
    private var originRotation: Double = 0
    private var originOffset: CGSize = .zero

    @MainActor
    func handlePinchRotate(
        phase: PinchPhase,
        scaleFromStart ds: CGFloat,
        rotationFromStart dθ: CGFloat,
        centroidInScreen a_scr: CGPoint
    ) {
        guard let store = mapTransform else { return }
        let Cscreen = store.screenCenter
        let Cmap    = CGPoint(x: store.mapSize.width/2, y: store.mapSize.height/2)

        switch phase {
        case .began:
            originScale    = store.totalScale
            originRotation = store.totalRotationRadians
            originOffset   = store.totalOffset
            fixedAnchorScreen = a_scr

            // Map anchor under the finger at start (invert transform once)
            let dx = a_scr.x - Cscreen.x - originOffset.width
            let dy = a_scr.y - Cscreen.y - originOffset.height
            let c0 = cos(-originRotation), s0 = sin(-originRotation)
            let rx = c0*dx - s0*dy
            let ry = s0*dx + c0*dy
            fixedAnchorMap = CGPoint(
                x: Cmap.x + rx / max(originScale, 0.0001),
                y: Cmap.y + ry / max(originScale, 0.0001)
            )

        case .changed:
            guard let a_map0 = fixedAnchorMap, let a_scr0 = fixedAnchorScreen else { return }
            // New cumulative totals
            let s1  = originScale * max(ds, 0.0001)
            let th1 = originRotation + Double(dθ)

            // Keep the same map point under the same screen point captured at .began
            let ax = a_map0.x - Cmap.x, ay = a_map0.y - Cmap.y
            let c1 = cos(th1), s1r = sin(th1)
            let rx = c1 * (s1 * ax) - s1r * (s1 * ay)
            let ry = s1r * (s1 * ax) + c1  * (s1 * ay)
            let t1 = CGSize(width: a_scr0.x - Cscreen.x - rx,
                            height: a_scr0.y - Cscreen.y - ry)

            // Defer publish (uses your existing coalescer)
            enqueueCandidate(scale: s1, rotationRadians: th1, offset: t1)

        case .ended, .cancelled:
            fixedAnchorScreen = nil
            fixedAnchorMap = nil
        }
    }

    // Pass-through mode to preserve current behavior (no throttling yet)
    var passThrough: Bool = true

    // Weak-ish reference (not retaining cycles with SwiftUI),
    // bind from ContentView on appear.
    private var mapTransform: MapTransformStore?

    // Coalescing state
    private var pushScheduled = false
    private var pendingScale: CGFloat = 1
    private var pendingRotation: Double = 0
    private var pendingOffset: CGSize = .zero

    // Last-pushed cache
    private var lastScale: CGFloat = 1
    private var lastRotation: Double = 0
    private var lastOffset: CGSize = .zero

    // Thresholds to reduce churn
    private let scaleEpsilon: CGFloat = 0.0005
    private let rotEpsilon: Double = 0.0005
    private let offEpsilon: CGFloat = 0.25

    init(mapTransform: MapTransformStore? = nil) {
        self.mapTransform = mapTransform
    }

    // Call once (e.g., ContentView.onAppear)
    func bind(to store: MapTransformStore) {
        self.mapTransform = store
        // Optional: seed last/pending with current store values to avoid an initial jump
        self.lastScale = store.totalScale
        self.lastRotation = store.totalRotationRadians
        self.lastOffset = store.totalOffset
    }

    // View metadata setters (route through processor so the view stays dumb)
    func setMapSize(_ size: CGSize) {
        // REPLACE direct write with guard + deferred helper:
        guard let store = mapTransform else { return }
        if store.mapSize == size { return }
        DispatchQueue.main.async { [weak self] in
            self?.mapTransform?._setMapSize(size)
        }
    }

    func setScreenCenter(_ point: CGPoint) {
        guard let store = mapTransform else { return }
        if store.screenCenter == point { return }
        DispatchQueue.main.async { [weak self] in
            self?.mapTransform?._setScreenCenter(point)
        }
    }

    // Main entry from GestureHandler (call very frequently)
    func enqueueCandidate(scale: CGFloat, rotationRadians: Double, offset: CGSize) {
        // REPLACE the immediate write with a deferred commit:
        if passThrough {
            // Coalesce to next runloop tick (avoids "publish during view update")
            pendingScale = scale
            pendingRotation = rotationRadians
            pendingOffset = offset
            schedulePushIfNeeded()
            return
        }
        
        pendingScale = scale
        pendingRotation = rotationRadians
        pendingOffset = offset
        schedulePushIfNeeded()
    }

    // MARK: - Private

    private func schedulePushIfNeeded() {
        guard !pushScheduled else { return }
        pushScheduled = true
        // Coalesce to next runloop tick (one update per frame)
        DispatchQueue.main.async { [weak self] in
            self?.pushScheduled = false
            self?.pushIfMeaningful()
        }
    }

    private func pushIfMeaningful() {
        guard let store = mapTransform else { return }

        let scaleChanged = abs(pendingScale - lastScale) > scaleEpsilon
        let rotChanged   = abs(pendingRotation - lastRotation) > rotEpsilon
        let offChanged   = abs(pendingOffset.width  - lastOffset.width)  > offEpsilon
                        || abs(pendingOffset.height - lastOffset.height) > offEpsilon

        guard scaleChanged || rotChanged || offChanged else { return }

        // REPLACE the three direct assignments with this single call:
        store._setTotals(scale: pendingScale,
                         rotationRadians: pendingRotation,
                         offset: pendingOffset)

        lastScale = pendingScale
        lastRotation = pendingRotation
        lastOffset = pendingOffset
    }
}

