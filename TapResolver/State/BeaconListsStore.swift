//
//  BeaconListsStore.swift
//  TapResolver
//
//  Created by restructuring on 9/19/25.
//

import Foundation
import Combine

final class BeaconListsStore: ObservableObject {
    private let ctx = PersistenceContext.shared
    private var bag = Set<AnyCancellable>()
    
    @Published var beacons: [String] = []
    @Published var morgue: [String] = []
    
    // Computed property: smart-sorted morgue for display
    var sortedMorgue: [String] {
        // Separate into two groups
        let beaconPattern = morgue.filter { isBeaconName($0) }
        let otherDevices = morgue.filter { !isBeaconName($0) }
        
        // Beacon-pattern devices: alphabetical
        // Other devices: preserve original order (newest first)
        return beaconPattern.sorted() + otherDevices
    }

    // Persistence keys
    private let beaconsKey = "BeaconLists_beacons_v1"
    
    private func morgueKey(for locationID: String) -> String {
        return "locations.\(locationID).beaconLists.morgue.v1"
    }

    init() {
        load()
        reloadMorgue()
        
        // Reload when location changes
        NotificationCenter.default.publisher(for: .locationDidChange)
            .sink { [weak self] _ in
                self?.load()
                self?.reloadMorgue()
            }
            .store(in: &bag)
    }

    private func save() {
        ctx.write(beaconsKey, value: beacons)
    }
    
    private func saveMorgue() {
        let loc = PersistenceContext.shared.locationID
        let key = morgueKey(for: loc)
        UserDefaults.standard.set(morgue, forKey: key)
    }

    private func load() {
        beacons = ctx.read(beaconsKey, as: [String].self) ?? []
    }
    
    private func reloadMorgue() {
        let loc = PersistenceContext.shared.locationID
        let key = morgueKey(for: loc)
        if let array = UserDefaults.standard.array(forKey: key) as? [String] {
            morgue = array
        } else {
            morgue = []
        }
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
        if morgue.contains(trimmed) { return }

        // Remove from beacons if present (de-dupe)
        if let i = beacons.firstIndex(of: trimmed) {
            beacons.remove(at: i)
        }

        // Only add to beacons if it matches pattern
        if isBeaconName(trimmed) {
            beacons.append(trimmed)
            save()
        } else {
            // Non-beacon devices go to morgue
            morgue.insert(trimmed, at: 0)
            saveMorgue()
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
        if let j = morgue.firstIndex(of: trimmed) {
            morgue.remove(at: j)
            print("   ✓ Removed from morgue (de-dupe)")
        }
        
        // Add to top of morgue (newest first)
        morgue.insert(trimmed, at: 0)
        print("   ✓ Added to top of morgue. Morgue now has \(morgue.count) items")
        
        save()
        saveMorgue()
        objectWillChange.send()
        print("   ✓ Saved and notified UI")
    }

    func promoteToBeacons(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // Remove from morgue
        if let j = morgue.firstIndex(of: trimmed) {
            morgue.remove(at: j)
        }
        
        // Remove from beacons if already there (de-dupe)
        if let i = beacons.firstIndex(of: trimmed) {
            beacons.remove(at: i)
        }
        
        // Add to top of beacons list (newest first)
        beacons.insert(trimmed, at: 0)
        
        save()
        saveMorgue()
        objectWillChange.send()
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
