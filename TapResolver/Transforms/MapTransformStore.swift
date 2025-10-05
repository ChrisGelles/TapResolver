//
//  MapTransformStore.swift
//  TapResolver
//
//  Created by restructuring on 9/19/25.
//

import SwiftUI
import CoreGraphics

// MARK: - Map transform publisher (for screen <-> map conversions)
public final class MapTransformStore: ObservableObject {
    @Published public private(set) var screenCenter: CGPoint = .zero
    @Published public private(set) var totalScale: CGFloat = 1.0
    @Published public private(set) var totalRotationRadians: CGFloat = 0.0
    @Published public private(set) var totalOffset: CGSize = .zero
    @Published public private(set) var mapSize: CGSize = .zero

    public init() {}

    // MARK: - Internal setters (only TransformProcessor should use these)
    @MainActor
    internal func _setTotals(scale: CGFloat, rotationRadians: Double, offset: CGSize) {
        totalScale = scale
        totalRotationRadians = CGFloat(rotationRadians)
        totalOffset = offset
    }

    @MainActor
    internal func _setMapSize(_ size: CGSize) {
        mapSize = size
    }

    @MainActor
    internal func _setScreenCenter(_ point: CGPoint) {
        screenCenter = point
    }

    /// Convert GLOBAL (screen) point to MAP-LOCAL point
    public func screenToMap(_ G: CGPoint) -> CGPoint {
        let s = max(totalScale, 0.0001)
        let O = CGPoint(x: totalOffset.width, y: totalOffset.height)
        let Cscreen = screenCenter
        let Cmap = CGPoint(x: mapSize.width / 2, y: mapSize.height / 2)

        let v = CGPoint(x: G.x - Cscreen.x - O.x,
                        y: G.y - Cscreen.y - O.y)

        let theta = -totalRotationRadians
        let c = cos(theta), ss = sin(theta)
        let vUnrot = CGPoint(x: c * v.x - ss * v.y,
                             y: ss * v.x + c * v.y)

        let vUnscale = CGPoint(x: vUnrot.x / s, y: vUnrot.y / s)
        return CGPoint(x: Cmap.x + vUnscale.x, y: Cmap.y + vUnscale.y)
    }

    /// Convert GLOBAL (screen) translation ΔG into MAP-LOCAL ΔL
    public func screenTranslationToMap(_ dG: CGSize) -> CGPoint {
        let s = max(totalScale, 0.0001)
        let theta = -totalRotationRadians
        let c = cos(theta), ss = sin(theta)
        let v = CGPoint(x: dG.width, y: dG.height)
        let vUnrot = CGPoint(x: c * v.x - ss * v.y,
                             y: ss * v.x + c * v.y)
        return CGPoint(x: vUnrot.x / s, y: vUnrot.y / s)
    }
    
    /// Convert MAP-LOCAL point to GLOBAL (screen) point
    public func mapToScreen(_ M: CGPoint) -> CGPoint {
        let s = max(totalScale, 0.0001)
        let O = CGPoint(x: totalOffset.width, y: totalOffset.height)
        let Cscreen = screenCenter
        let Cmap = CGPoint(x: mapSize.width / 2, y: mapSize.height / 2)
        
        let v = CGPoint(x: M.x - Cmap.x, y: M.y - Cmap.y)
        let vScaled = CGPoint(x: v.x * s, y: v.y * s)
        
        let theta = totalRotationRadians
        let c = cos(theta), ss = sin(theta)
        let vRot = CGPoint(x: c * vScaled.x - ss * vScaled.y,
                          y: ss * vScaled.x + c * vScaled.y)
        
        return CGPoint(x: Cscreen.x + vRot.x + O.x,
                      y: Cscreen.y + vRot.y + O.y)
    }
}
