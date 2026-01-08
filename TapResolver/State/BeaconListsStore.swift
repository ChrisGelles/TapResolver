//
//  BeaconListsStore.swift
//  TapResolver
//
//  Created by restructuring on 9/19/25.
//

import Foundation
import Combine

// MARK: - Morgue Item Model

/// Represents an item in the morgue with history tracking.
/// hasHistory = true means the item was promoted or demoted at some point (persists across sessions)
/// hasHistory = false means it was just scanned (ephemeral, clears when location closes)
struct MorgueItem: Codable, Equatable, Identifiable {
    let displayName: String
    var hasHistory: Bool
    
    var id: String { displayName }
    
    init(displayName: String, hasHistory: Bool = false) {
        self.displayName = displayName
        self.hasHistory = hasHistory
    }
}

// MARK: - Beacon Lists Store

final class BeaconListsStore: ObservableObject {
    private let ctx = PersistenceContext.shared
    private var bag = Set<AnyCancellable>()
    
    @Published var beacons: [String] = []
    @Published var morgue: [MorgueItem] = []
    
    // Computed property: smart-sorted morgue for display
    // CRITICAL: Excludes any item that's currently in the Beacon List
    var sortedMorgue: [MorgueItem] {
        // First, filter out anything that's in the beacons list
        let morgueOnly = morgue.filter { !beacons.contains($0.displayName) }
        
        // Separate into two groups
        let beaconPattern = morgueOnly.filter { isBeaconName($0.displayName) }
        let otherDevices = morgueOnly.filter { !isBeaconName($0.displayName) }
        
        // Beacon-pattern devices: alphabetical by name
        // Other devices: preserve original order (newest first)
        return beaconPattern.sorted { $0.displayName < $1.displayName } + otherDevices
    }
    
    // Convenience: check if a name exists in morgue
    func morgueContains(_ name: String) -> Bool {
        morgue.contains { $0.displayName == name }
    }

    // Persistence keys
    private let beaconsKey = "BeaconLists_beacons_v1"
    
    private func morgueKey(for locationID: String) -> String {
        return "locations.\(locationID).beaconLists.morgue.v1"
    }

