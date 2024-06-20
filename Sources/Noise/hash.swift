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

extension HashedTilingNoise where IntV == SIMD2<Int>
{
    func _transpose_wavelengths(_ wavelengths:Math.IntV2, octaves:Int) -> SIMD2<Int>
    {
        return SIMD2<Int>(wavelengths.x << octaves, wavelengths.y << octaves)
    }

    func hash(point:SIMD2<Int>) -> Int
    {
        return self.permutation_table.hash(Math.mod(point, self.wavelengths))
    }
}

extension HashedTilingNoise where IntV == SIMD3<Int>
{
    func _transpose_wavelengths(_ wavelengths:SIMD3<Int>, octaves:Int) -> SIMD3<Int>
    {
        return SIMD3<Int>(wavelengths.x << octaves, wavelengths.y << octaves, wavelengths.z << octaves)
    }

    func hash(point:SIMD3<Int>) -> Int
    {
        return self.permutation_table.hash(Math.mod(point, self.wavelengths))
    }
}

/// A cryptographically unsecure 128-bit [Xorshift](https://en.wikipedia.org/wiki/Xorshift)
/// pseudo-random number generator.
public
struct RandomXorshift
{
    private
    var state128:(UInt32, UInt32, UInt32, UInt32)

    /// The maximum unsigned integer value the random number generator is capable of producing.
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

    /// Generates a pseudo-random 32 bit unsigned integer, and advances the random number
    /// generator state.
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

    /// Generates a pseudo-random 32 bit unsigned integer less than `maximum`, and advances the
    /// random number generator state. This function should be preferred over using the plain
    /// ``generate`` method with the modulo operator to avoid modulo biasing. However, if
    /// `maximum` is a power of two, a bit mask may be faster.
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

/// An 8-bit permutation table useful for generating pseudo-random hash values.
///
/// ![2D voronoi noise](png/banner_voronoi2d.png)
///
/// Permutation tables can be used, among other things, to hash
/// [cell noise](doc:CellNoise2D/closest_point(_:_:)) to produce a
/// [Voronoi diagram](https://en.wikipedia.org/wiki/Voronoi_diagram).
public
struct PermutationTable
{
    private
    let permut:[UInt8] // keep these small to minimize cache misses

    /// Creates an instance with the given random `seed` containing the values `0 ... 255`
    /// shuffled in a random order.
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

    func hash(_ n2:SIMD2<Int>) -> Int
    {
        return Int(self.permut[Int(self.permut[n2.x & 255]) ^ (n2.y & 255)])
    }

    func hash(_ n3:SIMD3<Int>) -> Int
    {
        return Int(self.permut[self.hash(SIMD2<Int>(n3.x, n3.y)) ^ (n3.z & 255)])
    }

    /// Hash a single integer value.
    public
    func hash(_ h1:Int) -> UInt8
    {
        return self.permut[h1 & 255]
    }
    /// Hash two integer values.
    public
    func hash(_ h1:Int, _ h2:Int) -> UInt8
    {
        return self.permut[Int(self.hash(h1)) ^ (h2 & 255)]
    }
    /// Hash three integer values.
    public
    func hash(_ h1:Int, _ h2:Int, _ h3:Int) -> UInt8
    {
        return self.permut[Int(self.hash(h1, h2)) ^ (h3 & 255)]
    }
}
