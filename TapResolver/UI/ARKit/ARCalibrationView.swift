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

struct ARCalibrationView: View {
    @Binding var isPresented: Bool
    let mapPointID: UUID
    
    @EnvironmentObject private var mapPointStore: MapPointStore
    @EnvironmentObject private var worldMapStore: ARWorldMapStore
    @State private var markerPlaced = false
    @State private var relocalizationStatus: String = ""
    @State private var selectedMarkerID: UUID?
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        ZStack {
            // AR Camera feed
            ARViewContainer(
                mapPointID: mapPointID,
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
            
            // Delete button for selected marker
            if selectedMarkerID != nil {
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
        guard let activePoint = mapPointStore.points.first(where: { $0.id == mapPointID }),
              let lastSession = activePoint.sessions.last else {
            return 1.05 // Default fallback
        }
        return lastSession.deviceHeight_m
    }
}
