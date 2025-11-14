//
//  ARReferenceImageView.swift
//  TapResolver
//
//  Reference image PiP overlay for AR calibration
//

import SwiftUI

struct ARReferenceImageView: View {
    var image: UIImage
    
    var body: some View {
        ZStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.8), lineWidth: 3)
                )
            
            // Optional crosshair overlay
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.red)
        }
        .padding(.top, 50)
        .padding(.leading, 20)
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
}

