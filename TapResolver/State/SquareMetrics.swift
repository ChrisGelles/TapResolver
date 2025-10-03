//
//  SquareMetrics.swift
//  TapResolver
//
//  Created by restructuring on 9/19/25.
//

import SwiftUI
import Combine

extension Notification.Name {
    static let locationDidChange = Notification.Name("LocationDidChange")
}

// MARK: - Square metrics (delegates to MetricSquareStore)
final class SquareMetrics: ObservableObject {
    private var metricSquareStore: MetricSquareStore?
    
    struct ActiveEdit: Identifiable {
        let id: UUID
        var text: String
    }
    
    @Published var activeEdit: ActiveEdit? = nil
    
    // MARK: - Per-location North offset (degrees, +CW / -CCW)
    @Published var northOffsetDeg: Double = 0 {
        didSet { saveNorthOffset() }
    }
    
    /// Display + logging fine-tune offset for facing (degrees CW; negative = CCW)
    @Published var facingFineTuneDeg: Double = 0 {
        didSet { saveFacingFineTune() }
    }

    // MARK: - Facing Fine-Tune Persistence
    private func facingFineTuneKey(for locationID: String) -> String {
        return "locations.\(locationID).mapMetrics.facingFineTuneDeg.v1"
    }

    private func reloadFacingFineTune() {
        let loc = PersistenceContext.shared.locationID
        let key = facingFineTuneKey(for: loc)
        if UserDefaults.standard.object(forKey: key) != nil {
            facingFineTuneDeg = UserDefaults.standard.double(forKey: key)
        } else {
            facingFineTuneDeg = 0
        }
    }

    private func saveFacingFineTune() {
        let loc = PersistenceContext.shared.locationID
        let key = facingFineTuneKey(for: loc)
        UserDefaults.standard.set(facingFineTuneDeg, forKey: key)
    }
    
    private var bag = Set<AnyCancellable>()
    
    init() {
        // Load per-location values
        reloadNorthOffset()
        reloadFacingFineTune()
        
        // Observe location changes so we reload per-location value
        NotificationCenter.default.publisher(for: .locationDidChange)
            .sink { [weak self] _ in
                self?.reloadNorthOffset()
                self?.reloadFacingFineTune()
            }
            .store(in: &bag)
    }
    
    func updatePixelSide(for id: UUID, side: CGFloat) {
        // This is handled by MetricSquareStore directly, no local state needed
    }
    
    func entry(for id: UUID) -> (pixelSide: CGFloat, meters: Double)? {
        guard let store = metricSquareStore,
              let square = store.squares.first(where: { $0.id == id }) else { return nil }
        return (pixelSide: square.side, meters: square.meters)
    }
    
    func displayMetersText(for id: UUID) -> String {
        // Read from MetricSquareStore
        if let store = metricSquareStore,
           let square = store.squares.first(where: { $0.id == id }) {
            let formatted = String(format: "%g", square.meters)
            return "\(formatted)m"
        }
        
        // Fallback if no store available
        return "1m"
    }
    
    func commitMetersText(_ text: String, for id: UUID) {
        guard let meters = Double(text) else { return }
        
        // Push value down into MetricSquareStore
        metricSquareStore?.updateMeters(for: id, meters: meters)
        activeEdit = nil
    }
    
    // Method to set the MetricSquareStore reference
    func setMetricSquareStore(_ store: MetricSquareStore) {
        metricSquareStore = store
    }
    
    // MARK: - North Offset Persistence
    private func northOffsetKey(for locationID: String) -> String {
        return "locations.\(locationID).mapMetrics.northOffsetDeg.v1"
    }
    
    private func reloadNorthOffset() {
        let loc = PersistenceContext.shared.locationID
        let key = northOffsetKey(for: loc)
        if UserDefaults.standard.object(forKey: key) != nil {
            northOffsetDeg = UserDefaults.standard.double(forKey: key)
        } else {
            northOffsetDeg = 0
        }
    }
    
    private func saveNorthOffset() {
        let loc = PersistenceContext.shared.locationID
        let key = northOffsetKey(for: loc)
        UserDefaults.standard.set(northOffsetDeg, forKey: key)
    }
    
    // Public setter used by bindings (keeps @Published updates consistent)
    func setNorthOffset(_ deg: Double) {
        northOffsetDeg = deg
    }
}
