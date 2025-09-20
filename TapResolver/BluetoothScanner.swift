//
//  BluetoothScanner.swift
//  TapResolver
//
//  Created by Chris Gelles on 9/17/25.
//
//  Simple BLE sniffer that logs discovered devices to the console.
//  Prints: name, identifier (UUID), RSSI, and a compact ad summary.
//
//  NOTE: Add the Info.plist key:
//  - Privacy - Bluetooth Always Usage Description (NSBluetoothAlwaysUsageDescription)
//

import Foundation
import CoreBluetooth

final class BluetoothScanner: NSObject, ObservableObject {

    // MARK: - Published state (optional to drive UI later)
    @Published private(set) var isScanning = false
    @Published private(set) var devices: [DiscoveredDevice] = []

    // MARK: - Internal storage
    private var central: CBCentralManager!
    private var deviceIndex: [UUID: Int] = [:] // quick lookup by peripheral.identifier
    // If start() was called before .poweredOn, remember to auto-start once ready.
    private var pendingStart: Bool = false
    // If start() is called before .poweredOn, remember it and auto-start later.
    private var wantsScanOnPowerOn = false


    // MARK: - Setup
    override init() {
        super.init()
        central = CBCentralManager(
            delegate: self,
            queue: .main,
            options: [CBCentralManagerOptionShowPowerAlertKey: true]
        )
    }

    // MARK: - Public API
    func start() {
        // Always remember that the user wanted scanning
        wantsScanOnPowerOn = true

        // If Bluetooth isn’t ready yet, just log and return; we’ll auto-start later.
        guard central.state == .poweredOn else {
            print("ℹ️ Deferring BLE scan until Bluetooth is powered on (state=\(central.state.rawValue))")
            return
        }
        guard !isScanning else { return }

        print("🔍 Starting BLE scan…")
        isScanning = true
        wantsScanOnPowerOn = false
        central.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
    }

    func stop() {
        guard isScanning else { return }
        central.stopScan()
        isScanning = false
        print("🛑 Stopped BLE scan. Total devices seen: \(devices.count)")
    }

    // MARK: - Model
    struct DiscoveredDevice: Identifiable {
        let id: UUID
        var name: String
        var rssi: Int
        var txPower: Int?        // optional TX power from advertisement (CBAdvertisementDataTxPowerLevelKey)
        var lastSeen: Date
        var advSummary: String
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothScanner: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("✅ Bluetooth is powered on.")
            // Helpful: log current authorization
            if #available(iOS 13.0, *) {
                print("   Authorization:", CBManager.authorization == .allowedAlways ? "allowedAlways" : "\(CBManager.authorization.rawValue)")
            }

            // If the user asked to scan before power-on, kick it off now.
            if wantsScanOnPowerOn && !isScanning {
                start()
            }
        case .poweredOff:
            print("❌ Bluetooth is powered off.")
        case .resetting:
            print("🔄 Bluetooth resetting.")
        case .unsupported:
            print("🚫 Bluetooth unsupported on this device.")
        case .unauthorized:
            print("🚫 Bluetooth unauthorized. Check app permissions.")
        case .unknown:
            fallthrough
        @unknown default:
            print("❓ Bluetooth state unknown: \(central.state.rawValue)")
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {

        let id = peripheral.identifier
        let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let name = localName ?? (peripheral.name?.isEmpty == false ? peripheral.name! : "Unknown")
        let rssi = RSSI.intValue
        let txPower = (advertisementData[CBAdvertisementDataTxPowerLevelKey] as? NSNumber)?.intValue
        let summary = summarize(advertisementData)

        // Update or insert
        if let idx = deviceIndex[id] {
            devices[idx].name = name
            devices[idx].rssi = rssi
            devices[idx].txPower = txPower ?? devices[idx].txPower
            devices[idx].lastSeen = Date()
            devices[idx].advSummary = summary
        } else {
            let dev = DiscoveredDevice(
               id: id,
               name: name,
               rssi: rssi,
               txPower: txPower,
               lastSeen: Date(),
               advSummary: summary
            )
            deviceIndex[id] = devices.count
            devices.append(dev)
        }

        // Console log (throttled to first time we see a UUID, then minimal spam)
        if deviceIndex[id] == devices.count - 1 {
            print("📱 Discovered: \(name)  •  id=\(id.uuidString)  •  RSSI=\(rssi) dBm")
            if !summary.isEmpty { print("    ⤷ \(summary)") }
        } else {
            // Occasional updates; comment out if noisy
            print("↻ Update: \(name)  •  RSSI=\(rssi) dBm")
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
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy" // correct calendar year
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"

        func pad(_ s: String, _ n: Int) -> String {
            if s.count >= n { return String(s.prefix(n)) }
            return s + String(repeating: " ", count: n - s.count)
        }

        let dateStr = dateFormatter.string(from: now)
        print("")
        print("Bluetooth Devices Detected (\(dateStr))")
        print("----------------------------------------")

        // Header
        let header = "\(pad("Name", 28))  \(pad("RSSI", 6))  \(pad("Tx Power", 8))  \(pad("Time", 8))"
        print(header)

        // Rows
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
