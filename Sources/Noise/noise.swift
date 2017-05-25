func floor(_ x:Double) -> Int
{
    return x > 0 ? Int(x) : Int(x) - 1
}

let SQUISH_2D :Double = 0.5 * (1 / 3.squareRoot() - 1)
let STRETCH_2D:Double = 0.5 * (3.squareRoot() - 1)

public
protocol Noise
{
    init(amplitude:Double, frequency:Double, seed:Int)

    func evaluate(_ x:Double, _ y:Double)                         -> Double
    func evaluate(_ x:Double, _ y:Double, _ z:Double)             -> Double
    func evaluate(_ x:Double, _ y:Double, _ z:Double, _ w:Double) -> Double
}

public
extension Noise
{
    public
    func noise2d(width:Int, height:Int) -> [UInt8]
    {
        var pixbuf:[UInt8] = []
            pixbuf.reserveCapacity(width * height)
        var y:Double = 0
        for _ in 0 ..< height
        {
            var x:Double = 0
            for _ in 0 ..< width
            {
                x += 1
                let noise:Double = self.evaluate(x, y)
                pixbuf.append(UInt8(max(0, min(255, noise + 127))))
            }
            y += 1
        }
        return pixbuf
    }
}

protocol HashedNoise:Noise
{
    var perm1024:[Int] { get }
    var hashes:[Int] { get }

    static
    var n_hashes:Int { get }
}

extension HashedNoise
{
    static
    func table(seed:Int) -> ([Int], [Int])
    {
        let range:Int = Self.n_hashes
        var seed = seed
        var perm1024:[Int] = [Int](repeating: 0, count: 1024),
            hashes:[Int]   = [Int](repeating: 0, count: 1024)
        var source:[Int]   = Array(0 ..< 1024)
        for i in stride(from: 1023, to: 0, by: -1)
        {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            var r:Int = (seed + 31) % (i + 1)
            if r < 0
            {
                r += i + 1
            }
            perm1024[i] = source[r]
            hashes[i]   = perm1024[i] % range
            source[r]   = source[i]
        }

        return (perm1024, hashes)
    }
}

protocol Hashed2DGradientNoise:HashedNoise
{
    static var gradient_table:[(Double, Double)] { get }
    static var radius:Double { get }
}

extension Hashed2DGradientNoise
{
    static
    var n_hashes:Int
    {
        return Self.gradient_table.count
    }

    func gradient(u:Int, v:Int, dx:Double, dy:Double) -> Double
    {
        let dr:Double = Self.radius - dx*dx - dy*dy
        if dr > 0
        {
            let hash:Int = self.hashes[self.perm1024[u & 1023] ^ (v & 1023)],
                gradient:(Double, Double) = Self.gradient_table[hash],
                drdr:Double = dr * dr
            return drdr * drdr * (gradient.0 * dx + gradient.1 * dy)
        }
        else
        {
            return 0
        }
    }
}

protocol Hashed3DGradientNoise:HashedNoise
{
    static var gradient_table:[(Double, Double, Double)] { get }
}

extension Hashed3DGradientNoise
{
    static
    var n_hashes:Int
    {
        return Self.gradient_table.count
    }

    func gradient(u:Int, v:Int, w:Int, dx:Double, dy:Double, dz:Double) -> Double
    {
        let dr:Double = 0.75 - dx*dx - dy*dy - dz*dz
        if dr > 0
        {
            let hash:Int = self.hashes[self.perm1024[self.perm1024[u & 1023] ^ (v & 1023)] ^ (w & 1023)],
                gradient:(Double, Double, Double) = Self.gradient_table[hash],
                drdr:Double = dr * dr
            return drdr * drdr * (gradient.0 * dx + gradient.1 * dy + gradient.2 * dz)
        }
        else
        {
            return 0
        }
    }
}

public
struct fBm<Generator:Noise>:Noise
{
    private
    let generators:[Generator]

    public
    init(amplitude:Double, frequency:Double, seed:Int)
    {
        self.init(amplitude: amplitude, frequency: frequency, octaves: 1, seed: seed)
    }

    public
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

    public
    func evaluate(_ x:Double, _ y:Double) -> Double
    {
        var z:Double = 0
        for generator in self.generators
        {
            z += generator.evaluate(x, y) // a .reduce(:{}) is much slower than a simple loop
        }
        return z
    }

    public
    func evaluate(_ x:Double, _ y:Double, _ z:Double) -> Double
    {
        var w:Double = 0
        for generator in self.generators
        {
            w += generator.evaluate(x, y, z)
        }
        return w
    }

    public
    func evaluate(_ x:Double, _ y:Double, _ z:Double, _ w:Double) -> Double
    {
        var u:Double = 0
        for generator in self.generators
        {
            u += generator.evaluate(x, y, z, w)
        }
        return u
    }
}
