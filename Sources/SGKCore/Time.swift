import Foundation

/// High-resolution timing utilities.
public struct Time: Sendable {
    public private(set) var deltaTime: Double = 0
    public private(set) var unscaledDeltaTime: Double = 0
    public private(set) var fixedDeltaTime: Double = 1.0 / 60.0
    public private(set) var time: Double = 0
    public private(set) var unscaledTime: Double = 0
    public private(set) var frameCount: UInt64 = 0
    public private(set) var fixedFrameCount: UInt64 = 0

    public var timeScale: Double = 1.0 {
        didSet {
            if timeScale < 0 { timeScale = 0 }
        }
    }

    public var targetFrameRate: Double? = 60
    public var maximumDeltaTime: Double = 0.25

    private var lastFrameTime: Double = 0
    private var accumulator: Double = 0
    private var isFirstFrame = true

    public init(fixedDeltaTime: Double = 1.0 / 60.0) {
        self.fixedDeltaTime = fixedDeltaTime
    }

    public mutating func beginFrame() {
        let now = Time.now()
        if isFirstFrame {
            lastFrameTime = now
            isFirstFrame = false
            unscaledDeltaTime = 0
            deltaTime = 0
            return
        }

        var rawDelta = now - lastFrameTime
        lastFrameTime = now

        if let target = targetFrameRate, target > 0 {
            let minDelta = 1.0 / target
            if rawDelta < minDelta {
                let sleepTime = minDelta - rawDelta
                if sleepTime > 0.0005 {
                    Thread.sleep(forTimeInterval: sleepTime)
                    let after = Time.now()
                    rawDelta = after - (now - rawDelta)
                    lastFrameTime = after
                }
            }
        }

        unscaledDeltaTime = min(rawDelta, maximumDeltaTime)
        deltaTime = unscaledDeltaTime * timeScale
        time += deltaTime
        unscaledTime += unscaledDeltaTime
        frameCount += 1
        accumulator += deltaTime
    }

    public mutating func consumeFixedSteps() -> Int {
        var steps = 0
        let maxSteps = 8
        while accumulator >= fixedDeltaTime && steps < maxSteps {
            accumulator -= fixedDeltaTime
            fixedFrameCount += 1
            steps += 1
        }
        // Prevent spiral of death
        if steps >= maxSteps {
            accumulator = 0
        }
        return steps
    }

    public var alpha: Double {
        guard fixedDeltaTime > 0 else { return 0 }
        return accumulator / fixedDeltaTime
    }

    public static func now() -> Double {
        ProcessInfo.processInfo.systemUptime
    }

    public static func highResolutionNow() -> UInt64 {
        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
        return mach_absolute_time()
        #else
        var ts = timespec()
        clock_gettime(CLOCK_MONOTONIC, &ts)
        return UInt64(ts.tv_sec) * 1_000_000_000 + UInt64(ts.tv_nsec)
        #endif
    }
}

#if os(Linux)
import Glibc
#endif
