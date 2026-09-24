import Foundation

public enum SGKError: Error, LocalizedError, Sendable {
    case notFound(String)
    case invalidFormat(String)
    case loadingFailed(String)
    case alreadyExists(String)
    case invalidState(String)
    case outOfBounds(String)
    case unsupported(String)
    case network(String)
    case serialization(String)
    case physics(String)
    case rendering(String)
    case unknown(String)

    public var errorDescription: String? {
        switch self {
        case .notFound(let m): return "Not found: \(m)"
        case .invalidFormat(let m): return "Invalid format: \(m)"
        case .loadingFailed(let m): return "Loading failed: \(m)"
        case .alreadyExists(let m): return "Already exists: \(m)"
        case .invalidState(let m): return "Invalid state: \(m)"
        case .outOfBounds(let m): return "Out of bounds: \(m)"
        case .unsupported(let m): return "Unsupported: \(m)"
        case .network(let m): return "Network error: \(m)"
        case .serialization(let m): return "Serialization error: \(m)"
        case .physics(let m): return "Physics error: \(m)"
        case .rendering(let m): return "Rendering error: \(m)"
        case .unknown(let m): return "Unknown error: \(m)"
        }
    }
}

public typealias AssetError = SGKError
public typealias PhysicsError = SGKError
public typealias NetworkError = SGKError
