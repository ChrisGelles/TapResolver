//
//  ARReferenceImageView.swift
//  TapResolver
//
//  Reference image PiP overlay for AR calibration
//

import SwiftUI

struct ARReferenceImageView: View {
    var image: UIImage
    var mapPoint: MapPointStore.MapPoint
    var isOutdated: Bool
    @State private var showFullImage = false
    @EnvironmentObject private var mapPointStore: MapPointStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isOutdated ? Color.yellow.opacity(0.8) : Color.orange.opacity(0.8), lineWidth: 3)
                    )
                    .overlay(
                        // Dim overlay for outdated photos
                        isOutdated ? Color.yellow.opacity(0.2) : Color.clear
                    )
                
                // Outdated indicator badge
                if isOutdated {
                    VStack {
                        HStack {
                            Spacer()
                            VStack(spacing: 2) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.yellow)
                                Text("Outdated")
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundColor(.yellow)
                            }
                            .padding(6)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(8)
                        }
                        Spacer()
                    }
                }
                
                // Optional crosshair overlay
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.red)
            }
            
            // Update button if outdated
            if isOutdated {
                Button(action: {
                    // Trigger photo update flow
                    NotificationCenter.default.post(
                        name: NSNotification.Name("UpdateMapPointPhoto"),
                        object: nil,
                        userInfo: ["mapPointID": mapPoint.id]
                    )
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 10))
                        Text("Update Photo")
                            .font(.caption2)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.8))
                    .cornerRadius(6)
                }
            }
        }
        .padding(.bottom, 60)
        .padding(.leading, 20)
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
        .onTapGesture {
            showFullImage = true
        }
        .sheet(isPresented: $showFullImage) {
            FullImageView(image: image, mapPoint: mapPoint)
        }
    }
}

// Full image view for tap-to-expand
struct FullImageView: View {
    var image: UIImage
    var mapPoint: MapPointStore.MapPoint
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .ignoresSafeArea()
            }
            .navigationTitle("Reference Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

