//
//  BeaconListsStore.swift
//  TapResolver
//
//  Created by Chris Gelles on 9/19/25.
//
//

import Foundation

final class BeaconListsStore: ObservableObject {
    @Published var beacons: [String] = []
    @Published var morgue:  [String] = []

    // Persistence keys
    private let beaconsKey = "BeaconLists_beacons_v1"
    private let morgueKey  = "BeaconLists_morgue_v1"

    init() {
        load()
    }

    private func save() {
        UserDefaults.standard.set(beacons, forKey: beaconsKey)
        UserDefaults.standard.set(morgue,  forKey: morgueKey)
    }

    private func load() {
        if let b = UserDefaults.standard.array(forKey: beaconsKey) as? [String] {
            beacons = b
        }
        if let m = UserDefaults.standard.array(forKey: morgueKey) as? [String] {
            morgue = m
        }
    }
    
    // Strict: "##-adjectiveAnimal" (e.g., "12-angryBeaver")
    private let beaconNameRegex = try! NSRegularExpression(
        pattern: #"^\d{2}-[a-z]+[A-Z][A-Za-z]*$"#,
        options: []
    )

    /// Base ingest that sorts into Beacons vs Morgue by name pattern.
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
}
