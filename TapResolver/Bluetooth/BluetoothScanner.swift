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
    private var continuousMode: Bool = false
    
    // MARK: - Scan utility references (set by app)
    weak var scanUtility: MapPointScanUtility?
    weak var simpleLogger: SimpleBeaconLogger?
    weak var beaconLists: BeaconListsStore?
    weak var surveyCollector: SurveySessionCollector?
    var onDeviceNameDiscovered: ((_ name: String, _ id: UUID) -> Void)?

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
        if continuousMode { return }  // Don't stop if in continuous mode
        central.stopScan()
        isScanning = false
        if verboseLogging { print("🛑 Stopped BLE scan. Total devices seen: \(devices.count)") }
    }
    
    /// Start continuous scanning (won't auto-stop)
    func startContinuous() {
        continuousMode = true
        start()
    }
    
    /// Stop continuous scanning
    func stopContinuous() {
        continuousMode = false
        stop()
        central.stopScan()
        isScanning = false
        if verboseLogging { print("🛑 Stopped continuous BLE scan. Total devices seen: \(devices.count)") }
    }

    // MARK: - iBeacon Parsing
    
    /// Parse iBeacon data from manufacturer data
    /// Apple's iBeacon format: Company ID 0x004C, followed by 0x02 0x15, then UUID, Major, Minor, Measured Power
    private func parseIBeaconData(_ manufacturerData: Data) -> (uuid: String, major: Int, minor: Int, measuredPower: Int)? {
        // iBeacon packet structure:
        // Byte 0-1:   Company ID (0x4C 0x00 for Apple, little-endian)
        // Byte 2:     iBeacon type (0x02)
        // Byte 3:     Data length (0x15 = 21 bytes)
        // Byte 4-19:  UUID (16 bytes)
        // Byte 20-21: Major (2 bytes, big-endian)
        // Byte 22-23: Minor (2 bytes, big-endian)
        // Byte 24:    Measured Power (1 byte, signed int8)
        
        guard manufacturerData.count >= 25 else { return nil }
        
        // Check for Apple company ID (0x004C in little-endian = 0x4C 0x00)
        guard manufacturerData[0] == 0x4C && manufacturerData[1] == 0x00 else { return nil }
        
        // Check for iBeacon type and length
        guard manufacturerData[2] == 0x02 && manufacturerData[3] == 0x15 else { return nil }
        
        // Extract UUID (16 bytes starting at index 4)
        let uuidData = manufacturerData.subdata(in: 4..<20)
        let uuid = uuidData.map { String(format: "%02X", $0) }.joined()
        // Format as standard UUID: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
        let formattedUUID = "\(uuid.prefix(8))-\(uuid.dropFirst(8).prefix(4))-\(uuid.dropFirst(12).prefix(4))-\(uuid.dropFirst(16).prefix(4))-\(uuid.dropFirst(20))"
        
        // Extract Major (2 bytes, big-endian)
        let major = Int(manufacturerData[20]) << 8 | Int(manufacturerData[21])
        
        // Extract Minor (2 bytes, big-endian)
        let minor = Int(manufacturerData[22]) << 8 | Int(manufacturerData[23])
        
        // Extract Measured Power (1 byte, signed)
        let measuredPower = Int(Int8(bitPattern: manufacturerData[24]))
        
        return (uuid: formattedUUID, major: major, minor: minor, measuredPower: measuredPower)
    }
    
    // MARK: - Model
    struct DiscoveredDevice: Identifiable {
        let id: UUID
        var name: String
        var rssi: Int
        var txPower: Int?        // optional TX power from advertisement
        var lastSeen: Date
        var advSummary: String
        
        // iBeacon protocol data (parsed from manufacturer data)
        var ibeaconUUID: String?           // 128-bit UUID
        var ibeaconMajor: Int?             // 16-bit major ID
        var ibeaconMinor: Int?             // 16-bit minor ID
        var ibeaconMeasuredPower: Int?     // Calibrated RSSI at 1 meter
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothScanner: @preconcurrency CBCentralManagerDelegate {
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

    @MainActor
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {

        let id = peripheral.identifier
        let name = displayName(from: advertisementData, peripheral: peripheral)
        let rssi = RSSI.intValue
        let txPower = (advertisementData[CBAdvertisementDataTxPowerLevelKey] as? NSNumber)?.intValue
        let summary = summarize(advertisementData)
        onDeviceNameDiscovered?(name, id)
        
        // Parse iBeacon data if available
        var ibeaconUUID: String? = nil
        var ibeaconMajor: Int? = nil
        var ibeaconMinor: Int? = nil
        var ibeaconMeasuredPower: Int? = nil
        
        if let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
            if let ibeaconData = parseIBeaconData(manufacturerData) {
                ibeaconUUID = ibeaconData.uuid
                ibeaconMajor = ibeaconData.major
                ibeaconMinor = ibeaconData.minor
                ibeaconMeasuredPower = ibeaconData.measuredPower
                
                // Debug: Log iBeacon data on first detection
                if deviceIndex[id] == nil {
                    print("📱 iBeacon detected: \(name)")
                    print("   UUID: \(ibeaconData.uuid)")
                    print("   Major: \(ibeaconData.major), Minor: \(ibeaconData.minor)")
                    print("   Measured Power: \(ibeaconData.measuredPower) dBm")
                }
            }
        }

        // DIRECT INJECTION: During active survey dwell, bypass @Published entirely
        // Collector handles its own filtering, throttling, and buffering
        if let collector = surveyCollector, collector.isCollecting {
            collector.ingestBLEData(beaconID: name, rssi: rssi)
            // Skip @Published update - reduces Combine traffic during time-critical dwell
            // Discovery (beaconLists.ingest) still happens below
        } else {
            // Normal path: Update @Published devices for UI consumers
            // FILTER: Only add whitelisted devices to @Published devices array
            // Discovery (beaconLists.ingest) still happens below for ALL devices
            // Empty whitelist = publish all (backwards compatible for fresh setups)
            let whitelist = beaconLists?.beacons ?? []
            let shouldPublish = whitelist.isEmpty || whitelist.contains(name)
            
            if shouldPublish {
                if let idx = deviceIndex[id] {
                    devices[idx].name = name
                    devices[idx].rssi = rssi
                    devices[idx].txPower = txPower ?? devices[idx].txPower
                    devices[idx].lastSeen = Date()
                    devices[idx].advSummary = summary
                    devices[idx].ibeaconUUID = ibeaconUUID ?? devices[idx].ibeaconUUID
                    devices[idx].ibeaconMajor = ibeaconMajor ?? devices[idx].ibeaconMajor
                    devices[idx].ibeaconMinor = ibeaconMinor ?? devices[idx].ibeaconMinor
                    devices[idx].ibeaconMeasuredPower = ibeaconMeasuredPower ?? devices[idx].ibeaconMeasuredPower
                } else {
                    let dev = DiscoveredDevice(
                        id: id,
                        name: name,
                        rssi: rssi,
                        txPower: txPower,
                        lastSeen: Date(),
                        advSummary: summary,
                        ibeaconUUID: ibeaconUUID,
                        ibeaconMajor: ibeaconMajor,
                        ibeaconMinor: ibeaconMinor,
                        ibeaconMeasuredPower: ibeaconMeasuredPower
                    )
                    deviceIndex[id] = devices.count
                    devices.append(dev)
                    if verboseLogging {
                        print("📱 Discovered: \(name) • id=\(id.uuidString) • RSSI=\(rssi) dBm")
                        if !summary.isEmpty { print("    ⤷ \(summary)") }
                    }
                }
            } // end shouldPublish
        } // end else (normal path)
        
        // Forward advertisement to scan utility for map point logging
        // Use device name as beaconID since that's how beacons are identified in our system
        scanUtility?.ingest(
            beaconID: name,
            name: name,
            rssiDbm: rssi,
            txPowerDbm: txPower,
            timestamp: CFAbsoluteTimeGetCurrent()
        )
        
        // Auto-update beacon lists during continuous scanning
        // Pattern matching (##-adjectiveAnimal) and morgue filtering handled by BeaconListsStore.ingest()
        beaconLists?.ingest(deviceName: name, id: id)

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

extension BluetoothScanner {
    /// Run a brief snapshot scan to populate Morgue on app launch (morning behavior)
    func snapshotOnce() {
        guard central.state == .poweredOn else { return }
        snapshotScan(duration: 1.5) { [weak self] in
            // Snapshot complete - devices are now in the devices array
            // The onDeviceNameDiscovered callback has already populated the lists
        }
    }
}

private extension BluetoothScanner {
    func displayName(from advertisementData: [String: Any], peripheral: CBPeripheral) -> String {
        // Prefer advertised local name if present; fallback to peripheral.name; then a generic.
        if let local = advertisementData[CBAdvertisementDataLocalNameKey] as? String, !local.isEmpty {
            return local
        }
        if let pname = peripheral.name, !pname.isEmpty {
            return pname
        }
        return "Unknown"
    }
}
