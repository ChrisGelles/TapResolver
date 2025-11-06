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
import ARKit

struct CalibrationMarker {
    let mapPointID: UUID
    let mapPoint: CGPoint
    let arPosition: simd_float3
    let placedAt: Date
}

struct ARCalibrationView: View {
    @Binding var isPresented: Bool
    let mapPointID: UUID?  // Optional now - nil in interpolation mode
    let interpolationFirstPointID: UUID?  // First point for interpolation
    let interpolationSecondPointID: UUID?  // Second point for interpolation
    
    @EnvironmentObject private var mapPointStore: MapPointStore
    @EnvironmentObject private var worldMapStore: ARWorldMapStore
    @EnvironmentObject private var metricSquares: MetricSquareStore
    @EnvironmentObject private var locationManager: LocationManager
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
    
    // Calibration mode tracking
    @State private var isCalibrationMode: Bool = false
    @State private var calibrationMarkers: [CalibrationMarker] = []
    @State private var arCoordinator: ARViewContainer.Coordinator?
    
    // Anchor mode tracking
    @State private var isAnchorMode = false
    
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
                interpolationSecondPointID: interpolationSecondPointID,
                isAnchorMode: isAnchorMode
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
                // Normal mode - PiP + Drawer + Close button
                
                // Top row: [controls grid] ---spacer--- [PiP map]
                VStack {
                    HStack(alignment: .top) {
                        // --- Controls grid pinned to LEFT edge ---
                        ControlsGrid(
                            isPresented: $isPresented,
                            isCalibrationMode: $isCalibrationMode,
                            isAnchorMode: $isAnchorMode,
                            calibrationMarkers: $calibrationMarkers
                        )
                        .padding(.leading, ARInterpolationLayout.controlsLeftMargin)
                        .padding(.top, ARInterpolationLayout.pipMapTopMargin)

                        Spacer(minLength: 2) // middle gap managed by the layout

                        // --- PiP Map pinned to RIGHT edge ---
                        PiPMapView(
                            firstPointID: mapPointStore.activePointID,
                            secondPointID: nil,
                            markedPointIDs: markedPointIDs
                        )
                        .environmentObject(mapPointStore)
                        .environmentObject(locationManager)
                        .frame(
                            width: ARInterpolationLayout.pipMapWidth,
                            height: ARInterpolationLayout.pipMapHeight
                        )
                        .clipShape(RoundedRectangle(cornerRadius: ARInterpolationLayout.pipMapCornerRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: ARInterpolationLayout.pipMapCornerRadius)
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        )
                        .padding(.trailing, ARInterpolationLayout.pipMapRightMargin)
                        .padding(.top, ARInterpolationLayout.pipMapTopMargin)
                    }

                    Spacer()
                }
                .zIndex(10001) // stay above AR content

                
                // Map Point Drawer (right side, below PiP)
                VStack {
                    HStack {
                        Spacer()
                        
                        MapPointDrawer()
                            .padding(.top, 40 + ARInterpolationLayout.pipMapHeight + 20)
                            .padding(.trailing, 20)
                    }
                    
                    Spacer()
                }
                .zIndex(5000)
                
                // Place Marker button (bottom center, calibration mode only)
                if isCalibrationMode && mapPointStore.activePointID != nil {
                    VStack {
                        Spacer()
                        
                        Button(action: {
                            placeCalibrationMarker()
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "flag.fill")
                                    .font(.system(size: 28))
                                
                                Text("Place Marker \(calibrationMarkers.count + 1)/3")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.green.opacity(0.9))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                        .padding(.bottom, 60)
                    }
                    .zIndex(10002)
                }
                
