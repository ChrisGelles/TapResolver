//
//  KBeaconConnectionManager.swift
//  TapResolver
//
//  Wraps kbeaconlib2 SDK for beacon configuration reading
//

import Foundation
import kbeaconlib2
import Combine

/// Configuration data read from a KBeacon device
struct KBeaconConfiguration {
    let txPower: Int           // dBm
    let intervalMs: Float      // milliseconds
    let batteryPercent: Int    // 0-100
    let model: String?
    let firmwareVersion: String?
}

class KBeaconConnectionManager: NSObject, ObservableObject {
    @Published var discoveredBeacons: [KBeacon] = []
    @Published var isScanning = false
    @Published var connectionState: ConnectionState = .disconnected
    
    enum ConnectionState: Equatable {
        case disconnected
        case connecting
        case connected
        case failed(String)
    }
    
    private var beaconsMgr: KBeaconsMgr?
    private var beaconsDictionary: [String: KBeacon] = [:]
    private var currentCompletion: ((Bool, String) -> Void)?
    
    override init() {
        super.init()
        beaconsMgr = KBeaconsMgr.sharedBeaconManager
        beaconsMgr?.delegate = self
    }
    
    // MARK: - Scanning
    
    func startScanning() {
        discoveredBeacons.removeAll()
        beaconsDictionary.removeAll()
        
        if beaconsMgr?.startScanning() == true {
            isScanning = true
            print("📡 [KBeaconMgr] Started scanning")
        } else {
            print("⚠️ [KBeaconMgr] Failed to start scanning")
        }
    }
    
    func stopScanning() {
        beaconsMgr?.stopScanning()
        isScanning = false
        print("📡 [KBeaconMgr] Stopped scanning")
    }
    
    // MARK: - Connection
    
    func connect(to beacon: KBeacon, password: String, completion: @escaping (Bool, String) -> Void) {
        currentCompletion = completion
        connectionState = .connecting
        beacon.connect(password, timeout: 15.0, delegate: self)
    }
    
    func disconnect(from beacon: KBeacon) {
        beacon.disconnect()
        connectionState = .disconnected
    }
    
    /// Connect to a beacon using the stored password for the current location
    func connectUsingStoredPassword(to beacon: KBeacon, locationID: String, completion: @escaping (Bool, String) -> Void) {
        guard let password = BeaconPasswordStore.shared.getPassword(for: locationID) else {
            completion(false, "No password stored for location '\(locationID)'")
            return
        }
        
        connect(to: beacon, password: password, completion: completion)
    }
    
    // MARK: - Configuration Reading
    
    func readConfiguration(from beacon: KBeacon) -> KBeaconConfiguration? {
        guard let commonCfg = beacon.getCommonCfg() else {
            print("⚠️ [KBeaconMgr] Failed to get common config")
            return nil
        }
        
        var txPower: Int = 0
        var intervalMs: Float = 1000
        
        if let slotCfg = beacon.getSlotCfg(0) as? KBCfgAdvBase {
            txPower = Int(slotCfg.getTxPower())
            
            let interval = slotCfg.getAdvPeriod()
            if !interval.isNaN && !interval.isInfinite && interval > 0 && interval <= 100000 {
                intervalMs = interval
            }
        }
        
        let batteryPercent = commonCfg.getBatteryPercent()
        let safeBattery = (batteryPercent >= 0 && batteryPercent <= 100) ? batteryPercent : 0
        
        return KBeaconConfiguration(
            txPower: txPower,
            intervalMs: intervalMs,
            batteryPercent: Int(safeBattery),
            model: commonCfg.getModel(),
            firmwareVersion: commonCfg.getVersion()
        )
    }
}

// MARK: - KBeaconMgrDelegate
extension KBeaconConnectionManager: KBeaconMgrDelegate {
    func onBeaconDiscovered(beacons: [KBeacon]) {
        for beacon in beacons {
            if let uuidString = beacon.uuidString {
                beaconsDictionary[uuidString] = beacon
            }
        }
        
        DispatchQueue.main.async {
            self.discoveredBeacons = Array(self.beaconsDictionary.values)
                .sorted { ($0.name ?? "") < ($1.name ?? "") }
        }
    }
    
    func onCentralBleStateChange(newState: BLECentralMgrState) {
        switch newState {
        case .PowerOn:
            print("📡 [KBeaconMgr] Bluetooth powered on")
        case .PowerOff:
            print("📡 [KBeaconMgr] Bluetooth powered off")
        default:
            print("📡 [KBeaconMgr] Bluetooth state changed")
        }
    }
}

// MARK: - ConnStateDelegate
extension KBeaconConnectionManager: ConnStateDelegate {
    func onConnStateChange(_ beacon: KBeacon, state: KBConnState, evt: KBConnEvtReason) {
        DispatchQueue.main.async {
            switch state {
            case .Connected:
                self.connectionState = .connected
                self.currentCompletion?(true, "Connected successfully")
                self.currentCompletion = nil
            case .Disconnected:
                if evt == .ConnAuthFail {
                    self.connectionState = .failed("Authentication failed")
                    self.currentCompletion?(false, "Authentication failed - check password")
                } else {
                    self.connectionState = .disconnected
                    self.currentCompletion?(false, "Connection failed")
                }
                self.currentCompletion = nil
            case .Connecting:
                self.connectionState = .connecting
            @unknown default:
                break
            }
        }
    }
}

