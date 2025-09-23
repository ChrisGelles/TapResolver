//
//  SquareMetrics.swift
//  TapResolver
//
//  Created by restructuring on 9/19/25.
//

import SwiftUI

// MARK: - Square metrics (unchanged)
final class SquareMetrics: ObservableObject {
    struct Entry: Identifiable {
        let id: UUID
        var pixelSide: CGFloat
        var meters: Double?
    }
    
    struct ActiveEdit: Identifiable {
        let id: UUID
        var text: String
    }
    
    @Published private(set) var entries: [UUID: Entry] = [:]
    @Published var activeEdit: ActiveEdit? = nil
    func updatePixelSide(for id: UUID, side: CGFloat) {
        if var e = entries[id] { e.pixelSide = side; entries[id] = e }
        else { entries[id] = Entry(id: id, pixelSide: side, meters: nil) }
    }
    func setMeters(for id: UUID, meters: Double) {
        if var e = entries[id] { e.meters = meters; entries[id] = e }
        else { entries[id] = Entry(id: id, pixelSide: 0, meters: meters) }
    }
    func entry(for id: UUID) -> Entry? { entries[id] }
    
    func displayMetersText(for id: UUID) -> String {
        guard let entry = entries[id] else { return "1m" }
        if let meters = entry.meters {
            // Remove unnecessary decimal places (1.0 -> 1, 1.5 -> 1.5)
            let formatted = String(format: "%g", meters)
            return "\(formatted)m"
        } else {
            return "\(Int(entry.pixelSide))px"
        }
    }
    
    func commitMetersText(_ text: String, for id: UUID) {
        if let meters = Double(text) {
            setMeters(for: id, meters: meters)
        }
    }
}