import Foundation

/// Unit quaternion representing 3D rotations.
public struct Quaternion: Equatable, Hashable, Codable, Sendable, CustomStringConvertible {
    public var x: Float
    public var y: Float
    public var z: Float
    public var w: Float

    public init(x: Float, y: Float, z: Float, w: Float) {
        self.x = x; self.y = y; self.z = z; self.w = w
    }

    public init(_ x: Float, _ y: Float, _ z: Float, _ w: Float) {
        self.x = x; self.y = y; self.z = z; self.w = w
    }

    public static let identity = Quaternion(0, 0, 0, 1)

    public var lengthSquared: Float { x*x + y*y + z*z + w*w }
    public var length: Float { sqrt(lengthSquared) }

    public var normalized: Quaternion {
        let len = length
        guard len > .ulpOfOne else { return .identity }
        return Quaternion(x/len, y/len, z/len, w/len)
    }

    public var conjugate: Quaternion {
        Quaternion(-x, -y, -z, w)
    }

    public var inverse: Quaternion {
        let lenSq = lengthSquared
        guard lenSq > .ulpOfOne else { return .identity }
        let inv = 1.0 / lenSq
        return Quaternion(-x * inv, -y * inv, -z * inv, w * inv)
    }

    public var description: String {
        String(format: "Quaternion(%.4f, %.4f, %.4f, %.4f)", x, y, z, w)
    }

    /// Create from axis-angle (axis should be normalized, angle in radians).
    public static func fromAxisAngle(axis: Vector3, angle: Float) -> Quaternion {
        let half = angle * 0.5
        let s = sin(half)
        let c = cos(half)
        let n = axis.normalized
        return Quaternion(n.x * s, n.y * s, n.z * s, c)
    }

    /// Create from Euler angles (yaw, pitch, roll) in radians. Order: YXZ.
    public static func fromEuler(yaw: Float, pitch: Float, roll: Float) -> Quaternion {
        let cy = cos(yaw * 0.5)
        let sy = sin(yaw * 0.5)
        let cp = cos(pitch * 0.5)
        let sp = sin(pitch * 0.5)
        let cr = cos(roll * 0.5)
        let sr = sin(roll * 0.5)

        return Quaternion(
            sr * cp * cy - cr * sp * sy,
            cr * sp * cy + sr * cp * sy,
            cr * cp * sy - sr * sp * cy,
            cr * cp * cy + sr * sp * sy
        )
    }

    public func toEuler() -> (yaw: Float, pitch: Float, roll: Float) {
        // Roll (x-axis)
        let sinr_cosp = 2 * (w * x + y * z)
        let cosr_cosp = 1 - 2 * (x * x + y * y)
        let roll = atan2(sinr_cosp, cosr_cosp)

        // Pitch (y-axis)
        let sinp = 2 * (w * y - z * x)
        let pitch: Float
        if abs(sinp) >= 1 {
            pitch = copysign(.pi / 2, sinp)
        } else {
            pitch = asin(sinp)
        }

        // Yaw (z-axis)
        let siny_cosp = 2 * (w * z + x * y)
        let cosy_cosp = 1 - 2 * (y * y + z * z)
        let yaw = atan2(siny_cosp, cosy_cosp)

        return (yaw, pitch, roll)
    }

    public static func * (lhs: Quaternion, rhs: Quaternion) -> Quaternion {
        Quaternion(
            lhs.w * rhs.x + lhs.x * rhs.w + lhs.y * rhs.z - lhs.z * rhs.y,
            lhs.w * rhs.y - lhs.x * rhs.z + lhs.y * rhs.w + lhs.z * rhs.x,
            lhs.w * rhs.z + lhs.x * rhs.y - lhs.y * rhs.x + lhs.z * rhs.w,
            lhs.w * rhs.w - lhs.x * rhs.x - lhs.y * rhs.y - lhs.z * rhs.z
        )
    }

    public func rotate(_ v: Vector3) -> Vector3 {
        let qv = Vector3(x, y, z)
        let uv = qv.cross(v)
        let uuv = qv.cross(uv)
        return v + ((uv * w) + uuv) * 2
    }

    public func slerp(to other: Quaternion, t: Float) -> Quaternion {
        var q1 = self.normalized
        var q2 = other.normalized
        var dot = q1.x * q2.x + q1.y * q2.y + q1.z * q2.z + q1.w * q2.w

        if dot < 0 {
            q2 = Quaternion(-q2.x, -q2.y, -q2.z, -q2.w)
            dot = -dot
        }

        if dot > 0.9995 {
            // Linear fallback
            let result = Quaternion(
                q1.x + t * (q2.x - q1.x),
                q1.y + t * (q2.y - q1.y),
                q1.z + t * (q2.z - q1.z),
                q1.w + t * (q2.w - q1.w)
            )
            return result.normalized
        }

        let theta0 = acos(Swift.min(Swift.max(dot, -1), 1))
        let theta = theta0 * t
        let sinTheta = sin(theta)
        let sinTheta0 = sin(theta0)

        let s0 = cos(theta) - dot * sinTheta / sinTheta0
        let s1 = sinTheta / sinTheta0

        return Quaternion(
            s0 * q1.x + s1 * q2.x,
            s0 * q1.y + s1 * q2.y,
            s0 * q1.z + s1 * q2.z,
            s0 * q1.w + s1 * q2.w
        )
    }

    public mutating func normalize() {
        let len = length
        guard len > .ulpOfOne else {
            x = 0; y = 0; z = 0; w = 1
            return
        }
        x /= len; y /= len; z /= len; w /= len
    }
}
