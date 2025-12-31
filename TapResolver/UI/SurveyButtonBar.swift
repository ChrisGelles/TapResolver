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
    
    // Zone Mode properties
    var isZoneCornerMode: Bool = false
    var hasZoneSurveyMarkers: Bool = false  // True when zone has been flooded
    var onFloodZone: () -> Void = {}
    var onClearZone: () -> Void = {}
    var isRovingMode: Bool = false
    var onToggleRovingMode: () -> Void = {}
    var onExportSVG: () -> Void = {}
    var onManualMarker: () -> Void = {}
    
    var body: some View {
        if isZoneCornerMode {
            // ZONE MODE LAYOUT
            zoneModeSurveyBar
        } else {
            // EXISTING CALIBRATION CRAWL LAYOUT
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
    
    // MARK: - Zone Mode Layout
    
    @ViewBuilder
    private var zoneModeSurveyBar: some View {
        HStack(spacing: 12) {
            // LEFT: Flood Zone / Clear Zone toggle (spans 2 rows)
            Button(action: {
                if hasZoneSurveyMarkers {
                    print("🧹 [ZONE_SURVEY] Clear Zone tapped")
                    onClearZone()
                } else {
                    print("🌊 [ZONE_SURVEY] Flood Zone tapped")
                    onFloodZone()
                }
            }) {
                VStack(spacing: 4) {
                    Image(systemName: hasZoneSurveyMarkers ? "xmark.circle.fill" : "square.grid.3x3.fill")
                        .font(.system(size: 24))
                    Text(hasZoneSurveyMarkers ? "Clear Zone" : "Flood Zone")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(width: 90, height: 76)
                .background(Color.blue.opacity(0.6))
                .cornerRadius(12)
            }
            
            // CENTER: Two stacked buttons
            VStack(spacing: 8) {
                // CENTER TOP: Roving Mode toggle (placeholder)
                Button(action: {
                    print("🎯 [ZONE_SURVEY] Roving Mode tapped (placeholder)")
                    onToggleRovingMode()
                }) {
                    VStack(spacing: 2) {
                        Image(systemName: "target")
                            .font(.system(size: 18))
                        Text("Roving")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(width: 70, height: 34)
                    .background(Color.orange.opacity(0.6))
                    .cornerRadius(8)
                }
                .disabled(true)  // Placeholder - disabled for now
                .opacity(0.5)
                
                // CENTER BOTTOM: Export SVG (placeholder)
                Button(action: {
                    print("📄 [ZONE_SURVEY] Export SVG tapped (placeholder)")
                    onExportSVG()
                }) {
                    VStack(spacing: 2) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18))
                        Text("Export")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(width: 70, height: 34)
                    .background(Color.gray.opacity(0.6))
                    .cornerRadius(8)
                }
                .disabled(true)  // Placeholder - disabled for now
                .opacity(0.5)
            }
            
            // RIGHT: Manual Survey Marker (spans 2 rows)
            Button(action: {
                print("📍 [ZONE_SURVEY] Manual Survey Marker tapped")
                onManualMarker()
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "plus.viewfinder")
                        .font(.system(size: 24))
                    Text("Manual")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(width: 60, height: 76)
                .background(Color.red.opacity(0.85))
                .cornerRadius(12)
            }
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
