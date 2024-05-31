import Benchmark
import Noise
import Foundation

let viewer_size: Int = 1024
let offset: Double = 0

// running at roughly 500ms for a pass, so maxDuration will limit far before iteration count for this
//func cell2d() async -> Data {
//    var pixbuf:[UInt8]  = [UInt8](repeating: 0, count: viewer_size * viewer_size)
//    for (i, (x, y)) in Domain2D(samples_x: viewer_size, samples_y: viewer_size).enumerated() {
//        pixbuf[i] = UInt8(max(0, min(255, CellNoise2D(amplitude: 255, frequency: 0.01).evaluate(x, y) + offset)))
//    }
//    return Data(pixbuf)
//}

let benchmarks = {
    Benchmark.defaultConfiguration.maxIterations = .count(1024 * 1024) // Default = 100_000
    Benchmark.defaultConfiguration.maxDuration = .seconds(1) // Default = 1 second
    Benchmark.defaultConfiguration.metrics = [.throughput, .wallClock]
    
    Benchmark("cell2d") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(CellNoise2D(amplitude: 255, frequency: 0.01))
        }
    }
    Benchmark("cell3d") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(CellNoise3D(amplitude: 255, frequency: 0.01))
        }
    }

    Benchmark("cell_tiling3d") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(
                TilingCellNoise3D(amplitude: 255,
                                  frequency: 16 / Double(viewer_size),
                                  wavelengths: 16)
            )
        }
    }

    Benchmark("classic_tiling_fbm3d") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(
                FBM<TilingClassicNoise3D>(
                    tiling: TilingClassicNoise3D(amplitude: 255,
                                                 frequency: 16 / Double(viewer_size),
                                                 wavelengths: 16),
                    octaves: 10,
                    persistence: 0.62)
            )
        }
    }

    Benchmark("classic3d") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(
                FBM<ClassicNoise3D>(ClassicNoise3D(amplitude: 255, frequency: 0.001),
                    octaves: 10, persistence: 0.62)
            )
        }
    }

    
    Benchmark("classic_tiling3d") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(
                TilingClassicNoise3D(amplitude: 255, frequency: 16 / Double(viewer_size), wavelengths: 16)
            )
        }
    }
    Benchmark("gradient2d") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(
                FBM<GradientNoise2D>(GradientNoise2D(amplitude: 180, frequency: 0.001), octaves: 10, persistence: 0.62)
            )
        }
    }

    Benchmark("gradient3d") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(
                FBM<GradientNoise3D>(GradientNoise3D(amplitude: 180, frequency: 0.001), octaves: 10, persistence: 0.62)
            )
        }
    }

    
    
    
    
}

