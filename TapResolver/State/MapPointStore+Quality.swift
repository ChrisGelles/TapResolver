//
//  MapPointStore+Quality.swift
//  TapResolver
//
//  Scan quality evaluation for MapPointStore
//

import Foundation
import SwiftUI

extension MapPointStore {
    
    /// Quality categories for map point scans
    enum ScanQuality: Comparable {
        case none, poor, fair, good
        
        var color: Color {
            switch self {
            case .none: return Color.gray.opacity(0.4)
            case .poor: return .red
            case .fair: return .orange
            case .good: return .green
            }
        }
        
        var description: String {
            switch self {
            case .none: return "No data"
            case .poor: return "Poor - needs attention"
            case .fair: return "Fair"
            case .good: return "Good"
            }
        }
    }
    
    /// Calculate overall scan quality for a map point based on worst session
    func scanQuality(for pointID: UUID) -> ScanQuality {
        guard let point = points.first(where: { $0.id == pointID }) else {
            return .none
        }
        
        guard !point.sessions.isEmpty else {
            return .none
        }
        
        // Evaluate each session and take the WORST quality (highlights problems)
        let qualities = point.sessions.map { session in
            evaluateSessionQuality(session)
        }
        
        return qualities.min() ?? .none
    }
    
    /// Evaluate quality of a single session based on beacon RSSI values
    private func evaluateSessionQuality(_ session: ScanSession) -> ScanQuality {
        // Count beacons with good RSSI (> -80 dBm)
        let goodBeacons = session.beacons.filter { beacon in
            beacon.stats.median_dbm > -80  // Good signal threshold
        }.count
        
        // Categorize based on good beacon count
        // 3+ good beacons = acceptable scan
        switch goodBeacons {
        case 0:
            return .none
        case 1...2:
            return .poor
        case 3...4:
            return .fair
        default:
            return .good  // 5+ good beacons
        }
    }
}

