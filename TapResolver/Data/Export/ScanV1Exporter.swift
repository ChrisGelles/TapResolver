import Foundation
import CoreGraphics

enum ScanV1Exporter {
    static func buildJSON(
        from utilRecord: MapPointScanUtility.ScanRecord,
        locationID: String,
        ppm: Double,
        pointPx: CGPoint,           // map-point in pixels
        beaconsPx: [String: CGPoint],// beaconID -> px
        elevations: [String: Double?],
        txPowers: [String: Int?],
        colors: [String: [Double]?],
        mapResolution: CGSize?
    ) throws -> (json: Data, filename: String) {

        // 1) Convert pointPx -> meters (optional)
        let pointM = CGPoint(x: pointPx.x / ppm, y: pointPx.y / ppm)

        // 2) Build geometry dictionary with full beacon metadata
        var beaconGeo: [String: (posPx: CGPoint, elevation_m: Double?, txPower_dbm: Int?, name: String, color: [Double]?)] = [:]
        for (id, px) in beaconsPx {
            beaconGeo[id] = (
                posPx: px,
                elevation_m: elevations[id] ?? nil,
                txPower_dbm: txPowers[id] ?? nil,
                name: id,  // beaconID is the name
                color: colors[id] ?? nil
            )
        }

        // 3) Flatten utilRecord beacons into the tuple list ScanBuilder expects:
        //    (beaconID, median, mad, p10, p90, samples, hist)
        let tuples: [(String, Int, Int, Int, Int, Int, (min:Int,max:Int,size:Int,counts:[Int])?)] =
            utilRecord.beacons.map { b in
                let median = b.medianDbm ?? -999
                let mad = Int(b.madDb ?? 0)
                let p10 = b.p10Dbm ?? -999
                let p90 = b.p90Dbm ?? -999
                let hist = (min: b.obin.binMinDbm, max: b.obin.binMaxDbm, size: b.obin.binSizeDb, counts: b.obin.counts)
                return (b.beacon.beaconID, median, mad, p10, p90, b.samples, hist)
            }

        // 4) Use your existing builder (this computes distances):
        let v1 = ScanBuilder.makeScan(
            scanID: utilRecord.scanID,
            locationID: locationID,
            pointID: utilRecord.point.pointID,
            sessionID: utilRecord.point.sessionID,
            start: ISO8601DateFormatter().date(from: utilRecord.timingStartISO) ?? Date(),
            end: ISO8601DateFormatter().date(from: utilRecord.timingEndISO) ?? Date(),
            duration: utilRecord.duration_s,
            deviceHeight_m: utilRecord.point.userHeight_m,
            facing_deg: utilRecord.userFacing_deg,
            point_xy_px: pointPx, point_xy_m: pointM,
            mapResolution_px: mapResolution,
            pixelsPerMeter: ppm,
            beaconGeo: beaconGeo,
            beacons: tuples
        )

        // 5) Encode with your JSONKit encoder (pretty/sorted)
        let data = try JSONKit.encoder().encode(v1)
        let filename = "\(v1.scanID).json"
        return (data, filename)
    }
}
