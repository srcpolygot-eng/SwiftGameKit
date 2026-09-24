import Foundation

/// Marker protocol for all components.
public protocol Component: Sendable {}

/// Empty tag component.
public protocol TagComponent: Component {}

/// Component that has an associated entity id for convenience (optional).
public protocol EntityAwareComponent: Component {
    var entity: EntityID { get set }
}

/// Unique identifier for an entity.
public struct EntityID: Hashable, Codable, Sendable, CustomStringConvertible {
    public let index: UInt32
    public let generation: UInt32

    public init(index: UInt32, generation: UInt32) {
        self.index = index
        self.generation = generation
    }

    public static let invalid = EntityID(index: .max, generation: .max)

    public var isValid: Bool {
        self != .invalid
    }

    public var description: String {
        "Entity(\(index):\(generation))"
    }
}

/// Type-erased component type key.
public struct ComponentTypeID: Hashable, Sendable {
    public let id: ObjectIdentifier

    public init<T: Component>(_ type: T.Type) {
        self.id = ObjectIdentifier(type)
    }
}

public protocol ComponentStorage: AnyObject {
    var count: Int { get }
    func remove(at sparseIndex: Int)
    func clear()
}
