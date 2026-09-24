import Foundation
import SGKCore
import SGKMath

/// Recorded input snapshot for a single frame.
public struct ReplayFrame: Codable, Sendable {
    public var frame: UInt64
    public var time: Double
    public var seed: UInt64?
    public var actions: [String: Bool] // action name -> pressed
    public var axes: [String: Float]
    public var customEvents: [String]

    public init(frame: UInt64, time: Double, seed: UInt64? = nil, actions: [String: Bool] = [:], axes: [String: Float] = [:], customEvents: [String] = []) {
        self.frame = frame
        self.time = time
        self.seed = seed
        self.actions = actions
        self.axes = axes
        self.customEvents = customEvents
    }
}

public struct ReplayMetadata: Codable, Sendable {
    public var version: Int
    public var name: String
    public var recordedAt: Date
    public var frameCount: Int
    public var duration: Double
    public var initialSeed: UInt64

    public init(version: Int = 1, name: String, frameCount: Int, duration: Double, initialSeed: UInt64) {
        self.version = version
        self.name = name
        self.recordedAt = Date()
        self.frameCount = frameCount
        self.duration = duration
        self.initialSeed = initialSeed
    }
}

public final class ReplayRecorder {
    public private(set) var frames: [ReplayFrame] = []
    public var initialSeed: UInt64 = 0
    public private(set) var isRecording = false
    private var startTime: Double = 0

    public func begin(seed: UInt64 = 0) {
        frames = []
        initialSeed = seed
        startTime = Time.now()
        isRecording = true
        Log.info("Replay recording started (seed=\(seed))")
    }

    public func record(frame: UInt64, actions: [String: Bool] = [:], axes: [String: Float] = [:], events: [String] = []) {
        guard isRecording else { return }
        let t = Time.now() - startTime
        frames.append(ReplayFrame(frame: frame, time: t, seed: nil, actions: actions, axes: axes, customEvents: events))
    }

    public func stop() -> (metadata: ReplayMetadata, frames: [ReplayFrame]) {
        isRecording = false
        let duration = frames.last?.time ?? 0
        let meta = ReplayMetadata(name: "replay", frameCount: frames.count, duration: duration, initialSeed: initialSeed)
        Log.info("Replay stopped: \(frames.count) frames, \(String(format: "%.2f", duration))s")
        return (meta, frames)
    }
}

public final class ReplayPlayer {
    public private(set) var frames: [ReplayFrame] = []
    public private(set) var metadata: ReplayMetadata?
    public private(set) var isPlaying = false
    public private(set) var currentIndex = 0

    public func load(metadata: ReplayMetadata, frames: [ReplayFrame]) {
        self.metadata = metadata
        self.frames = frames
        currentIndex = 0
        isPlaying = false
    }

    public func play() {
        guard !frames.isEmpty else { return }
        isPlaying = true
        currentIndex = 0
        if let seed = metadata?.initialSeed {
            Random.seed(seed)
        }
    }

    public func pause() { isPlaying = false }
    public func resume() { isPlaying = true }

    public func seek(to frameIndex: Int) {
        currentIndex = max(0, min(frameIndex, frames.count - 1))
    }

    /// Returns the frame for the current index and advances if playing.
    public func nextFrame() -> ReplayFrame? {
        guard currentIndex < frames.count else {
            isPlaying = false
            return nil
        }
        let f = frames[currentIndex]
        if isPlaying { currentIndex += 1 }
        return f
    }

    public var progress: Float {
        guard !frames.isEmpty else { return 0 }
        return Float(currentIndex) / Float(frames.count)
    }
}
