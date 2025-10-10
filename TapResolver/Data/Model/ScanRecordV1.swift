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
        public let meta: BeaconMeta
        public let ibeacon: IBeaconData?
        public let radio: BeaconRadio?
        
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
        
        // Identity & display metadata
        public struct BeaconMeta: Codable {
            public let name: String              // Human-readable beacon name
            public let color: [Double]?          // RGB color [r, g, b] (0.0-1.0)
            public let model: String?            // Hardware model (e.g., "BC04P")
        }
        
        // Apple iBeacon protocol data (from advertisement)
        public struct IBeaconData: Codable {
            public let uuid: String              // 128-bit UUID
            public let major: Int                // 16-bit major ID
            public let minor: Int                // 16-bit minor ID
            public let measuredPower_dbm: Int    // Calibrated RSSI at 1 meter
        }
        
        // Radio/RF configuration (manual settings)
        public struct BeaconRadio: Codable {
            public let txPowerSetting_dbm: Int?  // Configured transmission power
            public let advertisingInterval_ms: Int?  // Broadcast interval (optional)
        }
        
        // Physical location on map (UPDATED - position only)
        public struct BeaconGeo: Codable {
            public let position_px: [Double]?    // [x, y] in pixels
            public let position_m: [Double]?     // [x, y] in meters
            public let elevation_m: Double?      // Z coordinate in meters
        }
        
        public let geo: BeaconGeo?
    }
    public let beacons: [BeaconObs]
}
