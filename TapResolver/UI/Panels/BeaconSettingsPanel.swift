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
import UniformTypeIdentifiers
import kbeaconlib2

struct BeaconSettingsPanel: View {
    @EnvironmentObject private var beaconDotStore: BeaconDotStore
    @EnvironmentObject private var beaconListsStore: BeaconListsStore
    @EnvironmentObject private var locationManager: LocationManager
    
    @StateObject private var kbeaconManager = KBeaconConnectionManager()
    
    @Binding var isPresented: Bool
    
    // Configuration values
    @State private var selectedTxPower: Int = -4
    @State private var intervalText: String = "1000"
    
    // Beacon selection
    @State private var selectedBeaconIDs: Set<String> = []
    
    // Pending elevation edits (not saved until "Save Values" pressed)
    @State private var pendingElevations: [String: String] = [:]
    
    // Progress state
    @State private var showProgress: Bool = false
    @State private var configurationResults: [BeaconConfigResult] = []
    
    // Confirmation dialog state
    @State private var showSaveConfirmation: Bool = false
    @State private var pendingChangeCount: Int = 0
    
    // Export state
    @State private var exportFileURL: URL? = nil
    @State private var showShareSheet: Bool = false
    
    // Import state
    @State private var showFilePicker: Bool = false
    @State private var showImportOptions: Bool = false
    @State private var pendingImportData: BeaconExportData? = nil
    
    private let txPowerOptions: [Int] = [8, 4, 0, -4, -8, -12, -16, -20, -40]

    /// Dots filtered to only beacons in the current location's whitelist
    private var filteredDots: [BeaconDotStore.BeaconDotV2] {
        let whitelistedBeaconIDs = Set(beaconListsStore.beacons)
        return beaconDotStore.dots.filter { whitelistedBeaconIDs.contains($0.beaconID) }
    }
    
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
                
                Divider()
                
