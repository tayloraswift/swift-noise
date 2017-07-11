import Noise
import MaxPNG

import Tests

import func Glibc.clock

banners(width: 700, ratio: 5)

calibrate_noise(width: 256, height: 256)

var t0:Int

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
for (i, (x, y)) in Domain2D(samples_x: viewer_size, samples_y: viewer_size).enumerated()
{
    pixbuf[i] = UInt8(max(0, min(255, V.evaluate(x, y))))
}
print(clock() - t0)
try png_encode(path: "tests/cell2d.png", raw_data: pixbuf, properties: png_properties)

let V3:CellNoise3D = CellNoise3D(amplitude: 255, frequency: 0.01)
t0 = clock()
for (i, (x, y)) in Domain2D(samples_x: viewer_size, samples_y: viewer_size).enumerated()
{
    pixbuf[i] = UInt8(max(0, min(255, V3.evaluate(x, y))))
}
print(clock() - t0)
try png_encode(path: "tests/cell3d.png", raw_data: pixbuf, properties: png_properties)

let P:FBM<ClassicNoise3D> = FBM<ClassicNoise3D>(ClassicNoise3D(amplitude: 255, frequency: 0.001), octaves: 10, persistence: 0.62)
t0 = clock()
for (i, (x, y)) in Domain2D(samples_x: viewer_size, samples_y: viewer_size).enumerated()
{
    pixbuf[i] = UInt8(max(0, min(255, P.evaluate(x, y) + 127.5)))
}
print(clock() - t0)
try png_encode(path: "tests/classic3d.png", raw_data: pixbuf, properties: png_properties)

let PT:Noise = ClassicTilingNoise3D(amplitude: 255, frequency: 16 / Double(viewer_size), wavelengths: 16)
t0 = clock()
for (i, (x, y)) in Domain2D(samples_x: viewer_size, samples_y: viewer_size).enumerated()
{
    pixbuf[i] = UInt8(max(0, min(255, PT.evaluate(x, y) + 127.5)))
}
print(clock() - t0)
try png_encode(path: "tests/classic_tiling3d.png", raw_data: pixbuf, properties: png_properties)

let SS:FBM<GradientNoise2D> = FBM<GradientNoise2D>(GradientNoise2D(amplitude: 180, frequency: 0.001), octaves: 10, persistence: 0.62)
t0 = clock()
for (i, (x, y)) in Domain2D(samples_x: viewer_size, samples_y: viewer_size).enumerated()
{
    pixbuf[i] = UInt8(max(0, min(255, SS.evaluate(x, y) + 127.5)))
}
print(clock() - t0)
try png_encode(path: "tests/gradient2d.png", raw_data: pixbuf, properties: png_properties)

let SS3D:FBM<GradientNoise3D> = FBM<GradientNoise3D>(GradientNoise3D(amplitude: 180, frequency: 0.001), octaves: 10, persistence: 0.62)
t0 = clock()
for (i, (x, y)) in Domain2D(samples_x: viewer_size, samples_y: viewer_size).enumerated()
{
    pixbuf[i] = UInt8(max(0, min(255, SS3D.evaluate(x, y) + 127.5)))
}
print(clock() - t0)
try png_encode(path: "tests/gradient3d.png", raw_data: pixbuf, properties: png_properties)
