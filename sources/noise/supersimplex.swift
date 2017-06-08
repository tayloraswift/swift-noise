import func Glibc.sin
import func Glibc.cos

public
struct SuperSimplex2D:GradientNoise2D
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
    let gradient_table16:[(Double, Double)] =
    {
        var gradients:[(Double, Double)] = []
            gradients.reserveCapacity(16)

        let dθ:Double = 2 * Double.pi / Double(16)
        for i in 0 ..< 16
        {
            let θ:Double = Double(i) * dθ
            gradients.append((cos(θ), sin(θ)))
        }

        return gradients
    }()

    static
    let radius:Double = 2/3

    let permutation_table:PermutationTable

    private
    let amplitude:Double,
        frequency:Double

    public
    init(amplitude:Double, frequency:Double, seed:Int = 0)
    {
        self.amplitude = 18 * amplitude
        self.frequency = frequency
        self.permutation_table = PermutationTable(seed: seed)
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
        let base_vertex_index:Int = a << 2 |
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

        var Σ:Double = 0
        for point in SuperSimplex2D.points[base_vertex_index ..< base_vertex_index + 4]
        {
            // get the relative offset from *that* particular point
            let dx:Double = dx0 - point.dx,
                dy:Double = dy0 - point.dy
            Σ += self.gradient(u: ub + point.u, v: vb + point.v, dx: dx, dy: dy)
        }
        return self.amplitude * Σ
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
struct SuperSimplex3D:GradientNoise3D
{
    private
    struct LatticePoint
    {
        let u:Int,
            v:Int,
            w:Int
        let du:Double,
            dv:Double,
            dw:Double

        init(_ u:Int, _ v:Int, _ w:Int)
        {
            self.u = u
            self.v = v
            self.w = w
            self.du = Double(u)
            self.dv = Double(v)
            self.dw = Double(w)
        }
    }

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

            points.append(LatticePoint(i1, j1, k1))
            points.append(LatticePoint(i2, j2, k2))
            points.append(LatticePoint(i3, j3, k3))
            points.append(LatticePoint(i4, j4, k4))
        }

        return points
    }()

    static
    let gradient_table16:[(Double, Double, Double)] =
    [
        (1, 1, 0), (-1, 1, 0), (1, -1, 0), (-1, -1, 0),
        (1, 0, 1), (-1, 0, 1), (1, 0, -1), (-1, 0, -1),
        (0, 1, 1), (0, -1, 1), (0, 1, -1), (0, -1, -1),
        (1, 1, 0), (-1, 1, 0), (0, -1, 1), (0, -1, -1)
    ]

    let permutation_table:PermutationTable

    private
    let amplitude:Double,
        frequency:Double

    public
    init(amplitude:Double, frequency:Double, seed:Int = 0)
    {
        self.amplitude = 9 * amplitude
        self.frequency = frequency
        self.permutation_table = PermutationTable(seed: seed)
    }

    public
    func evaluate(_ x:Double, _ y:Double) -> Double
    {
        return self.evaluate(x, y, 0)
    }

    public
    func evaluate(_ x:Double, _ y:Double, _ z:Double) -> Double
    {
        let x:Double = x * self.frequency,
            y:Double = y * self.frequency,
            z:Double = z * self.frequency

        // transform our coordinate system so that out rotated lattice (x, y, z)
        // forms an axis-aligned rectangular grid again (u, v, w)
        let rotation_offset:Double = 2/3 * (x + y + z),
            u1:Double = rotation_offset - x,
            v1:Double = rotation_offset - y,
            w1:Double = rotation_offset - z,
        // do the same for an offset cube lattice
            u2:Double = u1 + 512.5,
            v2:Double = v1 + 512.5,
            w2:Double = w1 + 512.5

        // get integral (u, v, w) cube coordinates (can Swift vectorize this??)
        let ub1:Int = floor(u1),
            vb1:Int = floor(v1),
            wb1:Int = floor(w1),
            ub2:Int = floor(u2),
            vb2:Int = floor(v2),
            wb2:Int = floor(w2)

        // get offsets inside the cubes from the cube origins
        let du1:Double = u1 - Double(ub1),
            dv1:Double = v1 - Double(vb1),
            dw1:Double = w1 - Double(wb1),
            du2:Double = u2 - Double(ub2),
            dv2:Double = v2 - Double(vb2),
            dw2:Double = w2 - Double(wb2)

        // get nearest points
        let base_vertex_index1:Int =
            ( du1 + dv1 + dw1 >= 1.5 ?  4 : 0) |
            (-du1 + dv1 + dw1 >= 0.5 ?  8 : 0) |
            ( du1 - dv1 + dw1 >= 0.5 ? 16 : 0) |
            ( du1 + dv1 - dw1 >= 0.5 ? 32 : 0)

        let base_vertex_index2:Int =
            ( du2 + dv2 + dw2 >= 1.5 ?  4 : 0) |
            (-du2 + dv2 + dw2 >= 0.5 ?  8 : 0) |
            ( du2 - dv2 + dw2 >= 0.5 ? 16 : 0) |
            ( du2 + dv2 - dw2 >= 0.5 ? 32 : 0)

        // sum up the contributions from the two lattices
        var Σ:Double = 0
        for point in SuperSimplex3D.points[base_vertex_index1 ..< base_vertex_index1 + 4]
        {
            // get the relative offset from *that* particular point
            let dx:Double = du1 - point.du,
                dy:Double = dv1 - point.dv,
                dz:Double = dw1 - point.dw
            Σ += self.gradient(u: ub1 + point.u, v: vb1 + point.v, w: wb1 + point.w, dx: dx, dy: dy, dz: dz)
        }

        for point in SuperSimplex3D.points[base_vertex_index2 ..< base_vertex_index2 + 4]
        {
            // get the relative offset from *that* particular point
            let dx:Double = du2 - point.du,
                dy:Double = dv2 - point.dv,
                dz:Double = dw2 - point.dw
            Σ += self.gradient(u: ub2 + point.u, v: vb2 + point.v, w: wb2 + point.w, dx: dx, dy: dy, dz: dz)
        }

        return self.amplitude * Σ
    }

    public
    func evaluate(_ x:Double, _ y:Double, _ z:Double, _:Double) -> Double
    {
        return self.evaluate(x, y, z)
    }
}
