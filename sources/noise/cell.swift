fileprivate
protocol _CellNoise2D
{
    var frequency:Double { get }
    var amplitude:Double { get }

    func hash(point:Math.IntV2) -> Int
}

extension _CellNoise2D
{
    @inline(__always)
    private
    func distance2(from sample_point:Math.DoubleV2, generating_point:Math.IntV2) -> Double
    {
        let hash:Int = self.hash(point: generating_point)
        // hash is within 0 ... 255, take it to 0 ... 0.5

        // Notice that we have 256 possible hashes, and therefore 8 bits of entropy,
        // to be divided up between 2 axes. We can assign 4 bits to the x and y
        // axes each (16 levels each)

        //          0b XXXX YYYY

        let dp:Math.DoubleV2 = ((Double(hash >> 4         ) - 15 / 2) * 1 / 16,
                                (Double(hash      & 0b1111) - 15 / 2) * 1 / 16)

        let dv:Math.DoubleV2 = Math.sub(Math.add(Math.cast_double(generating_point), dp), sample_point)
        return Math.dot(dv, dv)
    }

    // ugly hack to get around compiler linker bug
    @inline(__always)
    func _closest_point(_ x:Double, _ y:Double) -> (point:(Int, Int), r2:Double)
    {
        let sample:Math.DoubleV2 = (x * self.frequency, y * self.frequency)

        let (bin, sample_rel):(Math.IntV2, Math.DoubleV2) = Math.fraction(sample)

        // determine kernel

        // The feature points do not live within the grid cells, rather they float
        // around the *corners* of the grid cells (the ‘O’s in the diagram).
        // The grid cell that the sample point has been binned into is shaded.

        //               xb   xb + 1
        //          +------------------+
        //          |     |      |     |
        //       yb |---- O//////O ----|
        //          |     |//////|     |
        //   yb + 1 |---- O//////O ----|
        //          |     |      |     |
        //          +------------------+

        // The bin itself is divided into quadrants to classify the four corners
        // as “near” and “far” points. We call these points the *generating points*.
        // The sample point (example) has been marked with an ‘*’.

        //          A —————— far
        //          |    |    |
        //          |----+----|
        //          |  * |    |
        //        near —————— A                ← quadrant
        //                                          ↓

        // The actual feature points never spawn outside of the unit square surrounding
        // their generating points. Therefore, the boundaries of the generating
        // squares serve as a useful means of early exit — if the square is farther
        // away than a point already found, then there is no point checking that
        // square since it cannot produce a feature point closer than we have already
        // found.

        let quadrant:Math.IntV2 = (sample_rel.x > 0.5 ? 1 : -1  , sample_rel.y > 0.5 ? 1 : -1),
            near:Math.IntV2     = Math.add(bin, ((quadrant.a + 1) >> 1, (quadrant.b + 1) >> 1)),
            far:Math.IntV2      = (near.a - quadrant.a          , near.b - quadrant.b)

        let nearpoint_disp:Math.DoubleV2 = (abs(sample_rel.x - Double((quadrant.a + 1) >> 1)),
                                            abs(sample_rel.y - Double((quadrant.b + 1) >> 1)))

        var r2:Double = self.distance2(from: sample, generating_point: near),
            closest_point:Math.IntV2 = near

        @inline(__always)
        func _inspect(generating_point:Math.IntV2, dx:Double = 0, dy:Double = 0)
        {
            if dx*dx + dy*dy < r2
            {
                let dr2:Double = self.distance2(from: sample, generating_point: generating_point)
                if dr2 < r2
                {
                    r2            = dr2
                    closest_point = generating_point
                }
            }
        }

        // Cell group I:
        //                 within r^2 = 0.25
        // cumulative sample coverage = 65.50%

        // A points
        _inspect(generating_point: (near.a, far.b), dy: nearpoint_disp.y - 0.5)
        _inspect(generating_point: (far.a, near.b), dx: nearpoint_disp.x - 0.5)

        // far point
        _inspect(generating_point: far, dx: nearpoint_disp.x - 0.5, dy: nearpoint_disp.y - 0.5)

        guard r2 > 0.25
        else
        {
            return (closest_point, r2)
        }

        // This is the part where shit hits the fan. (`inner` and `outer` are never
        // sampled directly, they are used for calculating the coordinates of the
        // generating point.)

        //          +-------- D ------- E ----- outer
        //          |    |    |    |    |    |    |
        //          |----+----|----+----|----+----|
        //          |    |    |    |    |    |    |
        //          C ------- A —————— far ------ E
        //          |    |    |    |    |    |    |
        //          |----+----|----+----|----+----|
        //          |    |    |  * |    |    |    |
        //          B ----- near —————— A ------- D
        //          |    |    |    |    |    |    |
        //          |----+----|----+----|----+----|
        //          |    |    |    |    |    |    |
        //        inner ----- B ------- C --------+               ← quadrant
        //                                                             ↓

        // Cell group II:
        //                 within r^2 = 1.0
        // cumulative sample coverage = 99.96%
        let inner:Math.IntV2 = Math.add(near, quadrant)

        // B points
        _inspect(generating_point: (inner.a, near.b), dx: nearpoint_disp.x + 0.5)
        _inspect(generating_point: (near.a, inner.b), dy: nearpoint_disp.y + 0.5)

        // C points
        _inspect(generating_point: (inner.a, far.b), dx: nearpoint_disp.x + 0.5, dy: nearpoint_disp.y - 0.5)
        _inspect(generating_point: (far.a, inner.b), dx: nearpoint_disp.x - 0.5, dy: nearpoint_disp.y + 0.5)

        guard r2 > 1.0
        else
        {
            return (closest_point, r2)
        }

        // Cell group III:
        //                 within r^2 = 2.0
        // cumulative sample coverage = 100%
        let outer:Math.IntV2 = Math.sub(far, quadrant)

        // D points
        _inspect(generating_point: (near.a, outer.b), dy: nearpoint_disp.y - 1.5)
        _inspect(generating_point: (outer.a, near.b), dx: nearpoint_disp.x - 1.5)

        // E points
        _inspect(generating_point: (far.a, outer.b), dx: nearpoint_disp.x - 0.5, dy: nearpoint_disp.y - 1.5)
        _inspect(generating_point: (outer.a, far.b), dx: nearpoint_disp.x - 1.5, dy: nearpoint_disp.y - 0.5)

        return (closest_point, r2)
    }
}

