/// A point sampler capable of producing uniform and roughly-evenly spaced pseudo-random point
/// distributions in the plane. Disk sampling is sometimes referred to as
/// [Poisson sampling](https://en.wikipedia.org/wiki/Supersampling#Poisson_disc).
///
/// ![preview](png/banner_disk2d.png)
///
/// Disk samples are not a noise field — its generation is inherently sequential, as opposed to
/// most procedural noise fields which are embarrassingly parallel. Thus, disk samples have no
/// concept of *evaluation*; the entire sample set must be generated as a whole.
///
/// Disk samples have an internal state, which is advanced every time the point generator runs.
/// In many ways, disk samples have more in common with pseudo-random number generators than
/// they do with procedural noise fields.
public
struct DiskSampler2D
{
    private
    let candidate_ring:[SIMD2<Double>]

    private
    var rng:RandomXorshift,
        candidate_index:Int = 0

    private
    var candidate_offset:SIMD2<Double>
    {
        return self.candidate_ring[self.candidate_index]
    }

    private static
    let candidate_table_bitmask:Int = 0b1111111111 // 1023

    /// Creates an instance with the given fixed random `seed`. This process calculates a random
    /// table used internally in the sample generation step. The same instance can be reused to
    /// generate multiple, different point distributions.
    public
    init(seed:Int = 0)
    {
        self.rng = RandomXorshift(seed: seed)
        let rand_scale:Double = 4 / Double(self.rng.max)

        var candidates_generated:Int = 0
        var candidate_ring:[SIMD2<Double>] = []
            candidate_ring.reserveCapacity(DiskSampler2D.candidate_table_bitmask + 1)

        while candidates_generated <= DiskSampler2D.candidate_table_bitmask
        {
            let x:Double  = Double(self.rng.generate()) * rand_scale - 1,
                y:Double  = Double(self.rng.generate()) * rand_scale - 1,
                r2:Double = x*x + y*y

            guard r2 < 4 && r2 > 1
            else
            {
                continue
            }

            candidate_ring.append(SIMD2<Double>(x, y))
            candidates_generated += 1
        }

        self.candidate_ring = candidate_ring
    }

    /// Generates a set of sample points that are spaced no less than `radius` apart over a
    /// region sized `width` by `height` . Up to `k` candidate points will be used to generate
    /// each sample point; higher values of `k` yield more compact point distributions, but take
    /// longer to run. The `seed` point specifies the first point that is added to the
    /// distribution, and influences where subsequent sample points are added. This `seed` is
    /// orthogonal to the `seed` supplied in the initializer. If `seed` is left `nil`, the seed
    /// point is placed at the center of the region.
    public mutating
    func generate(radius:Double, width:Int, height:Int, k:Int = 32, seed:SIMD2<Double>? = nil) -> [SIMD2<Double>]
    {
        let normalized_width:Double  = Double(width ) / radius,
            normalized_height:Double = Double(height) / radius,
            grid_width:Int  = Int((2.squareRoot() * normalized_width ).rounded(.up)),
            grid_height:Int = Int((2.squareRoot() * normalized_height).rounded(.up)),
            grid_stride:Int = grid_width + 4
        var grid = [Math.DoubleV2?](repeating: nil, count: grid_stride * (grid_height + 4))

        var queue:[SIMD2<Double>]
        if let seed:SIMD2<Double> = seed
        {
            queue = [SIMD2<Double>(seed / radius)]
        }
        else
        {
            queue = [SIMD2<Double>(0.5 * normalized_width, 0.5 * normalized_height)]
        }

        _ = DiskSampler2D.attempt_insert(candidate: queue[0], into_grid: &grid, grid_stride: grid_stride)
        var points:[SIMD2<Double>] = [queue[0] * radius]
        outer: while let front:SIMD2<Double> = queue.last
        {
            for _ in 0 ..< k
            {
                let candidate:Math.DoubleV2 = Math.add(front, self.candidate_offset)
                self.candidate_index = (self.candidate_index + 1) & DiskSampler2D.candidate_table_bitmask

                guard 0 ..< normalized_width ~= candidate.x && 0 ..< normalized_height ~= candidate.y
                else
                {
                    continue
                }

                if DiskSampler2D.attempt_insert(candidate: candidate, into_grid: &grid, grid_stride: grid_stride)
                {
                    points.append(candidate * radius)
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
    func attempt_insert(candidate:SIMD2<Double>, into_grid grid:inout [SIMD2<Double>?], grid_stride:Int) -> Bool
    {
        let i:Int      = Int(candidate.y * 2.squareRoot()) + 2,
            j:Int      = Int(candidate.x * 2.squareRoot()) + 2,
            center:Int = i * grid_stride + j

        guard grid[center] == nil
        else
        {
            return false
        }

        let base:(Int, Int, Int, Int) = (center - 2*grid_stride,
                                         center -   grid_stride,
                                         center +   grid_stride,
                                         center + 2*grid_stride)

        let ring:[SIMD2<Double>?] = [         grid[base.0 - 1], grid[base.0], grid[base.0 + 1],
                            grid[base.1 - 2], grid[base.1 - 1], grid[base.1], grid[base.1 + 1], grid[base.1 + 2],
                            grid[center - 2], grid[center - 1],               grid[center + 1], grid[center + 2],
                            grid[base.2 - 2], grid[base.2 - 1], grid[base.2], grid[base.2 + 1], grid[base.2 + 2],
                                              grid[base.3 - 1], grid[base.3], grid[base.3 + 1]]
        for cell:SIMD2<Double>? in ring
        {
            guard let occupant:SIMD2<Double> = cell
            else
            {
                continue
            }

            let dv = occupant - candidate

            guard Math.dot(dv, dv) > 1
            else
            {
                return false
            }
        }

        grid[center] = candidate
        return true
    }
}
