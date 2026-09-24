import Foundation

public struct GraphicsConfig: Codable, Sendable {
    public var width: Int = 1280
    public var height: Int = 720
    public var fullscreen: Bool = false
    public var vsync: Bool = true
    public var targetFrameRate: Int = 60
    public var msaaSamples: Int = 4

    public init() {}
}

public struct AudioConfig: Codable, Sendable {
    public var masterVolume: Float = 1.0
    public var musicVolume: Float = 0.8
    public var sfxVolume: Float = 1.0
    public var sampleRate: Int = 44100

    public init() {}
}

public struct InputConfig: Codable, Sendable {
    public var mouseSensitivity: Float = 1.0
    public var invertY: Bool = false

    public init() {}
}

public struct DebugConfig: Codable, Sendable {
    public var showFPS: Bool = false
    public var showColliders: Bool = false
    public var showBounds: Bool = false
    public var logLevel: String = "info"

    public init() {}
}

public struct PerformanceConfig: Codable, Sendable {
    public var enableProfiling: Bool = false
    public var maxEntities: Int = 100_000
    public var physicsSubsteps: Int = 1

    public init() {}
}

public struct GameConfig: Codable, Sendable {
    public var graphics = GraphicsConfig()
    public var audio = AudioConfig()
    public var input = InputConfig()
    public var debug = DebugConfig()
    public var performance = PerformanceConfig()
    public var custom: [String: String] = [:]

    public init() {}

    public static func load(from url: URL) throws -> GameConfig {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(GameConfig.self, from: data)
    }

    public func save(to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(self)
        try data.write(to: url)
    }
}
