//
//  RssiDistance.swift
//  IndoorPositioningUtils
//
//  Created by Chris (Museum Project)
//
//  This utility converts an RSSI value (received signal strength indicator)
//  into an estimated distance in meters, using the log-distance path-loss model.
//

import Foundation

/// Converts RSSI (dBm) into a distance estimate (meters).
///
/// Formula (log-distance path loss):
///    d = 10 ^ ((TxPower1m - RSSI) / (10 * n))
///
/// - Parameters:
///   - rssi: The measured RSSI value from the beacon (in dBm).
///           Typically a **negative number**: e.g. -59, -65, -80.
///           More negative → weaker signal → farther away.
///   - txPowerAt1m: The **calibrated RSSI value at 1 meter** (dBm).
///           Example: -59 dBm (meaning "when standing 1 m away,
///           my phone sees about -59 dBm").
///           This must be measured for each **device class** (e.g., iPhone 14)
///           because different antennas read differently.
///   - pathLossExponent: The "n" factor that describes how quickly
///           the signal attenuates with distance.
///           • Free space: ~2.0
///           • Typical indoor gallery: 2.2–2.8
///           • Dense/cluttered areas: 3.0–3.5
///           You may override this with a live-updating number if you
///           are training on accumulated data.
///   - maxDistance: A sanity cap (meters). Prevents insane values
///           when RSSI is very weak or noisy. Example: 30.0 m.
///           Default = 30.0.
///   - beaconHeight: Optional. The physical height of the beacon (m).
///   - userHeight: Optional. The estimated height of the device (m),
///           usually ~1.2–1.5 m if handheld.
///           If both heights are provided, the function will compute
///           a **horizontal distance** corrected for vertical offset.
///
/// - Returns: The estimated distance (meters) as a Float.
///            Will always be >= 0 and <= maxDistance.
/// 
/// 
/*

Example usage:

let rssi: Float = -70.0

let d = rssiToDistance(
    rssi: rssi,
    txPowerAt1m: -59.0,       // calibration constant
    pathLossExponent: 2.4,    // typical indoor gallery
    maxDistance: 25.0,
    beaconHeight: 2.5,
    userHeight: 1.3
)

print("Estimated distance = \(d) meters")
// Output ≈ 2.7 m (depending on inputs)
*/



func rssiToDistance(
    rssi: Float,
    txPowerAt1m: Float,
    pathLossExponent n: Float,
    maxDistance: Float = 30.0,
    beaconHeight: Float? = nil,
    userHeight: Float? = nil
) -> Float {
    
    // Core path-loss formula:
    // exponent = (TxPower@1m - RSSI) / (10 * n)
    // distance = 10 ^ exponent
    let exponent = (txPowerAt1m - rssi) / (10.0 * n)
    var distance = pow(10.0, exponent)
    
    // Optional: correct for vertical offset between beacon and user device.
    if let bz = beaconHeight, let uz = userHeight {
        let vertical = fabsf(bz - uz)    // absolute vertical difference in meters
        // Ensure the total distance is at least as large as vertical
        distance = sqrt(max(distance * distance - vertical * vertical, 0.0))
    }
    
    // Clamp to maximum distance (safety guard against noise).
    if distance > maxDistance {
        distance = maxDistance
    }
    
    // Final distance estimate (meters).
    return distance
}
