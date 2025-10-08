//
//  ScanQualityDisplayView.swift
//  TapResolver
//
//  Displays real-time scan quality with master donut and beacon grid
//

import SwiftUI

struct ScanQualityDisplayView: View {
    let viewModel: ScanQualityViewModel
    
    // Grid layout configuration
    private let columns = [
        GridItem(.adaptive(minimum: 32, maximum: 32), spacing: 8)
    ]
    
    var body: some View {
        HStack(spacing: 16) {
            // Left: Master donut with count
            masterDonut
                .frame(width: 56, height: 56)
            
            // Right: Beacon grid (2 rows visible + peek of 3rd)
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(viewModel.beacons) { beacon in
                        BeaconDotView(beacon: beacon)
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(height: 96) // Shows 2 full rows + peek of 3rd
            .clipped()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black.opacity(0.6))
        )
    }
    
    // MARK: - Master Donut
    
    private var masterDonut: some View {
        ZStack {
            // Background ring (unfilled portion)
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 6)
            
            // Filled ring (detection progress, color-coded by quality)
            Circle()
                .trim(from: 0, to: viewModel.detectionFraction)
                .stroke(viewModel.masterDonutColor, lineWidth: 6)
                .rotationEffect(.degrees(-90)) // Start from top
                .animation(.easeInOut(duration: 0.3), value: viewModel.detectionFraction)
            
            // Center text: "8/13"
            Text("\(viewModel.detectedCount)/\(viewModel.totalBeacons)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Beacon Dot with Quality Ring

struct BeaconDotView: View {
    let beacon: ScanQualityViewModel.BeaconStatus
    
    var body: some View {
        ZStack {
            // Outer quality ring
            Circle()
                .trim(from: 0, to: beacon.stabilityPercent)
                .stroke(beacon.signalQuality.color, lineWidth: 2.5)
                .frame(width: 24, height: 24)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: beacon.stabilityPercent)
            
            // Inner beacon dot
            Circle()
                .fill(beacon.color)
                .frame(width: 18, height: 18)
                .overlay(
                    Text(beacon.prefix)
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                        .shadow(color: .white.opacity(0.3), radius: 0.5, x: 0, y: 0)
                )
        }
        .opacity(beacon.signalQuality == .none ? 0.3 : 1.0) // Dim undetected beacons
        .animation(.easeInOut(duration: 0.2), value: beacon.signalQuality)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        ScanQualityDisplayView(viewModel: .dummyData)
            .frame(maxWidth: 400)
        
        Text("Preview with dummy data")
            .font(.caption)
            .foregroundColor(.white.opacity(0.7))
    }
    .padding()
    .background(Color.black)
}
