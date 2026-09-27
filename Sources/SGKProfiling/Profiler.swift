import Foundation
import SGKCore

public final class Profiler: @unchecked Sendable {
    public static let shared = Profiler()

    public struct Sample: Sendable {
        public let name: String
        public let duration: Double
        public let timestamp: Double
    }

    private var samples: [String: [Double]] = [:]
    private var activeScopes: [String: Double] = [:]
    private let lock = NSLock()
    public var enabled = true

    private init() {}

    public func begin(_ name: String) {
        guard enabled else { return }
        lock.lock()
        activeScopes[name] = Time.now()
        lock.unlock()
    }

    public func end(_ name: String) {
        guard enabled else { return }
        let now = Time.now()
        lock.lock()
        if let start = activeScopes.removeValue(forKey: name) {
            let dt = now - start
            samples[name, default: []].append(dt)
            if samples[name]!.count > 240 {
                samples[name]!.removeFirst()
            }
        }
        lock.unlock()
    }

    public func measure<T>(_ name: String, _ body: () throws -> T) rethrows -> T {
        begin(name)
        defer { end(name) }
        return try body()
    }

    public func average(_ name: String) -> Double {
        lock.lock()
        defer { lock.unlock() }
        guard let list = samples[name], !list.isEmpty else { return 0 }
        return list.reduce(0, +) / Double(list.count)
    }

    public func last(_ name: String) -> Double {
        lock.lock()
        defer { lock.unlock() }
        return samples[name]?.last ?? 0
    }

    public func report() -> [(name: String, avgMs: Double, lastMs: Double)] {
        lock.lock()
        defer { lock.unlock() }
        return samples.map { name, list in
            let avg = list.isEmpty ? 0 : list.reduce(0, +) / Double(list.count)
            return (name, avg * 1000, (list.last ?? 0) * 1000)
        }.sorted { $0.avgMs > $1.avgMs }
    }

    public func reset() {
        lock.lock()
        samples.removeAll()
        activeScopes.removeAll()
        lock.unlock()
    }
}

public func measure<T>(_ name: String, _ body: () throws -> T) rethrows -> T {
    try Profiler.shared.measure(name, body)
}
