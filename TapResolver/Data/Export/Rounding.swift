import CoreGraphics

enum Rounding {
    @inline(__always)
    static func d(_ x: Double, _ places: Int = 2) -> Double {
        let p = pow(10.0, Double(places))
        return (x * p).rounded(.toNearestOrAwayFromZero) / p
    }
    @inline(__always)
    static func arr2(_ x: Double, _ y: Double, _ places: Int = 2) -> [Double] {
        [d(x, places), d(y, places)]
    }
    @inline(__always)
    static func arr2(_ p: CGPoint, _ places: Int = 2) -> [Double] {
        [d(Double(p.x), places), d(Double(p.y), places)]
    }
}

