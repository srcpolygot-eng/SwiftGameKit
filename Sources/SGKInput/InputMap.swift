import Foundation
import SGKCore

public enum InputBinding: Hashable, Sendable {
    case keyboard(KeyCode)
    case mouse(MouseButton)
    case keyCombo([KeyCode])
}

public struct ActionBinding: Sendable {
    public var name: String
    public var bindings: [InputBinding]
    public var scale: Float

    public init(name: String, bindings: [InputBinding], scale: Float = 1) {
        self.name = name
        self.bindings = bindings
        self.scale = scale
    }
}

/// Named input context (e.g. "gameplay", "menu", "vehicle").
public final class InputContext {
    public let name: String
    public private(set) var actions: [String: ActionBinding] = [:]
    public var isActive: Bool = true

    public init(name: String) {
        self.name = name
    }

    public func bind(_ action: String, to binding: InputBinding, scale: Float = 1) {
        if var existing = actions[action] {
            existing.bindings.append(binding)
            existing.scale = scale
            actions[action] = existing
        } else {
            actions[action] = ActionBinding(name: action, bindings: [binding], scale: scale)
        }
    }

    public func bind(_ action: String, to bindings: [InputBinding], scale: Float = 1) {
        actions[action] = ActionBinding(name: action, bindings: bindings, scale: scale)
    }

    public func unbind(_ action: String) {
        actions[action] = nil
    }
}

public final class InputMap: @unchecked Sendable {
    public static let shared = InputMap()

    public private(set) var contexts: [String: InputContext] = [:]
    public var activeContextName: String = "default"
    public var mouseSensitivity: Float = 1.0
    public var deadZone: Float = 0.15

    private init() {
        let gameplay = InputContext(name: "gameplay")
        gameplay.bind("jump", to: .keyboard(.space))
        gameplay.bind("jump", to: .keyboard(.w))
        gameplay.bind("fire", to: .mouse(.left))
        gameplay.bind("move_left", to: .keyboard(.a))
        gameplay.bind("move_right", to: .keyboard(.d))
        gameplay.bind("move_up", to: .keyboard(.w))
        gameplay.bind("move_down", to: .keyboard(.s))
        contexts["gameplay"] = gameplay
        contexts["default"] = gameplay

        let menu = InputContext(name: "menu")
        menu.bind("confirm", to: .keyboard(.enter))
        menu.bind("cancel", to: .keyboard(.escape))
        contexts["menu"] = menu
    }

    public func context(_ name: String) -> InputContext {
        if let c = contexts[name] { return c }
        let c = InputContext(name: name)
        contexts[name] = c
        return c
    }

    public func setActiveContext(_ name: String) {
        activeContextName = name
    }

    public var activeContext: InputContext? {
        contexts[activeContextName]
    }

    /// Evaluate an action against the current input state.
    public func isPressed(_ action: String, input: InputSystem = Input) -> Bool {
        guard let ctx = activeContext, ctx.isActive,
              let binding = ctx.actions[action] else { return false }
        for b in binding.bindings {
            switch b {
            case .keyboard(let key):
                if input.isKeyPressed(key) { return true }
            case .mouse(let btn):
                if input.isMousePressed(btn) { return true }
            case .keyCombo(let keys):
                if keys.allSatisfy({ input.isKeyDown($0) }) && keys.contains(where: { input.isKeyPressed($0) }) {
                    return true
                }
            }
        }
        return false
    }

    public func isHeld(_ action: String, input: InputSystem = Input) -> Bool {
        guard let ctx = activeContext, ctx.isActive,
              let binding = ctx.actions[action] else { return false }
        for b in binding.bindings {
            switch b {
            case .keyboard(let key):
                if input.isKeyDown(key) { return true }
            case .mouse(let btn):
                if input.isMouseDown(btn) { return true }
            case .keyCombo(let keys):
                if keys.allSatisfy({ input.isKeyDown($0) }) { return true }
            }
        }
        return false
    }

    public func axis(_ positive: String, _ negative: String, input: InputSystem = Input) -> Float {
        var v: Float = 0
        if isHeld(positive, input: input) { v += 1 }
        if isHeld(negative, input: input) { v -= 1 }
        if abs(v) < deadZone { return 0 }
        return v
    }
}
