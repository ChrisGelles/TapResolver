//
//  ARViewWithOverlays.swift
//  TapResolver
//
//  Unified AR view wrapper that includes ARViewContainer with UI overlays
//  This is the ONLY way to present AR - no separate calibration views
//

import SwiftUI
import UIKit
import Combine
import simd

struct ARViewWithOverlays: View {
    @Binding var isPresented: Bool
    @State private var currentMode: ARMode = .idle
    
    // Calibration mode properties
    var isCalibrationMode: Bool = false
    var selectedTriangle: TrianglePatch? = nil
    
    @EnvironmentObject private var mapPointStore: MapPointStore
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var arCalibrationCoordinator: ARCalibrationCoordinator
    @EnvironmentObject private var arWorldMapStore: ARWorldMapStore
    
    // Relocalization coordinator for strategy selection (developer UI)
    @StateObject private var relocalizationCoordinator: RelocalizationCoordinator
    
    init(isPresented: Binding<Bool>, isCalibrationMode: Bool = false, selectedTriangle: TrianglePatch? = nil) {
        self._isPresented = isPresented
        self.isCalibrationMode = isCalibrationMode
        self.selectedTriangle = selectedTriangle
        
        // Initialize with temporary store, will be updated in onAppear
        let tempStore = ARWorldMapStore()
        _relocalizationCoordinator = StateObject(wrappedValue: RelocalizationCoordinator(arStore: tempStore))
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // AR View Container
            ARViewContainer(
                mode: $currentMode,
                isCalibrationMode: isCalibrationMode,
                selectedTriangle: selectedTriangle,
                onDismiss: {
                    isPresented = false
                }
            )
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                // Update relocalization coordinator to use actual store
                relocalizationCoordinator.updateARStore(arWorldMapStore)
                
                // Debug: Print instance and mode
                let instanceAddress = Unmanaged.passUnretained(self as AnyObject).toOpaque()
                
                // Set mode based on calibration mode
                if isCalibrationMode, let triangle = selectedTriangle {
                    currentMode = .triangleCalibration(triangleID: triangle.id)
                    print("🧪 ARView ID: triangle calibration mode for \(String(triangle.id.uuidString.prefix(8)))")
                    print("🧪 ARViewWithOverlays instance: \(instanceAddress)")
                    // Initialize coordinator for this triangle
                    arCalibrationCoordinator.startCalibration(for: triangle.id)
                    // Set vertices for legacy compatibility
                    arCalibrationCoordinator.setVertices(triangle.vertexIDs)
                } else {
                    currentMode = .idle
                    print("🧪 ARView ID: generic/idle mode")
                    print("🧪 ARViewWithOverlays instance: \(instanceAddress)")
                }
            }
            .onDisappear {
                // Clean up on dismiss
                currentMode = .idle
                arCalibrationCoordinator.reset()
                print("🧹 ARViewWithOverlays: Cleaned up on disappear")
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ARMarkerPlaced"))) { notification in
                // Handle marker placement in calibration mode
                guard isCalibrationMode,
                      let triangle = selectedTriangle,
                      let markerID = notification.userInfo?["markerID"] as? UUID,
                      let positionArray = notification.userInfo?["position"] as? [Float],
                      positionArray.count == 3 else {
                    return
                }
                
                // Get current vertex being calibrated
                guard let currentVertexID = arCalibrationCoordinator.getCurrentVertexID() else {
                    print("⚠️ No current vertex ID for marker placement")
                    return
                }
                
                // Check if photo is outdated and needs replacement
                if let mapPoint = mapPointStore.points.first(where: { $0.id == currentVertexID }),
                   mapPoint.photoOutdated == true {
                    // Auto-capture new photo from AR camera feed
                    if let coordinator = ARViewContainer.Coordinator.current {
                        coordinator.captureARFrame { image in
                            guard let image = image else {
                                print("⚠️ Failed to capture AR frame for photo replacement")
                                return
                            }
                            
                            // Convert UIImage to Data
                            if let imageData = image.jpegData(compressionQuality: 0.8) {
                                // Save photo and update metadata
                                if mapPointStore.savePhotoToDisk(for: currentVertexID, photoData: imageData) {
                                    // Update capture position to current position
                                    if let index = mapPointStore.points.firstIndex(where: { $0.id == currentVertexID }) {
                                        mapPointStore.points[index].photoCapturedAtPosition = mapPoint.mapPoint
                                        mapPointStore.points[index].photoOutdated = false
                                        mapPointStore.save()
                                    }
                                    print("📸 Auto-replaced outdated photo for MapPoint \(String(currentVertexID.uuidString.prefix(8)))")
                                }
                            }
                        }
                    }
                }
                
                // Create ARMarker
                let arPosition = simd_float3(positionArray[0], positionArray[1], positionArray[2])
                let mapPoint = mapPointStore.points.first(where: { $0.id == currentVertexID })
                let mapCoordinates = mapPoint?.mapPoint ?? CGPoint.zero
                
                let marker = ARMarker(
                    id: markerID,
                    linkedMapPointID: currentVertexID,
                    arPosition: arPosition,
                    mapCoordinates: mapCoordinates,
                    isAnchor: false
                )
                
                // Register with coordinator
                arCalibrationCoordinator.registerMarker(mapPointID: currentVertexID, marker: marker)
                
                print("✅ Registered marker \(String(markerID.uuidString.prefix(8))) for vertex \(String(currentVertexID.uuidString.prefix(8)))")
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UpdateMapPointPhoto"))) { notification in
                // Handle photo update request
                guard let mapPointID = notification.userInfo?["mapPointID"] as? UUID else {
                    print("⚠️ No mapPointID in UpdateMapPointPhoto notification")
                    return
                }
                
                // Trigger photo capture flow (for now, just log - can be enhanced with camera picker)
                print("📸 Photo update requested for MapPoint \(String(mapPointID.uuidString.prefix(8)))")
                // TODO: Integrate with photo capture UI when available
                // For now, this notification can be handled by external photo capture flow
            }
            
