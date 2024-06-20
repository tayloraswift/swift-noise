/// A procedural noise generator.
public
protocol Noise
{
    /// Evaluates the noise field at the given coordinate. For three- and higher-dimensional
    /// noise fields, the `z` and `w` coordinates, if applicable, are set to zero.
    func evaluate(_ x:Double, _ y:Double) -> Double
    /// Evaluates the noise field at the given coordinate. For two-dimensional noise fields, the
    /// `z` coordinate is ignored. For four-dimensional noise fields, the `w` coordinate is set
    /// to zero.
    func evaluate(_ x:Double, _ y:Double, _ z:Double) -> Double
    /// Evaluates the noise field at the given coordinate. For three-dimensional and lower noise
    /// fields, the `z` and `w` coordinates are ignored, if necessary. No existing noise
    /// generator in the library currently supports true four-dimensional evaluation.
    func evaluate(_ x:Double, _ y:Double, _ z:Double, _ w:Double) -> Double

    func amplitude_scaled(by factor:Double) -> Self
    func frequency_scaled(by factor:Double) -> Self
    func reseeded() -> Self

    /// Creates an instance with the given `amplitude`, `frequency`, and random `seed` values.
    /// Creating an instance generates a new pseudo-random permutation table for that instance,
    /// and a new instance does not need to be regenerated to sample the same procedural noise
    /// field.

    //  It looks like our archaic selves wrote documentation as if this method were a
    //  requirement, but it only appears on a handful of the concrete ``Noise`` types?

    //  init(amplitude:Double, frequency:Double, seed:Int)
}

public
extension Noise
{
    /// Evaluates the noise field over the given area, starting from the origin, and extending
    /// over the first quadrant, taking unit steps in both directions. Although the `x` and `y`
    /// coordinates are returned, the output vector is guaranteed to be in row-major order.
    @available(*, deprecated, message: """
        area sampling is deprecated, iterate over a `Domain2D.Iterator` iterator and sample \
        directly instead.
        """)
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

    /// Evaluates the noise field over the given area, starting from the origin, and extending
    /// over the first quadrant, storing the values in a row-major array of samples. The samples
    /// are clamped, but not scaled, to the range `0 ... 255`.
    @available(*, deprecated, message: """
        area sampling is deprecated, iterate over a `Domain2D.Iterator` iterator and sample \
        directly instead.
        """)
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

    /// Evaluates the noise field over the given volume, starting from the origin, and extending
    /// over the first octant, taking unit steps in all three directions. Although the `x`, `y`,
    /// and `z` coordinates are returned, the output vector is guaranteed to be in
    /// `xy` plane-major, and then row-major order.
    @available(*, deprecated, message: """
        volume sampling is deprecated, iterate over a `Domain3D.Iterator` iterator and sample \
        directly instead.
        """)
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

    /// Evaluates the noise field over the given volume, starting from the origin, and extending
    /// over the first octant, storing the values in a `xy` plane-major, and then row-major
    /// order array of samples. The samples are clamped, but not scaled, to the range
    /// `0 ... 255`.
    @available(*, deprecated, message: """
        volume sampling is deprecated, iterate over a `Domain3D.Iterator` iterator and sample \
        directly instead.
        """)
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

enum Math
{
    typealias IntV2    = SIMD2<Int>
    typealias IntV3    = SIMD3<Int>
    typealias DoubleV2 = SIMD2<Double>
    typealias DoubleV3 = SIMD3<Double>

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
        
        let (i1, f1):(Int, Double) = Math.fraction(v.x),
            (i2, f2):(Int, Double) = Math.fraction(v.y)
        return (IntV2(i1, i2), DoubleV2(f1, f2))
    }
    @inline(__always)
    static
    func fraction(_ v:DoubleV3) -> (IntV3, DoubleV3)
    {
        let (i1, f1):(Int, Double) = Math.fraction(v.x),
            (i2, f2):(Int, Double) = Math.fraction(v.y),
            (i3, f3):(Int, Double) = Math.fraction(v.z)
        return (IntV3(i1, i2, i3), DoubleV3(f1, f2, f3))
    }

