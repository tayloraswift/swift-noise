public
struct FBM<Source>:Noise where Source:Noise
{
    private
    let generators:[Source]

    // UNDOCUMENTED
    public
    func amplitude_scaled(by factor:Double) -> FBM
    {
        return FBM<Source>(generators: self.generators.map{ $0.amplitude_scaled(by: factor) })
    }
    public
    func frequency_scaled(by factor:Double) -> FBM
    {
        return FBM<Source>(generators: self.generators.map{ $0.frequency_scaled(by: factor) })
    }
    public
    func reseeded() -> FBM
    {
        return FBM<Source>(generators: self.generators.map{ $0.reseeded() })
    }

    private
    init(generators:[Source])
    {
        self.generators = generators
    }

    @available(*, unavailable, message: "init(amplitude:frequency:seed:) defaults to octaves = 1, which does not make sense for FBM modules")
    public
    init(amplitude:Double, frequency:Double, seed:Int)
    {
        self.generators = []
    }

    @available(*, unavailable, message: "use init(_:octaves:persistence:lacunarity:) instead")
    public
    init(amplitude:Double, frequency:Double, octaves:Int, persistence:Double = 0.75, lacunarity:Double = 2, seed:Int = 0)
    {
        self.generators  = []
    }

    // UNDOCUMENTED, default was changed from 0.75 to 0.5
    public
    init(_ source:Source, octaves:Int, persistence:Double = 0.5, lacunarity:Double = 2)
    {
        // calculate maximum range
        let range_inverse:Double
        if persistence == 0.5
        {
            range_inverse = Double(1 << (octaves - 1)) / Double(1 << octaves - 1)
        }
        else
        {
            var accumulation:Double = 1,
                contribution:Double = persistence
            for _ in (0 ..< octaves - 1)
            {
                accumulation += contribution
                contribution *= persistence
            }

            range_inverse = 1 / accumulation
        }

        var generators:[Source] = [source.amplitude_scaled(by: range_inverse)]
            generators.reserveCapacity(octaves)
        for i in (0 ..< octaves - 1)
        {
            generators.append(generators[i].amplitude_scaled(by: persistence).frequency_scaled(by: lacunarity).reseeded())
        }

        self.generators  = generators
    }

    public
    func evaluate(_ x:Double, _ y:Double) -> Double
    {
        var Σ:Double = 0
        for generator in self.generators
        {
            Σ += generator.evaluate(x, y) // a .reduce(:{}) is much slower than a simple loop
        }
        return Σ
    }

    public
    func evaluate(_ x:Double, _ y:Double, _ z:Double) -> Double
    {
        var Σ:Double = 0
        for generator in self.generators
        {
            Σ += generator.evaluate(x, y, z)
        }
        return Σ
    }

    public
    func evaluate(_ x:Double, _ y:Double, _ z:Double, _ w:Double) -> Double
    {
        var Σ:Double = 0
        for generator in self.generators
        {
            Σ += generator.evaluate(x, y, z, w)
        }
        return Σ
    }
}
extension FBM where Source:TilingNoise
{
    public
    init(tiling source:Source, octaves:Int, persistence:Double = 0.5)
    {
        // calculate maximum range
        let range_inverse:Double
        if persistence == 0.5
        {
            range_inverse = Double(1 << (octaves - 1)) / Double(1 << octaves - 1)
        }
        else
        {
            var accumulation:Double = 1,
                contribution:Double = persistence
            for _ in (0 ..< octaves - 1)
            {
                accumulation += contribution
                contribution *= persistence
            }

            range_inverse = 1 / accumulation
        }

        var generators:[Source] = [source.amplitude_scaled(by: range_inverse)]
            generators.reserveCapacity(octaves)
        for i in (0 ..< octaves - 1)
        {
            generators.append( generators[i].amplitude_scaled(by: persistence)
                                            .frequency_scaled(by: 2)
                                            .transposed(octaves: 1)
                                            .reseeded())
        }

        self.generators  = generators
    }
}

// UNDOCUMENTED
public
struct DistortedNoise<Source, Displacement>:Noise where Source:Noise, Displacement:Noise
{
    private
    let source:Source,
        displacement:Displacement

    public
    func amplitude_scaled(by factor:Double) -> DistortedNoise<Source, Displacement>
    {
        return DistortedNoise<Source, Displacement>(displacing: self.source.amplitude_scaled(by: factor),
                                                    with: self.displacement)
    }
    public
    func frequency_scaled(by factor:Double) -> DistortedNoise<Source, Displacement>
    {
        return DistortedNoise<Source, Displacement>(displacing: self.source.frequency_scaled(by: factor),
                                                    with:  self.displacement.frequency_scaled(by: factor)
                                                                            .amplitude_scaled(by: factor))
    }
    public
    func reseeded() -> DistortedNoise<Source, Displacement>
    {
        return DistortedNoise<Source, Displacement>(displacing: self.source.reseeded(),
                                                    with: self.displacement.reseeded())
    }

    public
    init(displacing source:Source, with displacement:Displacement)
    {
        self.source       = source
        self.displacement = displacement
    }

    public
    func evaluate(_ x: Double, _ y: Double) -> Double
    {
        let dx:Double = self.displacement.evaluate(x, y),
            dy:Double = self.displacement.evaluate(y, x)
        return self.source.evaluate(x + dx, y + dy)
    }

    public
    func evaluate(_ x: Double, _ y: Double, _ z: Double) -> Double
    {
        let dx:Double = self.displacement.evaluate(x, y, z),
            dy:Double = self.displacement.evaluate(y, z, x),
            dz:Double = self.displacement.evaluate(z, x, y)
        return self.source.evaluate(x + dx, y + dy, z + dz)
    }

    public
    func evaluate(_ x: Double, _ y: Double, _ z: Double, _ w:Double) -> Double
    {
        let dx:Double = self.displacement.evaluate(x, y, z, w),
            dy:Double = self.displacement.evaluate(y, z, w, x),
            dz:Double = self.displacement.evaluate(z, w, x, y),
            dw:Double = self.displacement.evaluate(w, x, y, z)
        return self.source.evaluate(x + dx, y + dy, z + dz, w + dw)
    }
}

extension DistortedNoise where Source == Displacement
{
    public
    init(_ source:Source, strength:Double)
    {
        self.source       = source
        self.displacement = source.amplitude_scaled(by: strength)
    }
}
