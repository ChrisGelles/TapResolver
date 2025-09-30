//
//  AppBootstrap.swift
//  TapResolver
//
//  Created by restructuring on 9/19/25.
//

import SwiftUI


struct AppBootstrap: ViewModifier {
    let scanner: BluetoothScanner
    let beaconDots: BeaconDotStore
    let squares: MetricSquareStore
    let lists: BeaconListsStore
    let scanUtility: MapPointScanUtility

    private let initialScanWindow: TimeInterval = 2.0

    // Run-once guard to prevent double wiring on scene changes
    private static var hasBootstrapped = false

    func body(content: Content) -> some View {
        content
            .onAppear {
                // Prevent double running on scene activations
                guard !Self.hasBootstrapped else { return }
                Self.hasBootstrapped = true

                createLocationStubIfNeeded()
                scanner.scanUtility = scanUtility
                configureScanUtilityClosures()
            }
    }
    
    
    
    private func configureScanUtilityClosures() {
        // Exclude anything NOT in Beacon Drawer or without a dot
        scanUtility.isExcluded = { [weak lists, weak beaconDots] beaconID, name in
            guard let lists = lists, let beaconDots = beaconDots else { return true }
            guard let name = name, !name.isEmpty else { return true }
            guard lists.beacons.contains(name) else { return true }
            guard beaconDots.dots.contains(where: { $0.beaconID == name }) else { return true }
            return false
        }

        // Provide meta for known beacons (x,y,z,label, tx power)
        scanUtility.resolveBeaconMeta = { [weak beaconDots] beaconID in
            guard let store = beaconDots,
                  let dot = store.dots.first(where: { $0.beaconID == beaconID }) else {
                return MapPointScanUtility.BeaconMeta(
                    beaconID: beaconID, name: beaconID,
                    posX_m: nil, posY_m: nil, posZ_m: nil,
                    txPowerSettingDbm: nil
                )
            }

            return MapPointScanUtility.BeaconMeta(
                beaconID: beaconID,
                name: beaconID,
                posX_m: Double(dot.mapPoint.x),
                posY_m: Double(dot.mapPoint.y),
                posZ_m: store.getElevation(for: beaconID),
                txPowerSettingDbm: store.getTxPower(for: beaconID)
            )
        }
    }
    
    /// Create a location.json stub for future use
    private func createLocationStubIfNeeded() {
        struct LocationStub: Codable {
            let id: String
            let name: String
            let createdISO: String
            let updatedISO: String
        }
        
        let ctx = PersistenceContext.shared
        let fm = FileManager.default
        let locationJSONPath = ctx.locationDir.appendingPathComponent("location.json")
        
        if !fm.fileExists(atPath: locationJSONPath.path) {
            let now = ISO8601DateFormatter().string(from: Date())
            let stub = LocationStub(id: ctx.locationID, name: "Default Location", createdISO: now, updatedISO: now)
            if let data = try? JSONEncoder().encode(stub) {
                try? data.write(to: locationJSONPath, options: .atomic)
                print("📁 Created location.json stub at \(locationJSONPath.path)")
            }
        }
    }
}

extension View {
    func appBootstrap(
        scanner: BluetoothScanner,
        beaconDots: BeaconDotStore,
        squares: MetricSquareStore,
        lists: BeaconListsStore,
        scanUtility: MapPointScanUtility
    ) -> some View {
        self.modifier(AppBootstrap(
            scanner: scanner,
            beaconDots: beaconDots,
            squares: squares,
            lists: lists,
            scanUtility: scanUtility
        ))
    }
}
