//
//  AppBootstrap.swift
//  TapResolver
//
//  Created by restructuring on 9/19/25.
//

import SwiftUI


struct AppBootstrap: ViewModifier {
    let scanner: BluetoothScanner
    let beaconDots: BeaconDotStore
    let squares: MetricSquareStore
    let lists: BeaconListsStore
    let scanUtility: MapPointScanUtility
    let orientationManager: CompassOrientationManager
    let squareMetrics: SquareMetrics
    let beaconState: BeaconStateManager  // Added for beacon state consolidation

    private let initialScanWindow: TimeInterval = 2.0

    // Run-once guard to prevent double wiring on scene changes
    private static var hasBootstrapped = false

    func body(content: Content) -> some View {
        content
            .onAppear {
                // Prevent double running on scene activations
                guard !Self.hasBootstrapped else { return }
                Self.hasBootstrapped = true

                createLocationStubIfNeeded()
                scanner.scanUtility = scanUtility
                scanner.beaconLists = lists
                scanner.onDeviceNameDiscovered = { name, id in
                    lists.ingest(deviceName: name, id: id)
                }
                configureScanUtilityClosures()
                
                // ARCHITECTURAL INTEGRATION: Start beacon state monitoring
                // This consolidates beacon state updates into a single source of truth
                beaconState.startMonitoring(scanner: scanner)
                
                // Run initial snapshot scan to populate Morgue on app launch
                // This restores "morning behavior" where Morgue is auto-populated
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    scanner.snapshotOnce()
                }
            }
    }
    
    
    
    private func configureScanUtilityClosures() {
        // Whitelist-only filter: allow any device that's in Beacon Drawer.
        // (Distances will be optional if a dot isn't placed yet.)
        scanUtility.isExcluded = { [weak lists] beaconID, name in
            guard let lists = lists else { return true }          // fail safe: exclude if lists missing
            guard let name = name, !name.isEmpty else { return true }
            return !lists.beacons.contains(name)                  // exclude if not on whitelist
        }

        // Provide meta for known beacons (x,y,z,label, tx power, iBeacon data)
        scanUtility.resolveBeaconMeta = { [weak beaconDots, weak squares, weak scanner] beaconID in
            guard let store = beaconDots,
                  let dot = store.dots.first(where: { $0.beaconID == beaconID }) else {
                return MapPointScanUtility.BeaconMeta(
                    beaconID: beaconID,
                    name: beaconID,
                    posX_m: nil,
                    posY_m: nil,
                    posZ_m: nil,
                    txPowerSettingDbm: nil,
                    ibeaconUUID: nil,
                    ibeaconMajor: nil,
                    ibeaconMinor: nil,
                    ibeaconMeasuredPower: nil
                )
            }

            // Convert pixels to meters using the same ppm calculation
            var x_m: Double?, y_m: Double?
            if let squaresStore = squares {
                let lockedSquares = squaresStore.squares.filter { $0.isLocked }
                let squaresToUse = lockedSquares.isEmpty ? squaresStore.squares : lockedSquares
                if let square = squaresToUse.first {
                    let ppm = Double(square.side) / square.meters
                    if ppm > 0 {
                        x_m = Double(dot.mapPoint.x) / ppm
                        y_m = Double(dot.mapPoint.y) / ppm
                    }
                }
            }
            
            // Get iBeacon data from BluetoothScanner
            let device = scanner?.devices.first(where: { $0.name == beaconID })

            return MapPointScanUtility.BeaconMeta(
                beaconID: beaconID,
                name: beaconID,
                posX_m: x_m,
                posY_m: y_m,
                posZ_m: store.getElevation(for: beaconID),
                txPowerSettingDbm: store.getTxPower(for: beaconID),
                ibeaconUUID: device?.ibeaconUUID,
                ibeaconMajor: device?.ibeaconMajor,
                ibeaconMinor: device?.ibeaconMinor,
                ibeaconMeasuredPower: device?.ibeaconMeasuredPower
            )
        }
        
        // Provide pixels per meter from MetricSquareStore
        scanUtility.getPixelsPerMeter = { [weak squares] in
            guard let store = squares else { return nil }
            
            // Calculate pixels per meter from the first locked square, or any square if none are locked
            let lockedSquares = store.squares.filter { $0.isLocked }
            let squaresToUse = lockedSquares.isEmpty ? store.squares : lockedSquares
            
            guard let square = squaresToUse.first else { return nil }
            
            // pixels per meter = side_pixels / side_meters
            let pixelsPerMeter = Double(square.side) / square.meters
            return pixelsPerMeter > 0 ? pixelsPerMeter : nil
        }
        
        // Heading source (0–360° CW from north)
        scanUtility.getFusedHeadingDegrees = { [weak orientationManager] in
            orientationManager?.fusedHeadingDegrees
        }
        
        // Offsets from location config (SquareMetrics)
        scanUtility.getNorthOffsetDeg = { [weak squareMetrics] in
            squareMetrics?.northOffsetDeg ?? 0
        }
        scanUtility.getFacingFineTuneDeg = { [weak squareMetrics] in
            squareMetrics?.facingFineTuneDeg ?? 0
        }
        
        // Map base orientation (where north points on the map image)
        scanUtility.getMapBaseOrientation = { [weak squareMetrics] in
            squareMetrics?.mapBaseOrientation ?? 270.0
        }
    }
    
    /// Create a location.json stub for future use
    private func createLocationStubIfNeeded() {
        struct LocationStub: Codable {
            let id: String
            let name: String
            let createdISO: String
            let updatedISO: String
        }
        
        let ctx = PersistenceContext.shared
        let fm = FileManager.default
        let locationJSONPath = ctx.locationDir.appendingPathComponent("location.json")
        
        if !fm.fileExists(atPath: locationJSONPath.path) {
            let now = ISO8601DateFormatter().string(from: Date())
            let stub = LocationStub(id: ctx.locationID, name: "Default Location", createdISO: now, updatedISO: now)
            if let data = try? JSONEncoder().encode(stub) {
                try? data.write(to: locationJSONPath, options: .atomic)
                print("📁 Created location.json stub at \(locationJSONPath.path)")
            }
        }
    }
}

extension View {
    func appBootstrap(
        scanner: BluetoothScanner,
        beaconDots: BeaconDotStore,
        squares: MetricSquareStore,
        lists: BeaconListsStore,
        scanUtility: MapPointScanUtility,
        orientationManager: CompassOrientationManager,
        squareMetrics: SquareMetrics,
        beaconState: BeaconStateManager  // Pass BeaconStateManager for initialization
    ) -> some View {
        self.modifier(AppBootstrap(
            scanner: scanner,
            beaconDots: beaconDots,
            squares: squares,
            lists: lists,
            scanUtility: scanUtility,
            orientationManager: orientationManager,
            squareMetrics: squareMetrics,
            beaconState: beaconState
        ))
    }
}
