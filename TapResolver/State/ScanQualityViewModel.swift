//
//  ScanQualityViewModel.swift
//  TapResolver
//
//  Created for scan quality HUD display
//

import SwiftUI

struct ScanQualityViewModel {
    struct BeaconStatus: Identifiable {
        let id = UUID()
        let beaconID: String        // e.g., "05-bouncyLynx"
        let color: Color
        let prefix: String          // "05"
        let rssiMedian: Int?        // nil if not detected
        let signalQuality: Quality  // .none, .poor, .fair, .good
        let stabilityPercent: Double // 0.0-1.0 for ring fill (based on MAD)
        let detectionOrder: Int     // Order in which beacon was detected
    }
    
    enum Quality {
        case none      // gray, not detected
        case poor      // red, RSSI < -90 dBm
        case fair      // yellow, RSSI -80 to -90 dBm
        case good      // green, RSSI > -80 dBm
        
        var color: Color {
            switch self {
            case .none: return Color.white.opacity(0.15)
            case .poor: return Color.red.opacity(0.8)
            case .fair: return Color.yellow.opacity(0.8)
            case .good: return Color.green.opacity(0.8)
            }
        }
    }
    
    let detectedCount: Int
    let totalBeacons: Int
    let beacons: [BeaconStatus]
    
    var detectionFraction: Double {
        guard totalBeacons > 0 else { return 0 }
        return Double(detectedCount) / Double(totalBeacons)
    }
    
    var averageQuality: Double {
        let detected = beacons.filter { $0.signalQuality != .none }
        guard !detected.isEmpty else { return 0 }
        
        let qualitySum = detected.reduce(0.0) { sum, beacon in
            let qualityValue: Double
            switch beacon.signalQuality {
            case .none: qualityValue = 0.0
            case .poor: qualityValue = 0.3
            case .fair: qualityValue = 0.65
            case .good: qualityValue = 1.0
            }
            return sum + qualityValue
        }
        
        return qualitySum / Double(detected.count)
    }
    
    var masterDonutColor: Color {
        if averageQuality >= 0.8 {
            return Color.green.opacity(0.8)
        } else if averageQuality >= 0.5 {
            return Color.yellow.opacity(0.8)
        } else {
            return Color.red.opacity(0.8)
        }
    }
}

// MARK: - Dummy Data Generator

