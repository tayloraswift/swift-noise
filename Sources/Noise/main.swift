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

func table(seed:Int, hashes_2d:Int) -> ([Int], [Int])
{
    var seed = seed
    var perm:[Int]   = [Int](repeating: 0, count: 1024),
        perm2d:[Int] = [Int](repeating: 0, count: 1024)
    var source:[Int] = Array(0 ..< 1024)
    for i in stride(from: 1023, to: 0, by: -1)
    {
        seed = seed &* 6364136223846793005 &+ 1442695040888963407
        var r:Int = (seed + 31) % (i + 1)
        if r < 0
        {
            r += i + 1
        }
        perm[i]   = source[r]
        perm2d[i] = perm[i] % hashes_2d
        //perm3d[i] = (short)((perm[i] % 48) * 3);
        source[r] = source[i]
    }

    return (perm, perm2d)
}

func floor(_ x:Double) -> Int
{
    return x > 0 ? Int(x) : Int(x) - 1
}

let SQUISH_2D :Double = 0.5 * (1 / 3.squareRoot() - 1)
let STRETCH_2D:Double = 0.5 * (3.squareRoot() - 1)

protocol NoiseGenerator
{
    init(amplitude:Double, frequency:Double, seed:Int)
    func evaluate(_ x:Double, _ y:Double) -> Double
}

protocol HashedNoiseGenerator:NoiseGenerator
{
    var perm:[Int] { get }
    var perm2d:[Int] { get }
    static var gradient_table_2d:[(Double, Double)] { get }
    static var radius:Double { get }
}

extension HashedNoiseGenerator
{
    func gradient(u:Int, v:Int, dx:Double, dy:Double) -> Double
    {
        let dr:Double = Self.radius - dx*dx - dy*dy
        if dr > 0
        {
            let drdr:Double = dr * dr
            let hash:Int = self.perm2d[self.perm[u & 1023] ^ (v & 1023)],
                gradient:(Double, Double) = Self.gradient_table_2d[hash]
            return drdr * drdr * (gradient.0 * dx + gradient.1 * dy)
        }
        else
        {
            return 0
        }
    }
}

struct fBm<Generator:NoiseGenerator>:NoiseGenerator
{
    let generators:[Generator]

    init(amplitude:Double, frequency:Double, seed:Int)
    {
        self.init(amplitude: amplitude, frequency: frequency, octaves: 1, seed: seed)
    }

    init(amplitude:Double, frequency:Double, octaves:Int, persistence:Double = 0.75, seed:Int = 0)
    {
        var generators:[Generator] = []
            generators.reserveCapacity(octaves)
        var f:Double = frequency,
            a:Double = amplitude
        for s in (seed ..< seed + octaves)
        {
            generators.append(Generator(amplitude: a, frequency: f, seed: s))
            a *= persistence
            f *= 2
        }

        self.generators  = generators
    }

    func evaluate(_ x:Double, _ y:Double) -> Double
    {
        var z:Double = 0
        for generator in self.generators
        {
            z += generator.evaluate(x, y) // a .reduce(:{}) is much slower than a simple loop
        }
        return z
    }
}

import func Glibc.clock

var pixbuf:[UInt8] = [UInt8](repeating: 0, count: viewer_size * viewer_size)
let png_properties:PNGProperties = PNGProperties(width: viewer_size, height: viewer_size, bit_depth: 8, color: .grayscale, interlaced: false)!

var t0:Int

let S:fBm<Simplex> = fBm<Simplex>(amplitude: 127 / 20, frequency: 0.00083429273, octaves: 10)
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


let SS:fBm<SuperSimplex> = fBm<SuperSimplex>(amplitude: 127, frequency: 0.00083429273, octaves: 10)
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
