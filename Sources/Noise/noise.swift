func table(seed:Int, n_hashes:Int) -> ([Int], [Int])
{
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
        hashes[i]   = perm1024[i] % n_hashes
        source[r]   = source[i]
    }

    return (perm1024, hashes)
}

func floor(_ x:Double) -> Int
{
    return x > 0 ? Int(x) : Int(x) - 1
}

let SQUISH_2D :Double = 0.5 * (1 / 3.squareRoot() - 1)
let STRETCH_2D:Double = 0.5 * (3.squareRoot() - 1)

public
protocol NoiseGenerator
{
    init(amplitude:Double, frequency:Double, seed:Int)
    func evaluate(_ x:Double, _ y:Double)                         -> Double
    func evaluate(_ x:Double, _ y:Double, _ z:Double)             -> Double
    func evaluate(_ x:Double, _ y:Double, _ z:Double, _ w:Double) -> Double
}

protocol HashedNoiseGenerator:NoiseGenerator
{
    var perm1024:[Int] { get }
    var hashes:[Int] { get }
    static var gradient_table:[(Double, Double)] { get }
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
            let hash:Int = self.hashes[self.perm1024[u & 1023] ^ (v & 1023)],
                gradient:(Double, Double) = Self.gradient_table[hash]
            return drdr * drdr * (gradient.0 * dx + gradient.1 * dy)
        }
        else
        {
            return 0
        }
    }
}

public
struct fBm<Generator:NoiseGenerator>:NoiseGenerator
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
