import Foundation

public struct Vector4: Equatable, Hashable, Codable, Sendable, CustomStringConvertible {
    public var x: Float
    public var y: Float
    public var z: Float
    public var w: Float

    public init(_ x: Float, _ y: Float, _ z: Float, _ w: Float) {
        self.x = x; self.y = y; self.z = z; self.w = w
    }

    public init(x: Float, y: Float, z: Float, w: Float) {
        self.x = x; self.y = y; self.z = z; self.w = w
    }

    public init(_ v3: Vector3, w: Float = 1) {
        self.x = v3.x; self.y = v3.y; self.z = v3.z; self.w = w
    }

    public init(_ simd: Float4) {
        self.x = simd.x; self.y = simd.y; self.z = simd.z; self.w = simd.w
    }

    public var simd: Float4 { Float4(x, y, z, w) }
    public var xyz: Vector3 {
        get { Vector3(x, y, z) }
        set { x = newValue.x; y = newValue.y; z = newValue.z }
    }

    public static let zero = Vector4(0, 0, 0, 0)
    public static let one = Vector4(1, 1, 1, 1)

    public var lengthSquared: Float { x*x + y*y + z*z + w*w }
    public var length: Float { sqrt(lengthSquared) }

    public var normalized: Vector4 {
        let len = length
        guard len > .ulpOfOne else { return .zero }
        return Vector4(x/len, y/len, z/len, w/len)
    }

    public var description: String {
        String(format: "Vector4(%.4f, %.4f, %.4f, %.4f)", x, y, z, w)
    }

    public static func + (lhs: Vector4, rhs: Vector4) -> Vector4 {
        Vector4(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z, lhs.w + rhs.w)
    }

    public static func - (lhs: Vector4, rhs: Vector4) -> Vector4 {
        Vector4(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z, lhs.w - rhs.w)
    }

    public static func * (lhs: Vector4, rhs: Float) -> Vector4 {
        Vector4(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs, lhs.w * rhs)
    }

    public static func * (lhs: Float, rhs: Vector4) -> Vector4 {
        Vector4(lhs * rhs.x, lhs * rhs.y, lhs * rhs.z, lhs * rhs.w)
    }

    public static prefix func - (v: Vector4) -> Vector4 {
        Vector4(-v.x, -v.y, -v.z, -v.w)
    }

    public func dot(_ other: Vector4) -> Float {
        x * other.x + y * other.y + z * other.z + w * other.w
    }

    public func lerp(to other: Vector4, t: Float) -> Vector4 {
        Vector4(
            x + (other.x - x) * t,
            y + (other.y - y) * t,
            z + (other.z - z) * t,
            w + (other.w - w) * t
        )
    }
}
