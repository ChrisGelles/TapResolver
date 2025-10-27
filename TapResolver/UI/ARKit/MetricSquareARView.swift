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
                    mapPointStore: mapPointStore
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
                    
                    HStack {
                        if relocalizationStatus.contains("✅") {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        
                        Text(relocalizationStatus)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
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

