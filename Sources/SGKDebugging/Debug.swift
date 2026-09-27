import Foundation
import SGKCore
import SGKProfiling

public enum Debug {
    nonisolated(unsafe) public static var showFPS = false
    nonisolated(unsafe) public static var showColliders = false
    nonisolated(unsafe) public static var showBounds = false
    nonisolated(unsafe) public static var showEntityCount = false
    nonisolated(unsafe) public static var showProfiler = false

    nonisolated(unsafe) private static var frameTimes: [Double] = []
    nonisolated(unsafe) private static var lastFPSUpdate = 0.0
    nonisolated(unsafe) private static var currentFPS: Double = 0

    public static func recordFrame(deltaTime: Double) {
        frameTimes.append(deltaTime)
        if frameTimes.count > 60 { frameTimes.removeFirst() }
        let now = Time.now()
        if now - lastFPSUpdate >= 0.5 {
            if !frameTimes.isEmpty {
                let avg = frameTimes.reduce(0, +) / Double(frameTimes.count)
                currentFPS = avg > 0 ? 1.0 / avg : 0
            }
            lastFPSUpdate = now
        }
    }

    public static var fps: Double { currentFPS }

    public static var frameTimeMs: Double {
        guard !frameTimes.isEmpty else { return 0 }
        return (frameTimes.reduce(0, +) / Double(frameTimes.count)) * 1000
    }

    public static func overlayText(entityCount: Int = 0) -> String {
        var lines: [String] = []
        if showFPS {
            lines.append(String(format: "FPS: %.1f (%.2f ms)", fps, frameTimeMs))
        }
        if showEntityCount {
            lines.append("Entities: \(entityCount)")
        }
        if showProfiler {
            for s in Profiler.shared.report().prefix(8) {
                lines.append(String(format: "%@: %.2f ms", s.name, s.avgMs))
            }
        }
        return lines.joined(separator: "\n")
    }
}

public final class DeveloperConsole: @unchecked Sendable {
    public static let shared = DeveloperConsole()

    public typealias CommandHandler = ([String]) -> String

    private var commands: [String: CommandHandler] = [:]
    public private(set) var history: [String] = []
    public var isVisible = false

    private init() {
        register("help") { [weak self] _ in
            guard let self else { return "" }
            return "Commands: " + self.commands.keys.sorted().joined(separator: ", ")
        }
        register("fps") { _ in
            Debug.showFPS.toggle()
            return "showFPS = \(Debug.showFPS)"
        }
        register("entities") { args in
            Debug.showEntityCount.toggle()
            return "showEntityCount = \(Debug.showEntityCount)"
        }
        register("pause") { _ in "Use Game.pause() / resume()" }
        register("timescale") { args in
            guard let v = args.first, let scale = Double(v) else { return "Usage: timescale <value>" }
            return "Set timeScale to \(scale) via Game.timeScale"
        }
        register("profiler") { _ in
            Debug.showProfiler.toggle()
            return "showProfiler = \(Debug.showProfiler)"
        }
    }

    public func register(_ name: String, handler: @escaping CommandHandler) {
        commands[name.lowercased()] = handler
    }

    public func execute(_ line: String) -> String {
        history.append(line)
        let parts = line.split(separator: " ").map(String.init)
        guard let cmd = parts.first?.lowercased() else { return "" }
        let args = Array(parts.dropFirst())
        if let handler = commands[cmd] {
            return handler(args)
        }
        return "Unknown command: \(cmd). Type 'help'."
    }
}
