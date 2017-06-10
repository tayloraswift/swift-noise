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

enum Math
{
    @inline(__always)
    static
    func ifloor(_ x:Double) -> Int
    {
        return x > 0 ? Int(x) : Int(x) - 1
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
    init(amplitude:Double, frequency:Double, octaves:Int, persistence:Double = 0.75, lacunarity:Double = 2, seed:Int = 0)
    {
        var generators:[Generator] = []
            generators.reserveCapacity(octaves)
        var f:Double = frequency,
            a:Double = amplitude
        for s in (seed ..< seed + octaves)
        {
            generators.append(Generator(amplitude: a, frequency: f, seed: s))
            a *= persistence
            f *= lacunarity
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

struct RandomXORShift
{
    private
    var state128:(UInt32, UInt32, UInt32, UInt32)

    var max:UInt32
    {
        return UInt32.max
    }

    init(seed:Int)
    {
        self.state128 = (1, 0, UInt32(extendingOrTruncating: seed >> 32), UInt32(extendingOrTruncating: seed))
    }

    mutating
    func generate() -> UInt32
    {
        var t:UInt32 = self.state128.3
        t ^= t &<< 11
        t ^= t &>> 8
        self.state128.3 = self.state128.2
        self.state128.2 = self.state128.1
        self.state128.1 = self.state128.0
        t ^= self.state128.0
        t ^= self.state128.0 &>> 19
        self.state128.0 = t
        return t
    }

    mutating
    func generate(less_than maximum:UInt32) -> UInt32
    {
        let upper_bound:UInt32 = UInt32.max - UInt32.max % maximum
        var x:UInt32 = 0
        repeat
        {
            x = self.generate()
        } while x >= upper_bound

        return x % maximum
    }
}

struct PermutationTable
{
    private
    let permut:[UInt8] // keep these small to minimize cache misses

    init(seed:Int)
    {
        var permutations:[UInt8] = [UInt8](0 ... 255),
            rng:RandomXORShift = RandomXORShift(seed: seed)
        for i in 0 ..< 255 - 1
        {
            permutations.swapAt(i, Int(rng.generate()) & 255)
        }

        self.permut = permutations
    }

    func hash(_ n1:Int, _ n2:Int) -> Int
    {
        return Int(self.permut[Int(self.permut[n1 & 255]) ^ (n2 & 255)])
    }

    func hash(_ n1:Int, _ n2:Int, _ n3:Int) -> Int
    {
        return Int(self.permut[self.hash(n1, n2) ^ (n3 & 255)])
    }
}
