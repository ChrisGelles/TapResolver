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
                            Text("Anchor: \(package.id.uuidString.prefix(8))...")
                                .font(.headline)
                            
                            if let mapPoint = mapPointStore.points.first(where: { $0.id == package.mapPointID }) {
                                Text("Map Point: (\(Int(mapPoint.mapPoint.x)), \(Int(mapPoint.mapPoint.y)))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Label("\(package.spatialData.featureCloud.pointCount) points", systemImage: "circle.grid.cross")
                                Spacer()
                                Label("\(package.spatialData.planes.count) planes", systemImage: "square.stack.3d.up")
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
}