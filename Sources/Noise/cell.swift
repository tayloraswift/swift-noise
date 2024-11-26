fileprivate
protocol _CellNoise2D
{
    var frequency:Double { get }
    var amplitude:Double { get }

    func hash(point:SIMD2<Int>) -> Int
}

extension _CellNoise2D
{
    @inline(__always)
    private
    func distance2(from sample_point:SIMD2<Double>, generating_point:SIMD2<Int>) -> Double
    {
        let hash:Int = self.hash(point: generating_point)
        // hash is within 0 ... 255, take it to 0 ... 0.5

        // Notice that we have 256 possible hashes, and therefore 8 bits of entropy,
        // to be divided up between 2 axes. We can assign 4 bits to the x and y
        // axes each (16 levels each)

        //          0b XXXX YYYY

        let dp = SIMD2<Double>(
            ((Double(hash >> 4         ) - 7.5) / 16.0),
            ((Double(hash      & 0b1111) - 7.5) / 16.0)
        )

        let dv = Math.sub(Math.add(Math.cast_double(generating_point), dp), sample_point)
        return Math.dot(dv, dv)
    }

    // ugly hack to get around compiler linker bug
    @inline(__always)
    func _closest_point(_ x:Double, _ y:Double) -> (point:SIMD2<Int>, r2:Double)
    {
        let sample = SIMD2<Double>(x * self.frequency, y * self.frequency)

        let (bin, sample_rel):(SIMD2<Int>, SIMD2<Double>) = Math.fraction(sample)

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

        let quadrant = SIMD2<Int>(sample_rel.x > 0.5 ? 1 : -1, sample_rel.y > 0.5 ? 1 : -1)
        let _x = (quadrant.x + 1) >> 1
        let _y = (quadrant.y + 1) >> 1
        let near = bin &+ SIMD2<Int>(_x, _y)
        
        let far = near &- quadrant

        let nearpoint_disp = SIMD2<Double>(abs(sample_rel.x - Double((quadrant.x + 1) >> 1)),
                                           abs(sample_rel.y - Double((quadrant.y + 1) >> 1)))

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
        _inspect(generating_point: SIMD2<Int>(near.x, far.y), dy: nearpoint_disp.y - 0.5)
        _inspect(generating_point: SIMD2<Int>(far.x, near.y), dx: nearpoint_disp.x - 0.5)

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
        let inner:SIMD2<Int> = near &+ quadrant

        // B points
        _inspect(generating_point: SIMD2<Int>(inner.x, near.y), dx: nearpoint_disp.x + 0.5)
        _inspect(generating_point: SIMD2<Int>(near.x, inner.y), dy: nearpoint_disp.y + 0.5)

        // C points
        _inspect(generating_point: SIMD2<Int>(inner.x, far.y), dx: nearpoint_disp.x + 0.5, dy: nearpoint_disp.y - 0.5)
        _inspect(generating_point: SIMD2<Int>(far.x, inner.y), dx: nearpoint_disp.x - 0.5, dy: nearpoint_disp.y + 0.5)

        guard r2 > 1.0
        else
        {
            return (closest_point, r2)
        }

        // Cell group III:
        //                 within r^2 = 2.0
        // cumulative sample coverage = 100%
        let outer:SIMD2<Int> = far &- quadrant

        // D points
        _inspect(generating_point: SIMD2<Int>(near.x, outer.y), dy: nearpoint_disp.y - 1.5)
        _inspect(generating_point: SIMD2<Int>(outer.x, near.y), dx: nearpoint_disp.x - 1.5)

        // E points
        _inspect(generating_point: SIMD2<Int>(far.x, outer.y), dx: nearpoint_disp.x - 0.5, dy: nearpoint_disp.y - 1.5)
        _inspect(generating_point: SIMD2<Int>(outer.x, far.y), dx: nearpoint_disp.x - 1.5, dy: nearpoint_disp.y - 0.5)

        return (closest_point, r2)
    }
}

