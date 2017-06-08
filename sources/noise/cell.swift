public
struct CellNoise2D:Noise
{
    private
    let permutation_table:PermutationTable,
        amplitude:Double,
        frequency:Double

    public
    init(amplitude:Double, frequency:Double, seed:Int = 0)
    {
        self.amplitude = 2.squareRoot() * amplitude
        self.frequency = frequency
        self.permutation_table = PermutationTable(seed: seed)
    }

    private
    func distance(from sample_point:(x:Double, y:Double), generating_point:(a:Int, b:Int)) -> Double
    {
        let hash:Int = self.permutation_table.hash(generating_point.a, generating_point.b)
        // hash is within 0 ... 255, take it to 0 ... 0.5
        let length:Double = Double(hash) * 0.5/255,
            diagonal:Double = length * (1 / 2.squareRoot())

        let (dpx, dpy):(Double, Double)
        switch hash & 0b0111
        {
        case 0:
            (dpx, dpy) = ( diagonal,  diagonal)
        case 1:
            (dpx, dpy) = (-diagonal,  diagonal)
        case 2:
            (dpx, dpy) = (-diagonal, -diagonal)
        case 3:
            (dpx, dpy) = ( diagonal, -diagonal)
        case 4:
            (dpx, dpy) = ( length, 0)
        case 5:
            (dpx, dpy) = (0,  length)
        case 6:
            (dpx, dpy) = (-length, 0)
        case 7:
            (dpx, dpy) = ( 0, -length)
        default:
            fatalError("unreachable")
        }

        let dx:Double = Double(generating_point.a) + dpx - sample_point.x,
            dy:Double = Double(generating_point.b) + dpy - sample_point.y
        return dx*dx + dy*dy
    }

