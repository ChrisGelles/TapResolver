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
                // Normal mode - PiP + Drawer + Close button
                
                // Close button (upper-left)
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
                
                // PiP Map (upper right)
                VStack {
                    HStack {
                        Spacer()
                        
                        PiPMapView(
                            firstPointID: mapPointStore.activePointID,
                            secondPointID: nil
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
                        .padding(.top, 40)
                        .padding(.trailing, ARInterpolationLayout.pipMapRightMargin)
                    }
                    
                    Spacer()
                }
                .zIndex(5000)
                
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
                
                // Mini map using existing MapContainer infrastructure
                PiPMapView(
                    firstPointID: interpolationFirstPointID,
                    secondPointID: interpolationSecondPointID
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
}

// MARK: - PiP Map View

struct PiPMapView: View {
    let firstPointID: UUID?
    let secondPointID: UUID?
    
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
                        Circle()
                            .fill(Color.white.opacity(0.6))
                            .frame(width: 6, height: 6)
                            .overlay(
                                Circle()
                                    .stroke(Color.black.opacity(0.8), lineWidth: 1)
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
        print("🔍 PiP Scale Calculation:")
        print("   Point A: (\(Int(pointA.x)), \(Int(pointA.y)))")
        print("   Point B: (\(Int(pointB.x)), \(Int(pointB.y)))")
        print("   PiP frame size: \(Int(frameSize.width))x\(Int(frameSize.height))")
        print("   Map image size: \(Int(imageSize.width))x\(Int(imageSize.height))")
        
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
        
        print("   Center point: (\(Int(centerX)), \(Int(centerY)))")
        print("   Max X distance: \(Int(maxXDistance)), padded: \(Int(paddedXDistance))")
        print("   Max Y distance: \(Int(maxYDistance)), padded: \(Int(paddedYDistance))")
        print("   Scale X: \(String(format: "%.3f", scaleX))")
        print("   Scale Y: \(String(format: "%.3f", scaleY))")
        print("   Final scale: \(String(format: "%.3f", finalScale))")
        
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
        
        print("🎯 PiP Offset Calculation:")
        print("   Point A: (\(Int(pointA.x)), \(Int(pointA.y)))")
        print("   Point B: (\(Int(pointB.x)), \(Int(pointB.y)))")
        print("   Xavg: \(Int(Xavg)), Yavg: \(Int(Yavg))")
        print("   Image center: \(Int(imageCenter))")
        print("   Offset from image center: (\(Int(offsetFromImageCenter_X)), \(Int(offsetFromImageCenter_Y)))")
        print("   Scale: \(String(format: "%.3f", scale))")
        print("   Final offset (scaled): (\(Int(offsetX)), \(Int(offsetY)))")
        
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
