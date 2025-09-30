//
//  BeaconListsStore.swift
//  TapResolver
//
//  Created by restructuring on 9/19/25.
//

import Foundation

final class BeaconListsStore: ObservableObject {
    private let ctx = PersistenceContext.shared
    @Published var beacons: [String] = []
    @Published var morgue:  [String] = []

    // Persistence keys
    private let beaconsKey = "BeaconLists_beacons_v1"
    // private let morgueKey  = "BeaconLists_morgue_v1"   // not persisted
    private let lockedBeaconsKey = "LockedBeaconNames_v1"
    
    /// Reload data for the active location
    public func reloadForActiveLocation() {
        clearAndReloadForActiveLocation()
    }
    
    public func clearAndReloadForActiveLocation() {
        beacons.removeAll()
        morgue.removeAll()
        load()
        reconcileWithLockedDots()
        objectWillChange.send()
    }
    
    /// Clear in-memory without saving (used right before a location switch load)
    func flush() {
        beacons.removeAll()
        morgue.removeAll()
        objectWillChange.send()
    }

    /// Load persisted list for active namespace (no reconcile, no clears)
    func loadOnly() {
        beacons = ctx.read(beaconsKey, as: [String].self) ?? []
        // morgue stays in-memory only
    }

    init() {
        load()
    }

    private func save() {
        ctx.write(beaconsKey, value: beacons) // namespaced-only
    }

    private func load() {
        beacons = ctx.read(beaconsKey, as: [String].self) ?? []
        morgue.removeAll() // transient
    }
    
    // Strict: "##-adjectiveAnimal" (e.g., "12-angryBeaver")
    private let beaconNameRegex = try! NSRegularExpression(
        pattern: #"^\d{2}-[a-z]+[A-Z][A-Za-z]*$"#,
        options: []
    )

    /// Base ingest that sorts into Beacons vs Morgue by name pattern.
    /// This method is location-aware and only ingests for the current active location.
    func ingest(deviceName: String) {
        let trimmed = deviceName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Remove from either list first (de-dupe)
        if let i = beacons.firstIndex(of: trimmed) { beacons.remove(at: i) }
        if let j = morgue.firstIndex(of: trimmed)  { morgue.remove(at: j) }

        if isBeaconName(trimmed) {
            beacons.append(trimmed)
        } else {
            // Newest-first in Morgue
            morgue.insert(trimmed, at: 0)
        }
        save()  // <— add this
    }
    
    /// Clear all beacon lists for location switching
    func clearForLocationSwitch() {
        beacons.removeAll()
        morgue.removeAll()
        // do NOT save here
    }

    /// Overload that accepts (name, id). If name is empty/Unknown, suffix a short id.
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
        guard let i = beacons.firstIndex(of: name) else { return }
        beacons.remove(at: i)
        morgue.insert(name, at: 0)     // newest at the top
        save()  // <— add this
    }

    func promoteToBeacons(_ name: String) {
        guard let i = morgue.firstIndex(of: name) else { return }
        morgue.remove(at: i)
        beacons.append(name)
        save()  // <— add this
    }
    
    /// Clear unlocked beacons and morgue (called on scan refresh and app launch)
    func refreshFromScan() {
        // Clear morgue completely
        morgue.removeAll()
        
        // Clear unlocked beacons (keep only locked ones)
        clearUnlockedBeacons()
        
        save()
    }
    
    /// Get only the locked beacon names
    func getLockedBeacons() -> [String] {
        return beacons.filter { beaconName in
            // We need to check if this beacon has a locked dot
            // This will be called from ContentView with access to beaconDotStore
            return true // Placeholder - will be implemented in ContentView
        }
    }
    
    /// Clear unlocked beacons (helper method)
    private func clearUnlockedBeacons() {
        // This will be called from ContentView with access to beaconDotStore
        // For now, keep all beacons - will be implemented when we update ContentView
    }
    
    /// Clear unlocked beacons using beaconDotStore to check lock status
    func clearUnlockedBeacons(lockedBeaconNames: [String]) {
        beacons = beacons.filter { beaconName in
            lockedBeaconNames.contains(beaconName)
        }
    }
    
    // MARK: - Reconciliation with locked dots
    func reconcileWithLockedDots(_ lockedBeaconNames: [String]? = nil) {
        // If caller passed a list, use it; otherwise derive from BeaconDotStore via NotificationCenter or singleton
        let names: [String]
        if let locked = lockedBeaconNames {
            names = locked
        } else {
            // Lightweight pull from BeaconDotStore if available in environment later;
            // no-op if not available
            names = BeaconDotRegistry.sharedLockedIDs?() ?? []
        }

        guard !names.isEmpty else { return }

        // Merge any locked names that aren't already present
        var changed = false
        for name in names where !beacons.contains(name) {
            beacons.append(name)
            changed = true
        }
        if changed { save() }
    }
}
