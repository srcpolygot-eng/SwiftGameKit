import XCTest
@testable import SwiftGameKit

final class V2Tests: XCTestCase {
    func testQueryExcluding() {
        let world = World()
        let a = world.createEntity()
        let b = world.createEntity()
        world.add(Health(current: 10), to: a)
        world.add(Transform2DComponent(), to: a)
        world.add(Health(current: 20), to: b)
        world.add(Transform2DComponent(), to: b)
        world.add(Disabled(), to: b)

        let results = world.query(Health.self, Transform2DComponent.self, excluding: [Disabled.self])
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].entity, a)
    }

    func testEnableDisable() {
        let world = World()
        let e = world.createEntity()
        XCTAssertTrue(world.isEnabled(e))
        world.setEnabled(e, false)
        XCTAssertFalse(world.isEnabled(e))
        world.setEnabled(e, true)
        XCTAssertTrue(world.isEnabled(e))
    }

    func testNavigationAgent() {
        let grid = NavigationGrid(width: 15, height: 15)
        let agent = NavigationAgent(position: Vector2(1, 1), speed: 5)
        XCTAssertTrue(agent.setDestination(GridNode(10, 10), on: grid))
        XCTAssertTrue(agent.hasPath)
        for _ in 0..<200 {
            _ = agent.update(deltaTime: 0.1)
        }
        XCTAssertTrue(agent.isStopped || agent.remainingDistance < 1)
    }

    func testValueNoiseDeterministic() {
        let n1 = ValueNoise(seed: 99)
        let n2 = ValueNoise(seed: 99)
        XCTAssertEqual(n1.noise(1.5, 2.5), n2.noise(1.5, 2.5), accuracy: 1e-5)
    }

    func testCellularAutomata() {
        let grid = CellularAutomata.generate(width: 20, height: 20, seed: 7, steps: 3)
        XCTAssertEqual(grid.count, 20)
        XCTAssertEqual(grid[0].count, 20)
    }

    func testReplayRoundtrip() {
        let recorder = ReplayRecorder()
        recorder.begin(seed: 123)
        recorder.record(frame: 0, actions: ["jump": true])
        recorder.record(frame: 1, actions: ["jump": false], axes: ["move": 0.5])
        let (meta, frames) = recorder.stop()
        XCTAssertEqual(frames.count, 2)
        XCTAssertEqual(meta.initialSeed, 123)

        let player = ReplayPlayer()
        player.load(metadata: meta, frames: frames)
        player.play()
        let f0 = player.nextFrame()
        XCTAssertEqual(f0?.actions["jump"], true)
    }

    func testInputMap() {
        let map = InputMap.shared
        map.setActiveContext("gameplay")
        // Without real key events, just verify structure
        XCTAssertNotNil(map.activeContext)
        XCTAssertNotNil(map.activeContext?.actions["jump"])
    }

    func testMaterialInstance() {
        let def = MaterialDefinition.standard
        let inst = MaterialInstance(definition: def)
        inst.set("albedo", .color(Vector4(1, 0, 0, 1)))
        if case .color(let c) = inst.parameter("albedo") {
            XCTAssertEqual(c.x, 1, accuracy: 1e-5)
        } else {
            XCTFail("Expected color")
        }
    }

    func testSkeleton() {
        let bones = [
            Bone(name: "root"),
            Bone(name: "spine", parentIndex: 0, localBind: Transform(position: Vector3(0, 1, 0))),
            Bone(name: "head", parentIndex: 1, localBind: Transform(position: Vector3(0, 0.5, 0)))
        ]
        let sk = Skeleton(name: "humanoid", bones: bones)
        XCTAssertEqual(sk.boneCount, 3)
        XCTAssertEqual(sk.bindPose[2].position.y, 1.5, accuracy: 1e-4)
    }

    func testTileMap() {
        let set = TileSet(name: "terrain", tileWidth: 16, tileHeight: 16, textureID: "tiles", tileCount: 64, columns: 8)
        let map = TileMap(name: "level1", tileSet: set)
        let layer = TileLayer(name: "ground", width: 10, height: 8)
        layer.setTile(3, at: 2, y: 1)
        map.addLayer(layer)
        XCTAssertEqual(map.layers[0].tile(at: 2, y: 1), 3)
    }

    func testAudioBuses() {
        let mgr = AudioManager.shared
        mgr.master.volume = 0.5
        mgr.sfx.volume = 0.8
        XCTAssertEqual(mgr.sfx.effectiveVolume, 0.8, accuracy: 1e-5)
        mgr.sfx.isMuted = true
        XCTAssertEqual(mgr.sfx.effectiveVolume, 0)
    }

    func testProcRooms() {
        let rooms = ProcGen.generateRooms(mapWidth: 40, mapHeight: 30, roomCount: 8, seed: 42)
        XCTAssertFalse(rooms.isEmpty)
        XCTAssertLessThanOrEqual(rooms.count, 8)
    }
}