    init() {
        // Defer initial load to avoid "Publishing changes from within view updates"
        DispatchQueue.main.async { [weak self] in
            self?.load()
            self?.reloadMorgue()
        }
        
        // Reload when location changes
        NotificationCenter.default.publisher(for: .locationDidChange)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.load()
                    self?.reloadMorgue()
                }
            }
            .store(in: &bag)
    }

    private func save() {
        ctx.write(beaconsKey, value: beacons)
    }
    
    private func saveMorgue() {
        let loc = PersistenceContext.shared.locationID
        let key = morgueKey(for: loc)
        
        // Only persist items that have beacon history (promoted or demoted)
        let itemsToSave = morgue.filter { $0.hasHistory }
        
        if let encoded = try? JSONEncoder().encode(itemsToSave) {
            UserDefaults.standard.set(encoded, forKey: key)
            let ephemeralCount = morgue.count - itemsToSave.count
            if itemsToSave.count > 0 || ephemeralCount > 0 {
                print("💾 [Morgue] Saved \(itemsToSave.count) with history, \(ephemeralCount) ephemeral (not saved)")
            }
        }
    }

    private func load() {
        beacons = ctx.read(beaconsKey, as: [String].self) ?? []
    }
    
    private func reloadMorgue() {
        let loc = PersistenceContext.shared.locationID
        let key = morgueKey(for: loc)
        
        // Try new format first (MorgueItem array as JSON Data)
        if let data = UserDefaults.standard.data(forKey: key),
           let items = try? JSONDecoder().decode([MorgueItem].self, from: data) {
            morgue = items
            print("📖 [Morgue] Loaded \(items.count) items with history")
            return
        }
        
        // Migration: try old format (plain string array)
        if let oldArray = UserDefaults.standard.array(forKey: key) as? [String] {
            // Migrate: assume all previously-persisted items had history
            // (they were saved, so user made a decision about them)
            morgue = oldArray.map { name in
                MorgueItem(displayName: name, hasHistory: true)
            }
            print("📖 [Morgue] Migrated \(oldArray.count) items from old format (all marked as having history)")
            saveMorgue()  // Re-save in new format
            return
        }
        
        morgue = []
    }

    // Strict: "##-adjectiveAnimal" (e.g., "12-angryBeaver")
    private let beaconNameRegex = try! NSRegularExpression(
        pattern: #"^\d{2}-[a-z]+[A-Z][A-Za-z]*$"#,
        options: []
    )

    func ingest(deviceName: String) {
        let trimmed = deviceName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // CRITICAL: Don't re-add if already in morgue (respects user's demotion)
        if morgueContains(trimmed) { return }

        // Remove from beacons if present (de-dupe)
        if let i = beacons.firstIndex(of: trimmed) {
            beacons.remove(at: i)
        }

        // Only add to beacons if it matches pattern
        if isBeaconName(trimmed) {
            beacons.append(trimmed)
            save()
        } else {
            // Non-beacon devices go to morgue as EPHEMERAL (hasHistory = false)
            // These will NOT be persisted - they clear when location closes
            let item = MorgueItem(displayName: trimmed, hasHistory: false)
            morgue.insert(item, at: 0)
            // NOTE: NOT calling saveMorgue() - ephemeral items don't persist
        }
        objectWillChange.send()
    }

    func ingest(deviceName: String, id: UUID) {
        let base = deviceName.trimmingCharacters(in: .whitespacesAndNewlines)
        let shortId = id.uuidString.prefix(4)
        let display = (base.isEmpty || base == "Unknown")
            ? "(unnamed bluetooth device)-\(shortId)"
            : base
        self.ingest(deviceName: String(display))
    }

    private func isBeaconName(_ name: String) -> Bool {
        let range = NSRange(location: 0, length: (name as NSString).length)
        return beaconNameRegex.firstMatch(in: name, options: [], range: range) != nil
    }

    func demoteToMorgue(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        print("📤 Demoting '\(trimmed)' to Morgue")
        
        // Remove from beacons list
        if let i = beacons.firstIndex(of: trimmed) {
            beacons.remove(at: i)
            print("   ✓ Removed from beacons list")
        }
        
        // Remove from morgue if already there (de-dupe)
        if let j = morgue.firstIndex(where: { $0.displayName == trimmed }) {
            morgue.remove(at: j)
            print("   ✓ Removed from morgue (de-dupe)")
        }
        
        // Add to top of morgue with hasHistory = true (WILL be persisted)
        let item = MorgueItem(displayName: trimmed, hasHistory: true)
        morgue.insert(item, at: 0)
        print("   ✓ Added to morgue with history. Morgue now has \(morgue.count) items")
        
        save()
        saveMorgue()
        objectWillChange.send()
        print("   ✓ Saved and notified UI")
    }

    func promoteToBeacons(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        print("📥 Promoting '\(trimmed)' to Beacons")
        
        // Remove from morgue
        if let j = morgue.firstIndex(where: { $0.displayName == trimmed }) {
            morgue.remove(at: j)
            print("   ✓ Removed from morgue")
        }
        
        // Remove from beacons if already there (de-dupe)
        if let i = beacons.firstIndex(of: trimmed) {
            beacons.remove(at: i)
        }
        
        // Add to top of beacons list (newest first)
        beacons.insert(trimmed, at: 0)
        print("   ✓ Added to beacons list")
        
        save()
        saveMorgue()
        objectWillChange.send()
    }
    
    // MARK: - Morgue History Management
    
    /// Clear history flag for a morgue item (makes it ephemeral again)
    /// Item will be removed when location closes
    func clearHistory(for name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        if let index = morgue.firstIndex(where: { $0.displayName == trimmed }) {
            // Replace the item with a new one without history
            morgue[index] = MorgueItem(displayName: trimmed, hasHistory: false)
            print("🗑️ Cleared history for '\(trimmed)' - now ephemeral")
            saveMorgue()  // Re-save without this item
            objectWillChange.send()
        }
    }
    
    /// Check if a morgue item has history
    func hasHistory(for name: String) -> Bool {
        morgue.first(where: { $0.displayName == name })?.hasHistory ?? false
    }
    
    /// Batch clear history for ALL morgue items
    /// Makes everything ephemeral - will be cleared on location close
    /// Does NOT affect anything in the Beacon List
    /// Returns count of items affected
    @discardableResult
    func clearAllMorgueHistory() -> Int {
        var count = 0
        for i in morgue.indices {
            if morgue[i].hasHistory {
                morgue[i] = MorgueItem(displayName: morgue[i].displayName, hasHistory: false)
                count += 1
            }
        }
        if count > 0 {
            print("🗑️ Cleared history for \(count) morgue items - all now ephemeral")
            saveMorgue()  // Will save empty (nothing has history now)
            objectWillChange.send()
        }
        return count
    }
    
    /// Remove all ephemeral items from morgue immediately (don't wait for location close)
    /// Returns count of items removed
    @discardableResult
    func purgeEphemeralMorgueItems() -> Int {
        let beforeCount = morgue.count
        morgue.removeAll { !$0.hasHistory }
        let removed = beforeCount - morgue.count
        if removed > 0 {
            print("🧹 Purged \(removed) ephemeral morgue items")
            objectWillChange.send()
        }
        return removed
    }

    func clearUnlockedBeacons(lockedBeaconNames: [String]) {
        beacons = beacons.filter { lockedBeaconNames.contains($0) }
        save()
    }

    // MARK: - Location switching support
    
    func reloadForActiveLocation() {
        beacons.removeAll()
        morgue.removeAll()
        load()
        reloadMorgue()
        reconcileWithLockedDots()
        objectWillChange.send()
    }
    
    func flush() {
        beacons.removeAll()
        morgue.removeAll()
        objectWillChange.send()
    }
    
    func loadOnly() {
        beacons = ctx.read(beaconsKey, as: [String].self) ?? []
        // Also reload morgue when doing loadOnly (was missing!)
        reloadMorgue()
    }
    
    func reconcileWithLockedDots(_ lockedBeaconNames: [String]? = nil) {
        let names: [String]
        if let locked = lockedBeaconNames {
            names = locked
        } else {
            names = BeaconDotRegistry.sharedLockedIDs?() ?? []
        }

        guard !names.isEmpty else { return }

        var changed = false
        for name in names where !beacons.contains(name) {
            beacons.append(name)
            changed = true
        }
        if changed { save() }
    }
    
    func clearAndReloadForActiveLocation() {
        reloadForActiveLocation()
    }
}
