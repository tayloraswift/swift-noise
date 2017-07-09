public
protocol Noise
{
    func evaluate(_ x:Double, _ y:Double)                         -> Double
    func evaluate(_ x:Double, _ y:Double, _ z:Double)             -> Double
    func evaluate(_ x:Double, _ y:Double, _ z:Double, _ w:Double) -> Double

    func amplitude_scaled(by factor:Double) -> Self
    func frequency_scaled(by factor:Double) -> Self
}

public
extension Noise
{
    @available(*, deprecated, message: "area sampling is deprecated, iterate over a Domain2D.Iterator iterator and sample directly instead.")
    public
    func sample_area(width:Int, height:Int) -> [(Double, Double, Double)]
    {
        var samples:[(Double, Double, Double)] = []
            samples.reserveCapacity(width * height)
        for i in 0 ..< height
        {
            for j in 0 ..< width
            {
                let x:Double = Double(j) + 0.5,
                    y:Double = Double(i) + 0.5
                samples.append((x, y, self.evaluate(x, y)))
            }
        }
        return samples
    }

    @available(*, deprecated, message: "area sampling is deprecated, iterate over a Domain2D.Iterator iterator and sample directly instead.")
    public
    func sample_area_saturated_to_u8(width:Int, height:Int, offset:Double = 0.5) -> [UInt8]
    {
        var samples:[UInt8] = []
            samples.reserveCapacity(width * height)
        for i in 0 ..< height
        {
            for j in 0 ..< width
            {
                let x:Double = Double(j) + 0.5,
                    y:Double = Double(i) + 0.5
                samples.append(UInt8(max(0, min(255, self.evaluate(x, y) + offset))))
            }
        }
        return samples
    }

    @available(*, deprecated, message: "volume sampling is deprecated, iterate over a Domain3D.Iterator iterator and sample directly instead.")
    public
    func sample_volume(width:Int, height:Int, depth:Int) -> [(Double, Double, Double, Double)]
    {
        var samples:[(Double, Double, Double, Double)] = []
            samples.reserveCapacity(width * height * depth)
        for i in 0 ..< depth
        {
            for j in 0 ..< height
            {
                for k in 0 ..< width
                {
                    let x:Double = Double(k) + 0.5,
                        y:Double = Double(j) + 0.5,
                        z:Double = Double(i) + 0.5
                    samples.append((x, y, z, self.evaluate(x, y, z)))
                }
            }
        }
        return samples
    }

    @available(*, deprecated, message: "volume sampling is deprecated, iterate over a Domain3D.Iterator iterator and sample directly instead.")
    public
    func sample_volume_saturated_to_u8(width:Int, height:Int, depth:Int, offset:Double = 0.5) -> [UInt8]
    {
        var samples:[UInt8] = []
            samples.reserveCapacity(width * height * depth)
        for i in 0 ..< depth
        {
            for j in 0 ..< height
            {
                for k in 0 ..< width
                {
                    let x:Double = Double(k) + 0.5,
                        y:Double = Double(j) + 0.5,
                        z:Double = Double(i) + 0.5
                    samples.append(UInt8(max(0, min(255, self.evaluate(x, y, z) + offset))))
                }
            }
        }
        return samples
    }
}

// UNDOCUMENTED
public
protocol BaseNoise:Noise
{
    init(amplitude:Double, frequency:Double, seed:Int)
}

/// UNDOCUMENTED
public
struct Domain2D:Sequence
{
    private
    let i_max:Double,
        j_max:Double,

        dx:Double,
        dy:Double,
        i0:Double,
        j0:Double

    public
    struct Iterator:IteratorProtocol
    {
        private
        var i:Double = -0.5,
            j:Double =  0.5

        private
        let domain:Domain2D

        init(_ domain:Domain2D)
        {
            self.i = domain.i0 - 0.5
            self.j = domain.j0 + 0.5

            self.domain = domain
        }

        public mutating
        func next() -> (Double, Double)?
        {
            self.i += 1
            if self.i >= self.domain.i_max
            {
                self.i = self.domain.i0 + 0.5
                self.j += 1
                if self.j >= self.domain.j_max
                {
                    return nil
                }
            }

            return (self.domain.dx * self.i, self.domain.dy * self.j)
        }
    }

    public
    init(samples_x:Int, samples_y:Int)
    {
        self.dx = 1
        self.dy = 1
        self.i0 = 0
        self.j0 = 0

        self.i_max = Double(samples_x)
        self.j_max = Double(samples_y)
    }

