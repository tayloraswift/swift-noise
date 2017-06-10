public
struct CellNoise2D:Noise
{
    private
    typealias IntV2    = (a:Int, b:Int)
    private
    typealias DoubleV2 = (x:Double, y:Double)

    private
    let permutation_table:PermutationTable,
        amplitude:Double,
        frequency:Double

    public
    init(amplitude:Double, frequency:Double, seed:Int = 0)
    {
        self.amplitude = amplitude * 1/2.squareRoot()
        self.frequency = frequency
        self.permutation_table = PermutationTable(seed: seed)
    }

    private
    func distance(from sample_point:DoubleV2, generating_point:IntV2) -> Double
    {
        let hash:Int = self.permutation_table.hash(generating_point.a, generating_point.b)
        // hash is within 0 ... 255, take it to 0 ... 0.5

        // Notice that we have 256 possible hashes, and therefore 8 bits of entropy,
        // to be divided up between 2 axes. We can assign 4 bits to the x and y
        // axes each (16 levels each)

        //          0b XXXX YYYY

        let dpx:Double = (Double(hash >> 4         ) - 15/2) * 1/16,
            dpy:Double = (Double(hash      & 0b1111) - 15/2) * 1/16

        let dx:Double = Double(generating_point.a) + dpx - sample_point.x,
            dy:Double = Double(generating_point.b) + dpy - sample_point.y
        return dx*dx + dy*dy
    }

