public
protocol Noise
{
    func evaluate(_ x:Double, _ y:Double)                         -> Double
    func evaluate(_ x:Double, _ y:Double, _ z:Double)             -> Double
    func evaluate(_ x:Double, _ y:Double, _ z:Double, _ w:Double) -> Double

    func amplitude_scaled(by factor:Double) -> Self
    func frequency_scaled(by factor:Double) -> Self
    func reseeded() -> Self
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
    func sub(_ v1:IntV2, _ v2:IntV2) -> IntV2
    {
        return (v1.a - v2.a, v1.b - v2.b)
    }
    @inline(__always)
    static
    func sub(_ v1:IntV3, _ v2:IntV3) -> IntV3
    {
        return (v1.a - v2.a, v1.b - v2.b, v1.c - v2.c)
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
    func mult(_ v1:IntV2, _ v2:IntV2) -> IntV2
    {
        return (v1.a * v2.a, v1.b * v2.b)
    }
    @inline(__always)
    static
    func mult(_ v1:IntV3, _ v2:IntV3) -> IntV3
    {
        return (v1.a * v2.a, v1.b * v2.b, v1.c * v2.c)
    }

    @inline(__always)
    static
    func mult(_ v1:DoubleV2, _ v2:DoubleV2) -> DoubleV2
    {
        return (v1.x * v2.x, v1.y * v2.y)
    }
    @inline(__always)
    static
    func mult(_ v1:DoubleV3, _ v2:DoubleV3) -> DoubleV3
    {
        return (v1.x * v2.x, v1.y * v2.y, v1.z * v2.z)
    }

    @inline(__always)
    static
    func div(_ v1:DoubleV2, _ v2:DoubleV2) -> DoubleV2
    {
        return (v1.x / v2.x, v1.y / v2.y)
    }
    @inline(__always)
    static
    func div(_ v1:DoubleV3, _ v2:DoubleV3) -> DoubleV3
    {
        return (v1.x / v2.x, v1.y / v2.y, v1.z / v2.z)
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
        return (Math.mod(v1.a, v2.a), Math.mod(v1.b, v2.b))
    }
    @inline(__always)
    static
    func mod(_ v1:IntV3, _ v2:IntV3) -> IntV3
    {
        return (Math.mod(v1.a, v2.a), Math.mod(v1.b, v2.b), Math.mod(v1.c, v2.c))
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

/// UNDOCUMENTED
public
struct Domain2D:Sequence
{
    private
    let sample_lower_bound:Math.DoubleV2,
        sample_upper_bound:Math.DoubleV2,
        increment:Math.DoubleV2

    public
    struct Iterator:IteratorProtocol
    {
        private
        var sample:Math.DoubleV2

        private
        let domain:Domain2D

        init(_ domain:Domain2D)
        {
            self.sample = Math.add(domain.sample_lower_bound, (-0.5, 0.5))
            self.domain = domain
        }

        public mutating
        func next() -> (Double, Double)?
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
        self.increment          = (1, 1)
        self.sample_lower_bound = (0, 0)
        self.sample_upper_bound = Math.cast_double((samples_x, samples_y))
    }

    public
    init(_ x_range:ClosedRange<Double>, _ y_range:ClosedRange<Double>, samples_x:Int, samples_y:Int)
    {
        let sample_count:Math.DoubleV2      = Math.cast_double((samples_x, samples_y)),
            range_lower_bound:Math.DoubleV2 = (x_range.lowerBound, y_range.lowerBound),
            range_upper_bound:Math.DoubleV2 = (x_range.upperBound, y_range.upperBound),
            range_difference:Math.DoubleV2  = Math.sub(range_upper_bound, range_lower_bound)

        self.increment = Math.div(range_difference, sample_count)
        self.sample_lower_bound = Math.div(Math.mult(range_lower_bound, sample_count), range_difference)
        self.sample_upper_bound = Math.add(self.sample_lower_bound, sample_count)
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
    let sample_lower_bound:Math.DoubleV3,
        sample_upper_bound:Math.DoubleV3,
        increment:Math.DoubleV3

    public
    struct Iterator:IteratorProtocol
    {
        private
        var sample:Math.DoubleV3

        private
        let domain:Domain3D

        init(_ domain:Domain3D)
        {
            self.sample = Math.add(domain.sample_lower_bound, (-0.5, 0.5, 0.5))
            self.domain = domain
        }

        public mutating
        func next() -> (Double, Double, Double)?
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
        self.increment          = (1, 1, 1)
        self.sample_lower_bound = (0, 0, 0)
        self.sample_upper_bound = Math.cast_double((samples_x, samples_y, samples_z))
    }

    public
    init(_ x_range:ClosedRange<Double>, _ y_range:ClosedRange<Double>, _ z_range:ClosedRange<Double>,
        samples_x:Int, samples_y:Int, samples_z:Int)
    {
        let sample_count:Math.DoubleV3      = Math.cast_double((samples_x, samples_y, samples_z)),
            range_lower_bound:Math.DoubleV3 = (x_range.lowerBound, y_range.lowerBound, z_range.lowerBound),
            range_upper_bound:Math.DoubleV3 = (x_range.upperBound, y_range.upperBound, z_range.upperBound),
            range_difference:Math.DoubleV3  = Math.sub(range_upper_bound, range_lower_bound)

        self.increment = Math.div(range_difference, sample_count)
        self.sample_lower_bound = Math.div(Math.mult(range_lower_bound, sample_count), range_difference)
        self.sample_upper_bound = Math.add(self.sample_lower_bound, sample_count)
    }

    public
    func makeIterator() -> Iterator
    {
        return Iterator(self)
    }
}
