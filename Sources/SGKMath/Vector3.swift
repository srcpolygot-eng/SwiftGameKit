import Foundation

/// A 3-component floating-point vector.
public struct Vector3: Equatable, Hashable, Codable, Sendable, CustomStringConvertible {
    public var x: Float
    public var y: Float
    public var z: Float

    public init(_ x: Float, _ y: Float, _ z: Float) {
        self.x = x
        self.y = y
        self.z = z
    }

    public init(x: Float, y: Float, z: Float) {
        self.x = x
        self.y = y
        self.z = z
    }

    public init(_ value: Float) {
        self.x = value
        self.y = value
        self.z = value
    }

    public init(_ v2: Vector2, z: Float = 0) {
        self.x = v2.x
        self.y = v2.y
        self.z = z
    }

    public init(_ simd: Float3) {
        self.x = simd.x
        self.y = simd.y
        self.z = simd.z
    }

    public var simd: Float3 {
        Float3(x, y, z)
    }

    public var xy: Vector2 {
        get { Vector2(x, y) }
        set { x = newValue.x; y = newValue.y }
    }

    // MARK: - Constants

    public static let zero = Vector3(0, 0, 0)
    public static let one = Vector3(1, 1, 1)
    public static let unitX = Vector3(1, 0, 0)
    public static let unitY = Vector3(0, 1, 0)
    public static let unitZ = Vector3(0, 0, 1)
    public static let up = Vector3(0, 1, 0)
    public static let down = Vector3(0, -1, 0)
    public static let left = Vector3(-1, 0, 0)
    public static let right = Vector3(1, 0, 0)
    public static let forward = Vector3(0, 0, -1)
    public static let back = Vector3(0, 0, 1)

    // MARK: - Properties

    public var lengthSquared: Float {
        x * x + y * y + z * z
    }

    public var length: Float {
        sqrt(lengthSquared)
    }

    public var normalized: Vector3 {
        let len = length
        guard len > .ulpOfOne else { return .zero }
        return Vector3(x / len, y / len, z / len)
    }

    public var isNearlyZero: Bool {
        lengthSquared < Float.ulpOfOne * Float.ulpOfOne
    }

    public var description: String {
        String(format: "Vector3(%.4f, %.4f, %.4f)", x, y, z)
    }

    // MARK: - Operators

    public static func + (lhs: Vector3, rhs: Vector3) -> Vector3 {
        Vector3(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z)
    }

    public static func - (lhs: Vector3, rhs: Vector3) -> Vector3 {
        Vector3(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z)
    }

    public static func * (lhs: Vector3, rhs: Float) -> Vector3 {
        Vector3(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs)
    }

    public static func * (lhs: Float, rhs: Vector3) -> Vector3 {
        Vector3(lhs * rhs.x, lhs * rhs.y, lhs * rhs.z)
    }

    public static func * (lhs: Vector3, rhs: Vector3) -> Vector3 {
        Vector3(lhs.x * rhs.x, lhs.y * rhs.y, lhs.z * rhs.z)
    }

    public static func / (lhs: Vector3, rhs: Float) -> Vector3 {
        Vector3(lhs.x / rhs, lhs.y / rhs, lhs.z / rhs)
    }

    public static prefix func - (v: Vector3) -> Vector3 {
        Vector3(-v.x, -v.y, -v.z)
    }

    public static func += (lhs: inout Vector3, rhs: Vector3) {
        lhs.x += rhs.x; lhs.y += rhs.y; lhs.z += rhs.z
    }

    public static func -= (lhs: inout Vector3, rhs: Vector3) {
        lhs.x -= rhs.x; lhs.y -= rhs.y; lhs.z -= rhs.z
    }

    public static func *= (lhs: inout Vector3, rhs: Float) {
        lhs.x *= rhs; lhs.y *= rhs; lhs.z *= rhs
    }

    // MARK: - Methods

    public mutating func normalize() {
        let len = length
        guard len > .ulpOfOne else {
            x = 0; y = 0; z = 0
            return
        }
        x /= len; y /= len; z /= len
    }

    public func dot(_ other: Vector3) -> Float {
        x * other.x + y * other.y + z * other.z
    }

    public func cross(_ other: Vector3) -> Vector3 {
        Vector3(
            y * other.z - z * other.y,
            z * other.x - x * other.z,
            x * other.y - y * other.x
        )
    }

    public func distance(to other: Vector3) -> Float {
        (self - other).length
    }

    public func distanceSquared(to other: Vector3) -> Float {
        (self - other).lengthSquared
    }

    public func lerp(to other: Vector3, t: Float) -> Vector3 {
        Vector3(
            x + (other.x - x) * t,
            y + (other.y - y) * t,
            z + (other.z - z) * t
        )
    }

    public func clamped(min: Vector3, max: Vector3) -> Vector3 {
        Vector3(
            Swift.min(Swift.max(x, min.x), max.x),
            Swift.min(Swift.max(y, min.y), max.y),
            Swift.min(Swift.max(z, min.z), max.z)
        )
    }

    public func project(onto other: Vector3) -> Vector3 {
        let lenSq = other.lengthSquared
        guard lenSq > .ulpOfOne else { return .zero }
        return other * (dot(other) / lenSq)
    }

    public func reflect(normal: Vector3) -> Vector3 {
        let n = normal.normalized
        return self - 2 * dot(n) * n
    }

    public func abs() -> Vector3 {
        Vector3(Swift.abs(x), Swift.abs(y), Swift.abs(z))
    }

    public static func approximatelyEqual(_ a: Vector3, _ b: Vector3, epsilon: Float = 1e-5) -> Bool {
        Swift.abs(a.x - b.x) < epsilon && Swift.abs(a.y - b.y) < epsilon && Swift.abs(a.z - b.z) < epsilon
    }
}