                // Import/Export section
                importExportSection
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
        .onAppear {
            // Initialize pending elevations from current stored values
            for dot in filteredDots {
                let elevation = beaconDotStore.getElevation(for: dot.beaconID)
                pendingElevations[dot.beaconID] = String(format: "%g", elevation)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = exportFileURL {
                ShareSheet(items: [url])
            }
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .confirmationDialog(
            "Import Options",
            isPresented: $showImportOptions,
            titleVisibility: .visible
        ) {
            Button("Update Existing Only") {
                performImport(mode: .updateOnly)
            }
            Button("Merge (Update + Add New)") {
                performImport(mode: .merge)
            }
            Button("Replace All", role: .destructive) {
                performImport(mode: .replaceAll)
            }
            Button("Cancel", role: .cancel) {
                pendingImportData = nil
            }
        } message: {
            if let data = pendingImportData {
                Text("File contains \(data.beacons.count) beacon(s) from '\(data.locationID)'")
            }
        }
        .alert("Save Elevation Values?", isPresented: $showSaveConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                saveElevationValues()
            }
        } message: {
            Text("This will update \(pendingChangeCount) elevation value\(pendingChangeCount == 1 ? "" : "s").")
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
            // Diagnostic: Show what location we think we're editing
            Text("Location: \(PersistenceContext.shared.locationID)")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.orange)
                .padding(.horizontal)
            
            HStack {
                Text("Select Beacons (\(filteredDots.count))")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Button(selectedBeaconIDs.count == filteredDots.count ? "Deselect All" : "Select All") {
                    if selectedBeaconIDs.count == filteredDots.count {
                        selectedBeaconIDs.removeAll()
                    } else {
                        selectedBeaconIDs = Set(filteredDots.map { $0.beaconID })
                    }
                }
                .font(.system(size: 12))
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(filteredDots.sorted(by: { $0.beaconID < $1.beaconID }), id: \.beaconID) { dot in
                        BeaconSelectionRow(
                            beaconID: dot.beaconID,
                            isSelected: selectedBeaconIDs.contains(dot.beaconID),
                            elevationText: Binding(
                                get: { pendingElevations[dot.beaconID] ?? "0.75" },
                                set: { pendingElevations[dot.beaconID] = $0 }
                            ),
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
        VStack(spacing: 12) {
            // Top row: Save Values + Push to Hardware
            HStack(spacing: 12) {
                Button {
                    confirmSaveElevationValues()
                } label: {
                    Text("Save Values")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.green)
                        .cornerRadius(8)
                }
                
                Button {
                    startConfiguration()
                } label: {
                    Text("Push to Hardware")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selectedBeaconIDs.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(8)
                }
                .disabled(selectedBeaconIDs.isEmpty)
            }
            
            // Bottom row: Read from Hardware + Cancel
            HStack(spacing: 12) {
                Button {
                    readFromHardware()
                } label: {
                    Text("Read from Hardware")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selectedBeaconIDs.isEmpty ? Color.gray : Color.orange)
                        .cornerRadius(8)
                }
                .disabled(selectedBeaconIDs.isEmpty)
                
                Button {
                    isPresented = false
                } label: {
                    Text("Cancel")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
    }
    
    // MARK: - Import/Export Section
    
    private var importExportSection: some View {
        VStack(spacing: 8) {
            Text("Import / Export")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                Button {
                    exportBeacons()
                } label: {
                    Label("Export Beacons", systemImage: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.indigo)
                        .cornerRadius(8)
                }
                
                Button {
                    showFilePicker = true
                } label: {
                    Label("Import Beacons", systemImage: "square.and.arrow.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.indigo)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
    }
    
    // MARK: - Configuration Logic
    
    private func confirmSaveElevationValues() {
        // Count how many values have actually changed
        var changeCount = 0
        
        for (beaconID, elevationString) in pendingElevations {
            if let elevation = Double(elevationString) {
                let currentElevation = beaconDotStore.getElevation(for: beaconID)
                if abs(elevation - currentElevation) > 0.001 {
                    changeCount += 1
                }
            }
        }
        
        if changeCount == 0 {
            print("ℹ️ [BeaconSettings] No elevation changes to save")
            return
        }
        
        pendingChangeCount = changeCount
        showSaveConfirmation = true
    }
    
    private func exportBeacons() {
        let locationID = PersistenceContext.shared.locationID
        
        // Build export items from filtered dots only
        let exportItems: [BeaconExportItem] = filteredDots.map { dot in
            BeaconExportItem(
                beaconID: dot.beaconID,
                x: dot.x,
                y: dot.y,
                elevation: dot.elevation,
                txPower: dot.txPower,
                advertisingInterval: dot.advertisingInterval,
                lastConfigChange: dot.lastConfigChange
            )
        }
        
        // ISO 8601 timestamp
        let formatter = ISO8601DateFormatter()
        let exportedAt = formatter.string(from: Date())
        
        let exportData = BeaconExportData(
            locationID: locationID,
            exportedAt: exportedAt,
            beacons: exportItems
        )
        
        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        guard let jsonData = try? encoder.encode(exportData) else {
            print("❌ [BeaconSettings] Failed to encode export data")
            return
        }
        
        // Generate filename: museum-beacons-20260108-1305.json
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd-HHmm"
        let timestamp = dateFormatter.string(from: Date())
        let filename = "\(locationID)-beacons-\(timestamp).json"
        
        // Write to temp file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        
        do {
            try jsonData.write(to: tempURL)
            exportFileURL = tempURL
            showShareSheet = true
            print("📤 [BeaconSettings] Exported \(exportItems.count) beacons to \(filename)")
        } catch {
            print("❌ [BeaconSettings] Failed to write export file: \(error)")
        }
    }
    
    // MARK: - Import Logic
    
    private enum ImportMode {
        case updateOnly   // Only update beacons that already exist
        case merge        // Update existing + add new
        case replaceAll   // Clear and replace all
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                print("❌ [BeaconSettings] No file selected")
                return
            }
            
            // Need to access security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                print("❌ [BeaconSettings] Cannot access file")
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }
            
            do {
                let data = try Data(contentsOf: url)
                let decoded = try JSONDecoder().decode(BeaconExportData.self, from: data)
                
                print("📥 [BeaconSettings] Parsed \(decoded.beacons.count) beacons from '\(decoded.locationID)'")
                
                pendingImportData = decoded
                showImportOptions = true
                
            } catch {
                print("❌ [BeaconSettings] Failed to parse import file: \(error)")
            }
            
        case .failure(let error):
            print("❌ [BeaconSettings] File picker error: \(error)")
        }
    }
    
    private func performImport(mode: ImportMode) {
        guard let importData = pendingImportData else { return }
        
        let currentBeaconIDs = Set(beaconDotStore.dots.map { $0.beaconID })
        var updatedCount = 0
        var addedCount = 0
        
        switch mode {
        case .updateOnly:
            // Only update beacons that already exist
            for item in importData.beacons where currentBeaconIDs.contains(item.beaconID) {
                applyImportItem(item)
                updatedCount += 1
            }
            print("📥 [BeaconSettings] Updated \(updatedCount) existing beacon(s)")
            
        case .merge:
            // Update existing + add new
            for item in importData.beacons {
                if currentBeaconIDs.contains(item.beaconID) {
                    applyImportItem(item)
                    updatedCount += 1
                } else {
                    addImportItem(item)
                    addedCount += 1
                }
            }
            print("📥 [BeaconSettings] Updated \(updatedCount), added \(addedCount) beacon(s)")
            
        case .replaceAll:
            // Clear current location's dots and import all
            beaconDotStore.clear()
            for item in importData.beacons {
                addImportItem(item)
                addedCount += 1
            }
            print("📥 [BeaconSettings] Replaced all with \(addedCount) beacon(s)")
        }
        
        // Refresh pending elevations to reflect imported values
        for dot in filteredDots {
            let elevation = beaconDotStore.getElevation(for: dot.beaconID)
            pendingElevations[dot.beaconID] = String(format: "%g", elevation)
        }
        
        pendingImportData = nil
    }
    
    private func applyImportItem(_ item: BeaconExportItem) {
        // Update existing dot's properties
        beaconDotStore.setElevation(for: item.beaconID, elevation: item.elevation)
        if let tx = item.txPower {
            beaconDotStore.setTxPower(for: item.beaconID, dbm: tx)
        }
        if let interval = item.advertisingInterval {
            beaconDotStore.setAdvertisingInterval(for: item.beaconID, ms: interval)
        }
        // Position update
        beaconDotStore.updateDot(for: item.beaconID, newMapPoint: CGPoint(x: item.x, y: item.y))
    }
    
    private func addImportItem(_ item: BeaconExportItem) {
        // Create new dot via toggleDot, then update all properties
        let point = CGPoint(x: item.x, y: item.y)
        let color = BeaconDotStore.BeaconDotV2(beaconID: item.beaconID, x: item.x, y: item.y).color
        beaconDotStore.toggleDot(for: item.beaconID, mapPoint: point, color: color)
        
        // Apply additional properties
        beaconDotStore.setElevation(for: item.beaconID, elevation: item.elevation)
        if let tx = item.txPower {
            beaconDotStore.setTxPower(for: item.beaconID, dbm: tx)
        }
        if let interval = item.advertisingInterval {
            beaconDotStore.setAdvertisingInterval(for: item.beaconID, ms: interval)
        }
    }
    
    private func saveElevationValues() {
        var savedCount = 0
        
        for (beaconID, elevationString) in pendingElevations {
            if let elevation = Double(elevationString) {
                let currentElevation = beaconDotStore.getElevation(for: beaconID)
                if abs(elevation - currentElevation) > 0.001 {
                    beaconDotStore.setElevation(for: beaconID, elevation: elevation)
                    savedCount += 1
                }
            }
        }
        
        print("💾 [BeaconSettings] Saved \(savedCount) elevation value(s)")
    }
    
    private func readFromHardware() {
        guard !selectedBeaconIDs.isEmpty else { return }
        
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
            print("📡 [BeaconSettings] Found \(discoveredBeacons.count) beacon(s) for read")
            
            // Match selected beacons to discovered devices
            var matchedBeacons: [(beaconID: String, device: KBeacon)] = []
            for beaconID in selectedBeaconIDs.sorted() {
                if let device = discoveredBeacons.first(where: { $0.name == beaconID }) {
                    matchedBeacons.append((beaconID: beaconID, device: device))
                } else {
                    updateResult(for: beaconID, status: .failed, error: "Not found in scan")
                }
            }
            
            // Process matched beacons sequentially
            readSequentially(beacons: matchedBeacons, password: password, index: 0)
        }
    }
    
    private func readSequentially(
        beacons: [(beaconID: String, device: KBeacon)],
        password: String,
        index: Int
    ) {
        // Base case: all beacons processed
        guard index < beacons.count else {
            print("✅ [BeaconSettings] Read complete - \(beacons.count) beacon(s)")
            return
        }
        
        let (beaconID, device) = beacons[index]
        
        // Helper to process next beacon
        func processNext() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.readSequentially(beacons: beacons, password: password, index: index + 1)
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
            
            // Update status: reading (reuse verifying status)
            updateResult(for: beaconID, status: .verifying)
            
            // Read configuration
            if let config = kbeaconManager.readConfiguration(from: device) {
                // Update BeaconDotStore with read values
                beaconDotStore.updateFromDeviceConfig(
                    beaconName: beaconID,
                    txPower: config.txPower,
                    intervalMs: config.intervalMs,
                    mac: device.mac,
                    model: config.model,
                    firmware: config.firmwareVersion
                )
                
                updateResult(for: beaconID, status: .complete)
                print("📖 [BeaconSettings] Read \(beaconID): TX=\(config.txPower)dBm, Interval=\(Int(config.intervalMs))ms")
            } else {
                updateResult(for: beaconID, status: .failed, error: "Failed to read configuration")
            }
            
            kbeaconManager.disconnect(from: device)
            processNext()
        }
    }
    
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
    @Binding var elevationText: String
    let currentTxPower: Int?
    let currentInterval: Double
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // Checkbox
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .frame(width: 24)
            }
            .buttonStyle(.plain)
            
            // Beacon name
            Text(beaconID)
                .font(.system(size: 12))
                .foregroundColor(.primary)
                .frame(minWidth: 100, alignment: .leading)
                .lineLimit(1)
            
            // Elevation input
            HStack(spacing: 2) {
                TextField("0.75", text: $elevationText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 11, design: .monospaced))
                    .frame(width: 50)
                Text("m")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // TX Power column
            Text(currentTxPower != nil ? "\(currentTxPower!)dBm" : "—")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .trailing)
            
            // Interval column
            Text("\(Int(currentInterval))ms")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .trailing)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(6)
    }
}

// MARK: - Export Data Structures

struct BeaconExportData: Codable {
    let locationID: String
    let exportedAt: String
    let beacons: [BeaconExportItem]
}

struct BeaconExportItem: Codable {
    let beaconID: String
    let x: Double
    let y: Double
    let elevation: Double
    let txPower: Int?
    let advertisingInterval: Double?
    let lastConfigChange: BeaconDotStore.ConfigChangeInfo?
}
