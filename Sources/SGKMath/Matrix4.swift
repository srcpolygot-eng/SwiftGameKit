import Foundation

/// Column-major 4x4 matrix.
public struct Matrix4: Equatable, Codable, Sendable, CustomStringConvertible {
    /// Storage in column-major order: m[col * 4 + row]
    public var m: [Float]

    public init() {
        m = [
            1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 1, 0,
            0, 0, 0, 1
        ]
    }

    public init(_ values: [Float]) {
        precondition(values.count == 16)
        m = values
    }

    public init(columns: (Vector4, Vector4, Vector4, Vector4)) {
        m = [
            columns.0.x, columns.0.y, columns.0.z, columns.0.w,
            columns.1.x, columns.1.y, columns.1.z, columns.1.w,
            columns.2.x, columns.2.y, columns.2.z, columns.2.w,
            columns.3.x, columns.3.y, columns.3.z, columns.3.w
        ]
    }

    public static let identity = Matrix4()

    public subscript(row: Int, col: Int) -> Float {
        get { m[col * 4 + row] }
        set { m[col * 4 + row] = newValue }
    }

    public var description: String {
        var s = "Matrix4(\n"
        for r in 0..<4 {
            s += "  "
            for c in 0..<4 {
                s += String(format: "%8.4f ", self[r, c])
            }
            s += "\n"
        }
        s += ")"
        return s
    }

    // MARK: - Construction

    public static func translation(_ v: Vector3) -> Matrix4 {
        var mat = Matrix4.identity
        mat[0, 3] = v.x
        mat[1, 3] = v.y
        mat[2, 3] = v.z
        return mat
    }

    public static func translation(_ x: Float, _ y: Float, _ z: Float) -> Matrix4 {
        translation(Vector3(x, y, z))
    }

    public static func scale(_ v: Vector3) -> Matrix4 {
        var mat = Matrix4.identity
        mat[0, 0] = v.x
        mat[1, 1] = v.y
        mat[2, 2] = v.z
        return mat
    }

    public static func scale(_ s: Float) -> Matrix4 {
        scale(Vector3(s, s, s))
    }

    public static func rotationX(_ angle: Float) -> Matrix4 {
        let c = cos(angle)
        let s = sin(angle)
        var mat = Matrix4.identity
        mat[1, 1] = c
        mat[1, 2] = -s
        mat[2, 1] = s
        mat[2, 2] = c
        return mat
    }

    public static func rotationY(_ angle: Float) -> Matrix4 {
        let c = cos(angle)
        let s = sin(angle)
        var mat = Matrix4.identity
        mat[0, 0] = c
        mat[0, 2] = s
        mat[2, 0] = -s
        mat[2, 2] = c
        return mat
    }

    public static func rotationZ(_ angle: Float) -> Matrix4 {
        let c = cos(angle)
        let s = sin(angle)
        var mat = Matrix4.identity
        mat[0, 0] = c
        mat[0, 1] = -s
        mat[1, 0] = s
        mat[1, 1] = c
        return mat
    }

    public static func fromQuaternion(_ q: Quaternion) -> Matrix4 {
        let nq = q.normalized
        let xx = nq.x * nq.x
        let yy = nq.y * nq.y
        let zz = nq.z * nq.z
        let xy = nq.x * nq.y
        let xz = nq.x * nq.z
        let yz = nq.y * nq.z
        let wx = nq.w * nq.x
        let wy = nq.w * nq.y
        let wz = nq.w * nq.z

        var mat = Matrix4.identity
        mat[0, 0] = 1 - 2 * (yy + zz)
        mat[0, 1] = 2 * (xy - wz)
        mat[0, 2] = 2 * (xz + wy)
        mat[1, 0] = 2 * (xy + wz)
        mat[1, 1] = 1 - 2 * (xx + zz)
        mat[1, 2] = 2 * (yz - wx)
        mat[2, 0] = 2 * (xz - wy)
        mat[2, 1] = 2 * (yz + wx)
        mat[2, 2] = 1 - 2 * (xx + yy)
        return mat
    }

