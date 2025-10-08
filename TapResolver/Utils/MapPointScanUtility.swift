//
//  MapPointScanUtility.swift
//  TapResolver
//
//  Role (Utility, NOT persistence):
//  - Run a timed scan window (3–20 s) at a selected Map Point.
//  - Ingest every BLE advertisement during that window (forwarded from BluetoothScanner).
//  - Aggregate per-beacon RSSI into compact "Obins" (1 dB histogram).
//  - Compute per-beacon stats (median, p10, p90, MAD).
//  - Expose the completed ScanRecord and update an in-memory running aggregate.
//
//  What this file does NOT do:
//  - It does NOT write to disk. Your Persistence layer should observe
//    `lastScanRecord` / `runningAggregates` and save them.
//
//  Expected integration:
//  - In BluetoothScanner's discovery callback, call `scanUtility.ingest(...)` once per adv frame.
//  - From UI (e.g., MapPointDrawer), call `scanUtility.startScan(...)`, and read its published state.
//
//  All types are public so your Persistence code can encode/decode if desired.
//

import Foundation
import Combine

public final class MapPointScanUtility: ObservableObject {

    // MARK: - Dependencies (injected closures)

    /// Return true to exclude a device (your "Morgue" predicate).
    /// Wire this to BeaconListsStore (e.g., by beacon ID or name).
    public var isExcluded: (_ beaconID: String, _ name: String?) -> Bool

    /// Resolve static meta for a known beacon ID (position/elevation/tx/name) from BeaconDotStore.
    /// Return nil for unknown beacons (will still be logged with minimal meta).
    public var resolveBeaconMeta: (_ beaconID: String) -> BeaconMeta?
    
    /// Get pixels per meter ratio from MetricSquareStore
    public var getPixelsPerMeter: () -> Double?
    
    /// 0–360° CW from north (already fused/filtered). Return nil if unavailable.
    public var getFusedHeadingDegrees: () -> Double? = { nil }
    
    /// Offsets (degrees) from location config (SquareMetrics)
    public var getNorthOffsetDeg:    () -> Double = { 0 }
    public var getFacingFineTuneDeg: () -> Double = { 0 }
    
    // Snapshot captured at scan start (0–360°), stored on the ScanRecord
    private var capturedFacing_deg: Double?

    // MARK: - Published runtime state (observe from UI & Persistence)

    @Published public private(set) var isScanning: Bool = false
    @Published public private(set) var activePoint: MapPointRef?
    @Published public private(set) var secondsRemaining: Double = 0
    @Published public private(set) var lastScanRecord: ScanRecord?        // emit on each scan completion
    @Published public private(set) var lastSummary: ScanSummary?           // small UI summary
    @Published public private(set) var runningAggregates: [String: RunningAggregate] = [:]
    // key = "\(pointID)|\(beaconID)"

    // MARK: - Internal state

    private var scanTimer: AnyCancellable?
    private var wallClockStart: Date?
    private var wallClockEnd: Date?
    private var windowBins: [String: Obin] = [:] // beaconID -> Obin
    private var excludedBeacons: Set<String> = [] // Track excluded beacons for debug output
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Config

    public struct Config {
        public var binMinDbm: Int = -100
        public var binMaxDbm: Int = -30
        public var binSizeDb: Int = 1
        public var defaultSessionID: String = "session-\(ISO8601DateFormatter().string(from: Date()))"
        public init() {}
    }
    @Published public var config = Config()
    
    public struct Quality {
        public var minSamples = 10
        public var minPacketsPerSecond = 0.8
        public init() {}
    }
    @Published public var quality = Quality()
    
    // MARK: - Debug Settings
    private let verboseDebug = true

    // MARK: - Shared model types (public so Persistence can use them)

    public struct MapPointRef: Codable, Equatable {
        public let pointID: String
        public let mapX_m: Double
        public let mapY_m: Double
        public let userHeight_m: Double
        public let sessionID: String
        public init(pointID: String, mapX_m: Double, mapY_m: Double, userHeight_m: Double, sessionID: String) {
            self.pointID = pointID
            self.mapX_m = mapX_m
            self.mapY_m = mapY_m
            self.userHeight_m = userHeight_m
            self.sessionID = sessionID
        }
    }

