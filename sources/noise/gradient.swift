import func Glibc.sin
import func Glibc.cos

fileprivate let SQUISH_2D :Double = 0.5 * (1 / 3.squareRoot() - 1)
fileprivate let STRETCH_2D:Double = 0.5 * (3.squareRoot() - 1)

fileprivate
protocol GradientNoise2D:Noise
{
    var permutation_table:PermutationTable { get }

    static var gradient_table16:[Math.DoubleV2] { get }
    static var radius:Double { get }
}

fileprivate
extension GradientNoise2D
{
    func gradient(from point:Math.IntV2, at offset:Math.DoubleV2) -> Double
    {
        let dr:Double = Self.radius - Math.dot(offset, offset)
        if dr > 0
        {
            let gradient:Math.DoubleV2 = Self.gradient_table16[self.permutation_table.hash(point) & 15],
                drdr:Double = dr * dr
            return drdr * drdr * Math.dot(gradient, offset)
        }
        else
        {
            return 0
        }
    }
}

public
struct SimplexNoise2D:GradientNoise2D
{
    fileprivate static
    let gradient_table16:[Math.DoubleV2] =
    [
        (-1, -1),   (1,  0),   (-1,  0),   (1,  1),
        (-1,  1),   (0, -1),    (0,  1),   (1, -1),

        (-1, -1),   (1,  0),   (-1,  0),   (1,  1),
        (-1,  1),   (0, -1),    (0,  1),   (1, -1)
    ]

    fileprivate static
    let radius:Double = 2

    fileprivate
    let permutation_table:PermutationTable

    private
    let amplitude:Double, // not the same amplitude passed into the initializer
        frequency:Double

    public
    init(amplitude:Double, frequency:Double, seed:Int = 0)
    {
        self.amplitude = 0.096 * amplitude
        self.frequency = frequency
        self.permutation_table = PermutationTable(seed: seed)
    }

