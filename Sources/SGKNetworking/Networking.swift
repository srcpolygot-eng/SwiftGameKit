import Foundation
import SGKCore
import SGKSerialization

public protocol NetworkPacket: Codable, Sendable {
    static var packetType: String { get }
}

public struct ConnectPacket: NetworkPacket {
    public static let packetType = "connect"
    public var clientID: String
    public var version: Int
    public init(clientID: String, version: Int = 1) {
        self.clientID = clientID
        self.version = version
    }
}

public struct SnapshotPacket: NetworkPacket {
    public static let packetType = "snapshot"
    public var tick: UInt64
    public var payload: Data
    public init(tick: UInt64, payload: Data) {
        self.tick = tick
        self.payload = payload
    }
}

public enum NetworkRole: Sendable {
    case server
    case client
    case listenServer
}

public protocol NetworkTransport: AnyObject {
    func send(_ data: Data, reliable: Bool)
    func receive() -> Data?
    var isConnected: Bool { get }
}

public final class InMemoryTransport: NetworkTransport {
    private var queue: [Data] = []
    public var isConnected = true
    public weak var peer: InMemoryTransport?

    public init() {}

    public func send(_ data: Data, reliable: Bool) {
        peer?.queue.append(data)
    }

    public func receive() -> Data? {
        guard !queue.isEmpty else { return nil }
        return queue.removeFirst()
    }

    public static func linkedPair() -> (InMemoryTransport, InMemoryTransport) {
        let a = InMemoryTransport()
        let b = InMemoryTransport()
        a.peer = b
        b.peer = a
        return (a, b)
    }
}

public final class NetworkManager {
    public var role: NetworkRole = .client
    public var transport: NetworkTransport?
    public private(set) var tick: UInt64 = 0

    public init() {}

    public func send<P: NetworkPacket>(_ packet: P, reliable: Bool = true) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(packet)
        var envelope = Data()
        let typeData = Data(P.packetType.utf8)
        var typeLen = UInt16(typeData.count)
        envelope.append(Data(bytes: &typeLen, count: 2))
        envelope.append(typeData)
        envelope.append(data)
        transport?.send(envelope, reliable: reliable)
    }

    public func poll() -> [(type: String, data: Data)] {
        var results: [(String, Data)] = []
        while let data = transport?.receive() {
            guard data.count >= 2 else { continue }
            let typeLen = Int(data.withUnsafeBytes { $0.load(as: UInt16.self) })
            guard data.count >= 2 + typeLen else { continue }
            let typeStart = data.index(data.startIndex, offsetBy: 2)
            let typeEnd = data.index(typeStart, offsetBy: typeLen)
            let type = String(data: data[typeStart..<typeEnd], encoding: .utf8) ?? ""
            let payload = Data(data[typeEnd...])
            results.append((type, payload))
        }
        return results
    }

    public func advanceTick() {
        tick += 1
    }
}
