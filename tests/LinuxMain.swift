import Noise
import MaxPNG

import Tests

import func Glibc.clock

banners(width: 700, ratio: 5)

calibrate_noise(width: 256, height: 256)

let viewer_size:Int = 1024
var pixbuf:[UInt8]  = [UInt8](repeating: 0, count: viewer_size * viewer_size)
let png_properties:PNGProperties = PNGProperties(width: viewer_size, height: viewer_size, bit_depth: 8, color: .grayscale, interlaced: false)!

func benchmark<Generator>(noise generator:Generator, name:String, offset:Double = 0) where Generator:Noise
{
    let t0:Int = clock()
    for (i, (x, y)) in Domain2D(samples_x: viewer_size, samples_y: viewer_size).enumerated()
    {
        pixbuf[i] = UInt8(max(0, min(255, generator.evaluate(x, y) + offset)))
    }
    print("\(name): \(clock() - t0)")
    try! png_encode(path: "tests/\(name).png", raw_data: pixbuf, properties: png_properties)
}

var poisson = DiskSampler2D(seed: 0)
let t0:Int = clock()
for point:(x:Double, y:Double) in poisson.generate(radius: 10, width: viewer_size, height: viewer_size)
{
    pixbuf[Int(point.y) * viewer_size + Int(point.x)] = 255
}
print("disk2d: \(clock() - t0)")
try png_encode(path: "tests/disk2d.png", raw_data: pixbuf, properties: png_properties)

benchmark(noise: CellNoise2D(amplitude: 255, frequency: 0.01), name: "cell2d")
benchmark(noise: CellNoise3D(amplitude: 255, frequency: 0.01), name: "cell3d")
benchmark(  noise: TilingCellNoise3D(   amplitude: 255, frequency: 16 / Double(viewer_size),
                                        wavelengths: 16),
            name: "cell_tiling3d")
benchmark(  noise: FBM<TilingClassicNoise3D>(tiling: TilingClassicNoise3D(  amplitude: 255,
                                                                            frequency: 16 / Double(viewer_size),
                                                                            wavelengths: 16),
                                                octaves: 10, persistence: 0.62),
            name: "classic_tiling_fbm3d",
            offset: 127.5)
benchmark(  noise: FBM<ClassicNoise3D>( ClassicNoise3D(amplitude: 255, frequency: 0.001),
                                        octaves: 10, persistence: 0.62),
            name: "classic3d",
            offset: 127.5)
benchmark(  noise: TilingClassicNoise3D(amplitude: 255, frequency: 16 / Double(viewer_size), wavelengths: 16),
            name: "classic_tiling3d",
            offset: 127.5)
benchmark(noise: FBM<GradientNoise2D>(GradientNoise2D(amplitude: 180, frequency: 0.001), octaves: 10, persistence: 0.62),
            name: "gradient2d",
            offset: 127.5)
benchmark(noise: FBM<GradientNoise3D>(GradientNoise3D(amplitude: 180, frequency: 0.001), octaves: 10, persistence: 0.62),
            name: "gradient3d",
            offset: 127.5)
