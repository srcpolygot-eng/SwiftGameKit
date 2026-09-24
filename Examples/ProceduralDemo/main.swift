import Foundation
import SwiftGameKit

print("=== Procedural Generation Demo (V2) ===")

let noise = ValueNoise(seed: 42)
print("Noise sample: \(noise.noise(3.2, 7.1))")
print("FBM sample: \(noise.fbm(3.2, 7.1, octaves: 5))")

let caves = CellularAutomata.generate(width: 32, height: 16, fillProbability: 0.45, seed: 99, steps: 5)
var wallCount = 0
for row in caves { wallCount += row.filter { $0 }.count }
print("Cave map walls: \(wallCount)/\(32*16)")

let rooms = ProcGen.generateRooms(mapWidth: 50, mapHeight: 40, roomCount: 10, seed: 7)
print("Rooms placed: \(rooms.count)")
for (i, r) in rooms.prefix(3).enumerated() {
    print("  Room \(i): (\(r.x),\(r.y)) \(r.w)x\(r.h)")
}

print("Procedural demo completed.")
