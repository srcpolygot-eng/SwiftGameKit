# SwiftGameKit

**Version 2.0.0** — Major expansion of the Swift-native game framework.

See [CHANGELOG.md](CHANGELOG.md) and [Documentation/ARCHITECTURE.md](Documentation/ARCHITECTURE.md).

---


**SwiftGameKit** is a modular, Swift-native game development framework designed as a foundation for 2D games, 3D scenes, simulations, tools, and larger projects.

Version: **2.0.0** (V1 foundation)

## Vision

SwiftGameKit aims to provide a reusable ecosystem similar in spirit to a lightweight combination of:

- Game runtime & loop
- Entity Component System (ECS)
- 2D & 3D scene / transform systems
- Physics abstraction
- Animation & tweening
- Particle systems
- Audio & input abstractions
- UI toolkit for games
- AI utilities (FSM, A* pathfinding)
- Asset management & serialization
- Debugging, profiling, and developer console
- Networking foundation
- Gameplay utilities (health, inventory, cooldowns, etc.)

It is **not** a wrapper around Unity, Unreal, Godot, or SpriteKit. It is a first-party Swift architecture that can integrate with platform graphics APIs (Metal, etc.) on Apple platforms.

## Architecture

```
SwiftGameKit/
├── Package.swift
├── Sources/
│   ├── SGKMath/          # Vectors, matrices, quaternions, transforms, easing, RNG
│   ├── SGKCore/          # Game loop, time, logging, config, errors
│   ├── SGKECS/           # Entity Component System
│   ├── SGKScene/         # Scenes & transitions
│   ├── SGKRendering/     # Renderer abstraction, materials, meshes
│   ├── SGKPhysics/       # 2D physics (software)
│   ├── SGKAnimation/     # Keyframe & sprite animation
│   ├── SGKAudio/         # Audio abstraction
│   ├── SGKInput/         # Unified input + action mapping
│   ├── SGKUI/            # Game UI (labels, buttons, bars, panels)
│   ├── SGKParticles/     # Configurable particle emitter
│   ├── SGKAssets/        # Asset loading & caching
│   ├── SGKSerialization/ # Save/load with versioning
│   ├── SGKDebugging/     # FPS, console, overlays
│   ├── SGKProfiling/     # Scoped timers & reports
│   ├── SGKUtilities/     # Tween, EventBus
│   ├── SGKAI/            # A*, FSM
│   ├── SGKNetworking/    # Packet & transport abstraction
│   ├── SGKGameplay/      # Health, inventory, cooldowns, etc.
│   └── SwiftGameKit/     # Umbrella re-export
├── Tests/
├── Examples/
└── Documentation/
```

Modules are independent; you can depend only on what you need.

## Quick Start

```swift
import SwiftGameKit

let game = Game()
game.onUpdate = { dt in
    // your update logic
}
game.onRender = {
    // your render logic
}
game.run()
```

Or with ECS:

```swift
let world = World()
let player = world.createEntity()
world.add(Health(current: 100), to: player)
world.add(Transform2DComponent(local: .init(position: Vector2(100, 200))), to: player)

struct MovementSystem: System {
    func update(_ world: World, deltaTime: Double) {
        world.forEach(Velocity2D.self) { entity, vel in
            if var t = world.get(Transform2DComponent.self, for: entity) {
                t.position += vel.linear * Float(deltaTime)
                world.add(t, to: entity)
            }
        }
    }
}
world.addSystem(MovementSystem())
```

## Building & Testing

Requires Swift 5.9+ / 6.x.

```bash
cd SwiftGameKit
swift build
swift test
swift run PlatformerExample
swift run AIPathfindingDemo
swift run ParticleSandbox
swift run PhysicsSandbox
swift run Simple3DExample
swift run UIDemo
swift run AudioDemo
swift run TopDownExample
```

## Platform Notes

- Developed and verified primarily on Linux (Swift 6.4) for core logic, math, ECS, physics, pathfinding, particles, serialization, etc.
- Graphics/audio backends are abstracted. On Linux/headless, `NullRenderBackend` and `NullAudioBackend` are used.
- On Apple platforms, you can implement Metal / AVAudioEngine backends against the same interfaces.
- macOS / iOS / tvOS / watchOS platform declarations are present in `Package.swift`.

## What is Implemented in V1

| System              | Status                                      |
|---------------------|---------------------------------------------|
| Math (Vec/Mat/Quat) | Full, tested                                |
| Game loop & Time    | Full (fixed + variable timestep)            |
| ECS                 | Sparse-set style, systems, queries, tested  |
| Scene manager       | Transitions (fade/crossfade/instant)        |
| 2D Physics          | Circles/boxes, integration, raycast, tested |
| Animation           | Keyframes, sprite frames, players           |
| Particles           | Emitter with pooling, tested                |
| Audio               | Abstraction + null backend                  |
| Input               | Keyboard/mouse action mapping               |
| UI                  | Views, labels, buttons, progress bars       |
| Rendering           | Abstraction + null backend + mesh helpers   |
| Assets              | Texture/sound cache                         |
| Save system         | Codable JSON slots + metadata, tested       |
| Debugging           | FPS, console commands                       |
| Profiling           | Scoped measure & reports                    |
| Tween / Events      | Full, tested                                |
| AI / Pathfinding    | A* grid + FSM, tested                       |
| Networking          | Packet envelope + in-memory transport       |
| Gameplay helpers    | Health, inventory, cooldown, score, team    |
| Examples            | 8 runnable demos                            |
| Tests               | Math, ECS, Core, Framework integration      |

## Known Limitations

- No real GPU backend (Metal/Vulkan) in this repository yet — rendering is abstract + null.
- 2D physics is educational/O(n²); no broadphase spatial hash in V1.
- 3D physics not implemented.
- Networking is architectural foundation only (no real sockets / NAT traversal).
- Platform windowing / event pump not included (integrate with your app lifecycle).
- Some advanced features (skeletal animation, behavior trees, full replication) are stubs or future work.

## License

Apache 2.0 / MIT dual-license friendly for game use. (Add preferred license file for your project.)

## Contributing

Build the actual systems. Prefer real implementations and tests over placeholders.