/// A type of two-dimensional cellular noise (sometimes called
/// [Worley noise](https://en.wikipedia.org/wiki/Worley_noise), or Voronoi noise), suitable for
/// texturing two-dimensional planes.
///
/// ![preview](png/banner_cell2d.png)
///
/// Unlike many other cell noise implementations, *Noise*’s implementation samples all relevant
/// generating-points, preventing artifacts or discontinuities from ever appearing in the noise.
/// Accordingly, *Noise*’s implementation is heavily optimized to prevent the additional edge
/// cases from impacting the performance of the cell noise.
///
/// Cell noise has a three-dimensional version, ``CellNoise3D``.
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

    /// Creates an instance with the given `amplitude`, `frequency`, and random `seed` values.
    /// Creating an instance generates a new pseudo-random permutation table for that instance,
    /// and a new instance does not need to be regenerated to sample the same procedural noise
    /// field.
    ///
    /// The given amplitude is adjusted internally to produce output *exactly* within the range
    /// of `0 ... amplitude`. However, in practice the cell noise rarely reaches the maximum
    /// threshold, as it is often useful to inflate the amplitude to get the desired appearance.
    public
    init(amplitude:Double, frequency:Double, seed:Int = 0)
    {
        self.amplitude = amplitude / 2
        self.frequency = frequency
        self.permutation_table = PermutationTable(seed: seed)
    }

    /// Returns the index numbers of the closest feature point to the given coordinate, and the
    /// squared distance from the given coordinate to the feature point. These index numbers can
    /// be fed to a color hashing function to produce a
    /// [Voronoi diagram](https://en.wikipedia.org/wiki/Voronoi_diagram).
    public
    func closest_point(_ x:Double, _ y:Double) -> (point:SIMD2<Int>, r2:Double)
    {
        return self._closest_point(x, y)
    }

    /// Evaluates the cell noise field at the given coordinates.
    public
    func evaluate(_ x:Double, _ y:Double) -> Double
    {
        let (_, r2):(SIMD2<Int>, Double) = self.closest_point(x, y)
        return self.amplitude * r2
    }

    /// Evaluates the cell noise field at the given coordinates. The third coordinate is
    /// ignored.
    public
    func evaluate(_ x:Double, _ y:Double, _:Double) -> Double
    {
        return self.evaluate(x, y)
    }

    /// Evaluates the cell noise field at the given coordinates. The third and fourth
    /// coordinates are ignored.
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
        self.wavelengths = SIMD2<Int>(wavelengths_x, wavelengths_y)
    }

    public
    func closest_point(_ x:Double, _ y:Double) -> (point:SIMD2<Int>, r2:Double)
    {
        return self._closest_point(x, y)
    }

    public
    func evaluate(_ x:Double, _ y:Double) -> Double
    {
        let (_, r2):(SIMD2<Int>, Double) = self.closest_point(x, y)
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

    func hash(point:SIMD3<Int>) -> Int
}

extension _CellNoise3D
{
    @inline(__always)
    private
    func distance2(from sample_point:SIMD3<Double>, generating_point:SIMD3<Int>) -> Double
    {
        let hash:Int = self.hash(point: generating_point)
        // hash is within 0 ... 255, take it to 0 ... 0.5

        // Notice that we have 256 possible hashes, and therefore 8 bits of entropy,
        // to be divided up between three axes. We can assign 3 bits to the x and
        // y axes each (8 levels each), and 2 bits to the z axis (4 levels). To
        // compensate for the lack of z resolution, we bump up every other feature
        // point by half a level.

        //          0b XXX YYY ZZ

        let axes:SIMD3<Double> = Math.cast_double(SIMD3<Int>( hash >> 5,
                                                    hash >> 2 & 0b0111,
                                                    hash << 1 & 0b0111 + ((hash >> 5 ^ hash >> 2) & 1)))
        let dp:SIMD3<Double> = SIMD3<Double>((axes.x - 7 / 2) * 1.0 / 8,
                                (axes.y - 7 / 2) * 1.0 / 8,
                                (axes.z - 7 / 2) * 1.0 / 8)

        let dv:SIMD3<Double> = Math.sub(Math.add(Math.cast_double(generating_point), dp), sample_point)
        return Math.dot(dv, dv)
    }

