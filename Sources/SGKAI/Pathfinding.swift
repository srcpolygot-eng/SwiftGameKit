import Foundation
import SGKMath
import SGKCore

public struct GridNode: Hashable, Sendable {
    public let x: Int
    public let y: Int
    public init(_ x: Int, _ y: Int) { self.x = x; self.y = y }
}

public final class NavigationGrid {
    public let width: Int
    public let height: Int
    public var costs: [[Float]] // 0 = blocked, >0 walkable cost

    public init(width: Int, height: Int, defaultCost: Float = 1) {
        self.width = width
        self.height = height
        self.costs = Array(repeating: Array(repeating: defaultCost, count: width), count: height)
    }

    public func setBlocked(_ x: Int, _ y: Int, blocked: Bool = true) {
        guard inBounds(x, y) else { return }
        costs[y][x] = blocked ? 0 : 1
    }

    public func setCost(_ x: Int, _ y: Int, cost: Float) {
        guard inBounds(x, y) else { return }
        costs[y][x] = max(0, cost)
    }

    public func isWalkable(_ x: Int, _ y: Int) -> Bool {
        inBounds(x, y) && costs[y][x] > 0
    }

    public func inBounds(_ x: Int, _ y: Int) -> Bool {
        x >= 0 && y >= 0 && x < width && y < height
    }

    public func neighbors(of node: GridNode, allowDiagonal: Bool = true) -> [(GridNode, Float)] {
        var result: [(GridNode, Float)] = []
        let dirs: [(Int, Int, Float)] = allowDiagonal
            ? [(-1,0,1),(1,0,1),(0,-1,1),(0,1,1),(-1,-1,1.414),(-1,1,1.414),(1,-1,1.414),(1,1,1.414)]
            : [(-1,0,1),(1,0,1),(0,-1,1),(0,1,1)]
        for (dx, dy, base) in dirs {
            let nx = node.x + dx
            let ny = node.y + dy
            if isWalkable(nx, ny) {
                result.append((GridNode(nx, ny), base * costs[ny][nx]))
            }
        }
        return result
    }
}

public struct Pathfinder {
    public static func findPath(
        on grid: NavigationGrid,
        from start: GridNode,
        to goal: GridNode,
        allowDiagonal: Bool = true
    ) -> [GridNode]? {
        guard grid.isWalkable(start.x, start.y), grid.isWalkable(goal.x, goal.y) else { return nil }
        if start == goal { return [start] }

        var open = PriorityQueue<GridNode>()
        var cameFrom: [GridNode: GridNode] = [:]
        var gScore: [GridNode: Float] = [start: 0]
        var fScore: [GridNode: Float] = [start: heuristic(start, goal)]

        open.push(start, priority: fScore[start]!)

        var closed = Set<GridNode>()

        while let current = open.pop() {
            if current == goal {
                return reconstruct(cameFrom, current)
            }
            closed.insert(current)

            for (neighbor, cost) in grid.neighbors(of: current, allowDiagonal: allowDiagonal) {
                if closed.contains(neighbor) { continue }
                let tentative = (gScore[current] ?? .infinity) + cost
                if tentative < (gScore[neighbor] ?? .infinity) {
                    cameFrom[neighbor] = current
                    gScore[neighbor] = tentative
                    let f = tentative + heuristic(neighbor, goal)
                    fScore[neighbor] = f
                    open.push(neighbor, priority: f)
                }
            }
        }
        return nil
    }

    private static func heuristic(_ a: GridNode, _ b: GridNode) -> Float {
        let dx = Float(abs(a.x - b.x))
        let dy = Float(abs(a.y - b.y))
        return sqrt(dx * dx + dy * dy)
    }

    private static func reconstruct(_ cameFrom: [GridNode: GridNode], _ current: GridNode) -> [GridNode] {
        var path = [current]
        var c = current
        while let prev = cameFrom[c] {
            path.append(prev)
            c = prev
        }
        return path.reversed()
    }
}

/// Simple binary heap priority queue.
public struct PriorityQueue<T: Hashable> {
    private var elements: [(T, Float)] = []
    private var positions: [T: Int] = [:]

    public init() {}

    public mutating func push(_ element: T, priority: Float) {
        if let idx = positions[element] {
            if priority < elements[idx].1 {
                elements[idx].1 = priority
                siftUp(idx)
            }
            return
        }
        elements.append((element, priority))
        positions[element] = elements.count - 1
        siftUp(elements.count - 1)
    }

    public mutating func pop() -> T? {
        guard !elements.isEmpty else { return nil }
        let result = elements[0].0
        positions[result] = nil
        let last = elements.removeLast()
        if !elements.isEmpty {
            elements[0] = last
            positions[last.0] = 0
            siftDown(0)
        }
        return result
    }

    private mutating func siftUp(_ index: Int) {
        var i = index
        while i > 0 {
            let parent = (i - 1) / 2
            if elements[i].1 < elements[parent].1 {
                elements.swapAt(i, parent)
                positions[elements[i].0] = i
                positions[elements[parent].0] = parent
                i = parent
            } else { break }
        }
    }

    private mutating func siftDown(_ index: Int) {
        var i = index
        while true {
            let left = 2 * i + 1
            let right = 2 * i + 2
            var smallest = i
            if left < elements.count && elements[left].1 < elements[smallest].1 {
                smallest = left
            }
            if right < elements.count && elements[right].1 < elements[smallest].1 {
                smallest = right
            }
            if smallest != i {
                elements.swapAt(i, smallest)
                positions[elements[i].0] = i
                positions[elements[smallest].0] = smallest
                i = smallest
            } else { break }
        }
    }
}

// MARK: - FSM

public protocol State: AnyObject {
    func enter()
    func update(deltaTime: Double)
    func exit()
}

public extension State {
    func enter() {}
    func update(deltaTime: Double) {}
    func exit() {}
}

public final class StateMachine {
    public private(set) var current: (any State)?
    private var states: [String: any State] = [:]

    public func add(_ name: String, state: any State) {
        states[name] = state
    }

    public func change(to name: String) {
        current?.exit()
        current = states[name]
        current?.enter()
    }

    public func update(deltaTime: Double) {
        current?.update(deltaTime: deltaTime)
    }
}
