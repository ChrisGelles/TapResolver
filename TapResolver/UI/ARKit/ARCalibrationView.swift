//
//  ARCalibrationView.swift
//  TapResolver
//
//  Created by Chris Gelles on 10/19/25.
//


//
//  ARCalibrationView.swift
//  TapResolver
//
//  Role: Full-screen AR calibration interface for mapping 2D map points to 3D space
//

import SwiftUI
import Foundation
import simd

struct ARCalibrationView: View {
    @Binding var isPresented: Bool
    let mapPointID: UUID?  // Optional now - nil in interpolation mode
    let interpolationFirstPointID: UUID?  // First point for interpolation
    let interpolationSecondPointID: UUID?  // Second point for interpolation
    
    @EnvironmentObject private var mapPointStore: MapPointStore
    @EnvironmentObject private var worldMapStore: ARWorldMapStore
    @State private var markerPlaced = false
    @State private var relocalizationStatus: String = ""
    @State private var selectedMarkerID: UUID?
    @State private var showDeleteConfirmation = false
    
    // Interpolation mode tracking
    @State private var isInterpolationMode: Bool = false
    @State private var currentTargetPointID: UUID? = nil
    
    // Independent marker placement tracking
    @State private var markerAPlaced: Bool = false
    @State private var markerBPlaced: Bool = false
    @State private var markerAPosition: simd_float3? = nil
    @State private var markerBPosition: simd_float3? = nil
    @State private var showDistanceWarning: Bool = false
    @State private var distanceMismatchPercent: CGFloat = 0
    
