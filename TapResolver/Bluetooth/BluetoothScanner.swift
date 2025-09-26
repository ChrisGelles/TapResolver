//
//  BluetoothScanner.swift
//  TapResolver
//
//  Created by Chris Gelles on 9/17/25.
//
//  Simple BLE sniffer with a “snapshot” scan helper.
//  Press a button -> scan for N seconds -> stop -> use `devices` array.
//

import Foundation
import CoreBluetooth

final class BluetoothScanner: NSObject, ObservableObject {

    // MARK: - Tuning
    static let defaultSnapshotSeconds: TimeInterval = 2.0   // ← tweak window here
    private let verboseLogging = false                      // ← set true to see per-ad prints

    // MARK: - Published state
    @Published private(set) var isScanning = false
    @Published private(set) var devices: [DiscoveredDevice] = []

    // MARK: - Internal storage
    private var central: CBCentralManager!
    private var deviceIndex: [UUID: Int] = [:] // quick lookup by peripheral.identifier
    private var pendingStopWork: DispatchWorkItem?
    
    // MARK: - Scan utility reference (set by app)
    weak var scanUtility: MapPointScanUtility?

    // MARK: - Setup
    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main) // main queue for simplicity
    }

    // MARK: - Snapshot API
    /// Clears current list, scans for `duration`, then stops and calls `onComplete`.
    func snapshotScan(duration: TimeInterval = BluetoothScanner.defaultSnapshotSeconds,
                      onComplete: @escaping () -> Void)
    {
        // If Bluetooth isn’t ready yet, defer until it is, then run the snapshot.
        guard central.state == .poweredOn else {
            if verboseLogging { print("ℹ️ Deferring BLE snapshot until powered on (state=\(central.state.rawValue)).") }
            // Wait for poweredOn in delegate, then run this snapshot
            let work = DispatchWorkItem { [weak self] in
                self?.snapshotScan(duration: duration, onComplete: onComplete)
            }
            // Store the work item to run once powered on.
            // We won’t keep multiple queued; latest wins.
            pendingStopWork?.cancel()
            pendingStopWork = work
            return
        }

        // Reset current cache so we aggregate a clean 2s window.
        devices.removeAll()
        deviceIndex.removeAll()

        // Start scan
        if verboseLogging { print("🔍 Snapshot scan starting for \(duration)s…") }
        start()

        // Schedule stop + completion
        pendingStopWork?.cancel()
        let stopWork = DispatchWorkItem { [weak self] in
            self?.stop()
            if self?.verboseLogging == true {
                print("⏹️ Snapshot scan complete. \(self?.devices.count ?? 0) unique devices.")
            }
            onComplete()
        }
        pendingStopWork = stopWork
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: stopWork)
    }

    // MARK: - Public start/stop (unchanged)
    func start() {
        guard central.state == .poweredOn else {
            if verboseLogging { print("⚠️ Bluetooth not ready. State: \(central.state.rawValue)") }
            return
        }
        guard !isScanning else { return }

        if verboseLogging { print("🔍 Starting BLE scan…") }
        isScanning = true
        central.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
    }

    func stop() {
        guard isScanning else { return }
        central.stopScan()
        isScanning = false
        if verboseLogging { print("🛑 Stopped BLE scan. Total devices seen: \(devices.count)") }
    }

    // MARK: - Model
    struct DiscoveredDevice: Identifiable {
        let id: UUID
        var name: String
        var rssi: Int
        var txPower: Int?        // optional TX power from advertisement
        var lastSeen: Date
        var advSummary: String
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothScanner: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            if verboseLogging { print("✅ Bluetooth is powered on.") }
            // If a snapshot was deferred waiting for poweredOn, run it now
            if let work = pendingStopWork {
                pendingStopWork = nil
                DispatchQueue.main.async(execute: work)
            }
        case .poweredOff:
            if verboseLogging { print("❌ Bluetooth is powered off.") }
        case .resetting:
            if verboseLogging { print("🔄 Bluetooth resetting.") }
        case .unsupported:
            if verboseLogging { print("🚫 Bluetooth unsupported.") }
        case .unauthorized:
            if verboseLogging { print("🚫 Bluetooth unauthorized.") }
        case .unknown:
            fallthrough
        @unknown default:
            if verboseLogging { print("❓ Bluetooth state unknown: \(central.state.rawValue)") }
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {

        let id = peripheral.identifier
        let name = (peripheral.name?.isEmpty == false ? peripheral.name! : "Unknown")
        let rssi = RSSI.intValue
        let txPower = (advertisementData[CBAdvertisementDataTxPowerLevelKey] as? NSNumber)?.intValue
        let summary = summarize(advertisementData)

        if let idx = deviceIndex[id] {
            devices[idx].name = name
            devices[idx].rssi = rssi
            devices[idx].txPower = txPower ?? devices[idx].txPower
            devices[idx].lastSeen = Date()
            devices[idx].advSummary = summary
        } else {
            let dev = DiscoveredDevice(
                id: id, name: name, rssi: rssi, txPower: txPower, lastSeen: Date(), advSummary: summary
            )
            deviceIndex[id] = devices.count
            devices.append(dev)
            if verboseLogging {
                print("📱 Discovered: \(name) • id=\(id.uuidString) • RSSI=\(rssi) dBm")
                if !summary.isEmpty { print("    ⤷ \(summary)") }
            }
        }
        
        // Forward advertisement to scan utility for map point logging
        // Use device name as beaconID since that's how beacons are identified in our system
        scanUtility?.ingest(
            beaconID: name,
            name: name,
            rssiDbm: rssi,
            txPowerDbm: txPower,
            timestamp: CFAbsoluteTimeGetCurrent()
        )

        if verboseLogging {
            // Comment this out entirely to eliminate update spam:
            // print("↻ Update: \(name) • RSSI=\(rssi) dBm")
        }
    }
}

