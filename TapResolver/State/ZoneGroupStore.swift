//
//  ZoneGroupStore.swift
//  TapResolver
//
//  State management for ZoneGroup entities with persistence.
//

import Foundation
import Combine

/// Manages ZoneGroup entities with persistence
public class ZoneGroupStore: ObservableObject {
    @Published public var groups: [ZoneGroup] = []
    
    /// Currently selected group for editing (nil = none selected)
    @Published public var selectedGroupID: String?
    
    /// Location-scoped UserDefaults key
    private var userDefaultsKey: String {
        let locationID = PersistenceContext.shared.locationID
        return "ZoneGroups_v1_\(locationID)"
    }
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - CRUD Operations
    
    /// Create a new zone group
    /// - Parameters:
    ///   - id: Unique identifier (human-readable)
    ///   - displayName: Display name for the group
    ///   - colorHex: Hex color string (e.g., "#3154ff")
    /// - Returns: The created ZoneGroup
    @discardableResult
    public func createGroup(
        id: String,
        displayName: String,
        colorHex: String = "#808080"
    ) -> ZoneGroup {
        // Check for duplicate ID
        if groups.contains(where: { $0.id == id }) {
            print("⚠️ [ZoneGroupStore] Group with ID '\(id)' already exists")
            return groups.first { $0.id == id }!
        }
        
        let group = ZoneGroup(
            id: id,
            displayName: displayName,
            colorHex: colorHex
        )
        
        groups.append(group)
        save()
        
        print("✅ [ZoneGroupStore] Created group '\(displayName)' with ID '\(id)'")
        return group
    }
    
    /// Delete a zone group by ID
    /// Note: Does not delete zones in the group, just removes the group
    public func deleteGroup(_ id: String) {
        guard let index = groups.firstIndex(where: { $0.id == id }) else {
            print("⚠️ [ZoneGroupStore] Cannot delete: group '\(id)' not found")
            return
        }
        let name = groups[index].displayName
        groups.remove(at: index)
        save()
        print("🗑️ [ZoneGroupStore] Deleted group '\(name)'")
    }
    
    /// Update an existing zone group
    public func updateGroup(_ group: ZoneGroup) {
        guard let index = groups.firstIndex(where: { $0.id == group.id }) else {
            print("⚠️ [ZoneGroupStore] Cannot update: group '\(group.id)' not found")
            return
        }
        
        var updatedGroup = group
        updatedGroup.modifiedAt = Date()
        
        groups[index] = updatedGroup
        save()
        print("✅ [ZoneGroupStore] Updated group '\(updatedGroup.displayName)'")
    }
    
    /// Add a zone to a group
    public func addZone(_ zoneID: String, toGroup groupID: String) {
        guard let index = groups.firstIndex(where: { $0.id == groupID }) else {
            print("⚠️ [ZoneGroupStore] Cannot add zone: group '\(groupID)' not found")
            return
        }
        
        if !groups[index].zoneIDs.contains(zoneID) {
            groups[index].zoneIDs.append(zoneID)
            groups[index].modifiedAt = Date()
            save()
            print("➕ [ZoneGroupStore] Added zone '\(zoneID)' to group '\(groups[index].displayName)'")
        }
    }
    
    /// Remove a zone from a group
    public func removeZone(_ zoneID: String, fromGroup groupID: String) {
        guard let index = groups.firstIndex(where: { $0.id == groupID }) else {
            print("⚠️ [ZoneGroupStore] Cannot remove zone: group '\(groupID)' not found")
            return
        }
        
        if let zoneIndex = groups[index].zoneIDs.firstIndex(of: zoneID) {
            groups[index].zoneIDs.remove(at: zoneIndex)
            groups[index].modifiedAt = Date()
            save()
            print("➖ [ZoneGroupStore] Removed zone '\(zoneID)' from group '\(groups[index].displayName)'")
        }
    }
    
    // MARK: - Queries
    
    /// Find group by ID
    public func group(withID id: String) -> ZoneGroup? {
        groups.first { $0.id == id }
    }
    
    /// Find group containing a specific zone
    public func group(containingZone zoneID: String) -> ZoneGroup? {
        groups.first { $0.zoneIDs.contains(zoneID) }
    }
    
    // MARK: - Persistence
    
    /// Save groups to UserDefaults
    public func save() {
        do {
            let data = try JSONEncoder().encode(groups)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
            print("💾 [ZoneGroupStore] Saved \(groups.count) groups to UserDefaults")
        } catch {
            print("❌ [ZoneGroupStore] Failed to save: \(error)")
        }
    }
    
    /// Load groups from UserDefaults
    public func load() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            print("📂 [ZoneGroupStore] No saved groups found for key '\(userDefaultsKey)'")
            groups = []
            return
        }
        
        do {
            groups = try JSONDecoder().decode([ZoneGroup].self, from: data)
            print("📂 [ZoneGroupStore] Loaded \(groups.count) groups from UserDefaults")
        } catch {
            print("❌ [ZoneGroupStore] Failed to load: \(error)")
            groups = []
        }
    }
    
    /// Clear all groups (for location switching)
    public func clearAll() {
        groups = []
        print("🗑️ [ZoneGroupStore] Cleared all groups")
    }
    
    /// Purge all zone groups from memory AND UserDefaults (destructive)
    public func purgeAll() {
        let count = groups.count
        groups = []
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        print("🗑️ [ZoneGroupStore] Purged \(count) zone groups from memory and UserDefaults")
    }
    
    /// Reload for active location (call when location changes)
    public func reloadForActiveLocation() {
        load()
    }
}
