//
//  HUDContainer.swift
//  TapResolver
//
//  Created by restructuring on 9/19/25.
//

import SwiftUI
import Combine
import Foundation

// MARK: - Notification Extensions
extension Notification.Name {
    static let beaconSelectedForTxPower = Notification.Name("beaconSelectedForTxPower")
    static let sliderInteractionBegan = Notification.Name("sliderInteractionBegan")
    static let sliderInteractionEnded = Notification.Name("sliderInteractionEnded")
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
    @EnvironmentObject private var triangleStore: TrianglePatchStore
    @EnvironmentObject private var arWorldMapStore: ARWorldMapStore
    @StateObject private var beaconLogger = SimpleBeaconLogger()
    @StateObject private var relocalizationCoordinator: RelocalizationCoordinator

    @State private var sliderValue: Double = 10.0 // Default to 10 seconds
    @State private var showMetricSquareAR = false
    @EnvironmentObject private var arViewLaunchContext: ARViewLaunchContext

    @State private var selectedBeaconForTxPower: String? = nil
    @State private var showScanQuality = true  // Temporary: always show for testing
    @State private var activeIntervalEdit: (beaconID: String, text: String)? = nil
    @State private var showRelocalizationDebug = false  // Debug UI toggle

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
            .onReceive(NotificationCenter.default.publisher(for: .sliderInteractionBegan)) { _ in
                mapTransform.isHUDInteracting = true
            }
            .onReceive(NotificationCenter.default.publisher(for: .sliderInteractionEnded)) { _ in
                mapTransform.isHUDInteracting = false
            }
            // AR view launch is now handled via ARViewLaunchContext
            // Removed notification handler - using direct method call instead
            .overlay(alignment: .topLeading) { topLeftButtons }
            .overlay(alignment: .topLeading) { rolePanelOverlay }
            .overlay { txPowerOverlay }
            .overlay { keypadOverlay }
            .overlay { arViewOverlay }
            .overlay(alignment: .top) { interpolationModeBanner }
            .overlay { triangleCreationInstructions }
            .overlay(alignment: .bottomTrailing) { relocalizationDebugOverlay }
            .onAppear {
                // Update coordinator to use actual ARWorldMapStore
                relocalizationCoordinator.updateARStore(arWorldMapStore)
            }
        }
        
    init() {
        // Initialize relocalization coordinator with temporary store
        // Will be updated to use actual store in onAppear
        let tempARStore = ARWorldMapStore()
        _relocalizationCoordinator = StateObject(wrappedValue: RelocalizationCoordinator(arStore: tempARStore))
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
                        MapPointLogButton() //This log panel is a good example for the Debug/Settings panel I'd like to see.
                        ResetMapButton()
                        BluetoothScanButton()
                        RSSIMeterButton()
                        DebugSettingsButton() // Opens Debug/Settings Panel with moved buttons
                        // MARK: - Initial Diagnostic Buttons (Hidden - can be restored if needed)
                        /*
                        UserDefaultsDiagnosticButton()
                        MapPointsInspectionButton()
                        PhotoMigrationPlanButton()
                        MapPointStructureButton()
                        PhotoManagerButton()
                        PurgePhotosButton()
                        */
                        // MARK: - Triangle Diagnostic Buttons (Hidden - can be restored if needed)
                        /*
                        TriangleInspectionButton()      // 🔺 Inspect Triangle Data
                        TriangleValidationButton()      // ✓🔺 Validate Triangle Vertex IDs
                        DeleteMalformedTrianglesButton() // 🗑️🔺 Delete Malformed Triangles
                        */
                        // MARK: - AR Marker Diagnostic Buttons (Hidden - can be restored if needed)
                        /*
                        MarkerInspectionButton()        // 🧠📍 Inspect AR Markers
                        MarkerDeletionButton()          // 🗑️📍 Delete All AR Markers
                        */
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
            
            if hud.isDebugSettingsOpen {
                VStack {
                    Spacer()
                    DebugSettingsPanel(showRelocalizationDebug: $showRelocalizationDebug)
                        .transition(.move(edge: .bottom))
                }
                .zIndex(200)
            }
        }
        .zIndex(100)
        .animation(.easeInOut(duration: 0.3), value: hud.isMapPointLogOpen)
        .animation(.easeInOut(duration: 0.3), value: hud.isDebugSettingsOpen)
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
            
            // AR View button (always visible)
            Button(action: {
                print("📱 HUDContainer: Launching generic AR view — FROM HUD")
                arViewLaunchContext.launchGeneric()
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
            
            // Triangle creation button
            if !triangleStore.isCreatingTriangle {
                Button {
                    triangleStore.startCreatingTriangle()
                } label: {
                    Image(systemName: "triangle")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                        .background(Color.blue.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.top, 80)
            } else {
                // Cancel button during creation
                Button {
                    triangleStore.cancelCreatingTriangle()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                        .background(Color.red.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.top, 80)
            }
            
            // MARK: - Connection Button (Hidden - preserving for future use)
            if false {  // ✅ Set to true to re-enable
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
    private var relocalizationDebugOverlay: some View {
        if showRelocalizationDebug {
            RelocalizationDebugView(coordinator: relocalizationCoordinator, isPresented: $showRelocalizationDebug)
                .frame(maxWidth: 350, maxHeight: 500)
                .padding()
        }
    }

    @ViewBuilder
    private var rolePanelOverlay: some View {
        if let selectedID = mapPointStore.selectedPointID {
            VStack {
                HStack {
                    MapPointRolePanel(pointID: selectedID)
                        .environmentObject(mapPointStore)
                        .padding(.leading, 2)
                        .padding(.top, 166)  // ✅ CHANGED: Position where Connection button was
                        .transition(.move(edge: .leading).combined(with: .opacity))
                    
                    Spacer()
                }
                Spacer()
            }
            .animation(.easeInOut(duration: 0.3), value: mapPointStore.selectedPointID)
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
        // AR View is now presented via ContentView's fullScreenCover
        // No overlay needed here anymore
        
        if showMetricSquareAR, let activeID = metricSquares.activeSquareID {
            MetricSquareARView(
                isPresented: $showMetricSquareAR,
                squareID: activeID
            )
            .allowsHitTesting(true)
        }
    }
    
    @ViewBuilder
    private var triangleCreationInstructions: some View {
        Group {
            if triangleStore.isCreatingTriangle {
                VStack {
                    HStack {
                        Text("Tap \(3 - triangleStore.creationVertices.count) Triangle Edge point(s)")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .cornerRadius(8)
                        
                        Spacer()
                    }
                    .padding(.leading, 80)
                    .padding(.top, 120)
                    
                    Spacer()
                }
            }
        }
    }
    
    @ViewBuilder
    private var interpolationModeBanner: some View {
        if mapPointStore.isInterpolationMode && !arViewLaunchContext.isPresented {
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

private struct DebugSettingsButton: View {
    @EnvironmentObject private var hudPanels: HUDPanelsState
    
    var body: some View {
        Button {
            hudPanels.toggleDebugSettings()
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
                .padding(10)
                .background(Circle().fill(Color.gray.opacity(0.8)))
        }
        .shadow(radius: 4)
        .accessibilityLabel("Open Debug Settings")
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
        slider.addTarget(
            context.coordinator,
            action: #selector(Coordinator.touchBegan),
            for: .touchDown
        )
        slider.addTarget(
            context.coordinator,
            action: #selector(Coordinator.touchEnded),
            for: [.touchUpInside, .touchUpOutside, .touchCancel]
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
        
        @objc func touchBegan() {
            NotificationCenter.default.post(name: .sliderInteractionBegan, object: nil)
        }
        
        @objc func touchEnded() {
            NotificationCenter.default.post(name: .sliderInteractionEnded, object: nil)
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

// MARK: - Relocalization Debug Toggle Button

private struct MapPointDiagnosticButton: View {
    var body: some View {
        Button(action: {
            Task {
                await MapPointDebugTool.runDiagnostic()
            }
        }) {
            Image(systemName: "magnifyingglass.circle.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .padding(10)
                .background(Color.orange.opacity(0.9), in: Circle())
        }
        .shadow(radius: 4)
        .accessibilityLabel("Map Point Diagnostic")
        .buttonStyle(.plain)
    }
}

private struct RelocalizationDebugToggleButton: View {
    @Binding var showDebug: Bool
    
    var body: some View {
        Button {
            showDebug.toggle()
        } label: {
            Image(systemName: showDebug ? "location.magnifyingglass.fill" : "location.magnifyingglass")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
                .padding(10)
                .background(.ultraThinMaterial, in: Circle())
        }
        .accessibilityLabel("Toggle relocalization debug")
        .buttonStyle(.plain)
        .allowsHitTesting(true)
    }
}

// MARK: - Debug Settings Panel

private struct DebugSettingsPanel: View {
    @EnvironmentObject private var hudPanels: HUDPanelsState
    @EnvironmentObject private var mapPointStore: MapPointStore
    @EnvironmentObject private var triangleStore: TrianglePatchStore
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var mapTransform: MapTransformStore
    
    @Binding var showRelocalizationDebug: Bool
    @State private var showingSoftResetAlert = false
    @State private var showingPurgePhotosAlert = false
    @State private var showOrphanPurgeConfirmation = false
    @State private var showOrphanPurgeResult = false
    @State private var showingPurgeARHistoryAlert = false
    @State private var showingFullResetAlert = false
    @State private var orphanPurgeResultMessage = ""
    @State private var showingLogShare = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header with close button
                HStack {
                    Text("Debug & Settings")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button {
                        hudPanels.toggleDebugSettings()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.black.opacity(0.8))
                
                // Grid of buttons
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 16) {
                        // Facing Toggle Button
                        Button {
                            hudPanels.showFacingOverlay.toggle()
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "location.north.fill")
                                    .font(.system(size: 24))
                                Text("Facing")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        
                        // Relocalization Debug Toggle
                        Button {
                            showRelocalizationDebug.toggle()
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: showRelocalizationDebug ? "location.magnifyingglass.fill" : "location.magnifyingglass")
                                    .font(.system(size: 24))
                                Text("Reloc Debug")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        
                        // Purge Diagnostic Button (Eye)
                        Button {
                            showPurgeDiagnostic()
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "eye.fill")
                                    .font(.system(size: 24))
                                Text("Diagnostic")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        
                        // Soft Reset Button (Red X)
                        Button {
                            showingSoftResetAlert = true
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 24))
                                Text("Soft Reset")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        
                        // Purge AR Position History Button
                        Button {
                            showingPurgeARHistoryAlert = true
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "trash.circle")
                                    .font(.system(size: 24))
                                Text("Purge AR History")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.orange)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        
                        // Full Reset Button (Soft Reset + Purge History)
                        Button {
                            showingFullResetAlert = true
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "arrow.counterclockwise.circle.fill")
                                    .font(.system(size: 24))
                                Text("Full Reset")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        
                        // Photo Purge Button
                        Button {
                            showingPurgePhotosAlert = true
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 24))
                                Text("Purge Photos")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.orange)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        
                        // Orphan Triangle Purge Button
                        Button(role: .destructive) {
                            showOrphanPurgeConfirmation = true
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "trash.slash")
                                    .font(.system(size: 24))
                                Text("Purge Orphaned Triangles")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        
                        // MARK: - User Position Tracking Toggles
                        
                        // Follow User in PiP Toggle
                        Button {
                            AppSettings.followUserInPiP.toggle()
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: AppSettings.followUserInPiP ? "location.fill" : "location")
                                    .font(.system(size: 24))
                                Text("PiP Follow")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(AppSettings.followUserInPiP ? .green : .gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        
                        // Follow User in Main Map Toggle
                        Button {
                            AppSettings.followUserInMainMap.toggle()
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: AppSettings.followUserInMainMap ? "map.fill" : "map")
                                    .font(.system(size: 24))
                                Text("Map Follow")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(AppSettings.followUserInMainMap ? .green : .gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        
                        // Export Console Log Button
                        Button {
                            showingLogShare = true
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 24))
                                Text("Export Log")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        .sheet(isPresented: $showingLogShare) {
                            ShareSheet(items: [FileLogger.shared.exportFileURL])
                        }
                        
                        // Clear Console Log Button
                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            FileLogger.shared.clearLog()
                            print("Internal Log Cleared")
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "trash")
                                    .font(.system(size: 24))
                                Text("Clear Log")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.orange)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in mapTransform.isHUDInteracting = true }
                        .onEnded { _ in mapTransform.isHUDInteracting = false }
                )
                .background(Color.black.opacity(0.7))
            }
            .frame(height: min(geometry.size.height * 0.5, 400))
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.9))
            .cornerRadius(16, corners: [.topLeft, .topRight])
            .shadow(color: .black.opacity(0.2), radius: 10, y: -5)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .ignoresSafeArea(edges: .bottom)
        }
        .alert("Soft Reset Calibration?", isPresented: $showingSoftResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                performSoftReset()
            }
        } message: {
            let location = PersistenceContext.shared.locationID
            Text("This will clear all calibration data for '\(location)' location.\n\nTriangle mesh structure will be preserved.\nOther locations (museum, etc.) will NOT be affected.")
        }
        .alert("Purge All Photos?", isPresented: $showingPurgePhotosAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Purge Photos", role: .destructive) {
                mapPointStore.purgeAllPhotos()
            }
        } message: {
            let location = locationManager.currentLocationID
            Text("This will delete all \(mapPointStore.points.count) photo assets for location '\(location)'. This cannot be undone.")
        }
        .alert("Purge AR Position History?", isPresented: $showingPurgeARHistoryAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Purge History", role: .destructive) {
                mapPointStore.purgeARPositionHistory()
            }
        } message: {
            let location = locationManager.currentLocationID ?? "unknown"
            let totalRecords = mapPointStore.points.reduce(0) { $0 + $1.arPositionHistory.count }
            Text("This will purge all \(totalRecords) AR position record(s) from \(mapPointStore.points.count) MapPoint(s) for location '\(location)'.\n\n2D map coordinates and triangle structure will be preserved.\nConsensus positions will be reset.")
        }
        .alert("Full Reset (Calibration + History)?", isPresented: $showingFullResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Full Reset", role: .destructive) {
                // First do soft reset
                performSoftReset()
                // Then purge position history
                mapPointStore.purgeARPositionHistory()
                print("🔄 Full Reset Complete: Calibration data cleared + AR history purged")
            }
        } message: {
            let location = locationManager.currentLocationID ?? "unknown"
            Text("This will:\n1. Clear all calibration data (Soft Reset)\n2. Purge all AR position history\n\nFor location '\(location)'.\n\n2D map coordinates and triangle structure will be preserved.\nThis cannot be undone.")
        }
        .alert("Purge Orphaned Triangles?", isPresented: $showOrphanPurgeConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Purge", role: .destructive) {
                let validIDs = Set(mapPointStore.points.map { $0.id })
                let removed = triangleStore.purgeOrphanedTriangles(validMapPointIDs: validIDs)
                orphanPurgeResultMessage = removed > 0 
                    ? "Removed \(removed) orphaned triangle(s)" 
                    : "No orphaned triangles found"
                showOrphanPurgeResult = true
            }
        } message: {
            Text("This will delete triangles that reference MapPoints which no longer exist. This cannot be undone.")
        }
        .alert("Purge Complete", isPresented: $showOrphanPurgeResult) {
            Button("OK") { }
        } message: {
            Text(orphanPurgeResultMessage)
        }
    }
    
    private func showPurgeDiagnostic() {
        let currentLocation = PersistenceContext.shared.locationID
        
        print("================================================================================")
        print("👁️ PURGE DIAGNOSTIC - LOCATION ISOLATION CHECK")
        print("================================================================================")
        print("📍 Current Location: '\(currentLocation)'")
        print("")
        print("🗑️ WILL AFFECT:")
        print("   ✓ Triangles: /Documents/locations/\(currentLocation)/dots.json")
        print("   ✓ ARWorldMaps: /Documents/locations/\(currentLocation)/ARSpatial/")
        print("   ✓ Triangle count: \(triangleStore.triangles.count)")
        
        let calibratedCount = triangleStore.triangles.filter { $0.isCalibrated }.count
        let totalMarkers = triangleStore.triangles.reduce(0) { $0 + $1.arMarkerIDs.count }
        
        print("   ✓ Calibrated triangles: \(calibratedCount)")
        print("   ✓ Total AR markers: \(totalMarkers)")
        print("")
        print("🛡️ WILL NOT AFFECT:")
        
        // List other locations
        let locationsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("locations")
        
        if let locationDirs = try? FileManager.default.contentsOfDirectory(atPath: locationsURL.path) {
            for dir in locationDirs where dir != currentLocation {
                print("   ✓ Location '\(dir)' - UNTOUCHED")
            }
        }
        
        print("")
        print("🎯 ACTION:")
        print("   Soft reset will clear calibration data but keep triangle mesh structure")
        print("   All triangles will be marked uncalibrated (isCalibrated = false)")
        print("   AR marker associations will be cleared (arMarkerIDs = [])")
        print("   Triangle vertices and mesh connectivity preserved")
        print("================================================================================")
    }
    
    private func performSoftReset() {
        let currentLocation = PersistenceContext.shared.locationID
        
        print("================================================================================")
        print("🗑️ SOFT RESET - CLEARING CALIBRATION DATA")
        print("================================================================================")
        print("📍 Target Location: '\(currentLocation)'")
        print("")
        
        let beforeCount = triangleStore.triangles.filter { $0.isCalibrated }.count
        let beforeMarkers = triangleStore.triangles.reduce(0) { $0 + $1.arMarkerIDs.count }
        
        print("📊 Before reset:")
        print("   Calibrated triangles: \(beforeCount)")
        print("   Total AR markers: \(beforeMarkers)")
        print("")
        
        // Clear calibration data for all triangles
        for i in 0..<triangleStore.triangles.count {
            triangleStore.triangles[i].isCalibrated = false
            triangleStore.triangles[i].arMarkerIDs = []
            triangleStore.triangles[i].calibrationQuality = 0.0
            triangleStore.triangles[i].legMeasurements = []
            triangleStore.triangles[i].worldMapFilename = nil
            triangleStore.triangles[i].worldMapFilesByStrategy = [:]
            triangleStore.triangles[i].transform = nil
            triangleStore.triangles[i].lastCalibratedAt = nil
            triangleStore.triangles[i].userPositionWhenCalibrated = nil
        }
        
        // Save changes
        triangleStore.save()
        
        print("✅ Cleared calibration data:")
        print("   - Set isCalibrated = false for all triangles")
        print("   - Cleared arMarkerIDs arrays")
        print("   - Reset calibrationQuality to 0.0")
        print("   - Cleared legMeasurements")
        print("   - Cleared ARWorldMap filenames")
        print("   - Cleared transform data")
        print("   - Cleared lastCalibratedAt")
        print("   - Cleared userPositionWhenCalibrated")
        print("")
        print("✅ Preserved:")
        print("   - Triangle vertices (\(triangleStore.triangles.reduce(0) { $0 + $1.vertexIDs.count }) total)")
        print("   - Mesh connectivity")
        print("   - Triangle structure (\(triangleStore.triangles.count) triangles)")
        print("")
        
        // Delete ARWorldMap files for this location
        let arSpatialURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("locations")
            .appendingPathComponent(currentLocation)
            .appendingPathComponent("ARSpatial")
        
        if FileManager.default.fileExists(atPath: arSpatialURL.path) {
            do {
                try FileManager.default.removeItem(at: arSpatialURL)
                print("🗑️ Deleted ARWorldMap files at: \(arSpatialURL.path)")
            } catch {
                print("⚠️ Failed to delete ARWorldMap files: \(error)")
            }
        }
        
        print("")
        print("🛡️ Other locations UNTOUCHED:")
        
        // Verify other locations still exist
        let locationsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("locations")
        
        if let locationDirs = try? FileManager.default.contentsOfDirectory(atPath: locationsURL.path) {
            for dir in locationDirs where dir != currentLocation {
                let dotsPath = locationsURL.appendingPathComponent(dir).appendingPathComponent("dots.json").path
                if FileManager.default.fileExists(atPath: dotsPath) {
                    print("   ✓ Location '\(dir)' - VERIFIED INTACT")
                }
            }
        }
        
        print("================================================================================")
        print("✅ Soft reset complete for location '\(currentLocation)'")
        print("================================================================================")
    }
}