    var body: some View {
        ZStack {
            // AR Camera feed
            ARViewContainer(
                mapPointID: currentTargetPointID ?? mapPointID ?? UUID(),
                userHeight: Float(getUserHeight()),
                markerPlaced: $markerPlaced,
                metricSquareID: nil,
                squareColor: nil,
                squareSideMeters: nil,
                worldMapStore: worldMapStore,
                relocalizationStatus: $relocalizationStatus,
                mapPointStore: mapPointStore,
                selectedMarkerID: $selectedMarkerID
            )
            .ignoresSafeArea()
            
            // New Interpolation UI (only in interpolation mode)
            if isInterpolationMode {
                // Back button (upper left)
                backButton
                
                // PiP Map (upper right)
                pipMapPlaceholder
                
                // Instructions overlay
                instructionsOverlay
                
                // Bottom button section
                VStack {
                    Spacer()
                    bottomButtonSection
                }
            } else {
                // Normal mode - keep existing close button
                VStack {
                    HStack {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isPresented = false
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 60)
                        .padding(.leading, 20)
                        
                        Spacer()
                    }
                    
                    Spacer()
                }
            }
            
            // Relocalization status overlay
            if !relocalizationStatus.isEmpty {
                VStack {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        HStack {
                            if relocalizationStatus.contains("✅") {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else if relocalizationStatus.contains("⚠️") {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                            } else {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            
                            Text(relocalizationStatus)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        // Helpful tips during relocalization
                        if relocalizationStatus.contains("Matching") || relocalizationStatus.contains("Initializing") {
                            Text("💡 Look for distinctive features like corners, furniture, or artwork")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                        }
                        
                        // Failed relocalization options
                        if relocalizationStatus.contains("⚠️") {
                            HStack(spacing: 12) {
                                Button(action: {
                                    // Clear error state first
                                    relocalizationStatus = ""
                                    
                                    // Close and reopen to restart AR session
                                    isPresented = false
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        isPresented = true
                                    }
                                }) {
                                    Text("Try Again")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.blue)
                                        .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                                
                                Button(action: {
                                    // Clear status and close
                                    relocalizationStatus = ""
                                    withAnimation {
                                        isPresented = false
                                    }
                                }) {
                                    Text("Exit")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.red)
                                        .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.75))
                    .cornerRadius(10)
                    .padding(.bottom, 40)
                }
            }
            
            // Delete button for selected marker (only in normal mode)
            if selectedMarkerID != nil && !isInterpolationMode {
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            showDeleteConfirmation = true
                        }) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.red)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .alert("Delete AR Marker?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteSelectedMarker()
            }
        } message: {
            Text("This will permanently remove the AR marker. This action cannot be undone.")
        }
        .zIndex(10000)
        .transition(.move(edge: .leading))
        .onAppear {
            // Check if we're in interpolation mode
            if let firstID = interpolationFirstPointID,
               let secondID = interpolationSecondPointID {
                isInterpolationMode = true
                print("🔗 AR View opened in interpolation mode")
                print("   First point: \(firstID)")
                print("   Second point: \(secondID)")
            } else {
                isInterpolationMode = false
                currentTargetPointID = mapPointID
            }
        }
    }
    
    private func deleteSelectedMarker() {
        guard let markerID = selectedMarkerID else { return }
        
        // Post notification to trigger coordinator deletion
        NotificationCenter.default.post(
            name: NSNotification.Name("DeleteARMarker"),
            object: nil,
            userInfo: ["markerID": markerID]
        )
        
        // Clear selection
        selectedMarkerID = nil
        
        print("📢 Posted delete notification for marker \(markerID)")
    }
    
    private func getUserHeight() -> Double {
        guard let pointID = currentTargetPointID ?? mapPointID,
              let activePoint = mapPointStore.points.first(where: { $0.id == pointID }),
              let lastSession = activePoint.sessions.last else {
            return 1.05 // Default fallback
        }
        return lastSession.deviceHeight_m
    }
    
    private func getPointLabel(_ point: MapPointStore.MapPoint) -> String {
        // ScanSession doesn't have a notes property, so use coordinates
        return "Point (\(Int(point.mapPoint.x)), \(Int(point.mapPoint.y)))"
    }
    
    // MARK: - New Interpolation UI Components
    
    private var bottomButtonSection: some View {
        VStack(spacing: ARInterpolationLayout.markerButtonGap) {
            // Two marker placement buttons
            HStack(spacing: ARInterpolationLayout.markerButtonGap) {
                // Place Marker A button
                Button(action: {
                    // TODO: Handle Marker A placement
                    print("🟠 Place Marker A tapped")
                }) {
                    HStack(spacing: 8) {
                        if markerAPlaced {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        Text(markerAPlaced ? "Marker A ✓" : "Place Marker A")
                            .font(.system(size: ARInterpolationLayout.markerButtonFontSize, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: ARInterpolationLayout.markerButtonHeight)
                    .background(markerAPlaced ? ARInterpolationLayout.successColor : ARInterpolationLayout.markerAColor)
                    .cornerRadius(ARInterpolationLayout.markerButtonCornerRadius)
                }
                
                // Place Marker B button
                Button(action: {
                    // TODO: Handle Marker B placement
                    print("🟢 Place Marker B tapped")
                }) {
                    HStack(spacing: 8) {
                        if markerBPlaced {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        Text(markerBPlaced ? "Marker B ✓" : "Place Marker B")
                            .font(.system(size: ARInterpolationLayout.markerButtonFontSize, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: ARInterpolationLayout.markerButtonHeight)
                    .background(markerBPlaced ? ARInterpolationLayout.successColor : ARInterpolationLayout.markerBColor)
                    .cornerRadius(ARInterpolationLayout.markerButtonCornerRadius)
                }
            }
            
            // Interpolate button (only when both placed)
            if markerAPlaced && markerBPlaced {
                Button(action: {
                    print("🎯 Interpolate tapped")
                    // TODO: Proceed to Milestone 3
                    isPresented = false
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "function")
                        Text("INTERPOLATE!")
                    }
                    .font(.system(size: ARInterpolationLayout.interpolateButtonFontSize, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: ARInterpolationLayout.interpolateButtonHeight)
                    .background(showDistanceWarning ? Color.gray : ARInterpolationLayout.successColor)
                    .cornerRadius(ARInterpolationLayout.interpolateButtonCornerRadius)
                }
                .disabled(showDistanceWarning && distanceMismatchPercent > ARInterpolationLayout.distanceCriticalThreshold)
            }
        }
        .padding(.horizontal, ARInterpolationLayout.markerButtonSideMargin)
        .padding(.bottom, ARInterpolationLayout.bottomButtonSectionBottomPadding)
    }
    
    private var instructionsOverlay: some View {
        VStack {
            Spacer()
            
            // Instructions text
            Text(instructionText)
                .font(.system(size: ARInterpolationLayout.instructionsFontSize, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, ARInterpolationLayout.instructionsHorizontalPadding)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.7))
                .cornerRadius(8)
                .padding(.bottom, ARInterpolationLayout.instructionsBottomOffset)
        }
    }
    
    private var instructionText: String {
        if !markerAPlaced && !markerBPlaced {
            return "Place marker at either location first"
        } else if markerAPlaced && !markerBPlaced {
            return "Marker A placed - Now place Marker B"
        } else if !markerAPlaced && markerBPlaced {
            return "Marker B placed - Now place Marker A"
        } else if showDistanceWarning {
            return "⚠️ Distance mismatch - Check placement"
        } else {
            return "Distance: Map \(formatDistance(mapDistance))m | AR \(formatDistance(arDistance))m ✓"
        }
    }
    
    private func formatDistance(_ distance: Float) -> String {
        return String(format: "%.1f", distance)
    }
    
    // Placeholder distance calculations
    private var mapDistance: Float {
        // TODO: Calculate from map coordinates
        return 6.8
    }
    
    private var arDistance: Float {
        guard let posA = markerAPosition, let posB = markerBPosition else { return 0 }
        return simd_distance(posA, posB)
    }
    
    private var backButton: some View {
        Button(action: {
            isPresented = false
        }) {
            Image(systemName: "arrow.left")
                .font(.system(size: ARInterpolationLayout.backButtonIconSize, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: ARInterpolationLayout.backButtonSize, height: ARInterpolationLayout.backButtonSize)
                .background(Color.black.opacity(0.6))
                .clipShape(Circle())
        }
        .position(
            x: ARInterpolationLayout.backButtonLeftMargin + ARInterpolationLayout.backButtonSize/2,
            y: ARInterpolationLayout.backButtonTopMargin + ARInterpolationLayout.backButtonSize/2
        )
    }
    
    private var pipMapPlaceholder: some View {
        VStack {
            HStack {
                Spacer()
                // Placeholder for PiP map
                Rectangle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(
                        width: ARInterpolationLayout.pipMapWidth,
                        height: ARInterpolationLayout.pipMapHeight
                    )
                    .cornerRadius(ARInterpolationLayout.pipMapCornerRadius)
                    .padding(.top, ARInterpolationLayout.pipMapTopMargin)
                    .padding(.trailing, ARInterpolationLayout.pipMapRightMargin)
            }
            Spacer()
        }
    }
}
