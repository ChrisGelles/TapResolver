//
//  CompassOrientationManager.swift
//  TapResolver
//
//  Created by Chris Gelles on 9/30/25.
//

import Foundation
import CoreLocation
import CoreMotion
import Combine
import simd

/// High-level quality signal for downstream consumers.
public enum HeadingQuality: String {
    case excellent, good, fair, poor, unavailable
}

/// A modular sensor-fusion manager for compass/orientation.
/// - Combines CoreLocation heading (true & magnetic) with CoreMotion deviceMotion yaw (xTrueNorthZVertical when possible).
/// - Exposes stable, low-latency fused heading + pitch/roll for HUD/overlays.
/// - Start/stop on demand; no UI dependencies.
public final class CompassOrientationManager: NSObject, ObservableObject {

    // MARK: - Published outputs (subscribe in UI or other modules)
    @Published public private(set) var fusedHeadingDegrees: Double = .nan        // 0...360 (true north)
    @Published public private(set) var trueHeadingDegrees: Double?               // from CLHeading (0...360)
    @Published public private(set) var magneticHeadingDegrees: Double?           // from CLHeading (0...360)
    @Published public private(set) var headingAccuracyDegrees: Double?           // lower is better
    @Published public private(set) var yawDegrees: Double = .nan                 // from deviceMotion (0...360, true-north frame)
    @Published public private(set) var pitchDegrees: Double = .nan               // -180...180
    @Published public private(set) var rollDegrees: Double = .nan                // -180...180
    @Published public private(set) var isActive: Bool = false
    @Published public private(set) var quality: HeadingQuality = .unavailable
    @Published public private(set) var lastUpdate: Date?

    // MARK: - Config
    /// Complementary filter mixing: higher favors motion yaw (smooth/low-latency), lower favors CLHeading (absolute/slow).
    public var motionBlend: Double = 0.85          // 0.0...1.0
    /// Minimum expected update rate for motion (Hz). Used to adapt smoothing (not a hard guarantee).
    public var expectedMotionHz: Double = 60.0
    /// Accuracy gates (deg)
    public var excellentAcc: Double = 5.0
    public var goodAcc: Double = 10.0
    public var fairAcc: Double = 20.0

    // MARK: - Internals
    private let location = CLLocationManager()
    private let motion = CMMotionManager()
    private let queue = OperationQueue()
    private var cancellables = Set<AnyCancellable>()

    // Filter state
    private var lastFusedRad: Double?
    private var lastTimestamp: CFTimeInterval?
    private var useTrueNorthReference: Bool = true

    // Lifecycle
    public override init() {
        super.init()
        queue.name = "CompassOrientationManager.motion"
        queue.qualityOfService = .userInteractive

        location.delegate = self
        location.headingFilter = kCLHeadingFilterNone // push all updates
        // Choose true-north reference if available (CoreMotion will try to align using magnetometer & location)
        useTrueNorthReference = true
    }

    deinit { stop() }

    // MARK: - Public control
    public func start() {
        guard !isActive else { return }
        isActive = true
        lastFusedRad = nil
        lastTimestamp = nil

        // 1) Location (for heading & to help CM align to true north)
        if CLLocationManager.headingAvailable() {
            if location.authorizationStatus == .notDetermined {
                location.requestWhenInUseAuthorization()
            }
            location.startUpdatingHeading()
        }

        // 2) CoreMotion deviceMotion in a north-aligned frame if possible
        let refFrame: CMAttitudeReferenceFrame = useTrueNorthReference
            ? .xTrueNorthZVertical
            : .xArbitraryCorrectedZVertical

        if CMMotionManager.availableAttitudeReferenceFrames().contains(refFrame) {
            motion.showsDeviceMovementDisplay = false
            motion.deviceMotionUpdateInterval = 1.0 / expectedMotionHz
            motion.startDeviceMotionUpdates(using: refFrame, to: queue) { [weak self] dm, _ in
                guard let self, let dm else { return }
                self.handleDeviceMotion(dm)
            }
        } else {
            // Fallback to gyro-only reference if needed
            motion.deviceMotionUpdateInterval = 1.0 / expectedMotionHz
            motion.startDeviceMotionUpdates(to: queue) { [weak self] dm, _ in
                guard let self, let dm else { return }
                self.handleDeviceMotion(dm)
            }
        }
    }

    public func stop() {
        guard isActive else { return }
        isActive = false
        location.stopUpdatingHeading()
        motion.stopDeviceMotionUpdates()
        lastFusedRad = nil
        lastTimestamp = nil
        quality = .unavailable
    }

    /// Reset internal filter (e.g., after big jumps or manual recenter).
    public func resetFilter() {
        lastFusedRad = nil
        lastTimestamp = nil
    }

    // MARK: - Private handlers

