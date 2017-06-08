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
    func sample_area(width:Int, height:Int) -> [(x:Double, y:Double, z:Double)]
    {
        var samples:[(x:Double, y:Double, z:Double)] = []
            samples.reserveCapacity(width * height)
        for i in 0 ..< height
        {
            for j in 0 ..< width
            {
                let x:Double = Double(i) + 0.5,
                    y:Double = Double(j) + 0.5
                samples.append((x: x, y: y, z: self.evaluate(x, y)))
            }
        }
        return samples
    }

    public
    func sample_area_saturated_to_u8(width:Int, height:Int, offset:Double = 0.5) -> [UInt8]
    {
        var samples:[UInt8] = []
            samples.reserveCapacity(width * height)
        for y in 0 ..< height
        {
            for x in 0 ..< width
            {
                samples.append(UInt8(max(0, min(255, self.evaluate(Double(x), Double(y)) + offset))))
            }
        }
        return samples
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
        var perm1024:[Int] = [Int](0 ..< 1024),
            state128:(UInt32, UInt32, UInt32, UInt32) = (1, 0, 0, UInt32(extendingOrTruncating: seed))
        for i in 0 ..< 1024 - 1
        {
            var t:UInt32 = state128.3
            t ^= t &<< 11
            t ^= t &>> 8
            state128.3 = state128.2
            state128.2 = state128.1
            state128.1 = state128.0
            t ^= state128.0
            t ^= state128.0 &>> 19
            state128.0 = t
            perm1024.swapAt(i, Int(t) & 1023)
        }

        return (perm1024, perm1024.map{ $0 % range })
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
