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
    @State private var markerPlaced = false
    
    var body: some View {
        ZStack {
            // AR Camera feed
            ARViewContainer(
                mapPointID: mapPointID,
                userHeight: Float(getUserHeight()),
                markerPlaced: $markerPlaced
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
        }
        .zIndex(10000)
        .transition(.move(edge: .leading))
    }
    
    private func getUserHeight() -> Double {
        guard let activePoint = mapPointStore.points.first(where: { $0.id == mapPointID }),
              let lastSession = activePoint.sessions.last else {
            return 1.05 // Default fallback
        }
        return lastSession.deviceHeight_m
    }
}