// MARK: - UserDefaults Diagnostic Button

private struct UserDefaultsDiagnosticButton: View {
    @EnvironmentObject private var locationManager: LocationManager
    
    var body: some View {
        Button {
            UserDefaultsDiagnostics.printInventory()
            _ = UserDefaultsDiagnostics.identifyHeavyData()
        } label: {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .padding(10)
                .background(Color.purple.opacity(0.8), in: Circle())
        }
        .shadow(radius: 4)
        .accessibilityLabel("UserDefaults Diagnostic")
        .buttonStyle(.plain)
        .allowsHitTesting(true)
    }
}

// MARK: - MapPoints Inspection Button

private struct MapPointsInspectionButton: View {
    @EnvironmentObject private var locationManager: LocationManager
    
    var body: some View {
        Button {
            let currentLoc = PersistenceContext.shared.locationID
            UserDefaultsDiagnostics.inspectMapPointStructure(locationID: currentLoc)
        } label: {
            Text("🔬")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .padding(10)
                .background(Color.orange.opacity(0.8), in: Circle())
        }
        .shadow(radius: 4)
        .accessibilityLabel("Inspect MapPoints")
        .buttonStyle(.plain)
        .allowsHitTesting(true)
    }
}

// MARK: - Photo Migration Plan Button

