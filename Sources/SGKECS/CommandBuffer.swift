import Foundation

/// Deferred entity operations that are applied safely after system updates.
public final class CommandBuffer {
    public enum Command {
        case create(EntityID)
        case destroy(EntityID)
        case addComponent(EntityID, any Component)
        case removeComponent(EntityID, ObjectIdentifier)
        case enable(EntityID)
        case disable(EntityID)
    }

    private var commands: [Command] = []
    private weak var world: World?

    public init(world: World) {
        self.world = world
    }

    public func createEntity() -> EntityID {
        guard let world else { return .invalid }
        let id = world.createEntity()
        // Already created; recorded for tracking if needed
        return id
    }

    public func destroyEntity(_ entity: EntityID) {
        commands.append(.destroy(entity))
    }

    public func add<T: Component>(_ component: T, to entity: EntityID) {
        commands.append(.addComponent(entity, component))
    }

    public func remove<T: Component>(_ type: T.Type, from entity: EntityID) {
        commands.append(.removeComponent(entity, ObjectIdentifier(type)))
    }

    public func enable(_ entity: EntityID) {
        commands.append(.enable(entity))
    }

    public func disable(_ entity: EntityID) {
        commands.append(.disable(entity))
    }

    /// Apply all buffered commands to the world.
    public func flush() {
        guard let world else { return }
        for cmd in commands {
            switch cmd {
            case .create:
                break
            case .destroy(let e):
                world.destroyEntity(e)
            case .addComponent(let e, let c):
                world.addAny(c, to: e)
            case .removeComponent(let e, let id):
                world.removeAny(id, from: e)
            case .enable(let e):
                world.setEnabled(e, true)
            case .disable(let e):
                world.setEnabled(e, false)
            }
        }
        commands.removeAll(keepingCapacity: true)
    }

    public var pendingCount: Int { commands.count }
}
