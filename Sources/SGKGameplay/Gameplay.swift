import Foundation
import SGKMath
import SGKCore
import SGKECS

public struct DamageEvent {
    public var amount: Float
    public var source: EntityID?
    public var target: EntityID
}

public struct Cooldown: Component, Codable, Sendable {
    public var duration: Float
    public var remaining: Float

    public init(_ duration: Float) {
        self.duration = duration
        self.remaining = 0
    }

    public var isReady: Bool { remaining <= 0 }

    public mutating func trigger() {
        remaining = duration
    }

    public mutating func update(_ dt: Float) {
        if remaining > 0 { remaining -= dt }
    }
}

public struct TimerComponent: Component, Codable, Sendable {
    public var duration: Float
    public var elapsed: Float
    public var looped: Bool
    public var completed: Bool

    public init(duration: Float, looped: Bool = false) {
        self.duration = duration
        self.elapsed = 0
        self.looped = looped
        self.completed = false
    }

    public mutating func update(_ dt: Float) -> Bool {
        elapsed += dt
        if elapsed >= duration {
            completed = true
            if looped {
                elapsed = 0
                completed = false
                return true
            }
            return true
        }
        return false
    }
}

public struct Inventory: Component, Sendable {
    public var items: [String: Int]
    public var capacity: Int

    public init(capacity: Int = 20) {
        self.items = [:]
        self.capacity = capacity
    }

    public mutating func add(_ item: String, count: Int = 1) -> Bool {
        let current = items[item] ?? 0
        let total = items.values.reduce(0, +)
        if total + count > capacity { return false }
        items[item] = current + count
        return true
    }

    public mutating func remove(_ item: String, count: Int = 1) -> Bool {
        guard let current = items[item], current >= count else { return false }
        let next = current - count
        if next == 0 { items[item] = nil } else { items[item] = next }
        return true
    }

    public func count(of item: String) -> Int {
        items[item] ?? 0
    }
}

public struct Score: Component, Codable, Sendable {
    public var value: Int
    public init(_ value: Int = 0) { self.value = value }
    public mutating func add(_ amount: Int) { value += amount }
}

public struct Team: Component, Codable, Sendable {
    public var id: Int
    public init(_ id: Int) { self.id = id }
}

public struct StatusEffect: Component, Sendable {
    public var name: String
    public var remaining: Float
    public var magnitude: Float
    public init(name: String, duration: Float, magnitude: Float = 1) {
        self.name = name
        self.remaining = duration
        self.magnitude = magnitude
    }
}

public final class GameplaySystems {
    public static func updateCooldowns(world: World, dt: Float) {
        world.forEach(Cooldown.self) { _, cd in
            cd.update(dt)
        }
    }

    public static func updateTimers(world: World, dt: Float) {
        world.forEach(TimerComponent.self) { _, timer in
            _ = timer.update(dt)
        }
    }

    public static func applyDamage(world: World, to entity: EntityID, amount: Float) {
        guard var health = world.get(Health.self, for: entity) else { return }
        health.damage(amount)
        world.add(health, to: entity)
        if !health.isAlive {
            Log.debug("Entity \(entity) died")
        }
    }
}
