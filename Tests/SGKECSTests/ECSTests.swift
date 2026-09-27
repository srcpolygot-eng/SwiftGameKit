import XCTest
@testable import SGKECS
@testable import SGKMath

final class ECSTests: XCTestCase {
    func testEntityLifecycle() {
        let world = World()
        let e1 = world.createEntity()
        let e2 = world.createEntity()
        XCTAssertTrue(world.isAlive(e1))
        XCTAssertTrue(world.isAlive(e2))
        XCTAssertEqual(world.entityCount, 2)
        world.destroyEntity(e1)
        XCTAssertFalse(world.isAlive(e1))
        XCTAssertEqual(world.entityCount, 1)
        let e3 = world.createEntity()
        XCTAssertTrue(world.isAlive(e3))
        XCTAssertEqual(world.entityCount, 2)
    }

    func testComponents() {
        let world = World()
        let e = world.createEntity()
        world.add(Health(current: 100), to: e)
        world.add(TransformComponent(local: Transform(position: Vector3(1, 2, 3))), to: e)
        XCTAssertTrue(world.has(Health.self, entity: e))
        XCTAssertEqual(world.get(Health.self, for: e)?.current, 100)
        XCTAssertEqual(world.get(TransformComponent.self, for: e)?.position.x, 1)
        world.remove(Health.self, from: e)
        XCTAssertFalse(world.has(Health.self, entity: e))
    }

    func testQuery() {
        let world = World()
        for i in 0..<10 {
            let e = world.createEntity()
            world.add(Health(current: Float(i * 10)), to: e)
        }
        var sum: Float = 0
        world.forEach(Health.self) { _, h in
            sum += h.current
        }
        XCTAssertEqual(sum, 450, accuracy: 1e-3)
        XCTAssertEqual(world.componentCount(Health.self), 10)
    }

    func testSystem() {
        let world = World()
        let e = world.createEntity()
        // maximum must exceed current or heal() is capped
        world.add(Health(current: 50, maximum: 100), to: e)
        world.forEach(Health.self) { _, h in
            h.heal(10)
        }
        let health = world.get(Health.self, for: e)?.current
        XCTAssertEqual(health ?? 0, 60, accuracy: 0.001)

        final class NoopSystem: System {
            var ran = false
            func update(_ world: World, deltaTime: Double) {
                ran = true
            }
        }
        let sys = NoopSystem()
        world.addSystem(sys)
        world.updateSystems(deltaTime: 0.016)
        XCTAssertTrue(sys.ran)
    }
}