// MARK: - Helpers
private extension BluetoothScanner {
    func summarize(_ ad: [String: Any]) -> String {
        var parts: [String] = []

        if let mfg = ad[CBAdvertisementDataManufacturerDataKey] as? Data, mfg.count >= 2 {
            let companyId = mfg.prefix(2).withUnsafeBytes { $0.load(as: UInt16.self) }
            parts.append(String(format: "Mfg=0x%04X (%d bytes)", companyId, mfg.count))
        }
        if let services = ad[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID], !services.isEmpty {
            let uuids = services.map { $0.uuidString }.joined(separator: ",")
            parts.append("Services=[\(uuids)]")
        }
        if let serviceData = ad[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data], !serviceData.isEmpty {
            let keys = serviceData.keys.map { $0.uuidString }.joined(separator: ",")
            parts.append("ServiceData=[\(keys)]")
        }
        if let overflow = ad[CBAdvertisementDataOverflowServiceUUIDsKey] as? [CBUUID], !overflow.isEmpty {
            let uuids = overflow.map { $0.uuidString }.joined(separator: ",")
            parts.append("Overflow=[\(uuids)]")
        }
        if let isConnectable = ad[CBAdvertisementDataIsConnectable] as? Bool {
            parts.append("Connectable=\(isConnectable ? "yes" : "no")")
        }
        return parts.joined(separator: "  ·  ")
    }
}

extension BluetoothScanner {
    /// Print a one-shot, formatted table of the currently known devices.
    /// Does not start/stop scanning; just prints what we’ve seen so far.
    func dumpSummaryTable() {
        let now = Date()
        let dateFormatter = DateFormatter(); dateFormatter.dateFormat = "MM/dd/yyyy"
        let timeFormatter = DateFormatter(); timeFormatter.dateFormat = "HH:mm:ss"

        func pad(_ s: String, _ n: Int) -> String {
            if s.count >= n { return String(s.prefix(n)) }
            return s + String(repeating: " ", count: n - s.count)
        }

        let dateStr = dateFormatter.string(from: now)
        print("")
        print("Bluetooth Devices Detected (\(dateStr))")
        print("----------------------------------------")
        let header = "\(pad("Name", 28))  \(pad("RSSI", 6))  \(pad("Tx Power", 8))  \(pad("Time", 8))"
        print(header)

        for d in devices {
            let displayName = (d.name.isEmpty || d.name == "Unknown") ? "(unnamed bluetooth device)" : d.name
            let rssiStr = "\(d.rssi)"
            let txStr = d.txPower.map { String($0) } ?? "??"
            let tStr = timeFormatter.string(from: d.lastSeen)
            let row = "\(pad(displayName, 28))  \(pad(rssiStr, 6))  \(pad(txStr, 8))  \(pad(tStr, 8))"
            print(row)
        }
        print("----------------------------------------\n")
    }
}
