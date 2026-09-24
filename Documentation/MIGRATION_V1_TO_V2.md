# Migrating from SwiftGameKit V1 to V2

V2 is largely additive. Existing V1 APIs continue to work.

## Version

```swift
SwiftGameKitInfo.version // "2.0.0"
```

## ECS

- New: `world.setEnabled(entity, false)` / `isEnabled`
- New: `Disabled` component tag
- New: `world.query(A.self, B.self, excluding: [Disabled.self])`
- New: `world.createCommandBuffer()` for deferred structural changes

Prefer command buffers when modifying entities inside systems.

## Input

V1 `Input.action("jump")` still works.  
V2 adds `InputMap` with contexts:

```swift
InputMap.shared.setActiveContext("gameplay")
if InputMap.shared.isPressed("jump") { ... }
```

## Audio

```swift
AudioManager.shared.playSFX("hit")
AudioManager.shared.music.volume = 0.5
```

## Navigation

```swift
let agent = NavigationAgent(position: start)
agent.setDestination(goal, on: grid)
agent.update(deltaTime: dt)
```

## Saves

Register migrators if you change save schema:

```swift
SaveMigration.register(MyMigrator())
```

## Breaking changes

Minimal. Some internal storage access levels were relaxed for query helpers.  
If you depended on private/fileprivate symbols, switch to public APIs.
