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

    // Strict: "##-adjectiveAnimal" (e.g., "12-angryBeaver")
    private let beaconNameRegex = try! NSRegularExpression(
        pattern: #"^\d{2}-[a-z]+[A-Z][A-Za-z]*$"#,
        options: []
    )

    func ingest(deviceName: String) {
        let trimmed = deviceName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Remove from either list first (de-dupe)
        if let i = beacons.firstIndex(of: trimmed) { beacons.remove(at: i) }
        if let j = morgue.firstIndex(of: trimmed)  { morgue.remove(at: j) }

        if isBeaconName(trimmed) {
            // Append to beacons (sorted in UI if you want alpha)
            beacons.append(trimmed)
        } else {
            // Newest-first in Morgue
            morgue.insert(trimmed, at: 0)
        }
    }

    private func isBeaconName(_ name: String) -> Bool {
        let range = NSRange(location: 0, length: (name as NSString).length)
        return beaconNameRegex.firstMatch(in: name, options: [], range: range) != nil
    }
    
    func demoteToMorgue(_ name: String) {
        guard let i = beacons.firstIndex(of: name) else { return }
        beacons.remove(at: i)
        morgue.insert(name, at: 0)     // newest at the top
    }

    func promoteToBeacons(_ name: String) {
        guard let i = morgue.firstIndex(of: name) else { return }
        morgue.remove(at: i)
        beacons.append(name)
    }
    
}

