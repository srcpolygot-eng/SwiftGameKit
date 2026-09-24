import Foundation
import SGKCore
import SGKMath
import SGKSerialization

public enum AssetState: Sendable {
    case unloaded
    case loading
    case loaded
    case failed(Error)
}

public protocol Asset: AnyObject {
    var id: String { get }
    var state: AssetState { get }
}

public final class TextureAsset: Asset {
    public let id: String
    public private(set) var state: AssetState = .unloaded
    public var width: Int = 0
    public var height: Int = 0
    public var data: Data?

    public init(id: String) { self.id = id }

    public func markLoaded(width: Int, height: Int, data: Data?) {
        self.width = width
        self.height = height
        self.data = data
        self.state = .loaded
    }
}

public final class SoundAsset: Asset {
    public let id: String
    public private(set) var state: AssetState = .unloaded
    public var duration: Double = 0

    public init(id: String) { self.id = id }
    public func markLoaded(duration: Double) {
        self.duration = duration
        self.state = .loaded
    }
}

public final class AssetManager {
    public static let shared = AssetManager()

    private var textures: [String: TextureAsset] = [:]
    private var sounds: [String: SoundAsset] = [:]
    private let lock = NSLock()

    private init() {}

    public func loadTexture(id: String, path: String? = nil) -> TextureAsset {
        lock.lock()
        defer { lock.unlock() }
        if let existing = textures[id] { return existing }
        let asset = TextureAsset(id: id)
        // Simulated load - in real engine would load from disk / bundle
        asset.markLoaded(width: 64, height: 64, data: nil)
        textures[id] = asset
        Log.debug("Loaded texture: \(id)")
        return asset
    }

    public func loadSound(id: String, path: String? = nil) -> SoundAsset {
        lock.lock()
        defer { lock.unlock() }
        if let existing = sounds[id] { return existing }
        let asset = SoundAsset(id: id)
        asset.markLoaded(duration: 1.0)
        sounds[id] = asset
        Log.debug("Loaded sound: \(id)")
        return asset
    }

    public func getTexture(_ id: String) -> TextureAsset? {
        lock.lock(); defer { lock.unlock() }
        return textures[id]
    }

    public func unloadTexture(_ id: String) {
        lock.lock()
        textures[id] = nil
        lock.unlock()
    }

    public func unloadAll() {
        lock.lock()
        textures.removeAll()
        sounds.removeAll()
        lock.unlock()
    }

    public var textureCount: Int {
        lock.lock(); defer { lock.unlock() }
        return textures.count
    }
}

public let Assets = AssetManager.shared
