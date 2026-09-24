# SwiftGameKit Architecture (V2)

## Overview

SwiftGameKit is a modular Swift package. Each subsystem is a separate target so consumers can depend on only what they need.

```
Application
    │
    ▼
SwiftGameKit (umbrella)
    │
    ├── SGKCore          Game loop, time, logging, config, errors
    ├── SGKMath          Vectors, matrices, quaternions, noise helpers
    ├── SGKECS           Entities, components, systems, queries, command buffers
    ├── SGKScene         Scenes, transitions, lifecycle
    ├── SGKRendering     Renderer backend, materials, lights, tilemaps, meshes
    ├── SGKPhysics       2D rigid bodies, colliders, raycasts
    ├── SGKAnimation     Keyframes, sprites, skeletal, state machines
    ├── SGKAudio         Backends + buses
    ├── SGKInput         Raw input + InputMap contexts
    ├── SGKUI            Game UI widgets
    ├── SGKParticles     Emitters
    ├── SGKAssets        Handles & caches
    ├── SGKSerialization Save slots + migrations
    ├── SGKAI            Pathfinding, NavigationAgent, FSM
    ├── SGKNetworking    Packets & transport abstraction
    ├── SGKGameplay      Health, inventory, cooldowns, …
    ├── SGKUtilities     Tween, EventBus, Replay, Procedural
    ├── SGKDebugging     Overlay, console
    └── SGKProfiling     Hierarchical timers
```

## Data flow (typical frame)

1. **Input** → `InputSystem` / `InputMap` records state  
2. **Update** → ECS systems, gameplay, AI agents, tweens  
3. **Fixed update** → Physics step  
4. **Command buffers** flushed  
5. **Render** → Scene walks visible objects → `RenderBackend`  
6. **Audio** → bus-scaled playback  
7. **Debug / Profiler** sample  

## ECS design

- Sparse-set storage per component type  
- Entity generations prevent stale IDs  
- `Disabled` tag skips entities without destroying them  
- `CommandBuffer` defers structural changes until after system iteration  

## Platform boundaries

Platform-specific code (Metal, AVAudio, windowing) must live behind:

- `RenderBackend`
- `AudioBackend`
- optional window/event pump (not shipped in core)

Core modules remain pure Swift and testable on Linux.

## Extension points

- New components + systems  
- Custom `RenderBackend` / `AudioBackend`  
- `SaveMigrator` for game data versions  
- `InputContext` for mode-specific bindings  
- Script registration hooks (architecture only in V2)
