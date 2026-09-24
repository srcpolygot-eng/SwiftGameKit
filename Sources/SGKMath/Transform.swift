import Foundation

/// Combined position, rotation and scale.
public struct Transform: Equatable, Codable, Sendable {
    public var position: Vector3
    public var rotation: Quaternion
    public var scale: Vector3

    public init(
        position: Vector3 = .zero,
        rotation: Quaternion = .identity,
        scale: Vector3 = .one
    ) {
        self.position = position
        self.rotation = rotation
        self.scale = scale
    }

    public static let identity = Transform()

    public var matrix: Matrix4 {
        let t = Matrix4.translation(position)
        let r = Matrix4.fromQuaternion(rotation)
        let s = Matrix4.scale(scale)
        return t * r * s
    }

    public var inverseMatrix: Matrix4? {
        matrix.inverted()
    }

    public mutating func translate(by delta: Vector3) {
        position += delta
    }

    public mutating func rotate(by q: Quaternion) {
        rotation = (q * rotation).normalized
    }

    public mutating func rotate(axis: Vector3, angle: Float) {
        rotate(by: .fromAxisAngle(axis: axis, angle: angle))
    }

    public func transformedPoint(_ point: Vector3) -> Vector3 {
        matrix.transformPoint(point)
    }

    public func transformedDirection(_ dir: Vector3) -> Vector3 {
        matrix.transformDirection(dir)
    }

    public static func * (parent: Transform, child: Transform) -> Transform {
        let pos = parent.transformedPoint(child.position)
        let rot = (parent.rotation * child.rotation).normalized
        let scl = Vector3(
            parent.scale.x * child.scale.x,
            parent.scale.y * child.scale.y,
            parent.scale.z * child.scale.z
        )
        return Transform(position: pos, rotation: rot, scale: scl)
    }
}

/// 2D transform helper.
public struct Transform2D: Equatable, Codable, Sendable {
    public var position: Vector2
    public var rotation: Float // radians
    public var scale: Vector2

    public init(
        position: Vector2 = .zero,
        rotation: Float = 0,
        scale: Vector2 = .one
    ) {
        self.position = position
        self.rotation = rotation
        self.scale = scale
    }

    public static let identity = Transform2D()

    public var matrix: Matrix4 {
        let t = Matrix4.translation(Vector3(position.x, position.y, 0))
        let r = Matrix4.rotationZ(rotation)
        let s = Matrix4.scale(Vector3(scale.x, scale.y, 1))
        return t * r * s
    }

    public mutating func translate(by delta: Vector2) {
        position += delta
    }

    public func transformedPoint(_ point: Vector2) -> Vector2 {
        let p = matrix.transformPoint(Vector3(point.x, point.y, 0))
        return Vector2(p.x, p.y)
    }
}
