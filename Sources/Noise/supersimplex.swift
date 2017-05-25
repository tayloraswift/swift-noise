import func Glibc.sin
import func Glibc.cos

public
struct SuperSimplex2D:Hashed2DGradientNoise
{
    private
    struct LatticePoint
    {
        let u:Int,
            v:Int,
            dx:Double,
            dy:Double

        init(u:Int, v:Int)
        {
            let stretch_offset:Double = Double(u + v) * SQUISH_2D
            self.u = u
            self.v = v
            self.dx = Double(u) + stretch_offset
            self.dy = Double(v) + stretch_offset
        }
    }

    private static
    let n_hashes:Int = 16

    static
    let gradient_table:[(Double, Double)] = (0 ..< SuperSimplex2D.n_hashes).lazy.map
    { Double($0) * 2 * Double.pi/Double(SuperSimplex2D.n_hashes) }.map
    {
        let x:Double = cos($0),
            y:Double = sin($0)
        return (x, y)
    }

    private static
    let points:[LatticePoint] =
    {
        var points:[LatticePoint] = []
            points.reserveCapacity(32)

        for n in 0 ..< 8
        {
            let i1:Int, j1:Int,
                i2:Int, j2:Int

            if n & 1 != 0
            {
                if n & 2 != 0
                {
                    i1 =  2; j1 =  1
                }
                else
                {
                    i1 =  0; j1 =  1
                }

                if n & 4 != 0
                {
                    i2 =  1; j2 =  2
                }
                else
                {
                    i2 =  1; j2 =  0
                }
            }
            else
            {
                if n & 2 != 0
                {
                    i1 =  1; j1 =  0
                }
                else
                {
                    i1 = -1; j1 =  0
                }

                if n & 4 != 0
                {
                    i2 =  0; j2 =  1
                }
                else
                {
                    i2 =  0; j2 = -1
                }
            }

            points.append(LatticePoint(u:  0, v:  0))
            points.append(LatticePoint(u:  1, v:  1))
            points.append(LatticePoint(u: i1, v: j1))
            points.append(LatticePoint(u: i2, v: j2))
        }

        return points
    }()

    static
    let radius:Double = 2/3

    let perm1024:[Int],
        hashes:[Int]

    private
    let amplitude:Double,
        frequency:Double

    public
    init(amplitude:Double, frequency:Double, seed:Int = 0)
    {
        self.amplitude = 10 * amplitude
        self.frequency = frequency
        (self.perm1024, self.hashes) = table(seed: seed, n_hashes: SuperSimplex2D.n_hashes)
    }

