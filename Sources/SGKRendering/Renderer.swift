import Foundation
import SGKMath
import SGKCore
import SGKScene

public protocol RenderBackend: AnyObject {
    func beginFrame()
    func endFrame()
    func clear(color: Vector4)
    func setViewport(x: Int, y: Int, width: Int, height: Int)
    func drawSprite(texture: String, position: Vector2, size: Vector2, rotation: Float, color: Vector4, layer: Int)
    func drawMesh(meshID: String, transform: Matrix4, material: String)
    func drawLine(from: Vector2, to: Vector2, color: Vector4)
    func drawText(_ text: String, position: Vector2, size: Float, color: Vector4)
}

public final class NullRenderBackend: RenderBackend {
    public var drawCalls = 0
    public init() {}
    public func beginFrame() { drawCalls = 0 }
    public func endFrame() {}
    public func clear(color: Vector4) {}
    public func setViewport(x: Int, y: Int, width: Int, height: Int) {}
    public func drawSprite(texture: String, position: Vector2, size: Vector2, rotation: Float, color: Vector4, layer: Int) {
        drawCalls += 1
    }
    public func drawMesh(meshID: String, transform: Matrix4, material: String) { drawCalls += 1 }
    public func drawLine(from: Vector2, to: Vector2, color: Vector4) { drawCalls += 1 }
    public func drawText(_ text: String, position: Vector2, size: Float, color: Vector4) { drawCalls += 1 }
}

public final class Renderer: @unchecked Sendable {
    public static let shared = Renderer()
    public var backend: RenderBackend = NullRenderBackend()
    public private(set) var drawCalls: Int = 0

    private init() {}

    public func beginFrame() {
        backend.beginFrame()
        drawCalls = 0
    }

    public func endFrame() {
        backend.endFrame()
        if let null = backend as? NullRenderBackend {
            drawCalls = null.drawCalls
        }
    }

    public func clear(color: Vector4 = Vector4(0.1, 0.1, 0.15, 1)) {
        backend.clear(color: color)
    }

    public func drawSprite(texture: String, position: Vector2, size: Vector2 = Vector2(32, 32), rotation: Float = 0, color: Vector4 = .one, layer: Int = 0) {
        backend.drawSprite(texture: texture, position: position, size: size, rotation: rotation, color: color, layer: layer)
        drawCalls += 1
    }

    public func drawMesh(meshID: String, transform: Matrix4, material: String = "default") {
        backend.drawMesh(meshID: meshID, transform: transform, material: material)
        drawCalls += 1
    }
}

public struct Material: Sendable {
    public var name: String
    public var albedo: Vector4
    public var metallic: Float
    public var roughness: Float
    public var textureID: String?

    public init(name: String = "default", albedo: Vector4 = .one, metallic: Float = 0, roughness: Float = 0.5, textureID: String? = nil) {
        self.name = name
        self.albedo = albedo
        self.metallic = metallic
        self.roughness = roughness
        self.textureID = textureID
    }
}

public struct MeshDescriptor: Sendable {
    public var name: String
    public var vertices: [Vector3]
    public var normals: [Vector3]
    public var uvs: [Vector2]
    public var indices: [UInt32]

    public init(name: String, vertices: [Vector3], normals: [Vector3] = [], uvs: [Vector2] = [], indices: [UInt32] = []) {
        self.name = name
        self.vertices = vertices
        self.normals = normals
        self.uvs = uvs
        self.indices = indices
    }

    public static func cube(size: Float = 1) -> MeshDescriptor {
        let h = size * 0.5
        let verts: [Vector3] = [
            Vector3(-h,-h,-h), Vector3(h,-h,-h), Vector3(h,h,-h), Vector3(-h,h,-h),
            Vector3(-h,-h,h), Vector3(h,-h,h), Vector3(h,h,h), Vector3(-h,h,h)
        ]
        let indices: [UInt32] = [
            0,1,2, 0,2,3, 4,6,5, 4,7,6,
            0,4,5, 0,5,1, 2,6,7, 2,7,3,
            0,3,7, 0,7,4, 1,5,6, 1,6,2
        ]
        return MeshDescriptor(name: "cube", vertices: verts, indices: indices)
    }
}
