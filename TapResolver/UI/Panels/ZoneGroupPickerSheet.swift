//
//  ZoneGroupPickerSheet.swift
//  TapResolver
//
//  Sheet for selecting a Zone Group when creating a new Zone.
//

import SwiftUI

struct ZoneGroupPickerSheet: View {
    @EnvironmentObject private var zoneStore: ZoneStore
    @EnvironmentObject private var zoneGroupStore: ZoneGroupStore
    
    @Binding var isPresented: Bool
    
    @State private var showNewGroupDialog = false
    @State private var newGroupName = ""
    
    var body: some View {
        NavigationView {
            List {
                // Existing groups
                Section("Assign to Group") {
                    ForEach(zoneGroupStore.groups) { group in
                        Button {
                            selectGroup(group.id)
                        } label: {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(group.color)
                                    .frame(width: 16, height: 16)
                                
                                Text(group.displayName)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Text("\(group.zoneIDs.count) zones")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Create new group option
                    Button {
                        showNewGroupDialog = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                                .frame(width: 16, height: 16)
                            
                            Text("New Zone Group...")
                                .foregroundColor(.green)
                        }
                    }
                }
                
                // Ungrouped option
                Section {
                    Button {
                        selectGroup(nil)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "square.dashed")
                                .foregroundColor(.secondary)
                                .frame(width: 16, height: 16)
                            
                            Text("Leave Ungrouped")
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            .navigationTitle("Select Zone Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        zoneStore.cancelPendingZone()
                        isPresented = false
                    }
                }
            }
        }
        .alert("New Zone Group", isPresented: $showNewGroupDialog) {
            TextField("Group name", text: $newGroupName)
            Button("Cancel", role: .cancel) {
                newGroupName = ""
            }
            Button("Create") {
                createNewGroupAndSelect()
            }
        } message: {
            Text("Enter a name for the new zone group")
        }
    }
    
    private func selectGroup(_ groupID: String?) {
        zoneStore.completeZoneCreation(groupID: groupID, zoneGroupStore: zoneGroupStore)
        isPresented = false
    }
    
    private func createNewGroupAndSelect() {
        let trimmedName = newGroupName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            newGroupName = ""
            return
        }
        
        // Generate ID from name
        let groupID = trimmedName.lowercased().replacingOccurrences(of: " ", with: "-") + "-zones"
        
        // Create group with random color (HSB: random hue, 70% saturation, 80% brightness)
        let hue = Double.random(in: 0...1)
        let saturation = 0.7
        let brightness = 0.8
        
        // Convert HSB to RGB
        let h = hue * 6
        let c = brightness * saturation
        let x = c * (1 - abs((h.truncatingRemainder(dividingBy: 2)) - 1))
        let m = brightness - c
        
        var r: Double, g: Double, b: Double
        switch Int(h) {
        case 0: (r, g, b) = (c, x, 0)
        case 1: (r, g, b) = (x, c, 0)
        case 2: (r, g, b) = (0, c, x)
        case 3: (r, g, b) = (0, x, c)
        case 4: (r, g, b) = (x, 0, c)
        default: (r, g, b) = (c, 0, x)
        }
        
        let ri = Int((r + m) * 255)
        let gi = Int((g + m) * 255)
        let bi = Int((b + m) * 255)
        
        let colorHex = String(format: "#%02X%02X%02X", ri, gi, bi)
        
        let group = zoneGroupStore.createGroup(
            id: groupID,
            displayName: trimmedName,
            colorHex: colorHex
        )
        
        newGroupName = ""
        selectGroup(group.id)
    }
}

#Preview {
    ZoneGroupPickerSheet(isPresented: .constant(true))
        .environmentObject(ZoneStore())
        .environmentObject(ZoneGroupStore())
}
