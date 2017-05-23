let super_gradient_table_2d:[Double] =
[
                0,  18.518518518518519,
9.259259259259260,  16.037507477489605,
16.037507477489605,   9.259259259259260,
18.518518518518519,                   0,
16.037507477489605,  -9.259259259259260,
9.259259259259260, -16.037507477489605,
                0, -18.518518518518519,
-9.259259259259260, -16.037507477489605,
-16.037507477489605,  -9.259259259259260,
-18.518518518518519,                   0,
-16.037507477489605,   9.259259259259260,
-9.259259259259260,  16.037507477489605,
]

func supergradient(u:Int, v:Int, dx:Double, dy:Double) -> Double
{
    let dr:Double = 2/3 - dx*dx - dy*dy // why 2/3 ?
    if (dr > 0)
    {
        let drdr:Double = dr * dr
        let hash:Int = (random_index_table[(u + random_index_table[v & 255]) & 255] % 12) << 1
        return drdr * drdr * (super_gradient_table_2d[hash] * dx + super_gradient_table_2d[hash + 1] * dy)
    }
    else
    {
        return 0
    }
}

struct LatticePoint2D
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
        self.dx = -Double(u) - stretch_offset
        self.dy = -Double(v) - stretch_offset
    }
}

let SS_LOOKUP_2D:[LatticePoint2D] =
[
    ((-1,  0), ( 0, -1)),
    (( 0,  1), ( 1,  0)),
    (( 1,  0), ( 0, -1)),
    (( 2,  1), ( 1,  0)),
    ((-1,  0), ( 0,  1)),
    (( 0,  1), ( 1,  2)),
    (( 1,  0), ( 0,  1)),
    (( 2,  1), ( 1,  2)),
].map
{
    return [LatticePoint2D(u:    0, v:    0),
            LatticePoint2D(u:    1, v:    1),
            LatticePoint2D(u: $0.0, v: $0.1),
            LatticePoint2D(u: $1.0, v: $1.1)]
}.flatMap{ $0 }

func super_simplex(_ x:Double, _ y:Double) -> Double
{
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
    //            (0, 1) -- (1, 1) --- (2, 1)
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

    let region:Int = Int(du0 + dv0) // always either 0 or 1
    let vertex_index:Int = region << 2 |
        Int(du0 - 0.5*dv0 + 1 - 0.5*Double(region)) << 3 |
        Int(dv0 - 0.5*du0 + 1 - 0.5*Double(region)) << 4

    let squish_offset:Double = (du0 + dv0) * SQUISH_2D,
        dx0:Double = du0 + squish_offset,
        dy0:Double = dv0 + squish_offset

    var z:Double = 0
    for point in SS_LOOKUP_2D[vertex_index ..< vertex_index + 4]
    {
        let dx:Double = dx0 + point.dx,
            dy:Double = dy0 + point.dy
        z += supergradient(u: ub + point.u, v: vb + point.v, dx: dx, dy: dy)
    }

    return z*0.5
}
