import Foundation
import SwiftGameKit

print("=== Particle Sandbox ===")
var config = ParticleEmitterConfig()
config.emissionRate = 100
config.maxParticles = 500
config.lifetime = 0.5...1.5
config.speed = 30...120
config.gravity = Vector2(0, -80)
config.startColor = Vector4(1, 0.6, 0.1, 1)
config.endColor = Vector4(1, 0.1, 0, 0)

let emitter = ParticleEmitter(config: config)
emitter.burst(50)

for i in 0..<120 {
    emitter.update(deltaTime: 1.0 / 60.0)
    if i % 30 == 0 {
        print("  Frame \(i): alive=\(emitter.aliveCount)")
    }
}
print("Particle sandbox done. Final alive: \(emitter.aliveCount)")