    public
    func evaluate(_ x:Double, _ y:Double) -> Double
    {
        let x:Double = x * self.frequency,
            y:Double = y * self.frequency
        // transform our (x, y) coordinate to (u, v) space
        let stretch_offset:Double = (x + y) * STRETCH_2D,
            u:Double = x + stretch_offset,
            v:Double = y + stretch_offset

        //         (0, 0) ----- (1, 0)
        //           / \    A    /
        //         /     \     /                ← (x, y) coordinates
        //       /    B    \ /
        //    (0, 1) ----- (1, 1)

        //             (-1, 0)
        //                | \
        //                |    \
        //                |   C   \
        //  (0, -1) -- (0, 0) -- (1, 0)
        //       \   D   | \   A   | \
        //          \    |    \    |    \       ← (u, v) coordinates
        //             \ |   B   \ |   E   \
        //            (0, 1) -- (1, 1) -- (2, 1)
        //                  \   F   |
        //                     \    |
        //                        \ |
        //                       (1, 2)

        // use the (u, v) coordinates to bin the triangle
        let ub:Int = floor(u),
            vb:Int = floor(v)

        // get relative offsets from the top-left corner of the square (in (u, v) space)
        let du0:Double = u - Double(ub),
            dv0:Double = v - Double(vb)

        let a:Int = du0 + dv0 > 1 ? 1 : 0
        let vertex_index:Int = a << 2 |
            Int((2*du0 - dv0 - Double(a))*0.5 + 1) << 3 |
            Int((2*dv0 - du0 - Double(a))*0.5 + 1) << 4
        /*
            This bit of code deserves some explanation. OpenSimplex/SuperSimplex
            always samples four vertices. Which four depends on what part of the A–B
            square our (x, y) → (u, v) sample coordinate lands in. Think of each
            triangular slice of that square as being further subdivided into three
            smaller triangles.

            ************************
            **  *           a     **
            *  * *     *       *   *
            *   *   *      *       *
            *    *    *   b   *  c *
            *     *   e  *     *   *
            *  d   *       *    *  *
            *    *      *    *   * *
            *  *            *  *  **
            **        f           **
            ************************

            Obviously we’re running up against the bounds on what can be explained
            with an ASCII art comment. Hopefully you get the idea. We have 6 regions,
            counter-clockwise in the upper-right triangle from the top, regions a, b,
            and c, and clockwise in the lower-left triangle from the left, regions
            d, e, and f.

            Region a borders region C, so it gets the extra vertices (-1, 0) and (1, 0)
            in addition to (0, 0), and (1, 1), which every region samples. Region c
            borders region E, so it gets the extra vertices (1, 0) and (2, 1). Region b
            doesn’t border any exterior region, so it just gets the other two vertices
            of the square, (0, 1) and (1, 0). Regions d and f are the same as a and c,
            except they border D and F, respectively. Region e is essentially the same
            as region b.

            This means that we effectively have five different vertex selection outcomes.
            That means we need no less than three bits of information, i.e., three tests
            to determine where we are. Two such tests could be:

            (0, 0) -------------- (1, 0)
                | \        \       |
                |  \        \      |
                |   \        \     |
                |    \        \    |
                |     \        \   |
                |      \        \  |
                |       \        \ |
            (1, 0) -------------- (1, 1)
                       v = 2u    v = 2u - 1

            and

            (0, 0) -------------- (1, 0)
                |   -              |
                |       -          |
                |           -      |
                |               -  |
    u = 2v - 1  |   -              |  u = 2v
                |       -          |
                |           -      |
            (1, 0) -------------- (1, 1)

            Each test has two lines. How do we pick which one? We use a third test:

            (0, 0) -------------- (1, 0)
                |              /   |
                |            /     |
                |          /       |
                |        /         |
                |      /           |
                |    /  u + v = 1  |
                |  /               |
            (1, 0) -------------- (1, 1)

            If we’re in the top left, we use the lines without the offsets, otherwise
            we use the ones with the -1 offset. That’s where the `- Double(a)` term
            comes from.
        */

        // get the relative offset from (0, 0)
        let squish_offset:Double = (du0 + dv0) * SQUISH_2D,
            dx0:Double = du0 + squish_offset,
            dy0:Double = dv0 + squish_offset

        var z:Double = 0
        for point in SuperSimplex2D.points[vertex_index ..< vertex_index + 4]
        {
            // get the relative offset from *that* particular point
            let dx:Double = dx0 - point.dx,
                dy:Double = dy0 - point.dy
            z += self.gradient(u: ub + point.u, v: vb + point.v, dx: dx, dy: dy)
        }
        return self.amplitude * z
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
struct SuperSimplex3D:Hashed3DGradientNoise
{
    private
    struct LatticePoint
    {
        let u:Int,
            v:Int,
            w:Int
    }

    private static
    let n_hashes:Int = 16

    static
    let gradient_table:[(Double, Double, Double)] =
    [
        (1, 1, 0), (-1, 1, 0), (1, -1, 0), (-1, -1, 0),
        (1, 0, 1), (-1, 0, 1), (1, 0, -1), (-1, 0, -1),
        (0, 1, 1), (0, -1, 1), (0, 1, -1), (0, -1, -1),
        (1, 1, 0), (-1, 1, 0), (0, -1, 1), (0, -1, -1)
    ]

    private static
    let points:[LatticePoint] =
    {
        var points:[LatticePoint] = []
            points.reserveCapacity(64)

        for n in 0 ..< 16
        {
            let i1:Int, j1:Int, k1:Int,
                i2:Int, j2:Int, k2:Int,
                i3:Int, j3:Int, k3:Int,
                i4:Int, j4:Int, k4:Int

            if n & 1 != 0
            {
                i1 = 1; j1 = 1; k1 = 1
            }
            else
            {
                i1 = 0; j1 = 0; k1 = 0
            }

            if n & 2 != 0
            {
                i2 = 0; j2 = 1; k2 = 1
            }
            else
            {
                i2 = 1; j2 = 0; k2 = 0
            }

            if n & 4 != 0
            {
                i3 = 1; j3 = 0; k3 = 1
            }
            else
            {
                i3 = 0; j3 = 1; k3 = 0
            }

            if n & 8 != 0
            {
                i4 = 1; j4 = 1; k4 = 0
            }
            else
            {
                i4 = 0; j4 = 0; k4 = 1
            }

            points.append(LatticePoint(u: i1, v: j1, w: k1))
            points.append(LatticePoint(u: i2, v: j2, w: k2))
            points.append(LatticePoint(u: i3, v: j3, w: k3))
            points.append(LatticePoint(u: i4, v: j4, w: k4))
        }

        return points
    }()

    let perm1024:[Int],
        hashes:[Int]

    private
    let amplitude:Double,
        frequency:Double

    public
    init(amplitude:Double, frequency:Double, seed:Int = 0)
    {
        self.amplitude = amplitude
        self.frequency = frequency
        (self.perm1024, self.hashes) = table(seed: seed, n_hashes: SuperSimplex3D.n_hashes)
    }

    public
    func evaluate(_ x:Double, _ y:Double) -> Double
    {
        return self.evaluate(x, y, 0)
    }

    public
    func evaluate(_ x:Double, _ y:Double, _ z:Double) -> Double
    {
        return 0
    }

    public
    func evaluate(_ x:Double, _ y:Double, _ z:Double, _:Double) -> Double
    {
        return self.evaluate(x, y, z)
    }
}
