import Noise
import MaxPNG

import func Glibc.clock

var t0:Int

banners(width: 700, ratio: 5)

let viewer_size:Int = 1024
var pixbuf:[UInt8]
let png_properties:PNGProperties = PNGProperties(width: viewer_size, height: viewer_size, bit_depth: 8, color: .grayscale, interlaced: false)!

var poisson = DiskSampler2D(seed: 0)
t0 = clock()
pixbuf = [UInt8](repeating: 0, count: viewer_size * viewer_size)
for point:(x:Double, y:Double) in poisson.generate(radius: 10, width: viewer_size, height: viewer_size)
{
    pixbuf[Int(point.y) * viewer_size + Int(point.x)] = 255
}
print(clock() - t0)
try png_encode(path: "tests/disk2d.png", raw_data: pixbuf, properties: png_properties)


let V:CellNoise2D = CellNoise2D(amplitude: 255, frequency: 0.01)
t0 = clock()
for (i, (x, y)):(offset:Int, element:(Double, Double)) in Domain2D(samples_x: viewer_size, samples_y: viewer_size).enumerated()
{
    pixbuf[i] = UInt8(max(0, min(255, V.evaluate(x, y))))
}
print(clock() - t0)
try png_encode(path: "tests/cell2d.png", raw_data: pixbuf, properties: png_properties)

let V3:CellNoise3D = CellNoise3D(amplitude: 255, frequency: 0.01)
t0 = clock()
pixbuf = V3.sample_area_saturated_to_u8(width: viewer_size, height: viewer_size, offset: 0)
print(clock() - t0)
try png_encode(path: "tests/cell3d.png", raw_data: pixbuf, properties: png_properties)


let S:FBM<SimplexNoise2D> = FBM<SimplexNoise2D>(amplitude: 0.5*127.5, frequency: 0.001, octaves: 10)
t0 = clock()
for (i, (x, y)):(offset:Int, element:(Double, Double)) in Domain2D(samples_x: viewer_size, samples_y: viewer_size).enumerated()
{
    pixbuf[i] = UInt8(max(0, min(255, S.evaluate(x, y) + 127.5)))
}
print(clock() - t0)
try png_encode(path: "tests/simplex2d.png", raw_data: pixbuf, properties: png_properties)


let SS:FBM<SuperSimplexNoise2D> = FBM<SuperSimplexNoise2D>(amplitude: 0.5*127.5, frequency: 0.001, octaves: 10)
t0 = clock()
for (i, (x, y)):(offset:Int, element:(Double, Double)) in Domain2D(samples_x: viewer_size, samples_y: viewer_size).enumerated()
{
    pixbuf[i] = UInt8(max(0, min(255, SS.evaluate(x, y) + 127.5)))
}
print(clock() - t0)
try png_encode(path: "tests/super_simplex2d.png", raw_data: pixbuf, properties: png_properties)

let SS3D:FBM<SuperSimplexNoise3D> = FBM<SuperSimplexNoise3D>(amplitude: 0.5*127.5, frequency: 0.001, octaves: 10)
t0 = clock()
pixbuf = SS3D.sample_area_saturated_to_u8(width: viewer_size, height: viewer_size, offset: 127.5)
print(clock() - t0)
try png_encode(path: "tests/super_simplex3d.png", raw_data: pixbuf, properties: png_properties)
