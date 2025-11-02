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
    @EnvironmentObject private var beaconState: BeaconStateManager
    @StateObject private var beaconLogger = SimpleBeaconLogger()

    @State private var sliderValue: Double = 10.0 // Default to 10 seconds
    @State private var showARCalibration = false
    @State private var showMetricSquareAR = false

    @State private var selectedBeaconForTxPower: String? = nil
    @State private var showScanQuality = true  // Temporary: always show for testing
    @State private var activeIntervalEdit: (beaconID: String, text: String)? = nil

    var body: some View {
        baseContent
            .background { backgroundOverlays }
            .overlay(alignment: .bottomLeading) { calibrationTools }
            .onReceive(NotificationCenter.default.publisher(for: .toggleNorthCalibration)) { _ in
                hud.isCalibratingNorth.toggle()
            }
            .onReceive(NotificationCenter.default.publisher(for: .stopNorthCalibration)) { _ in
                hud.isCalibratingNorth = false
            }
            .onReceive(NotificationCenter.default.publisher(for: .beaconSelectedForTxPower)) { notification in
                if let beaconID = notification.object as? String {
                    selectedBeaconForTxPower = beaconID
                }
            }
            .overlay(alignment: .topLeading) { topLeftButtons }
            .overlay { txPowerOverlay }
            .overlay { keypadOverlay }
            .overlay { arViewOverlay }
            .overlay(alignment: .top) { interpolationModeBanner }
        }
    
    // MARK: - View Composition Helpers
        
    private var baseContent: some View {
        ZStack {
            Color.clear.ignoresSafeArea().allowsHitTesting(false)
            CrosshairHUDOverlay()
            
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
                        MapPointLogButton()
                        ResetMapButton()
                        BluetoothScanButton()
                        RSSIMeterButton()
                        FacingToggleButton()
                    }
                }
                Spacer()
                
                if hud.isMapPointOpen {
                    VStack(spacing: 8) {
                        if showScanQuality {
                            ScanQualityDisplayView(
                                viewModel: .fromRealData(
                                    beaconState: beaconState,
                                    beaconDotStore: beaconDotStore,
                                    scanUtility: scanUtility
                                )
                            )
                            .transition(.opacity)
                        }
                        bottomButtons
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .allowsHitTesting(true)
            
            if hud.isMapPointLogOpen {
                VStack {
                    Spacer()
                    MapPointLogView()
                        .transition(.move(edge: .bottom))
                }
                .zIndex(200)
            }
        }
        .zIndex(100)
        .animation(.easeInOut(duration: 0.3), value: hud.isMapPointLogOpen)
    }

    @ViewBuilder
    private var backgroundOverlays: some View {
        if hud.isCalibratingNorth {
            CompassCalibrationOverlay(
                angleDeg: Binding(
                    get: { squareMetrics.northOffsetDeg },
                    set: { squareMetrics.setNorthOffset($0) }
                )
            )
            .allowsHitTesting(!hud.isCalibratingFacing)
            
            if hud.isCalibratingFacing {
                UserFacingCalibrationOverlay(
                    facingFineTuneDeg: Binding(
                        get: { squareMetrics.facingFineTuneDeg },
                        set: { squareMetrics.setFacingFineTune($0) }
                    )
                )
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

    @ViewBuilder
    private var calibrationTools: some View {
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

    private var topLeftButtons: some View {
        VStack(alignment: .leading, spacing: 12) {
            LocationMenuButton()
                .allowsHitTesting(true)
                .onAppear {
                    print("🔍 DEBUG: activePointID on VStack appear = \(mapPointStore.activePointID?.uuidString ?? "nil")")
                    print("🔍 DEBUG: Total points in store = \(mapPointStore.points.count)")
                }
            
            if mapPointStore.activePointID != nil {
                let _ = print()
                
                Button(action: {
                    print("Launching AR View Tools")
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showARCalibration = true
                    }
                }) {
                    Image(systemName: "cube.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(
                            Circle()
                                .fill(Color.blue.opacity(0.9))
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                }
                .buttonStyle(.plain)
                .transition(.move(edge: .leading).combined(with: .opacity))
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: mapPointStore.activePointID)
            }
            
            // Interpolation mode button (appears when one point selected)
            if let selectedID = mapPointStore.activePointID,
               !mapPointStore.isInterpolationMode,
               mapPointStore.interpolationFirstPointID == nil {
                
                Button(action: {
                    mapPointStore.startInterpolationMode(firstPointID: selectedID)
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.circle")
                            .font(.system(size: 24))
                            .foregroundColor(.orange)
                        
                        Text("Connect")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.orange)
                    }
                    .frame(width: 60, height: 60)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                .transition(.move(edge: .leading).combined(with: .opacity))
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: mapPointStore.activePointID)
            }
            
            // AR Calibration button for Metric Square (only when square active)
            if metricSquares.activeSquareID != nil {
                Button(action: {
                    print("Launching Metric Square AR Calibration")
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showMetricSquareAR = true
                    }
                }) {
                    Image(systemName: "square.dashed")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(
                            Circle()
                                .fill(Color.orange.opacity(0.9))
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                }
                .buttonStyle(.plain)
                .transition(.move(edge: .leading).combined(with: .opacity))
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: metricSquares.activeSquareID)
            }
        }
        .zIndex(1000)
    }

    @ViewBuilder
    private var txPowerOverlay: some View {
        if let selectedBeacon = selectedBeaconForTxPower {
            TxPowerSelectionView(
                beaconID: selectedBeacon,
                onSelectTxPower: { txPower in
                    beaconDotStore.setTxPower(for: selectedBeacon, dbm: txPower)
                    selectedBeaconForTxPower = nil
                },
                onDismiss: {
                    selectedBeaconForTxPower = nil
                },
                onShowIntervalKeypad: {
                    let currentInterval = beaconDotStore.getAdvertisingInterval(for: selectedBeacon)
                    activeIntervalEdit = (
                        beaconID: selectedBeacon,
                        text: String(format: "%.2f", currentInterval)
                    )
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
    }

    @ViewBuilder
    private var keypadOverlay: some View {
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
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        } else if let edit = squareMetrics.activeEdit {
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
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        } else if let edit = activeIntervalEdit {
            NumericInputKeypad(
                title: "Broadcast Interval (ms)",
                initialText: edit.text,
                onCommit: { text in
                    if let value = Double(text) {
                        beaconDotStore.setAdvertisingInterval(for: edit.beaconID, ms: value)
                    }
                    activeIntervalEdit = nil
                },
                onDismiss: {
                    activeIntervalEdit = nil
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }

    @ViewBuilder
    private var arViewOverlay: some View {
        if showARCalibration {
            ARCalibrationView(
                isPresented: $showARCalibration,
                mapPointID: mapPointStore.isInterpolationMode ? nil : mapPointStore.activePointID,
                interpolationFirstPointID: mapPointStore.isInterpolationMode ? mapPointStore.interpolationFirstPointID : nil,
                interpolationSecondPointID: mapPointStore.isInterpolationMode ? mapPointStore.interpolationSecondPointID : nil
            )
            .allowsHitTesting(true)
        }
        
        if showMetricSquareAR, let activeID = metricSquares.activeSquareID {
            MetricSquareARView(
                isPresented: $showMetricSquareAR,
                squareID: activeID
            )
            .allowsHitTesting(true)
        }
    }
    
    @ViewBuilder
    private var interpolationModeBanner: some View {
        if mapPointStore.isInterpolationMode && !showARCalibration {
            VStack(spacing: 0) {
                // Push banner down below status bar
                Color.clear
                    .frame(height: 60)
                
                HStack {
                    Image(systemName: "link.circle.fill")
                        .font(.system(size: 16))
                    
                    Text(mapPointStore.interpolationSecondPointID == nil 
                         ? "Select second Map Point" 
                         : "Ready to interpolate")
                        .font(.system(size: 14, weight: .semibold))
                    
                    Spacer()
                    
                    Button(action: {
                        mapPointStore.cancelInterpolationMode()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.orange)
                .foregroundColor(.white)
                
                Spacer()
            }
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: mapPointStore.isInterpolationMode)
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
        }
    }

    private var addMapPointButton: some View {
        Button {
            guard mapTransform.mapSize != .zero else {
                print("âš ï¸ Map point add ignored: mapTransform not ready (mapSize == .zero)")
                return
            }
            let targetScreen = mapTransform.screenCenter
            let offsetX: CGFloat = 0.0
            let offsetY: CGFloat = 48.0
            let adjustedScreen = CGPoint(x: targetScreen.x + offsetX, y: targetScreen.y + offsetY)
            let mapPoint = mapTransform.screenToMap(adjustedScreen)
            let success = mapPointStore.addPoint(at: mapPoint)
            if !success {
                print("âš ï¸ Cannot add map point: location already occupied")
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

    private func handleLogDataButtonTap() {
        guard let activePoint = mapPointStore.activePoint else {
            print("âš ï¸ No active map point selected")
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
            print("ðŸ“Š Session completed:")
            print("   Session ID: \(session.sessionID)")
            print("   Map Point: \(session.mapPointID)")
            print("   Coordinates: (\(Int(session.coordinates.x)), \(Int(session.coordinates.y)))")
            print("   Duration: \(Int(session.duration))s")
            print("   Interval: \(Int(session.interval))ms")
            print("   Beacons logged: \(session.obinsPerBeacon.count)")
            for (beaconName, stats) in session.statsPerBeacon {
                let medianText = stats.medianDbm != nil ? "\(stats.medianDbm!) dBm" : "insufficient data"
                print("   â€¢ \(beaconName): \(stats.samples) samples, median: \(medianText), \(String(format: "%.1f", stats.packetsPerSecond)) pkt/s")
            }
        }
    }

    private func handleStartLogging(activePoint: MapPointStore.MapPoint) {
        print("ðŸ” Starting beacon logging for point \(activePoint.id)")

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

}


private struct LocationMenuButton: View {
    @EnvironmentObject private var locationManager: LocationManager

    var body: some View {
        Button {
            print("ðŸŽ¯ Location Menu button tapped!")
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

private struct MapPointLogButton: View {
    @EnvironmentObject private var hudPanels: HUDPanelsState
    
    var body: some View {
        Button {
            hudPanels.toggleMapPointLog()
        } label: {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
                .padding(10)
                .background(Circle().fill(Color.blue.opacity(0.8)))
        }
        .shadow(radius: 4)
        .accessibilityLabel("Open Map Point Log")
        .buttonStyle(.plain)
        .allowsHitTesting(true)
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

    var body: some View {
        Button {
            if btScanner.isScanning {
                btScanner.stopContinuous()
            } else {
                btScanner.startContinuous()
            }
        } label: {
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
                .padding(10)
                .background(
                    btScanner.isScanning ? Color.green : Color(white: 0.3),
                    in: Circle()
                )
        }
        .accessibilityLabel(btScanner.isScanning ? "Stop continuous Bluetooth scanning" : "Start continuous Bluetooth scanning")
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
    @State private var isActive = false

    var body: some View {
        Button {
            isActive.toggle()

            // Notify MeterLabels about state change (it manages the 0.5s timer)
            // Labels will consume data from continuous scan (if active)
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
        .accessibilityLabel("Toggle RSSI label display")
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
    @EnvironmentObject private var beaconDotStore: BeaconDotStore
    
    let beaconID: String
    let onSelectTxPower: (Int?) -> Void
    let onDismiss: () -> Void
    let onShowIntervalKeypad: () -> Void
    
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
            
            // Tx Power selection buttons
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
            }
            
            // Divider
            Divider()
                .background(Color.white.opacity(0.3))
                .padding(.vertical, 4)
            
            // Advertising Interval section
            VStack(spacing: 4) {
                Text("Broadcast Interval (ms)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                Button(action: {
                    onShowIntervalKeypad()
                }) {
                    Text(beaconDotStore.displayAdvertisingInterval(for: beaconID))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .fixedSize(horizontal: true, vertical: false)  // â† ADD THIS LINE
                        .frame(minWidth: 100)
                        .background(Color.gray.opacity(0.6), in: RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
            
            // Divider
            Divider()
                .background(Color.white.opacity(0.3))
                .padding(.vertical, 4)
            
            // Cancel button
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
        .padding(12)
        .background(Color.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 12))
        .padding(.trailing, 20)
        .padding(.bottom, 40)
        .frame(width: 220, alignment: .trailing)   // keep it compact and consistent
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
