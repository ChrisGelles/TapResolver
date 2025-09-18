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

    // MARK: - Setup
    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main) // main queue for simplicity
    }

    // MARK: - Public API
    func start() {
        guard central.state == .poweredOn else {
            print("⚠️ Bluetooth not ready. State: \(central.state.rawValue)")
            return
        }
        guard !isScanning else { return }

        print("🔍 Starting BLE scan…")
        isScanning = true
        central.scanForPeripherals(withServices: nil,
                                   options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
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
            // Optional: auto-start scanning
            // start()
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
        let name = (peripheral.name?.isEmpty == false ? peripheral.name! : "Unknown")
        let rssi = RSSI.intValue
        let summary = summarize(advertisementData)

        // Update or insert
        if let idx = deviceIndex[id] {
            devices[idx].name = name
            devices[idx].rssi = rssi
            devices[idx].lastSeen = Date()
            devices[idx].advSummary = summary
        } else {
            let dev = DiscoveredDevice(id: id,
                                       name: name,
                                       rssi: rssi,
                                       lastSeen: Date(),
                                       advSummary: summary)
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

