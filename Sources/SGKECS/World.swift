import Foundation
import SGKCore
import SGKMath

/// High-performance ECS world using sparse-set style storage.
public final class World {
    private var generations: [UInt32] = []
    private var freeList: [UInt32] = []
    var componentStores: [ObjectIdentifier: AnyComponentStore] = [:]
    var entityMasks: [UInt64] = []
    var componentTypeIndex: [ObjectIdentifier: Int] = [:]
    private var nextTypeIndex = 0
    private var systems: [any System] = []
    private var systemNames: [String] = []

    public private(set) var entityCount: Int = 0
    public var isLocked: Bool = false

    public init(initialCapacity: Int = 1024) {
        generations.reserveCapacity(initialCapacity)
        entityMasks.reserveCapacity(initialCapacity)
    }

    public func createEntity() -> EntityID {
        precondition(!isLocked, "Cannot create entities while world is locked")
        let index: UInt32
        let generation: UInt32
        if let free = freeList.popLast() {
            index = free
            generation = generations[Int(index)]
        } else {
            index = UInt32(generations.count)
            generations.append(0)
            entityMasks.append(0)
            generation = 0
        }
        entityCount += 1
        return EntityID(index: index, generation: generation)
    }

    public func destroyEntity(_ entity: EntityID) {
        precondition(!isLocked, "Cannot destroy entities while world is locked")
        guard isAlive(entity) else { return }
        let idx = Int(entity.index)
        for store in componentStores.values {
            store.removeEntity(entity)
        }
        entityMasks[idx] = 0
        generations[idx] &+= 1
        freeList.append(entity.index)
        entityCount -= 1
    }

    public func isAlive(_ entity: EntityID) -> Bool {
        guard entity.index < generations.count else { return false }
        return generations[Int(entity.index)] == entity.generation
    }

    private func typeIndex<T: Component>(for type: T.Type) -> Int {
        let key = ObjectIdentifier(type)
        if let existing = componentTypeIndex[key] { return existing }
        let idx = nextTypeIndex
        nextTypeIndex += 1
        componentTypeIndex[key] = idx
        return idx
    }

    func store<T: Component>(for type: T.Type) -> ComponentStore<T> {
        let key = ObjectIdentifier(type)
        if let existing = componentStores[key] as? ComponentStore<T> { return existing }
        let store = ComponentStore<T>()
        componentStores[key] = store
        return store
    }

    public func add<T: Component>(_ component: T, to entity: EntityID) {
        precondition(!isLocked, "Cannot modify components while world is locked")
        guard isAlive(entity) else { return }
        let s = store(for: T.self)
        s.set(component, for: entity)
        let ti = typeIndex(for: T.self)
        if ti < 64 { entityMasks[Int(entity.index)] |= (1 << ti) }
    }

    public func remove<T: Component>(_ type: T.Type, from entity: EntityID) {
        precondition(!isLocked, "Cannot modify components while world is locked")
        guard isAlive(entity) else { return }
        store(for: type).remove(entity)
        let ti = typeIndex(for: type)
        if ti < 64 { entityMasks[Int(entity.index)] &= ~(1 << ti) }
    }

    public func get<T: Component>(_ type: T.Type, for entity: EntityID) -> T? {
        guard isAlive(entity) else { return nil }
        return store(for: type).get(entity)
    }

    public func has<T: Component>(_ type: T.Type, entity: EntityID) -> Bool {
        guard isAlive(entity) else { return false }
        return store(for: type).contains(entity)
    }

    public func getOrAdd<T: Component>(_ type: T.Type, for entity: EntityID, default defaultValue: @autoclosure () -> T) -> T {
        if let existing = get(type, for: entity) { return existing }
        let value = defaultValue()
        add(value, to: entity)
        return value
    }

    public func query<T: Component>(_ type: T.Type) -> ComponentQuery<T> {
        ComponentQuery(store: store(for: type), world: self)
    }

    public func query<A: Component, B: Component>(_ a: A.Type, _ b: B.Type) -> DualQuery<A, B> {
        DualQuery(storeA: store(for: a), storeB: store(for: b), world: self)
    }

    public func forEach<T: Component>(_ type: T.Type, _ body: (EntityID, inout T) -> Void) {
        store(for: type).forEach(body)
    }

    public func addSystem<S: System>(_ system: S) {
        systems.append(system)
        systemNames.append(String(describing: S.self))
    }

    public func updateSystems(deltaTime: Double) {
        isLocked = true
        defer { isLocked = false }
        for i in systems.indices {
            systems[i].update(self, deltaTime: deltaTime)
        }
    }

    public func systemCount() -> Int { systems.count }

    public func componentCount<T: Component>(_ type: T.Type) -> Int {
        store(for: type).count
    }

    public func clear() {
        for store in componentStores.values { store.clear() }
        generations.removeAll(keepingCapacity: true)
        freeList.removeAll(keepingCapacity: true)
        entityMasks.removeAll(keepingCapacity: true)
        entityCount = 0
    }