    public
    func evaluate(_ x:Double, _ y:Double) -> Double
    {
        let sample:Math.DoubleV2 = (x * self.frequency, y * self.frequency)
        // transform our coordinate system so that the *simplex* (x, y) forms a
        // rectangular grid (u, v)
        let squish_offset:Double    = (sample.x + sample.y) * SQUISH_2D,
            sample_uv:Math.DoubleV2 = (sample.x + squish_offset, sample.y + squish_offset)

        // get integral (u, v) coordinates of the rhombus and get position inside
        // the rhombus relative to (floor(u), floor(v))
        let (bin, sample_uv_rel):(Math.IntV2, Math.DoubleV2) = Math.fraction(sample_uv)

        //   (0, 0) ----- (1, 0)
        //       \    A    / \
        //         \     /     \                ← (x, y) coordinates
        //           \ /    B    \
        //         (0, 1)-------(1, 1)

        //                   (1, -1)
        //                    /   |
        //                  /  D  |
        //                /       |
        //    bin = (0, 0) --- (1, 0) -- (2, 0)
        //          /   |      /  |       /
        //        /  E  | A  /  B |  C  /       ← (u, v) coordinates
        //      /       |  /      |   /
        // (-1, 1) -- (0, 1) --- (1, 1)
        //              |       /
        //              |  F  /
        //              |   /
        //            (0, 2)

        // do the same in the original (x, y) coordinate space

        // stretch back to get (x, y) coordinates of rhombus origin
        let stretch_offset:Double = Double(bin.a + bin.b) * STRETCH_2D,
            origin:Math.DoubleV2 = (Double(bin.a) + stretch_offset, Double(bin.b) + stretch_offset)

        // get relative position inside the rhombus relative to (xb, xb)
        let sample_rel:Math.DoubleV2 = Math.sub(sample, origin)

        var Σ:Double = 0 // the value of the noise function, which we will sum up

        @inline(__always)
        func _inspect(point_offset:Math.IntV2, sample_offset:Math.DoubleV2)
        {
            Σ += gradient(from: Math.add(bin, point_offset), at: Math.sub(sample_rel, sample_offset))
        }

        // contribution from (1, 0)
        _inspect(point_offset: (1, 0), sample_offset: (1 + STRETCH_2D, STRETCH_2D))

        // contribution from (0, 1)
        _inspect(point_offset: (0, 1), sample_offset: (STRETCH_2D, 1 + STRETCH_2D))

        // decide which triangle we are in
        let uv_sum:Double = sample_uv_rel.x + sample_uv_rel.y
        if (uv_sum > 1) // we are to the bottom-right of the diagonal line (du = 1 - dv)
        {
            _inspect(point_offset: (1, 1), sample_offset: (1 + 2*STRETCH_2D, 1 + 2*STRETCH_2D))

            let center_dist:Double = 2 - uv_sum
            if center_dist < sample_uv_rel.x || center_dist < sample_uv_rel.y
            {
                if sample_uv_rel.x > sample_uv_rel.y
                {
                    _inspect(point_offset: (2, 0), sample_offset: (2 + 2*STRETCH_2D, 2*STRETCH_2D))
                }
                else
                {
                    _inspect(point_offset: (0, 2), sample_offset: (2*STRETCH_2D, 2 + 2*STRETCH_2D))
                }
            }
            else
            {
                Σ += gradient(from: bin, at: sample_rel)
            }
        }
        else
        {
            Σ += gradient(from: bin, at: sample_rel)

            let center_dist:Double = 1 - uv_sum
            if center_dist > sample_uv_rel.x || center_dist > sample_uv_rel.y
            {
                if sample_uv_rel.x > sample_uv_rel.y
                {
                    _inspect(point_offset: (1, -1), sample_offset: (-1, 1))
                }
                else
                {
                    _inspect(point_offset: (-1, 1), sample_offset: (1, -1))
                }
            }
            else
            {
                _inspect(point_offset: (1, 1), sample_offset: (1 + 2*STRETCH_2D, 1 + 2*STRETCH_2D))
            }
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
struct SuperSimplexNoise2D:GradientNoise2D
{
    private static
    let points:[(Math.IntV2, Math.DoubleV2)] =
    {
        var points:[(Math.IntV2, Math.DoubleV2)] = []
            points.reserveCapacity(32)

        @inline(__always)
        func _lattice_point(at point:Math.IntV2) -> (Math.IntV2, Math.DoubleV2)
        {
            let stretch_offset:Double = Double(point.a + point.b) * SQUISH_2D
            return (point, (Double(point.a) + stretch_offset, Double(point.b) + stretch_offset))
        }

        for (i1, j1, i2, j2):(Int, Int, Int, Int) in
        [
            (-1, 0, 0, -1), (0, 1, 1, 0), (1, 0, 0, -1), (2, 1, 1, 0),
            (-1, 0, 0,  1), (0, 1, 1, 2), (1, 0, 0,  1), (2, 1, 1, 2)
        ]
        {
            points.append(_lattice_point(at: ( 0,  0)))
            points.append(_lattice_point(at: ( 1,  1)))
            points.append(_lattice_point(at: (i1, j1)))
            points.append(_lattice_point(at: (i2, j2)))
        }

        return points
    }()

    static
    let gradient_table16:[Math.DoubleV2] =
    {
        var gradients:[Math.DoubleV2] = []
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
        let sample:Math.DoubleV2 = (x * self.frequency, y * self.frequency)
        // transform our (x, y) coordinate to (u, v) space
        let stretch_offset:Double = (sample.x + sample.y) * STRETCH_2D,
            sample_uv:Math.DoubleV2 = (sample.x + stretch_offset, sample.y + stretch_offset)

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

        // use the (u, v) coordinates to bin the triangle and get relative offsets
        // from the top-left corner of the square (in (u, v) space)
        let (bin, sample_uv_rel):(Math.IntV2, Math.DoubleV2) = Math.fraction(sample_uv)

        let a:Int = sample_uv_rel.x + sample_uv_rel.y > 1 ? 1 : 0
        let base_vertex_index:Int = a << 2 |
            Int((2*sample_uv_rel.x - sample_uv_rel.y - Double(a))*0.5 + 1) << 3 |
            Int((2*sample_uv_rel.y - sample_uv_rel.x - Double(a))*0.5 + 1) << 4
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
     u = 2v - 1 |   -              |  u = 2v
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
        let squish_offset:Double = (sample_uv_rel.x + sample_uv_rel.y) * SQUISH_2D,
            sample_rel:Math.DoubleV2 = (sample_uv_rel.x + squish_offset, sample_uv_rel.y + squish_offset)

        var Σ:Double = 0
        for (point, point_offset) in SuperSimplexNoise2D.points[base_vertex_index ..< base_vertex_index + 4]
        {
            Σ += self.gradient(from: Math.add(bin, point), at: Math.sub(sample_rel, point_offset))
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
struct SuperSimplexNoise3D:Noise
{
    private static
    let points:[(Math.IntV3, Math.DoubleV3)] =
    {
        var points:[(Math.IntV3, Math.DoubleV3)] = []
            points.reserveCapacity(64)

        for n in 0 ..< 16
        {
            let p1:Math.IntV3 = (    n      & 1,     n      & 1,     n      & 1),
                p2:Math.IntV3 = (1 - n >> 1 & 1,     n >> 1 & 1,     n >> 1 & 1),
                p3:Math.IntV3 = (    n >> 2 & 1, 1 - n >> 2 & 1,     n >> 2 & 1),
                p4:Math.IntV3 = (    n >> 3 & 1,     n >> 3 & 1, 1 - n >> 3 & 1)

            points.append((p1, Math.cast_double(p1)))
            points.append((p2, Math.cast_double(p2)))
            points.append((p3, Math.cast_double(p3)))
            points.append((p4, Math.cast_double(p4)))
        }

        return points
    }()

    private static
    let gradient_table16:[Math.DoubleV3] =
    [
        (1, 1, 0), (-1,  1, 0), (1, -1,  0), (-1, -1,  0),
        (1, 0, 1), (-1,  0, 1), (1,  0, -1), (-1,  0, -1),
        (0, 1, 1), ( 0, -1, 1), (0,  1, -1), ( 0, -1, -1),
        (1, 1, 0), (-1,  1, 0), (0, -1,  1), ( 0, -1, -1)
    ]

    private
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

    private
    func gradient(from point:Math.IntV3, at offset:Math.DoubleV3) -> Double
    {
        let dr:Double = 0.75 - Math.dot(offset, offset)
        if dr > 0
        {
            let gradient:Math.DoubleV3 = SuperSimplexNoise3D.gradient_table16[self.permutation_table.hash(point) & 15],
                drdr:Double = dr * dr
            return drdr * drdr * Math.dot(gradient, offset)
        }
        else
        {
            return 0
        }
    }

    public
    func evaluate(_ x:Double, _ y:Double) -> Double
    {
        return self.evaluate(x, y, 0)
    }

    public
    func evaluate(_ x:Double, _ y:Double, _ z:Double) -> Double
    {
        let sample:Math.DoubleV3 = (x * self.frequency, y * self.frequency, z * self.frequency)

        // transform our coordinate system so that out rotated lattice (x, y, z)
        // forms an axis-aligned rectangular grid again (u, v, w)
        let rot_offset:Double = 2/3 * (sample.x + sample.y + sample.z),
            U1:Math.DoubleV3 = (rot_offset - sample.x, rot_offset - sample.y, rot_offset - sample.z),
        // do the same for an offset cube lattice
            U2:Math.DoubleV3 = (U1.x + 512.5, U1.y + 512.5, U1.z + 512.5)

        // get integral (u, v, w) cube coordinates as well as fractional offsets
        let (bin1, sample_rel1):(Math.IntV3, Math.DoubleV3) = Math.fraction(U1),
            (bin2, sample_rel2):(Math.IntV3, Math.DoubleV3) = Math.fraction(U2)

        // get nearest points
        let base_vertex_index1:Int =
            ( sample_rel1.x + sample_rel1.y + sample_rel1.z >= 1.5 ?  4 : 0) |
            (-sample_rel1.x + sample_rel1.y + sample_rel1.z >= 0.5 ?  8 : 0) |
            ( sample_rel1.x - sample_rel1.y + sample_rel1.z >= 0.5 ? 16 : 0) |
            ( sample_rel1.x + sample_rel1.y - sample_rel1.z >= 0.5 ? 32 : 0)

        let base_vertex_index2:Int =
            ( sample_rel2.x + sample_rel2.y + sample_rel2.z >= 1.5 ?  4 : 0) |
            (-sample_rel2.x + sample_rel2.y + sample_rel2.z >= 0.5 ?  8 : 0) |
            ( sample_rel2.x - sample_rel2.y + sample_rel2.z >= 0.5 ? 16 : 0) |
            ( sample_rel2.x + sample_rel2.y - sample_rel2.z >= 0.5 ? 32 : 0)

        // sum up the contributions from the two lattices
        var Σ:Double = 0
        for (point, point_offset) in SuperSimplexNoise3D.points[base_vertex_index1 ..< base_vertex_index1 + 4]
        {
            Σ += self.gradient(from: Math.add(bin1, point), at: Math.sub(sample_rel1, point_offset))
        }

        for (point, point_offset) in SuperSimplexNoise3D.points[base_vertex_index2 ..< base_vertex_index2 + 4]
        {
            Σ += self.gradient(from: Math.add(bin2, point), at: Math.sub(sample_rel2, point_offset))
        }

        return self.amplitude * Σ
    }

    public
    func evaluate(_ x:Double, _ y:Double, _ z:Double, _:Double) -> Double
    {
        return self.evaluate(x, y, z)
    }
}