    @inline(__always)
    func _closest_point(_ x:Double, _ y:Double, _ z:Double) -> (point:SIMD3<Int>, r2:Double)
    {
        let sample = SIMD3<Double>(x * self.frequency, y * self.frequency, z * self.frequency)

        let (bin, sample_rel):(SIMD3<Int>, SIMD3<Double>) = Math.fraction(sample)

        // determine kernel

        // Same idea as with the 2D points, except in 3 dimensions

        //   near - quadrant.xy ———— near - quadrant.y
        //                  |    |    |
        //                  |----+----|
        //                  |    | *  |
        //   near - quadrant.x ————— near            quadrant →
        //                                              ↓

        let quadrant:SIMD3<Int>  = SIMD3<Int>(sample_rel.x > 0.5 ? 1 : -1,
                                    sample_rel.y > 0.5 ? 1 : -1,
                                    sample_rel.z > 0.5 ? 1 : -1)
        let near:SIMD3<Int>      = Math.add(bin, SIMD3<Int>((quadrant.x + 1) >> 1,
                                                  (quadrant.y + 1) >> 1,
                                                  (quadrant.z + 1) >> 1))

        let nearpoint_disp:SIMD3<Double> = SIMD3<Double>(abs(sample_rel.x - Double((quadrant.x + 1) >> 1)),
                                            abs(sample_rel.y - Double((quadrant.y + 1) >> 1)),
                                            abs(sample_rel.z - Double((quadrant.z + 1) >> 1)))

        var r2:Double = self.distance2(from: sample, generating_point: near),
            closest_point:SIMD3<Int> = near

        @inline(__always)
        func _inspect_cell(offset:SIMD3<Int>)
        {
            // calculate distance from quadrant volume to kernel cell
            var cell_distance2:Double
            if offset.x != 0
            {                                                                // move by 0.5 towards zero
                let dx:Double = nearpoint_disp.x + Double(offset.x) + (offset.x > 0 ? -0.5 : 0.5)
                cell_distance2 = dx*dx
            }
            else
            {
                cell_distance2 = 0
            }

            if offset.y != 0
            {                                                                // move by 0.5 towards zero
                let dy:Double = nearpoint_disp.y + Double(offset.y) + (offset.y > 0 ? -0.5 : 0.5)
                cell_distance2 += dy*dy
            }

            if offset.z != 0
            {                                                                // move by 0.5 towards zero
                let dz:Double = nearpoint_disp.z + Double(offset.z) + (offset.z > 0 ? -0.5 : 0.5)
                cell_distance2 += dz*dz
            }

            guard cell_distance2 < r2
            else
            {
                return
            }

            let generating_point:SIMD3<Int> = Math.add(near, Math.mult(quadrant, offset))
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
        _inspect_cell(offset: SIMD3<Int>(-1,  0,  0))
        _inspect_cell(offset: SIMD3<Int>( 0, -1,  0))
        _inspect_cell(offset: SIMD3<Int>( 0,  0, -1))

        _inspect_cell(offset: SIMD3<Int>( 0, -1, -1))
        _inspect_cell(offset: SIMD3<Int>(-1,  0, -1))
        _inspect_cell(offset: SIMD3<Int>(-1, -1,  0))

        _inspect_cell(offset: SIMD3<Int>(-1, -1, -1))

        // Cell group II:
        //                outside r^2 = 0.25
        // cumulative sample coverage = 88.60%
        guard r2 > 0.25
        else
        {
            return (closest_point, r2)
        }
        for offset in  [SIMD3<Int>(1,  0,  0), SIMD3<Int>( 0, 1,  0), SIMD3<Int>( 0,  0,  1),
                        SIMD3<Int>(0, -1,  1), SIMD3<Int>( 0, 1, -1), SIMD3<Int>( 1,  0, -1), SIMD3<Int>(-1, 0, 1), SIMD3<Int>(-1, 1, 0), SIMD3<Int>(1, -1, 0),
                        SIMD3<Int>(1, -1, -1), SIMD3<Int>(-1, 1, -1), SIMD3<Int>(-1, -1,  1)]
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
        for offset in [SIMD3<Int>(0, 1, 1), SIMD3<Int>(1, 0, 1), SIMD3<Int>(1, 1, 0), SIMD3<Int>(-1, 1, 1), SIMD3<Int>(1, -1, 1), SIMD3<Int>(1, 1, -1)]
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
        for offset in  [SIMD3<Int>(-2,  0,  0), SIMD3<Int>( 0, -2,  0), SIMD3<Int>( 0,  0, -2),
                        SIMD3<Int>( 0, -2, -1), SIMD3<Int>( 0, -1, -2), SIMD3<Int>(-2,  0, -1), SIMD3<Int>(-1, 0, -2), SIMD3<Int>(-2, -1, 0), SIMD3<Int>(-1, -2, 0),
                        SIMD3<Int>(-2, -1, -1), SIMD3<Int>(-1, -2, -1), SIMD3<Int>(-1, -1, -2)]
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
        for offset in  [SIMD3<Int>( 0, 1, -2), SIMD3<Int>( 0, -2, 1), SIMD3<Int>(1,  0, -2), SIMD3<Int>(-2,  0, 1), SIMD3<Int>(1, -2,  0), SIMD3<Int>(-2, 1,  0),
                        SIMD3<Int>(-2, 1, -1), SIMD3<Int>(-2, -1, 1), SIMD3<Int>(1, -2, -1), SIMD3<Int>(-1, -2, 1), SIMD3<Int>(1, -1, -2), SIMD3<Int>(-1, 1, -2)]
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
        for offset in [SIMD3<Int>(0, -2, -2), SIMD3<Int>(-2, 0, -2), SIMD3<Int>(-2, -2, 0), SIMD3<Int>(-1, -2, -2), SIMD3<Int>(-2, -1, -2), SIMD3<Int>(-2, -2, -1)]
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
        for offset in  [SIMD3<Int>(2,  0,  0), SIMD3<Int>(0,  2,  0), SIMD3<Int>( 0,  0, 2),
                        SIMD3<Int>(0, -1,  2), SIMD3<Int>(0,  2, -1), SIMD3<Int>(-1,  0, 2), SIMD3<Int>( 2,  0, -1), SIMD3<Int>(-1, 2,  0), SIMD3<Int>( 2, -1,  0),
                        SIMD3<Int>(2, -1, -1),              SIMD3<Int>(-1, -1,  2),              SIMD3<Int>(-1,  2, -1)]
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
        for offset in  [SIMD3<Int>(0, 1,  2), SIMD3<Int>(0,  2, 1), SIMD3<Int>(1, 0,  2), SIMD3<Int>( 2, 0, 1), SIMD3<Int>(1,  2, 0), SIMD3<Int>( 2, 1, 0),
                        SIMD3<Int>(2, 1, -1), SIMD3<Int>(2, -1, 1), SIMD3<Int>(1, 2, -1), SIMD3<Int>(-1, 2, 1), SIMD3<Int>(1, -1, 2), SIMD3<Int>(-1, 1, 2)]
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

/// A type of three-dimensional cellular noise (sometimes called
/// [Worley noise](https://en.wikipedia.org/wiki/Worley_noise), or Voronoi noise), suitable for
/// texturing arbitrary three-dimensional objects.
///
/// ![preview](png/banner_cell3d.png)
///
/// Unlike many other cell noise implementations, *Noise*’s implementation samples all relevant
/// generating-points, preventing artifacts or discontinuities from ever appearing in the noise.
/// Accordingly, *Noise*’s implementation is heavily optimized to prevent the additional edge
/// cases from impacting the performance of the cell noise.
///
/// Three dimensional cell noise is approximately three to four times slower than its
/// [two-dimensional version](doc:CellNoise2D), but has a vastly superior visual appearance,
/// even when sampled in two dimensions.
///
/// `CellNoise3D` is analogous to
/// [Blender Voronoi noise](https://docs.blender.org/manual/en/dev/render/cycles/nodes/types/textures/voronoi.html),
/// with the *Distance Squared* metric. The *Scale* of Blender Voronoi noise is identical to the
/// frequency of `CellNoise3D`; its range is approximately `0 ... 10/3` in `CellNoise3D`
/// units.
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

    /// Creates an instance with the given `amplitude`, `frequency`, and random `seed` values.
    /// Creating an instance generates a new pseudo-random permutation table for that instance,
    /// and a new instance does not need to be regenerated to sample the same procedural noise
    /// field.
    ///
    /// The given amplitude is adjusted internally to produce output *exactly* within the range
    /// of `0 ... amplitude`. However, in practice the cell noise rarely reaches the maximum
    /// threshold, as it is often useful to inflate the amplitude to get the desired appearance.
    public
    init(amplitude:Double, frequency:Double, seed:Int = 0)
    {
        self.amplitude = amplitude * 1/3
        self.frequency = frequency
        self.permutation_table = PermutationTable(seed: seed)
    }

    /// Returns the index numbers of the closest feature point to the given coordinate, and the
    /// squared distance from the given coordinate to the feature point. These index numbers can
    /// be fed to a color hashing function to produce a
    /// [Voronoi diagram](https://en.wikipedia.org/wiki/Voronoi_diagram).
    public
    func closest_point(_ x:Double, _ y:Double, _ z:Double) -> (point:SIMD3<Int>, r2:Double)
    {
        return self._closest_point(x, y, z)
    }

    /// Evaluates the cell noise field at the given `x, y` coordinates, supplying `0` for the
    /// missing `z` coordinate.
    public
    func evaluate(_ x:Double, _ y:Double) -> Double
    {
        return self.evaluate(x, y, 0)
    }

    /// Evaluates the cell noise field at the given coordinates.
    public
    func evaluate(_ x:Double, _ y:Double, _ z:Double) -> Double
    {
        let (_, r2):(SIMD3<Int>, Double) = self.closest_point(x, y, z)
        return self.amplitude * r2
    }

    /// Evaluates the cell noise field at the given coordinates. The fourth coordinate is
    /// ignored.
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
        self.wavelengths = SIMD3<Int>(wavelengths_x, wavelengths_y, wavelengths_z)
    }

    public
    func closest_point(_ x:Double, _ y:Double, _ z:Double) -> (point:SIMD3<Int>, r2:Double)
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
        let (_, r2):(SIMD3<Int>, Double) = self.closest_point(x, y, z)
        return self.amplitude * r2
    }

    public
    func evaluate(_ x:Double, _ y:Double, _ z:Double, _:Double) -> Double
    {
        return self.evaluate(x, y, z)
    }
}
