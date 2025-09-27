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

                // 0) Wire the scanner → utility (per-ad ingest)
                scanner.scanUtility = scanUtility

                // 1) Configure the utility's closures (exclusion + metadata)
                configureScanUtilityClosures()

                // 2) Restore persisted state
                loadLockedItems()

                // 3) Run one-time snapshot scan + rebuild lists
                runInitialScan()
            }
    }
    
    /// Load locked items on app launch (beacons and squares)
    private func loadLockedItems() {
        // Restore all previously saved beacon dots and their positions
        beaconDots.restoreAllDots()
        
        // Also restore locked beacon names to the beacon list
        let lockedBeaconNames = beaconDots.locked.keys.filter { beaconDots.isLocked($0) }
        lists.beacons = lockedBeaconNames
        
        // Squares are already loaded by their respective stores in init()
        // No additional action needed for squares
    }
    
    /// Kick off a brief BLE scan, then stop, dump table, and ingest discovered devices.
    private func runInitialScan() {
        // Start immediately (safe if not powered on; we'll re-try shortly)
        scanner.start()

        // Re-try shortly in case the central wasn't powered on yet
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.scanner.start()
        }

        // Stop after the window, print a snapshot table, and ingest into lists
        DispatchQueue.main.asyncAfter(deadline: .now() + initialScanWindow) {
            self.scanner.dumpSummaryTable()
            self.scanner.stop()

            // Clear unlocked beacons and morgue before ingesting new devices
            self.refreshBeaconLists()
            
            // Ingest each unique device by (name, id)
            for d in self.scanner.devices {
                self.lists.ingest(deviceName: d.name, id: d.id)
            }
        }
    }
    
    /// Refresh beacon lists by clearing unlocked beacons and morgue
    private func refreshBeaconLists() {
        // Get locked beacon names from beaconDotStore
        let lockedBeaconNames = beaconDots.locked.keys.filter { beaconDots.isLocked($0) }
        
        // Clear unlocked beacons and morgue
        lists.clearUnlockedBeacons(lockedBeaconNames: lockedBeaconNames)
        lists.morgue.removeAll()
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

        // Provide meta for known beacons (x,y,z,label, tx if added later)
        scanUtility.resolveBeaconMeta = { [weak beaconDots] beaconID in
            guard let dots = beaconDots?.dots,
                  let dot = dots.first(where: { $0.beaconID == beaconID }) else {
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
                posZ_m: beaconDots?.getElevation(for: beaconID),
                txPowerSettingDbm: nil
            )
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