    public
    init(_ x_range:ClosedRange<Double>, _ y_range:ClosedRange<Double>, samples_x:Int, samples_y:Int)
    {
        self.dx     = (x_range.upperBound - x_range.lowerBound) / Double(samples_x)
        self.dy     = (y_range.upperBound - y_range.lowerBound) / Double(samples_y)
        self.i0     = x_range.lowerBound * Double(samples_x) / (x_range.upperBound - x_range.lowerBound)
        self.j0     = y_range.lowerBound * Double(samples_y) / (y_range.upperBound - y_range.lowerBound)

        self.i_max = self.i0 + Double(samples_x)
        self.j_max = self.j0 + Double(samples_y)
    }

    public
    func makeIterator() -> Iterator
    {
        return Iterator(self)
    }
}

/// UNDOCUMENTED
public
struct Domain3D:Sequence
{
    private
    let i_max:Double,
        j_max:Double,
        k_max:Double,

        dx:Double,
        dy:Double,
        dz:Double,
        i0:Double,
        j0:Double,
        k0:Double

    public
    struct Iterator:IteratorProtocol
    {
        private
        var i:Double = -0.5,
            j:Double =  0.5,
            k:Double =  0.5

        private
        let domain:Domain3D

        init(_ domain:Domain3D)
        {
            self.i = domain.i0 - 0.5
            self.j = domain.j0 + 0.5
            self.k = domain.k0 + 0.5

            self.domain = domain
        }

        public mutating
        func next() -> (Double, Double, Double)?
        {
            self.i += 1
            if self.i >= self.domain.i_max
            {
                self.i = self.domain.i0 + 0.5
                self.j += 1
                if self.j >= self.domain.j_max
                {
                    self.j = self.domain.j0 + 0.5
                    self.k += 1
                    if self.k >= self.domain.k_max
                    {
                        return nil
                    }
                }
            }

            return (self.domain.dx * self.i, self.domain.dy * self.j, self.domain.dz * self.k)
        }
    }

    public
    init(samples_x:Int, samples_y:Int, samples_z:Int)
    {
        self.dx = 1
        self.dy = 1
        self.dz = 1
        self.i0 = 0
        self.j0 = 0
        self.k0 = 0

        self.i_max = Double(samples_x)
        self.j_max = Double(samples_y)
        self.k_max = Double(samples_z)
    }

    public
    init(_ x_range:ClosedRange<Double>, _ y_range:ClosedRange<Double>, _ z_range:ClosedRange<Double>,
        samples_x:Int, samples_y:Int, samples_z:Int)
    {
        self.dx     = (x_range.upperBound - x_range.lowerBound) / Double(samples_x)
        self.dy     = (y_range.upperBound - y_range.lowerBound) / Double(samples_y)
        self.dz     = (z_range.upperBound - z_range.lowerBound) / Double(samples_z)
        self.i0     = x_range.lowerBound * Double(samples_x) / (x_range.upperBound - x_range.lowerBound)
        self.j0     = y_range.lowerBound * Double(samples_y) / (y_range.upperBound - y_range.lowerBound)
        self.k0     = z_range.lowerBound * Double(samples_z) / (z_range.upperBound - z_range.lowerBound)

        self.i_max = self.i0 + Double(samples_x)
        self.j_max = self.j0 + Double(samples_y)
        self.k_max = self.k0 + Double(samples_z)
    }

    public
    func makeIterator() -> Iterator
    {
        return Iterator(self)
    }
}

enum Math
{
    typealias IntV2    = (a:Int, b:Int)
    typealias IntV3    = (a:Int, b:Int, c:Int)
    typealias DoubleV2 = (x:Double, y:Double)
    typealias DoubleV3 = (x:Double, y:Double, z:Double)

    @inline(__always)
    private static
    func fraction(_ x:Double) -> (Int, Double)
    {
        let integer:Int = x > 0 ? Int(x) : Int(x) - 1
        return (integer, x - Double(integer))
    }

    @inline(__always)
    static
    func fraction(_ v:DoubleV2) -> (IntV2, DoubleV2)
    {
        let (i1, f1):(Int, Double) = Math.fraction(v.0),
            (i2, f2):(Int, Double) = Math.fraction(v.1)
        return ((i1, i2), (f1, f2))
    }

    @inline(__always)
    static
    func fraction(_ v:DoubleV3) -> (IntV3, DoubleV3)
    {
        let (i1, f1):(Int, Double) = Math.fraction(v.0),
            (i2, f2):(Int, Double) = Math.fraction(v.1),
            (i3, f3):(Int, Double) = Math.fraction(v.2)
        return ((i1, i2, i3), (f1, f2, f3))
    }

    @inline(__always)
    static
    func add(_ v1:IntV2, _ v2:IntV2) -> IntV2
    {
        return (v1.a + v2.a, v1.b + v2.b)
    }

    @inline(__always)
    static
    func add(_ v1:IntV3, _ v2:IntV3) -> IntV3
    {
        return (v1.a + v2.a, v1.b + v2.b, v1.c + v2.c)
    }

