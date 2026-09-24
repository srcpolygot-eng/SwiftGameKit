import Foundation
import SGKMath

/// Parameter types for materials.
public enum MaterialParameter: Sendable {
    case scalar(Float)
    case vector2(Vector2)
    case vector3(Vector3)
    case vector4(Vector4)
    case color(Vector4)
    case texture(String)
}

/// Reusable material definition.
public final class MaterialDefinition: @unchecked Sendable {
    public let name: String
    public var shaderName: String
    public private(set) var parameters: [String: MaterialParameter] = [:]

    public init(name: String, shaderName: String = "default") {
        self.name = name
        self.shaderName = shaderName
    }

    public func set(_ name: String, _ value: MaterialParameter) {
        parameters[name] = value
    }

    public func scalar(_ name: String) -> Float? {
        if case .scalar(let v) = parameters[name] { return v }
        return nil
    }

    public func color(_ name: String) -> Vector4? {
        if case .color(let v) = parameters[name] { return v }
        if case .vector4(let v) = parameters[name] { return v }
        return nil
    }

    public func texture(_ name: String) -> String? {
        if case .texture(let id) = parameters[name] { return id }
        return nil
    }

    public static let unlit = MaterialDefinition(name: "unlit", shaderName: "unlit")
    public static let standard: MaterialDefinition = {
        let m = MaterialDefinition(name: "standard", shaderName: "standard")
        m.set("albedo", .color(Vector4(0.8, 0.8, 0.8, 1)))
        m.set("metallic", .scalar(0))
        m.set("roughness", .scalar(0.5))
        return m
    }()
}

/// Instance of a material with overridden parameters.
public final class MaterialInstance: @unchecked Sendable {
    public let definition: MaterialDefinition
    public private(set) var overrides: [String: MaterialParameter] = [:]

    public init(definition: MaterialDefinition) {
        self.definition = definition
    }

    public func set(_ name: String, _ value: MaterialParameter) {
        overrides[name] = value
    }

    public func parameter(_ name: String) -> MaterialParameter? {
        overrides[name] ?? definition.parameters[name]
    }
}

/// Basic light description (architecture; actual shading depends on backend).
public struct Light: Sendable {
    public enum Kind: Sendable {
        case directional
        case point
        case spot
        case ambient
    }

    public var kind: Kind
    public var color: Vector3
    public var intensity: Float
    public var position: Vector3
    public var direction: Vector3
    public var range: Float
    public var innerCone: Float
    public var outerCone: Float
    public var castsShadows: Bool

    public init(
        kind: Kind = .directional,
        color: Vector3 = Vector3(1, 1, 1),
        intensity: Float = 1,
        position: Vector3 = .zero,
        direction: Vector3 = Vector3(0, -1, 0),
        range: Float = 10,
        innerCone: Float = 0.4,
        outerCone: Float = 0.6,
        castsShadows: Bool = false
    ) {
        self.kind = kind
        self.color = color
        self.intensity = intensity
        self.position = position
        self.direction = direction
        self.range = range
        self.innerCone = innerCone
        self.outerCone = outerCone
        self.castsShadows = castsShadows
    }

    public static func directional(color: Vector3 = .one, intensity: Float = 1, direction: Vector3 = Vector3(0, -1, 0)) -> Light {
        Light(kind: .directional, color: color, intensity: intensity, direction: direction)
    }

    public static func point(color: Vector3 = .one, intensity: Float = 1, position: Vector3, range: Float = 10) -> Light {
        Light(kind: .point, color: color, intensity: intensity, position: position, range: range)
    }

    public static func ambient(color: Vector3 = Vector3(0.1, 0.1, 0.12), intensity: Float = 1) -> Light {
        Light(kind: .ambient, color: color, intensity: intensity)
    }
}
