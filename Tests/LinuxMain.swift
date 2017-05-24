import Noise

import MaxPNG
import SwiftCairo

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

var pixbuf:[UInt8] = [UInt8](repeating: 0, count: viewer_size * viewer_size)
let png_properties:PNGProperties = PNGProperties(width: viewer_size, height: viewer_size, bit_depth: 8, color: .grayscale, interlaced: false)!

var t0:Int

let S:fBm<Simplex2D> = fBm<Simplex2D>(amplitude: 127 / 20, frequency: 0.00083429273, octaves: 10)
t0 = clock()
for y in 0 ..< viewer_size
{
    for x in 0 ..< viewer_size
    {
        let noise:Double = S.evaluate(Double(x), Double(y))
        pixbuf[y * viewer_size + x] = UInt8(max(0, min(255, noise + 127)))
    }
}
print(clock() - t0)
try png_encode(path: "simplex.png", raw_data: pixbuf, properties: png_properties)


let SS:fBm<SuperSimplex2D> = fBm<SuperSimplex2D>(amplitude: 127, frequency: 0.00083429273, octaves: 10)
t0 = clock()
for y in 0 ..< viewer_size
{
    for x in 0 ..< viewer_size
    {
        let noise:Double = SS.evaluate(Double(x), Double(y))
        pixbuf[y * viewer_size + x] = UInt8(max(0, min(255, noise + 127)))
    }
}
print(clock() - t0)
try png_encode(path: "super_simplex.png", raw_data: pixbuf, properties: png_properties)


/*
var pixbuf:[UInt32] = [UInt32](repeating: 0, count: viewer_size * viewer_size)
let png_properties:PNGProperties = PNGProperties(width: viewer_size, height: viewer_size, bit_depth: 8, color: .rgba, interlaced: false)!

let surface:CairoSurface = CairoSurface(withoutOwningBuffer: &pixbuf, format: .argb32, width: viewer_size, height: viewer_size)!
let cr:CairoContext = surface.create()

cr.set_source_rgba(1, 0.2, 0.5, 1)
cr.move_to(200, 200)
cr.arc(x: 200, y: 200, r: 100)
cr.fill()

print(pixbuf[0...3])
try png_encode(path: "viewer.png", raw_data: rgba_from_argb32(pixbuf), properties: png_properties)
*/
