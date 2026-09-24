import Foundation
import SGKCore
import SGKMath

public protocol AudioBackend: AnyObject {
    func playSound(id: String, volume: Float, loop: Bool) -> AudioHandle
    func playMusic(id: String, volume: Float, loop: Bool) -> AudioHandle
    func stop(_ handle: AudioHandle)
    func setVolume(_ handle: AudioHandle, volume: Float)
    func pause(_ handle: AudioHandle)
    func resume(_ handle: AudioHandle)
    func setMasterVolume(_ volume: Float)
}

public struct AudioHandle: Hashable, Sendable {
    public let id: UInt64
    public init(_ id: UInt64) { self.id = id }
    public static let invalid = AudioHandle(0)
}

/// Software / stub backend for platforms without native audio or headless.
public final class NullAudioBackend: AudioBackend {
    private var nextID: UInt64 = 1
    public init() {}
    public func playSound(id: String, volume: Float, loop: Bool) -> AudioHandle {
        Log.debug("NullAudio: playSound \(id)")
        let h = AudioHandle(nextID); nextID += 1; return h
    }
    public func playMusic(id: String, volume: Float, loop: Bool) -> AudioHandle {
        Log.debug("NullAudio: playMusic \(id)")
        let h = AudioHandle(nextID); nextID += 1; return h
    }
    public func stop(_ handle: AudioHandle) {}
    public func setVolume(_ handle: AudioHandle, volume: Float) {}
    public func pause(_ handle: AudioHandle) {}
    public func resume(_ handle: AudioHandle) {}
    public func setMasterVolume(_ volume: Float) {}
}

public enum Audio {
    public static var backend: AudioBackend = NullAudioBackend()
    public static var masterVolume: Float = 1 {
        didSet { backend.setMasterVolume(masterVolume) }
    }
    public static var musicVolume: Float = 0.8
    public static var sfxVolume: Float = 1.0

    @discardableResult
    public static func play(_ id: String, volume: Float = 1, loop: Bool = false) -> AudioHandle {
        backend.playSound(id: id, volume: volume * sfxVolume * masterVolume, loop: loop)
    }

    public static let music = MusicController()

    public final class MusicController {
        private var current: AudioHandle = .invalid
        public func play(_ id: String, volume: Float = 1, loop: Bool = true) {
            if current != .invalid { Audio.backend.stop(current) }
            current = Audio.backend.playMusic(id: id, volume: volume * Audio.musicVolume * Audio.masterVolume, loop: loop)
        }
        public func stop() {
            Audio.backend.stop(current)
            current = .invalid
        }
        public func pause() { Audio.backend.pause(current) }
        public func resume() { Audio.backend.resume(current) }
    }
}

// MARK: - V2 Audio Buses

public final class AudioBus {
    public let name: String
    public var volume: Float = 1.0 {
        didSet { volume = max(0, min(1, volume)) }
    }
    public var isMuted: Bool = false

    public init(name: String, volume: Float = 1) {
        self.name = name
        self.volume = volume
    }

    public var effectiveVolume: Float {
        isMuted ? 0 : volume
    }
}

public final class AudioManager {
    public static let shared = AudioManager()

    public let master = AudioBus(name: "master")
    public let music = AudioBus(name: "music", volume: 0.8)
    public let sfx = AudioBus(name: "sfx")
    public let ambient = AudioBus(name: "ambient", volume: 0.6)
    public let voice = AudioBus(name: "voice")

    public private(set) var buses: [String: AudioBus] = [:]

    private init() {
        buses["master"] = master
        buses["music"] = music
        buses["sfx"] = sfx
        buses["ambient"] = ambient
        buses["voice"] = voice
    }

    public func bus(_ name: String) -> AudioBus {
        if let b = buses[name] { return b }
        let b = AudioBus(name: name)
        buses[name] = b
        return b
    }

    public func playSFX(_ id: String, volume: Float = 1) -> AudioHandle {
        let v = volume * sfx.effectiveVolume * master.effectiveVolume
        return Audio.backend.playSound(id: id, volume: v, loop: false)
    }

    public func playMusic(_ id: String, volume: Float = 1, loop: Bool = true) -> AudioHandle {
        let v = volume * music.effectiveVolume * master.effectiveVolume
        return Audio.backend.playMusic(id: id, volume: v, loop: loop)
    }

    public func fadeBus(_ name: String, to target: Float, duration: Float) {
        // Simple immediate set for V2 foundation; full fade can use Tween
        bus(name).volume = target
        Log.debug("AudioBus \(name) -> \(target)")
    }
}
