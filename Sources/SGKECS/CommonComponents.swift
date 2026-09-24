import Foundation
import SGKMath

public struct TransformComponent: Component, Codable, Sendable {
    public var local: Transform
    public var world: Transform

    public init(local: Transform = .identity) {
        self.local = local
        self.world = local
    }

    public var position: Vector3 {
        get { local.position }
        set { local.position = newValue }
    }

    public var rotation: Quaternion {
        get { local.rotation }
        set { local.rotation = newValue }
    }

    public var scale: Vector3 {
        get { local.scale }
        set { local.scale = newValue }
    }
}

public struct Transform2DComponent: Component, Codable, Sendable {
    public var local: Transform2D
    public var world: Transform2D

    public init(local: Transform2D = .identity) {
        self.local = local
        self.world = local
    }

    public var position: Vector2 {
        get { local.position }
        set { local.position = newValue }
    }

    public var rotation: Float {
        get { local.rotation }
        set { local.rotation = newValue }
    }

    public var scale: Vector2 {
        get { local.scale }
        set { local.scale = newValue }
    }
}

public struct Velocity: Component, Codable, Sendable {
    public var linear: Vector3
    public var angular: Vector3

    public init(linear: Vector3 = .zero, angular: Vector3 = .zero) {
        self.linear = linear
        self.angular = angular
    }
}

public struct Velocity2D: Component, Codable, Sendable {
    public var linear: Vector2
    public var angular: Float

    public init(linear: Vector2 = .zero, angular: Float = 0) {
        self.linear = linear
        self.angular = angular
    }
}

public struct Health: Component, Codable, Sendable {
    public var current: Float
    public var maximum: Float

    public init(current: Float, maximum: Float? = nil) {
        self.current = current
        self.maximum = maximum ?? current
    }

    public var isAlive: Bool { current > 0 }
    public var ratio: Float { maximum > 0 ? current / maximum : 0 }

    public mutating func damage(_ amount: Float) {
        current = max(0, current - amount)
    }

    public mutating func heal(_ amount: Float) {
        current = min(maximum, current + amount)
    }
}

public struct NameComponent: Component, Codable, Sendable {
    public var name: String
    public init(_ name: String) { self.name = name }
}

public struct Tag: Component, Codable, Sendable {
    public var value: String
    public init(_ value: String) { self.value = value }
}

public struct Parent: Component, Sendable {
    public var entity: EntityID
    public init(_ entity: EntityID) { self.entity = entity }
}

public struct Children: Component, Sendable {
    public var entities: [EntityID]
    public init(_ entities: [EntityID] = []) { self.entities = entities }
}

public struct Lifetime: Component, Codable, Sendable {
    public var remaining: Double
    public init(_ remaining: Double) { self.remaining = remaining }
}

public struct SpriteComponent: Component, Sendable {
    public var textureID: String
    public var region: (x: Float, y: Float, w: Float, h: Float)?
    public var color: Vector4
    public var flipX: Bool
    public var flipY: Bool
    public var layer: Int
    public var orderInLayer: Int

    public init(
        textureID: String = "",
        region: (x: Float, y: Float, w: Float, h: Float)? = nil,
        color: Vector4 = .one,
        flipX: Bool = false,
        flipY: Bool = false,
        layer: Int = 0,
        orderInLayer: Int = 0
    ) {
        self.textureID = textureID
        self.region = region
        self.color = color
        self.flipX = flipX
        self.flipY = flipY
        self.layer = layer
        self.orderInLayer = orderInLayer
    }
}

public struct CameraComponent: Component, Codable, Sendable {
    public var isOrthographic: Bool
    public var fov: Float
    public var near: Float
    public var far: Float
    public var orthographicSize: Float
    public var zoom: Float
    public var clearColor: Vector4
    public var priority: Int

    public init(
        isOrthographic: Bool = true,
        fov: Float = 60 * Math.degToRad,
        near: Float = 0.1,
        far: Float = 1000,
        orthographicSize: Float = 5,
        zoom: Float = 1,
        clearColor: Vector4 = Vector4(0.1, 0.1, 0.15, 1),
        priority: Int = 0
    ) {
        self.isOrthographic = isOrthographic
        self.fov = fov
        self.near = near
        self.far = far
        self.orthographicSize = orthographicSize
        self.zoom = zoom
        self.clearColor = clearColor
        self.priority = priority
    }
}

/// Marker component: entity is disabled and skipped by most systems/queries.
public struct Disabled: Component, TagComponent, Sendable {}

/// Marker for entities that changed this frame (optional tracking).
public struct Changed: Component, TagComponent, Sendable {}
