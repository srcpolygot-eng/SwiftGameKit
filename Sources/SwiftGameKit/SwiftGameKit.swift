// SwiftGameKit - Umbrella module
// Re-exports all public APIs for convenient single import.

@_exported import SGKMath
@_exported import SGKCore
@_exported import SGKECS
@_exported import SGKScene
@_exported import SGKRendering
@_exported import SGKPhysics
@_exported import SGKAnimation
@_exported import SGKAudio
@_exported import SGKInput
@_exported import SGKUI
@_exported import SGKParticles
@_exported import SGKAssets
@_exported import SGKSerialization
@_exported import SGKDebugging
@_exported import SGKProfiling
@_exported import SGKUtilities
@_exported import SGKAI
@_exported import SGKNetworking
@_exported import SGKGameplay

/// Framework version.
public enum SwiftGameKitInfo {
    public static let version = "2.0.0"
    public static let name = "SwiftGameKit"
}
