public
struct PoissonSampler
{
    public
    struct Point
    {
        public
        let x:Double,
            y:Double

        init(_ x:Double, _ y:Double)
        {
            self.x = x
            self.y = y
        }
    }

    private
    let candidate_ring:[Math.DoubleV2]

    private
    var rng:RandomXORShift,
        candidate_index:Int = 0

    private
    var candidate_offset:Math.DoubleV2
    {
        return self.candidate_ring[self.candidate_index]
    }

    private static
    let candidate_table_bitmask:Int = 0b1111111111 // 1023

    public
    init(seed:Int = 0)
    {
        self.rng = RandomXORShift(seed: seed)
        let rand_scale:Double = 4 / Double(self.rng.max)

        var candidates_generated:Int = 0
        var candidate_ring:[Math.DoubleV2] = []
            candidate_ring.reserveCapacity(PoissonSampler.candidate_table_bitmask + 1)

        while candidates_generated <= PoissonSampler.candidate_table_bitmask
        {
            let x:Double  = Double(self.rng.generate()) * rand_scale - 1,
                y:Double  = Double(self.rng.generate()) * rand_scale - 1,
                r2:Double = x*x + y*y

            guard r2 < 4 && r2 > 1
            else
            {
                continue
            }

            candidate_ring.append((x, y))
            candidates_generated += 1
        }

        self.candidate_ring = candidate_ring
    }

    public mutating
    func generate(radius:Double, width:Int, height:Int, k:Int = 32, seed:(Double, Double)? = nil) -> [(Double, Double)]
    {
        let normalized_width:Double  = Double(width ) / radius,
            normalized_height:Double = Double(height) / radius,
            grid_width:Int  = Int((2.squareRoot() * normalized_width ).rounded(.up)),
            grid_height:Int = Int((2.squareRoot() * normalized_height).rounded(.up))
        var grid = [[Math.DoubleV2?]](repeating: [Math.DoubleV2?](repeating: nil, count: grid_width + 4), count: grid_height + 4)

        var queue:[Math.DoubleV2]
        if let seed:Math.DoubleV2 = seed
        {
            queue = [(Double(seed.x) / radius, Double(seed.y) / radius)]
        }
        else
        {
            queue = [(0.5 * normalized_width, 0.5 * normalized_height)]
        }

        var points:[(Double, Double)] = queue
        outer: while let front:Math.DoubleV2 = queue.last
        {
            for _ in 0 ..< k
            {
                let candidate:Math.DoubleV2 = Math.add(front, self.candidate_offset)
                self.candidate_index = (self.candidate_index + 1) & PoissonSampler.candidate_table_bitmask

                guard 0 ..< normalized_width ~= candidate.x && 0 ..< normalized_height ~= candidate.y
                else
                {
                    continue
                }

                if PoissonSampler.attempt_insert(candidate: candidate, into_grid: &grid)
                {
                    points.append((candidate.x * radius, candidate.y * radius))
                    queue.append(candidate)
                    queue.swapAt(queue.endIndex - 1, Int(self.rng.generate(less_than: UInt32(queue.endIndex))))
                    continue outer
                }
            }
            queue.removeLast()
        }

        return points
    }

    private static
    func attempt_insert(candidate:Math.DoubleV2, into_grid grid:inout [[Math.DoubleV2?]]) -> Bool
    {
        let i:Int = Int(candidate.y * 2.squareRoot()) + 2,
            j:Int = Int(candidate.x * 2.squareRoot()) + 2

        guard grid[i][j] == nil
        else
        {
            return false
        }

        let ring:[Math.DoubleV2?] = [           grid[i - 2][j - 1], grid[i - 2][j], grid[i - 2][j + 1],
                            grid[i - 1][j - 2], grid[i - 1][j - 1], grid[i - 1][j], grid[i - 1][j + 1], grid[i - 1][j + 2],
                            grid[i    ][j - 2], grid[i    ][j - 1],                 grid[i    ][j + 1], grid[i    ][j + 2],
                            grid[i + 1][j - 2], grid[i + 1][j - 1], grid[i + 1][j], grid[i + 1][j + 1], grid[i + 1][j + 2],
                                                grid[i + 2][j - 1], grid[i + 2][j], grid[i + 2][j + 1]]
        for cell:Math.DoubleV2? in ring
        {
            guard let occupant:Math.DoubleV2 = cell
            else
            {
                continue
            }

            let dv:Math.DoubleV2 = Math.sub(occupant, candidate)

            guard Math.dot(dv, dv) > 1
            else
            {
                return false
            }
        }

        grid[i][j] = candidate
        return true
    }
}
