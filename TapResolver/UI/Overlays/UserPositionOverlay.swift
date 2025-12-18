//
//  UserPositionOverlay.swift
//  TapResolver
//
//  Renders the user's current position on the map as a pulsing dot.
//  Used by both main MapContainer and PiP Map.
//

import SwiftUI

struct UserPositionOverlay: View {
    /// The user's position in map-local coordinates (pixels)
    let userPosition: CGPoint?
    
    /// Whether to show the overlay (respects toggle settings)
    let isEnabled: Bool
    
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            if isEnabled, let pos = userPosition {
                userPositionDot
                    .position(pos)
            }
        }
    }
    
    @ViewBuilder
    private var userPositionDot: some View {
        ZStack {
            // Base dot - purple
            Circle()
                .fill(Color(red: 103/255, green: 31/255, blue: 121/255))
                .frame(width: 15, height: 15)
            
            // Pulse animation ring - cyan
            Circle()
                .stroke(Color(red: 73/255, green: 206/255, blue: 248/255), lineWidth: 2)
                .frame(width: 15, height: 15)
                .scaleEffect(isAnimating ? 22.0/15.0 : 1.0)
                .opacity(isAnimating ? 0.0 : 0.5)
        }
        .onAppear {
            withAnimation(Animation.easeOut(duration: 1.0).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
        .onDisappear {
            isAnimating = false
        }
    }
}

