import Foundation

public struct ScanRecordV1: Codable {
    public let schema: String = "tapresolver.scan.v1"
    public let scanID: String
    public let locationID: String
    public let pointID: String
    public let sessionID: String

    public struct Timing: Codable { public let startISO: String; public let endISO: String; public let duration_s: Double }
    public let timing: Timing

    public struct UserPose: Codable { public let deviceHeight_m: Double?; public let facing_deg: Double? }
    public let user: UserPose

    public struct Point: Codable { public let xy_px: [Double]; public let xy_m: [Double]? }
    public let point: Point

    public struct TransformSnap: Codable { public let mapAssetResolution_px: [Int]? } // keep only what's useful now
    public let transform: TransformSnap?

    public struct BeaconObs: Codable {
        public let beaconID: String
        public struct Stats: Codable { public let median_dbm: Int; public let mad_db: Int; public let p10_dbm: Int; public let p90_dbm: Int; public let samples: Int }
        public let stats: Stats
        public struct Hist: Codable { public let binMin_dbm: Int; public let binMax_dbm: Int; public let binSize_db: Int; public let counts: [Int]; public let underflow: Int?; public let overflow: Int?; public let edgePolicy: String? }
        public let hist: Hist?
        
        public struct Distances: Codable {
            public let xyMapD_px: Double
            public let xyMapD_m: Double
            public let xyzMapD_px: Double
            public let xyzMapD_m: Double
        }
        public let dist: Distances?
        
        // Beacon physical properties and metadata
        public struct BeaconGeo: Codable {
            // Position
            public let position_px: [Double]?    // [x, y] in pixels on map
            public let position_m: [Double]?     // [x, y] in meters
            public let elevation_m: Double?      // Z coordinate in meters (beacon height)
            
            // Radio properties
            public let txPower_dbm: Int?         // Transmit power setting (dBm)
            
            // Metadata
            public let name: String              // Beacon identifier/name
            public let color: [Double]?          // RGB color [r, g, b] in 0.0-1.0 range
        }
        public let geo: BeaconGeo?
    }
    public let beacons: [BeaconObs]
}
