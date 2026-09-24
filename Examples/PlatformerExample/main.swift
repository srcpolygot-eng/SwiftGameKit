import Foundation
import SwiftGameKit

/// Minimal 2D platformer-style demo using ECS + Physics.
print("=== SwiftGameKit Platformer Example ===")
print("Version: \(SwiftGameKitInfo.version)")

let world = World()
let physics = PhysicsWorld2D()
physics.gravity = Vector2(0, -20)

// Ground
let ground = world.createEntity()
world.add(Transform2DComponent(local: Transform2D(position: Vector2(0, -5))), to: ground)
world.add(RigidBody2D(bodyType: .staticBody), to: ground)
world.add(Collider2D(shape: .box(halfExtents: Vector2(20, 1))), to: ground)

// Player
let player = world.createEntity()
world.add(NameComponent("Player"), to: player)
world.add(Transform2DComponent(local: Transform2D(position: Vector2(0, 2))), to: player)
world.add(RigidBody2D(bodyType: .dynamic, mass: 1, restitution: 0), to: player)
world.add(Collider2D(shape: .box(halfExtents: Vector2(0.4, 0.8))), to: player)
world.add(Health(current: 100), to: player)
world.add(Velocity2D(), to: player)

print("Entities: \(world.entityCount)")
print("Simulating 60 frames...")

for frame in 0..<60 {
    // Simple "input"
    if frame == 10 {
        if var body = world.get(RigidBody2D.self, for: player) {
            body.applyImpulse(Vector2(0, 12))
            world.add(body, to: player)
            print("  Frame \(frame): Jump!")
        }
    }
    if frame > 20 && frame < 40 {
        if var body = world.get(RigidBody2D.self, for: player) {
            body.velocity.x = 3
            world.add(body, to: player)
        }
    }
    physics.step(world: world, dt: 1.0 / 60.0)
}

if let t = world.get(Transform2DComponent.self, for: player) {
    print("Player final position: \(t.position)")
}
print("Platformer example completed successfully.")