    private func handleDeviceMotion(_ dm: CMDeviceMotion) {
        // Attitude in chosen reference frame; yaw around Z (z-vertical)
        // Note: for xTrueNorthZVertical, yaw=0 means facing true north.
        let yawRad = normalizeAngle(dm.attitude.yaw) // radians
        let pitchRad = dm.attitude.pitch
        let rollRad = dm.attitude.roll

        let yawDeg = radiansToDegrees(yawRad)
        let pitchDeg = radiansToDegrees(pitchRad)
        let rollDeg = radiansToDegrees(rollRad)

        // Update motion-facing values on main thread
        DispatchQueue.main.async {
            self.yawDegrees = wrapDegrees(yawDeg)
            self.pitchDegrees = wrapSignedDegrees(pitchDeg)
            self.rollDegrees = wrapSignedDegrees(rollDeg)
            self.lastUpdate = Date()

            // Run complementary fusion with latest CLHeading if quality is decent
            let headingDeg = (self.trueHeadingDegrees ?? self.magneticHeadingDegrees)
            let headingRad = headingDeg.map { degreesToRadians($0) }

            let fusedRad: Double
            if let headingRad, let acc = self.headingAccuracyDegrees, acc.isFinite {
                // Weight motion more, but pull toward CLHeading when accuracy is reasonable
                let alpha = self.alphaForAccuracy(acc, fallback: self.motionBlend)
                fusedRad = self.mixAngles(self.lastFusedRad ?? yawRad, yawRad, headingRad, alpha: alpha)
                self.quality = self.qualityForAccuracy(acc)
            } else {
                // No reliable CLHeading; use motion yaw directly
                fusedRad = yawRad
                self.quality = .fair
            }

            self.lastFusedRad = fusedRad
            self.fusedHeadingDegrees = wrapDegrees(radiansToDegrees(fusedRad))
        }
    }

    private func alphaForAccuracy(_ acc: Double, fallback: Double) -> Double {
        // Smaller accuracy => more trust in heading => slightly less motionBlend
        // Clamp in [0.6, 0.95] to avoid instability.
        let t: Double
        switch acc {
        case ..<excellentAcc: t = 0.75
        case ..<goodAcc:      t = 0.80
        case ..<fairAcc:      t = 0.85
        default:              t = fallback
        }
        return min(0.95, max(0.60, t))
    }

    private func qualityForAccuracy(_ acc: Double) -> HeadingQuality {
        switch acc {
        case ..<excellentAcc: return .excellent
        case ..<goodAcc:      return .good
        case ..<fairAcc:      return .fair
        default:              return .poor
        }
    }

    // Mix current motion yaw toward absolute heading using a complementary approach
    private func mixAngles(_ prev: Double, _ motionYaw: Double, _ absolute: Double, alpha: Double) -> Double {
        // Interpolate on the circle to avoid wrap artifacts
        let motion = motionYaw
        let target = closestAngle(on: motion, to: absolute)
        let blended = motion + (1 - alpha) * shortestDelta(from: motion, to: target)
        // Bias toward previous fused to add temporal smoothing
        let prevTarget = closestAngle(on: blended, to: prev)
        let smoothed = prev.isFinite ? (0.9 * blended + 0.1 * prevTarget) : blended
        return normalizeAngle(smoothed)
    }
}

// MARK: - CLLocationManagerDelegate
extension CompassOrientationManager: CLLocationManagerDelegate {

    public func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        // Allow system calibration view when accuracy is poor
        if let acc = headingAccuracyDegrees, acc > fairAcc { return true }
        return false
    }

    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // If just authorized and we're active, (re)start heading updates
        if isActive, CLLocationManager.headingAvailable() {
            manager.startUpdatingHeading()
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // Use trueHeading when valid; fallback to magneticHeading
        let acc = newHeading.headingAccuracy
        let trueH = newHeading.trueHeading >= 0 ? newHeading.trueHeading : nil
        let magH  = newHeading.magneticHeading

        DispatchQueue.main.async {
            self.trueHeadingDegrees = trueH
            self.magneticHeadingDegrees = magH
            self.headingAccuracyDegrees = acc.isFinite ? acc : nil
            self.lastUpdate = Date()
        }
    }
}

// MARK: - Angle helpers
@inline(__always) private func degreesToRadians(_ deg: Double) -> Double { deg * .pi / 180.0 }
@inline(__always) private func radiansToDegrees(_ rad: Double) -> Double { rad * 180.0 / .pi }

@inline(__always) private func normalizeAngle(_ rad: Double) -> Double {
    var x = rad
    let twoPi = 2.0 * .pi
    x.formTruncatingRemainder(dividingBy: twoPi)
    if x < 0 { x += twoPi }
    return x
}

@inline(__always) private func shortestDelta(from a: Double, to b: Double) -> Double {
    var d = b - a
    let twoPi = 2.0 * .pi
    if d > .pi { d -= twoPi }
    if d < -.pi { d += twoPi }
    return d
}

@inline(__always) private func closestAngle(on anchor: Double, to target: Double) -> Double {
    anchor + shortestDelta(from: anchor, to: target)
}

@inline(__always) private func wrapDegrees(_ deg: Double) -> Double {
    let x = fmod(deg, 360.0)
    return x < 0 ? x + 360.0 : x
}

@inline(__always) private func wrapSignedDegrees(_ deg: Double) -> Double {
    var x = fmod(deg + 180.0, 360.0)
    if x < 0 { x += 360.0 }
    return x - 180.0
}


