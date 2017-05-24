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

let random_index_table:[Int] = [
172, 53, 72, 76, 104, 13, 177, 111, 168, 35, 105, 75, 165, 148, 127, 43, 57, 122,
131, 103, 242, 78, 107, 161, 162, 33, 150, 64, 252, 236, 119, 118, 152, 85, 157,
38, 29, 198, 84, 225, 83, 117, 143, 142, 114, 0, 145, 45, 139, 121, 223, 120, 185,
7, 82, 212, 196, 58, 234, 244, 255, 81, 55, 28, 24, 91, 89, 100, 174, 65, 34, 208,
140, 135, 125, 241, 229, 194, 109, 17, 90, 169, 232, 167, 138, 32, 190, 124, 213,
195, 9, 233, 137, 46, 12, 6, 253, 77, 202, 98, 70, 200, 239, 80, 203, 224, 59, 166,
181, 249, 99, 88, 49, 160, 86, 133, 154, 149, 215, 1, 186, 251, 226, 146, 227,
183, 176, 246, 5, 42, 61, 31, 23, 126, 123, 62, 27, 50, 110, 20, 48, 221, 14, 18,
201, 130, 92, 151, 191, 189, 44, 25, 209, 67, 199, 141, 11, 182, 36, 19, 216, 87,
21, 205, 153, 3, 245, 15, 113, 192, 254, 214, 56, 210, 8, 71, 204, 66, 134, 193,
235, 218, 102, 217, 147, 97, 250, 188, 37, 69, 40, 2, 197, 73, 178, 112, 51, 159,
219, 238, 39, 211, 247, 108, 173, 116, 93, 206, 184, 243, 248, 171, 4, 68, 26, 164,
16, 106, 96, 54, 60, 128, 179, 132, 207, 63, 101, 230, 52, 95, 129, 144, 10, 158,
156, 231, 237, 79, 180, 240, 228, 170, 115, 222, 175, 22, 220, 94, 187, 163, 155,
136, 30, 47, 41, 74]

let SQUISH_2D :Double = 0.5 * (1 / 3.squareRoot() - 1)
let STRETCH_2D:Double = 0.5 * (3.squareRoot() - 1)

func floor(_ x:Double) -> Int
{
    return x > 0 ? Int(x) : Int(x) - 1
}

func octaves(_ x:Double, _ y:Double, f function:(Double, Double) -> Double, frequency:Double, octaves:Int, persistence:Double = 0.66666666666) -> Double
{
    var f:Double = frequency,
        k:Double = 1,
        z:Double = 0
    for _ in 0 ..< octaves
    {
        z += k * function(f*x, f*y)
        k *= persistence
        f *= 2
    }
    return z
}

import func Glibc.clock

var pixbuf:[UInt8] = [UInt8](repeating: 0, count: viewer_size * viewer_size)
let png_properties:PNGProperties = PNGProperties(width: viewer_size, height: viewer_size, bit_depth: 8, color: .grayscale, interlaced: false)!

var t0:Int = clock()
/*
for y in 0 ..< viewer_size
{
    for x in 0 ..< viewer_size
    {
        let noise:Double = octaves(Double(x), Double(y), f: simplex, frequency: 0.00083429273, octaves: 12, persistence: 0.75)
        pixbuf[y * viewer_size + x] = UInt8(max(0, min(255, 255 * (noise / 2 + 0.5))))
    }
}
print(clock() - t0)

try png_encode(path: "simplex.png", raw_data: pixbuf, properties: png_properties)
*/
t0 = clock()
for y in 0 ..< viewer_size
{
    for x in 0 ..< viewer_size
    {
        let noise:Double = octaves(Double(x), Double(y), f: super_simplex, frequency: 0.00083429273, octaves: 12, persistence: 0.75)
        pixbuf[y * viewer_size + x] = UInt8(max(0, min(255, 255 * (noise / 2 + 0.5))))
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