private struct PhotoMigrationPlanButton: View {
    var body: some View {
        Button {
            UserDefaultsDiagnostics.generatePhotoMigrationPlan()
        } label: {
            Text("📋")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .padding(10)
                .background(Color.blue.opacity(0.8), in: Circle())
        }
        .shadow(radius: 4)
        .accessibilityLabel("Photo Migration Plan")
        .buttonStyle(.plain)
        .allowsHitTesting(true)
    }
}

// MARK: - MapPoint Structure Button

private struct MapPointStructureButton: View {
    @EnvironmentObject private var locationManager: LocationManager
    
    var body: some View {
        Button {
            let currentLoc = PersistenceContext.shared.locationID
            UserDefaultsDiagnostics.inspectMapPointStructure(locationID: currentLoc)
        } label: {
            Text("🔍")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .padding(10)
                .background(Color.green.opacity(0.8), in: Circle())
        }
        .shadow(radius: 4)
        .accessibilityLabel("MapPoint Structure")
        .buttonStyle(.plain)
        .allowsHitTesting(true)
    }
}

// MARK: - Photo Manager Button

private struct PhotoManagerButton: View {
    var body: some View {
        Button {
            let currentLoc = PersistenceContext.shared.locationID
            UserDefaultsDiagnostics.launchPhotoManager(locationID: currentLoc)
        } label: {
            Text("📸")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .padding(10)
                .background(Color.purple.opacity(0.8), in: Circle())
        }
        .shadow(radius: 4)
        .accessibilityLabel("Manage Photos")
        .buttonStyle(.plain)
        .allowsHitTesting(true)
    }
}

