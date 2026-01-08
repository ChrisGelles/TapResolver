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
    @State private var isExpanded: Bool = false
    
    private var point: MapPointStore.MapPoint? {
        mapPointStore.points.first { $0.id == pointID }
    }
    
    var body: some View {
        if isExpanded {
            expandedPanel
        } else {
            collapsedTab
        }
    }
    
    // MARK: - Collapsed Tab Button
    
    private var collapsedTab: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded = true
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 16))
                Text("Roles")
                    .font(.system(size: 9, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(width: 48, height: 56)
            .background(Color.blue.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .shadow(radius: 4)
    }
    
    // MARK: - Expanded Panel
    
    private var expandedPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Point Roles")
                    .font(.headline)
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded = false
                    }
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

