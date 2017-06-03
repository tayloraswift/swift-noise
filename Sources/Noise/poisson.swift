import func Glibc.rand
import func Glibc.srand

public
struct PoissonSampler
{
    private
    struct Candidate
    {
        let x:Double,
            y:Double
    }

    private
    let ring_field:[Candidate],
        ring_index:Int = 0

    private static
    let ring_table_bitmask:Int = 0b1111111111 // 1023

    public
    init(seed:Int)
    {
        let rand_scale:Double = 4 / Double(CInt.max)
        srand(UInt32(extendingOrTruncating: seed))

        var candidates_generated:Int = 0
        var ring_field:[Candidate] = []
            ring_field.reserveCapacity(PoissonSampler.ring_table_bitmask + 1)

        while candidates_generated <= PoissonSampler.ring_table_bitmask
        {
            let x:Double  = Double(rand()) * rand_scale - 1,
                y:Double  = Double(rand()) * rand_scale - 1,
                r2:Double = x*x + y*y

            guard r2 < 4 && r2 > 1
            else
            {
                continue
            }

            ring_field.append(Candidate(x: x, y: y))
            candidates_generated += 1
        }

        self.ring_field = ring_field
    }
}
