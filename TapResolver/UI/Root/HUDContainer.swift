//
//  HUDContainer.swift
//  TapResolver
//
//  Created by restructuring on 9/19/25.
//

import SwiftUI
import Combine

// MARK: - Notification Extensions
extension Notification.Name {
    static let beaconSelectedForTxPower = Notification.Name("beaconSelectedForTxPower")
}

// MARK: - Color extension for hex support
extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}

struct HUDContainer: View {
    @EnvironmentObject private var beaconDotStore: BeaconDotStore
    @EnvironmentObject private var metricSquares: MetricSquareStore
    @EnvironmentObject private var squareMetrics: SquareMetrics
    @EnvironmentObject private var mapPointStore: MapPointStore
    @EnvironmentObject private var mapTransform: MapTransformStore
    @EnvironmentObject private var hud: HUDPanelsState
    @EnvironmentObject private var btScanner: BluetoothScanner
    @EnvironmentObject private var beaconLists: BeaconListsStore
    @EnvironmentObject private var scanUtility: MapPointScanUtility
    @EnvironmentObject private var locationManager: LocationManager
    @StateObject private var beaconLogger = SimpleBeaconLogger()

    @State private var sliderValue: Double = 10.0 // Default to 10 seconds
    @State private var didExport = false
    @State private var showFilesPicker = false
    @State private var lastExportURL: URL? = nil

