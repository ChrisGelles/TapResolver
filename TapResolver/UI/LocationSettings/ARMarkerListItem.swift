//
//  ARMarkerListItem.swift
//  TapResolver
//
//  Role: List item component for AR Marker in settings
//

import SwiftUI

struct ARMarkerListItem: View {
    let marker: ARMarker
    let mapPointStore: MapPointStore
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Marker icon
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.blue)
            
            // Marker info
            VStack(alignment: .leading, spacing: 4) {
                // Marker ID (shortened)
                Text("Marker \(String(marker.id.uuidString.prefix(8)))...")
                    .font(.system(size: 14, weight: .medium))
                
                // Linked MapPoint info
                if let mapPoint = mapPointStore.points.first(where: { $0.id == marker.linkedMapPointID }) {
                    Text("@ (\(Int(mapPoint.mapPoint.x)), \(Int(mapPoint.mapPoint.y)))")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                } else {
                    Text("Unlinked marker")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                }
                
                // Creation date
                Text("Created: \(formatDate(marker.createdAt))")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // AR position indicator
            VStack(alignment: .trailing, spacing: 2) {
                Text("Position:")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Text(String(format: "(%.1f, %.1f, %.1f)", 
                           marker.arPosition.x,
                           marker.arPosition.y,
                           marker.arPosition.z))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.blue)
            }
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.red)
                    .padding(8)
                    .background(Color.red.opacity(0.15))
                    .cornerRadius(6)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

