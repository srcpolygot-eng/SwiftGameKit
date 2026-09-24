import XCTest
@testable import SGKMath

final class MathTests: XCTestCase {
    func testVector2Basics() {
        let a = Vector2(3, 4)
        XCTAssertEqual(a.length, 5, accuracy: 1e-5)
        XCTAssertEqual(a.normalized.length, 1, accuracy: 1e-5)
        XCTAssertEqual(a.dot(Vector2(3, 4)), 25, accuracy: 1e-5)
        let b = a + Vector2(1, 1)
        XCTAssertEqual(b.x, 4)
        XCTAssertEqual(b.y, 5)
    }

    func testVector3Cross() {
        let x = Vector3.unitX
        let y = Vector3.unitY
        let z = x.cross(y)
        XCTAssertTrue(Vector3.approximatelyEqual(z, Vector3.unitZ))
    }

    func testQuaternionIdentity() {
        let q = Quaternion.identity
        let v = Vector3(1, 2, 3)
        let r = q.rotate(v)
        XCTAssertTrue(Vector3.approximatelyEqual(r, v))
    }

    func testMatrix4Translation() {
        let m = Matrix4.translation(1, 2, 3)
        let p = m.transformPoint(Vector3.zero)
        XCTAssertTrue(Vector3.approximatelyEqual(p, Vector3(1, 2, 3)))
    }

    func testEasing() {
        XCTAssertEqual(Easing.linear.evaluate(0.5), 0.5, accuracy: 1e-5)
        XCTAssertEqual(Easing.easeInQuad.evaluate(0), 0, accuracy: 1e-5)
        XCTAssertEqual(Easing.easeInQuad.evaluate(1), 1, accuracy: 1e-5)
    }

    func testSeededRandomDeterministic() {
        var r1 = SeededRandom(seed: 12345)
        var r2 = SeededRandom(seed: 12345)
        for _ in 0..<10 {
            XCTAssertEqual(r1.nextFloat(), r2.nextFloat())
        }
    }

    func testLerp() {
        XCTAssertEqual(Math.lerp(0, 10, t: 0.5), 5, accuracy: 1e-5)
    }

    func testTransformComposition() {
        var t = Transform(position: Vector3(1, 0, 0))
        t.translate(by: Vector3(0, 2, 0))
        XCTAssertTrue(Vector3.approximatelyEqual(t.position, Vector3(1, 2, 0)))
    }
}
