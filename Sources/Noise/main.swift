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

let simplex_gradient_table_2d:[Double] =
[
    -1, -1,     1,  0,    -1,  0,     1,  1,
    -1,  1,     0, -1,     0,  1,     1, -1
]

let STRETCH_2D  :Double = 0.5 * (1 / 3.squareRoot() - 1)
let UNSTRETCH_2D:Double = 0.5 * (3.squareRoot() - 1)
let NORMALIZATION_2D:Double = 1/14

func floor(_ x:Double) -> Int
{
    return x > 0 ? Int(x) : Int(x) - 1
}

func gradient(u:Int, v:Int, dx:Double, dy:Double) -> Double
{
    let dr1:Double = 2 - dx*dx - dy*dy
    if (dr1 > 0)
    {
        let drdr1:Double = dr1 * dr1
        let hash:Int = random_index_table[(u + random_index_table[v & 255]) & 255] & 14
        return drdr1 * drdr1 * (simplex_gradient_table_2d[hash] * dx + simplex_gradient_table_2d[hash + 1] * dy)
    }
    else
    {
        return 0
    }
}

func simplex(_ x:Double, _ y:Double) -> Double
{
    // transform our coordinate system so that the *simplex* (x, y) forms a rectangular grid (u, v)
    let stretch_offset:Double = (x + y) * STRETCH_2D,
        u:Double = x + stretch_offset,
        v:Double = y + stretch_offset

    // get integral (u, v) coordinates of the rhombus
    let ub:Int = floor(u),
        vb:Int = floor(v)

    //   (0, 0)------(1, 0)
    //      \         / \
    //        \     /     \             ← (x, y) coordinates
    //          \ /         \
    //        (0, 1)-------(1, 1)

    // (ub, vb) = (0, 0) --- (1, 0)
    //            |   A     /     |
    //            |       /       |     ← (u, v) coordinates
    //            |     /     B   |
    //            (0, 1) --- (1, 1)

    // get relative position inside the rhombus relative to (ub, vb)
    let du0:Double = u - Double(ub),
        dv0:Double = v - Double(vb)

    // do the same in the original (x, y) coordinate space

    // unstretch to get (x, y) coordinates of rhombus origin
    let unstretch_offset:Double = Double(ub + vb) * UNSTRETCH_2D,
        xb:Double = Double(ub) + unstretch_offset,
        yb:Double = Double(vb) + unstretch_offset

    // get relative position inside the rhombus relative to (xb, xb)
    let dx0:Double = x - xb,
        dy0:Double = y - yb

    var z:Double = 0 // the value of the noise function, which we will sum up

    // contribution from (1, 0)
    z += gradient(u : ub + 1,
                  v : vb,
                  dx: dx0 - 1 - UNSTRETCH_2D,
                  dy: dy0     - UNSTRETCH_2D)

    // contribution from (0, 1)
    z += gradient(u : ub,
                  v : vb + 1,
                  dx: dx0     - UNSTRETCH_2D,
                  dy: dy0 - 1 - UNSTRETCH_2D)

    // decide which triangle we are in
    let uv_sum:Double = du0 + dv0
    if (uv_sum > 1) // we are to the bottom-right of the diagonal line (du = 1 - dv)
    {
        z += gradient(u : ub + 1,
                      v : vb + 1,
                      dx: dx0 - 1 - 2*UNSTRETCH_2D,
                      dy: dy0 - 1 - 2*UNSTRETCH_2D)
    }
    else
    {
        z += gradient(u : ub,
                      v : vb,
                      dx: dx0,
                      dy: dy0)
    }

    return z * NORMALIZATION_2D
}

func octaves(_ x:Double, _ y:Double, frequency:Double, octaves:Int, persistence:Double = 0.66666666666) -> Double
{
    var f:Double = frequency,
        k:Double = 1,
        z:Double = 0
    for _ in 0 ..< octaves
    {
        z += k * simplex(f*x, f*y)
        k *= persistence
        f *= 2
    }
    return z
}

var pixbuf:[UInt8] = [UInt8](repeating: 0, count: viewer_size * viewer_size)
let png_properties:PNGProperties = PNGProperties(width: viewer_size, height: viewer_size, bit_depth: 8, color: .grayscale, interlaced: false)!
for y in 0 ..< viewer_size
{
    for x in 0 ..< viewer_size
    {
        pixbuf[y * viewer_size + x] = UInt8(max(0, min(255, 255 * (octaves(Double(x), Double(y), frequency: 0.00083429273, octaves: 12, persistence: 0.75) / 2 + 0.5))))
    }
}
try png_encode(path: "viewer.png", raw_data: pixbuf, properties: png_properties)
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
