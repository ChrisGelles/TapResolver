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
    let onReposition: () -> Void
    
    var body: some View {
        if arCalibrationCoordinator.selectedGhostMapPointID != nil {
            if arCalibrationCoordinator.repositionModeActive {
                // REPOSITION MODE: Simplified layout - just Place Marker + status indicator
                VStack(spacing: 12) {
                    // Place Marker to Adjust - now the primary action (full width, blue)
                    Button(action: {
                        print("🎯 [GHOST_UI] Place Marker to Adjust tapped (reposition mode)")
                        onPlaceMarker()
                    }) {
                        Text("Place Marker to Adjust")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    
                    // Status indicator - not a button, just informational
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Actively Moving Marker")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.5))
                    .cornerRadius(25)
                }
                .padding(.horizontal)
            } else {
                // NORMAL MODE: Ghost selected AND visible - show three buttons
                VStack(spacing: 12) {
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
                        
                        // Adjust button (right, orange)
                        Button(action: {
                            print("🎯 [GHOST_UI] Place Marker to Adjust tapped")
                            onPlaceMarker()
                        }) {
                            Text("Place Marker to Adjust")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.orange)
                                .cornerRadius(12)
                        }
                    }
                    
                    // Reposition Marker button - for large spaces where ghost is far from correct position
                    Button(action: {
                        print("🎯 [GHOST_UI] Reposition Marker tapped")
                        onReposition()
                    }) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Reposition Marker...")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.purple.opacity(0.9))
                        .cornerRadius(25)
                    }
                }
                .padding(.horizontal)
            }
        } else if arCalibrationCoordinator.nearbyButNotVisibleGhostID != nil {
            // Ghost nearby but NOT visible - show message
            HStack {
                Image(systemName: "location.circle")
                    .foregroundColor(.yellow)
                Text("Unconfirmed Marker Nearby")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding()
            .background(Color.black.opacity(0.7))
            .cornerRadius(12)
            .padding(.horizontal)
        } else {
            // No ghost nearby - show standard Place Marker button
            Button(action: {
                print("🔍 [PLACE_MARKER_BTN] Button tapped")
                onPlaceMarker()
            }) {
                Text("Place Marker")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
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

