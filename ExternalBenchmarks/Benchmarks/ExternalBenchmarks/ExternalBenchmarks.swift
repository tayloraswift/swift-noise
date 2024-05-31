import Benchmark
import Noise
import Foundation

let viewer_size: Int = 1024
let offset: Double = 0

// running at roughly 500ms for a pass, so maxDuration will limit far before iteration count for this
func cell2d() async -> Data {
    var pixbuf:[UInt8]  = [UInt8](repeating: 0, count: viewer_size * viewer_size)
    for (i, (x, y)) in Domain2D(samples_x: viewer_size, samples_y: viewer_size).enumerated() {
        pixbuf[i] = UInt8(max(0, min(255, CellNoise2D(amplitude: 255, frequency: 0.01).evaluate(x, y) + offset)))
    }
    return Data(pixbuf)
}

let benchmarks = {
    Benchmark.defaultConfiguration.maxIterations = .count(100_000) // same as default
    Benchmark.defaultConfiguration.maxDuration = .seconds(5)
    Benchmark.defaultConfiguration.metrics = [.throughput, .wallClock]
    
    Benchmark("cell2d") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(await cell2d())
        }
    }
}