public
struct CellNoise2D:_CellNoise2D, HashedNoise
{
    let permutation_table:PermutationTable,
        amplitude:Double,
        frequency:Double

    init(amplitude:Double, frequency:Double, permutation_table:PermutationTable)
    {
        self.amplitude = amplitude
        self.frequency = frequency
        self.permutation_table = permutation_table
    }

    public
    init(amplitude:Double, frequency:Double, seed:Int = 0)
    {
        self.amplitude = amplitude / 2
        self.frequency = frequency
        self.permutation_table = PermutationTable(seed: seed)
    }

    public
    func closest_point(_ x:Double, _ y:Double) -> (point:(Int, Int), r2:Double)
    {
        return self._closest_point(x, y)
    }

    public
    func evaluate(_ x:Double, _ y:Double) -> Double
    {
        let (_, r2):((Int, Int), Double) = self.closest_point(x, y)
        return self.amplitude * r2
    }

    public
    func evaluate(_ x:Double, _ y:Double, _:Double) -> Double
    {
        return self.evaluate(x, y)
    }

    public
    func evaluate(_ x:Double, _ y:Double, _:Double, _:Double) -> Double
    {
        return self.evaluate(x, y)
    }
}

public
struct TilingCellNoise2D:_CellNoise2D, HashedTilingNoise
{
    let permutation_table:PermutationTable,
        amplitude:Double,
        frequency:Double,
        wavelengths:Math.IntV2

    init(amplitude:Double, frequency:Double, permutation_table:PermutationTable, wavelengths:Math.IntV2)
    {
        self.amplitude = amplitude
        self.frequency = frequency
        self.permutation_table = permutation_table
        self.wavelengths = wavelengths
    }

    public
    init(amplitude:Double, frequency:Double, wavelengths:Int, seed:Int = 0)
    {
        self.init(  amplitude: amplitude, frequency: frequency,
                    wavelengths_x: wavelengths,
                    wavelengths_y: wavelengths,
                    seed: seed)
    }

    public
    init(amplitude:Double, frequency:Double, wavelengths_x:Int, wavelengths_y:Int, seed:Int = 0)
    {
        self.amplitude = amplitude / 2
        self.frequency = frequency
        self.permutation_table = PermutationTable(seed: seed)
        self.wavelengths = (wavelengths_x, wavelengths_y)
    }

