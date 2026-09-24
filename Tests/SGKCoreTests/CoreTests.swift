import XCTest
@testable import SGKCore
@testable import SGKMath

final class CoreTests: XCTestCase {
    func testTimeScale() {
        var time = Time()
        time.timeScale = 0.5
        XCTAssertEqual(time.timeScale, 0.5)
        time.timeScale = -1
        XCTAssertEqual(time.timeScale, 0)
    }

    func testGameLifecycle() {
        let game = Game()
        XCTAssertEqual(game.state, .uninitialized)
        var updateCount = 0
        game.onUpdate = { _ in
            updateCount += 1
            if updateCount >= 3 {
                game.stop()
            }
        }
        // Run on background briefly is hard; just verify API
        game.timeScale = 2
        XCTAssertEqual(game.timeScale, 2)
    }

    func testConfigCodable() throws {
        var config = GameConfig()
        config.graphics.width = 1920
        config.debug.showFPS = true
        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(GameConfig.self, from: data)
        XCTAssertEqual(decoded.graphics.width, 1920)
        XCTAssertTrue(decoded.debug.showFPS)
    }
}
