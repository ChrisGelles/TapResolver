//
//  AnchorManagementView.swift
//  TapResolver
//
//  Created by Chris Gelles on 11/6/25.
//


//
//  AnchorManagementView.swift
//  TapResolver
//

import SwiftUI

struct AnchorManagementView: View {
    @ObservedObject var mapPointStore: MapPointStore
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                if mapPointStore.anchorPackages.isEmpty {
                    Text("No anchor packages")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(mapPointStore.anchorPackages, id: \.id) { package in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Anchor: \(package.id.uuidString.prefix(8))...")
                                    .font(.headline)
                                
                                Spacer()
                                
                                // Signature image indicator
                                if package.referenceImages.contains(where: { $0.captureType == .signature }) {
                                    Image(systemName: "camera.fill")
                                        .foregroundColor(.green)
                                        .font(.title3)
                                }
                            }
                            
                            if let mapPoint = mapPointStore.points.first(where: { $0.id == package.mapPointID }) {
                                HStack {
                                    Text("Map Point: (\(Int(mapPoint.mapPoint.x)), \(Int(mapPoint.mapPoint.y)))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text("Data: \(formatDataSize(package))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .fontWeight(.medium)
                                }
                            }
                            
                            // Show signature image thumbnail if available
                            if let signatureImage = package.referenceImages.first(where: { $0.captureType == .signature }) {
                                if let uiImage = UIImage(data: signatureImage.imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: 120)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.green, lineWidth: 2)
                                        )
                                }
                            }
                            
                            HStack {
                                Label("\(package.spatialData.featureCloud.pointCount) points", systemImage: "circle.grid.cross")
                                Spacer()
                                Label("\(package.spatialData.planes.count) planes", systemImage: "square.stack.3d.up")
                                Spacer()
                                Label("\(package.referenceImages.count) images", systemImage: "photo")
                                Spacer()
                                Text("\(package.spatialData.totalDataSize / 1024) KB")
                                    .font(.caption)
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                mapPointStore.deleteAnchorPackage(package.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Anchor Packages (\(mapPointStore.anchorPackages.count))")
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
    
    private func formatDataSize(_ package: AnchorPointPackage) -> String {
        // Calculate total size: spatial data + all images
        let spatialSize = package.spatialData.totalDataSize
        let imagesSize = package.referenceImages.reduce(0) { $0 + $1.imageData.count }
        let totalSize = spatialSize + imagesSize
        
        // Format as MB, KB, or bytes
        let mbSize = Double(totalSize) / (1024 * 1024)
        if mbSize >= 1.0 {
            return String(format: "%.1f MB", mbSize)
        }
        
        let kbSize = Double(totalSize) / 1024
        if kbSize >= 1.0 {
            return String(format: "%.0f KB", kbSize)
        }
        
        return "\(totalSize) bytes"
    }
}