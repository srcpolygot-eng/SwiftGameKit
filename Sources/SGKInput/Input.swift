import Foundation
import SGKMath
import SGKCore

public enum KeyCode: String, Sendable, Hashable {
    case a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z
    case space, enter, escape, shift, control, tab
    case left, right, up, down
    case digit0, digit1, digit2, digit3, digit4, digit5, digit6, digit7, digit8, digit9
    case f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12
}

public enum MouseButton: Int, Sendable {
    case left = 0, right = 1, middle = 2
}

public struct InputAction: Sendable {
    public var keys: [KeyCode]
    public var mouseButtons: [MouseButton]
    public init(keys: [KeyCode] = [], mouseButtons: [MouseButton] = []) {
        self.keys = keys
        self.mouseButtons = mouseButtons
    }
}

public final class InputSystem: @unchecked Sendable {
    public static let shared = InputSystem()

    private var keyDown = Set<KeyCode>()
    private var keyPressed = Set<KeyCode>()
    private var keyReleased = Set<KeyCode>()
    private var mouseDown = Set<MouseButton>()
    private var mousePressed = Set<MouseButton>()
    private var mouseReleased = Set<MouseButton>()
    public private(set) var mousePosition = Vector2.zero
    public private(set) var mouseDelta = Vector2.zero
    private var actions: [String: InputAction] = [:]
    private var axes: [String: (positive: KeyCode, negative: KeyCode)] = [:]

    private init() {
        bindAction("jump", keys: [.space, .w, .up])
        bindAction("fire", mouseButtons: [.left])
        bindAxis("horizontal", positive: .d, negative: .a)
        bindAxis("vertical", positive: .w, negative: .s)
        bindAxis("horizontal_arrows", positive: .right, negative: .left)
        bindAxis("vertical_arrows", positive: .up, negative: .down)
    }

    public func bindAction(_ name: String, keys: [KeyCode] = [], mouseButtons: [MouseButton] = []) {
        actions[name] = InputAction(keys: keys, mouseButtons: mouseButtons)
    }

    public func bindAxis(_ name: String, positive: KeyCode, negative: KeyCode) {
        axes[name] = (positive, negative)
    }

    public func keyDown(_ key: KeyCode) {
        if !keyDown.contains(key) { keyPressed.insert(key) }
        keyDown.insert(key)
        keyReleased.remove(key)
    }

    public func keyUp(_ key: KeyCode) {
        keyDown.remove(key)
        keyReleased.insert(key)
        keyPressed.remove(key)
    }

    public func mouseDown(_ button: MouseButton) {
        if !mouseDown.contains(button) { mousePressed.insert(button) }
        mouseDown.insert(button)
        mouseReleased.remove(button)
    }

    public func mouseUp(_ button: MouseButton) {
        mouseDown.remove(button)
        mouseReleased.insert(button)
        mousePressed.remove(button)
    }

    public func setMousePosition(_ pos: Vector2) {
        mouseDelta = pos - mousePosition
        mousePosition = pos
    }

    public func endFrame() {
        keyPressed.removeAll()
        keyReleased.removeAll()
        mousePressed.removeAll()
        mouseReleased.removeAll()
        mouseDelta = .zero
    }

    public func isKeyDown(_ key: KeyCode) -> Bool { keyDown.contains(key) }
    public func isKeyPressed(_ key: KeyCode) -> Bool { keyPressed.contains(key) }
    public func isKeyReleased(_ key: KeyCode) -> Bool { keyReleased.contains(key) }
    public func isMouseDown(_ button: MouseButton) -> Bool { mouseDown.contains(button) }
    public func isMousePressed(_ button: MouseButton) -> Bool { mousePressed.contains(button) }
    public func isMouseReleased(_ button: MouseButton) -> Bool { mouseReleased.contains(button) }

    public func isActionPressed(_ name: String) -> Bool {
        guard let action = actions[name] else { return false }
        if action.keys.contains(where: { isKeyPressed($0) }) { return true }
        if action.mouseButtons.contains(where: { isMousePressed($0) }) { return true }
        return false
    }

    public func isActionDown(_ name: String) -> Bool {
        guard let action = actions[name] else { return false }
        if action.keys.contains(where: { isKeyDown($0) }) { return true }
        if action.mouseButtons.contains(where: { isMouseDown($0) }) { return true }
        return false
    }

    public func getAxis(_ name: String) -> Float {
        guard let axis = axes[name] else { return 0 }
        var v: Float = 0
        if isKeyDown(axis.positive) { v += 1 }
        if isKeyDown(axis.negative) { v -= 1 }
        return v
    }
}

public let Input = InputSystem.shared
