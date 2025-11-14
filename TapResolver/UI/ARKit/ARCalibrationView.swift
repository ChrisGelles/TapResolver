import SwiftUI
import UIKit

struct ARCalibrationView: View {
    @Binding var isPresented: Bool
    @State private var currentMode: ARMode = .idle
    @State private var coordinator: ARViewContainer.ARViewCoordinator?
    
    @EnvironmentObject private var mapPointStore: MapPointStore
    @EnvironmentObject private var locationManager: LocationManager
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            ARViewContainer(mode: $currentMode)
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    // Capture coordinator reference for button access
                    // Note: This is a workaround - in production, use proper coordinator access
                }

            // Exit button (top-left)
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

            // Reference image PiP (top-left, below exit button)
            if case .calibration(let pointID) = currentMode,
               let mapPoint = mapPointStore.points.first(where: { $0.id == pointID }),
               let photoData = mapPoint.locationPhotoData,
               let uiImage = UIImage(data: photoData) {
                ARReferenceImageView(image: uiImage)
                    .zIndex(999)
            }

            // PiP Map (top-right)
            ARPiPMapView()
                .environmentObject(mapPointStore)
                .environmentObject(locationManager)
                .frame(width: 150, height: 150)
                .cornerRadius(12)
                .padding(.top, 50)
                .padding(.trailing, 20)
                .zIndex(998)

            // Tap-to-Place Button (bottom)
            VStack {
                Spacer()
                Button(action: {
                    // Place marker at current cursor position
                    // Note: This requires coordinator access - will be improved in Phase 5.2
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

            // Test mode button (temporary)
            VStack {
                Spacer()
                Button("Enter Calibration Mode") {
                    currentMode = .calibration(mapPointID: UUID())
                }
                .padding()
                .background(Color.black.opacity(0.5))
                .cornerRadius(12)
                .padding(.bottom, 140)
            }
            .zIndex(996)
        }
        .onDisappear {
            // Clear AR Mode & Coordinator State on Exit
            currentMode = .idle
            print("🧹 ARCalibrationView: Cleaned up on disappear")
        }
    }
}

// Simple PiP Map View for AR overlay
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
