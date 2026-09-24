import Foundation
import SGKMath
import SGKCore

/// Autonomous agent that follows paths on a navigation grid.
public final class NavigationAgent {
    public var position: Vector2
    public var speed: Float
    public var stoppingDistance: Float
    public var path: [GridNode] = []
    public private(set) var pathIndex: Int = 0
    public var isStopped: Bool = false
    public weak var grid: NavigationGrid?

    public var hasPath: Bool { !path.isEmpty && pathIndex < path.count }
    public var remainingDistance: Float {
        guard hasPath else { return 0 }
        var dist: Float = 0
        var prev = position
        for i in pathIndex..<path.count {
            let node = path[i]
            let p = Vector2(Float(node.x), Float(node.y))
            dist += prev.distance(to: p)
            prev = p
        }
        return dist
    }

    public init(position: Vector2 = .zero, speed: Float = 3.0, stoppingDistance: Float = 0.15) {
        self.position = position
        self.speed = speed
        self.stoppingDistance = stoppingDistance
    }

    public func setDestination(_ goal: GridNode, on grid: NavigationGrid) -> Bool {
        self.grid = grid
        let start = GridNode(Int(position.x.rounded()), Int(position.y.rounded()))
        guard let found = Pathfinder.findPath(on: grid, from: start, to: goal) else {
            path = []
            pathIndex = 0
            return false
        }
        path = found
        pathIndex = 0
        isStopped = false
        return true
    }

    public func setDestination(worldPoint: Vector2, on grid: NavigationGrid) -> Bool {
        let goal = GridNode(Int(worldPoint.x.rounded()), Int(worldPoint.y.rounded()))
        return setDestination(goal, on: grid)
    }

    /// Advance along the path. Returns true if still moving.
    @discardableResult
    public func update(deltaTime: Float) -> Bool {
        guard !isStopped, hasPath else { return false }
        let targetNode = path[pathIndex]
        let target = Vector2(Float(targetNode.x), Float(targetNode.y))
        let delta = target - position
        let dist = delta.length

        if dist <= stoppingDistance {
            pathIndex += 1
            if pathIndex >= path.count {
                position = target
                isStopped = true
                return false
            }
            return true
        }

        let step = min(speed * deltaTime, dist)
        position += delta.normalized * step
        return true
    }

    public func stop() {
        isStopped = true
        path = []
        pathIndex = 0
    }

    public func resetPath() {
        path = []
        pathIndex = 0
        isStopped = false
    }
}

/// Simple steering helpers for agents.
public enum Steering {
    public static func seek(current: Vector2, target: Vector2, maxSpeed: Float) -> Vector2 {
        let desired = (target - current).normalized * maxSpeed
        return desired
    }

    public static func arrive(current: Vector2, target: Vector2, maxSpeed: Float, slowingRadius: Float) -> Vector2 {
        let toTarget = target - current
        let dist = toTarget.length
        if dist < .ulpOfOne { return .zero }
        let speed = dist < slowingRadius ? maxSpeed * (dist / slowingRadius) : maxSpeed
        return toTarget.normalized * speed
    }

    public static func flee(current: Vector2, threat: Vector2, maxSpeed: Float) -> Vector2 {
        let desired = (current - threat).normalized * maxSpeed
        return desired
    }
}
