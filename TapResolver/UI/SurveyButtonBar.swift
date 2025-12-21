//
//  SurveyButtonBar.swift
//  TapResolver
//
//  Survey marker control buttons with enable/disable state logic
//

import SwiftUI
import Foundation

// MARK: - Survey Button Bar

struct SurveyButtonBar: View {
    // Current state
    let userContainingTriangleID: UUID?
    let hasAnyCalibratedTriangle: Bool
    let fillableKnownCount: Int      // Session + ghost markers only
    let fillableBakedCount: Int      // Using baked historical data
    let canFillCurrentTriangle: Bool
    let currentTriangleHasMarkers: Bool
    let hasAnySurveyMarkers: Bool
    
    // Actions
    let onFillTriangle: () -> Void
    let onClearTriangle: () -> Void
    let onFillKnown: () -> Void
    let onDefineSwath: () -> Void
    let onFillMap: () -> Void
    let onClearAll: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 8) {
                // Row 1: Triangle-level operations
                HStack(spacing: 12) {
                    // Fill Triangle
                    SurveyButton(
                        icon: "circle.grid.3x3.fill",
                        label: "Fill Triangle",
                        color: .red,
                        isEnabled: canFillCurrentTriangle,
                        action: onFillTriangle
                    )
                    
                    // Clear Triangle
                    SurveyButton(
                        icon: "xmark.circle.fill",
                        label: "Clear Triangle",
                        color: .orange,
                        isEnabled: currentTriangleHasMarkers,
                        action: onClearTriangle
                    )
                    
                    // Fill Known - session + ghost markers only
                    SurveyButton(
                        icon: "triangle.fill",
                        label: fillableKnownCount > 0 ? "Fill Known (\(fillableKnownCount)△)" : "Fill Known",
                        color: .green,
                        isEnabled: fillableKnownCount > 0,
                        action: onFillKnown
                    )
                }
                
                // Row 2: Map-level operations
                HStack(spacing: 12) {
                    // Define Swath
                    SurveyButton(
                        icon: "square.3.layers.3d.top.filled",
                        label: "Define Swath",
                        color: .purple,
                        isEnabled: hasAnyCalibratedTriangle,
                        action: onDefineSwath
                    )
                    
                    // Fill Map - uses baked data
                    SurveyButton(
                        icon: "map.fill",
                        label: fillableBakedCount > 0 ? "Fill Map (\(fillableBakedCount)△)" : "Fill Map",
                        color: .blue,
                        isEnabled: fillableBakedCount > 0,
                        action: onFillMap
                    )
                    
                    // Clear All
                    SurveyButton(
                        icon: "trash.fill",
                        label: "Clear All",
                        color: .gray,
                        isEnabled: hasAnySurveyMarkers,
                        action: onClearAll
                    )
                }
            }
            
            // Manual Survey Marker button - spans both rows
            Button(action: {
                NotificationCenter.default.post(
                    name: .placeManualSurveyMarker,
                    object: nil
                )
            }) {
                Image(systemName: "plus.viewfinder")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 76)  // Match combined height of 2 rows
                    .background(Color.red)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 60)
    }
}

// MARK: - Individual Button

struct SurveyButton: View {
    let icon: String
    let label: String
    let color: Color
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            if isEnabled {
                action()
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundColor(isEnabled ? .white : .white.opacity(0.4))
            .frame(minWidth: 80)
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(isEnabled ? color.opacity(0.85) : Color.gray.opacity(0.4))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack {
            Spacer()
            
            // All enabled
            SurveyButtonBar(
                userContainingTriangleID: UUID(),
                hasAnyCalibratedTriangle: true,
                fillableKnownCount: 5,
                fillableBakedCount: 21,
                canFillCurrentTriangle: true,
                currentTriangleHasMarkers: true,
                hasAnySurveyMarkers: true,
                onFillTriangle: {},
                onClearTriangle: {},
                onFillKnown: {},
                onDefineSwath: {},
                onFillMap: {},
                onClearAll: {}
            )
            
            Spacer().frame(height: 40)
            
            // Some disabled
            SurveyButtonBar(
                userContainingTriangleID: nil,
                hasAnyCalibratedTriangle: false,
                fillableKnownCount: 0,
                fillableBakedCount: 0,
                canFillCurrentTriangle: false,
                currentTriangleHasMarkers: false,
                hasAnySurveyMarkers: false,
                onFillTriangle: {},
                onClearTriangle: {},
                onFillKnown: {},
                onDefineSwath: {},
                onFillMap: {},
                onClearAll: {}
            )
        }
    }
}
