public
struct Simplex2D:Hashed2DGradientNoise
{
    private static
    let n_hashes:Int = 8

    static
    let gradient_table:[(Double, Double)] =
    [
        (-1, -1),   (1,  0),   (-1,  0),   (1,  1),
        (-1,  1),   (0, -1),    (0,  1),   (1, -1)
    ]

    static
    let radius:Double = 2

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
        (self.perm1024, self.hashes) = table(seed: seed, n_hashes: Simplex2D.n_hashes)
    }

    public
    func evaluate(_ x:Double, _ y:Double) -> Double
    {
        let x:Double = x * self.frequency,
            y:Double = y * self.frequency
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
