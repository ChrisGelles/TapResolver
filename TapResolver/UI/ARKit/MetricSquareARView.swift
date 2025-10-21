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
    
    var body: some View {
        ZStack {
            // AR Camera feed with square placement
            if let square = metricSquares.squares.first(where: { $0.id == squareID }) {
                ARViewContainer(
                    mapPointID: UUID(), // Unused in square mode
                    userHeight: 0, // Unused in square mode
                    markerPlaced: .constant(false), // Unused in square mode
                    metricSquareID: square.id,
                    squareColor: UIColor(square.color),
                    squareSideMeters: square.meters
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
        }
        .zIndex(10000)
        .transition(.move(edge: .leading))
    }
}

