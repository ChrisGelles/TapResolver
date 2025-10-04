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
        mapTransform?.mapSize = size
    }

    func setScreenCenter(_ point: CGPoint) {
        mapTransform?.screenCenter = point
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

        store.totalScale = pendingScale
        store.totalRotationRadians = pendingRotation
        store.totalOffset = pendingOffset

        lastScale = pendingScale
        lastRotation = pendingRotation
        lastOffset = pendingOffset
    }
}

