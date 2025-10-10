//
//  RSSILabelsOverlay.swift
//  TapResolver
//
//  Created by restructuring on 9/19/25.
//

import SwiftUI

struct RSSILabelsOverlay: View {
    @EnvironmentObject private var btScanner: BluetoothScanner
    @EnvironmentObject private var beaconDotStore: BeaconDotStore
    @EnvironmentObject private var beaconLists: BeaconListsStore
    @EnvironmentObject private var mapTransform: MapTransformStore
    @EnvironmentObject private var beaconState: BeaconStateManager  // Added for consolidated beacon state
    
    @State private var rssiLabels: [RSSILabel] = []
    @State private var isRSSIActive = false
    // Timer removed - now observing BeaconStateManager's published updates
    
    var body: some View { 
        ZStack {
            Color.clear
            
            // RSSI Labels when active
            if isRSSIActive && !rssiLabels.isEmpty {
                ForEach(rssiLabels) { label in
                    RSSIPillLabel(label: label)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .rssiStateChanged)) { notification in
            if let isActive = notification.object as? Bool {
                isRSSIActive = isActive
                if isActive {
                    startRSSIUpdates()
                } else {
                    stopRSSIUpdates()
                }
            }
        }
        // ARCHITECTURAL UPDATE: Auto-refresh labels when BeaconStateManager updates
        // This replaces the previous local timer pattern
        .onChange(of: beaconState.liveBeacons) { _ in
            if isRSSIActive {
                updateRSSILabels()
            }
        }
    }
    
    // ARCHITECTURAL UPDATE: No longer needs local timer
    // BeaconStateManager updates every 0.5s, we just observe changes
    private func startRSSIUpdates() {
        updateRSSILabels()
        // Labels will auto-update via beaconState @Published property changes
    }
    
    // ARCHITECTURAL UPDATE: No timer to invalidate
    private func stopRSSIUpdates() {
        rssiLabels.removeAll()
    }
    
    // ARCHITECTURAL UPDATE: Now queries BeaconStateManager instead of BluetoothScanner
    // Uses consistent 3-second staleness window and benefits from unified update timing
    private func updateRSSILabels() {
        var newLabels: [RSSILabel] = []
        
        // Get beacons that are both listed and have dots on the map
        let activeBeacons = beaconLists.beacons.filter { beaconName in
            beaconDotStore.dots.contains { $0.beaconID == beaconName }
        }
        
        for beaconName in activeBeacons {
            // Find the beacon dot position
            if let dot = beaconDotStore.dots.first(where: { $0.beaconID == beaconName }) {
                // ARCHITECTURAL UPDATE: Query BeaconStateManager for active beacon data
                if let liveBeacon = beaconState.beacon(named: beaconName),
                   liveBeacon.isActive {
                    // Use exact beacon dot position
                    let beaconDotX = dot.mapPoint.x
                    let beaconDotY = dot.mapPoint.y
                    
                    let rssiLabelPosX = beaconDotX + 0
                    let rssiLabelPosY = beaconDotY - 20
                    
                    // Keep in MAP-LOCAL coords so it rides with the map transforms.
                    let mapLocalPosition = CGPoint(x: rssiLabelPosX, y: rssiLabelPosY)

                    let rssiLabel = RSSILabel(
                        beaconID: beaconName,
                        rssiValue: liveBeacon.rssi,  // From BeaconStateManager
                        mapPosition: mapLocalPosition
                    )

                    newLabels.append(rssiLabel)
                }
            }
        }
        
        rssiLabels = newLabels
    }
}

// MARK: - RSSI Pill Label Component
struct RSSIPillLabel: View {
    let label: RSSILabel
    
    var body: some View {
        Text("\(label.rssiValue) dBm")
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.7))
            )
            .position(label.mapPosition)
    }
}
