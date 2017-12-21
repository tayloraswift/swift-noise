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
        let new_table:PermutationTable = PermutationTable(reseeding: self.permutation_table)
        return Self(amplitude: self.amplitude, frequency: self.frequency, permutation_table: new_table)
    }

    func hash(point:Math.IntV2) -> Int
    {
        return self.permutation_table.hash(point)
    }

    func hash(point:Math.IntV3) -> Int
    {
        return self.permutation_table.hash(point)
    }
}

public
protocol TilingNoise:Noise
{
    func transposed(octaves:Int) -> Self
}

protocol HashedTilingNoise:TilingNoise
{
    associatedtype IntV

    var permutation_table:PermutationTable { get }
    var amplitude:Double { get }
    var frequency:Double { get }
    var wavelengths:IntV { get }

    init(amplitude:Double, frequency:Double, permutation_table:PermutationTable, wavelengths:IntV)

    func _transpose_wavelengths(_ wavelengths:IntV, octaves:Int) -> IntV
}

extension HashedTilingNoise
{
    public
    func amplitude_scaled(by factor:Double) -> Self
    {
        return Self(amplitude: self.amplitude * factor, frequency: self.frequency,
                    permutation_table: self.permutation_table, wavelengths: self.wavelengths)
    }
    public
    func frequency_scaled(by factor:Double) -> Self
    {
        return Self(amplitude: self.amplitude, frequency: self.frequency * factor,
                    permutation_table: self.permutation_table, wavelengths: self.wavelengths)
    }
    public
    func reseeded() -> Self
    {
        let new_table:PermutationTable = PermutationTable(reseeding: self.permutation_table)
        return Self(amplitude: self.amplitude, frequency: self.frequency,
                    permutation_table: new_table, wavelengths: self.wavelengths)
    }

    public
    func transposed(octaves:Int = 1) -> Self
    {
        return Self(amplitude: self.amplitude, frequency: self.frequency,
                    permutation_table: self.permutation_table,
                    wavelengths: self._transpose_wavelengths(self.wavelengths, octaves: octaves))
    }
}

extension HashedTilingNoise where IntV == Math.IntV2
{
    func _transpose_wavelengths(_ wavelengths:Math.IntV2, octaves:Int) -> Math.IntV2
    {
        return (wavelengths.a << octaves, wavelengths.b << octaves)
    }

    func hash(point:Math.IntV2) -> Int
    {
        return self.permutation_table.hash(Math.mod(point, self.wavelengths))
    }
}

extension HashedTilingNoise where IntV == Math.IntV3
{
    func _transpose_wavelengths(_ wavelengths:Math.IntV3, octaves:Int) -> Math.IntV3
    {
        return (wavelengths.a << octaves, wavelengths.b << octaves, wavelengths.c << octaves)
    }

    func hash(point:Math.IntV3) -> Int
    {
        return self.permutation_table.hash(Math.mod(point, self.wavelengths))
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

    public
    init(seed:Int)
    {
        self.state128 = (1, 0, UInt32(truncatingIfNeeded: seed >> UInt32.bitWidth), UInt32(truncatingIfNeeded: seed))
    }

    public mutating
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

    public mutating
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
