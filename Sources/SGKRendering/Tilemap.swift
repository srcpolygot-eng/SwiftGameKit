import Foundation
import SGKMath

public struct TileCoord: Hashable, Sendable {
    public var x: Int
    public var y: Int
    public init(_ x: Int, _ y: Int) { self.x = x; self.y = y }
}

public struct TileSet: Sendable {
    public var name: String
    public var tileWidth: Int
    public var tileHeight: Int
    public var textureID: String
    public var tileCount: Int
    public var columns: Int

    public init(name: String, tileWidth: Int, tileHeight: Int, textureID: String, tileCount: Int, columns: Int) {
        self.name = name
        self.tileWidth = tileWidth
        self.tileHeight = tileHeight
        self.textureID = textureID
        self.tileCount = tileCount
        self.columns = columns
    }

    public func region(for tileID: Int) -> (x: Float, y: Float, w: Float, h: Float) {
        guard tileID >= 0, columns > 0 else { return (0, 0, Float(tileWidth), Float(tileHeight)) }
        let col = tileID % columns
        let row = tileID / columns
        return (
            Float(col * tileWidth),
            Float(row * tileHeight),
            Float(tileWidth),
            Float(tileHeight)
        )
    }
}

public final class TileLayer {
    public var name: String
    public var width: Int
    public var height: Int
    public var tiles: [Int] // row-major, -1 = empty
    public var visible: Bool = true
    public var opacity: Float = 1
    public var offset: Vector2 = .zero
    public var parallax: Vector2 = .one

    public init(name: String, width: Int, height: Int, fill: Int = -1) {
        self.name = name
        self.width = width
        self.height = height
        self.tiles = Array(repeating: fill, count: width * height)
    }

    public func tile(at x: Int, y: Int) -> Int {
        guard x >= 0, y >= 0, x < width, y < height else { return -1 }
        return tiles[y * width + x]
    }

    public func setTile(_ id: Int, at x: Int, y: Int) {
        guard x >= 0, y >= 0, x < width, y < height else { return }
        tiles[y * width + x] = id
    }

    public func fill(_ id: Int) {
        for i in tiles.indices { tiles[i] = id }
    }
}

public final class TileMap {
    public var name: String
    public var tileSet: TileSet
    public var layers: [TileLayer] = []
    public var tileWidth: Int { tileSet.tileWidth }
    public var tileHeight: Int { tileSet.tileHeight }

    public init(name: String, tileSet: TileSet) {
        self.name = name
        self.tileSet = tileSet
    }

    public func addLayer(_ layer: TileLayer) {
        layers.append(layer)
    }

    public func worldPosition(for coord: TileCoord) -> Vector2 {
        Vector2(Float(coord.x * tileWidth), Float(coord.y * tileHeight))
    }

    public func tileCoord(at world: Vector2) -> TileCoord {
        TileCoord(Int(world.x / Float(tileWidth)), Int(world.y / Float(tileHeight)))
    }
}

/// Simple sprite atlas (regions in a single texture).
public struct SpriteAtlas: Sendable {
    public var textureID: String
    public var frames: [String: (x: Float, y: Float, w: Float, h: Float)]

    public init(textureID: String, frames: [String: (x: Float, y: Float, w: Float, h: Float)] = [:]) {
        self.textureID = textureID
        self.frames = frames
    }

    public mutating func add(name: String, x: Float, y: Float, w: Float, h: Float) {
        frames[name] = (x, y, w, h)
    }

    public func region(_ name: String) -> (x: Float, y: Float, w: Float, h: Float)? {
        frames[name]
    }
}
