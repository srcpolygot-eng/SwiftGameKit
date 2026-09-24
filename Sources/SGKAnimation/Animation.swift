import Foundation
import SGKMath
import SGKCore

public struct Keyframe<T> {
    public var time: Float
    public var value: T
    public var easing: Easing

    public init(time: Float, value: T, easing: Easing = .linear) {
        self.time = time
        self.value = value
        self.easing = easing
    }
}

public protocol Animatable {
    static func interpolate(_ a: Self, _ b: Self, t: Float) -> Self
}

extension Float: Animatable {
    public static func interpolate(_ a: Float, _ b: Float, t: Float) -> Float { Math.lerp(a, b, t: t) }
}
extension Vector2: Animatable {
    public static func interpolate(_ a: Vector2, _ b: Vector2, t: Float) -> Vector2 { a.lerp(to: b, t: t) }
}
extension Vector3: Animatable {
    public static func interpolate(_ a: Vector3, _ b: Vector3, t: Float) -> Vector3 { a.lerp(to: b, t: t) }
}
extension Vector4: Animatable {
    public static func interpolate(_ a: Vector4, _ b: Vector4, t: Float) -> Vector4 { a.lerp(to: b, t: t) }
}
extension Quaternion: Animatable {
    public static func interpolate(_ a: Quaternion, _ b: Quaternion, t: Float) -> Quaternion { a.slerp(to: b, t: t) }
}

public final class AnimationClip<T: Animatable> {
    public var name: String
    public var keyframes: [Keyframe<T>]
    public var duration: Float
    public var looped: Bool

    public init(name: String, keyframes: [Keyframe<T>], looped: Bool = false) {
        self.name = name
        self.keyframes = keyframes.sorted { $0.time < $1.time }
        self.duration = keyframes.map(\.time).max() ?? 0
        self.looped = looped
    }

    public func sample(at time: Float) -> T? {
        guard !keyframes.isEmpty else { return nil }
        var t = time
        if looped && duration > 0 {
            t = t.truncatingRemainder(dividingBy: duration)
            if t < 0 { t += duration }
        }
        if t <= keyframes[0].time { return keyframes[0].value }
        if t >= keyframes[keyframes.count - 1].time { return keyframes[keyframes.count - 1].value }

        for i in 0..<(keyframes.count - 1) {
            let k0 = keyframes[i]
            let k1 = keyframes[i + 1]
            if t >= k0.time && t <= k1.time {
                let local = (t - k0.time) / max(k1.time - k0.time, .ulpOfOne)
                let eased = k0.easing.evaluate(local)
                return T.interpolate(k0.value, k1.value, t: eased)
            }
        }
        return keyframes.last?.value
    }
}

public final class AnimationPlayer<T: Animatable> {
    public private(set) var clip: AnimationClip<T>?
    public private(set) var time: Float = 0
    public private(set) var isPlaying = false
    public var speed: Float = 1
    public var onComplete: (() -> Void)?

    public init() {}

    public func play(_ clip: AnimationClip<T>, fromStart: Bool = true) {
        self.clip = clip
        if fromStart { time = 0 }
        isPlaying = true
    }

    public func stop() {
        isPlaying = false
        time = 0
    }

    public func pause() { isPlaying = false }
    public func resume() { isPlaying = true }

    public func update(deltaTime: Float) -> T? {
        guard isPlaying, let clip = clip else { return clip?.sample(at: time) }
        time += deltaTime * speed
        if !clip.looped && time >= clip.duration {
            time = clip.duration
            isPlaying = false
            onComplete?()
        }
        return clip.sample(at: time)
    }
}

/// Sprite frame animation.
public struct SpriteAnimation: Sendable {
    public var name: String
    public var frames: [String] // texture / region ids
    public var frameDuration: Float
    public var looped: Bool

    public init(name: String, frames: [String], frameDuration: Float = 0.1, looped: Bool = true) {
        self.name = name
        self.frames = frames
        self.frameDuration = frameDuration
        self.looped = looped
    }

    public var duration: Float { Float(frames.count) * frameDuration }

    public func frame(at time: Float) -> String? {
        guard !frames.isEmpty else { return nil }
        var t = time
        if looped {
            t = t.truncatingRemainder(dividingBy: duration)
            if t < 0 { t += duration }
        } else if t >= duration {
            return frames.last
        }
        let index = min(Int(t / frameDuration), frames.count - 1)
        return frames[index]
    }
}

public final class SpriteAnimator {
    public private(set) var current: SpriteAnimation?
    public private(set) var time: Float = 0
    public private(set) var isPlaying = false
    public var speed: Float = 1

    public func play(_ anim: SpriteAnimation, fromStart: Bool = true) {
        current = anim
        if fromStart { time = 0 }
        isPlaying = true
    }

    public func update(deltaTime: Float) -> String? {
        guard isPlaying, let anim = current else { return current?.frame(at: time) }
        time += deltaTime * speed
        return anim.frame(at: time)
    }
}
