import Foundation
import SGKMath
import SGKCore
import SGKInput
import SGKRendering

public protocol UIElement: AnyObject {
    var frame: (x: Float, y: Float, w: Float, h: Float) { get set }
    var isVisible: Bool { get set }
    var isInteractive: Bool { get set }
    func update(deltaTime: Float)
    func render(renderer: Renderer)
    func handleInput(_ input: InputSystem) -> Bool
}

public class UIView: UIElement {
    public var frame: (x: Float, y: Float, w: Float, h: Float)
    public var isVisible = true
    public var isInteractive = true
    public var children: [UIElement] = []
    public var backgroundColor: Vector4 = Vector4(0.2, 0.2, 0.25, 0.9)

    public init(x: Float, y: Float, w: Float, h: Float) {
        frame = (x, y, w, h)
    }

    public func addChild(_ child: UIElement) {
        children.append(child)
    }

    public func update(deltaTime: Float) {
        for c in children { c.update(deltaTime: deltaTime) }
    }

    public func render(renderer: Renderer) {
        guard isVisible else { return }
        renderer.drawSprite(texture: "ui_panel", position: Vector2(frame.x, frame.y), size: Vector2(frame.w, frame.h), color: backgroundColor)
        for c in children { c.render(renderer: renderer) }
    }

    public func handleInput(_ input: InputSystem) -> Bool {
        guard isVisible && isInteractive else { return false }
        for c in children.reversed() {
            if c.handleInput(input) { return true }
        }
        return false
    }
}

public class UILabel: UIElement {
    public var frame: (x: Float, y: Float, w: Float, h: Float)
    public var isVisible = true
    public var isInteractive = false
    public var text: String
    public var fontSize: Float
    public var color: Vector4

    public init(text: String, x: Float, y: Float, fontSize: Float = 16, color: Vector4 = .one) {
        self.text = text
        self.fontSize = fontSize
        self.color = color
        self.frame = (x, y, 200, fontSize + 4)
    }

    public func update(deltaTime: Float) {}
    public func render(renderer: Renderer) {
        guard isVisible else { return }
        renderer.backend.drawText(text, position: Vector2(frame.x, frame.y), size: fontSize, color: color)
    }
    public func handleInput(_ input: InputSystem) -> Bool { false }
}

public class UIButton: UIElement {
    public var frame: (x: Float, y: Float, w: Float, h: Float)
    public var isVisible = true
    public var isInteractive = true
    public var title: String
    public var onTap: (() -> Void)?
    public var normalColor = Vector4(0.3, 0.5, 0.8, 1)
    public var hoverColor = Vector4(0.4, 0.6, 0.9, 1)
    private var isHovered = false

    public init(title: String, x: Float, y: Float, w: Float = 120, h: Float = 36) {
        self.title = title
        self.frame = (x, y, w, h)
    }

    public func update(deltaTime: Float) {}

    public func render(renderer: Renderer) {
        guard isVisible else { return }
        let color = isHovered ? hoverColor : normalColor
        renderer.drawSprite(texture: "ui_button", position: Vector2(frame.x, frame.y), size: Vector2(frame.w, frame.h), color: color)
        renderer.backend.drawText(title, position: Vector2(frame.x + 10, frame.y + 8), size: 14, color: .one)
    }

    public func handleInput(_ input: InputSystem) -> Bool {
        guard isVisible && isInteractive else { return false }
        let m = input.mousePosition
        isHovered = m.x >= frame.x && m.x <= frame.x + frame.w && m.y >= frame.y && m.y <= frame.y + frame.h
        if isHovered && input.isMousePressed(.left) {
            onTap?()
            return true
        }
        return false
    }
}

public class UIProgressBar: UIElement {
    public var frame: (x: Float, y: Float, w: Float, h: Float)
    public var isVisible = true
    public var isInteractive = false
    public var progress: Float = 1
    public var fillColor = Vector4(0.2, 0.8, 0.3, 1)
    public var backgroundColor = Vector4(0.15, 0.15, 0.15, 1)

    public init(x: Float, y: Float, w: Float = 200, h: Float = 16) {
        frame = (x, y, w, h)
    }

    public func update(deltaTime: Float) {}
    public func render(renderer: Renderer) {
        guard isVisible else { return }
        renderer.drawSprite(texture: "ui_bar_bg", position: Vector2(frame.x, frame.y), size: Vector2(frame.w, frame.h), color: backgroundColor)
        let fillW = frame.w * Math.clamp(progress, min: 0, max: 1)
        renderer.drawSprite(texture: "ui_bar_fill", position: Vector2(frame.x, frame.y), size: Vector2(fillW, frame.h), color: fillColor)
    }
    public func handleInput(_ input: InputSystem) -> Bool { false }
}

public final class UICanvas {
    public var root = UIView(x: 0, y: 0, w: 1280, h: 720)

    public init() {}

    public func update(deltaTime: Float) {
        root.update(deltaTime: deltaTime)
        _ = root.handleInput(Input)
    }

    public func render(renderer: Renderer) {
        root.render(renderer: renderer)
    }
}
