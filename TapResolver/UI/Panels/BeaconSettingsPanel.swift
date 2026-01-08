//
//  BeaconSettingsPanel.swift
//  TapResolver
//
//  Created by Chris Gelles on 1/3/26.
//


//
//  BeaconSettingsPanel.swift
//  TapResolver
//
//  Panel for bulk beacon configuration.
//

import SwiftUI
import kbeaconlib2

struct BeaconSettingsPanel: View {
    @EnvironmentObject private var beaconDotStore: BeaconDotStore
    @EnvironmentObject private var locationManager: LocationManager
    
    @StateObject private var kbeaconManager = KBeaconConnectionManager()
    
    @Binding var isPresented: Bool
    
    // Configuration values
    @State private var selectedTxPower: Int = -4
    @State private var intervalText: String = "1000"
    
    // Beacon selection
    @State private var selectedBeaconIDs: Set<String> = []
    
    // Progress state
    @State private var showProgress: Bool = false
    @State private var configurationResults: [BeaconConfigResult] = []
    
    private let txPowerOptions: [Int] = [8, 4, 0, -4, -8, -12, -16, -20, -40]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Configuration section
                configurationSection
                
                Divider()
                
                // Beacon selection list
                beaconSelectionList
                
                Divider()
                
                // Action buttons
                actionButtons
            }
            .navigationTitle("Beacon Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
        .sheet(isPresented: $showProgress) {
            BeaconConfigProgressView(
                results: $configurationResults,
                onClose: {
                    showProgress = false
                }
            )
        }
    }
    
    // MARK: - Configuration Section
    
    private var configurationSection: some View {
        VStack(spacing: 16) {
            // TX Power picker
            HStack {
                Text("TX Power")
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                Picker("TX Power", selection: $selectedTxPower) {
                    ForEach(txPowerOptions, id: \.self) { power in
                        Text("\(power) dBm").tag(power)
                    }
                }
                .pickerStyle(.menu)
            }
            
            // Interval text field
            HStack {
                Text("Interval")
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                TextField("1000", text: $intervalText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                Text("ms")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
    
    // MARK: - Beacon Selection List
    
    private var beaconSelectionList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Select Beacons")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Button(selectedBeaconIDs.count == beaconDotStore.dots.count ? "Deselect All" : "Select All") {
                    if selectedBeaconIDs.count == beaconDotStore.dots.count {
                        selectedBeaconIDs.removeAll()
                    } else {
                        selectedBeaconIDs = Set(beaconDotStore.dots.map { $0.beaconID })
                    }
                }
                .font(.system(size: 12))
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(beaconDotStore.dots.sorted(by: { $0.beaconID < $1.beaconID }), id: \.beaconID) { dot in
                        BeaconSelectionRow(
                            beaconID: dot.beaconID,
                            isSelected: selectedBeaconIDs.contains(dot.beaconID),
                            currentTxPower: beaconDotStore.getTxPower(for: dot.beaconID),
                            currentInterval: beaconDotStore.getAdvertisingInterval(for: dot.beaconID),
                            onToggle: {
                                if selectedBeaconIDs.contains(dot.beaconID) {
                                    selectedBeaconIDs.remove(dot.beaconID)
                                } else {
                                    selectedBeaconIDs.insert(dot.beaconID)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 16) {
            Button {
                startConfiguration()
            } label: {
                Text("Confirm")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(selectedBeaconIDs.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(10)
            }
            .disabled(selectedBeaconIDs.isEmpty)
            
            Button {
                isPresented = false
            } label: {
                Text("Cancel")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
            }
        }
        .padding()
    }
    
    // MARK: - Configuration Logic
    
    private func startConfiguration() {
        guard !selectedBeaconIDs.isEmpty else { return }
        
        guard let interval = Float(intervalText), interval > 0 else {
            // TODO: Show error for invalid interval
            return
        }
        
        // Get password for current location
        let locationID = PersistenceContext.shared.locationID
        guard let password = BeaconPasswordStore.shared.getPassword(for: locationID) else {
            print("⚠️ [BeaconSettings] No password stored for location '\(locationID)'")
            return
        }
        
        // Initialize results for all selected beacons
        configurationResults = selectedBeaconIDs.sorted().map { beaconID in
            BeaconConfigResult(beaconID: beaconID, status: .waiting)
        }
        
        showProgress = true
        
        // Start scanning for beacons
        kbeaconManager.startScanning()
        
        // Wait for scan results, then process
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [self] in
            kbeaconManager.stopScanning()
            
            let discoveredBeacons = kbeaconManager.discoveredBeacons
            print("📡 [BeaconSettings] Found \(discoveredBeacons.count) beacon(s)")
            
            // Match selected beacons to discovered devices
            var matchedBeacons: [(beaconID: String, device: KBeacon)] = []
            for beaconID in selectedBeaconIDs.sorted() {
                if let device = discoveredBeacons.first(where: { $0.name == beaconID }) {
                    matchedBeacons.append((beaconID: beaconID, device: device))
                } else {
                    // Mark as failed - not found
                    updateResult(for: beaconID, status: .failed, error: "Not found in scan")
                }
            }
            
            // Process matched beacons sequentially
            configureSequentially(beacons: matchedBeacons, password: password, index: 0)
        }
    }
    
    private func configureSequentially(
        beacons: [(beaconID: String, device: KBeacon)],
        password: String,
        index: Int
    ) {
        // Base case: all beacons processed
        guard index < beacons.count else {
            print("✅ [BeaconSettings] Configuration complete - \(beacons.count) beacon(s)")
            return
        }
        
        let (beaconID, device) = beacons[index]
        
        // Helper to process next beacon
        func processNext() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.configureSequentially(beacons: beacons, password: password, index: index + 1)
            }
        }
        
        // Update status: connecting
        updateResult(for: beaconID, status: .connecting)
        
        kbeaconManager.connect(to: device, password: password) { [self] success, message in
            guard success else {
                updateResult(for: beaconID, status: .failed, error: message)
                processNext()
                return
            }
            
            // Update status: writing
            updateResult(for: beaconID, status: .settingTxPower)
            
            // Write configuration
            kbeaconManager.writeConfiguration(
                to: device,
                txPower: selectedTxPower,
                intervalMs: Float(intervalText) ?? 1000.0
            ) { [self] writeSuccess, writeMessage in
                guard writeSuccess else {
                    updateResult(for: beaconID, status: .failed, error: writeMessage)
                    kbeaconManager.disconnect(from: device)
                    processNext()
                    return
                }
                
                // Update status: verifying
                updateResult(for: beaconID, status: .verifying)
                
                // Read back to verify
                if let config = kbeaconManager.readConfiguration(from: device) {
                    // Verify values match
                    let targetInterval = Float(intervalText) ?? 1000.0
                    let txMatch = config.txPower == selectedTxPower
                    let intervalMatch = abs(config.intervalMs - targetInterval) < 1.0
                    
                    if txMatch && intervalMatch {
                        // Success! Update BeaconDotStore
                        beaconDotStore.updateFromDeviceConfig(
                            beaconName: beaconID,
                            txPower: config.txPower,
                            intervalMs: config.intervalMs,
                            mac: device.mac,
                            model: config.model,
                            firmware: config.firmwareVersion
                        )
                        
                        updateResult(for: beaconID, status: .complete)
                        print("✅ [BeaconSettings] \(beaconID): TX=\(config.txPower)dBm, Interval=\(Int(config.intervalMs))ms")
                    } else {
                        updateResult(for: beaconID, status: .failed, error: "Verification failed: TX=\(config.txPower), Interval=\(Int(config.intervalMs))")
                    }
                } else {
                    updateResult(for: beaconID, status: .failed, error: "Failed to read back configuration")
                }
                
                kbeaconManager.disconnect(from: device)
                processNext()
            }
        }
    }
    
    private func updateResult(for beaconID: String, status: BeaconConfigResult.ConfigStatus, error: String? = nil) {
        if let idx = configurationResults.firstIndex(where: { $0.beaconID == beaconID }) {
            configurationResults[idx].status = status
            configurationResults[idx].errorMessage = error
        }
    }
}

// MARK: - Supporting Types

struct BeaconConfigResult: Identifiable {
    let id = UUID()
    let beaconID: String
    var status: ConfigStatus
    var errorMessage: String?
    
    enum ConfigStatus {
        case waiting
        case connecting
        case settingTxPower
        case settingInterval
        case verifying
        case complete
        case failed
    }
}

// MARK: - Beacon Selection Row

struct BeaconSelectionRow: View {
    let beaconID: String
    let isSelected: Bool
    let currentTxPower: Int?
    let currentInterval: Double
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isSelected ? .blue : .gray)
                
                Text(beaconID)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Current values
                VStack(alignment: .trailing, spacing: 2) {
                    if let txPower = currentTxPower {
                        Text("\(txPower) dBm")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    Text("\(Int(currentInterval)) ms")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}