    public struct BeaconMeta: Codable {
        public let beaconID: String
        public let name: String?
        public let posX_m: Double?
        public let posY_m: Double?
        public let posZ_m: Double?
        public let txPowerSettingDbm: Int?
        public init(beaconID: String, name: String?, posX_m: Double?, posY_m: Double?, posZ_m: Double?, txPowerSettingDbm: Int?) {
            self.beaconID = beaconID
            self.name = name
            self.posX_m = posX_m
            self.posY_m = posY_m
            self.posZ_m = posZ_m
            self.txPowerSettingDbm = txPowerSettingDbm
        }
    }

    public struct Obin: Codable {
        public let binMinDbm: Int
        public let binMaxDbm: Int
        public let binSizeDb: Int
        public var counts: [Int]

        public init(binMinDbm: Int, binMaxDbm: Int, binSizeDb: Int) {
            self.binMinDbm = binMinDbm
            self.binMaxDbm = binMaxDbm
            self.binSizeDb = binSizeDb
            let bins = ((binMaxDbm - binMinDbm) / binSizeDb) + 1
            self.counts = Array(repeating: 0, count: max(0, bins))
        }

        public mutating func add(_ rssiDbm: Int) {
            guard rssiDbm >= binMinDbm, rssiDbm <= binMaxDbm else { return }
            let idx = (rssiDbm - binMinDbm) / binSizeDb
            if idx >= 0 && idx < counts.count { counts[idx] &+= 1 }
        }

        public var total: Int { counts.reduce(0, +) }

        public func quantileDbm(_ q: Double) -> Int? {
            guard total > 0 else { return nil }
            let target = Int(Double(total - 1) * q)
            var cum = 0
            for (i, c) in counts.enumerated() {
                cum += c
                if cum > target {
                    return binMinDbm + i * binSizeDb
                }
            }
            return nil
        }

        public var medianDbm: Int? { quantileDbm(0.5) }
        public var p10Dbm:   Int? { quantileDbm(0.10) }
        public var p90Dbm:   Int? { quantileDbm(0.90) }

        public func madDb(relativeTo median: Int?) -> Double? {
            guard let m = median, total > 0 else { return nil }
            var devs: [Int: Int] = [:]
            for (i, c) in counts.enumerated() where c > 0 {
                let v = binMinDbm + i * binSizeDb
                let d = abs(v - m)
                devs[d, default: 0] &+= c
            }
            let target = (total - 1) / 2
            var cum = 0
            for d in devs.keys.sorted() {
                cum += devs[d]!
                if cum > target { return Double(d) }
            }
            return nil
        }

        public mutating func merge(with other: Obin) {
            precondition(other.binMinDbm == binMinDbm && other.binMaxDbm == binMaxDbm && other.binSizeDb == binSizeDb,
                         "Cannot merge Obins with different binning")
            let n = min(counts.count, other.counts.count)
            for i in 0..<n { counts[i] &+= other.counts[i] }
        }
    }

    public struct BeaconScanAggregate: Codable {
        public let beacon: BeaconMeta
        public let samples: Int
        public let medianDbm: Int?
        public let p10Dbm: Int?
        public let p90Dbm: Int?
        public let madDb: Double?
        public let obin: Obin
        public init(beacon: BeaconMeta, samples: Int, medianDbm: Int?, p10Dbm: Int?, p90Dbm: Int?, madDb: Double?, obin: Obin) {
            self.beacon = beacon
            self.samples = samples
            self.medianDbm = medianDbm
            self.p10Dbm = p10Dbm
            self.p90Dbm = p90Dbm
            self.madDb = madDb
            self.obin = obin
        }
    }

    public struct ScanRecord: Codable {
        public let scanID: String
        public let point: MapPointRef
        public let timingStartISO: String
        public let timingEndISO: String
        public let duration_s: Double
        public let beacons: [BeaconScanAggregate]
        public let userFacing_deg: Double?   // 0–360°, CW from north, offsets applied at scan start
        public init(scanID: String, point: MapPointRef, timingStartISO: String, timingEndISO: String, duration_s: Double, beacons: [BeaconScanAggregate], userFacing_deg: Double?) {
            self.scanID = scanID
            self.point = point
            self.timingStartISO = timingStartISO
            self.timingEndISO = timingEndISO
            self.duration_s = duration_s
            self.beacons = beacons
            self.userFacing_deg = userFacing_deg
        }
    }

