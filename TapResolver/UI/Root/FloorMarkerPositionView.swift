//
//  FloorMarkerPositionView.swift
//  TapResolver
//
//  Created by Chris Gelles on 11/8/25.
//


import SwiftUI

struct FloorMarkerPositionView: View {
    let floorImage: UIImage
    let onConfirm: (CGPoint) -> Void
    let onCancel: () -> Void
    
    @State private var imageOffset: CGSize = .zero
    @State private var lastDragValue: CGSize = .zero  // Track last drag position
    @State private var imageScale: CGFloat = 1.0
    @State private var lastScaleValue: CGFloat = 1.0  // Track last scale
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black.ignoresSafeArea()
                
                // Floor image (pannable)
                Image(uiImage: floorImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(imageScale)
                    .offset(imageOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                // Calculate incremental change from last position
                                let deltaX = value.translation.width - lastDragValue.width
                                let deltaY = value.translation.height - lastDragValue.height
                                
                                imageOffset = CGSize(
                                    width: imageOffset.width + deltaX,
                                    height: imageOffset.height + deltaY
                                )
                                
                                lastDragValue = value.translation
                            }
                            .onEnded { _ in
                                // Reset tracking when drag ends
                                lastDragValue = .zero
                            }
                    )
                    .simultaneousGesture(
                        MagnificationGesture()
                            .onChanged { value in
                                // Calculate relative scale change
                                let delta = value / lastScaleValue
                                let newScale = imageScale * delta
                                imageScale = max(0.5, min(newScale, 3.0))
                                lastScaleValue = value
                            }
                            .onEnded { _ in
                                // Reset scale tracking
                                lastScaleValue = 1.0
                            }
                    )
                
                // Fixed crosshairs in center
                CrosshairsOverlay()
                
                // Instructions
                VStack {
                    Text("Position Floor Marker")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                    
                    Spacer()
                    
                    Text("Pan image to align crosshairs with anchor point")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                    
                    Spacer().frame(height: 20)
                    
                    // Action buttons
                    HStack(spacing: 20) {
                        Button("Cancel") {
                            onCancel()
                        }
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        
                        Button("Confirm Position") {
                            let coordinates = calculateCrosshairPosition(
                                in: geometry.size,
                                imageSize: floorImage.size
                            )
                            onConfirm(coordinates)
                        }
                        .padding()
                        .background(Color.green.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
    }
    
    private func calculateCrosshairPosition(in viewSize: CGSize, imageSize: CGSize) -> CGPoint {
        // Calculate where the crosshairs (center of screen) map to on the image
        // Returns normalized coordinates (0.0-1.0)
        
        let center = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2)
        
        let baseScale = min(viewSize.width / max(imageSize.width, 1),
                            viewSize.height / max(imageSize.height, 1))
        let scaledSize = CGSize(width: imageSize.width * baseScale * imageScale,
                                height: imageSize.height * baseScale * imageScale)
        
        let letterboxOffset = CGSize(
            width: (viewSize.width - scaledSize.width) / 2,
            height: (viewSize.height - scaledSize.height) / 2
        )
        
        let adjustedX = center.x - letterboxOffset.width - imageOffset.width
        let adjustedY = center.y - letterboxOffset.height - imageOffset.height
        
        let imageX = adjustedX / (baseScale * imageScale)
        let imageY = adjustedY / (baseScale * imageScale)
        
        let normalizedX = imageX / max(imageSize.width, 1)
        let normalizedY = imageY / max(imageSize.height, 1)
        
        return CGPoint(
            x: max(0.0, min(1.0, normalizedX)),
            y: max(0.0, min(1.0, normalizedY))
        )
    }
}

struct CrosshairsOverlay: View {
    var body: some View {
        ZStack {
            // Horizontal line
            Rectangle()
                .fill(Color.cyan)
                .frame(height: 2)
            
            // Vertical line
            Rectangle()
                .fill(Color.cyan)
                .frame(width: 2)
            
            // Center circle
            Circle()
                .stroke(Color.cyan, lineWidth: 2)
                .frame(width: 20, height: 20)
        }
        .frame(width: 100, height: 100)
    }
}

#Preview {
    FloorMarkerPositionView(
        floorImage: UIImage(systemName: "photo")!,
        onConfirm: { _ in },
        onCancel: {}
    )
}