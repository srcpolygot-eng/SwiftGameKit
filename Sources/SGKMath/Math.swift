import Foundation

public enum Math {
    public static let pi: Float = .pi
    public static let twoPi: Float = .pi * 2
    public static let halfPi: Float = .pi * 0.5
    public static let degToRad: Float = .pi / 180
    public static let radToDeg: Float = 180 / .pi

    public static func degrees(_ radians: Float) -> Float {
        radians * radToDeg
    }

    public static func radians(_ degrees: Float) -> Float {
        degrees * degToRad
    }

    public static func clamp<T: Comparable>(_ value: T, min: T, max: T) -> T {
        Swift.min(Swift.max(value, min), max)
    }

    public static func lerp(_ a: Float, _ b: Float, t: Float) -> Float {
        a + (b - a) * t
    }

    public static func inverseLerp(_ a: Float, _ b: Float, value: Float) -> Float {
        guard abs(b - a) > .ulpOfOne else { return 0 }
        return (value - a) / (b - a)
    }

    public static func smoothstep(_ edge0: Float, _ edge1: Float, _ x: Float) -> Float {
        let t = clamp((x - edge0) / (edge1 - edge0), min: 0, max: 1)
        return t * t * (3 - 2 * t)
    }

    public static func remap(_ value: Float, from: ClosedRange<Float>, to: ClosedRange<Float>) -> Float {
        let t = inverseLerp(from.lowerBound, from.upperBound, value: value)
        return lerp(to.lowerBound, to.upperBound, t: t)
    }

    public static func approximatelyEqual(_ a: Float, _ b: Float, epsilon: Float = 1e-5) -> Bool {
        abs(a - b) < epsilon
    }

    public static func sign(_ v: Float) -> Float {
        v >= 0 ? 1 : -1
    }

    public static func fract(_ v: Float) -> Float {
        v - floor(v)
    }

    public static func wrap(_ value: Float, min: Float, max: Float) -> Float {
        let range = max - min
        guard range > .ulpOfOne else { return min }
        var v = value - min
        v = v - floor(v / range) * range
        return v + min
    }

    public static func angleDifference(_ a: Float, _ b: Float) -> Float {
        var diff = b - a
        while diff > .pi { diff -= twoPi }
        while diff < -.pi { diff += twoPi }
        return diff
    }

    public static func moveTowards(_ current: Float, _ target: Float, maxDelta: Float) -> Float {
        let delta = target - current
        if abs(delta) <= maxDelta { return target }
        return current + sign(delta) * maxDelta
    }

    public static func moveTowards(_ current: Vector2, _ target: Vector2, maxDelta: Float) -> Vector2 {
        let delta = target - current
        let dist = delta.length
        if dist <= maxDelta || dist < .ulpOfOne { return target }
        return current + delta * (maxDelta / dist)
    }

    public static func moveTowards(_ current: Vector3, _ target: Vector3, maxDelta: Float) -> Vector3 {
        let delta = target - current
        let dist = delta.length
        if dist <= maxDelta || dist < .ulpOfOne { return target }
        return current + delta * (maxDelta / dist)
    }
}

// MARK: - Easing

public enum Easing: Sendable {
    case linear
    case easeIn
    case easeOut
    case easeInOut
    case easeInQuad
    case easeOutQuad
    case easeInOutQuad
    case easeInCubic
    case easeOutCubic
    case easeInOutCubic
    case easeInQuart
    case easeOutQuart
    case easeInOutQuart
    case easeInExpo
    case easeOutExpo
    case easeInOutExpo
    case easeInBack
    case easeOutBack
    case easeInOutBack
    case easeInElastic
    case easeOutElastic
    case easeInOutElastic
    case easeInBounce
    case easeOutBounce
    case easeInOutBounce
    case custom(@Sendable (Float) -> Float)

