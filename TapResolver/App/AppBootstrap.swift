//
//  AppBootstrap.swift
//  TapResolver
//
//  Created by restructuring on 9/19/25.
//

import SwiftUI

struct AppBootstrap: ViewModifier {
    @EnvironmentObject private var scanner: BluetoothScanner
    @EnvironmentObject private var beaconDots: BeaconDotStore
    @EnvironmentObject private var squares: MetricSquareStore
    @EnvironmentObject private var lists: BeaconListsStore

    private let initialScanWindow: TimeInterval = 2.0

    func body(content: Content) -> some View {
        content
            .onAppear {
                // 1) Restore persisted state
                loadLockedItems()
                
                // 2) Run one-time snapshot scan + rebuild lists
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
}

extension View {
    func appBootstrap() -> some View { self.modifier(AppBootstrap()) }
}