    @inline(__always)
    static
    func add(_ v1:IntV2, _ v2:IntV2) -> IntV2
    {
        return v1 &+ v2
    }
    
    @inline(__always)
    static
    func add(_ v1:IntV3, _ v2:IntV3) -> IntV3
    {
        return v1 &+ v2
    }

    @inline(__always)
    static
    func add(_ v1:DoubleV2, _ v2:DoubleV2) -> DoubleV2
    {
        return v1 + v2
    }
    
    @inline(__always)
    static
    func add(_ v1:DoubleV3, _ v2:DoubleV3) -> DoubleV3
    {
        return v1 + v2
    }

    @inline(__always)
    static
    func sub(_ v1:IntV2, _ v2:IntV2) -> IntV2
    {
        return v1 &- v2
    }
    @inline(__always)
    static
    func sub(_ v1:IntV3, _ v2:IntV3) -> IntV3
    {
        return v1 &- v2
    }

    @inline(__always)
    static
    func sub(_ v1:DoubleV2, _ v2:DoubleV2) -> DoubleV2
    {
        return v1 - v2
    }
    @inline(__always)
    static
    func sub(_ v1:DoubleV3, _ v2:DoubleV3) -> DoubleV3
    {
        return v1 - v2
    }

    @inline(__always)
    static
    func mult(_ v1:IntV2, _ v2:IntV2) -> IntV2
    {
        return v1 &* v2
    }
    @inline(__always)
    static
    func mult(_ v1:IntV3, _ v2:IntV3) -> IntV3
    {
        return v1 &* v2
    }

    @inline(__always)
    static
    func mult(_ v1:DoubleV2, _ v2:DoubleV2) -> DoubleV2
    {
        return v1 * v2
    }
    @inline(__always)
    static
    func mult(_ v1:DoubleV3, _ v2:DoubleV3) -> DoubleV3
    {
        return v1 * v2
    }

    @inline(__always)
    static
    func div(_ v1:DoubleV2, _ v2:DoubleV2) -> DoubleV2
    {
        return v1 / v2
    }
    @inline(__always)
    static
    func div(_ v1:DoubleV3, _ v2:DoubleV3) -> DoubleV3
    {
        return v1 / v2
    }

    @inline(__always)
    private static
    func mod(_ x:Int, _ n:Int) -> Int
    {
        let remainder = x % n
        return remainder >= 0 ? remainder : remainder + n
    }

    @inline(__always)
    static
    func mod(_ v1:IntV2, _ v2:IntV2) -> IntV2
    {
        return IntV2(Math.mod(v1.x, v2.x), Math.mod(v1.y, v2.y))
    }
    @inline(__always)
    static
    func mod(_ v1:IntV3, _ v2:IntV3) -> IntV3
    {
        return IntV3(Math.mod(v1.x, v2.x), Math.mod(v1.y, v2.y), Math.mod(v1.z, v2.z))
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
        return DoubleV2(Double(v.x), Double(v.y))
    }
    @inline(__always)
    static
    func cast_double(_ v:IntV3) -> DoubleV3
    {
        return DoubleV3(Double(v.x), Double(v.y), Double(v.z))
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
        return DoubleV2(Math.quintic_ease(v.x), Math.quintic_ease(v.y))
    }
    @inline(__always)
    static
    func quintic_ease(_ v:DoubleV3) -> DoubleV3
    {
        return DoubleV3(Math.quintic_ease(v.x), Math.quintic_ease(v.y), Math.quintic_ease(v.z))
    }
}

/// UNDOCUMENTED
public
struct Domain2D:Sequence
{
    private
    let sample_lower_bound:SIMD2<Double>,
        sample_upper_bound:SIMD2<Double>,
        increment:SIMD2<Double>

    public
    struct Iterator:IteratorProtocol
    {
        private
        var sample:SIMD2<Double>

        private
        let domain:Domain2D

