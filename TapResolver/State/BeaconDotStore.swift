//
//  BeaconDotStore.swift
//  TapResolver
//
//  Created by restructuring on 9/19/25.
//

import SwiftUI
import CoreGraphics

// MARK: - Elevation editing state
public struct ActiveElevationEdit: Identifiable {
    public let id = UUID()
    public let beaconID: String
    public var text: String
}

// MARK: - Store of dots (map-local positions) + Locks + Persistence
public final class BeaconDotStore: ObservableObject {
    private let ctx = PersistenceContext.shared
    public struct Dot: Identifiable {
        public let id = UUID()
        public let beaconID: String     // one dot per beacon
        public let color: Color
        public var mapPoint: CGPoint    // map-local (untransformed) coords
        public var elevation: Double = 0.75  // elevation in meters, default 0.75
    }

    @Published public private(set) var dots: [Dot] = []
    // beaconID -> locked?
    @Published private(set) var locked: [String: Bool] = [:]
    // beaconID -> elevation
    @Published private(set) var elevations: [String: Double] = [:]
    // beaconID -> txPower dBm
    @Published var txPowerByID: [String: Int] = [:]
    // Active elevation editing state
    @Published public var activeElevationEdit: ActiveElevationEdit? = nil

    // MARK: persistence keys
    private let dotsKey   = "BeaconDots_v1"
    private let locksKey  = "BeaconLocks_v1"
    private let lockedDotsKey = "LockedBeaconDots_v1"
    private let elevationsKey = "BeaconElevations_v1"
    private let txPowerKey = "BeaconDots_txPowerByID_v1"

    public init() {
        load()
    }

    public func dot(for beaconID: String) -> Dot? {
        dots.first { $0.beaconID == beaconID }
    }

    /// Toggle a dot for a beacon:
    /// - If it exists, remove it.
    /// - If not, add at `mapPoint` with `color`.
    public func toggleDot(for beaconID: String, mapPoint: CGPoint, color: Color) {
        if let idx = dots.firstIndex(where: { $0.beaconID == beaconID }) {
            dots.remove(at: idx)
            save()
            print("Removed dot for \(beaconID)")
        } else {
            dots.append(Dot(beaconID: beaconID, color: color, mapPoint: mapPoint))
            save()
            print("Added dot for \(beaconID) @ map (\(Int(mapPoint.x)), \(Int(mapPoint.y)))")
        }
    }

    /// Update a dot's map-local position (used while dragging).
    public func updateDot(id: UUID, to newPoint: CGPoint) {
        if let idx = dots.firstIndex(where: { $0.id == id }) {
            dots[idx].mapPoint = newPoint
            save()
        }
    }

    public func clear() {
        dots.removeAll()
        save()
    }
    
    /// Clear dots for unlocked beacons only (preserves locked beacons)
    public func clearUnlockedDots() {
        dots.removeAll { !isLocked($0.beaconID) }
        save()
    }
    
    /// Get only the locked beacon dots
    public func lockedDots() -> [Dot] {
        return dots.filter { isLocked($0.beaconID) }
    }
    
    /// Restore all beacon dots from storage (called on app launch)
    public func restoreAllDots() {
        // First load locks to know which beacons are locked
        loadLocks()
        
        // Load all dots from the main storage
        if let data = UserDefaults.standard.data(forKey: dotsKey),
           let dto = try? JSONDecoder().decode([DotDTO].self, from: data) {
            let allDots = dto.map { dotDTO in
                var dot = Dot(beaconID: dotDTO.beaconID,
                             color: beaconColor(for: dotDTO.beaconID),
                             mapPoint: CGPoint(x: dotDTO.x, y: dotDTO.y))
                dot.elevation = dotDTO.elevation
                return dot
            }
            
            // Clear current dots and restore all previously saved ones
            dots.removeAll()
            dots.append(contentsOf: allDots)
            
            // Restore elevation values for all dots
            for dot in allDots {
                elevations[dot.beaconID] = dot.elevation
            }
        }
    }
    
    // MARK: - Elevation API
    
    public func setElevation(for beaconID: String, elevation: Double) {
        elevations[beaconID] = elevation
        saveElevations()
    }
    
    public func getElevation(for beaconID: String) -> Double {
        return elevations[beaconID] ?? 0.75
    }
    
    public func startElevationEdit(for beaconID: String) {
        let current = getElevation(for: beaconID)
        let seed = String(format: "%g", current)
        activeElevationEdit = ActiveElevationEdit(beaconID: beaconID, text: seed)
    }
    
