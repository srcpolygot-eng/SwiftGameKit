import Foundation

#if canImport(simd)
import simd
public typealias Float2 = SIMD2<Float>
public typealias Float3 = SIMD3<Float>
public typealias Float4 = SIMD4<Float>
public typealias Double2 = SIMD2<Double>
public typealias Double3 = SIMD3<Double>
public typealias Double4 = SIMD4<Double>
#else
public struct Float2: Equatable, Hashable, Codable, Sendable {
    public var x: Float
    public var y: Float
    public init(_ x: Float, _ y: Float) { self.x = x; self.y = y }
    public init(x: Float, y: Float) { self.x = x; self.y = y }
    public static let zero = Float2(0, 0)
}
public struct Float3: Equatable, Hashable, Codable, Sendable {
    public var x: Float
    public var y: Float
    public var z: Float
    public init(_ x: Float, _ y: Float, _ z: Float) { self.x = x; self.y = y; self.z = z }
    public init(x: Float, y: Float, z: Float) { self.x = x; self.y = y; self.z = z }
    public static let zero = Float3(0, 0, 0)
}
public struct Float4: Equatable, Hashable, Codable, Sendable {
    public var x: Float
    public var y: Float
    public var z: Float
    public var w: Float
    public init(_ x: Float, _ y: Float, _ z: Float, _ w: Float) { self.x = x; self.y = y; self.z = z; self.w = w }
    public init(x: Float, y: Float, z: Float, w: Float) { self.x = x; self.y = y; self.z = z; self.w = w }
    public static let zero = Float4(0, 0, 0, 0)
}
public struct Double2: Equatable, Hashable, Codable, Sendable {
    public var x: Double
    public var y: Double
    public init(_ x: Double, _ y: Double) { self.x = x; self.y = y }
    public static let zero = Double2(0, 0)
}
public struct Double3: Equatable, Hashable, Codable, Sendable {
    public var x: Double
    public var y: Double
    public var z: Double
    public init(_ x: Double, _ y: Double, _ z: Double) { self.x = x; self.y = y; self.z = z }
    public static let zero = Double3(0, 0, 0)
}
public struct Double4: Equatable, Hashable, Codable, Sendable {
    public var x: Double
    public var y: Double
    public var z: Double
    public var w: Double
    public init(_ x: Double, _ y: Double, _ z: Double, _ w: Double) { self.x = x; self.y = y; self.z = z; self.w = w }
    public static let zero = Double4(0, 0, 0, 0)
}
#endif