    public
    func evaluate(_ x:Double, _ y:Double) -> Double
    {
        let sample:(x:Double, y:Double) = (x * self.frequency, y * self.frequency)

        let bin:(a:Int, b:Int)          = (floor(sample.x), floor(sample.y)),
            offset:(x:Double, y:Double) = (sample.x - Double(bin.a), sample.y - Double(bin.b))

        // determine kernel

        // The control points do not live within the grid cells, rather they float
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

        // The bin itself is divided into quadrants to classify the four corners as
        // “near” and “far” points. We call these points the *generating points*.
        // The sample point (example) has been marked with an ‘*’.

        //          O ------- far
        //          |    |    |
        //          |----+----|
        //          |  * |    |
        //       near ------- O

        // The actual control points never spawn more than 0.5 normalized units
        // away from the near and far points, and their cross-analogues. Therefore,
        // the quadrants also provide a means of early exit, since if a sample is
        // closer to a control point than the quadrant dividers, it is impossible
        // for the sample to be closer to the control point that lives on the
        // other side of the divider.

        let quadrant:(x:Bool, y:Bool) = (offset.x > 0.5, offset.y > 0.5),
            near:(a:Int, b:Int) = (bin.a + (quadrant.x ? 1 : 0), bin.b + (quadrant.y ? 1 : 0)),
            far:(a:Int, b:Int)  = (bin.a + (quadrant.x ? 0 : 1), bin.b + (quadrant.y ? 0 : 1))

        let divider_distance:(x:Double, y:Double) = ((offset.x - 0.5) * (offset.x - 0.5), (offset.y - 0.5) * (offset.y - 0.5))

        var r2_min:Double = self.distance(from: sample, generating_point: near)

        @inline(__always)
        func test(generating_point:(a:Int, b:Int))
        {
            let r2:Double = self.distance(from: sample, generating_point: generating_point)

            if r2 < r2_min
            {
                r2_min = r2
            }
        }

        if divider_distance.x < r2_min
        {
            test(generating_point: (far.a, near.b)) // near point horizontal
        }

        if divider_distance.y < r2_min
        {
            test(generating_point: (near.a, far.b)) // near point vertical
        }

        if divider_distance.x < r2_min && divider_distance.y < r2_min
        {
            test(generating_point: far)
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
    struct Point3
    {
        let x:Double, y:Double, z:Double

        init(_ x:Double, _ y:Double, _ z:Double)
        {
            self.x = x
            self.y = y
            self.z = z
        }
    }

    private
    let permutation_table:PermutationTable,
        amplitude:Double,
        frequency:Double

    public
    init(amplitude:Double, frequency:Double, seed:Int = 0)
    {
        self.amplitude = 2.squareRoot() * amplitude
        self.frequency = frequency
        self.permutation_table = PermutationTable(seed: seed)
    }

    private
    func distance(from sample_point:(x:Double, y:Double, z:Double), generating_point:(a:Int, b:Int, c:Int)) -> Double
    {
        let hash:Int = self.permutation_table.hash(generating_point.a, generating_point.b, generating_point.c)
        // hash is within 0 ... 255, take it to 0 ... 0.5

        // Notice that we have 256 possible hashes, and therefore 8 bits of entropy,
        // to be divided up between three axes. We can assign 3 bits to the x and
        // y axes each (8 levels each), and 2 bits to the z axis (4 levels). To
        // compensate for the lack of z resolution, we bump up every other control
        // point by half a level.

        //          0b XXX YYY ZZ

        let dpx:Double = (Double(hash >> 5                                         ) - 3.5) * 0.25,
            dpy:Double = (Double(hash >> 2 & 0b0111                                ) - 3.5) * 0.25,
            dpz:Double = (Double(hash << 1 & 0b0111 + ((hash >> 5 ^ hash >> 2) & 1)) - 3.5) * 0.25

        let dx:Double = Double(generating_point.a) + dpx - sample_point.x,
            dy:Double = Double(generating_point.b) + dpy - sample_point.y,
            dz:Double = Double(generating_point.c) + dpz - sample_point.z
        return dx*dx + dy*dy + dz*dz
    }

    public
    func evaluate(_ x:Double, _ y:Double) -> Double
    {
        /*
        let sample:(x:Double, y:Double) = (x * self.frequency, y * self.frequency)

        let bin:(a:Int, b:Int)          = (floor(sample.x), floor(sample.y)),
            offset:(x:Double, y:Double) = (sample.x - Double(bin.a), sample.y - Double(bin.b))

        // determine kernel

        // The control points do not live within the grid cells, rather they float
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

        // The bin itself is divided into quadrants to classify the four corners as
        // “near” and “far” points. We call these points the *generating points*.
        // The sample point (example) has been marked with an ‘*’.

        //          O ------- far
        //          |    |    |
        //          |----+----|
        //          |  * |    |
        //       near ------- O

        // The actual control points never spawn more than 0.5 normalized units
        // away from the near and far points, and their cross-analogues. Therefore,
        // the quadrants also provide a means of early exit, since if a sample is
        // closer to a control point than the quadrant dividers, it is impossible
        // for the sample to be closer to the control point that lives on the
        // other side of the divider.

        let quadrant:(x:Bool, y:Bool) = (offset.x > 0.5, offset.y > 0.5),
            near:(a:Int, b:Int) = (bin.a + (quadrant.x ? 1 : 0), bin.b + (quadrant.y ? 1 : 0)),
            far:(a:Int, b:Int)  = (bin.a + (quadrant.x ? 0 : 1), bin.b + (quadrant.y ? 0 : 1))

        let divider_distance:(x:Double, y:Double) = ((offset.x - 0.5) * (offset.x - 0.5), (offset.y - 0.5) * (offset.y - 0.5))

        var r2_min:Double = self.distance(from: sample, generating_point: near)

        @inline(__always)
        func test(generating_point:(a:Int, b:Int))
        {
            let r2:Double = self.distance(from: sample, generating_point: generating_point)

            if r2 < r2_min
            {
                r2_min = r2
            }
        }

        if divider_distance.x < r2_min
        {
            test(generating_point: (far.a, near.b)) // near point horizontal
        }

        if divider_distance.y < r2_min
        {
            test(generating_point: (near.a, far.b)) // near point vertical
        }

        if divider_distance.x < r2_min && divider_distance.y < r2_min
        {
            test(generating_point: far)
        }

        return self.amplitude * r2_min
        */
        return 0
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
