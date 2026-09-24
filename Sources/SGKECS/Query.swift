import Foundation

/// Filter for advanced ECS queries.
public struct QueryFilter: Sendable {
    public var required: [ObjectIdentifier] = []
    public var excluded: [ObjectIdentifier] = []

    public init() {}

    public mutating func require<T: Component>(_ type: T.Type) {
        required.append(ObjectIdentifier(type))
    }

    public mutating func exclude<T: Component>(_ type: T.Type) {
        excluded.append(ObjectIdentifier(type))
    }
}

/// Result of a multi-component query iteration.
public struct QueryResult2<A: Component, B: Component> {
    public let entity: EntityID
    public let a: A
    public let b: B
}

public struct QueryResult3<A: Component, B: Component, C: Component> {
    public let entity: EntityID
    public let a: A
    public let b: B
    public let c: C
}

extension World {
    /// Query entities that have all required component types and none of the excluded types.
    public func query<A: Component, B: Component>(
        _ typeA: A.Type,
        _ typeB: B.Type,
        excluding excluded: [any Component.Type] = []
    ) -> [QueryResult2<A, B>] {
        var results: [QueryResult2<A, B>] = []
        let storeA = store(for: typeA)
        storeA.forEach { entity, a in
            guard isAlive(entity) else { return }
            if !excluded.isEmpty {
                var skip = false
                for ex in excluded {
                    if hasComponent(of: ex, entity: entity) {
                        skip = true
                        break
                    }
                }
                if skip { return }
            }
            if let b = get(typeB, for: entity) {
                results.append(QueryResult2(entity: entity, a: a, b: b))
            }
        }
        return results
    }

    /// Query with three component types.
    public func query<A: Component, B: Component, C: Component>(
        _ typeA: A.Type,
        _ typeB: B.Type,
        _ typeC: C.Type,
        excluding excluded: [any Component.Type] = []
    ) -> [QueryResult3<A, B, C>] {
        var results: [QueryResult3<A, B, C>] = []
        let storeA = store(for: typeA)
        storeA.forEach { entity, a in
            guard isAlive(entity) else { return }
            for ex in excluded {
                if hasComponent(of: ex, entity: entity) { return }
            }
            guard let b = get(typeB, for: entity),
                  let c = get(typeC, for: entity) else { return }
            results.append(QueryResult3(entity: entity, a: a, b: b, c: c))
        }
        return results
    }

    /// Check presence of an arbitrary component type (type-erased helper).
    public func hasComponent(of type: any Component.Type, entity: EntityID) -> Bool {
        let key = ObjectIdentifier(type)
        guard let anyStore = componentStores[key] else { return false }
        // ComponentStore uses entity presence; we approximate via mask when possible
        if let idx = componentTypeIndex[key], idx < 64 {
            return (entityMasks[Int(entity.index)] & (1 << idx)) != 0
        }
        // Fallback: try common pattern - not perfect for arbitrary types without generics
        return false
    }
}
