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

        //          A ------ far
        //          |    |    |
        //          |----+----|
        //          |  * |    |
        //        near ------ A

        // The actual feature points never spawn outside of the unit square surrounding
        // their generating points. Therefore, the boundaries of the generating
        // squares serve as a useful means of early exit — if the square is farther
        // away than a point already found, then there is no point checking that
        // square since it cannot produce a feature point closer than we have already
        // found.

        let quadrant:(x:Bool, y:Bool) = (offset.x > 0.5, offset.y > 0.5),
            near:IntV2        = (bin.a + (quadrant.x ? 1 : 0), bin.b + (quadrant.y ? 1 : 0)),
            far:IntV2         = (bin.a + (quadrant.x ? 0 : 1), bin.b + (quadrant.y ? 0 : 1))

        let nearpoint_disp:DoubleV2 = (abs(offset.x - (quadrant.x ? 1 : 0)),
                                                   abs(offset.y - (quadrant.y ? 1 : 0)))

        var r2_min:Double = self.distance(from: sample, generating_point: near)

        @inline(__always)
        func test(generating_point:IntV2)
        {
            let r2:Double = self.distance(from: sample, generating_point: generating_point)

            if r2 < r2_min
            {
                r2_min = r2
            }
        }

        // A points
        if (0.5 - nearpoint_disp.y) * (0.5 - nearpoint_disp.y) < r2_min
        {
            test(generating_point: (near.a, far.b))
        }

        if (0.5 - nearpoint_disp.x) * (0.5 - nearpoint_disp.x) < r2_min
        {
            test(generating_point: (far.a, near.b))
        }

        // far point
        if (0.5 - nearpoint_disp.x) * (0.5 - nearpoint_disp.x) + (0.5 - nearpoint_disp.y) * (0.5 - nearpoint_disp.y) < r2_min
        {
            test(generating_point: far)
        }

        // EARLY EXIT: if we have a point within 0.5 units, we don’t have to check
        // the outer kernel
        if r2_min < 0.5*0.5
        {
            return self.amplitude * r2_min
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
        //        inner ----- B ------- C --------+

        let inner:IntV2 = (bin.a + (quadrant.x ?  2 : -1), bin.b + (quadrant.y ?  2 : -1)),
            outer:IntV2 = (bin.a + (quadrant.x ? -1 :  2), bin.b + (quadrant.y ? -1 :  2))

        // B points
        if (nearpoint_disp.x + 0.5) * (nearpoint_disp.x + 0.5) < r2_min
        {
            test(generating_point: (inner.a, near.b))
        }
        if (nearpoint_disp.y + 0.5) * (nearpoint_disp.y + 0.5) < r2_min
        {
            test(generating_point: (near.a, inner.b))
        }

        // C points
        if (nearpoint_disp.x + 0.5) * (nearpoint_disp.x + 0.5) + (0.5 - nearpoint_disp.y) * (0.5 - nearpoint_disp.y) < r2_min
        {
            test(generating_point: (inner.a, far.b))
        }
        if (nearpoint_disp.y + 0.5) * (nearpoint_disp.y + 0.5) + (0.5 - nearpoint_disp.x) * (0.5 - nearpoint_disp.x) < r2_min
        {
            test(generating_point: (far.a, inner.b))
        }

        // EARLY EXIT: if we have a point within 1 unit, we don’t have to check
        // the D points or the E points
        if r2_min < 1*1
        {
            return self.amplitude * r2_min
        }

        // D points
        if (1.5 - nearpoint_disp.y) * (1.5 - nearpoint_disp.y) < r2_min
        {
            test(generating_point: (near.a, outer.b))
        }
        if (1.5 - nearpoint_disp.x) * (1.5 - nearpoint_disp.x) < r2_min
        {
            test(generating_point: (outer.a, near.b))
        }

        // E points
        if (0.5 - nearpoint_disp.x) * (0.5 - nearpoint_disp.x) + (1.5 - nearpoint_disp.y) * (1.5 - nearpoint_disp.y) < r2_min
        {
            test(generating_point: (far.a, outer.b))
        }
        if (0.5 - nearpoint_disp.y) * (0.5 - nearpoint_disp.y) + (1.5 - nearpoint_disp.x) * (1.5 - nearpoint_disp.x) < r2_min
        {
            test(generating_point: (outer.a, far.b))
        }

        return self.amplitude * r2_min
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

        //   near - quadrant ---- near - quadrant.y
        //               |    |    |
        //               |----+----|
        //               |    | *  |
        //   near - quadrant.x -- near               quadrant →
        //                                              ↓

        let quadrant:IntV3 = (offset.x > 0.5 ? 1 : -1, offset.y > 0.5 ? 1 : -1, offset.z > 0.5 ? 1 : -1),
            near:IntV3     = (bin.a + (quadrant.a + 1) >> 1, bin.b + (quadrant.b + 1) >> 1, bin.c + (quadrant.c + 1) >> 1)

        let nearpoint_disp:DoubleV3 = (abs(offset.x - Double((quadrant.a + 1) >> 1)),
                                       abs(offset.y - Double((quadrant.b + 1) >> 1)),
                                       abs(offset.z - Double((quadrant.c + 1) >> 1)))

        var r2_min:Double = self.distance(from: sample, generating_point: near)

        let kernel:[(r:Double, cell_offsets:[(Int, Int, Int)])] =
        [
            (0.0 , [/*(0, 0, 0), */(-1, 0, 0), (0, -1, 0), (-1, -1, 0), (0, 0, -1), (-1, 0, -1), (0, -1, -1), (-1, -1, -1)]),
            (0.25, [(0, 0, 1), (-1, 0, 1), (0, -1, 1), (-1, -1, 1), (0, 1, 0), (-1, 1, 0), (1, 0, 0), (1, -1, 0),
                    (0, 1, -1), (-1, 1, -1), (1, 0, -1), (1, -1, -1)]),
            (0.5 , [(0, 1, 1), (-1, 1, 1), (1, 0, 1), (1, -1, 1), (1, 1, 0), (1, 1, -1)]),
            (0.75, [(1, 1, 1)]),
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

        for (kernel_radius, cell_offsets):(r:Double, cell_offsets:[(Int, Int, Int)]) in kernel
        {
            if r2_min < kernel_radius
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
                {                                             // move by 0.5 towards zero
                    let dx:Double = Double(cell_offset.a) + (cell_offset.a > 0 ? -0.5 : 0.5) + nearpoint_disp.x
                    cell_distance2 = dx*dx
                }

                if cell_offset.b != 0
                {                                             // move by 0.5 towards zero
                    let dy:Double = Double(cell_offset.b) + (cell_offset.b > 0 ? -0.5 : 0.5) + nearpoint_disp.y
                    cell_distance2 += dy*dy
                }

                if cell_offset.c != 0
                {                                             // move by 0.5 towards zero
                    let dz:Double = Double(cell_offset.c) + (cell_offset.c > 0 ? -0.5 : 0.5) + nearpoint_disp.z
                    cell_distance2 += dz*dz
                }

                guard cell_distance2 < r2_min
                else
                {
                    continue
                }

                let generating_point:IntV3 = (near.a + quadrant.a*cell_offset.a,
                                              near.b + quadrant.b*cell_offset.b,
                                              near.c + quadrant.c*cell_offset.c)
                let r2:Double = self.distance(from: sample, generating_point: generating_point)
                r2_min = min(r2, r2_min)
            }
        }

        return self.amplitude * r2_min
    }

    public
    func evaluate(_ x:Double, _ y:Double, _ z:Double, _:Double) -> Double
    {
        return self.evaluate(x, y)
    }
}