// MARK: - Purge Photos Button

// MARK: - Debug Button Component (Future-Proof)
private struct DebugButton: View {
    var icon: String
    var color: Color
    var action: () -> Void
    var accessibility: String
    
    var body: some View {
        Button(action: action) {
            Text(icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .padding(10)
                .background(color.opacity(0.8), in: Circle())
        }
        .shadow(radius: 4)
        .accessibilityLabel(accessibility)
        .buttonStyle(.plain)
        .allowsHitTesting(true)
    }
}

// MARK: - Triangle Inspection Button
private struct TriangleInspectionButton: View {
    @EnvironmentObject private var locationManager: LocationManager
    
    var body: some View {
        DebugButton(
            icon: "🔺",
            color: .purple,
            action: {
                let currentLoc = PersistenceContext.shared.locationID
                UserDefaultsDiagnostics.inspectTriangles(locationID: currentLoc)
                // TODO: Pipe results into user-visible HUD or log overlay for faster dev loop
            },
            accessibility: "Inspect Triangle Data"
        )
    }
}

// MARK: - Triangle Validation Button
private struct TriangleValidationButton: View {
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var mapPointStore: MapPointStore
    
    var body: some View {
        DebugButton(
            icon: "✓🔺",
            color: .purple,
            action: {
                // Fail-safe: Check if MapPoints are loaded
                guard !mapPointStore.points.isEmpty else {
                    print("⚠️ Map Points not yet loaded — validation aborted.")
                    print("   Current MapPoint count: \(mapPointStore.points.count)")
                    return
                }
                
                let currentLoc = PersistenceContext.shared.locationID
                UserDefaultsDiagnostics.validateTriangleVertices(locationID: currentLoc, mapPointStore: mapPointStore)
                // TODO: Pipe results into user-visible HUD or log overlay for faster dev loop
            },
            accessibility: "Validate Triangle Vertex IDs"
        )
    }
}

// MARK: - Delete Malformed Triangles Button
private struct DeleteMalformedTrianglesButton: View {
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var mapPointStore: MapPointStore
    @State private var showConfirmation = false
    @State private var showResultAlert = false
    @State private var deletionResult: (deletedCount: Int, remainingCount: Int)? = nil
    
