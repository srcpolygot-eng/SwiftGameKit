import Foundation
import SwiftGameKit

print("=== Simple 3D Scene Example ===")

let world = World()
let camera = world.createEntity()
world.add(TransformComponent(local: Transform(position: Vector3(0, 2, 5))), to: camera)
world.add(CameraComponent(isOrthographic: false, fov: 60 * Math.degToRad), to: camera)

let cube = world.createEntity()
world.add(TransformComponent(local: Transform(position: Vector3(0, 0, 0))), to: cube)
world.add(NameComponent("Cube"), to: cube)

let mesh = MeshDescriptor.cube(size: 1)
print("Cube mesh vertices: \(mesh.vertices.count), indices: \(mesh.indices.count)")

var angle: Float = 0
for frame in 0..<60 {
    angle += 0.05
    if var t = world.get(TransformComponent.self, for: cube) {
        t.rotation = .fromAxisAngle(axis: Vector3.up, angle: angle)
        world.add(t, to: cube)
    }
    if frame % 20 == 0 {
        let angleStr = String(format: "%.2f", angle)
        print("  Frame \(frame): rotation angle \(angleStr)")
    }
}

let view = Matrix4.lookAt(eye: Vector3(0, 2, 5), target: .zero, up: .up)
let proj = Matrix4.perspective(fovY: 60 * Math.degToRad, aspect: 16/9, near: 0.1, far: 100)
print("View/Projection matrices computed.")
print("3D example completed.")