    public
    func closest_point(_ x:Double, _ y:Double) -> (point:(Int, Int), r2:Double)
    {
        return self._closest_point(x, y)
    }

    public
    func evaluate(_ x:Double, _ y:Double) -> Double
    {
        let (_, r2):((Int, Int), Double) = self.closest_point(x, y)
        return self.amplitude * r2
    }

    public
    func evaluate(_ x:Double, _ y:Double, _:Double) -> Double
    {
        return self.evaluate(x, y)
    }

    public
    func evaluate(_ x:Double, _ y:Double, _:Double, _:Double) -> Double
    {
        return self.evaluate(x, y)
    }
}


fileprivate
protocol _CellNoise3D
{
    var frequency:Double { get }
    var amplitude:Double { get }

    func hash(point:Math.IntV3) -> Int
}

extension _CellNoise3D
{
    @inline(__always)
    private
    func distance2(from sample_point:Math.DoubleV3, generating_point:Math.IntV3) -> Double
    {
        let hash:Int = self.hash(point: generating_point)
        // hash is within 0 ... 255, take it to 0 ... 0.5

        // Notice that we have 256 possible hashes, and therefore 8 bits of entropy,
        // to be divided up between three axes. We can assign 3 bits to the x and
        // y axes each (8 levels each), and 2 bits to the z axis (4 levels). To
        // compensate for the lack of z resolution, we bump up every other feature
        // point by half a level.

        //          0b XXX YYY ZZ

        let axes:Math.DoubleV3 = Math.cast_double(( hash >> 5,
                                                    hash >> 2 & 0b0111,
                                                    hash << 1 & 0b0111 + ((hash >> 5 ^ hash >> 2) & 1)))
        let dp:Math.DoubleV3 = ((axes.x - 7 / 2) * 1.0 / 8,
                                (axes.y - 7 / 2) * 1.0 / 8,
                                (axes.z - 7 / 2) * 1.0 / 8)

        let dv:Math.DoubleV3 = Math.sub(Math.add(Math.cast_double(generating_point), dp), sample_point)
        return Math.dot(dv, dv)
    }