    var body: some View {
        DebugButton(
            icon: "🗑️🔺",
            color: .red,
            action: {
                // Fail-safe: Check if MapPoints are loaded
                guard !mapPointStore.points.isEmpty else {
                    print("⚠️ Map Points not yet loaded — deletion aborted.")
                    print("   Current MapPoint count: \(mapPointStore.points.count)")
                    return
                }
                
                showConfirmation = true
            },
            accessibility: "Delete Malformed Triangles"
        )
        .alert("Delete Malformed Triangles?", isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                performDeletion()
            }
        } message: {
            Text("This will permanently delete all triangles with invalid vertex IDs (referencing non-existent MapPoints). This action cannot be undone.")
        }
        .alert("Deletion Complete", isPresented: $showResultAlert) {
            Button("OK") {
                deletionResult = nil
            }
        } message: {
            if let result = deletionResult {
                if result.deletedCount > 0 {
                    Text("Deleted \(result.deletedCount) malformed triangle(s).\n\(result.remainingCount) valid triangle(s) remaining.")
                } else {
                    Text("No malformed triangles found. All triangles are valid.")
                }
            } else {
                Text("Deletion completed.")
            }
        }
    }
    
    private func performDeletion() {
        let currentLoc = PersistenceContext.shared.locationID
        let result = UserDefaultsDiagnostics.deleteMalformedTriangles(
            locationID: currentLoc,
            mapPointStore: mapPointStore
        )
        
        // Show result alert
        deletionResult = result
        showResultAlert = true
        
        // Reload triangles in TrianglePatchStore if needed
        // Note: TrianglePatchStore will reload on next access, but we could post a notification here
        NotificationCenter.default.post(name: NSNotification.Name("TrianglesUpdated"), object: nil)
        
        print("✅ Deletion complete: \(result.deletedCount) deleted, \(result.remainingCount) remaining")
    }
}

