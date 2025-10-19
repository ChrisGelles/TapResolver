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
    
    var body: some View {
        ZStack {
            // Black semi-transparent background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            // Close button (upper-left)
            VStack {
                HStack {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.white)
                            .padding(20)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
                
                Spacer()
            }
        }
        .zIndex(10000)
        .transition(.move(edge: .leading))
    }
}
