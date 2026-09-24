import Foundation
import SGKMath
import SGKCore
import SGKECS

public enum BodyType: Sendable {
    case staticBody
    case kinematic
    case dynamic
}

public enum Shape2D: Sendable {
    case circle(radius: Float)
    case box(halfExtents: Vector2)
    case capsule(radius: Float, height: Float)
}

public struct RigidBody2D: Component, Sendable {
    public var bodyType: BodyType
    public var velocity: Vector2
    public var angularVelocity: Float
    public var mass: Float
    public var inverseMass: Float
    public var restitution: Float
    public var friction: Float
    public var isTrigger: Bool
    public var gravityScale: Float
    public var linearDamping: Float
    public var angularDamping: Float
    public var fixedRotation: Bool

    public init(
        bodyType: BodyType = .dynamic,
        mass: Float = 1.0,
        restitution: Float = 0.2,
        friction: Float = 0.3,
        isTrigger: Bool = false,
        gravityScale: Float = 1.0
    ) {
        self.bodyType = bodyType
        self.velocity = .zero
        self.angularVelocity = 0
        self.mass = max(mass, 0.0001)
        self.inverseMass = bodyType == .staticBody || bodyType == .kinematic ? 0 : 1.0 / self.mass
        self.restitution = restitution
        self.friction = friction
        self.isTrigger = isTrigger
        self.gravityScale = gravityScale
        self.linearDamping = 0.01
        self.angularDamping = 0.01
        self.fixedRotation = false
    }

    public mutating func applyForce(_ force: Vector2) {
        guard bodyType == .dynamic else { return }
        velocity += force * inverseMass
    }

    public mutating func applyImpulse(_ impulse: Vector2) {
        guard bodyType == .dynamic else { return }
        velocity += impulse * inverseMass
    }
}

public struct Collider2D: Component, Sendable {
    public var shape: Shape2D
    public var offset: Vector2
    public var layer: UInt32
    public var mask: UInt32

    public init(shape: Shape2D, offset: Vector2 = .zero, layer: UInt32 = 1, mask: UInt32 = 0xFFFFFFFF) {
        self.shape = shape
        self.offset = offset
        self.layer = layer
        self.mask = mask
    }
}

public struct CollisionInfo: Sendable {
    public let a: EntityID
    public let b: EntityID
    public let normal: Vector2
    public let penetration: Float
    public let contactPoint: Vector2
}

public protocol CollisionListener: AnyObject {
    func onCollisionEnter(_ info: CollisionInfo)
    func onCollisionStay(_ info: CollisionInfo)
    func onCollisionExit(_ info: CollisionInfo)
    func onTriggerEnter(_ info: CollisionInfo)
    func onTriggerExit(_ info: CollisionInfo)
}

public extension CollisionListener {
    func onCollisionEnter(_ info: CollisionInfo) {}
    func onCollisionStay(_ info: CollisionInfo) {}
    func onCollisionExit(_ info: CollisionInfo) {}
    func onTriggerEnter(_ info: CollisionInfo) {}
    func onTriggerExit(_ info: CollisionInfo) {}
}

public final class PhysicsWorld2D {
    public var gravity: Vector2 = Vector2(0, -9.81)
    public weak var listener: CollisionListener?

    private var pairs: Set<UInt64> = []

    public init() {}

