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
    
    @State private var rssiLabels: [RSSILabel] = []
    @State private var isRSSIActive = false
    @State private var timer: Timer?
    
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
    }
    
    private func startRSSIUpdates() {
        updateRSSILabels()
        // Set up timer for continuous updates
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            updateRSSILabels()
        }
    }
    
    private func stopRSSIUpdates() {
        timer?.invalidate()
        timer = nil
        rssiLabels.removeAll()
    }
    
    private func updateRSSILabels() {
        var newLabels: [RSSILabel] = []
        
        // Get beacons that are both listed and have dots on the map
        let activeBeacons = beaconLists.beacons.filter { beaconName in
            beaconDotStore.dots.contains { $0.beaconID == beaconName }
        }
        
        for beaconName in activeBeacons {
            // Find the beacon dot position
            if let dot = beaconDotStore.dots.first(where: { $0.beaconID == beaconName }) {
                // Find RSSI value from scanner
                if let device = btScanner.devices.first(where: { $0.name == beaconName }) {
                    // Use exact beacon dot position
                    let beaconDotX = dot.mapPoint.x
                    let beaconDotY = dot.mapPoint.y
                    
                    let rssiLabelPosX = beaconDotX + 0
                    let rssiLabelPosY = beaconDotY - 20
                    
                    // Keep in MAP-LOCAL coords so it rides with the map transforms.
                    let mapLocalPosition = CGPoint(x: rssiLabelPosX, y: rssiLabelPosY)

                    let rssiLabel = RSSILabel(
                        beaconID: beaconName,
                        rssiValue: device.rssi,
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