                // Anchor mode bottom button
                if isAnchorMode && mapPointStore.activePointID != nil && !hasAnchorMarkerForSelectedPoint() {
                    VStack {
                        Spacer()
                        
                        Button(action: {
                            // Tap handler will place marker
                            print("🔶 Ready to place anchor marker")
                        }) {
                            Text("Tap to Place Anchor Marker")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.cyan)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 50)
                    }
                    .zIndex(10002)
                }
                
                // Calibration progress indicator
                if isCalibrationMode {
                    VStack {
                        HStack {
                            Spacer()
                            
                            HStack(spacing: 8) {
                                ForEach(0..<3, id: \.self) { index in
                                    Circle()
                                        .fill(index < calibrationMarkers.count ? Color.green : Color.white.opacity(0.3))
                                        .frame(width: 12, height: 12)
                                }
                                
                                Text("\(calibrationMarkers.count)/3")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(8)
                            .padding(.top, ARInterpolationLayout.pipMapTopMargin + ARInterpolationLayout.pipMapHeight + 280)
                            .padding(.trailing, 20)
                        }
                        
                        Spacer()
                    }
                    .zIndex(10003)
                }
            }
            
            /*
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
            */
            
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
                
                // Mini map using existing MapContainer infrastructure
                PiPMapView(
                    firstPointID: interpolationFirstPointID,
                    secondPointID: interpolationSecondPointID,
                    markedPointIDs: markedPointIDs
                )
                .environmentObject(mapPointStore)
                .environmentObject(locationManager)
                .frame(
                    width: ARInterpolationLayout.pipMapWidth,
                    height: ARInterpolationLayout.pipMapHeight
                )
                .clipShape(RoundedRectangle(cornerRadius: ARInterpolationLayout.pipMapCornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: ARInterpolationLayout.pipMapCornerRadius)
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                )
                .padding(.top, ARInterpolationLayout.pipMapTopMargin)
                .padding(.trailing, ARInterpolationLayout.pipMapRightMargin)
            }
            Spacer()
        }
    }
    
    private func placeCalibrationMarker() {
        guard let selectedPointID = mapPointStore.activePointID,
              let selectedPoint = mapPointStore.points.first(where: { $0.id == selectedPointID }),
              calibrationMarkers.count < 3 else { return }
        
        // Check if point already has a marker in this calibration
        if calibrationMarkers.contains(where: { $0.mapPointID == selectedPointID }) {
            print("⚠️ This point already has a calibration marker")
            return
        }
        
        // Get the AR coordinator from ARViewContainer.Coordinator.current
        guard let coordinator = ARViewContainer.Coordinator.current else {
            print("❌ No coordinator reference available")
            return
        }
        
        // Place marker using existing placeMarkerAt method (same as interpolation mode)
        coordinator.placeMarkerAt(
            mapPointID: selectedPointID,
            mapPoint: selectedPoint,
            color: UIColor.orange
        )
        
        // Get the AR position from the coordinator's lastPlacedPosition
        guard let arPosition = coordinator.lastPlacedPosition else {
            print("❌ Failed to get AR position from coordinator")
            return
        }
        
        let marker = CalibrationMarker(
            mapPointID: selectedPointID,
            mapPoint: selectedPoint.mapPoint,
            arPosition: arPosition,
            placedAt: Date()
        )
        
        calibrationMarkers.append(marker)
        
        print("📍 Placed calibration marker \(calibrationMarkers.count)/3")
        print("   Map Point: (\(Int(selectedPoint.mapPoint.x)), \(Int(selectedPoint.mapPoint.y)))")
        print("   AR Position: \(arPosition)")
        
        // Check if calibration complete
        if calibrationMarkers.count == 3 {
            performCalibration()
        }
    }
    
    // MARK: - Barycentric Calculation Helpers
    
    private func barycentricWeights(point p: CGPoint, 
                                     triangle: (CGPoint, CGPoint, CGPoint)) -> (w1: Float, w2: Float, w3: Float) {
        let (p1, p2, p3) = triangle
        
        // Convert to Float for calculation
        let px = Float(p.x)
        let py = Float(p.y)
        let p1x = Float(p1.x)
        let p1y = Float(p1.y)
        let p2x = Float(p2.x)
        let p2y = Float(p2.y)
        let p3x = Float(p3.x)
        let p3y = Float(p3.y)
        
        // Calculate area of full triangle using cross product
        let denom = (p2y - p3y) * (p1x - p3x) + (p3x - p2x) * (p1y - p3y)
        
        guard abs(denom) > 0.001 else {
            // Degenerate triangle - return centroid
            return (1.0/3.0, 1.0/3.0, 1.0/3.0)
        }
        
        // Calculate barycentric coordinates
        let w1 = ((p2y - p3y) * (px - p3x) + (p3x - p2x) * (py - p3y)) / denom
        let w2 = ((p3y - p1y) * (px - p3x) + (p1x - p3x) * (py - p3y)) / denom
        let w3 = 1.0 - w1 - w2
        
        return (w1, w2, w3)
    }
    
    private func getFloorPlaneY(from coordinator: ARViewContainer.Coordinator?) -> Float? {
        guard let arView = coordinator?.arView else { return nil }
        
        // Get all detected horizontal planes
        guard let currentFrame = arView.session.currentFrame else { return nil }
        
        let planes = currentFrame.anchors
            .compactMap { $0 as? ARPlaneAnchor }
            .filter { $0.alignment == .horizontal }
        
        // Use the largest plane (most likely the floor)
        let floorPlane = planes.max(by: { $0.extent.x * $0.extent.z < $1.extent.x * $1.extent.z })
        
        return floorPlane?.transform.columns.3.y
    }
    
    private func performCalibration() {
        print("✅ Calibration complete with 3 markers!")
        print("   Calculating AR positions for all MapPoints...")
        
        // Store calibration data in MapPointStore
        mapPointStore.calibrationPoints = calibrationMarkers
        mapPointStore.isCalibrated = true
        
        // Store calibration MapPoint IDs for color differentiation
        let calibrationPointIDs = calibrationMarkers.map { $0.mapPointID }
        
        // Generate AR markers for all MapPoints
        generateARMarkersFromCalibration()
        
        // Render the generated markers in AR scene
        if let coordinator = ARViewContainer.Coordinator.current {
            coordinator.renderGeneratedMarkers(from: mapPointStore, calibrationIDs: calibrationPointIDs)
        }
        
        // Exit calibration mode after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isCalibrationMode = false
            print("🎯 Calibration mode exited - \(mapPointStore.arMarkers.count) markers generated")
        }
    }
    
    private func generateARMarkersFromCalibration() {
        guard calibrationMarkers.count == 3 else {
            print("❌ Need exactly 3 calibration markers")
            return
        }
        
        // Get the 3 calibration points
        let p1_2D = calibrationMarkers[0].mapPoint
        let p2_2D = calibrationMarkers[1].mapPoint
        let p3_2D = calibrationMarkers[2].mapPoint
        
        let P1_3D = calibrationMarkers[0].arPosition
        let P2_3D = calibrationMarkers[1].arPosition
        let P3_3D = calibrationMarkers[2].arPosition
        
        // Get floor plane Y-coordinate from ARKit
        let coordinator = ARViewContainer.Coordinator.current
        let floorY = getFloorPlaneY(from: coordinator) ?? P1_3D.y
        
        // Get user height (use from first calibration marker)
        let userHeight = Float(getUserHeight())
        let markerY = floorY  // Place marker base on floor, structure creates height
        
        print("📏 Floor Y: \(floorY)m, User Height: \(userHeight)m (markers placed on floor)")
        
        // Clear existing generated markers (keep calibration markers separate)
        mapPointStore.arMarkers.removeAll()
        
        // Generate AR marker for each MapPoint
        for point in mapPointStore.points {
            // Calculate barycentric weights in 2D
            let weights = barycentricWeights(
                point: point.mapPoint,
                triangle: (p1_2D, p2_2D, p3_2D)
            )
            
            // Apply weights to horizontal positions (X, Z)
            let arX = weights.w1 * P1_3D.x + weights.w2 * P2_3D.x + weights.w3 * P3_3D.x
            let arZ = weights.w1 * P1_3D.z + weights.w2 * P2_3D.z + weights.w3 * P3_3D.z
            
            // Use fixed height from floor + user height
            let arPosition = simd_float3(arX, markerY, arZ)
            
            // Create AR marker (session-temporary, not persisted)
            let marker = ARMarker(
                linkedMapPointID: point.id,
                arPosition: arPosition,
                mapCoordinates: point.mapPoint
            )
            
            mapPointStore.arMarkers.append(marker)
        }
        
        print("✨ Generated \(mapPointStore.arMarkers.count) AR markers from calibration (includes 3 calibration points)")
        
        // Do NOT call save() - these markers are session-temporary
    }
    
    private var markedPointIDs: Set<UUID> {
        Set(calibrationMarkers.map { $0.mapPointID })
    }
    
    // MARK: - Anchor Helpers
    
    private func hasAnchorMarkerForSelectedPoint() -> Bool {
        guard let selectedID = mapPointStore.activePointID else { return false }
        return mapPointStore.arMarkers.contains { marker in
            marker.linkedMapPointID == selectedID && marker.isAnchor
        }
    }
}

