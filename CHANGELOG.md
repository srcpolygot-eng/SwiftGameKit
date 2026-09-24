# Changelog

## [2.0.0] - 2026-09-24 — SwiftGameKit V2 Major Expansion

### Added
- **Advanced ECS**: Query filters with exclusion, `Disabled` / `Changed` tags, entity enable/disable, `CommandBuffer` for deferred operations
- **NavigationAgent**: Path following, steering helpers (seek/arrive/flee)
- **Material system**: `MaterialDefinition`, `MaterialInstance`, parameter types, standard/unlit defaults
- **Lighting architecture**: Directional, point, spot, ambient light descriptors
- **Skeletal animation**: Bones, Skeleton, SkeletalClip, AnimationStateMachine
- **Tilemap & SpriteAtlas**: Tile layers, tile sets, atlas regions
- **InputMap**: Named contexts, multiple bindings, action evaluation, dead zones
- **Replay system**: Recorder + Player with metadata, seeking, deterministic seed restore
- **Procedural generation**: Value noise / FBM, cellular automata caves, room placement
- **Audio buses**: Master, music, SFX, ambient, voice with effective volume
- **Save migrations**: `SaveMigrator` protocol and ordered migration pipeline
- **Autosave config** structure

### Examples
- Existing 8 examples retained; new systems demonstrated in expanded demos where applicable

### Documentation
- CHANGELOG, ARCHITECTURE notes, migration guidance from V1

### Known limitations (unchanged core constraints)
- Null render/audio backends on non-Apple / headless
- Physics remains software 2D (no 3D physics body solver)
- Networking remains architectural (no production transport)
- Full Metal integration still requires platform-specific backend implementation

## [0.1.0] - 2026-09-24 — V1 Foundation

Initial modular framework: Math, Core loop, ECS, Scene, 2D Physics, Animation, Particles, Audio/Input abstractions, UI basics, Assets, Save, Debug, Profiler, AI pathfinding, Networking foundation, Gameplay helpers, 8 examples, unit tests.
