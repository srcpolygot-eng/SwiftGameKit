import Foundation
import SGKMath

public protocol GameDelegate: AnyObject {
    func gameDidInitialize(_ game: Game)
    func gameWillUpdate(_ game: Game, deltaTime: Double)
    func gameDidFixedUpdate(_ game: Game, fixedDeltaTime: Double)
    func gameWillRender(_ game: Game)
    func gameDidShutdown(_ game: Game)
}

public extension GameDelegate {
    func gameDidInitialize(_ game: Game) {}
    func gameWillUpdate(_ game: Game, deltaTime: Double) {}
    func gameDidFixedUpdate(_ game: Game, fixedDeltaTime: Double) {}
    func gameWillRender(_ game: Game) {}
    func gameDidShutdown(_ game: Game) {}
}

public enum GameState: Sendable {
    case uninitialized
    case running
    case paused
    case stopped
}

/// Core game runtime. Manages the main loop, timing, and lifecycle.
public final class Game {
    public private(set) var state: GameState = .uninitialized
    public var time = Time()
    public weak var delegate: GameDelegate?

    public var isRunning: Bool { state == .running }
    public var isPaused: Bool { state == .paused }

    public var onUpdate: ((Double) -> Void)?
    public var onFixedUpdate: ((Double) -> Void)?
    public var onRender: (() -> Void)?
    public var onShutdown: (() -> Void)?

    private var shouldStop = false
    private let runLoopLock = NSLock()

    public init() {}

    public func run() {
        runLoopLock.lock()
        guard state == .uninitialized || state == .stopped else {
            runLoopLock.unlock()
            Log.warning("Game is already running or paused")
            return
        }
        state = .running
        shouldStop = false
        runLoopLock.unlock()

        Log.info("Game starting")
        delegate?.gameDidInitialize(self)

        while true {
            runLoopLock.lock()
            let stop = shouldStop
            let paused = state == .paused
            runLoopLock.unlock()

            if stop { break }

            if paused {
                Thread.sleep(forTimeInterval: 0.01)
                continue
            }

            time.beginFrame()

            // Variable update
            delegate?.gameWillUpdate(self, deltaTime: time.deltaTime)
            onUpdate?(time.deltaTime)

            // Fixed updates
            let steps = time.consumeFixedSteps()
            for _ in 0..<steps {
                delegate?.gameDidFixedUpdate(self, fixedDeltaTime: time.fixedDeltaTime)
                onFixedUpdate?(time.fixedDeltaTime)
            }

            // Render
            delegate?.gameWillRender(self)
            onRender?()
        }

        Log.info("Game shutting down")
        delegate?.gameDidShutdown(self)
        onShutdown?()
        state = .stopped
    }

    public func stop() {
        runLoopLock.lock()
        shouldStop = true
        if state == .paused { state = .running } // allow exit
        runLoopLock.unlock()
    }

    public func pause() {
        runLoopLock.lock()
        if state == .running {
            state = .paused
            Log.debug("Game paused")
        }
        runLoopLock.unlock()
    }

    public func resume() {
        runLoopLock.lock()
        if state == .paused {
            state = .running
            Log.debug("Game resumed")
        }
        runLoopLock.unlock()
    }

    public var timeScale: Double {
        get { time.timeScale }
        set { time.timeScale = newValue }
    }
}

/// Convenience entry for simple games.
public func runGame(
    fixedDeltaTime: Double = 1.0 / 60.0,
    update: @escaping (Double) -> Void,
    fixedUpdate: ((Double) -> Void)? = nil,
    render: (() -> Void)? = nil
) {
    let game = Game()
    game.time.fixedDeltaTime = fixedDeltaTime
    game.onUpdate = update
    game.onFixedUpdate = fixedUpdate
    game.onRender = render
    game.run()
}