    public func commitElevationText(_ text: String, for beaconID: String) {
        if let elevation = Double(text) {
            setElevation(for: beaconID, elevation: elevation)
        }
    }
    
    public func displayElevationText(for beaconID: String) -> String {
        let elevation = getElevation(for: beaconID)
        let formatted = String(format: "%g", elevation)
        return "\(formatted)m"
    }
    
    // MARK: - Tx Power API
    
    public func setTxPower(for beaconID: String, dbm: Int?) {
        if let v = dbm {
            txPowerByID[beaconID] = v
        } else {
            txPowerByID.removeValue(forKey: beaconID)
        }
        saveTxPower()
    }
    
    public func getTxPower(for beaconID: String) -> Int? {
        return txPowerByID[beaconID]
    }
    
    /// Reload data for the active location
    public func reloadForActiveLocation() {
        load()
    }

    // MARK: - Lock API

    public func isLocked(_ beaconID: String) -> Bool {
        locked[beaconID] ?? false
    }

    public func toggleLock(_ beaconID: String) {
        let newVal = !(locked[beaconID] ?? false)
        locked[beaconID] = newVal
        saveLocks()
        save() // Also save dot data when locking/unlocking
    }

    // MARK: - Persistence

    private struct DotDTO: Codable {
        let beaconID: String
        let x: CGFloat
        let y: CGFloat
        let elevation: Double
    }

    private struct LocksDTO: Codable {
        let locks: [String: Bool]
    }

    private func save() {
        // Save all dots (for backward compatibility)
        let dto = dots.map { DotDTO(beaconID: $0.beaconID, x: $0.mapPoint.x, y: $0.mapPoint.y, elevation: getElevation(for: $0.beaconID)) }
        if let data = try? JSONEncoder().encode(dto) {
            UserDefaults.standard.set(data, forKey: dotsKey) // legacy
            ctx.write(dotsKey, value: dto, alsoWriteLegacy: true)
        }
        
        // Save only locked dots (new behavior)
        let lockedDots = dots.filter { isLocked($0.beaconID) }
        let lockedDTO = lockedDots.map { DotDTO(beaconID: $0.beaconID, x: $0.mapPoint.x, y: $0.mapPoint.y, elevation: getElevation(for: $0.beaconID)) }
        if let lockedData = try? JSONEncoder().encode(lockedDTO) {
            UserDefaults.standard.set(lockedData, forKey: lockedDotsKey)
        }
        
        saveLocks()
    }

    private func saveLocks() {
        let payload = LocksDTO(locks: locked)
        ctx.write(locksKey, value: payload, alsoWriteLegacy: true)
    }

    private func load() {
        // Dots
        if let dto: [DotDTO] = ctx.read(dotsKey, as: [DotDTO].self) {
            self.dots = dto.map { dotDTO in
                var dot = Dot(beaconID: dotDTO.beaconID,
                             color: beaconColor(for: dotDTO.beaconID),
                             mapPoint: CGPoint(x: dotDTO.x, y: dotDTO.y))
                // Handle backward compatibility - if elevation exists in DTO, use it
                if dotDTO.elevation != 0.75 || elevations[dotDTO.beaconID] == nil {
                    dot.elevation = dotDTO.elevation
                    elevations[dotDTO.beaconID] = dotDTO.elevation
                }
                return dot
            }
        }

        loadLocks()
        loadElevations()
        loadTxPower()
    }
    
    private func loadLocks() {
        if let locksDTO: LocksDTO = ctx.read(locksKey, as: LocksDTO.self) {
            self.locked = locksDTO.locks
        }
    }
    
    private func saveElevations() {
        ctx.write(elevationsKey, value: elevations, alsoWriteLegacy: true)
    }
    
    private func loadElevations() {
        if let e: [String: Double] = ctx.read(elevationsKey, as: [String: Double].self) {
            self.elevations = e
        }
    }
    
    private func loadTxPower() {
        if let t: [String: Int] = ctx.read(txPowerKey, as: [String: Int].self) {
            self.txPowerByID = t
        }
    }
    
    private func saveTxPower() {
        ctx.write(txPowerKey, value: txPowerByID, alsoWriteLegacy: true)
    }

    private func beaconColor(for beaconID: String) -> Color {
        let hash = beaconID.hash
        let hue = Double(abs(hash % 360)) / 360.0
        return Color(hue: hue, saturation: 0.7, brightness: 0.8)
    }
}