    public
    func evaluate(_ x:Double, _ y:Double) -> Double
    {
        let sample:DoubleV2 = (x * self.frequency, y * self.frequency)

        let bin:IntV2       = (floor(sample.x), floor(sample.y)),
            offset:DoubleV2 = (sample.x - Double(bin.a), sample.y - Double(bin.b))

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

        let quadrant:IntV2 = (offset.x > 0.5 ? 1 : -1, offset.y > 0.5 ? 1 : -1),
            near:IntV2     = (bin.a + (quadrant.a + 1) >> 1, bin.b + (quadrant.b + 1) >> 1),
            far:IntV2      = (near.a - quadrant.a, near.b - quadrant.b)

        let nearpoint_disp:DoubleV2 = (abs(offset.x - Double((quadrant.a + 1) >> 1)),
                                       abs(offset.y - Double((quadrant.b + 1) >> 1)))

        var r2:Double = self.distance(from: sample, generating_point: near)

        @inline(__always)
        func test(generating_point:IntV2, dx:Double = 0, dy:Double = 0)
        {
            if dx*dx + dy*dy < r2
            {
                r2 = min(r2, self.distance(from: sample, generating_point: generating_point))
            }
        }

        // A points
        test(generating_point: (near.a, far.b), dy: nearpoint_disp.y - 0.5)
        test(generating_point: (far.a, near.b), dx: nearpoint_disp.x - 0.5)

        // far point
        test(generating_point: far, dx: nearpoint_disp.x - 0.5, dy: nearpoint_disp.y - 0.5)

        // EARLY EXIT: if we have a point within 0.5 units, we don’t have to check
        // the outer kernel
        if r2 < 0.25
        {
            return self.amplitude * r2
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

        let inner:IntV2 = (near.a + quadrant.a, near.b + quadrant.b)

        // B points
        test(generating_point: (inner.a, near.b), dx: nearpoint_disp.x + 0.5)
        test(generating_point: (near.a, inner.b), dy: nearpoint_disp.y + 0.5)

        // C points
        test(generating_point: (inner.a, far.b), dx: nearpoint_disp.x + 0.5, dy: nearpoint_disp.y - 0.5)
        test(generating_point: (far.a, inner.b), dx: nearpoint_disp.x - 0.5, dy: nearpoint_disp.y + 0.5)

        // EARLY EXIT: if we have a point within 1 unit, we don’t have to check
        // the D points or the E points
        if r2 < 1
        {
            return self.amplitude * r2
        }

        let outer:IntV2 = (far.a  - quadrant.a, far.b  - quadrant.b)

        // D points
        test(generating_point: (near.a, outer.b), dy: nearpoint_disp.y - 1.5)
        test(generating_point: (outer.a, near.b), dx: nearpoint_disp.x - 1.5)

        // E points
        test(generating_point: (far.a, outer.b), dx: nearpoint_disp.x - 0.5, dy: nearpoint_disp.y - 1.5)
        test(generating_point: (outer.a, far.b), dx: nearpoint_disp.x - 1.5, dy: nearpoint_disp.y - 0.5)

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
struct CellNoise3D:Noise
{
    private
    typealias IntV3    = (a:Int, b:Int, c:Int)
    private
    typealias DoubleV3 = (x:Double, y:Double, z:Double)

    private
    let permutation_table:PermutationTable,
        amplitude:Double,
        frequency:Double

    public
    init(amplitude:Double, frequency:Double, seed:Int = 0)
    {
        self.amplitude = amplitude * 1/3.squareRoot()
        self.frequency = frequency
        self.permutation_table = PermutationTable(seed: seed)
    }

    private
    func distance(from sample_point:DoubleV3, generating_point:IntV3) -> Double
    {
        let hash:Int = self.permutation_table.hash(generating_point.a, generating_point.b, generating_point.c)
        // hash is within 0 ... 255, take it to 0 ... 0.5

        // Notice that we have 256 possible hashes, and therefore 8 bits of entropy,
        // to be divided up between three axes. We can assign 3 bits to the x and
        // y axes each (8 levels each), and 2 bits to the z axis (4 levels). To
        // compensate for the lack of z resolution, we bump up every other feature
        // point by half a level.

        //          0b XXX YYY ZZ

        let dpx:Double = (Double(hash >> 5                                         ) - 7/2) * 1/8,
            dpy:Double = (Double(hash >> 2 & 0b0111                                ) - 7/2) * 1/8,
            dpz:Double = (Double(hash << 1 & 0b0111 + ((hash >> 5 ^ hash >> 2) & 1)) - 7/2) * 1/8

        let dx:Double = Double(generating_point.a) + dpx - sample_point.x,
            dy:Double = Double(generating_point.b) + dpy - sample_point.y,
            dz:Double = Double(generating_point.c) + dpz - sample_point.z
        return dx*dx + dy*dy + dz*dz
    }

    public
    func evaluate(_ x:Double, _ y:Double) -> Double
    {
        return self.evaluate(x, y, 0)
    }

    public
    func evaluate(_ x:Double, _ y:Double, _ z:Double) -> Double
    {
        let sample:DoubleV3 = (x * self.frequency, y * self.frequency, z * self.frequency)

        let bin:IntV3       = (floor(sample.x), floor(sample.y), floor(sample.z)),
            offset:DoubleV3 = (sample.x - Double(bin.a), sample.y - Double(bin.b), sample.z - Double(bin.c))

        // determine kernel

        // Same idea as with the 2D points, except in 3 dimensions

        //   near - quadrant.xy ———— near - quadrant.y
        //                  |    |    |
        //                  |----+----|
        //                  |    | *  |
        //   near - quadrant.x ————— near            quadrant →
        //                                              ↓

        let quadrant:IntV3 = (offset.x > 0.5 ? 1 : -1, offset.y > 0.5 ? 1 : -1, offset.z > 0.5 ? 1 : -1),
            near:IntV3     = (bin.a + (quadrant.a + 1) >> 1, bin.b + (quadrant.b + 1) >> 1, bin.c + (quadrant.c + 1) >> 1)

        let nearpoint_disp:DoubleV3 = (abs(offset.x - Double((quadrant.a + 1) >> 1)),
                                       abs(offset.y - Double((quadrant.b + 1) >> 1)),
                                       abs(offset.z - Double((quadrant.c + 1) >> 1)))

        var r2:Double = self.distance(from: sample, generating_point: near)

        @inline(__always)
        func test(generating_point:IntV3, dx:Double = 0, dy:Double = 0, dz:Double = 0)
        {
            if dx*dx + dy*dy + dz*dz < r2
            {
                r2 = min(r2, self.distance(from: sample, generating_point: generating_point))
            }
        }

        // (0.0 , [(-1, 0, 0), (0, -1, 0), (0, 0, -1), (0, -1, -1), (-1, 0, -1), (-1, -1, 0), (-1, -1, -1)])
        let far:IntV3 = (near.a - quadrant.a, near.b - quadrant.b, near.c - quadrant.c)
        test(generating_point: (far.a, near.b, near.c), dx: nearpoint_disp.x - 0.5)
        test(generating_point: (near.a, far.b, near.c), dy: nearpoint_disp.y - 0.5)
        test(generating_point: (near.a, near.b, far.c), dz: nearpoint_disp.z - 0.5)

        test(generating_point: (near.a, far.b, far.c), dy: nearpoint_disp.y - 0.5, dz: nearpoint_disp.z - 0.5)
        test(generating_point: (far.a, near.b, far.c), dx: nearpoint_disp.x - 0.5, dz: nearpoint_disp.z - 0.5)
        test(generating_point: (far.a, far.b, near.c), dx: nearpoint_disp.x - 0.5, dy: nearpoint_disp.y - 0.5)

        test(generating_point: far, dx: nearpoint_disp.x - 0.5, dy: nearpoint_disp.y - 0.5, dz: nearpoint_disp.z - 0.5)

        // Testing shows about 47.85% of samples are eliminated by here
        // (0.25, [(1,  0,  0), ( 0, 1,  0), ( 0,  0,  1),
        //         (0, -1,  1), ( 0, 1, -1), ( 1,  0, -1), (-1, 0,  1), (-1,  1, 0), (1, -1, 0),
        //         (1, -1, -1), (-1, 1, -1), (-1, -1,  1)])
        guard r2 > 0.25
        else
        {
            return self.amplitude * r2
        }

        let inner:IntV3 = (near.a + quadrant.a, near.b + quadrant.b, near.c + quadrant.c)
        test(generating_point: (inner.a, near.b, near.c), dx: nearpoint_disp.x + 0.5)
        test(generating_point: (near.a, inner.b, near.c), dy: nearpoint_disp.y + 0.5)
        test(generating_point: (near.a, near.b, inner.c), dz: nearpoint_disp.z + 0.5)

        test(generating_point: (near.a, far.b, inner.c), dy: nearpoint_disp.y - 0.5, dz: nearpoint_disp.z + 0.5)
        test(generating_point: (near.a, inner.b, far.c), dy: nearpoint_disp.y + 0.5, dz: nearpoint_disp.z - 0.5)
        test(generating_point: (inner.a, near.b, far.c), dx: nearpoint_disp.x + 0.5, dz: nearpoint_disp.z - 0.5)
        test(generating_point: (far.a, near.b, inner.c), dx: nearpoint_disp.x - 0.5, dz: nearpoint_disp.z + 0.5)
        test(generating_point: (far.a, inner.b, near.c), dx: nearpoint_disp.x - 0.5, dy: nearpoint_disp.y + 0.5)
        test(generating_point: (inner.a, far.b, near.c), dx: nearpoint_disp.x + 0.5, dy: nearpoint_disp.y - 0.5)

        test(generating_point: (inner.a, far.b, far.c), dx: nearpoint_disp.x + 0.5, dy: nearpoint_disp.y - 0.5, dz: nearpoint_disp.z - 0.5)
        test(generating_point: (far.a, inner.b, far.c), dx: nearpoint_disp.x - 0.5, dy: nearpoint_disp.y + 0.5, dz: nearpoint_disp.z - 0.5)
        test(generating_point: (far.a, far.b, inner.c), dx: nearpoint_disp.x - 0.5, dy: nearpoint_disp.y - 0.5, dz: nearpoint_disp.z + 0.5)

        // Testing shows about 88.60% of samples are eliminated by here
        // (0.5 , [(0, 1, 1), (1, 0, 1), (1, 1, 0), (-1, 1, 1), (1, -1, 1), (1, 1, -1)])
        guard r2 > 0.5
        else
        {
            return self.amplitude * r2
        }

        test(generating_point: (near.a, inner.b, inner.c), dy: nearpoint_disp.y + 0.5, dz: nearpoint_disp.z + 0.5)
        test(generating_point: (inner.a, near.b, inner.c), dx: nearpoint_disp.x + 0.5, dz: nearpoint_disp.z + 0.5)
        test(generating_point: (inner.a, inner.b, near.c), dx: nearpoint_disp.x + 0.5, dy: nearpoint_disp.y + 0.5)

        test(generating_point: (far.a, inner.b, inner.c), dx: nearpoint_disp.x - 0.5, dy: nearpoint_disp.y + 0.5, dz: nearpoint_disp.z + 0.5)
        test(generating_point: (inner.a, far.b, inner.c), dx: nearpoint_disp.x + 0.5, dy: nearpoint_disp.y - 0.5, dz: nearpoint_disp.z + 0.5)
        test(generating_point: (inner.a, inner.b, far.c), dx: nearpoint_disp.x + 0.5, dy: nearpoint_disp.y + 0.5, dz: nearpoint_disp.z - 0.5)

        // Testing shows about 98.26% of samples are eliminated by here
        // (0.75, [(1, 1, 1)])
        guard r2 > 0.75
        else
        {
            return self.amplitude * r2
        }

        test(generating_point: inner, dx: nearpoint_disp.x + 0.5, dy: nearpoint_disp.y + 0.5, dz: nearpoint_disp.z + 0.5)

        // Testing shows about 99.94% of samples are eliminated by here

        // The following loop is responsible for about 25% of the noise generator’s
        // runtime. While it is possible to unroll the rest of it, we run up against
        // diminishing returns.
        let kernel:[(r2:Double, cell_offsets:[(Int, Int, Int)])] =
        [
            // (0.0 , [(-1, 0, 0), (0, -1, 0), (0, 0, -1), (-1, -1, 0), (-1, 0, -1), (0, -1, -1), (-1, -1, -1)]),
            // (0.25, [(1, 0, 0), (0, 1, 0), (0, 0, 1), (-1, 0, 1), (0, -1, 1), (-1, -1, 1), (-1, 1, 0), (1, -1, 0),
            //         (0, 1, -1), (-1, 1, -1), (1, 0, -1), (1, -1, -1)]),
            // (0.5 , [(0, 1, 1), (1, 0, 1), (1, 1, 0), (-1, 1, 1), (1, -1, 1), (1, 1, -1)]),
            // (0.75, [(1, 1, 1)]),
            (1.0 , [(-2, 0, 0), (-2, -1, 0), (0, -2, 0), (-1, -2, 0), (-2, 0, -1), (-2, -1, -1), (0, -2, -1), (-1, -2, -1),
                    (0, 0, -2), (-1, 0, -2), (0, -1, -2), (-1, -1, -2)]),
            (1.25, [(-2, 0, 1), (-2, -1, 1), (0, -2, 1), (-1, -2, 1), (-2, 1, 0), (1, -2, 0), (-2, 1, -1), (1, -2, -1),
                    (0, 1, -2), (-1, 1, -2), (1, 0, -2), (1, -1, -2)]),
            (1.5 , [(-2, 1, 1), (1, -2, 1), (1, 1, -2)]),
            (2.0 , [(-2, -2, 0), (-2, -2, -1), (-2, 0, -2), (-2, -1, -2), (0, -2, -2), (-1, -2, -2)]),
            (2.25, [(0, 0, 2), (-1, 0, 2), (0, -1, 2), (-1, -1, 2), (-2, -2, 1), (0, 2, 0), (-1, 2, 0), (2, 0, 0),
                    (2, -1, 0), (0, 2, -1), (-1, 2, -1), (2, 0, -1), (2, -1, -1), (-2, 1, -2), (1, -2, -2)]),
            (2.5 , [(0, 1, 2), (-1, 1, 2), (1, 0, 2), (1, -1, 2), (0, 2, 1), (-1, 2, 1), (2, 0, 1), (2, -1, 1),
                    (1, 2, 0), (2, 1, 0), (1, 2, -1), (2, 1, -1)]),
            (2.75, [(1, 1, 2), (1, 2, 1), (2, 1, 1)])
        ]

        for (kernel_radius2, cell_offsets):(r2:Double, cell_offsets:[(Int, Int, Int)]) in kernel
        {
            guard kernel_radius2 < r2
            else
            {
                break // EARLY EXIT
            }

            for cell_offset:IntV3 in cell_offsets
            {
                // calculate distance from quadrant volume to kernel cell
                var cell_distance2:Double
                if cell_offset.a == 0
                {
                    cell_distance2 = 0
                }
                else
                {                                                                // move by 0.5 towards zero
                    let dx:Double = nearpoint_disp.x + Double(cell_offset.a) + (cell_offset.a > 0 ? -0.5 : 0.5)
                    cell_distance2 = dx*dx
                }

                if cell_offset.b != 0
                {                                                                // move by 0.5 towards zero
                    let dy:Double = nearpoint_disp.y + Double(cell_offset.b) + (cell_offset.b > 0 ? -0.5 : 0.5)
                    cell_distance2 += dy*dy
                }

                if cell_offset.c != 0
                {                                                                // move by 0.5 towards zero
                    let dz:Double = nearpoint_disp.z + Double(cell_offset.c) + (cell_offset.c > 0 ? -0.5 : 0.5)
                    cell_distance2 += dz*dz
                }

                guard cell_distance2 < r2
                else
                {
                    continue
                }

                let generating_point:IntV3 = (near.a + quadrant.a*cell_offset.a,
                                              near.b + quadrant.b*cell_offset.b,
                                              near.c + quadrant.c*cell_offset.c)
                r2 = min(r2, self.distance(from: sample, generating_point: generating_point))
            }
        }

        return self.amplitude * r2
    }

    public
    func evaluate(_ x:Double, _ y:Double, _ z:Double, _:Double) -> Double
    {
        return self.evaluate(x, y, z)
    }
}
