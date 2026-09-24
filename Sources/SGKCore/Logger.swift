import Foundation

public enum LogLevel: Int, Comparable, Sendable, CaseIterable {
    case trace = 0
    case debug = 1
    case info = 2
    case warning = 3
    case error = 4
    case critical = 5

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public var name: String {
        switch self {
        case .trace: return "TRACE"
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warning: return "WARN"
        case .error: return "ERROR"
        case .critical: return "CRIT"
        }
    }
}

public protocol LogHandler: Sendable {
    func log(level: LogLevel, category: String, message: String, file: String, line: Int)
}

public struct ConsoleLogHandler: LogHandler {
    public init() {}

    public func log(level: LogLevel, category: String, message: String, file: String, line: Int) {
        let ts = ISO8601DateFormatter().string(from: Date())
        let shortFile = (file as NSString).lastPathComponent
        print("[\(ts)] [\(level.name)] [\(category)] \(message) (\(shortFile):\(line))")
    }
}

public final class Logger: @unchecked Sendable {
    public static let shared = Logger()

    public var minimumLevel: LogLevel = .info
    public var handlers: [LogHandler] = [ConsoleLogHandler()]
    public var categoryFilter: Set<String>? = nil

    private let lock = NSLock()

    private init() {}

    public func log(
        _ level: LogLevel,
        category: String = "SGK",
        _ message: @autoclosure () -> String,
        file: String = #file,
        line: Int = #line
    ) {
        guard level >= minimumLevel else { return }
        if let filter = categoryFilter, !filter.contains(category) { return }
        let msg = message()
        lock.lock()
        defer { lock.unlock() }
        for handler in handlers {
            handler.log(level: level, category: category, message: msg, file: file, line: line)
        }
    }

    public func trace(_ message: @autoclosure () -> String, category: String = "SGK", file: String = #file, line: Int = #line) {
        log(.trace, category: category, message(), file: file, line: line)
    }

    public func debug(_ message: @autoclosure () -> String, category: String = "SGK", file: String = #file, line: Int = #line) {
        log(.debug, category: category, message(), file: file, line: line)
    }

    public func info(_ message: @autoclosure () -> String, category: String = "SGK", file: String = #file, line: Int = #line) {
        log(.info, category: category, message(), file: file, line: line)
    }

    public func warning(_ message: @autoclosure () -> String, category: String = "SGK", file: String = #file, line: Int = #line) {
        log(.warning, category: category, message(), file: file, line: line)
    }

    public func error(_ message: @autoclosure () -> String, category: String = "SGK", file: String = #file, line: Int = #line) {
        log(.error, category: category, message(), file: file, line: line)
    }

    public func critical(_ message: @autoclosure () -> String, category: String = "SGK", file: String = #file, line: Int = #line) {
        log(.critical, category: category, message(), file: file, line: line)
    }
}

public let Log = Logger.shared
