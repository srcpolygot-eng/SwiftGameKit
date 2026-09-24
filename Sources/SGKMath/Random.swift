import Foundation

/// Deterministic seeded random number generator for reproducible gameplay.
public struct SeededRandom: RandomNumberGenerator, Sendable {
    private var state: UInt64

    public init(seed: UInt64) {
        self.state = seed == 0 ? 0xDEADBEEF : seed
    }

    public mutating func next() -> UInt64 {
        // xorshift64*
        state ^= state >> 12
        state ^= state << 25
        state ^= state >> 27
        return state &* 0x2545F4914F6CDD1D
    }

    public mutating func nextFloat() -> Float {
        Float(next() >> 40) / Float(1 << 24)
    }

    public mutating func nextFloat(in range: ClosedRange<Float>) -> Float {
        range.lowerBound + nextFloat() * (range.upperBound - range.lowerBound)
    }

    public mutating func nextDouble() -> Double {
        Double(next() >> 11) / Double(1 << 53)
    }

    public mutating func nextInt(in range: ClosedRange<Int>) -> Int {
        let span = UInt64(range.upperBound - range.lowerBound + 1)
        return range.lowerBound + Int(next() % span)
    }

    public mutating func nextBool() -> Bool {
        next() & 1 == 1
    }

    public mutating func nextVector2(in radius: Float = 1) -> Vector2 {
        let angle = nextFloat() * Math.twoPi
        let r = sqrt(nextFloat()) * radius
        return Vector2(cos(angle) * r, sin(angle) * r)
    }

    public mutating func nextVector3(in radius: Float = 1) -> Vector3 {
        // Marsaglia method for unit sphere
        var x, y, s: Float
        repeat {
            x = nextFloat(in: -1...1)
            y = nextFloat(in: -1...1)
            s = x * x + y * y
        } while s >= 1 || s < .ulpOfOne
        let z = 1 - 2 * s
        let scale = 2 * sqrt(1 - s) * radius
        return Vector3(x * scale, y * scale, z * radius)
    }

    public mutating func choose<T>(_ array: [T]) -> T? {
        guard !array.isEmpty else { return nil }
        return array[nextInt(in: 0...(array.count - 1))]
    }

    public mutating func weightedChoose<T>(_ items: [(T, Float)]) -> T? {
        guard !items.isEmpty else { return nil }
        let total = items.reduce(0) { $0 + $1.1 }
        guard total > 0 else { return items.first?.0 }
        var r = nextFloat() * total
        for (item, weight) in items {
            r -= weight
            if r <= 0 { return item }
        }
        return items.last?.0
    }

    public mutating func shuffle<T>(_ array: inout [T]) {
        guard array.count > 1 else { return }
        for i in stride(from: array.count - 1, through: 1, by: -1) {
            let j = nextInt(in: 0...i)
            array.swapAt(i, j)
        }
    }
}

/// Global convenience RNG (not deterministic across runs unless seeded).
public enum Random {
    private static nonisolated(unsafe) var rng = SeededRandom(seed: UInt64(Date().timeIntervalSince1970 * 1000))

    public static func seed(_ value: UInt64) {
        rng = SeededRandom(seed: value)
    }

    public static func float() -> Float {
        rng.nextFloat()
    }

    public static func float(in range: ClosedRange<Float>) -> Float {
        rng.nextFloat(in: range)
    }

    public static func int(in range: ClosedRange<Int>) -> Int {
        rng.nextInt(in: range)
    }

    public static func bool() -> Bool {
        rng.nextBool()
    }

    public static func vector2(in radius: Float = 1) -> Vector2 {
        rng.nextVector2(in: radius)
    }

    public static func vector3(in radius: Float = 1) -> Vector3 {
        rng.nextVector3(in: radius)
    }

    public static func choose<T>(_ array: [T]) -> T? {
        rng.choose(array)
    }
}
