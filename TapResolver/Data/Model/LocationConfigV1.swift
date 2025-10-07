import Foundation

public struct LocationConfigV1: Codable {
    public let schema: String = "tapresolver.location.v1"
    public let createdAtISO: String
    public let location: Location

    public struct Location: Codable {
        public let id: String
        public let name: String
        public let coords: Coords
        public let image: Image
        public let metric: Metric
        public let compass: Compass
        public let beacons: [Beacon]
        public let mapPoints: [MapPoint]
        public let userDefaults: UserDefaults?
    }

    public struct Coords: Codable { public let origin: String; public let yAxis: String; public let angleZero: String; public let angleClockwise: Bool }
    public struct Image: Codable { public let file: String; public let resolution_px: [Int] }
    public struct Metric: Codable { public let pixelSide_px: Int; public let meterSide_m: Double; public let pixelsPerMeter: Double }
    public struct Compass: Codable { public let northOffset_deg: Double; public let facingOffset_deg: Double }
    public struct Beacon: Codable { public let beaconID: String; public let mac: String?; public let txPower_dbm: Int?; public let elevation_m: Double?; public let position_px: [Double]?; public let position_m: [Double]? }
    public struct MapPoint: Codable { public let pointID: String; public let xy_px: [Double]; public let label: String? }
    public struct UserDefaults: Codable { public let deviceHeight_m: Double?; public let errorMargin_m: Double? }
}