    public func evaluate(_ t: Float) -> Float {
        let t = Math.clamp(t, min: 0, max: 1)
        switch self {
        case .linear:
            return t
        case .easeIn, .easeInQuad:
            return t * t
        case .easeOut, .easeOutQuad:
            return t * (2 - t)
        case .easeInOut, .easeInOutQuad:
            return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t
        case .easeInCubic:
            return t * t * t
        case .easeOutCubic:
            let u = t - 1
            return u * u * u + 1
        case .easeInOutCubic:
            return t < 0.5 ? 4 * t * t * t : (t - 1) * (2 * t - 2) * (2 * t - 2) + 1
        case .easeInQuart:
            return t * t * t * t
        case .easeOutQuart:
            let u = t - 1
            return 1 - u * u * u * u
        case .easeInOutQuart:
            return t < 0.5 ? 8 * t * t * t * t : 1 - 8 * (t - 1) * (t - 1) * (t - 1) * (t - 1)
        case .easeInExpo:
            return t == 0 ? 0 : pow(2, 10 * (t - 1))
        case .easeOutExpo:
            return t == 1 ? 1 : 1 - pow(2, -10 * t)
        case .easeInOutExpo:
            if t == 0 { return 0 }
            if t == 1 { return 1 }
            return t < 0.5
                ? 0.5 * pow(2, 20 * t - 10)
                : 1 - 0.5 * pow(2, -20 * t + 10)
        case .easeInBack:
            let c1: Float = 1.70158
            return (c1 + 1) * t * t * t - c1 * t * t
        case .easeOutBack:
            let c1: Float = 1.70158
            let u = t - 1
            return 1 + (c1 + 1) * u * u * u + c1 * u * u
        case .easeInOutBack:
            let c1: Float = 1.70158
            let c2 = c1 * 1.525
            if t < 0.5 {
                return 0.5 * ((2 * t) * (2 * t) * ((c2 + 1) * 2 * t - c2))
            } else {
                let u = 2 * t - 2
                return 0.5 * (u * u * ((c2 + 1) * u + c2) + 2)
            }
        case .easeInElastic:
            if t == 0 || t == 1 { return t }
            return -pow(2, 10 * t - 10) * sin((t * 10 - 10.75) * (2 * .pi) / 3)
        case .easeOutElastic:
            if t == 0 || t == 1 { return t }
            return pow(2, -10 * t) * sin((t * 10 - 0.75) * (2 * .pi) / 3) + 1
        case .easeInOutElastic:
            if t == 0 || t == 1 { return t }
            if t < 0.5 {
                return -0.5 * pow(2, 20 * t - 10) * sin((20 * t - 11.125) * (2 * .pi) / 4.5)
            } else {
                return 0.5 * pow(2, -20 * t + 10) * sin((20 * t - 11.125) * (2 * .pi) / 4.5) + 1
            }
        case .easeInBounce:
            return 1 - Easing.easeOutBounce.evaluate(1 - t)
        case .easeOutBounce:
            if t < 1 / 2.75 {
                return 7.5625 * t * t
            } else if t < 2 / 2.75 {
                let u = t - 1.5 / 2.75
                return 7.5625 * u * u + 0.75
            } else if t < 2.5 / 2.75 {
                let u = t - 2.25 / 2.75
                return 7.5625 * u * u + 0.9375
            } else {
                let u = t - 2.625 / 2.75
                return 7.5625 * u * u + 0.984375
            }
        case .easeInOutBounce:
            return t < 0.5
                ? 0.5 * Easing.easeInBounce.evaluate(t * 2)
                : 0.5 * Easing.easeOutBounce.evaluate(t * 2 - 1) + 0.5
        case .custom(let f):
            return f(t)
        }
    }
}

// MARK: - Curves

public struct BezierCurve {
    public var p0: Vector2
    public var p1: Vector2
    public var p2: Vector2
    public var p3: Vector2

    public init(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2) {
        self.p0 = p0; self.p1 = p1; self.p2 = p2; self.p3 = p3
    }

    public func evaluate(_ t: Float) -> Vector2 {
        let u = 1 - t
        let tt = t * t
        let uu = u * u
        let uuu = uu * u
        let ttt = tt * t
        return p0 * uuu + p1 * (3 * uu * t) + p2 * (3 * u * tt) + p3 * ttt
    }
}

public struct CatmullRomSpline {
    public var points: [Vector2]

    public init(points: [Vector2]) {
        self.points = points
    }

    public func evaluate(_ t: Float) -> Vector2 {
        guard points.count >= 2 else { return points.first ?? .zero }
        let n = points.count - 1
        let ft = t * Float(n)
        let i = Int(floor(ft))
        let localT = ft - Float(i)
        let i0 = max(i - 1, 0)
        let i1 = min(i, n)
        let i2 = min(i + 1, n)
        let i3 = min(i + 2, n)
        return catmullRom(points[i0], points[i1], points[i2], points[i3], t: localT)
    }

    private func catmullRom(_ p0: Vector2, _ p1: Vector2, _ p2: Vector2, _ p3: Vector2, t: Float) -> Vector2 {
        let t2 = t * t
        let t3 = t2 * t
        return 0.5 * (
            (2 * p1) +
            (-p0 + p2) * t +
            (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 +
            (-p0 + 3 * p1 - 3 * p2 + p3) * t3
        )
    }
}
