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

                // 0) Ensure location directories exist
                PersistenceContext.shared.ensureLocationDirs()
                UserDefaults.standard.set("default", forKey: "locations.lastOpened.v1")
                
                // 0.1) Create location.json stub if it doesn't exist
                createLocationStubIfNeeded()

                // 1) Wire the scanner → utility (per-ad ingest)
                scanner.scanUtility = scanUtility

                // 2) Configure the utility's closures (exclusion + metadata)
                configureScanUtilityClosures()

                // 3) Restore persisted state
                loadLockedItems()

                // 4) Run one-time snapshot scan + rebuild lists
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
        if !fm.fileExists(atPath: ctx.locationJSON.path) {
            let now = ISO8601DateFormatter().string(from: Date())
            let stub = LocationStub(id: ctx.locationID, name: "Default Location", createdISO: now, updatedISO: now)
            if let data = try? JSONEncoder().encode(stub) {
                try? data.write(to: ctx.locationJSON, options: .atomic)
                print("📁 Created location.json stub at \(ctx.locationJSON.path)")
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
