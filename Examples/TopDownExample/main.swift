import Foundation
import SwiftGameKit

print("=== Top-Down Example ===")

let world = World()
let player = world.createEntity()
world.add(NameComponent("Hero"), to: player)
world.add(Transform2DComponent(local: Transform2D(position: Vector2(5, 5))), to: player)
world.add(Velocity2D(linear: Vector2(2, 0)), to: player)
world.add(Health(current: 100), to: player)
world.add(Score(0), to: player)

// Enemies
for i in 0..<5 {
    let e = world.createEntity()
    world.add(NameComponent("Enemy\(i)"), to: e)
    world.add(Transform2DComponent(local: Transform2D(position: Vector2(Float(10 + i), Float(i * 2)))), to: e)
    world.add(Health(current: 30), to: e)
    world.add(Team(1), to: e)
}

print("World has \(world.entityCount) entities")

for frame in 0..<30 {
    world.forEach(Velocity2D.self) { entity, vel in
        if var t = world.get(Transform2DComponent.self, for: entity) {
            t.position += vel.linear * (1.0 / 60.0)
            world.add(t, to: entity)
        }
    }
    if frame == 15 {
        GameplaySystems.applyDamage(world: world, to: player, amount: 10)
        if var score = world.get(Score.self, for: player) {
            score.add(100)
            world.add(score, to: player)
        }
    }
}

let health = world.get(Health.self, for: player)!
let score = world.get(Score.self, for: player)!
print("Player health: \(health.current), score: \(score.value)")
print("Top-down example completed.")
