//
//  HUDContainer.swift
//  TapResolver
//
//  Created by restructuring on 9/19/25.
//

import SwiftUI

struct HUDContainer: View {
    var body: some View {
        ZStack {
            Color.clear.ignoresSafeArea().allowsHitTesting(false)
            CrosshairHUDOverlay() // shows crosshairs at screen center when beacons drawer is open
            VStack(spacing: 8) {
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 8) {
                        MetricSquareDrawer()
                            .padding(.top, 60)
                            .padding(.trailing, 0)
                        BeaconDrawer()
                        MorgueDrawer()                  // ← added, sits next to Beacon drawer
                        ResetMapButton()
                        
                        // Radio waves button: start scan + dump snapshot to console
                        BluetoothScanButton()
                        
                        RSSIMeterButton()
                    }
                    
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .allowsHitTesting(true)
            
            // Numeric keypad for square meters (only visible when editing)
            SquareMetersKeypadInterface()
                .zIndex(200)                  // above everything in the HUD
                .allowsHitTesting(true)       // it must receive touches when shown
            
            // Elevation keypad for beacons (only visible when editing)
            NumericKeypadInterface()
                .zIndex(200)
                .allowsHitTesting(true)
        }
        .zIndex(100)
    }
}

private struct ResetMapButton: View {
    var body: some View {
        Button {
            NotificationCenter.default.post(name: .resetMapTransform, object: nil)
        } label: {
            Image(systemName: "arrow.counterclockwise.circle")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.primary)
                .padding(10)
                .background(.ultraThinMaterial, in: Circle())
        }
        .accessibilityLabel("Reset map view")
        .buttonStyle(.plain)
        .allowsHitTesting(true)
    }
}

private struct BluetoothScanButton: View {
    @EnvironmentObject private var btScanner: BluetoothScanner
    @EnvironmentObject private var beaconLists: BeaconListsStore
    @EnvironmentObject private var beaconDotStore: BeaconDotStore

    var body: some View {
        Button {
            // 1) Run a clean snapshot scan for N seconds (see BluetoothScanner.defaultSnapshotSeconds)
            btScanner.snapshotScan { [weak btScanner, weak beaconLists, weak beaconDotStore] in
                guard let scanner = btScanner, let lists = beaconLists, let dotStore = beaconDotStore else { return }

                // 2) Clear unlocked beacons and morgue before ingesting new devices
                let lockedBeaconNames = dotStore.locked.keys.filter { dotStore.isLocked($0) }
                lists.clearUnlockedBeacons(lockedBeaconNames: lockedBeaconNames)
                lists.morgue.removeAll()

                // 3) After snapshot completes, (re)build lists from what we saw
                for d in scanner.devices {
                    lists.ingest(deviceName: d.name, id: d.id)
                }

                // 4) Optional: print a neat table once per snapshot
                scanner.dumpSummaryTable()
            }
        } label: {
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.primary)
                .padding(10)
                .background(.ultraThinMaterial, in: Circle())
        }
        .accessibilityLabel("Scan Bluetooth (2-second snapshot) & update lists")
        .buttonStyle(.plain)
        .allowsHitTesting(true)
    }
}

// MARK: - RSSI Data Structure
struct RSSILabel: Identifiable {
    let id = UUID()
    let beaconID: String
    let rssiValue: Int
    let mapPosition: CGPoint
}

private struct RSSIMeterButton: View {
    @EnvironmentObject private var btScanner: BluetoothScanner
    @State private var isActive = false

    var body: some View {
        Button {
            isActive.toggle()

            // Start/stop BLE scan to feed live RSSI while active
            if isActive {
                btScanner.start()
            } else {
                btScanner.stop()
            }

            // Notify MeterLabels about state change (it manages the 0.5s timer)
            NotificationCenter.default.post(
                name: .rssiStateChanged,
                object: isActive
            )
        } label: {
            Image(systemName: "target")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.primary)
                .padding(10)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: isActive ? 2 : 0)
                )
        }
        .accessibilityLabel("Add live RSSI values from map beacons to map")
        .buttonStyle(.plain)
        .allowsHitTesting(true)
    }
}