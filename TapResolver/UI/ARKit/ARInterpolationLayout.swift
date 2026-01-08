//
//  ARInterpolationLayout.swift
//  TapResolver
//
//  Created for AR Interpolation Mode layout constants
//

import SwiftUI

/// Layout constants for AR Interpolation Mode
/// All values easily adjustable in one place
struct ARInterpolationLayout {
    
    // MARK: - Screen Dimensions
    /// Assuming standard iPhone width
    static let screenWidth: CGFloat = 393
    static let screenHeight: CGFloat = 852
    
    // MARK: - PiP Map
    static let pipMapWidthRatio: CGFloat = 2.0/3.0  // 2/3 of screen width
    static let pipMapAspectRatio: CGFloat = 4.0/3.0  // width:height
    static let pipMapTopMargin: CGFloat = 50
    static let pipMapRightMargin: CGFloat = 20
    static let pipMapCornerRadius: CGFloat = 12
    static let pipMapOpacity: Double = 0.9
    
    // MARK: - Controls Grid
    static let controlsLeftMargin: CGFloat = 20
    
    // Calculated values
    static var pipMapWidth: CGFloat {
        screenWidth * pipMapWidthRatio
    }
    static var pipMapHeight: CGFloat {
        pipMapWidth / pipMapAspectRatio
    }
    
    // MARK: - Back Button
    static let backButtonTopMargin: CGFloat = 60
    static let backButtonLeftMargin: CGFloat = 20
    static let backButtonSize: CGFloat = 44
    static let backButtonIconSize: CGFloat = 20
    
    // MARK: - Instructions Area
    static let instructionsBottomOffset: CGFloat = 127  // Above buttons
    static let instructionsHorizontalPadding: CGFloat = 20
    static let instructionsFontSize: CGFloat = 14
    
    // MARK: - Bottom Button Section
    static let bottomButtonSectionHeight: CGFloat = 77  // Single row now
    static let bottomButtonSectionBottomPadding: CGFloat = 20
    
    // All three buttons in one row
    static let buttonHeight: CGFloat = 60
    static let buttonGap: CGFloat = 8
    static let buttonSideMargin: CGFloat = 20
    static let buttonCornerRadius: CGFloat = 12
    static let buttonFontSize: CGFloat = 14  // Smaller for three across
    
    // MARK: - AR Visualization
    static let connectorLineWidth: CGFloat = 0.02  // meters in AR space
    static let distanceLabelOffset: CGFloat = 0.3  // meters from line
    static let distanceLabelHeight: CGFloat = 0.2  // meters tall
    static let sphereRadius: CGFloat = 0.1  // meters
    
    // MARK: - Distance Validation
    static let distanceWarningThreshold: CGFloat = 0.20  // 20% difference triggers warning
    static let distanceCriticalThreshold: CGFloat = 0.35  // 35% blocks interpolation
    
    // MARK: - Colors
    static let markerAColor = Color.orange
    static let markerBColor = Color.green
    static let interpolateColor = Color.blue
    static let interpolateDisabledColor = Color.gray
    static let mapDistanceColor = Color.blue
    static let arDistanceColor = Color.yellow
    static let warningColor = Color.red
    static let successColor = Color.green
}

