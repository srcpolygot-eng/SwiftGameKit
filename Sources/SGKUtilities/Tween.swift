import Foundation
import SGKMath

public final class Tween {
    public private(set) var isRunning = false
    public private(set) var isCompleted = false

    private var duration: Float = 0
    private var elapsed: Float = 0
    private var delay: Float = 0
    private var easing: Easing = .linear
    private var onUpdate: ((Float) -> Void)?
    private var onComplete: (() -> Void)?
    private var from: Float = 0
    private var to: Float = 1

    public init() {}

    @discardableResult
    public func from(_ value: Float) -> Tween {
        from = value
        return self
    }

    @discardableResult
    public func to(_ value: Float) -> Tween {
        to = value
        return self
    }

    @discardableResult
    public func duration(_ d: Float) -> Tween {
        duration = max(0, d)
        return self
    }

    @discardableResult
    public func delay(_ d: Float) -> Tween {
        delay = max(0, d)
        return self
    }

    @discardableResult
    public func ease(_ e: Easing) -> Tween {
        easing = e
        return self
    }

    @discardableResult
    public func onUpdate(_ handler: @escaping (Float) -> Void) -> Tween {
        onUpdate = handler
        return self
    }

    @discardableResult
    public func onComplete(_ handler: @escaping () -> Void) -> Tween {
        onComplete = handler
        return self
    }

    public func start() {
        elapsed = 0
        isRunning = true
        isCompleted = false
        TweenManager.shared.add(self)
    }

    public func stop() {
        isRunning = false
        TweenManager.shared.remove(self)
    }

    fileprivate func update(dt: Float) {
        guard isRunning else { return }
        if delay > 0 {
            delay -= dt
            return
        }
        elapsed += dt
        let t = duration > 0 ? min(1, elapsed / duration) : 1
        let eased = easing.evaluate(t)
        let value = Math.lerp(from, to, t: eased)
        onUpdate?(value)
        if t >= 1 {
            isRunning = false
            isCompleted = true
            onComplete?()
            TweenManager.shared.remove(self)
        }
    }
}

public final class TweenManager {
    public static let shared = TweenManager()
    private var tweens: [Tween] = []
    private let lock = NSLock()

    private init() {}

    fileprivate func add(_ tween: Tween) {
        lock.lock()
        tweens.append(tween)
        lock.unlock()
    }

    fileprivate func remove(_ tween: Tween) {
        lock.lock()
        tweens.removeAll { $0 === tween }
        lock.unlock()
    }

    public func update(deltaTime: Float) {
        lock.lock()
        let copy = tweens
        lock.unlock()
        for t in copy {
            t.update(dt: deltaTime)
        }
    }

    public func clear() {
        lock.lock()
        tweens.removeAll()
        lock.unlock()
    }
}

// Convenience builders
public func Tween(_ target: AnyObject? = nil) -> Tween {
    Tween()
}

extension Tween {
    public func move(to point: Vector2, duration: Float) -> Tween {
        // Caller supplies onUpdate to apply position
        self.duration(duration)
        return self
    }
}
