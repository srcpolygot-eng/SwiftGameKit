import Foundation
import SGKMath

/// Value noise / simple Perlin-like 2D noise (deterministic with seed).
public struct ValueNoise {
    private var perm: [Int]

    public init(seed: UInt64 = 0) {
        var rng = SeededRandom(seed: seed == 0 ? 1 : seed)
        var p = Array(0..<256)
        rng.shuffle(&p)
        perm = p + p
    }

    public func noise(_ x: Float, _ y: Float) -> Float {
        let xi = Int(floor(x)) & 255
        let yi = Int(floor(y)) & 255
        let xf = x - floor(x)
        let yf = y - floor(y)
        let u = fade(xf)
        let v = fade(yf)

        let aa = perm[perm[xi] + yi]
        let ab = perm[perm[xi] + yi + 1]
        let ba = perm[perm[xi + 1] + yi]
        let bb = perm[perm[xi + 1] + yi + 1]

        let x1 = lerp(grad(aa, xf, yf), grad(ba, xf - 1, yf), u)
        let x2 = lerp(grad(ab, xf, yf - 1), grad(bb, xf - 1, yf - 1), u)
        return lerp(x1, x2, v)
    }

    public func fbm(_ x: Float, _ y: Float, octaves: Int = 4, lacunarity: Float = 2, gain: Float = 0.5) -> Float {
        var amp: Float = 1
        var freq: Float = 1
        var sum: Float = 0
        var maxAmp: Float = 0
        for _ in 0..<octaves {
            sum += noise(x * freq, y * freq) * amp
            maxAmp += amp
            amp *= gain
            freq *= lacunarity
        }
        return maxAmp > 0 ? sum / maxAmp : 0
    }

    private func fade(_ t: Float) -> Float { t * t * t * (t * (t * 6 - 15) + 10) }
    private func lerp(_ a: Float, _ b: Float, _ t: Float) -> Float { a + t * (b - a) }
    private func grad(_ hash: Int, _ x: Float, _ y: Float) -> Float {
        let h = hash & 3
        let u = h < 2 ? x : y
        let v = h < 2 ? y : x
        return ((h & 1) == 0 ? u : -u) + ((h & 2) == 0 ? v : -v)
    }
}

/// Cellular automata utilities (e.g. cave generation).
public enum CellularAutomata {
    public static func generate(width: Int, height: Int, fillProbability: Float = 0.45, seed: UInt64 = 42, steps: Int = 4) -> [[Bool]] {
        var rng = SeededRandom(seed: seed)
        var grid = Array(repeating: Array(repeating: false, count: width), count: height)
        for y in 0..<height {
            for x in 0..<width {
                grid[y][x] = rng.nextFloat() < fillProbability
            }
        }
        for _ in 0..<steps {
            grid = step(grid)
        }
        return grid
    }

    public static func step(_ grid: [[Bool]]) -> [[Bool]] {
        let h = grid.count
        let w = grid[0].count
        var next = grid
        for y in 0..<h {
            for x in 0..<w {
                let n = countNeighbors(grid, x, y)
                if grid[y][x] {
                    next[y][x] = n >= 4
                } else {
                    next[y][x] = n >= 5
                }
            }
        }
        return next
    }

    private static func countNeighbors(_ grid: [[Bool]], _ x: Int, _ y: Int) -> Int {
        var c = 0
        let h = grid.count
        let w = grid[0].count
        for dy in -1...1 {
            for dx in -1...1 {
                if dx == 0 && dy == 0 { continue }
                let nx = x + dx
                let ny = y + dy
                if nx < 0 || ny < 0 || nx >= w || ny >= h {
                    c += 1 // treat out of bounds as wall
                } else if grid[ny][nx] {
                    c += 1
                }
            }
        }
        return c
    }
}

/// Weighted random selection and simple dungeon room placement helpers.
public enum ProcGen {
    public static func weightedSelect<T>(_ items: [(T, Float)], rng: inout SeededRandom) -> T? {
        rng.weightedChoose(items)
    }

    public struct Room: Sendable {
        public var x: Int
        public var y: Int
        public var w: Int
        public var h: Int
        public var center: (x: Int, y: Int) { (x + w / 2, y + h / 2) }
    }

    public static func generateRooms(
        mapWidth: Int,
        mapHeight: Int,
        roomCount: Int,
        minSize: Int = 4,
        maxSize: Int = 10,
        seed: UInt64 = 1
    ) -> [Room] {
        var rng = SeededRandom(seed: seed)
        var rooms: [Room] = []
        for _ in 0..<roomCount {
            let w = rng.nextInt(in: minSize...maxSize)
            let h = rng.nextInt(in: minSize...maxSize)
            let x = rng.nextInt(in: 1...(max(1, mapWidth - w - 1)))
            let y = rng.nextInt(in: 1...(max(1, mapHeight - h - 1)))
            let candidate = Room(x: x, y: y, w: w, h: h)
            var overlaps = false
            for r in rooms {
                if candidate.x < r.x + r.w + 1 && candidate.x + candidate.w + 1 > r.x &&
                    candidate.y < r.y + r.h + 1 && candidate.y + candidate.h + 1 > r.y {
                    overlaps = true
                    break
                }
            }
            if !overlaps { rooms.append(candidate) }
        }
        return rooms
    }
}