    public func step(world: World, dt: Double) {
        let fdt = Float(dt)

        world.forEach(RigidBody2D.self) { entity, body in
            guard body.bodyType == .dynamic else { return }
            body.velocity += self.gravity * body.gravityScale * fdt
            body.velocity *= max(0, 1 - body.linearDamping * fdt)
            body.angularVelocity *= max(0, 1 - body.angularDamping * fdt)

            if var transform = world.get(Transform2DComponent.self, for: entity) {
                transform.position += body.velocity * fdt
                if !body.fixedRotation {
                    transform.rotation += body.angularVelocity * fdt
                }
                world.add(transform, to: entity)
            }
            world.add(body, to: entity)
        }

        var entities: [(EntityID, RigidBody2D, Collider2D, Transform2D)] = []
        world.forEach(RigidBody2D.self) { entity, body in
            if let col = world.get(Collider2D.self, for: entity),
               let t = world.get(Transform2DComponent.self, for: entity) {
                entities.append((entity, body, col, t.local))
            }
        }

        var currentPairs: Set<UInt64> = []

        for i in 0..<entities.count {
            for j in (i + 1)..<entities.count {
                let a = entities[i]
                let b = entities[j]
                if (a.2.layer & b.2.mask) == 0 || (b.2.layer & a.2.mask) == 0 { continue }

                if let contact = collide(a: a, b: b) {
                    let key = pairKey(a.0, b.0)
                    currentPairs.insert(key)
                    let isNew = !pairs.contains(key)

                    let info = CollisionInfo(
                        a: a.0, b: b.0,
                        normal: contact.normal,
                        penetration: contact.penetration,
                        contactPoint: contact.point
                    )

                    if a.1.isTrigger || b.1.isTrigger {
                        if isNew { listener?.onTriggerEnter(info) }
                    } else {
                        if isNew { listener?.onCollisionEnter(info) }
                        else { listener?.onCollisionStay(info) }
                        resolve(world: world, a: a, b: b, contact: contact)
                    }
                }
            }
        }
        pairs = currentPairs
    }

    private struct Contact {
        var normal: Vector2
        var penetration: Float
        var point: Vector2
    }

    private func collide(a: (EntityID, RigidBody2D, Collider2D, Transform2D), b: (EntityID, RigidBody2D, Collider2D, Transform2D)) -> Contact? {
        let posA = a.3.position + a.2.offset
        let posB = b.3.position + b.2.offset

        switch (a.2.shape, b.2.shape) {
        case (.circle(let ra), .circle(let rb)):
            let delta = posB - posA
            let dist = delta.length
            let sumR = ra + rb
            if dist >= sumR || dist < .ulpOfOne { return nil }
            let normal = delta.normalized
            return Contact(normal: normal, penetration: sumR - dist, point: posA + normal * ra)

        case (.box(let heA), .box(let heB)):
            let dx = abs(posB.x - posA.x)
            let dy = abs(posB.y - posA.y)
            let ox = heA.x + heB.x - dx
            let oy = heA.y + heB.y - dy
            if ox <= 0 || oy <= 0 { return nil }
            if ox < oy {
                let nx: Float = posB.x > posA.x ? 1 : -1
                return Contact(normal: Vector2(nx, 0), penetration: ox, point: Vector2(posA.x + nx * heA.x, posA.y))
            } else {
                let ny: Float = posB.y > posA.y ? 1 : -1
                return Contact(normal: Vector2(0, ny), penetration: oy, point: Vector2(posA.x, posA.y + ny * heA.y))
            }

        case (.circle(let r), .box(let he)), (.box(let he), .circle(let r)):
            let cPos: Vector2
            let bPos: Vector2
            let radius: Float
            let half: Vector2
            if case .circle = a.2.shape {
                cPos = posA; bPos = posB; radius = r; half = he
            } else {
                cPos = posB; bPos = posA; radius = r; half = he
            }
            let closest = Vector2(
                Math.clamp(cPos.x, min: bPos.x - half.x, max: bPos.x + half.x),
                Math.clamp(cPos.y, min: bPos.y - half.y, max: bPos.y + half.y)
            )
            let delta = cPos - closest
            let distSq = delta.lengthSquared
            if distSq >= radius * radius { return nil }
            let dist = sqrt(distSq)
            let normal = dist > .ulpOfOne ? delta / dist : Vector2(0, 1)
            return Contact(normal: normal, penetration: radius - dist, point: closest)

        default:
            return nil
        }
    }

