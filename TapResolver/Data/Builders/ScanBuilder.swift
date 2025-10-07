import Foundation
import CoreGraphics

enum ScanBuilder {
    static func makeScan(
        scanID: String,
        locationID: String,
        pointID: String,
        sessionID: String,
        start: Date, end: Date, duration: Double,
        deviceHeight_m: Double?,
        facing_deg: Double?,
        point_xy_px: CGPoint, point_xy_m: CGPoint?,
        mapResolution_px: CGSize?,
        pixelsPerMeter: Double?,                              // NEW
        beaconGeo: [String: (posPx: CGPoint, elevation_m: Double?)], // NEW (by beaconID)
        beacons: [(beaconID: String, median: Int, mad: Int, p10: Int, p90: Int, samples: Int,
                   hist: (min:Int, max:Int, size:Int, counts:[Int])?)]
    ) -> ScanRecordV1 {

        let timing = ScanRecordV1.Timing(
            startISO: JSONKit.iso8601.string(from: start),
            endISO: JSONKit.iso8601.string(from: end),
            duration_s: Rounding.d(duration, 3)  // 3 decimals
        )
        let user = ScanRecordV1.UserPose(deviceHeight_m: deviceHeight_m, facing_deg: facing_deg)
        let point = ScanRecordV1.Point(
            xy_px: Rounding.arr2(point_xy_px, 2),                  // 2 decimals in px
            xy_m: point_xy_m.map { Rounding.arr2(Double($0.x), Double($0.y), 2) } // 2 decimals in m
        )
        let transform = mapResolution_px.map { r in
            ScanRecordV1.TransformSnap(mapAssetResolution_px: [Int(r.width), Int(r.height)])
        }

        let obs: [ScanRecordV1.BeaconObs] = beacons.map { b in
            let stats = ScanRecordV1.BeaconObs.Stats(median_dbm: b.median, mad_db: b.mad, p10_dbm: b.p10, p90_dbm: b.p90, samples: b.samples)
            let hist = b.hist.map { h in
                ScanRecordV1.BeaconObs.Hist(binMin_dbm: h.min, binMax_dbm: h.max, binSize_db: h.size, counts: h.counts, underflow: 0, overflow: 0, edgePolicy: "leftInclusive")
            }
            
            // Distances (optional if we have geometry)
            var dist: ScanRecordV1.BeaconObs.Distances? = nil
            if let geo = beaconGeo[b.beaconID],
               let ppm = pixelsPerMeter {
                let planar_px_raw = DistanceKit.planarPx(from: point_xy_px, to: geo.posPx)
                let planar_m_raw  = planar_px_raw / ppm
                let dz_m = (geo.elevation_m ?? 0) - (deviceHeight_m ?? 0) // user height as receiver Z
                let xyz_px_raw = DistanceKit.xyzPx(planar_px: planar_px_raw, dz_m: dz_m, ppm: ppm)
                let xyz_m_raw  = DistanceKit.xyzM(planar_m: planar_m_raw, dz_m: dz_m)
                
                // Round to 2 decimals
                let planar_px = Rounding.d(planar_px_raw, 2)
                let planar_m  = Rounding.d(planar_m_raw, 2)
                let xyz_px = Rounding.d(xyz_px_raw, 2)
                let xyz_m  = Rounding.d(xyz_m_raw, 2)
                
                dist = .init(xyMapD_px: planar_px,
                             xyMapD_m:  planar_m,
                             xyzMapD_px: xyz_px,
                             xyzMapD_m:  xyz_m)
            }
            
            return ScanRecordV1.BeaconObs(
                beaconID: b.beaconID,
                stats: stats,
                hist: hist,
                dist: dist
            )
        }

        return ScanRecordV1(
            scanID: scanID,
            locationID: locationID,
            pointID: pointID,
            sessionID: sessionID,
            timing: timing,
            user: user,
            point: point,
            transform: transform,
            beacons: obs
        )
    }
}
