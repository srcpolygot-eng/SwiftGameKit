import Foundation
import SGKMath
import SGKCore

/// A single bone in a skeleton.
public struct Bone: Sendable, Codable {
    public var name: String
    public var parentIndex: Int // -1 for root
    public var localBind: Transform

    public init(name: String, parentIndex: Int = -1, localBind: Transform = .identity) {
        self.name = name
        self.parentIndex = parentIndex
        self.localBind = localBind
    }
}

/// Hierarchy of bones.
public final class Skeleton: @unchecked Sendable {
    public let name: String
    public private(set) var bones: [Bone]
    public private(set) var bindPose: [Transform] // world-space bind

    public init(name: String, bones: [Bone]) {
        self.name = name
        self.bones = bones
        self.bindPose = Array(repeating: .identity, count: bones.count)
        recomputeBindPose()
    }

    public func recomputeBindPose() {
        bindPose = Array(repeating: .identity, count: bones.count)
        for i in bones.indices {
            let bone = bones[i]
            if bone.parentIndex >= 0 && bone.parentIndex < i {
                bindPose[i] = bindPose[bone.parentIndex] * bone.localBind
            } else {
                bindPose[i] = bone.localBind
            }
        }
    }

    public var boneCount: Int { bones.count }
}

/// Keyframe animation for a skeleton (per-bone local transforms).
public struct SkeletalClip: Sendable {
    public var name: String
    public var duration: Float
    public var looped: Bool
    /// times -> list of local transforms per bone
    public var samples: [(time: Float, poses: [Transform])]

    public init(name: String, duration: Float, looped: Bool = true, samples: [(time: Float, poses: [Transform])] = []) {
        self.name = name
        self.duration = duration
        self.looped = looped
        self.samples = samples.sorted { $0.time < $1.time }
    }

    public func sample(at time: Float, boneCount: Int) -> [Transform] {
        guard !samples.isEmpty else {
            return Array(repeating: .identity, count: boneCount)
        }
        var t = time
        if looped && duration > 0 {
            t = t.truncatingRemainder(dividingBy: duration)
            if t < 0 { t += duration }
        }
        if t <= samples[0].time { return pad(samples[0].poses, boneCount) }
        if t >= samples[samples.count - 1].time { return pad(samples[samples.count - 1].poses, boneCount) }

        for i in 0..<(samples.count - 1) {
            let a = samples[i]
            let b = samples[i + 1]
            if t >= a.time && t <= b.time {
                let local = (t - a.time) / max(b.time - a.time, .ulpOfOne)
                return zip(pad(a.poses, boneCount), pad(b.poses, boneCount)).map { pa, pb in
                    Transform(
                        position: pa.position.lerp(to: pb.position, t: local),
                        rotation: pa.rotation.slerp(to: pb.rotation, t: local),
                        scale: pa.scale.lerp(to: pb.scale, t: local)
                    )
                }
            }
        }
        return pad(samples.last!.poses, boneCount)
    }

    private func pad(_ poses: [Transform], _ count: Int) -> [Transform] {
        if poses.count >= count { return Array(poses.prefix(count)) }
        return poses + Array(repeating: .identity, count: count - poses.count)
    }
}

public enum AnimationStateID: Hashable, Sendable {
    case idle
    case walking
    case running
    case jumping
    case custom(String)
}

/// Simple animation state machine for skeletal clips.
public final class AnimationStateMachine {
    public private(set) var current: AnimationStateID = .idle
    public private(set) var time: Float = 0
    private var clips: [AnimationStateID: SkeletalClip] = [:]
    private var transitions: [AnimationStateID: AnimationStateID] = [:]
    public var skeleton: Skeleton?
    public var onStateChanged: ((AnimationStateID, AnimationStateID) -> Void)?

    public func register(_ state: AnimationStateID, clip: SkeletalClip) {
        clips[state] = clip
    }

    public func setTransition(from: AnimationStateID, to: AnimationStateID) {
        transitions[from] = to
    }

    public func transition(to state: AnimationStateID) {
        let previous = current
        current = state
        time = 0
        onStateChanged?(previous, state)
    }

    public func update(deltaTime: Float) -> [Transform]? {
        guard let clip = clips[current], let skeleton else { return nil }
        time += deltaTime
        return clip.sample(at: time, boneCount: skeleton.boneCount)
    }
}