    @State private var selectedBeaconForTxPower: String? = nil
    @State private var showScanQuality = true  // Temporary: always show for testing

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
                        MorgueDrawer()
                        MapPointDrawer()
                        ResetMapButton()
                        BluetoothScanButton() // snapshot scan button
                        RSSIMeterButton()
                        FacingToggleButton()
                    }
                }
                Spacer()

                // Bottom buttons - only show when MapPoint drawer is open
                if hud.isMapPointOpen {
                    VStack(spacing: 8) {
                        // NEW: Scan quality display
                        if showScanQuality {
                            ScanQualityDisplayView(
                                viewModel: .countOnly(
                                    btScanner: btScanner,
                                    beaconLists: beaconLists,
                                    beaconDotStore: beaconDotStore
                                )
                            )
                            .transition(.opacity)
                        }
                        
                        // Existing bottom buttons
                        bottomButtons
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .allowsHitTesting(true)
        }
        .zIndex(100)

        // Numeric keypad overlays - positioned in lower portion of screen
        .overlay(
            Group {
                // Elevation keypad for beacons
                if let edit = beaconDotStore.activeElevationEdit {
                    NumericInputKeypad(
                        title: "Elevation",
                        initialText: edit.text,
                        onCommit: { text in
                            beaconDotStore.commitElevationText(text, for: edit.beaconID)
                        },
                        onDismiss: {
                            beaconDotStore.activeElevationEdit = nil
                        }
                    )
                }
                // Meters keypad for squares
                else if let edit = squareMetrics.activeEdit {
                    NumericInputKeypad(
                        title: "Meters",
                        initialText: edit.text,
                        onCommit: { text in
                            squareMetrics.commitMetersText(text, for: edit.id)
                        },
                        onDismiss: {
                            squareMetrics.activeEdit = nil
                        }
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .zIndex(200)
        )

        // Tx Power selection interface - positioned in bottom right
        .overlay(
            Group {
                if let selectedBeacon = selectedBeaconForTxPower {
                    TxPowerSelectionView(
                        beaconID: selectedBeacon,
                        onSelectTxPower: { txPower in
                            beaconDotStore.setTxPower(for: selectedBeacon, dbm: txPower)
                            selectedBeaconForTxPower = nil
                        },
                        onDismiss: {
                            selectedBeaconForTxPower = nil
                        }
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .zIndex(300)
        )

        // 🔵 Compass calibration overlay BEHIND the HUD so drawers stay tappable
        .background(
            Group {
                if hud.isCalibratingNorth {
                    CompassCalibrationOverlay(
                        angleDeg: Binding(
                            get: { squareMetrics.northOffsetDeg },
                            set: { squareMetrics.setNorthOffset($0) }
                        )
                    )
                    .allowsHitTesting(!hud.isCalibratingFacing)
                    
                    // When tools are enabled, show the user-facing calibration overlay on top.
                    if hud.isCalibratingFacing {
                        UserFacingCalibrationOverlay(
                            facingFineTuneDeg: Binding(
                                get: { squareMetrics.facingFineTuneDeg },
                                set: { squareMetrics.setFacingFineTune($0) }
                            )
                        )
                        // Bottom-right degree readout
                        .overlay(alignment: .bottomTrailing) {
                            Text("\(Int(squareMetrics.facingFineTuneDeg))°")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 8))
                                .padding(.trailing, 20)
                                .padding(.bottom, 24)
                        }
                    }
                }
                if hud.showFacingOverlay {
                    FacingOverlay()
                }
            }
        )
        
        // Tools button appears only during North calibration
        .overlay(alignment: .bottomLeading) {
            if hud.isCalibratingNorth {
                Button {
                    hud.isCalibratingFacing.toggle()
                } label: {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.black.opacity(0.6), in: Circle())
                }
                .padding(.leading, 20)
                .padding(.bottom, 24)
                .buttonStyle(.plain)
                .accessibilityLabel("Calibration Tools")
            }
        }
        
        // Bottom-left tools button shown only while calibrating north AND the Metric Square drawer is open
        /*.overlay(alignment: .bottomLeading) {
            if hud.isCalibratingNorth && hud.isSquareOpen {
                CalibrationToolsButton {
                    print("🛠️ Calibration Tools tapped")
                }
                .padding(.leading, 20)
                .padding(.bottom, 40)
                .zIndex(350)
            }
        }*/

        // Notifications for compass calibration mode
        .onReceive(NotificationCenter.default.publisher(for: .toggleNorthCalibration)) { _ in
            hud.isCalibratingNorth.toggle()
        }
        .onReceive(NotificationCenter.default.publisher(for: .stopNorthCalibration)) { _ in
            hud.isCalibratingNorth = false
        }

        // Tx Power picker notification
        .onReceive(NotificationCenter.default.publisher(for: .beaconSelectedForTxPower)) { notification in
            if let beaconID = notification.object as? String {
                selectedBeaconForTxPower = beaconID
            }
        }

        // Escape-to-menu button (upper-left)
        .overlay(alignment: .topLeading) {
            LocationMenuButton()
                .allowsHitTesting(true)
                .zIndex(1000)
        }
    }

    // MARK: - Bottom Buttons Cluster (MapPoint logging controls)
    private var bottomButtons: some View {
        bottomButtonRow
    }
    
    private var bottomButtonRow: some View {
        HStack(spacing: 8) {
            addMapPointButton
            durationSlider
            countdownDisplay
            logDataButton
            exportButton
        }
    }
    
    private var addMapPointButton: some View {
        Button {
            guard mapTransform.mapSize != .zero else {
                print("⚠️ Map point add ignored: mapTransform not ready (mapSize == .zero)")
                return
            }
            let targetScreen = mapTransform.screenCenter
            // Configurable X and Y pixel offsets
            let offsetX: CGFloat = 0.0  // Adjust this value as needed
            let offsetY: CGFloat = 48.0  // Adjust this value as needed
            let adjustedScreen = CGPoint(x: targetScreen.x + offsetX, y: targetScreen.y + offsetY)
            let mapPoint = mapTransform.screenToMap(adjustedScreen)
            let success = mapPointStore.addPoint(at: mapPoint)
            if !success {
                print("⚠️ Cannot add map point: location already occupied")
            }
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(Color.green, in: RoundedRectangle(cornerRadius: 12))
        }
        .accessibilityLabel("Add map point at crosshair location")
        .buttonStyle(.plain)
    }
    
    private var durationSlider: some View {
        VStack(spacing: 4) {
            HStack {
                Text("3")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Text("20")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 8)

            CustomSlider(value: $sliderValue, range: 3...20, step: 1, thumbColor: .gray, filledTrackColor: .black, unfilledTrackColor: .black)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 8))
    }
    
    @ViewBuilder
    private var countdownDisplay: some View {
        if beaconLogger.isLogging {
            Text("\(Int(beaconLogger.secondsRemaining))s")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.8), in: RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private var logDataButton: some View {
        Button {
            handleLogDataButtonTap()
        } label: {
            VStack(spacing: 2) {
                Text("\(Int(sliderValue))s")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                Text(beaconLogger.isLogging ? "Stop" : "Scan")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(beaconLogger.isLogging ? Color.red : Color.blue, in: RoundedRectangle(cornerRadius: 12))
        }
        .disabled(mapPointStore.activePoint == nil)
        .accessibilityLabel(beaconLogger.isLogging ? "Stop logging session" : "Log data for current map point")
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var exportButton: some View {
        HStack(spacing: 8) {
            if let record = scanUtility.lastScanRecord {
                Button("Export Last Scan") {
                    exportLastScanV1(record: record)
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.8), in: RoundedRectangle(cornerRadius: 8))
            }
            
            if let activePoint = mapPointStore.activePoint {
                Button("Export All Scans") {
                    exportAllScansForPoint(activePoint: activePoint)
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.8), in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .sheet(isPresented: $showFilesPicker) {
            Group {
                if let url = lastExportURL {
                    DocumentExportPicker(fileURL: url) { success in
                        didExport = success
                    }
                } else {
                    EmptyView()
                }
            }
        }
        .alert("Exported", isPresented: $didExport) {
            Button("OK", role: .cancel) {}
        }
    }
    
    private func handleLogDataButtonTap() {
        guard let activePoint = mapPointStore.activePoint else {
            print("⚠️ No active map point selected")
            return
        }

        if beaconLogger.isLogging {
            handleStopLogging()
        } else {
            handleStartLogging(activePoint: activePoint)
        }
    }
    
    private func handleStopLogging() {
        if let session = beaconLogger.stopLogging() {
            print("📊 Session completed:")
            print("   Session ID: \(session.sessionID)")
            print("   Map Point: \(session.mapPointID)")
            print("   Coordinates: (\(Int(session.coordinates.x)), \(Int(session.coordinates.y)))")
            print("   Duration: \(Int(session.duration))s")
            print("   Interval: \(Int(session.interval))ms")
            print("   Beacons logged: \(session.obinsPerBeacon.count)")
            for (beaconName, stats) in session.statsPerBeacon {
                let medianText = stats.medianDbm != nil ? "\(stats.medianDbm!) dBm" : "insufficient data"
                print("   • \(beaconName): \(stats.samples) samples, median: \(medianText), \(String(format: "%.1f", stats.packetsPerSecond)) pkt/s")
            }
        }
    }
    
    private func handleStartLogging(activePoint: MapPointStore.MapPoint) {
        print("🔍 Starting beacon logging for point \(activePoint.id)")

        beaconLogger.startLogging(
            mapPointID: activePoint.id.uuidString,
            coordinates: (x: activePoint.mapPoint.x, y: activePoint.mapPoint.y),
            duration: sliderValue,
            intervalMs: 500, // 500ms between samples
            btScanner: btScanner,
            beaconLists: beaconLists,
            beaconDotStore: beaconDotStore,
            scanUtility: scanUtility
        )
    }
    
    private func exportAllScansForPoint(activePoint: MapPointStore.MapPoint) {
        do {
            let locationID = PersistenceContext.shared.locationID
            let pointID = activePoint.id.uuidString
            
            // Load all scans for this map point
            let history = try MapPointHistoryBuilder.loadAll(locationID: locationID, pointID: pointID)
            
            // Create bundle
            let bundle = MapPointScanBundleV1(
                locationID: history.locationID,
                pointID: history.pointID,
                createdAtISO: JSONKit.iso8601.string(from: Date()),
                scans: history.scans
            )
            
            // Encode to JSON
            let data = try JSONKit.encoder().encode(bundle)
            
            // Save to temporary file
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("mappoint_scans_\(pointID)_\(Date().timeIntervalSince1970).json")
            try data.write(to: tempURL)
            
            // Show export picker
            lastExportURL = tempURL
            showFilesPicker = true
            
            print("📦 Exported \(history.scans.count) scans for point \(pointID)")
        } catch {
            print("❌ Failed to export all scans for point: \(error)")
        }
    }
    
    private func exportLastScanV1(record: MapPointScanUtility.ScanRecord) {
        do {
            // 1) Gather geometry data
            let locationID = PersistenceContext.shared.locationID
            
            // Get pixels per meter from metric squares
            let lockedSquares = metricSquares.squares.filter { $0.isLocked }
            let squaresToUse = lockedSquares.isEmpty ? metricSquares.squares : lockedSquares
            guard let square = squaresToUse.first else {
                print("❌ No metric squares available for pixels per meter calculation")
                return
            }
            let ppm = Double(square.side) / square.meters
            
            // Get map point pixel coordinates
            guard let activePoint = mapPointStore.activePoint else {
                print("❌ No active map point available")
                return
            }
            let pointPx = CGPoint(x: activePoint.mapPoint.x, y: activePoint.mapPoint.y)
            
            // Build beacon geometry from beacon dots
            let beaconsPx: [String: CGPoint] = Dictionary(uniqueKeysWithValues: 
                beaconDotStore.dots.compactMap { dot in
                    guard beaconLists.beacons.contains(dot.beaconID) else { return nil }
                    return (dot.beaconID, dot.mapPoint)
                }
            )
            
            let elevations: [String: Double?] = Dictionary(uniqueKeysWithValues:
                beaconDotStore.dots.compactMap { dot in
                    guard beaconLists.beacons.contains(dot.beaconID) else { return nil }
                    return (dot.beaconID, beaconDotStore.getElevation(for: dot.beaconID))
                }
            )
            
            // 2) Use the v1 exporter to build JSON with distances
            let result = try ScanV1Exporter.buildJSON(
                from: record,
                locationID: locationID,
                ppm: ppm,
                pointPx: pointPx,
                beaconsPx: beaconsPx,
                elevations: elevations,
                mapResolution: mapTransform.mapSize
            )
            
            // 3) Save to temporary file and show export picker
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(result.filename)
            try result.json.write(to: tempURL)
            
            lastExportURL = tempURL
            showFilesPicker = true
            
            print("📦 Exported scan V1 with distances for \(beaconsPx.count) beacons")
        } catch {
            print("❌ Failed to export scan V1: \(error)")
        }
    }
}

private struct LocationMenuButton: View {
    @EnvironmentObject private var locationManager: LocationManager

    var body: some View {
        Button {
            print("🎯 Location Menu button tapped!")
            locationManager.showLocationMenu = true
        } label: {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.primary)
                .imageScale(.large)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black.opacity(0.4)))
        }
        .buttonStyle(.plain)
        .padding(.top, 40)
        .padding(.leading, 20)
        //.shadow(radius: 2, y: 1)
        .allowsHitTesting(true)
        .accessibilityLabel("Return to Location Menu")
        .accessibilityHint("Opens the Location Browser")
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
            // 1) Run a clean snapshot scan for N seconds
            btScanner.snapshotScan { [weak btScanner, weak beaconLists, weak beaconDotStore] in
                guard let scanner = btScanner, let lists = beaconLists, let dotStore = beaconDotStore else { return }

                // 2) Clear unlocked beacons only (keep locked beacons and morgue intact)
                let lockedBeaconNames = dotStore.locked.keys.filter { dotStore.isLocked($0) }
                lists.clearUnlockedBeacons(lockedBeaconNames: lockedBeaconNames)

                // 3) Ingest all discovered devices - the ingest() method will handle morgue filtering
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

// MARK: - Custom Slider with Thumb Color Control
import UIKit

struct CustomSlider: UIViewRepresentable {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let thumbColor: UIColor
    let filledTrackColor: UIColor
    let unfilledTrackColor: UIColor
    
    func makeUIView(context: Context) -> UISlider {
        let slider = UISlider()
        slider.minimumValue = Float(range.lowerBound)
        slider.maximumValue = Float(range.upperBound)
        slider.value = Float(value)
        slider.thumbTintColor = thumbColor
        slider.minimumTrackTintColor = filledTrackColor
        slider.maximumTrackTintColor = unfilledTrackColor
        slider.addTarget(
            context.coordinator,
            action: #selector(Coordinator.valueChanged(_:)),
            for: .valueChanged
        )
        return slider
    }
    
    func updateUIView(_ uiView: UISlider, context: Context) {
        uiView.value = Float(value)
        uiView.thumbTintColor = thumbColor
        uiView.minimumTrackTintColor = filledTrackColor
        uiView.maximumTrackTintColor = unfilledTrackColor
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: CustomSlider
        
        init(_ parent: CustomSlider) {
            self.parent = parent
        }
        
        @objc func valueChanged(_ sender: UISlider) {
            // Round to nearest step
            let steppedValue = round(sender.value / Float(parent.step)) * Float(parent.step)
            parent.value = Double(steppedValue)
        }
    }
}

// MARK: - Tx Power Selection View
struct TxPowerSelectionView: View {
    let beaconID: String
    let onSelectTxPower: (Int?) -> Void
    let onDismiss: () -> Void
    
    private let txPowerOptions: [(label: String, value: Int?)] = [
        ("8 dBm", 8),
        ("4 dBm", 4),
        ("0 dBm", 0),
        ("-4 dBm", -4),
        ("-8 dBm", -8),
        ("-12 dBm", -12),
        ("-16 dBm", -16),
        ("-20 dBm", -20),
        ("-40 dBm", -40)
    ]
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            // Title
            Text("Tx Power")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            
            // Selection buttons
            VStack(spacing: 4) {
                ForEach(txPowerOptions, id: \.label) { option in
                    Button(action: {
                        onSelectTxPower(option.value)
                    }) {
                        Text(option.label)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.8), in: RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
                
                // Clear/Dismiss button
                Button(action: {
                    onDismiss()
                }) {
                    Text("Cancel")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.8), in: RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 12))
        .padding(.trailing, 20)
        .padding(.bottom, 40)
    }
}

// MARK: - Calibration Tools Button (gear + wrench)
private struct CalibrationToolsButton: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Gear (back)
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .offset(x: -2, y: 1)
                    .opacity(0.95)
            }
            .foregroundColor(.white)
            .padding(10)
            .background(Color.black.opacity(0.75), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Calibration tools")
        .allowsHitTesting(true)
    }
}


// MARK: - Facing Toggle Button

private struct FacingToggleButton: View {
    @EnvironmentObject private var hud: HUDPanelsState
    
    var body: some View {
        Button {
            hud.showFacingOverlay.toggle()
        } label: {
            Image(systemName: "location.north.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
                .padding(10)
                .background(.ultraThinMaterial, in: Circle())
        }
        .accessibilityLabel("Toggle facing overlay")
        .buttonStyle(.plain)
        .allowsHitTesting(true)
    }
}

// MARK: - Export Bundle Type
struct MapPointScanBundleV1: Codable {
    let schema = "tapresolver.mappointbundle.v1"
    let locationID: String
    let pointID: String
    let createdAtISO: String
    let scans: [ScanRecordV1]
}
