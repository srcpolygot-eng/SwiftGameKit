import Foundation
import SwiftGameKit

print("=== Physics Sandbox ===")
let world = World()
let physics = PhysicsWorld2D()
physics.gravity = Vector2(0, -9.81)

// Floor
let floor = world.createEntity()
world.add(Transform2DComponent(local: Transform2D(position: Vector2(0, -3))), to: floor)
world.add(RigidBody2D(bodyType: .staticBody), to: floor)
world.add(Collider2D(shape: .box(halfExtents: Vector2(10, 0.5))), to: floor)

// Balls
for i in 0..<5 {
    let e = world.createEntity()
    world.add(Transform2DComponent(local: Transform2D(position: Vector2(Float(i) - 2, 5 + Float(i)))), to: e)
    world.add(RigidBody2D(bodyType: .dynamic, mass: 1, restitution: 0.6), to: e)
    world.add(Collider2D(shape: .circle(radius: 0.4)), to: e)
}

print("Simulating 180 frames with \(world.entityCount) entities...")
for _ in 0..<180 {
    physics.step(world: world, dt: 1.0 / 60.0)
}

world.forEach(Transform2DComponent.self) { entity, t in
    if world.has(RigidBody2D.self, entity: entity) {
        let body = world.get(RigidBody2D.self, for: entity)!
        if body.bodyType == .dynamic {
            print("  Body \(entity.index) y=\(String(format: "%.2f", t.position.y))")
        }
    }
}
print("Physics sandbox completed.")
