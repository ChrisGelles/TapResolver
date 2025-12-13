//
//  SurveyButtonBar.swift
//  TapResolver
//
//  Survey marker control buttons with enable/disable state logic
//

import SwiftUI

// MARK: - Button State

/// Tracks which triangles currently have survey markers
class SurveyMarkerTracker: ObservableObject {
    @Published var trianglesWithMarkers: Set<UUID> = []
    
    func addTriangle(_ id: UUID) {
        trianglesWithMarkers.insert(id)
    }
    
    func removeTriangle(_ id: UUID) {
        trianglesWithMarkers.remove(id)
    }
    
    func hasMarkers(in triangleID: UUID) -> Bool {
        trianglesWithMarkers.contains(triangleID)
    }
}

// MARK: - Survey Button Bar

struct SurveyButtonBar: View {
    // Current state
    let userContainingTriangleID: UUID?
    let hasAnyCalibratedTriangle: Bool
    let swathIsDefined: Bool
    let swathTriangleCount: Int
    let canFillCurrentTriangle: Bool
    let currentTriangleHasMarkers: Bool
    
    // Actions
    let onFillTriangle: () -> Void
    let onDefineSwath: () -> Void
    let onFillSwath: () -> Void
    let onClearTriangle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Fill Triangle
            SurveyButton(
                icon: "circle.grid.3x3.fill",
                label: "Fill Triangle",
                color: .red,
                isEnabled: canFillCurrentTriangle,
                action: onFillTriangle
            )
            
            // Define Swath
            SurveyButton(
                icon: "square.3.layers.3d.top.filled",
                label: "Define Swath",
                color: .purple,
                isEnabled: hasAnyCalibratedTriangle,
                action: onDefineSwath
            )
            
            // Fill Swath
            SurveyButton(
                icon: "square.grid.3x3.topleft.filled",
                label: swathTriangleCount > 0 ? "Fill Swath (\(swathTriangleCount)△)" : "Fill Swath",
                color: .green,
                isEnabled: swathIsDefined && swathTriangleCount > 0,
                action: onFillSwath
            )
            
            // Clear Triangle
            SurveyButton(
                icon: "xmark.circle.fill",
                label: "Clear Triangle",
                color: .orange,
                isEnabled: currentTriangleHasMarkers,
                action: onClearTriangle
            )
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
                    .font(.system(size: 20, weight: .semibold))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundColor(isEnabled ? .white : .white.opacity(0.4))
            .padding(.horizontal, 10)
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
                swathIsDefined: true,
                swathTriangleCount: 5,
                canFillCurrentTriangle: true,
                currentTriangleHasMarkers: true,
                onFillTriangle: {},
                onDefineSwath: {},
                onFillSwath: {},
                onClearTriangle: {}
            )
            
            // Some disabled
            SurveyButtonBar(
                userContainingTriangleID: nil,
                hasAnyCalibratedTriangle: true,
                swathIsDefined: false,
                swathTriangleCount: 0,
                canFillCurrentTriangle: false,
                currentTriangleHasMarkers: false,
                onFillTriangle: {},
                onDefineSwath: {},
                onFillSwath: {},
                onClearTriangle: {}
            )
        }
    }
}