// MARK: - Controls Grid

private struct ControlsGrid: View {
    @Binding var isPresented: Bool
    @Binding var isCalibrationMode: Bool
    @Binding var isAnchorMode: Bool
    @Binding var calibrationMarkers: [CalibrationMarker]
    
    var body: some View {
        let cell = GridItem(.fixed(56), spacing: 12, alignment: .leading)
        
        LazyVGrid(columns: [cell, cell], alignment: .leading, spacing: 12) {
            // 1) Close (X)
            Button {
                withAnimation(.easeInOut(duration: 0.3)) { isPresented = false }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.black.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            
            // 2) Triangle (Calibration)
            Button {
                isCalibrationMode = true
                calibrationMarkers.removeAll()
            } label: {
                Image(systemName: "triangle")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.blue.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            
            // 3) Anchor
            Button {
                isAnchorMode.toggle()
            } label: {
                Text("⚓︎")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(isAnchorMode ? .cyan : .white)
                    .frame(width: 56, height: 56)
                    .background((isAnchorMode ? Color.cyan.opacity(0.3) : Color.blue.opacity(0.8)))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            
            // 4) Placeholder (future slot)
            Color.clear.frame(width: 56, height: 56)
        }
    }
}

// MARK: - PiP Map View

struct PiPMapView: View {
    let firstPointID: UUID?
    let secondPointID: UUID?
    let markedPointIDs: Set<UUID>
    
    @EnvironmentObject private var mapPointStore: MapPointStore
    @EnvironmentObject private var locationManager: LocationManager
    
    @StateObject private var pipTransform = MapTransformStore()
    @StateObject private var pipProcessor = TransformProcessor()
    
    @State private var mapImage: UIImage?
    @State private var isAnimating: Bool = false
    @State private var currentScale: CGFloat = 1.0
    @State private var currentOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geo in
            if let image = mapImage {
                // Calculate target values based on current selection
                let targets = calculateTargetTransform(image: image, geo: geo)
                
                ZStack {
                    MapContainer(mapImage: image)
                        .environmentObject(pipTransform)
                        .environmentObject(pipProcessor)
                        .frame(width: image.size.width, height: image.size.height)
                        .allowsHitTesting(false)
                    
                    // Show ALL map points as context
                    ForEach(mapPointStore.points) { point in
                        let hasMarker = markedPointIDs.contains(point.id)
                        Circle()
                            .fill(hasMarker ? Color.orange : Color.blue.opacity(0.4))
                            .frame(width: hasMarker ? 14 : 12, height: hasMarker ? 14 : 12)
                            .overlay(
                                Circle()
                                    .stroke(Color.black.opacity(1), lineWidth: 2)
                            )
                            .position(point.mapPoint)
                    }
                    
                    // Overlay points based on mode
                    if let pointID = firstPointID,
                       secondPointID == nil,
                       let point = mapPointStore.points.first(where: { $0.id == pointID }) {
                        // Single point dot
                        Circle()
                            .fill(Color.cyan)
                            .frame(width: 12, height: 12)
                            .position(point.mapPoint)
                    } else if let pointA = mapPointStore.points.first(where: { $0.id == firstPointID }),
                              let pointB = mapPointStore.points.first(where: { $0.id == secondPointID }) {
                        // Dual point overlay
                        PiPPointsOverlay(pointA: pointA.mapPoint, pointB: pointB.mapPoint)
                            .frame(width: image.size.width, height: image.size.height)
                    }
                }
                .scaleEffect(currentScale)
                .offset(currentOffset)
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
                .overlay(
                    RoundedRectangle(cornerRadius: ARInterpolationLayout.pipMapCornerRadius)
                        .stroke(Color.cyan, lineWidth: 3)
                )
                .onAppear {
                    setupPiPTransform(image: image, frameSize: geo.size)
                    currentScale = targets.scale
                    currentOffset = targets.offset
                }
                .onChange(of: targets.scale) { newScale in
                    currentScale = newScale
                }
                .onChange(of: targets.offset) { newOffset in
                    currentOffset = newOffset
                }
            } else {
                Rectangle()
                    .fill(Color.blue.opacity(0.3))
            }
        }
        .animation(.easeInOut(duration: 0.5), value: currentScale)
        .animation(.easeInOut(duration: 0.5), value: currentOffset)
        .onAppear {
            loadMapImage()
        }
    }
    
    private func loadMapImage() {
        let locationID = locationManager.currentLocationID
        
        // Try Documents first
        if let image = LocationImportUtils.loadDisplayImage(locationID: locationID) {
            mapImage = image
            return
        }
        
        // Fallback to bundled assets
        let assetName: String
        switch locationID {
        case "home": assetName = "myFirstFloor_v03-metric"
        case "museum": assetName = "MuseumMap-8k"
        default: return
        }
        
        mapImage = UIImage(named: assetName)
    }
    
    private func setupPiPTransform(image: UIImage, frameSize: CGSize) {
        pipProcessor.setMapSize(CGSize(width: image.size.width, height: image.size.height))
        pipProcessor.setScreenCenter(CGPoint(x: frameSize.width / 2, y: frameSize.height / 2))
    }
    
    private func calculateTargetTransform(image: UIImage, geo: GeometryProxy) -> (scale: CGFloat, offset: CGSize) {
        let frameSize = geo.size
        let imageSize = image.size
        
        // Calculate scale and offset based on current selection state
        if let pointID = firstPointID,
           secondPointID == nil,
           let point = mapPointStore.points.first(where: { $0.id == pointID }) {
            // Single point mode - create fake corners around point
            let regionSize: CGFloat = 400
            let cornerA = CGPoint(x: point.mapPoint.x - regionSize/2, y: point.mapPoint.y - regionSize/2)
            let cornerB = CGPoint(x: point.mapPoint.x + regionSize/2, y: point.mapPoint.y + regionSize/2)
            
            let scale = calculateScale(pointA: cornerA, pointB: cornerB, frameSize: frameSize, imageSize: imageSize)
            let offset = calculateOffset(pointA: cornerA, pointB: cornerB, frameSize: frameSize, imageSize: imageSize)
            return (scale, offset)
            
        } else if let pointA = mapPointStore.points.first(where: { $0.id == firstPointID }),
                  let pointB = mapPointStore.points.first(where: { $0.id == secondPointID }) {
            // Dual point mode
            let scale = calculateScale(pointA: pointA.mapPoint, pointB: pointB.mapPoint, frameSize: frameSize, imageSize: imageSize)
            let offset = calculateOffset(pointA: pointA.mapPoint, pointB: pointB.mapPoint, frameSize: frameSize, imageSize: imageSize)
            return (scale, offset)
            
        } else {
            // No selection - show full map using corners
            let cornerA = CGPoint(x: 0, y: 0)
            let cornerB = CGPoint(x: imageSize.width, y: imageSize.height)
            
            let scale = calculateScale(pointA: cornerA, pointB: cornerB, frameSize: frameSize, imageSize: imageSize)
            let offset = calculateOffset(pointA: cornerA, pointB: cornerB, frameSize: frameSize, imageSize: imageSize)
            return (scale, offset)
        }
    }
    
    private func calculateScale(pointA: CGPoint, pointB: CGPoint, frameSize: CGSize, imageSize: CGSize) -> CGFloat {
        /*
        print("🔍 PiP Scale Calculation:")
        print("   Point A: (\(Int(pointA.x)), \(Int(pointA.y)))")
        print("   Point B: (\(Int(pointB.x)), \(Int(pointB.y)))")
        print("   PiP frame size: \(Int(frameSize.width))x\(Int(frameSize.height))")
        print("   Map image size: \(Int(imageSize.width))x\(Int(imageSize.height))")
        */
        
        // Calculate center point between A and B
        let centerX = (pointA.x + pointB.x) / 2
        let centerY = (pointA.y + pointB.y) / 2
        
        // Calculate max distances from center to either point
        let maxXDistance = max(abs(pointA.x - centerX), abs(pointB.x - centerX))
        let maxYDistance = max(abs(pointA.y - centerY), abs(pointB.y - centerY))
        
        // Add padding (10% extra space around points)
        let paddingFactor: CGFloat = 1.1
        let paddedXDistance = maxXDistance * 2 * paddingFactor
        let paddedYDistance = maxYDistance * 2 * paddingFactor
        
        // Calculate scale factors for each dimension
        let scaleX = frameSize.width / paddedXDistance
        let scaleY = frameSize.height / paddedYDistance
        
        // Use the smaller scale to ensure both points fit
        let finalScale = min(scaleX, scaleY)
        
        /*
        print("   Center point: (\(Int(centerX)), \(Int(centerY)))")
        print("   Max X distance: \(Int(maxXDistance)), padded: \(Int(paddedXDistance))")
        print("   Max Y distance: \(Int(maxYDistance)), padded: \(Int(paddedYDistance))")
        print("   Scale X: \(String(format: "%.3f", scaleX))")
        print("   Scale Y: \(String(format: "%.3f", scaleY))")
        print("   Final scale: \(String(format: "%.3f", finalScale))")
        */
        
        return finalScale
    }
    
    private func calculateOffset(pointA: CGPoint, pointB: CGPoint, frameSize: CGSize, imageSize: CGSize) -> CGSize {
        let scale = calculateScale(pointA: pointA, pointB: pointB, frameSize: frameSize, imageSize: imageSize)
        
        // Calculate average of the two points (center between them)
        let Xavg = (pointA.x + pointB.x) / 2
        let Yavg = (pointA.y + pointB.y) / 2
        
        // Image center (assuming 2048x2048)
        let imageCenter = imageSize.width / 2
        
        // Offset from image center to average point
        let offsetFromImageCenter_X = imageCenter - Xavg
        let offsetFromImageCenter_Y = imageCenter - Yavg
        
        // Apply scale factor
        let offsetX = offsetFromImageCenter_X * scale
        let offsetY = offsetFromImageCenter_Y * scale
        
        /*
        print("🎯 PiP Offset Calculation:")
        print("   Point A: (\(Int(pointA.x)), \(Int(pointA.y)))")
        print("   Point B: (\(Int(pointB.x)), \(Int(pointB.y)))")
        print("   Xavg: \(Int(Xavg)), Yavg: \(Int(Yavg))")
        print("   Image center: \(Int(imageCenter))")
        print("   Offset from image center: (\(Int(offsetFromImageCenter_X)), \(Int(offsetFromImageCenter_Y)))")
        print("   Scale: \(String(format: "%.3f", scale))")
        print("   Final offset (scaled): (\(Int(offsetX)), \(Int(offsetY)))")
        */
        
        return CGSize(width: offsetX, height: offsetY)
    }
}

struct PiPPointsOverlay: View {
    let pointA: CGPoint
    let pointB: CGPoint
    
    var body: some View {
        ZStack {
            // Line between points
            Path { path in
                path.move(to: pointA)
                path.addLine(to: pointB)
            }
            .stroke(Color.white, lineWidth: 2)
            
            // Point A (orange)
            Circle()
                .fill(Color.orange)
                .frame(width: 12, height: 12)
                .position(pointA)
            
            // Point B (green)
            Circle()
                .fill(Color.green)
                .frame(width: 12, height: 12)
                .position(pointB)
        }
    }
}
