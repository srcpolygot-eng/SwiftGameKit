import XCTest
@testable import SwiftGameKit

final class FrameworkTests: XCTestCase {
    func testVersion() {
        XCTAssertEqual(SwiftGameKitInfo.version, "0.1.0")
    }

    func testPathfinding() {
        let grid = NavigationGrid(width: 10, height: 10)
        grid.setBlocked(5, 0)
        grid.setBlocked(5, 1)
        grid.setBlocked(5, 2)
        let path = Pathfinder.findPath(on: grid, from: GridNode(0, 0), to: GridNode(9, 0))
        XCTAssertNotNil(path)
        XCTAssertGreaterThan(path!.count, 2)
        XCTAssertEqual(path!.first, GridNode(0, 0))
        XCTAssertEqual(path!.last, GridNode(9, 0))
    }

    func testParticles() {
        var config = ParticleEmitterConfig()
        config.maxParticles = 100
        config.emissionRate = 50
        let emitter = ParticleEmitter(config: config)
        emitter.update(deltaTime: 0.1)
        XCTAssertGreaterThan(emitter.aliveCount, 0)
        for _ in 0..<100 {
            emitter.update(deltaTime: 0.05)
        }
        XCTAssertLessThanOrEqual(emitter.aliveCount, 100)
    }

    func testSaveLoad() throws {
        struct State: Codable {
            var score: Int
            var level: Int
        }
        let original = State(score: 42, level: 3)
        try SaveManager.save(original, slot: 99, name: "Test")
        XCTAssertTrue(SaveManager.exists(slot: 99))
        let loaded = try SaveManager.load(State.self, slot: 99)
        XCTAssertEqual(loaded.data.score, 42)
        XCTAssertEqual(loaded.data.level, 3)
        try SaveManager.delete(slot: 99)
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
        wait(for: [exp], timeout: 1)
        XCTAssertEqual(value, 100, accuracy: 1)
    }

    func testEventBus() {
        struct TestEvent: Event {
            let message: String
        }
        var received = ""
        let id = EventBus.shared.subscribe(TestEvent.self) { e in
            received = e.message
        }
        EventBus.shared.publish(TestEvent(message: "hello"))
        XCTAssertEqual(received, "hello")
        EventBus.shared.unsubscribe(id)
    }

    func testAnimationClip() {
        let clip = AnimationClip(name: "test", keyframes: [
            Keyframe(time: 0, value: Float(0)),
            Keyframe(time: 1, value: Float(10))
        ])
        XCTAssertEqual(clip.sample(at: 0.5)!, 5, accuracy: 1e-4)
    }

    func testAStarBlocked() {
        let grid = NavigationGrid(width: 3, height: 1)
        grid.setBlocked(1, 0)
        let path = Pathfinder.findPath(on: grid, from: GridNode(0, 0), to: GridNode(2, 0), allowDiagonal: false)
        XCTAssertNil(path)
    }
}