            // Exit button (top-left) - always visible
            Button(action: {
                isPresented = false
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
                    .padding(.top, 50)
                    .padding(.leading, 16)
            }
            .zIndex(1000)
            
            // PiP Map (top-right) - always visible
            ARPiPMapView()
                .environmentObject(mapPointStore)
                .environmentObject(locationManager)
                .frame(width: 180, height: 180)
                .cornerRadius(12)
                .padding(.top, 50)
                .padding(.trailing, 20)
                .zIndex(998)
            
            // Reference image PiP (bottom-left) - only in calibration mode
            // Positioned to avoid overlap with PiP Map (top-right) and exit button (top-left)
            if isCalibrationMode,
               let triangle = selectedTriangle,
               let currentVertexID = arCalibrationCoordinator.getCurrentVertexID(),
               let mapPoint = mapPointStore.points.first(where: { $0.id == currentVertexID }) {
                
                // Try to load photo from disk first, fall back to memory
                let photoData: Data? = {
                    if let diskData = mapPointStore.loadPhotoFromDisk(for: currentVertexID) {
                        return diskData
                    } else {
                        return mapPoint.locationPhotoData
                    }
                }()
                
                if let photoData = photoData,
                   let uiImage = UIImage(data: photoData) {
                    ARReferenceImageView(
                        image: uiImage,
                        mapPoint: mapPoint,
                        isOutdated: mapPoint.photoOutdated ?? false
                    )
                    .zIndex(999)
                }
            }
            
            // Tap-to-Place Button (bottom) - only in calibration mode
            if isCalibrationMode {
                VStack {
                    Spacer()
                    
                    // Progress dots indicator
                    HStack(spacing: 8) {
                        Circle()
                            .fill(arCalibrationCoordinator.progressDots.0 ? Color.green : Color.gray)
                            .frame(width: 12, height: 12)
                        Circle()
                            .fill(arCalibrationCoordinator.progressDots.1 ? Color.green : Color.gray)
                            .frame(width: 12, height: 12)
                        Circle()
                            .fill(arCalibrationCoordinator.progressDots.2 ? Color.green : Color.gray)
                            .frame(width: 12, height: 12)
                    }
                    .padding(.bottom, 8)
                    
                    // Status text
                    Text(arCalibrationCoordinator.statusText)
                        .font(.footnote)
                        .foregroundColor(.white)
                        .padding(.bottom, 8)
                    
                    // Place Marker button
                    Button(action: {
                        NotificationCenter.default.post(
                            name: NSNotification.Name("PlaceMarkerAtCursor"),
                            object: nil
                        )
                    }) {
                        Text("Place Marker")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.ultraThickMaterial)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 60)
                }
                .zIndex(997)
            }
            
            // Place AR Marker Button + Strategy Picker (bottom) - only in idle mode
            if currentMode == .idle {
                VStack {
                    Spacer()
                    
                    // Strategy Picker (developer UI)
                    VStack(spacing: 8) {
                        Text("Relocalization Strategy")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Picker("Strategy", selection: Binding(
                            get: { relocalizationCoordinator.selectedStrategyName },
                            set: { newName in
                                relocalizationCoordinator.selectedStrategyName = newName
                                // Update selectedStrategyID to match
                                if let strategy = relocalizationCoordinator.availableStrategies.first(where: { $0.displayName == newName }) {
                                    relocalizationCoordinator.selectedStrategyID = strategy.id
                                }
                            }
                        )) {
                            ForEach(relocalizationCoordinator.availableStrategies, id: \.id) { strategy in
                                Text(strategy.displayName).tag(strategy.displayName)
                            }
                        }
                        .pickerStyle(.segmented)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 12)
                    
                    Button(action: {
                        NotificationCenter.default.post(
                            name: NSNotification.Name("PlaceMarkerAtCursor"),
                            object: nil
                        )
                    }) {
                        Text("Place AR Marker")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.ultraThickMaterial)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 60)
                }
                .zIndex(997)
            }
        }
    }
}

// MARK: - PiP Map View (migrated from ARCalibrationView)

struct ARPiPMapView: View {
    @EnvironmentObject private var mapPointStore: MapPointStore
    @EnvironmentObject private var locationManager: LocationManager
    @State private var mapImage: UIImage?
    
    var body: some View {
        Group {
            if let mapImage = mapImage {
                Image(uiImage: mapImage)
                    .resizable()
                    .scaledToFit()
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    )
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Text("Loading Map...")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.caption)
                    )
            }
        }
        .onAppear {
            loadMapImage()
        }
        .onChange(of: locationManager.currentLocationID) { _ in
            loadMapImage()
        }
    }
    
    private func loadMapImage() {
        let locationID = locationManager.currentLocationID
        
        // Try loading from Documents first
        if let image = LocationImportUtils.loadDisplayImage(locationID: locationID) {
            mapImage = image
            return
        }
        
        // Fallback to bundled assets
        let assetName: String
        switch locationID {
        case "home":
            assetName = "myFirstFloor_v03-metric"
        case "museum":
            assetName = "MuseumMap-8k"
        default:
            mapImage = nil
            return
        }
        
        mapImage = UIImage(named: assetName)
    }
}

