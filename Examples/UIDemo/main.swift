import Foundation
import SwiftGameKit

print("=== UI Demo ===")

let canvas = UICanvas()
let panel = UIView(x: 100, y: 100, w: 400, h: 300)
let title = UILabel(text: "SwiftGameKit UI", x: 120, y: 120, fontSize: 22)
let healthBar = UIProgressBar(x: 120, y: 180, w: 300, h: 20)
healthBar.progress = 0.75
let button = UIButton(title: "Start Game", x: 180, y: 240)
button.onTap = { print("  Button tapped!") }

panel.addChild(title)
panel.addChild(healthBar)
panel.addChild(button)
canvas.root.addChild(panel)

print("UI hierarchy built.")
canvas.update(deltaTime: 0.016)
let renderer = Renderer.shared
canvas.render(renderer: renderer)
print("UI rendered (draw calls: \(renderer.drawCalls))")
print("UI demo completed.")