    public func setEnabled(_ entity: EntityID, _ enabled: Bool) {
        guard isAlive(entity) else { return }
        if enabled {
            remove(Disabled.self, from: entity)
        } else {
            add(Disabled(), to: entity)
        }
    }

    public func isEnabled(_ entity: EntityID) -> Bool {
        !has(Disabled.self, entity: entity)
    }

    public func addAny(_ component: any Component, to entity: EntityID) {
        if let c = component as? Health { add(c, to: entity); return }
        if let c = component as? TransformComponent { add(c, to: entity); return }
        if let c = component as? Transform2DComponent { add(c, to: entity); return }
        if let c = component as? Velocity { add(c, to: entity); return }
        if let c = component as? Velocity2D { add(c, to: entity); return }
        if let c = component as? NameComponent { add(c, to: entity); return }
        if let c = component as? Disabled { add(c, to: entity); return }
        if let c = component as? Tag { add(c, to: entity); return }
        Log.warning("addAny: unsupported component type \(type(of: component))")
    }

    public func removeAny(_ typeID: ObjectIdentifier, from entity: EntityID) {
        if typeID == ObjectIdentifier(Disabled.self) { remove(Disabled.self, from: entity); return }
        if typeID == ObjectIdentifier(Health.self) { remove(Health.self, from: entity); return }
        if typeID == ObjectIdentifier(Transform2DComponent.self) { remove(Transform2DComponent.self, from: entity); return }
        if typeID == ObjectIdentifier(TransformComponent.self) { remove(TransformComponent.self, from: entity); return }
        Log.warning("removeAny: unsupported type id")
    }

    public func createCommandBuffer() -> CommandBuffer {
        CommandBuffer(world: self)
    }

    public func hasComponent(of type: any Component.Type, entity: EntityID) -> Bool {
        let key = ObjectIdentifier(type)
        guard componentStores[key] != nil else { return false }
        if let idx = componentTypeIndex[key], idx < 64 {
            return (entityMasks[Int(entity.index)] & (1 << idx)) != 0
        }
        return false
    }
}

// MARK: - Storage

class AnyComponentStore {
    func removeEntity(_ entity: EntityID) {}
    func clear() {}
    var count: Int { 0 }
}

final class ComponentStore<T: Component>: AnyComponentStore {
    private var dense: [T] = []
    private var entities: [EntityID] = []
    private var sparse: [Int] = []

    override var count: Int { dense.count }

    func set(_ component: T, for entity: EntityID) {
        let idx = Int(entity.index)
        ensureSparse(idx)
        if sparse[idx] >= 0 {
            dense[sparse[idx]] = component
        } else {
            sparse[idx] = dense.count
            dense.append(component)
            entities.append(entity)
        }
    }

    func get(_ entity: EntityID) -> T? {
        let idx = Int(entity.index)
        guard idx < sparse.count, sparse[idx] >= 0 else { return nil }
        let denseIdx = sparse[idx]
        guard denseIdx < dense.count, entities[denseIdx] == entity else { return nil }
        return dense[denseIdx]
    }

    func contains(_ entity: EntityID) -> Bool { get(entity) != nil }

    func remove(_ entity: EntityID) {
        let idx = Int(entity.index)
        guard idx < sparse.count, sparse[idx] >= 0 else { return }
        let denseIdx = sparse[idx]
        let last = dense.count - 1
        if denseIdx != last {
            dense[denseIdx] = dense[last]
            entities[denseIdx] = entities[last]
            sparse[Int(entities[denseIdx].index)] = denseIdx
        }
        dense.removeLast()
        entities.removeLast()
        sparse[idx] = -1
    }

    override func removeEntity(_ entity: EntityID) { remove(entity) }

    override func clear() {
        dense.removeAll(keepingCapacity: true)
        entities.removeAll(keepingCapacity: true)
        sparse = sparse.map { _ in -1 }
    }

    func forEach(_ body: (EntityID, inout T) -> Void) {
        for i in dense.indices { body(entities[i], &dense[i]) }
    }

    private func ensureSparse(_ index: Int) {
        if index >= sparse.count {
            sparse.append(contentsOf: Array(repeating: -1, count: index - sparse.count + 1))
        }
    }
}

public struct ComponentQuery<T: Component>: Sequence {
    let store: ComponentStore<T>
    let world: World

    public func makeIterator() -> AnyIterator<(EntityID, T)> {
        AnyIterator { nil }
    }

    public func forEach(_ body: (EntityID, T) -> Void) {
        store.forEach { e, c in body(e, c) }
    }

    public func forEachMutating(_ body: (EntityID, inout T) -> Void) {
        store.forEach(body)
    }
}

public struct DualQuery<A: Component, B: Component> {
    let storeA: ComponentStore<A>
    let storeB: ComponentStore<B>
    let world: World

    public func forEach(_ body: (EntityID, A, B) -> Void) {
        storeA.forEach { entity, a in
            if let b = storeB.get(entity) { body(entity, a, b) }
        }
    }
}
