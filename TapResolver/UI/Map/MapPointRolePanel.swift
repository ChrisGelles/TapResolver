//
//  MapPointRolePanel.swift
//  TapResolver
//
//  Floating role assignment panel for MapPoints
//

import SwiftUI

struct MapPointRolePanel: View {
    let pointID: UUID
    
    @EnvironmentObject private var mapPointStore: MapPointStore
    @State private var errorMessage: String?
    
    private var point: MapPointStore.MapPoint? {
        mapPointStore.points.first { $0.id == pointID }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Point Roles")
                    .font(.headline)
                Spacer()
                Button {
                    mapPointStore.selectedPointID = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.white)
                    .font(.caption)
                    .padding(8)
                    .background(Color.red)
                    .cornerRadius(4)
                    .transition(.opacity)
            }
            
            ForEach(MapPointRole.allCases) { role in
                roleToggle(for: role)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(radius: 8)
        .frame(width: 280)
    }
    
    private func roleToggle(for role: MapPointRole) -> some View {
        HStack(spacing: 12) {
            Image(systemName: role.icon)
                .foregroundColor(role.color)
                .frame(width: 20)
            
            Text(role.displayName)
                .font(.subheadline)
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { point?.roles.contains(role) ?? false },
                set: { isOn in
                    guard let currentPoint = point else { return }
                    if isOn {
                        if let error = mapPointStore.assignRole(role, to: currentPoint.id) {
                            errorMessage = error
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation {
                                    errorMessage = nil
                                }
                            }
                        }
                    } else {
                        mapPointStore.removeRole(role, from: currentPoint.id)
                    }
                }
            ))
            .toggleStyle(SwitchToggleStyle(tint: role.color))
        }
    }
}

