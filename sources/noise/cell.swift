public
struct Cell2D:HashedNoise
{
    let perm1024:[Int],
        hashes:[Int]

    static
    var n_hashes:Int = 1024

    public
    init(amplitude:Double, frequency:Double, seed:Int = 0)
    {
        (self.perm1024, self.hashes) = SuperSimplex2D.table(seed: seed)
    }

    public
    func evaluate(_ x:Double, _ y:Double) -> Double
    {
        return 0
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
