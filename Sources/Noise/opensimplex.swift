let simplex_gradient_table_2d:[Double] =
[
    -1, -1,     1,  0,    -1,  0,     1,  1,
    -1,  1,     0, -1,     0,  1,     1, -1
]

func gradient(u:Int, v:Int, dx:Double, dy:Double) -> Double
{
    let dr1:Double = 2 - dx*dx - dy*dy
    if (dr1 > 0)
    {
        let drdr1:Double = dr1 * dr1
        let hash:Int = random_index_table[(u + random_index_table[v & 255]) & 255] & 14
        return drdr1 * drdr1 * (simplex_gradient_table_2d[hash] * dx + simplex_gradient_table_2d[hash + 1] * dy)
    }
    else
    {
        return 0
    }
}

func simplex(_ x:Double, _ y:Double) -> Double
{
    // transform our coordinate system so that the *simplex* (x, y) forms a rectangular grid (u, v)
    let squish_offset:Double = (x + y) * SQUISH_2D,
        u:Double = x + squish_offset,
        v:Double = y + squish_offset

    // get integral (u, v) coordinates of the rhombus
    let ub:Int = floor(u),
        vb:Int = floor(v)

    //   (0, 0) ----- (1, 0)
    //       \    A    / \
    //         \     /     \                ← (x, y) coordinates
    //           \ /    B    \
    //         (0, 1)-------(1, 1)

    //                   (1, -1)
    //                    /   |
    //                  /  D  |
    //                /       |
    // (ub, vb) = (0, 0) --- (1, 0) -- (2, 0)
    //          /   |      /  |       /
    //        /  E  | A  /  B |  C  /       ← (u, v) coordinates
    //      /       |  /      |   /
    // (-1, 1) -- (0, 1) --- (1, 1)
    //              |       /
    //              |  F  /
    //              |   /
    //            (0, 2)

    // get relative position inside the rhombus relative to (ub, vb)
    let du0:Double = u - Double(ub),
        dv0:Double = v - Double(vb)

    // do the same in the original (x, y) coordinate space

    // stretch back to get (x, y) coordinates of rhombus origin
    let stretch_offset:Double = Double(ub + vb) * STRETCH_2D,
        xb:Double = Double(ub) + stretch_offset,
        yb:Double = Double(vb) + stretch_offset

    // get relative position inside the rhombus relative to (xb, xb)
    let dx0:Double = x - xb,
        dy0:Double = y - yb

    var z:Double = 0 // the value of the noise function, which we will sum up

    // contribution from (1, 0)
    z += gradient(u : ub + 1,
                  v : vb,
                  dx: dx0 - 1 - STRETCH_2D,
                  dy: dy0     - STRETCH_2D)

    // contribution from (0, 1)
    z += gradient(u : ub,
                  v : vb + 1,
                  dx: dx0     - STRETCH_2D,
                  dy: dy0 - 1 - STRETCH_2D)

    // decide which triangle we are in
    let uv_sum:Double = du0 + dv0
    if (uv_sum > 1) // we are to the bottom-right of the diagonal line (du = 1 - dv)
    {
        z += gradient(u : ub  + 1,
                      v : vb  + 1,
                      dx: dx0 - 1 - 2*STRETCH_2D,
                      dy: dy0 - 1 - 2*STRETCH_2D)

        let center_dist:Double = 2 - uv_sum
        if center_dist < du0 || center_dist < dv0
        {
            if du0 > dv0
            {
                z += gradient(u : ub  + 2,
                              v : vb     ,
                              dx: dx0 - 2 - 2*STRETCH_2D,
                              dy: dy0     - 2*STRETCH_2D)
            }
            else
            {
                z += gradient(u : ub     ,
                              v : vb  + 2,
                              dx: dx0     - 2*STRETCH_2D,
                              dy: dy0 - 2 - 2*STRETCH_2D)
            }
        }
        else
        {
            z += gradient(u : ub,
                          v : vb,
                          dx: dx0,
                          dy: dy0)
        }
    }
    else
    {
        z += gradient(u : ub,
                      v : vb,
                      dx: dx0,
                      dy: dy0)

        let center_dist:Double = 1 - uv_sum
        if center_dist > du0 || center_dist > dv0
        {
            if du0 > dv0
            {
                z += gradient(u : ub  + 1,
                              v : vb  - 1,
                              dx: dx0 + 1,
                              dy: dy0 - 1)
            }
            else
            {
                z += gradient(u : ub  - 1,
                              v : vb  + 1,
                              dx: dx0 - 1,
                              dy: dy0 + 1)
            }
        }
        else
        {
            z += gradient(u : ub  + 1,
                          v : vb  + 1,
                          dx: dx0 - 1 - 2*STRETCH_2D,
                          dy: dy0 - 1 - 2*STRETCH_2D)
        }
    }

    return z * 1/14
}
