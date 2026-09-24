import Foundation

/// Base protocol for ECS systems.
public protocol System: AnyObject {
    func update(_ world: World, deltaTime: Double)
}

/// System that can declare dependencies for ordering.
public protocol OrderedSystem: System {
    static var dependencies: [any System.Type] { get }
}

public extension OrderedSystem {
    static var dependencies: [any System.Type] { [] }
}

/// Convenience system that runs a closure.
public final class ClosureSystem: System {
    private let body: (World, Double) -> Void

    public init(_ body: @escaping (World, Double) -> Void) {
        self.body = body
    }

    public func update(_ world: World, deltaTime: Double) {
        body(world, deltaTime)
    }
}