    public struct RunningAggregate: Codable {
        public let pointID: String
        public let beaconID: String
        public var totalPackets: Int
        public var totalSeconds: Double
        public var numScans: Int
        public var obin: Obin
        public var lastUpdateISO: String

        public var medianDbm: Int? { obin.medianDbm }
        public var p10Dbm: Int? { obin.p10Dbm }
        public var p90Dbm: Int? { obin.p90Dbm }
        public var madDb: Double? { obin.madDb(relativeTo: obin.medianDbm) }

        public init(pointID: String, beaconID: String, totalPackets: Int, totalSeconds: Double, numScans: Int, obin: Obin, lastUpdateISO: String) {
            self.pointID = pointID
            self.beaconID = beaconID
            self.totalPackets = totalPackets
            self.totalSeconds = totalSeconds
            self.numScans = numScans
            self.obin = obin
            self.lastUpdateISO = lastUpdateISO
        }
    }

    public struct ScanSummary: Codable {
        public let scanID: String
        public let pointID: String
        public let duration_s: Double
        public let topBeacons: [TopBeacon]
        public struct TopBeacon: Codable {
            public let beaconID: String
            public let name: String?
            public let medianDbm: Int?
            public let samples: Int
            public init(beaconID: String, name: String?, medianDbm: Int?, samples: Int) {
                self.beaconID = beaconID
                self.name = name
                self.medianDbm = medianDbm
                self.samples = samples
            }
        }
        public init(scanID: String, pointID: String, duration_s: Double, topBeacons: [TopBeacon]) {
            self.scanID = scanID
            self.pointID = pointID
            self.duration_s = duration_s
            self.topBeacons = topBeacons
        }
    }

    // MARK: - Init

    public init(
        isExcluded: @escaping (_ beaconID: String, _ name: String?) -> Bool,
        resolveBeaconMeta: @escaping (_ beaconID: String) -> BeaconMeta?,
        getPixelsPerMeter: @escaping () -> Double?
    ) {
        self.isExcluded = isExcluded
        self.resolveBeaconMeta = resolveBeaconMeta
        self.getPixelsPerMeter = getPixelsPerMeter
    }

    // MARK: - API

