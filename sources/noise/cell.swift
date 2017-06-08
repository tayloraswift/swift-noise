public
struct Cell2D
{

    public
    init(amplitude:Double, frequency:Double, seed:Int = 0)
    {
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
