import Foundation

public protocol Event: Sendable {}

public final class EventBus: @unchecked Sendable {
    public static let shared = EventBus()

    private var listeners: [ObjectIdentifier: [UUID: (any Event) -> Void]] = [:]
    private let lock = NSLock()

    private init() {}

    @discardableResult
    public func subscribe<E: Event>(_ type: E.Type, handler: @escaping (E) -> Void) -> UUID {
        let id = UUID()
        let key = ObjectIdentifier(type)
        lock.lock()
        if listeners[key] == nil { listeners[key] = [:] }
        listeners[key]![id] = { event in
            if let e = event as? E {
                handler(e)
            }
        }
        lock.unlock()
        return id
    }

    public func unsubscribe(_ id: UUID) {
        lock.lock()
        for key in listeners.keys {
            listeners[key]?[id] = nil
        }
        lock.unlock()
    }

    public func publish<E: Event>(_ event: E) {
        let key = ObjectIdentifier(E.self)
        lock.lock()
        let handlers = listeners[key]?.values.map { $0 } ?? []
        lock.unlock()
        for h in handlers {
            h(event)
        }
    }

    public func clear() {
        lock.lock()
        listeners.removeAll()
        lock.unlock()
    }
}
