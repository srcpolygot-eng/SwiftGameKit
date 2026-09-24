import Foundation
import SwiftGameKit

print("=== SwiftGameKit AI / Pathfinding Demo ===")

let grid = NavigationGrid(width: 20, height: 15)
// Walls
for y in 0..<10 {
    grid.setBlocked(8, y)
}
for x in 5..<15 {
    grid.setBlocked(x, 10)
}
grid.setBlocked(8, 5, blocked: false) // door

let start = GridNode(2, 2)
let goal = GridNode(17, 12)

if let path = Pathfinder.findPath(on: grid, from: start, to: goal) {
    print("Path found with \(path.count) nodes")
    print("Start: \(start), Goal: \(goal)")
    print("First 5: \(path.prefix(5).map { "(\($0.x),\($0.y))" }.joined(separator: " -> "))")
    print("Last 3: \(path.suffix(3).map { "(\($0.x),\($0.y))" }.joined(separator: " -> "))")
} else {
    print("No path found")
}

// FSM demo
class IdleState: State {
    func enter() { print("  Enter Idle") }
    func update(deltaTime: Double) {}
    func exit() { print("  Exit Idle") }
}
class ChaseState: State {
    func enter() { print("  Enter Chase") }
    func update(deltaTime: Double) {}
    func exit() { print("  Exit Chase") }
}

let fsm = StateMachine()
fsm.add("idle", state: IdleState())
fsm.add("chase", state: ChaseState())
fsm.change(to: "idle")
fsm.change(to: "chase")
print("AI demo completed.")
