import CoreGraphics

enum DistanceKit {
    @inline(__always)
    static func planarPx(from a: CGPoint, to b: CGPoint) -> Double {
        let dx = Double(b.x - a.x), dy = Double(b.y - a.y)
        return hypot(dx, dy)
    }
    @inline(__always)
    static func planarM(fromPx a: CGPoint, toPx b: CGPoint, ppm: Double) -> Double {
        planarPx(from: a, to: b) / max(ppm, 0.0001)
    }
    @inline(__always)
    static func xyzPx(planar_px: Double, dz_m: Double, ppm: Double) -> Double {
        let dz_px = dz_m * ppm
        return hypot(planar_px, dz_px)
    }
    @inline(__always)
    static func xyzM(planar_m: Double, dz_m: Double) -> Double {
        hypot(planar_m, dz_m)
    }
}
