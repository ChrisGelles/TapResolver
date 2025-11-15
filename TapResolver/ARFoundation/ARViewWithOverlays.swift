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
            
            // Reference image PiP (top-left, below exit button) - only in calibration mode
            if isCalibrationMode,
               let triangle = selectedTriangle,
               let firstVertexID = triangle.vertexIDs.first,
               let mapPoint = mapPointStore.points.first(where: { $0.id == firstVertexID }) {
                
                // Try to load photo from disk first, fall back to memory
                let photoData: Data? = {
                    if let diskData = mapPointStore.loadPhotoFromDisk(for: firstVertexID) {
                        return diskData
                    } else {
                        return mapPoint.locationPhotoData
                    }
                }()
                
                if let photoData = photoData,
                   let uiImage = UIImage(data: photoData) {
                    ARReferenceImageView(image: uiImage)
                        .zIndex(999)
                }
            }
            
            // PiP Map (top-right) - always visible
            ARPiPMapView()
                .environmentObject(mapPointStore)
                .environmentObject(locationManager)
                .frame(width: 150, height: 150)
                .cornerRadius(12)
                .padding(.top, 50)
                .padding(.trailing, 20)
                .zIndex(998)
            
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