    @inline(__always)
    static
    func add(_ v1:DoubleV2, _ v2:DoubleV2) -> DoubleV2
    {
        return (v1.x + v2.x, v1.y + v2.y)
    }

    @inline(__always)
    static
    func add(_ v1:DoubleV3, _ v2:DoubleV3) -> DoubleV3
    {
        return (v1.x + v2.x, v1.y + v2.y, v1.z + v2.z)
    }

    @inline(__always)
    static
    func sub(_ v1:DoubleV2, _ v2:DoubleV2) -> DoubleV2
    {
        return (v1.x - v2.x, v1.y - v2.y)
    }

    @inline(__always)
    static
    func sub(_ v1:DoubleV3, _ v2:DoubleV3) -> DoubleV3
    {
        return (v1.x - v2.x, v1.y - v2.y, v1.z - v2.z)
    }

    @inline(__always)
    static
    func dot(_ v1:DoubleV2, _ v2:DoubleV2) -> Double
    {
        return v1.x * v2.x + v1.y * v2.y
    }

    @inline(__always)
    static
    func dot(_ v1:DoubleV3, _ v2:DoubleV3) -> Double
    {
        return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z
    }

    @inline(__always)
    static
    func cast_double(_ v:IntV2) -> DoubleV2
    {
        return (Double(v.a), Double(v.b))
    }

    @inline(__always)
    static
    func cast_double(_ v:IntV3) -> DoubleV3
    {
        return (Double(v.a), Double(v.b), Double(v.c))
    }

    @inline(__always)
    static
    func lerp(_ a:Double, _ b:Double, factor:Double) -> Double
    {
        return (1 - factor) * a + factor * b
    }

    @inline(__always)
    static
    func quintic_ease(_ x:Double) -> Double
    {
        // 6x^5 - 15x^4 + 10x^3
        return x * x * x * (10.addingProduct(x, (-15).addingProduct(x, 6)))
    }

    @inline(__always)
    static
    func quintic_ease(_ v:DoubleV2) -> DoubleV2
    {
        return (Math.quintic_ease(v.x), Math.quintic_ease(v.y))
    }

    @inline(__always)
    static
    func quintic_ease(_ v:DoubleV3) -> DoubleV3
    {
        return (Math.quintic_ease(v.x), Math.quintic_ease(v.y), Math.quintic_ease(v.z))
    }
}

public
struct FBM<Generator>:Noise where Generator:Noise
{
    private
    let generators:[Generator]

    // UNDOCUMENTED
    public
    func amplitude_scaled(by factor:Double) -> FBM
    {
        return FBM<Generator>(generators: self.generators.map{ $0.amplitude_scaled(by: factor) })
    }
    public
    func frequency_scaled(by factor:Double) -> FBM
    {
        return FBM<Generator>(generators: self.generators.map{ $0.frequency_scaled(by: factor) })
    }

    private
    init(generators:[Generator])
    {
        self.generators = generators
    }

    @available(*, unavailable, message: "init(amplitude:frequency:seed:) defaults to octaves = 1, which does not make sense for FBM modules")
    public
    init(amplitude:Double, frequency:Double, seed:Int)
    {
        self.generators = []
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

// UNDOCUMENTED
extension FBM where Generator:BaseNoise
{
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
}

// UNDOCUMENTED
/*
struct DistortedNoise<Base, Distorter>:Noise where Base:Noise, Distorter:Noise
{
    private
    let base:Base,
        distorter:Distorter

    init(base:Base, distorted_by distorter:Distorter)
    {
        self.base      = base
        self.distorter = distorter
    }

    public
    func evaluate(_ x: Double, _ y: Double) -> Double
    {
        let dx:Double = self.distorter.evaluate(x, y),
            dy:Double = self.distorter.evaluate(y, x)
        return self.base.evaluate(x + dx, y + dy)
    }

    public
    func evaluate(_ x: Double, _ y: Double, _ z: Double) -> Double
    {
        let dx:Double = 1.0 + self.distorter.evaluate(x, y, z),
            dy:Double = 1.0 + self.distorter.evaluate(y, z, x),
            dz:Double = 1.0 + self.distorter.evaluate(z, x, y)
        return self.base.evaluate(x + dx, y + dy, z + dz)
    }

    public
    func evaluate(_ x: Double, _ y: Double, _ z: Double, _ w:Double) -> Double
    {
        let dx:Double = self.distorter.evaluate(x, y, z, w),
            dy:Double = self.distorter.evaluate(y, z, w, x),
            dz:Double = self.distorter.evaluate(z, w, x, y),
            dw:Double = self.distorter.evaluate(w, x, y, z)
        return self.base.evaluate(x + dx, y + dy, z + dz, w + dw)
    }
}
*/

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
        var permutations:[UInt8] = [UInt8](0 ... 255),
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