    public static func perspective(fovY: Float, aspect: Float, near: Float, far: Float) -> Matrix4 {
        let f = 1.0 / tan(fovY * 0.5)
        var mat = Matrix4()
        mat.m = [
            f / aspect, 0, 0, 0,
            0, f, 0, 0,
            0, 0, (far + near) / (near - far), -1,
            0, 0, (2 * far * near) / (near - far), 0
        ]
        return mat
    }

    public static func orthographic(left: Float, right: Float, bottom: Float, top: Float, near: Float, far: Float) -> Matrix4 {
        var mat = Matrix4.identity
        mat[0, 0] = 2 / (right - left)
        mat[1, 1] = 2 / (top - bottom)
        mat[2, 2] = -2 / (far - near)
        mat[0, 3] = -(right + left) / (right - left)
        mat[1, 3] = -(top + bottom) / (top - bottom)
        mat[2, 3] = -(far + near) / (far - near)
        return mat
    }

    public static func lookAt(eye: Vector3, target: Vector3, up: Vector3) -> Matrix4 {
        let f = (target - eye).normalized
        let s = f.cross(up).normalized
        let u = s.cross(f)

        var mat = Matrix4.identity
        mat[0, 0] = s.x
        mat[0, 1] = s.y
        mat[0, 2] = s.z
        mat[1, 0] = u.x
        mat[1, 1] = u.y
        mat[1, 2] = u.z
        mat[2, 0] = -f.x
        mat[2, 1] = -f.y
        mat[2, 2] = -f.z
        mat[0, 3] = -s.dot(eye)
        mat[1, 3] = -u.dot(eye)
        mat[2, 3] = f.dot(eye)
        return mat
    }

    // MARK: - Operations

    public static func * (lhs: Matrix4, rhs: Matrix4) -> Matrix4 {
        var result = Matrix4()
        for col in 0..<4 {
            for row in 0..<4 {
                var sum: Float = 0
                for i in 0..<4 {
                    sum += lhs[row, i] * rhs[i, col]
                }
                result[row, col] = sum
            }
        }
        return result
    }

    public static func * (lhs: Matrix4, rhs: Vector4) -> Vector4 {
        Vector4(
            lhs[0, 0] * rhs.x + lhs[0, 1] * rhs.y + lhs[0, 2] * rhs.z + lhs[0, 3] * rhs.w,
            lhs[1, 0] * rhs.x + lhs[1, 1] * rhs.y + lhs[1, 2] * rhs.z + lhs[1, 3] * rhs.w,
            lhs[2, 0] * rhs.x + lhs[2, 1] * rhs.y + lhs[2, 2] * rhs.z + lhs[2, 3] * rhs.w,
            lhs[3, 0] * rhs.x + lhs[3, 1] * rhs.y + lhs[3, 2] * rhs.z + lhs[3, 3] * rhs.w
        )
    }

    public static func * (lhs: Matrix4, rhs: Vector3) -> Vector3 {
        let v4 = lhs * Vector4(rhs, w: 1)
        return v4.xyz
    }

    public func transformPoint(_ p: Vector3) -> Vector3 {
        let v = self * Vector4(p, w: 1)
        if abs(v.w) > .ulpOfOne {
            return Vector3(v.x / v.w, v.y / v.w, v.z / v.w)
        }
        return v.xyz
    }

    public func transformDirection(_ d: Vector3) -> Vector3 {
        (self * Vector4(d, w: 0)).xyz
    }

    public func transposed() -> Matrix4 {
        var result = Matrix4()
        for r in 0..<4 {
            for c in 0..<4 {
                result[r, c] = self[c, r]
            }
        }
        return result
    }

