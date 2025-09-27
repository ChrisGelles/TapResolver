//
//  HUDContainer.swift
//  TapResolver
//
//  Created by restructuring on 9/19/25.
//

import SwiftUI

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
    @EnvironmentObject private var squareMetrics: SquareMetrics
    @EnvironmentObject private var mapPointStore: MapPointStore
    @EnvironmentObject private var mapTransform: MapTransformStore
    @EnvironmentObject private var hud: HUDPanelsState
    @EnvironmentObject private var btScanner: BluetoothScanner
    @EnvironmentObject private var beaconLists: BeaconListsStore
    @StateObject private var beaconLogger = SimpleBeaconLogger()
    
    @State private var sliderValue: Double = 10.0 // Default to 10 seconds
    
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
                        MapPointDrawer()                // ← added, sits between Morgue and Reset
                        ResetMapButton()
                        
                        // Radio waves button: start scan + dump snapshot to console
                        BluetoothScanButton()
                        
                        RSSIMeterButton()
                    }
                    
                }
                Spacer()
                
                        // Bottom buttons - only show when MapPoint drawer is open
                        if hud.isMapPointOpen {
                            VStack(spacing: 12) {
                                // Text field showing slider value
                                Text("\(Int(sliderValue))s")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 8))
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                
                                HStack {
                                    // Green plus button (left)
                                    Button {
                                        guard mapTransform.mapSize != .zero else {
                                            print("⚠️ Map point add ignored: mapTransform not ready (mapSize == .zero)")
                                            return
                                        }
                                        let targetScreen = mapTransform.screenCenter
                                        let mapPoint = mapTransform.screenToMap(targetScreen)
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
                                    
                                    // Horizontal slider (center)
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
                                    
                                    // Countdown display (if logging)
                                    if beaconLogger.isLogging {
                                        Text("\(Int(beaconLogger.secondsRemaining))s")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(Color.orange.opacity(0.8), in: RoundedRectangle(cornerRadius: 8))
                                    }
                                    
                                    // Blue Log Data button (right)
            Button {
                guard let activePoint = mapPointStore.activePoint else {
                    print("⚠️ No active map point selected")
                    return
                }
                
                if beaconLogger.isLogging {
                    // Stop current logging session
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
                } else {
                    // Start new logging session
                    print("🔍 Starting beacon logging for point \(activePoint.id)")
                    
                    beaconLogger.startLogging(
                        mapPointID: activePoint.id.uuidString,
                        coordinates: (x: activePoint.mapPoint.x, y: activePoint.mapPoint.y),
                        duration: sliderValue,
                        intervalMs: 500, // 500ms between samples
                        btScanner: btScanner,
                        beaconLists: beaconLists,
                        beaconDotStore: beaconDotStore
                    )
                }
            } label: {
                Text(beaconLogger.isLogging ? "Stop Logging" : "Log Data")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(beaconLogger.isLogging ? Color.red : Color.blue, in: RoundedRectangle(cornerRadius: 12))
            }
            .disabled(mapPointStore.activePoint == nil)
            .accessibilityLabel(beaconLogger.isLogging ? "Stop logging session" : "Log data for current map point")
            .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 40)
                        }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .allowsHitTesting(true)
            
        }
        .zIndex(100)
        .overlay(
            // Numeric keypad overlays - positioned in lower portion of screen
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
