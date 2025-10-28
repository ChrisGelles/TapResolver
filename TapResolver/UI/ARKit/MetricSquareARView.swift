//
//  MetricSquareARView.swift
//  TapResolver
//
//  Role: AR calibration interface for Metric Squares
//

import SwiftUI
import Foundation

struct MetricSquareARView: View {
    @Binding var isPresented: Bool
    let squareID: UUID
    
    @EnvironmentObject private var metricSquares: MetricSquareStore
    @EnvironmentObject private var worldMapStore: ARWorldMapStore
    @EnvironmentObject private var mapPointStore: MapPointStore
    @State private var relocalizationStatus: String = ""
    @State private var selectedMarkerID: UUID? = nil
    
    var body: some View {
        ZStack {
            // AR Camera feed with square placement
            if let square = metricSquares.squares.first(where: { $0.id == squareID }) {
                ARViewContainer(
                    mapPointID: UUID(),
                    userHeight: 0,
                    markerPlaced: .constant(false),
                    metricSquareID: square.id,
                    squareColor: UIColor(square.color),
                    squareSideMeters: square.meters,
                    worldMapStore: worldMapStore,
                    relocalizationStatus: $relocalizationStatus,
                    mapPointStore: mapPointStore,
                    selectedMarkerID: $selectedMarkerID
                )
                .ignoresSafeArea()
            }
            
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
        }
        .zIndex(10000)
        .transition(.move(edge: .leading))
    }
}

