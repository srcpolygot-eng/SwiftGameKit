import XCTest
@testable import SwiftGameKit

final class FrameworkTests: XCTestCase {
    func testVersion() {
        XCTAssertEqual(SwiftGameKitInfo.version, "2.0.0")
    }

    func testPathfinding() {
        let grid = NavigationGrid(width: 10, height: 10)
        grid.setBlocked(5, 0)
        grid.setBlocked(5, 1)
        grid.setBlocked(5, 2)
        let path = Pathfinder.findPath(on: grid, from: GridNode(0, 0), to: GridNode(9, 0))
        XCTAssertNotNil(path)
        XCTAssertGreaterThan(path!.count, 0)
    }

    func testAStarBlocked() {
        let grid = NavigationGrid(width: 5, height: 5)
        for y in 0..<5 { grid.setBlocked(2, y) }
        let path = Pathfinder.findPath(on: grid, from: GridNode(0, 2), to: GridNode(4, 2), allowDiagonal: false)
        XCTAssertNil(path)
    }

    func testPhysicsStep() {
        let world = World()
        let e = world.createEntity()
        world.add(Transform2DComponent(local: Transform2D(position: Vector2(0, 10))), to: e)
        world.add(RigidBody2D(bodyType: .dynamic, mass: 1), to: e)
        world.add(Collider2D(shape: .circle(radius: 0.5)), to: e)

        let physics = PhysicsWorld2D()
        physics.gravity = Vector2(0, -10)
        physics.step(world: world, dt: 0.1)

        let t = world.get(Transform2DComponent.self, for: e)
        XCTAssertNotNil(t)
        XCTAssertLessThan(t!.position.y, 10)
    }

    func testParticles() {
        var config = ParticleEmitterConfig()
        config.maxParticles = 10
        config.emissionRate = 100
        let emitter = ParticleEmitter(config: config)
        emitter.position = Vector2(0, 0)
        for _ in 0..<10 {
            emitter.update(deltaTime: 0.016)
        }
        XCTAssertGreaterThan(emitter.aliveCount, 0)
    }

    func testSaveLoad() throws {
        struct Payload: Codable { var score: Int }
        try SaveManager.save(Payload(score: 42), slot: 99, name: "test")
        let (meta, data) = try SaveManager.load(Payload.self, slot: 99)
        XCTAssertEqual(data.score, 42)
        XCTAssertEqual(meta.slot, 99)
        try SaveManager.delete(slot: 99)
    }

    func testTween() {
        let exp = expectation(description: "tween complete")
        var value: Float = 0
        Tween()
            .from(0)
            .to(100)
            .duration(0.05)
            .onUpdate { value = $0 }
            .onComplete { exp.fulfill() }
            .start()
        for _ in 0..<10 {
            TweenManager.shared.update(deltaTime: 0.01)
        }
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(value, 100, accuracy: 0.1)
    }

    func testEventBus() {
        struct Ping: Event { let n: Int }
        var received = 0
        let id = EventBus.shared.subscribe(Ping.self) { received = $0.n }
        EventBus.shared.publish(Ping(n: 7))
        XCTAssertEqual(received, 7)
        EventBus.shared.unsubscribe(id)
    }

    func testAnimationClip() {
        var clip = AnimationClip<Float>(name: "test")
        clip.addKey(time: 0, value: 0)
        clip.addKey(time: 1, value: 10)
        XCTAssertEqual(clip.sample(at: 0.5), 5, accuracy: 0.01)
    }
}
