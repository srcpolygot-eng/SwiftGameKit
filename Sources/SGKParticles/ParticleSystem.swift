import Foundation
import SGKMath
import SGKCore

public struct Particle: Sendable {
    public var position: Vector2
    public var velocity: Vector2
    public var acceleration: Vector2
    public var rotation: Float
    public var angularVelocity: Float
    public var scale: Float
    public var scaleVelocity: Float
    public var color: Vector4
    public var colorVelocity: Vector4
    public var lifetime: Float
    public var age: Float
    public var alive: Bool

    public init() {
        position = .zero
        velocity = .zero
        acceleration = .zero
        rotation = 0
        angularVelocity = 0
        scale = 1
        scaleVelocity = 0
        color = .one
        colorVelocity = .zero
        lifetime = 1
        age = 0
        alive = false
    }
}

public struct ParticleEmitterConfig: Sendable {
    public var emissionRate: Float = 50
    public var burstCount: Int = 0
    public var lifetime: ClosedRange<Float> = 0.5...2.0
    public var speed: ClosedRange<Float> = 50...150
    public var angle: ClosedRange<Float> = 0...(Math.twoPi)
    public var gravity: Vector2 = Vector2(0, -50)
    public var startScale: ClosedRange<Float> = 0.5...1.5
    public var endScale: Float = 0
    public var startColor: Vector4 = .one
    public var endColor: Vector4 = Vector4(1, 1, 1, 0)
    public var startRotation: ClosedRange<Float> = 0...0
    public var angularVelocity: ClosedRange<Float> = -2...2
    public var position: Vector2 = .zero
    public var positionVariance: Vector2 = .zero
    public var maxParticles: Int = 500

    public init() {}
}

public final class ParticleEmitter {
    public var config: ParticleEmitterConfig
    public private(set) var particles: [Particle]
    public var isEmitting = true
    private var emissionAccumulator: Float = 0
    private var rng = SeededRandom(seed: 42)

    public init(config: ParticleEmitterConfig = ParticleEmitterConfig()) {
        self.config = config
        self.particles = Array(repeating: Particle(), count: config.maxParticles)
    }

    public func burst(_ count: Int? = nil) {
        let n = count ?? config.burstCount
        for _ in 0..<n {
            spawn()
        }
    }

    public func update(deltaTime: Float) {
        if isEmitting {
            emissionAccumulator += config.emissionRate * deltaTime
            while emissionAccumulator >= 1 {
                spawn()
                emissionAccumulator -= 1
            }
        }

        for i in particles.indices {
            guard particles[i].alive else { continue }
            var p = particles[i]
            p.age += deltaTime
            if p.age >= p.lifetime {
                p.alive = false
                particles[i] = p
                continue
            }
            p.velocity += (p.acceleration + config.gravity) * deltaTime
            p.position += p.velocity * deltaTime
            p.rotation += p.angularVelocity * deltaTime
            p.scale += p.scaleVelocity * deltaTime
            p.color += p.colorVelocity * deltaTime
            particles[i] = p
        }
    }

    private func spawn() {
        guard let idx = particles.firstIndex(where: { !$0.alive }) else { return }
        var p = Particle()
        p.alive = true
        p.age = 0
        p.lifetime = rng.nextFloat(in: config.lifetime)
        p.position = config.position + Vector2(
            rng.nextFloat(in: -config.positionVariance.x...config.positionVariance.x),
            rng.nextFloat(in: -config.positionVariance.y...config.positionVariance.y)
        )
        let angle = rng.nextFloat(in: config.angle)
        let speed = rng.nextFloat(in: config.speed)
        p.velocity = Vector2(cos(angle) * speed, sin(angle) * speed)
        p.acceleration = .zero
        p.rotation = rng.nextFloat(in: config.startRotation)
        p.angularVelocity = rng.nextFloat(in: config.angularVelocity)
        p.scale = rng.nextFloat(in: config.startScale)
        p.scaleVelocity = (config.endScale - p.scale) / max(p.lifetime, .ulpOfOne)
        p.color = config.startColor
        p.colorVelocity = (config.endColor - config.startColor) * (1 / max(p.lifetime, .ulpOfOne))
        particles[idx] = p
    }

    public var aliveCount: Int {
        particles.filter(\.alive).count
    }
}
