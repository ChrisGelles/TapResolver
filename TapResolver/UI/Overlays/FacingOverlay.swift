//
//  FacingOverlay.swift
//  TapResolver
//
//  Created by Chris Gelles on 10/2/25.
//

import SwiftUI

@inline(__always)
private func radiansCCW_to_degreesCW(_ r: Double) -> Double {
    // Map transform is typically +CCW (math). SwiftUI rotationEffect uses +CW on screen.
    return -(r * 180.0 / .pi)
}

/// Overlay showing user's device orientation with facing glyph
struct FacingOverlay: View {
    @EnvironmentObject private var orientation: CompassOrientationManager
    @EnvironmentObject private var squareMetrics: SquareMetrics
    
    @EnvironmentObject private var mapTransform: MapTransformStore
    
    var body: some View {
        GeometryReader { geometry in
            let deviceDeg = orientation.fusedHeadingDegrees.isNaN ? 
                (orientation.trueHeadingDegrees ?? .nan) : 
                orientation.fusedHeadingDegrees
            
            // Convert current map rotation (radians, +CCW) to CW degrees for SwiftUI
            let mapRotationDegCW = radiansCCW_to_degreesCW(mapTransform.totalRotationRadians)

            // Display-facing angle (CW): device + calibrated north offset − current map rotation
            let mapFacingCW = normalizeDegrees(deviceDeg + squareMetrics.northOffsetDeg - mapRotationDegCW)

            // Use CW directly for SwiftUI (no negation needed)
            let renderDeg = mapFacingCW
            
            let facingGlyphImage = "facing-glyph"
            // Only render if heading is valid
            if deviceDeg.isFinite {
                ZStack {
                    // Centered container
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            
                            // Facing glyph
                            Image(facingGlyphImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: glyphSize(geometry), height: glyphSize(geometry))
                                .rotationEffect(.degrees(renderDeg))
                                .foregroundStyle(Color.cyan)
                                .allowsHitTesting(false)
                            
                            Spacer()
                        }
                        Spacer()
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func glyphSize(_ geometry: GeometryProxy) -> CGFloat {
        let minDimension = min(geometry.size.width, geometry.size.height)
        return minDimension * 1 // 9% of screen dimension
    }
    
    private func normalizeDegrees(_ degrees: Double) -> Double {
        var normalized = degrees.truncatingRemainder(dividingBy: 360.0)
        if normalized > 180.0 {
            normalized -= 360.0
        } else if normalized <= -180.0 {
            normalized += 360.0
        }
        return normalized
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        FacingOverlay()
            .environmentObject(CompassOrientationManager())
            .environmentObject(SquareMetrics())
            .environmentObject(MapTransformStore())
    }
}