extension ScanQualityViewModel {
    static var dummyData: ScanQualityViewModel {
        ScanQualityViewModel(
            detectedCount: 8,
            totalBeacons: 13,
            beacons: [
                // Detected beacons (in detection order)
                BeaconStatus(
                    beaconID: "05-bouncyLynx",
                    color: Color(hue: 0.6, saturation: 0.7, brightness: 0.8),
                    prefix: "05",
                    rssiMedian: -72,
                    signalQuality: .good,
                    stabilityPercent: 0.85,
                    detectionOrder: 1
                ),
                BeaconStatus(
                    beaconID: "07-happyParakeet",
                    color: Color(hue: 0.3, saturation: 0.7, brightness: 0.8),
                    prefix: "07",
                    rssiMedian: -85,
                    signalQuality: .fair,
                    stabilityPercent: 0.60,
                    detectionOrder: 2
                ),
                BeaconStatus(
                    beaconID: "08-spuriousCurr",
                    color: Color(hue: 0.1, saturation: 0.7, brightness: 0.8),
                    prefix: "08",
                    rssiMedian: -93,
                    signalQuality: .poor,
                    stabilityPercent: 0.40,
                    detectionOrder: 3
                ),
                BeaconStatus(
                    beaconID: "12-cleverFox",
                    color: Color(hue: 0.05, saturation: 0.7, brightness: 0.8),
                    prefix: "12",
                    rssiMedian: -76,
                    signalQuality: .good,
                    stabilityPercent: 0.78,
                    detectionOrder: 4
                ),
                BeaconStatus(
                    beaconID: "15-swiftEagle",
                    color: Color(hue: 0.75, saturation: 0.7, brightness: 0.8),
                    prefix: "15",
                    rssiMedian: -81,
                    signalQuality: .fair,
                    stabilityPercent: 0.65,
                    detectionOrder: 5
                ),
                BeaconStatus(
                    beaconID: "18-boldWolf",
                    color: Color(hue: 0.85, saturation: 0.7, brightness: 0.8),
                    prefix: "18",
                    rssiMedian: -74,
                    signalQuality: .good,
                    stabilityPercent: 0.82,
                    detectionOrder: 6
                ),
                BeaconStatus(
                    beaconID: "04-quietPanther",
                    color: Color(hue: 0.45, saturation: 0.7, brightness: 0.8),
                    prefix: "04",
                    rssiMedian: -88,
                    signalQuality: .fair,
                    stabilityPercent: 0.55,
                    detectionOrder: 7
                ),
                BeaconStatus(
                    beaconID: "09-proudToad",
                    color: Color(hue: 0.2, saturation: 0.7, brightness: 0.8),
                    prefix: "09",
                    rssiMedian: -95,
                    signalQuality: .poor,
                    stabilityPercent: 0.35,
                    detectionOrder: 8
                ),
                
                // Undetected beacons (no detection order, quality = .none)
                BeaconStatus(
                    beaconID: "01-lazySloth",
                    color: Color(hue: 0.15, saturation: 0.7, brightness: 0.8),
                    prefix: "01",
                    rssiMedian: nil,
                    signalQuality: .none,
                    stabilityPercent: 0.0,
                    detectionOrder: 999
                ),
                BeaconStatus(
                    beaconID: "02-shyTurtle",
                    color: Color(hue: 0.55, saturation: 0.7, brightness: 0.8),
                    prefix: "02",
                    rssiMedian: nil,
                    signalQuality: .none,
                    stabilityPercent: 0.0,
                    detectionOrder: 999
                ),
                BeaconStatus(
                    beaconID: "03-sleepyBear",
                    color: Color(hue: 0.4, saturation: 0.7, brightness: 0.8),
                    prefix: "03",
                    rssiMedian: nil,
                    signalQuality: .none,
                    stabilityPercent: 0.0,
                    detectionOrder: 999
                ),
                BeaconStatus(
                    beaconID: "10-calmOwl",
                    color: Color(hue: 0.65, saturation: 0.7, brightness: 0.8),
                    prefix: "10",
                    rssiMedian: nil,
                    signalQuality: .none,
                    stabilityPercent: 0.0,
                    detectionOrder: 999
                ),
                BeaconStatus(
                    beaconID: "11-gentleDeer",
                    color: Color(hue: 0.8, saturation: 0.7, brightness: 0.8),
                    prefix: "11",
                    rssiMedian: nil,
                    signalQuality: .none,
                    stabilityPercent: 0.0,
                    detectionOrder: 999
                )
            ].sorted { $0.detectionOrder < $1.detectionOrder } // Sort by detection order
        )
    }
}

// MARK: - Simple Real Data (Step 1: Count Only)

extension ScanQualityViewModel {
    static func countOnly(
        btScanner: BluetoothScanner, 
        beaconLists: BeaconListsStore,
        beaconDotStore: BeaconDotStore
    ) -> ScanQualityViewModel {
        // Only count beacons that have dots on the map
        let beaconsWithDots = beaconDotStore.dots.map { $0.beaconID }
        let totalBeacons = beaconsWithDots.count
        
        // Only count detected beacons that also have dots
        let detectedCount = btScanner.devices.filter { device in
            beaconsWithDots.contains(device.name)
        }.count
        
        // Return dummy beacons, but with real counts
        return ScanQualityViewModel(
            detectedCount: detectedCount,
            totalBeacons: totalBeacons,
            beacons: dummyData.beacons // Keep dummy visual for now
        )
    }
}

// MARK: - Real Data Builder

