import Foundation

/// A 2-component floating-point vector used throughout SwiftGameKit.
public struct Vector2: Equatable, Hashable, Codable, Sendable, CustomStringConvertible {
    public var x: Float
    public var y: Float

    public init(_ x: Float, _ y: Float) {
        self.x = x
        self.y = y
    }

    public init(x: Float, y: Float) {
        self.x = x
        self.y = y
    }

    public init(_ value: Float) {
        self.x = value
        self.y = value
    }

    public init(_ simd: Float2) {
        self.x = simd.x
        self.y = simd.y
    }

    public var simd: Float2 {
        Float2(x, y)
    }

    // MARK: - Constants

    public static let zero = Vector2(0, 0)
    public static let one = Vector2(1, 1)
    public static let unitX = Vector2(1, 0)
    public static let unitY = Vector2(0, 1)
    public static let up = Vector2(0, 1)
    public static let down = Vector2(0, -1)
    public static let left = Vector2(-1, 0)
    public static let right = Vector2(1, 0)

    // MARK: - Properties

    public var lengthSquared: Float {
        x * x + y * y
    }

    public var length: Float {
        sqrt(lengthSquared)
    }

    public var normalized: Vector2 {
        let len = length
        guard len > .ulpOfOne else { return .zero }
        return Vector2(x / len, y / len)
    }

    public var isNearlyZero: Bool {
        lengthSquared < Float.ulpOfOne * Float.ulpOfOne
    }

    public var description: String {
        String(format: "Vector2(%.4f, %.4f)", x, y)
    }

    // MARK: - Operators

    public static func + (lhs: Vector2, rhs: Vector2) -> Vector2 {
        Vector2(lhs.x + rhs.x, lhs.y + rhs.y)
    }

    public static func - (lhs: Vector2, rhs: Vector2) -> Vector2 {
        Vector2(lhs.x - rhs.x, lhs.y - rhs.y)
    }

    public static func * (lhs: Vector2, rhs: Float) -> Vector2 {
        Vector2(lhs.x * rhs, lhs.y * rhs)
    }

    public static func * (lhs: Float, rhs: Vector2) -> Vector2 {
        Vector2(lhs * rhs.x, lhs * rhs.y)
    }

    public static func * (lhs: Vector2, rhs: Vector2) -> Vector2 {
        Vector2(lhs.x * rhs.x, lhs.y * rhs.y)
    }

    public static func / (lhs: Vector2, rhs: Float) -> Vector2 {
        Vector2(lhs.x / rhs, lhs.y / rhs)
    }

    public static func / (lhs: Vector2, rhs: Vector2) -> Vector2 {
        Vector2(lhs.x / rhs.x, lhs.y / rhs.y)
    }

    public static prefix func - (v: Vector2) -> Vector2 {
        Vector2(-v.x, -v.y)
    }

    public static func += (lhs: inout Vector2, rhs: Vector2) {
        lhs.x += rhs.x
        lhs.y += rhs.y
    }

    public static func -= (lhs: inout Vector2, rhs: Vector2) {
        lhs.x -= rhs.x
        lhs.y -= rhs.y
    }

    public static func *= (lhs: inout Vector2, rhs: Float) {
        lhs.x *= rhs
        lhs.y *= rhs
    }

    public static func /= (lhs: inout Vector2, rhs: Float) {
        lhs.x /= rhs
        lhs.y /= rhs
    }

    // MARK: - Methods

    public mutating func normalize() {
        let len = length
        guard len > .ulpOfOne else {
            x = 0
            y = 0
            return
        }
        x /= len
        y /= len
    }

    public func dot(_ other: Vector2) -> Float {
        x * other.x + y * other.y
    }

    public func cross(_ other: Vector2) -> Float {
        x * other.y - y * other.x
    }

    public func distance(to other: Vector2) -> Float {
        (self - other).length
    }

    public func distanceSquared(to other: Vector2) -> Float {
        (self - other).lengthSquared
    }

    public func lerp(to other: Vector2, t: Float) -> Vector2 {
        Vector2(
            x + (other.x - x) * t,
            y + (other.y - y) * t
        )
    }

    public func clamped(min: Vector2, max: Vector2) -> Vector2 {
        Vector2(
            Swift.min(Swift.max(x, min.x), max.x),
            Swift.min(Swift.max(y, min.y), max.y)
        )
    }

    public func clamped(to range: ClosedRange<Float>) -> Vector2 {
        Vector2(
            Swift.min(Swift.max(x, range.lowerBound), range.upperBound),
            Swift.min(Swift.max(y, range.lowerBound), range.upperBound)
        )
    }

    public func rotated(by angle: Float) -> Vector2 {
        let c = cos(angle)
        let s = sin(angle)
        return Vector2(x * c - y * s, x * s + y * c)
    }

    public func angle(to other: Vector2) -> Float {
        let d = dot(other)
        let lengths = length * other.length
        guard lengths > .ulpOfOne else { return 0 }
        return acos(Swift.min(Swift.max(d / lengths, -1), 1))
    }

    public func project(onto other: Vector2) -> Vector2 {
        let lenSq = other.lengthSquared
        guard lenSq > .ulpOfOne else { return .zero }
        let scale = dot(other) / lenSq
        return other * scale
    }

    public func reflect(normal: Vector2) -> Vector2 {
        let n = normal.normalized
        return self - 2 * dot(n) * n
    }

    public func perpendicular() -> Vector2 {
        Vector2(-y, x)
    }

    public func abs() -> Vector2 {
        Vector2(Swift.abs(x), Swift.abs(y))
    }

    public func min(_ other: Vector2) -> Vector2 {
        Vector2(Swift.min(x, other.x), Swift.min(y, other.y))
    }

    public func max(_ other: Vector2) -> Vector2 {
        Vector2(Swift.max(x, other.x), Swift.max(y, other.y))
    }
}

// MARK: - Comparable Helpers

extension Vector2 {
    public static func approximatelyEqual(_ a: Vector2, _ b: Vector2, epsilon: Float = 1e-5) -> Bool {
        Swift.abs(a.x - b.x) < epsilon && Swift.abs(a.y - b.y) < epsilon
    }
}
