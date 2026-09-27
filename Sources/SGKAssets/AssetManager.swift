import Foundation
import SGKCore
import SGKSerialization
import SGKMath

public protocol Asset: AnyObject {
    var id: String { get }
    var isLoaded: Bool { get }
}

public final class TextureAsset: Asset {
    public let id: String
    public private(set) var isLoaded = false
    public var width: Int = 0
    public var height: Int = 0
    public var path: String

    public init(id: String, path: String) {
        self.id = id
        self.path = path
    }

    public func load() {
        isLoaded = true
        Log.debug("Loaded texture \(id) from \(path)")
    }
}

public final class SoundAsset: Asset {
    public let id: String
    public private(set) var isLoaded = false
    public var path: String

    public init(id: String, path: String) {
        self.id = id
        self.path = path
    }

    public func load() {
        isLoaded = true
        Log.debug("Loaded sound \(id) from \(path)")
    }
}

public final class AssetManager: @unchecked Sendable {
    public static let shared = AssetManager()

    private var textures: [String: TextureAsset] = [:]
    private var sounds: [String: SoundAsset] = [:]
    private let lock = NSLock()

    private init() {}

    public func loadTexture(id: String, path: String) -> TextureAsset {
        lock.lock()
        defer { lock.unlock() }
        if let existing = textures[id] { return existing }
        let asset = TextureAsset(id: id, path: path)
        asset.load()
        textures[id] = asset
        return asset
    }

    public func loadSound(id: String, path: String) -> SoundAsset {
        lock.lock()
        defer { lock.unlock() }
        if let existing = sounds[id] { return existing }
        let asset = SoundAsset(id: id, path: path)
        asset.load()
        sounds[id] = asset
        return asset
    }

    public func texture(_ id: String) -> TextureAsset? {
        lock.lock()
        defer { lock.unlock() }
        return textures[id]
    }

    public func sound(_ id: String) -> SoundAsset? {
        lock.lock()
        defer { lock.unlock() }
        return sounds[id]
    }

    public func unloadAll() {
        lock.lock()
        textures.removeAll()
        sounds.removeAll()
        lock.unlock()
    }
}