extension ScanQualityViewModel {
    static func fromRealData(
        btScanner: BluetoothScanner,
        beaconDotStore: BeaconDotStore,
        scanUtility: MapPointScanUtility
    ) -> ScanQualityViewModel {

        // Get all beacons that have dots on the map
        let beaconsWithDots: [BeaconDotStore.Dot] = beaconDotStore.dots
        let totalBeacons: Int = beaconsWithDots.count

        // Build detection state map: beaconID -> (rssi, timestamp)
        var detectionState: [String: (rssi: Int, lastSeen: Date)] = [:]
        for device in btScanner.devices {
            detectionState[device.name] = (device.rssi, device.lastSeen)
        }

        // Track detection order (earlier = lower number)
        var detectionOrder: [String: Int] = [:]
        var orderCounter: Int = 0

        // Build beacon status for each dot
        var beaconStatuses: [BeaconStatus] = []

        for dot in beaconsWithDots {
            let beaconID: String = dot.beaconID

            // Extract prefix (e.g., "05" from "05-bouncyLynx")
            let prefix: String = beaconID.split(separator: "-").first.map(String.init) ?? "??"

            // Check if currently detected (within last 3 seconds)
            let now: Date = Date()
            var currentRSSI: Int? = nil
            var signalQuality: Quality = .none
            var isCurrentlyDetected: Bool = false

            if let detection = detectionState[beaconID],
               now.timeIntervalSince(detection.lastSeen) < 3.0 {
                currentRSSI = detection.rssi
                isCurrentlyDetected = true

                // Assign detection order if not yet tracked
                if detectionOrder[beaconID] == nil {
                    detectionOrder[beaconID] = orderCounter
                    orderCounter += 1
                }

                // Calculate signal quality from RSSI
                signalQuality = qualityFromRSSI(detection.rssi)
            }

            // Get stability from last scan record (MAD-based)
            let stabilityPercent: Double = stabilityFromMAD(
                beaconID: beaconID,
                scanRecord: scanUtility.lastScanRecord
            )

            // Determine sort order
            let sortOrder: Int
            if isCurrentlyDetected {
                // Currently detected: use detection order
                sortOrder = detectionOrder[beaconID] ?? 9999
            } else if let lastOrder = detectionOrder[beaconID] {
                // Was detected, now silent: push after detected beacons
                sortOrder = 1000 + lastOrder
            } else {
                // Never detected: sort alphanumerically at the end
                sortOrder = 10000 + beaconID.hashValue
            }

            beaconStatuses.append(BeaconStatus(
                beaconID: beaconID,
                color: dot.color,
                prefix: prefix,
                rssiMedian: currentRSSI,
                signalQuality: signalQuality,
                stabilityPercent: stabilityPercent,
                detectionOrder: sortOrder
            ))
        }

        // Sort by detection order
        beaconStatuses.sort { $0.detectionOrder < $1.detectionOrder }

        // Count currently detected beacons
        let detectedCount: Int = beaconStatuses.filter { $0.signalQuality != .none }.count

        return ScanQualityViewModel(
            detectedCount: detectedCount,
            totalBeacons: totalBeacons,
            beacons: beaconStatuses
        )
    }

    // MARK: - Helper Functions

    private static func qualityFromRSSI(_ rssi: Int) -> Quality {
        if rssi > -80 {
            return .good
        } else if rssi >= -90 {
            return .fair
        } else {
            return .poor
        }
    }

    private static func stabilityFromMAD(
        beaconID: String,
        scanRecord: MapPointScanUtility.ScanRecord?
    ) -> Double {
        guard let record = scanRecord,
              let aggregate = record.beacons.first(where: { $0.beacon.beaconID == beaconID }),
              let madDb = aggregate.madDb else {
            return 0.0
        }

        // Convert MAD to stability percentage
        // Lower MAD = more stable = higher percentage
        // MAD of 0 = 100% stability, MAD of 10+ = 0% stability
        let stability: Double = max(0.0, min(1.0, 1.0 - (madDb / 10.0)))
        return stability
    }
}
