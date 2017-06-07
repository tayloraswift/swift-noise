import func Glibc.rand
import func Glibc.srand
import var Glibc.RAND_MAX

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
    let candidate_ring:[Point]

    private
    var candidate_index:Int = 0

    private
    var candidate_offset:Point
    {
        return self.candidate_ring[self.candidate_index]
    }

    //private
    //var grid:[Bool] = []

    private static
    let candidate_table_bitmask:Int = 0b1111111111 // 1023

    public
    init(seed:Int = 0)
    {
        let rand_scale:Double = 4 / Double(CInt.max)
        srand(UInt32(extendingOrTruncating: seed))

        var candidates_generated:Int = 0
        var candidate_ring:[Point] = []
            candidate_ring.reserveCapacity(PoissonSampler.candidate_table_bitmask + 1)

        while candidates_generated <= PoissonSampler.candidate_table_bitmask
        {
            let x:Double  = Double(rand()) * rand_scale - 1,
                y:Double  = Double(rand()) * rand_scale - 1,
                r2:Double = x*x + y*y

            guard r2 < 4 && r2 > 1
            else
            {
                continue
            }

            candidate_ring.append(Point(x, y))
            candidates_generated += 1
        }

        self.candidate_ring = candidate_ring
    }

    public mutating
    func generate(radius:Double, width:Int, height:Int, k:Int = 32, seed:Point? = nil) -> [Point]
    {
        let normalized_width:Double  = Double(width ) / radius,
            normalized_height:Double = Double(height) / radius,
            grid_width:Int  = Int((2.squareRoot() * normalized_width ).rounded(.up)),
            grid_height:Int = Int((2.squareRoot() * normalized_height).rounded(.up))
        var grid:[[Point?]] = [[Point?]](repeating: [Point?](repeating: nil, count: grid_width + 4), count: grid_height + 4)

        var queue:[Point]
        if let seed:Point = seed
        {
            queue = [Point(Double(seed.x) / radius, Double(seed.y) / radius)]
        }
        else
        {
            queue = [Point(0.5 * normalized_width, 0.5 * normalized_height)]
        }

        var points:[Point] = queue
        outer: while let front:Point = queue.last
        {
            for _ in 0 ..< k
            {
                let offset:Point    = self.candidate_offset,
                    candidate:Point = Point(front.x + offset.x, front.y + offset.y)
                self.candidate_index = (self.candidate_index + 1) & PoissonSampler.candidate_table_bitmask

                guard 0 ..< normalized_width ~= candidate.x && 0 ..< normalized_height ~= candidate.y
                else
                {
                    continue
                }

                if PoissonSampler.attempt_insert(candidate: candidate, into_grid: &grid)
                {
                    points.append(Point(candidate.x * radius, candidate.y * radius))
                    queue.append(candidate)
                    queue.swapAt(queue.endIndex - 1, PoissonSampler.random(less_than: queue.endIndex))
                    continue outer
                }
            }
            queue.removeLast()
        }

        return points
    }

    private static
    func attempt_insert(candidate:Point, into_grid grid:inout [[Point?]]) -> Bool
    {
        let i:Int = Int(candidate.y * 2.squareRoot()) + 2,
            j:Int = Int(candidate.x * 2.squareRoot()) + 2

        guard grid[i][j] == nil
        else
        {
            return false
        }

        let ring:[Point?] = [                   grid[i - 2][j - 1], grid[i - 2][j], grid[i - 2][j + 1],
                            grid[i - 1][j - 2], grid[i - 1][j - 1], grid[i - 1][j], grid[i - 1][j + 1], grid[i - 1][j + 2],
                            grid[i    ][j - 2], grid[i    ][j - 1],                 grid[i    ][j + 1], grid[i    ][j + 2],
                            grid[i + 1][j - 2], grid[i + 1][j - 1], grid[i + 1][j], grid[i + 1][j + 1], grid[i + 1][j + 2],
                                                grid[i + 2][j - 1], grid[i + 2][j], grid[i + 2][j + 1]]
        for cell:Point? in ring
        {
            guard let occupant:Point = cell
            else
            {
                continue
            }

            let dx:Double = occupant.x - candidate.x,
                dy:Double = occupant.y - candidate.y

            guard dx * dx + dy * dy > 1
            else
            {
                return false
            }
        }

        grid[i][j] = candidate
        return true
    }

    private static
    func random(less_than maximum:Int) -> Int
    {
        let upper_bound:CInt = RAND_MAX - RAND_MAX % CInt(maximum)
        var x:CInt = 0
        repeat
        {
            x = rand()
        } while x >= upper_bound

        return Int(x) % maximum
    }
}