    private func resolve(world: World, a: (EntityID, RigidBody2D, Collider2D, Transform2D), b: (EntityID, RigidBody2D, Collider2D, Transform2D), contact: Contact) {
        var bodyA = a.1
        var bodyB = b.1
        let invMassSum = bodyA.inverseMass + bodyB.inverseMass
        guard invMassSum > 0 else { return }

        let percent: Float = 0.8
        let slop: Float = 0.01
        let correction = contact.normal * max(contact.penetration - slop, 0) / invMassSum * percent
        if var ta = world.get(Transform2DComponent.self, for: a.0) {
            ta.position -= correction * bodyA.inverseMass
            world.add(ta, to: a.0)
        }
        if var tb = world.get(Transform2DComponent.self, for: b.0) {
            tb.position += correction * bodyB.inverseMass
            world.add(tb, to: b.0)
        }

        let relativeVel = bodyB.velocity - bodyA.velocity
        let velAlongNormal = relativeVel.dot(contact.normal)
        if velAlongNormal > 0 { return }

        let e = min(bodyA.restitution, bodyB.restitution)
        let j = -(1 + e) * velAlongNormal / invMassSum
        let impulse = contact.normal * j
        bodyA.velocity -= impulse * bodyA.inverseMass
        bodyB.velocity += impulse * bodyB.inverseMass

        world.add(bodyA, to: a.0)
        world.add(bodyB, to: b.0)
    }

    private func pairKey(_ a: EntityID, _ b: EntityID) -> UInt64 {
        let x = UInt64(a.index)
        let y = UInt64(b.index)
        return x < y ? (x << 32) | y : (y << 32) | x
    }

    public func raycast(world: World, origin: Vector2, direction: Vector2, maxDistance: Float = 1000) -> (entity: EntityID, point: Vector2, normal: Vector2, distance: Float)? {
        let dir = direction.normalized
        var closest: (EntityID, Vector2, Vector2, Float)? = nil

        world.forEach(Collider2D.self) { entity, col in
            guard let t = world.get(Transform2DComponent.self, for: entity) else { return }
            let pos = t.position + col.offset

            switch col.shape {
            case .circle(let r):
                let oc = origin - pos
                let a = dir.dot(dir)
                let b = 2 * oc.dot(dir)
                let c = oc.dot(oc) - r * r
                let disc = b * b - 4 * a * c
                if disc < 0 { return }
                let t1 = (-b - sqrt(disc)) / (2 * a)
                if t1 >= 0 && t1 <= maxDistance {
                    if closest == nil || t1 < closest!.3 {
                        let point = origin + dir * t1
                        let normal = (point - pos).normalized
                        closest = (entity, point, normal, t1)
                    }
                }
            case .box(let he):
                let minB = pos - he
                let maxB = pos + he
                var tmin: Float = 0
                var tmax: Float = maxDistance
                var hit = true
                for axis in 0..<2 {
                    let o = axis == 0 ? origin.x : origin.y
                    let d = axis == 0 ? dir.x : dir.y
                    let mn = axis == 0 ? minB.x : minB.y
                    let mx = axis == 0 ? maxB.x : maxB.y
                    if abs(d) < .ulpOfOne {
                        if o < mn || o > mx { hit = false; break }
                    } else {
                        var t1 = (mn - o) / d
                        var t2 = (mx - o) / d
                        if t1 > t2 { swap(&t1, &t2) }
                        tmin = max(tmin, t1)
                        tmax = min(tmax, t2)
                        if tmin > tmax { hit = false; break }
                    }
                }
                if hit && tmin >= 0 && tmin <= maxDistance {
                    if closest == nil || tmin < closest!.3 {
                        let point = origin + dir * tmin
                        let center = pos
                        let delta = point - center
                        let normal: Vector2
                        if abs(delta.x) / he.x > abs(delta.y) / he.y {
                            normal = Vector2(delta.x > 0 ? 1 : -1, 0)
                        } else {
                            normal = Vector2(0, delta.y > 0 ? 1 : -1)
                        }
                        closest = (entity, point, normal, tmin)
                    }
                }
            default:
                break
            }
        }
        return closest
    }
}