    @inline(__always)
    func _closest_point(_ x:Double, _ y:Double, _ z:Double) -> (point:(Int, Int, Int), r2:Double)
    {
        let sample:Math.DoubleV3 = (x * self.frequency, y * self.frequency, z * self.frequency)

        let (bin, sample_rel):(Math.IntV3, Math.DoubleV3) = Math.fraction(sample)

        // determine kernel

        // Same idea as with the 2D points, except in 3 dimensions

        //   near - quadrant.xy ———— near - quadrant.y
        //                  |    |    |
        //                  |----+----|
        //                  |    | *  |
        //   near - quadrant.x ————— near            quadrant →
        //                                              ↓

        let quadrant:Math.IntV3  = (sample_rel.x > 0.5 ? 1 : -1,
                                    sample_rel.y > 0.5 ? 1 : -1,
                                    sample_rel.z > 0.5 ? 1 : -1)
        let near:Math.IntV3      = Math.add(bin, ((quadrant.a + 1) >> 1,
                                                  (quadrant.b + 1) >> 1,
                                                  (quadrant.c + 1) >> 1))

        let nearpoint_disp:Math.DoubleV3 = (abs(sample_rel.x - Double((quadrant.a + 1) >> 1)),
                                            abs(sample_rel.y - Double((quadrant.b + 1) >> 1)),
                                            abs(sample_rel.z - Double((quadrant.c + 1) >> 1)))

        var r2:Double = self.distance2(from: sample, generating_point: near),
            closest_point:Math.IntV3 = near

        @inline(__always)
        func _inspect_cell(offset:Math.IntV3)
        {
            // calculate distance from quadrant volume to kernel cell
            var cell_distance2:Double
            if offset.a != 0
            {                                                                // move by 0.5 towards zero
                let dx:Double = nearpoint_disp.x + Double(offset.a) + (offset.a > 0 ? -0.5 : 0.5)
                cell_distance2 = dx*dx
            }
            else
            {
                cell_distance2 = 0
            }

            if offset.b != 0
            {                                                                // move by 0.5 towards zero
                let dy:Double = nearpoint_disp.y + Double(offset.b) + (offset.b > 0 ? -0.5 : 0.5)
                cell_distance2 += dy*dy
            }

            if offset.c != 0
            {                                                                // move by 0.5 towards zero
                let dz:Double = nearpoint_disp.z + Double(offset.c) + (offset.c > 0 ? -0.5 : 0.5)
                cell_distance2 += dz*dz
            }

            guard cell_distance2 < r2
            else
            {
                return
            }

            let generating_point:Math.IntV3 = Math.add(near, Math.mult(quadrant, offset))
            let dr2:Double = self.distance2(from: sample, generating_point: generating_point)
            if dr2 < r2
            {
                r2            = dr2
                closest_point = generating_point
            }
        }

        // check each cell group, exiting early if we are guaranteed to have found
        // the closest point

        // Cell group I:
        //                outside r^2 = 0
        // cumulative sample coverage = 47.85%
        _inspect_cell(offset: (-1,  0,  0))
        _inspect_cell(offset: ( 0, -1,  0))
        _inspect_cell(offset: ( 0,  0, -1))

        _inspect_cell(offset: ( 0, -1, -1))
        _inspect_cell(offset: (-1,  0, -1))
        _inspect_cell(offset: (-1, -1,  0))

        _inspect_cell(offset: (-1, -1, -1))

        // Cell group II:
        //                outside r^2 = 0.25
        // cumulative sample coverage = 88.60%
        guard r2 > 0.25
        else
        {
            return (closest_point, r2)
        }
        for offset in  [(1,  0,  0), ( 0, 1,  0), ( 0,  0,  1),
                        (0, -1,  1), ( 0, 1, -1), ( 1,  0, -1), (-1, 0, 1), (-1, 1, 0), (1, -1, 0),
                        (1, -1, -1), (-1, 1, -1), (-1, -1,  1)]
        {
            _inspect_cell(offset: offset)
        }

        // Cell group III:
        //                outside r^2 = 0.5
        // cumulative sample coverage = 98.26%
        guard r2 > 0.5
        else
        {
            return (closest_point, r2)
        }
        for offset in [(0, 1, 1), (1, 0, 1), (1, 1, 0), (-1, 1, 1), (1, -1, 1), (1, 1, -1)]
        {
            _inspect_cell(offset: offset)
        }

        // Cell group IV: [(1, 1, 1)] [ occluded ]
        //                outside r^2 = 0.75
        // cumulative sample coverage = 99.94%

        // Cell group V:
        //                outside r^2 = 1.0
        // cumulative sample coverage > 99.99%
        guard r2 > 1.0
        else
        {
            return (closest_point, r2)
        }
        for offset in  [(-2,  0,  0), ( 0, -2,  0), ( 0,  0, -2),
                        ( 0, -2, -1), ( 0, -1, -2), (-2,  0, -1), (-1, 0, -2), (-2, -1, 0), (-1, -2, 0),
                        (-2, -1, -1), (-1, -2, -1), (-1, -1, -2)]
        {
            _inspect_cell(offset: offset)
        }

        // Cell group VI:
        //                outside r^2 = 1.25
        // cumulative sample coverage > 99.99%
        guard r2 > 1.25
        else
        {
            return (closest_point, r2)
        }
        for offset in  [( 0, 1, -2), ( 0, -2, 1), (1,  0, -2), (-2,  0, 1), (1, -2,  0), (-2, 1,  0),
                        (-2, 1, -1), (-2, -1, 1), (1, -2, -1), (-1, -2, 1), (1, -1, -2), (-1, 1, -2)]
        {
            _inspect_cell(offset: offset)
        }

        // Cell group VII: [(-2, 1, 1), (1, -2, 1), (1, 1, -2)] [ occluded ]
        //                outside r^2 = 1.5
        // cumulative sample coverage > 99.99%

        // Cell group VIII:
        //                    outside = 2.0
        // cumulative sample coverage > 99.99%
        guard r2 > 2.0
        else
        {
            return (closest_point, r2)
        }
        for offset in [(0, -2, -2), (-2, 0, -2), (-2, -2, 0), (-1, -2, -2), (-2, -1, -2), (-2, -2, -1)]
        {
            _inspect_cell(offset: offset)
        }

        // Cell group IX: [(1, -2, -2), (-2, -2, 1), (-2, 1, -2)] [ occluded ]
        //                outside r^2 = 2.25
        // cumulative sample coverage > 99.99%
        guard r2 > 2.25
        else
        {
            return (closest_point, r2)
        }
        for offset in  [(2,  0,  0), (0,  2,  0), ( 0,  0, 2),
                        (0, -1,  2), (0,  2, -1), (-1,  0, 2), ( 2,  0, -1), (-1, 2,  0), ( 2, -1,  0),
                                     (2, -1, -1),              (-1, -1,  2),              (-1,  2, -1)]
        {
            _inspect_cell(offset: offset)
        }

        // Cell group X:
        //                outside r^2 = 2.5
        // cumulative sample coverage > 99.99%
        guard r2 > 2.5
        else
        {
            return (closest_point, r2)
        }
        for offset in  [(0, 1,  2), (0,  2, 1), (1, 0,  2), ( 2, 0, 1), (1,  2, 0), ( 2, 1, 0),
                        (2, 1, -1), (2, -1, 1), (1, 2, -1), (-1, 2, 1), (1, -1, 2), (-1, 1, 2)]
        {
            _inspect_cell(offset: offset)
        }

        // Cell group XI: [(2, 1, 1), (1, 2, 1), (1, 1, 2)] [ occluded ]
        //                outside r^2 = 2.75
        // cumulative sample coverage = 100%

        // stop           outside r^2 = 3.0
        return (closest_point, r2)
    }
}