// MARK: - AR Marker Diagnostic Buttons

private struct MarkerInspectionButton: View {
    @EnvironmentObject private var arWorldMapStore: ARWorldMapStore
    
    var body: some View {
        DebugButton(
            icon: "🧠📍",
            color: .orange,
            action: {
                arWorldMapStore.inspectMarkers()
                // TODO: Pipe results into user-visible HUD or log overlay for faster dev loop
            },
            accessibility: "Inspect AR Markers"
        )
    }
}

private struct MarkerDeletionButton: View {
    @EnvironmentObject private var arWorldMapStore: ARWorldMapStore
    @State private var showConfirmation = false
    
    var body: some View {
        DebugButton(
            icon: "🗑️📍",
            color: .red,
            action: {
                showConfirmation = true
            },
            accessibility: "Delete All AR Markers"
        )
        .alert("Delete All AR Markers?", isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                arWorldMapStore.deleteAllMarkers()
            }
        } message: {
            Text("This will permanently delete all persisted AR marker metadata files for the current location. This action cannot be undone and will not affect active ARKit anchors.")
        }
    }
}

private struct PurgePhotosButton: View {
    var body: some View {
        Button {
            // Manual purge for photos already on disk
            let locationID = PersistenceContext.shared.locationID
            let savedIDs = ["E49BCB0F", "86EB7B89", "CD8E90BB", "A59BC2FB", 
                            "58BA635B", "90EA7A4A", "3E185BD1", "B9714AA0", "9E947C28"]
            UserDefaultsDiagnostics.purgePhotosFromUserDefaults(
                locationID: locationID,
                confirmedFilesSaved: savedIDs
            )
        } label: {
            Text("🗑️")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .padding(10)
                .background(Color.red.opacity(0.8), in: Circle())
        }
        .shadow(radius: 4)
        .accessibilityLabel("Purge Photos from UD")
        .buttonStyle(.plain)
        .allowsHitTesting(true)
    }
}

// MARK: - UserDefaults Cleanup Function (callable from Xcode console)

// Call this from Xcode console during debugging:
// expr -l Swift -- cleanupUserDefaults()
func cleanupUserDefaults() {
    print("🧹 Starting UserDefaults cleanup...")
    
    // First, show what we have
    UserDefaultsDiagnostics.printInventory()
    
    // Identify heavy keys
    let heavyKeys = UserDefaultsDiagnostics.identifyHeavyData()
    
    // Dry run first
    print("\n🔍 Performing DRY RUN...")
    UserDefaultsDiagnostics.removeKeys(Array(heavyKeys.keys), dryRun: true)
    
    // Uncomment the line below to actually delete:
    // UserDefaultsDiagnostics.removeKeys(Array(heavyKeys.keys), dryRun: false)
}

// MARK: - Export Bundle Type
struct MapPointScanBundleV1: Codable {
    let schema = "tapresolver.mappointbundle.v1"
    let locationID: String
    let pointID: String
    let createdAtISO: String
    let scans: [ScanRecordV1]
}
