//
//  GhostInteractionButtons.swift
//  TapResolver
//
//  Created by Chris Gelles on 11/30/25.
//


//
//  GhostInteractionButtons.swift
//  TapResolver
//
//  Created: Ghost marker confirmation/adjustment UI
//

import SwiftUI

/// Contextual buttons for ghost marker interaction
/// Shows Confirm/Adjust when ghost is selected, otherwise shows standard Place Marker
struct GhostInteractionButtons: View {
    @ObservedObject var arCalibrationCoordinator: ARCalibrationCoordinator
    let onConfirmGhost: () -> Void
    let onPlaceMarker: () -> Void
    
    var body: some View {
        if arCalibrationCoordinator.selectedGhostMapPointID != nil {
            // Ghost selected - show dual buttons
            HStack(spacing: 12) {
                // Confirm button (left, green)
                Button(action: {
                    print("🎯 [GHOST_UI] Confirm Placement tapped")
                    onConfirmGhost()
                }) {
                    Text("Confirm Placement")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(12)
                }
                
                // Adjust button (right, standard material)
                Button(action: {
                    print("🎯 [GHOST_UI] Place Marker to Adjust tapped")
                    onPlaceMarker()
                }) {
                    Text("Place Marker")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.ultraThickMaterial)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
        } else {
            // No ghost selected - show standard button
            Button(action: {
                print("🔍 [PLACE_MARKER_BTN] Button tapped")
                onPlaceMarker()
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
        }
    }
}

#Preview {
    VStack {
        Spacer()
        // Preview with mock coordinator would go here
        Text("GhostInteractionButtons Preview")
        Spacer()
    }
}