public
struct CellNoise3D:_CellNoise3D, HashedNoise
{
    let permutation_table:PermutationTable,
        amplitude:Double,
        frequency:Double

    init(amplitude:Double, frequency:Double, permutation_table:PermutationTable)
    {
        self.amplitude = amplitude
        self.frequency = frequency
        self.permutation_table = permutation_table
    }

    public
    init(amplitude:Double, frequency:Double, seed:Int = 0)
    {
        self.amplitude = amplitude * 1/3
        self.frequency = frequency
        self.permutation_table = PermutationTable(seed: seed)
    }

    public
    func closest_point(_ x:Double, _ y:Double, _ z:Double) -> (point:(Int, Int, Int), r2:Double)
    {
        return self._closest_point(x, y, z)
    }

    public
    func evaluate(_ x:Double, _ y:Double) -> Double
    {
        return self.evaluate(x, y, 0)
    }

    public
    func evaluate(_ x:Double, _ y:Double, _ z:Double) -> Double
    {
        let (_, r2):((Int, Int, Int), Double) = self.closest_point(x, y, z)
        return self.amplitude * r2
    }

    public
    func evaluate(_ x:Double, _ y:Double, _ z:Double, _:Double) -> Double
    {
        return self.evaluate(x, y, z)
    }
}

public
struct TilingCellNoise3D:_CellNoise3D, HashedTilingNoise
{
    let permutation_table:PermutationTable,
        amplitude:Double,
        frequency:Double,
        wavelengths:Math.IntV3

    init(amplitude:Double, frequency:Double, permutation_table:PermutationTable, wavelengths:Math.IntV3)
    {
        self.amplitude = amplitude
        self.frequency = frequency
        self.permutation_table = permutation_table
        self.wavelengths = wavelengths
    }

    public
    init(amplitude:Double, frequency:Double, wavelengths:Int, seed:Int = 0)
    {
        self.init(  amplitude: amplitude, frequency: frequency,
                    wavelengths_x: wavelengths,
                    wavelengths_y: wavelengths,
                    wavelengths_z: wavelengths,
                    seed: seed)
    }

    public
    init(amplitude:Double, frequency:Double, wavelengths_x:Int, wavelengths_y:Int, wavelengths_z:Int, seed:Int = 0)
    {
        self.amplitude = 1 / 3 * amplitude
        self.frequency = frequency
        self.permutation_table = PermutationTable(seed: seed)
        self.wavelengths = (wavelengths_x, wavelengths_y, wavelengths_z)
    }

    public
    func closest_point(_ x:Double, _ y:Double, _ z:Double) -> (point:(Int, Int, Int), r2:Double)
    {
        return self._closest_point(x, y, z)
    }

    public
    func evaluate(_ x:Double, _ y:Double) -> Double
    {
        return self.evaluate(x, y, 0)
    }

    public
    func evaluate(_ x:Double, _ y:Double, _ z:Double) -> Double
    {
        let (_, r2):((Int, Int, Int), Double) = self.closest_point(x, y, z)
        return self.amplitude * r2
    }

    public
    func evaluate(_ x:Double, _ y:Double, _ z:Double, _:Double) -> Double
    {
        return self.evaluate(x, y, z)
    }
}