    /// Begin a timed scan window; UI should call this from your Scan button.
    public func startScan(pointID: String, mapX_m: Double, mapY_m: Double, userHeight_m: Double, sessionID: String? = nil, durationSeconds: TimeInterval) {
        guard !isScanning else { return }
        isScanning = true
        wallClockStart = Date()
        wallClockEnd = nil
        secondsRemaining = durationSeconds
        windowBins.removeAll(keepingCapacity: true)
        excludedBeacons.removeAll()

        let sid = sessionID ?? config.defaultSessionID
        activePoint = MapPointRef(pointID: pointID, mapX_m: mapX_m, mapY_m: mapY_m, userHeight_m: userHeight_m, sessionID: sid)
        
        // Capture facing at scan start (0–360°, CW from north)
        let fused = getFusedHeadingDegrees() ?? 0
        let northOffset = getNorthOffsetDeg()
        let facingFineTune = getFacingFineTuneDeg()
        let raw = fused + northOffset + facingFineTune
        var wrapped = raw.truncatingRemainder(dividingBy: 360)
        if wrapped < 0 { wrapped += 360 }
        capturedFacing_deg = wrapped
        
        // DEBUG: Print compass values
        print("🧭 COMPASS DEBUG at scan start:")
        print("   fusedHeadingDegrees: \(String(format: "%.2f", fused))°")
        print("   northOffsetDeg: \(String(format: "%.2f", northOffset))°")
        print("   facingFineTuneDeg: \(String(format: "%.2f", facingFineTune))°")
        print("   raw calculation: \(String(format: "%.2f", raw))°")
        print("   wrapped (exported): \(String(format: "%.2f", wrapped))°")

        // Countdown timer (UI: bind to `secondsRemaining`)
        scanTimer = Timer.publish(every: 0.05, on: .main, in: .default)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.secondsRemaining -= 0.05
                if self.secondsRemaining <= 0 {
                    self.finishScan()
                }
            }
    }

    /// Cancel current scan window (no output).
    public func cancelScan() {
        guard isScanning else { return }
        scanTimer?.cancel()
        scanTimer = nil
        isScanning = false
        activePoint = nil
        windowBins.removeAll()
    }

    /// Ingest a single BLE advertisement. Call this from BluetoothScanner's discovery callback.
    public func ingest(beaconID: String, name: String?, rssiDbm: Int, txPowerDbm: Int?, timestamp: TimeInterval) {
        guard isScanning, activePoint != nil else { return }
        
        // DEBUG: Show filtering decisions
        if isExcluded(beaconID, name) {
            // Only show first exclusion per beacon to avoid spam
            if windowBins[beaconID] == nil && !excludedBeacons.contains(beaconID) {
                print("🚫 Excluding beacon: \(name ?? "Unknown") (ID: \(beaconID)) - not in active beacon list or no map dot")
                excludedBeacons.insert(beaconID)
            }
            return 
        }
        
        // DEBUG: Show first few advertisements being ingested
        if windowBins[beaconID] == nil {
            print("📡 Ingesting new beacon: \(name ?? "Unknown") (ID: \(beaconID)) RSSI: \(rssiDbm) dBm")
        }
        
        var obin = windowBins[beaconID] ?? Obin(binMinDbm: config.binMinDbm, binMaxDbm: config.binMaxDbm, binSizeDb: config.binSizeDb)
        obin.add(rssiDbm)
        windowBins[beaconID] = obin
    }

    // MARK: - Internals

    public func finishScan() {
        scanTimer?.cancel()
        scanTimer = nil
        wallClockEnd = Date()
        let start = wallClockStart ?? Date()
        let end = wallClockEnd ?? Date()
        let duration = end.timeIntervalSince(start)

        guard let point = activePoint else {
            isScanning = false
            windowBins.removeAll()
            return
        }

        // Build per-beacon aggregates
        var aggregates: [BeaconScanAggregate] = []
        aggregates.reserveCapacity(windowBins.count)

        for (beaconID, obin) in windowBins {
            let meta = resolveBeaconMeta(beaconID) ?? BeaconMeta(beaconID: beaconID, name: nil, posX_m: nil, posY_m: nil, posZ_m: nil, txPowerSettingDbm: nil)
            let samples = obin.total
            let med = obin.medianDbm
            let agg = BeaconScanAggregate(
                beacon: meta,
                samples: samples,
                medianDbm: med,
                p10Dbm: obin.p10Dbm,
                p90Dbm: obin.p90Dbm,
                madDb: obin.madDb(relativeTo: med),
                obin: obin
            )
            aggregates.append(agg)

            // Update in-memory running aggregate
            updateRunningAggregate(pointID: point.pointID, beaconID: beaconID, obin: obin, duration: duration)
        }

        // Emit the completed ScanRecord (Persistence can observe and save)
        let scanID = "scan_\(ISO8601DateFormatter().string(from: start))_\(point.pointID)".replacingOccurrences(of: ":", with: "-")
        let record = ScanRecord(
            scanID: scanID,
            point: point,
            timingStartISO: ISO8601DateFormatter().string(from: start),
            timingEndISO: ISO8601DateFormatter().string(from: end),
            duration_s: duration,
            beacons: aggregates.sorted { ($0.medianDbm ?? -200) > ($1.medianDbm ?? -200) },
            userFacing_deg: capturedFacing_deg
        )
        lastScanRecord = record

        // Save using new V1 persistence format
        saveScanRecordV1(record: record, start: start, end: end)

        // DEBUG: Print scan results to console
        if verboseDebug {
            print("🔍 SCAN COMPLETE:")
            print("   Point ID: \(point.pointID)")
            print("   Duration: \(String(format: "%.1f", duration))s")
            print("   Beacons found: \(aggregates.count)")
            for beacon in aggregates.prefix(5) {
                let name = beacon.beacon.name ?? "Unknown"
                let samples = beacon.samples
                let median = beacon.medianDbm ?? -999
                let pps = duration > 0 ? Double(samples)/duration : 0
                print("   • \(name): \(samples) samples, median RSSI: \(median) dBm, \(String(format: "%.2f", pps)) pkt/s")
            }
            print("   Running aggregates total: \(runningAggregates.count) map point to beacon pairings")
        }

        // Small UI summary - filter by quality thresholds first
        let filtered = record.beacons.filter { b in
            // keep only beacons with enough data
            let samples = b.samples
            let pps = duration > 0 ? Double(samples)/duration : 0
            return samples >= quality.minSamples && pps >= quality.minPacketsPerSecond
        }
        let tops = filtered
            .sorted { ($0.medianDbm ?? -200) > ($1.medianDbm ?? -200) }
            .prefix(6)
            .map { ScanSummary.TopBeacon(beaconID: $0.beacon.beaconID, name: $0.beacon.name, medianDbm: $0.medianDbm, samples: $0.samples) }

        lastSummary = ScanSummary(scanID: scanID, pointID: point.pointID, duration_s: duration, topBeacons: Array(tops))

        // Reset window
        isScanning = false
        activePoint = nil
        windowBins.removeAll()
    }

    private func updateRunningAggregate(pointID: String, beaconID: String, obin newObin: Obin, duration: TimeInterval) {
        let key = "\(pointID)|\(beaconID)"
        let nowISO = ISO8601DateFormatter().string(from: Date())

        if var existing = runningAggregates[key] {
            var merged = existing.obin
            merged.merge(with: newObin)
            existing.obin = merged
            existing.totalPackets &+= newObin.total
            existing.totalSeconds += duration
            existing.numScans &+= 1
            existing.lastUpdateISO = nowISO
            runningAggregates[key] = existing
        } else {
            let agg = RunningAggregate(
                pointID: pointID,
                beaconID: beaconID,
                totalPackets: newObin.total,
                totalSeconds: duration,
                numScans: 1,
                obin: newObin,
                lastUpdateISO: nowISO
            )
            runningAggregates[key] = agg
        }
    }
    
    // MARK: - V1 Persistence Integration
    
    private func saveScanRecordV1(record: ScanRecord, start: Date, end: Date) {
        do {
            let locationID = PersistenceContext.shared.locationID
            
            // Get pixels per meter from MetricSquareStore
            let pixelsPerMeter = getPixelsPerMeter()
            
            // Build beacon geometry lookup from existing beacon metadata
            let beaconGeo: [String: (posPx: CGPoint, elevation_m: Double?)] = 
                Dictionary(uniqueKeysWithValues: record.beacons.compactMap { agg in
                    // Use the beacon metadata that was resolved during scanning
                    guard let posX = agg.beacon.posX_m, let posY = agg.beacon.posY_m else { return nil }
                    return (agg.beacon.beaconID, (CGPoint(x: posX, y: posY), agg.beacon.posZ_m))
                })
            
            // Convert existing ScanRecord to V1 format
            let beaconStatsTuples: [(beaconID: String, median: Int, mad: Int, p10: Int, p90: Int, samples: Int, hist: (min:Int, max:Int, size:Int, counts:[Int])?)] = record.beacons.map { agg in
                let median = agg.medianDbm ?? -999
                let mad = Int(agg.madDb ?? 0)
                let p10 = agg.p10Dbm ?? -999
                let p90 = agg.p90Dbm ?? -999
                let samples = agg.samples
                let hist = (min: agg.obin.binMinDbm, max: agg.obin.binMaxDbm, size: agg.obin.binSizeDb, counts: agg.obin.counts)
                
                return (beaconID: agg.beacon.beaconID, median: median, mad: mad, p10: p10, p90: p90, samples: samples, hist: hist)
            }
            
            // For now, use a dummy point position since we don't have the actual map point pixel coordinates
            // TODO: Get actual map point pixel coordinates from MapTransformStore
            let pointXY_px = CGPoint(x: 0, y: 0) // This should be the actual map point pixel position
            
            let scanDTO = ScanBuilder.makeScan(
                scanID: record.scanID,
                locationID: locationID,
                pointID: record.point.pointID,
                sessionID: record.point.sessionID,
                start: start, end: end, duration: record.duration_s,
                deviceHeight_m: record.point.userHeight_m,
                facing_deg: nil, // Not available in current format
                point_xy_px: pointXY_px,
                point_xy_m: CGPoint(x: record.point.mapX_m, y: record.point.mapY_m),
                mapResolution_px: nil, // Not available in current format
                pixelsPerMeter: pixelsPerMeter,
                beaconGeo: beaconGeo,
                beacons: beaconStatsTuples
            )
            
            let _ = try PersistenceService.writeScan(scanDTO, at: end)
            print("💾 Saved scan record V1 to Application Support with distances: \(beaconGeo.count) beacons")
        } catch {
            print("❌ Failed to save scan record V1: \(error)")
        }
    }
}