    public func inverted() -> Matrix4? {
        // Simple adjugate method for 4x4
        var inv = [Float](repeating: 0, count: 16)

        inv[0] = m[5]  * m[10] * m[15] - m[5]  * m[11] * m[14] - m[9]  * m[6]  * m[15] + m[9]  * m[7]  * m[14] + m[13] * m[6]  * m[11] - m[13] * m[7]  * m[10]
        inv[4] = -m[4]  * m[10] * m[15] + m[4]  * m[11] * m[14] + m[8]  * m[6]  * m[15] - m[8]  * m[7]  * m[14] - m[12] * m[6]  * m[11] + m[12] * m[7]  * m[10]
        inv[8] = m[4]  * m[9]  * m[15] - m[4]  * m[11] * m[13] - m[8]  * m[5]  * m[15] + m[8]  * m[7]  * m[13] + m[12] * m[5]  * m[11] - m[12] * m[7]  * m[9]
        inv[12] = -m[4]  * m[9]  * m[14] + m[4]  * m[10] * m[13] + m[8]  * m[5]  * m[14] - m[8]  * m[6]  * m[13] - m[12] * m[5]  * m[10] + m[12] * m[6]  * m[9]
        inv[1] = -m[1]  * m[10] * m[15] + m[1]  * m[11] * m[14] + m[9]  * m[2]  * m[15] - m[9]  * m[3]  * m[14] - m[13] * m[2]  * m[11] + m[13] * m[3]  * m[10]
        inv[5] = m[0]  * m[10] * m[15] - m[0]  * m[11] * m[14] - m[8]  * m[2]  * m[15] + m[8]  * m[3]  * m[14] + m[12] * m[2]  * m[11] - m[12] * m[3]  * m[10]
        inv[9] = -m[0]  * m[9]  * m[15] + m[0]  * m[11] * m[13] + m[8]  * m[1]  * m[15] - m[8]  * m[3]  * m[13] - m[12] * m[1]  * m[11] + m[12] * m[3]  * m[9]
        inv[13] = m[0]  * m[9]  * m[14] - m[0]  * m[10] * m[13] - m[8]  * m[1]  * m[14] + m[8]  * m[2]  * m[13] + m[12] * m[1]  * m[10] - m[12] * m[2]  * m[9]
        inv[2] = m[1]  * m[6]  * m[15] - m[1]  * m[7]  * m[14] - m[5]  * m[2]  * m[15] + m[5]  * m[3]  * m[14] + m[13] * m[2]  * m[7]  - m[13] * m[3]  * m[6]
        inv[6] = -m[0]  * m[6]  * m[15] + m[0]  * m[7]  * m[14] + m[4]  * m[2]  * m[15] - m[4]  * m[3]  * m[14] - m[12] * m[2]  * m[7]  + m[12] * m[3]  * m[6]
        inv[10] = m[0]  * m[5]  * m[15] - m[0]  * m[7]  * m[13] - m[4]  * m[1]  * m[15] + m[4]  * m[3]  * m[13] + m[12] * m[1]  * m[7]  - m[12] * m[3]  * m[5]
        inv[14] = -m[0]  * m[5]  * m[14] + m[0]  * m[6]  * m[13] + m[4]  * m[1]  * m[14] - m[4]  * m[2]  * m[13] - m[12] * m[1]  * m[6]  + m[12] * m[2]  * m[5]
        inv[3] = -m[1]  * m[6]  * m[11] + m[1]  * m[7]  * m[10] + m[5]  * m[2]  * m[11] - m[5]  * m[3]  * m[10] - m[9]  * m[2]  * m[7]  + m[9]  * m[3]  * m[6]
        inv[7] = m[0]  * m[6]  * m[11] - m[0]  * m[7]  * m[10] - m[4]  * m[2]  * m[11] + m[4]  * m[3]  * m[10] + m[8]  * m[2]  * m[7]  - m[8]  * m[3]  * m[6]
        inv[11] = -m[0]  * m[5]  * m[11] + m[0]  * m[7]  * m[9]  + m[4]  * m[1]  * m[11] - m[4]  * m[3]  * m[9]  - m[8]  * m[1]  * m[7]  + m[8]  * m[3]  * m[5]
        inv[15] = m[0]  * m[5]  * m[10] - m[0]  * m[6]  * m[9]  - m[4]  * m[1]  * m[10] + m[4]  * m[2]  * m[9]  + m[8]  * m[1]  * m[6]  - m[8]  * m[2]  * m[5]

        var det = m[0] * inv[0] + m[1] * inv[4] + m[2] * inv[8] + m[3] * inv[12]
        guard abs(det) > 1e-8 else { return nil }
        det = 1.0 / det
        for i in 0..<16 {
            inv[i] *= det
        }
        return Matrix4(inv)
    }
}
