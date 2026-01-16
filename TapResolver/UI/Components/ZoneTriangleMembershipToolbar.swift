//
//  ZoneTriangleMembershipToolbar.swift
//  TapResolver
//
//  Toolbar for editing zone triangle membership.
//

import SwiftUI

struct ZoneTriangleMembershipToolbar: View {
    @EnvironmentObject var zoneStore: ZoneStore
    
    var body: some View {
        if zoneStore.isEditingTriangleMembership {
            VStack(spacing: 0) {
                // Zone name header
                if let zone = zoneStore.editingZone {
                    HStack {
                        Text("Editing: \(zone.displayName)")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("\(zoneStore.pendingMemberTriangleIDs.count) triangles")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                }
                
                Divider()
                
                // Action buttons
                HStack(spacing: 20) {
                    Button(action: {
                        zoneStore.cancelTriangleMembershipEdits()
                    }) {
                        HStack {
                            Image(systemName: "xmark.circle")
                            Text("Cancel")
                        }
                        .foregroundColor(.red)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        zoneStore.acceptTriangleMembershipEdits()
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Accept")
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(Color.green)
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12, corners: [.topLeft, .topRight])
            .shadow(radius: 4)
        }
    }
}