        init(_ domain:Domain2D)
        {
            self.sample = Math.add(domain.sample_lower_bound, Math.DoubleV2(-0.5, 0.5))
            self.domain = domain
        }

        public mutating
        func next() -> SIMD2<Double>?
        {
            self.sample.x += 1
            if self.sample.x >= self.domain.sample_upper_bound.x
            {
                self.sample.x = self.domain.sample_lower_bound.x + 0.5
                self.sample.y += 1
                if self.sample.y >= self.domain.sample_upper_bound.y
                {
                    return nil
                }
            }

            return Math.mult(self.domain.increment, self.sample)
        }
    }

    public
    init(samples_x:Int, samples_y:Int)
    {
        self.increment          = SIMD2<Double>(1, 1)
        self.sample_lower_bound = SIMD2<Double>(0, 0)
        self.sample_upper_bound = SIMD2<Double>(Double(samples_x), Double(samples_y))
    }

    public
    init(_ x_range:ClosedRange<Double>, _ y_range:ClosedRange<Double>, samples_x:Int, samples_y:Int)
    {
        let sample_count      = SIMD2<Double>(Double(samples_x), Double(samples_y)),
            range_lower_bound = SIMD2<Double>(x_range.lowerBound, y_range.lowerBound),
            range_upper_bound = SIMD2<Double>(x_range.upperBound, y_range.upperBound),
            range_difference  = Math.sub(range_upper_bound, range_lower_bound)

        self.increment = range_difference / sample_count
        self.sample_lower_bound = (range_lower_bound * sample_count) / range_difference
        self.sample_upper_bound = self.sample_lower_bound + sample_count
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
    let sample_lower_bound:SIMD3<Double>,
        sample_upper_bound:SIMD3<Double>,
        increment:SIMD3<Double>

    public
    struct Iterator:IteratorProtocol
    {
        private
        var sample:SIMD3<Double>

        private
        let domain:Domain3D

        init(_ domain:Domain3D)
        {
            self.sample = Math.add(domain.sample_lower_bound, SIMD3<Double>(-0.5, 0.5, 0.5))
            self.domain = domain
        }

        public mutating
        func next() -> SIMD3<Double>?
        {
            self.sample.x += 1
            if self.sample.x >= self.domain.sample_upper_bound.x
            {
                self.sample.x = self.domain.sample_lower_bound.x + 0.5
                self.sample.y += 1
                if self.sample.y >= self.domain.sample_upper_bound.y
                {
                    self.sample.y = self.domain.sample_lower_bound.y + 0.5
                    self.sample.z += 1
                    if self.sample.z >= self.domain.sample_upper_bound.z
                    {
                        return nil
                    }
                }
            }

            return Math.mult(self.domain.increment, self.sample)
        }
    }

    public
    init(samples_x:Int, samples_y:Int, samples_z:Int)
    {
        self.increment          = SIMD3<Double>(1, 1, 1)
        self.sample_lower_bound = SIMD3<Double>(0, 0, 0)
        self.sample_upper_bound = SIMD3<Double>(Double(samples_x), Double(samples_y), Double(samples_z))
    }

    public
    init(_ x_range:ClosedRange<Double>, _ y_range:ClosedRange<Double>, _ z_range:ClosedRange<Double>,
        samples_x:Int, samples_y:Int, samples_z:Int)
    {
        let sample_count      = SIMD3<Double>(Double(samples_x), Double(samples_y), Double(samples_z)),
            range_lower_bound = SIMD3<Double>(x_range.lowerBound, y_range.lowerBound, z_range.lowerBound),
            range_upper_bound = SIMD3<Double>(x_range.upperBound, y_range.upperBound, z_range.upperBound),
            range_difference  = Math.sub(range_upper_bound, range_lower_bound)

        self.increment = range_difference / sample_count
        self.sample_lower_bound = (range_lower_bound * sample_count) / range_difference
        self.sample_upper_bound = self.sample_lower_bound + sample_count
    }

    public
    func makeIterator() -> Iterator
    {
        return Iterator(self)
    }
}
