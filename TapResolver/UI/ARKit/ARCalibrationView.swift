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
    @EnvironmentObject private var metricSquares: MetricSquareStore
    @State private var markerPlaced = false
    @State private var relocalizationStatus: String = ""
    @State private var selectedMarkerID: UUID?
    @State private var showDeleteConfirmation = false
    
    // Interpolation mode tracking
    @State private var currentTargetPointID: UUID? = nil
    
    // Computed property - derived from parameters
    private var isInterpolationMode: Bool {
        interpolationFirstPointID != nil && interpolationSecondPointID != nil
    }
    
    // Independent marker placement tracking
    @State private var markerAPlaced: Bool = false
    @State private var markerBPlaced: Bool = false
    @State private var markerAPosition: simd_float3? = nil
    @State private var markerBPosition: simd_float3? = nil
    @State private var showDistanceWarning: Bool = false
    @State private var distanceMismatchPercent: CGFloat = 0
    @State private var lastRaycastPosition: simd_float3? = nil
    
    // Interpolation slider
    @State private var interpolationCount: Int = 0
    @State private var maxNewMarkers: Int = 0
    
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
                selectedMarkerID: $selectedMarkerID,
                isInterpolationMode: isInterpolationMode,
                interpolationFirstPointID: interpolationFirstPointID,
                interpolationSecondPointID: interpolationSecondPointID
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
    
    // MARK: - Button Actions
    
    private func placeMarkerA() {
        guard !markerAPlaced else {
            print("🟠 Marker A already placed")
            return
        }
        
        guard let coordinator = ARViewContainer.Coordinator.current else {
            print("❌ No coordinator reference")
            return
        }
        
        guard let pointA = mapPointStore.points.first(where: { $0.id == interpolationFirstPointID }) else {
            print("❌ Cannot find Point A")
            return
        }
        
        print("🟠 Placing Marker A...")
        coordinator.placeMarkerAt(
            mapPointID: interpolationFirstPointID!,
            mapPoint: pointA,
            color: UIColor.orange
        )
        
        markerAPlaced = true
        markerAPosition = coordinator.lastPlacedPosition
        print("✅ Marker A placed")
        calculateMaxNewMarkers()
    }
    
    private func placeMarkerB() {
        guard !markerBPlaced else {
            print("🟢 Marker B already placed")
            return
        }
        
        guard let coordinator = ARViewContainer.Coordinator.current else {
            print("❌ No coordinator reference")
            return
        }
        
        guard let pointB = mapPointStore.points.first(where: { $0.id == interpolationSecondPointID }) else {
            print("❌ Cannot find Point B")
            return
        }
        
        print("🟢 Placing Marker B...")
        coordinator.placeMarkerAt(
            mapPointID: interpolationSecondPointID!,
            mapPoint: pointB,
            color: UIColor.green
        )
        
        markerBPlaced = true
        markerBPosition = coordinator.lastPlacedPosition
        
        if let posA = markerAPosition {
            let distance = simd_distance(posA, markerBPosition!)
            print("📏 Distance between markers: \(String(format: "%.2f", distance))m")
        }
        
        print("✅ Marker B placed")
        calculateMaxNewMarkers()
    }
    
    private func proceedToInterpolation() {
        guard interpolationCount > 0,
              let firstID = interpolationFirstPointID,
              let secondID = interpolationSecondPointID,
              let pointA = mapPointStore.points.first(where: { $0.id == firstID }),
              let pointB = mapPointStore.points.first(where: { $0.id == secondID }) else {
            print("❌ Cannot interpolate: missing data")
            return
        }
        
        print("🔨 Creating \(interpolationCount) interpolated Map Point(s)...")
        print("   Point A: \(pointA.mapPoint)")
        print("   Point B: \(pointB.mapPoint)")
        
        // Interpolate in map space
        let mapA = pointA.mapPoint
        let mapB = pointB.mapPoint
        
        for i in 1...interpolationCount {
            let t = CGFloat(i) / CGFloat(interpolationCount + 1)
            let interpolatedMapPoint = CGPoint(
                x: mapA.x + t * (mapB.x - mapA.x),
                y: mapA.y + t * (mapB.y - mapA.y)
            )
            
            // Create new Map Point using existing method (same as green "+" button)
            let success = mapPointStore.addPoint(at: interpolatedMapPoint)
            
            if success {
                print("   ✅ Created Map Point \(i)/\(interpolationCount) at (\(Int(interpolatedMapPoint.x)), \(Int(interpolatedMapPoint.y)))")
            } else {
                print("   ⚠️ Map Point \(i) not created (location occupied)")
            }
        }
        
        // Save all changes
        mapPointStore.save()
        
        print("💾 Saved \(interpolationCount) new Map Point(s)")
        print("🎉 Interpolation complete!")
        
        // Place AR markers at interpolation positions
        placeInterpolatedARMarkers()
    }
    
    private func placeInterpolatedARMarkers() {
        guard let coordinator = ARViewContainer.Coordinator.current,
              let markerA = coordinator.sessionMarkerA?.position,
              let markerB = coordinator.sessionMarkerB?.position else {
            print("❌ Cannot place AR markers: session markers not found")
            return
        }
        
        print("📍 Placing \(interpolationCount) AR marker(s) at interpolation positions...")
        
        // Clear cross-marks
        coordinator.updateInterpolationCrossMarks(count: 0)
        
        // Calculate and place markers
        let direction = markerB - markerA
        
        for i in 1...interpolationCount {
            let t = Float(i) / Float(interpolationCount + 1)
            let position = markerA + t * direction
            
            // Place marker at interpolated position
            coordinator.placeMarker(at: position)
            
            print("   📍 Placed AR marker \(i)/\(interpolationCount)")
        }
        
        print("✅ All interpolation AR markers placed - ready for manual exit")
    }
    
    private func calculateMaxNewMarkers() {
        guard let posA = markerAPosition, let posB = markerBPosition else {
            maxNewMarkers = 0
            return
        }
        
        let distance = simd_distance(posA, posB)
        
        // For N new markers: spacing = distance / (N + 1)
        // Minimum spacing: 1.0m
        // Therefore: N <= floor(distance / 1.0) - 1
        maxNewMarkers = max(0, Int(floor(distance / 1.0)) - 1)
        interpolationCount = min(interpolationCount, maxNewMarkers) // Clamp current value
        
        print("📊 Interpolation: distance=\(String(format: "%.2f", distance))m, max markers=\(maxNewMarkers)")
    }
    
    private func updateCrossMarks() {
        guard let coordinator = ARViewContainer.Coordinator.current else { return }
        coordinator.updateInterpolationCrossMarks(count: interpolationCount)
    }
    
    // MARK: - New Interpolation UI Components
    
    private var bottomButtonSection: some View {
        VStack(spacing: 0) {
            // Slider for interpolation count (only visible after both markers placed)
            if bothMarkersPlaced && maxNewMarkers > 0 {
                VStack(spacing: 8) {
                    Text(interpolationCount == 1 ? "1 new marker" : "\(interpolationCount) new markers")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
                    Slider(
                        value: Binding(
                            get: { Double(interpolationCount) },
                            set: { interpolationCount = Int($0.rounded()) }
                        ),
                        in: 0...Double(maxNewMarkers),
                        step: 1.0,
                        onEditingChanged: { editing in
                            if !editing {
                                // Slider released - update cross-marks
                                updateCrossMarks()
                            }
                        }
                    )
                    .accentColor(.white)
                }
                .padding(.horizontal, ARInterpolationLayout.buttonSideMargin)
                .padding(.bottom, 12)
            }
            
            HStack(spacing: ARInterpolationLayout.buttonGap) {
            // Place Marker A button
            Button(action: placeMarkerA) {
                VStack(spacing: 4) {
                    if markerAPlaced {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                    }
                    Text(markerAPlaced ? "A ✓" : "Marker A")
                        .font(.system(size: ARInterpolationLayout.buttonFontSize, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: ARInterpolationLayout.buttonHeight)
                .background(markerAPlaced ? ARInterpolationLayout.successColor : ARInterpolationLayout.markerAColor)
                .cornerRadius(ARInterpolationLayout.buttonCornerRadius)
            }
            
            // Place Marker B button
            Button(action: placeMarkerB) {
                VStack(spacing: 4) {
                    if markerBPlaced {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                    }
                    Text(markerBPlaced ? "B ✓" : "Marker B")
                        .font(.system(size: ARInterpolationLayout.buttonFontSize, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: ARInterpolationLayout.buttonHeight)
                .background(markerBPlaced ? ARInterpolationLayout.successColor : ARInterpolationLayout.markerBColor)
                .cornerRadius(ARInterpolationLayout.buttonCornerRadius)
            }
            
            // Interpolate button
            Button(action: proceedToInterpolation) {
                VStack(spacing: 4) {
                    Image(systemName: "function")
                        .font(.system(size: 16))
                    Text("Interpolate")
                        .font(.system(size: ARInterpolationLayout.buttonFontSize, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: ARInterpolationLayout.buttonHeight)
                .background(bothMarkersPlaced ? ARInterpolationLayout.interpolateColor : ARInterpolationLayout.interpolateDisabledColor)
                .cornerRadius(ARInterpolationLayout.buttonCornerRadius)
            }
            .disabled(!bothMarkersPlaced)
            }
            .padding(.horizontal, ARInterpolationLayout.buttonSideMargin)
            .padding(.bottom, ARInterpolationLayout.bottomButtonSectionBottomPadding)
        }
    }
    
    private var bothMarkersPlaced: Bool {
        return markerAPlaced && markerBPlaced
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
    
    // Calculate map distance using pixel coordinates and metric square calibration
    private var mapDistance: Float {
        guard let pointA = mapPointStore.points.first(where: { $0.id == interpolationFirstPointID }),
              let pointB = mapPointStore.points.first(where: { $0.id == interpolationSecondPointID }) else {
            print("⚠️ Cannot find map points for distance calculation")
            return 0
        }
        
        // Get pixel coordinates
        let pixelA = pointA.mapPoint
        let pixelB = pointB.mapPoint
        
        // Calculate Euclidean distance in pixels
        let dx = pixelB.x - pixelA.x
        let dy = pixelB.y - pixelA.y
        let pixelDistance = sqrt(dx * dx + dy * dy)
        
        // Calculate map distance if metric square is available
        if let activeSquare = metricSquares.squares.first {
            let pixelsPerMeter = activeSquare.side / activeSquare.meters
            let distanceInMeters = Float(pixelDistance / pixelsPerMeter)
            
            print("📐 Map distance calculation:")
            print("   Point A: (\(Int(pixelA.x)), \(Int(pixelA.y)))")
            print("   Point B: (\(Int(pixelB.x)), \(Int(pixelB.y)))")
            print("   Pixel distance: \(String(format: "%.1f", pixelDistance))")
            print("   Pixels per meter: \(String(format: "%.1f", pixelsPerMeter))")
            print("   Distance in meters: \(String(format: "%.2f", distanceInMeters))m")
            
            return distanceInMeters
        } else {
            print("⚠️ Metric Square Unknown - map distance unavailable")
            print("ℹ️ Proceeding with AR measurements only")
            return 0
        }
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
