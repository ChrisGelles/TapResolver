//
//  AnchorQualityOverlay.swift
//  TapResolver
//
//  Created by Chris Gelles on 11/6/25.
//

import SwiftUI

struct AnchorQualityOverlay: View {
    let qualityScore: Int  // 0-100
    let instruction: String
    let countdown: Int?  // Optional countdown (3, 2, 1)
    
    private var fillColor: Color {
        switch qualityScore {
        case 0...40:
            return Color(red: 0.75, green: 0.1, blue: 0.1)  // Dark red
        case 41...70:
            return Color(red: 0.75, green: 0.65, blue: 0.1)  // Gold
        default:
            return Color(red: 0.1, green: 0.75, blue: 0.2)  // Forest green
        }
    }
    
    private var displayText: String {
        if let count = countdown {
            return "Saving in \(count)..."
        }
        return instruction
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background capsule
                Capsule()
                    .fill(Color.black.opacity(0.3))
                    .frame(height: 50)
                
                // Progress fill
                Capsule()
                    .fill(fillColor)
                    .frame(width: geometry.size.width * CGFloat(qualityScore) / 100.0, height: 50)
                
                // Instruction text
                Text(displayText)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
            }
            .frame(width: geometry.size.width * 0.8, height: 50)
            .position(x: geometry.size.width / 2, y: 25)
        }
        .frame(height: 50)
    }
}

// MARK: - Preview

struct AnchorQualityOverlay_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            AnchorQualityOverlay(qualityScore: 20, instruction: "Move device slowly to detect surfaces", countdown: nil)
            AnchorQualityOverlay(qualityScore: 55, instruction: "Good! Keep moving to capture more detail", countdown: nil)
            AnchorQualityOverlay(qualityScore: 85, instruction: "Excellent anchor data captured!", countdown: 3)
        }
        .padding()
        .background(Color.gray)
    }
}
