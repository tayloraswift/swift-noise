// UNDOCUMENTED
protocol HashedNoise:Noise
{
    var permutation_table:PermutationTable { get }
    var amplitude:Double { get }
    var frequency:Double { get }

    init(amplitude:Double, frequency:Double, permutation_table:PermutationTable)
}

extension HashedNoise
{
    public
    func amplitude_scaled(by factor:Double) -> Self
    {
        return Self(amplitude: self.amplitude * factor, frequency: self.frequency, permutation_table: self.permutation_table)
    }
    public
    func frequency_scaled(by factor:Double) -> Self
    {
        return Self(amplitude: self.amplitude, frequency: self.frequency * factor, permutation_table: self.permutation_table)
    }
    public
    func reseeded() -> Self
    {
        return Self(amplitude: self.amplitude, frequency: self.frequency, permutation_table: PermutationTable(reseeding: self.permutation_table))
    }
}

public
struct RandomXorshift
{
    private
    var state128:(UInt32, UInt32, UInt32, UInt32)

    public
    var max:UInt32
    {
        return UInt32.max
    }

    init(seed:Int)
    {
        self.state128 = (1, 0, UInt32(extendingOrTruncating: seed >> UInt32.bitWidth), UInt32(extendingOrTruncating: seed))
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
        let upper_bound:UInt32 = self.max - self.max % maximum
        var x:UInt32 = 0
        repeat
        {
            x = self.generate()
        } while x >= upper_bound

        return x % maximum
    }
}

public
struct PermutationTable
{
    private
    let permut:[UInt8] // keep these small to minimize cache misses

    public
    init(seed:Int)
    {
        self.init(old_permut: [UInt8](0 ... 255), seed: seed)
    }

    // UNDOCUMENTED
    public
    init(reseeding old_table:PermutationTable)
    {
        self.init(old_permut: old_table.permut, seed: 0)
    }

    private
    init(old_permut:[UInt8], seed:Int)
    {
        var permutations:[UInt8] = old_permut,
            rng:RandomXorshift = RandomXorshift(seed: seed)
        for i in 0 ..< 255 - 1
        {
            permutations.swapAt(i, Int(rng.generate()) & 255)
        }

        self.permut = permutations
    }

    func hash(_ n2:Math.IntV2) -> Int
    {
        return Int(self.permut[Int(self.permut[n2.a & 255]) ^ (n2.b & 255)])
    }

    func hash(_ n3:Math.IntV3) -> Int
    {
        return Int(self.permut[self.hash((n3.a, n3.b)) ^ (n3.c & 255)])
    }

    public func hash(_ h1:Int)                     -> UInt8 { return self.permut[h1 & 255] }
    public func hash(_ h1:Int, _ h2:Int)           -> UInt8 { return self.permut[Int(self.hash(h1    )) ^ (h2 & 255)] }
    public func hash(_ h1:Int, _ h2:Int, _ h3:Int) -> UInt8 { return self.permut[Int(self.hash(h1, h2)) ^ (h3 & 255)] }
}
