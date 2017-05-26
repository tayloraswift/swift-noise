import Noise

import MaxPNG

let viewer_size:Int = 1024

func rgba_from_argb32(_ argb32:[UInt32]) -> [UInt8]
{
    var rgba:[UInt8] = []
    rgba.reserveCapacity(argb32.count * 4)
    for argb in argb32
    {
        rgba.append(UInt8(truncatingBitPattern: argb >> 16))
        rgba.append(UInt8(truncatingBitPattern: argb >> 8 ))
        rgba.append(UInt8(truncatingBitPattern: argb      ))
        rgba.append(UInt8(truncatingBitPattern: argb >> 24))
    }
    return rgba
}

import func Glibc.clock

var pixbuf:[UInt8]
let png_properties:PNGProperties = PNGProperties(width: viewer_size, height: viewer_size, bit_depth: 8, color: .grayscale, interlaced: false)!

var t0:Int

let S:fBm<Simplex2D> = fBm<Simplex2D>(amplitude: 1, frequency: 0.00083429273, octaves: 10)
t0 = clock()
pixbuf = S.noise2d(width: viewer_size, height: viewer_size)
print(clock() - t0)
try png_encode(path: "simplex.png", raw_data: pixbuf, properties: png_properties)


let SS:fBm<SuperSimplex2D> = fBm<SuperSimplex2D>(amplitude: 1, frequency: 0.00083429273, octaves: 10)
t0 = clock()
pixbuf = SS.noise2d(width: viewer_size, height: viewer_size)
print(clock() - t0)
try png_encode(path: "super_simplex.png", raw_data: pixbuf, properties: png_properties)

let SS3D:fBm<SuperSimplex3D> = fBm<SuperSimplex3D>(amplitude: 1, frequency: 0.00083429273, octaves: 10)
t0 = clock()
pixbuf = SS3D.noise2d(width: viewer_size, height: viewer_size)
print(clock() - t0)
try png_encode(path: "super_simplex3D.png", raw_data: pixbuf, properties: png_properties)
