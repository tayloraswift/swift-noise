public
struct FBM<Source>:Noise where Source:Noise
{
    private
    let generators:[Source],
        octaves:Int,
        persistence:Double,
        lacunarity:Double,
        amplitude:Double

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

        self.octaves = 1
        self.persistence = 0.5
        self.lacunarity = 2
        self.amplitude = 1
    }

    @available(*, unavailable, message: "init(amplitude:frequency:seed:) defaults to octaves = 1, which does not make sense for FBM modules")
    public
    init(amplitude:Double, frequency:Double, seed:Int)
    {
        self.generators = []

        self.octaves = 1
        self.persistence = 0.5
        self.lacunarity = 2
        self.amplitude = 1
    }

    @available(*, unavailable, message: "use init(_:octaves:persistence:lacunarity:) instead")
    public
    init(amplitude:Double, frequency:Double, octaves:Int, persistence:Double = 0.75, lacunarity:Double = 2, seed:Int = 0)
    {
        self.generators  = []

        self.octaves = 1
        self.persistence = 0.5
        self.lacunarity = 2
        self.amplitude = 1
    }

    // UNDOCUMENTED, default was changed from 0.75 to 0.5
    public
    init(_ source:Source, octaves:Int, persistence:Double = 0.5, lacunarity:Double = 2)
    {
        // calculate maximum range
        if persistence == 0.5
        {
            self.amplitude = Double(1 << (octaves - 1)) / Double(1 << octaves - 1)
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

            self.amplitude = 1 / accumulation
        }

        var generators:[Source] = [source]
            generators.reserveCapacity(octaves)
        for i in (0 ..< octaves - 1)
        {
            generators.append(generators[i].reseeded())
        }

        self.generators  = generators
        self.octaves = octaves
        self.persistence = persistence
        self.lacunarity = lacunarity
    }

    public
    func evaluate(_ x:Double, _ y:Double) -> Double
    {
        var Σ:Double = 0,
            a:Double = self.amplitude,
            f:Double = 1
        for generator in self.generators
        {
            Σ += a * generator.evaluate(f * x, f * y)
            a *= self.persistence
            f *= self.lacunarity
        }
        return Σ
    }

    public
    func evaluate(_ x:Double, _ y:Double, _ z:Double) -> Double
    {
        var Σ:Double = 0,
            a:Double = self.amplitude,
            f:Double = 1
        for generator in self.generators
        {
            Σ += a * generator.evaluate(f * x, f * y, f * z)
            a *= self.persistence
            f *= self.lacunarity
        }
        return Σ
    }

    public
    func evaluate(_ x:Double, _ y:Double, _ z:Double, _ w:Double) -> Double
    {
        var Σ:Double = 0,
            a:Double = self.amplitude,
            f:Double = 1
        for generator in self.generators
        {
            Σ += a * generator.evaluate(f * x, f * y, f * z, f * w)
            a *= self.persistence
            f *= self.lacunarity
        }
        return Σ
    }
}

// UNDOCUMENTED
public
struct DistortedNoise<Source, Displacement>:Noise where Source:Noise, Displacement:Noise
{
    private
    let source:Source,
        displacement:Displacement,
        strength:Double

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
    init(displacing source:Source, with displacement:Displacement, strength:Double = 1)
    {
        self.source       = source
        self.displacement = displacement
        self.strength     = strength
    }

    public
    func evaluate(_ x: Double, _ y: Double) -> Double
    {
        let dx:Double = self.strength * self.displacement.evaluate(x, y),
            dy:Double = self.strength * self.displacement.evaluate(y, x)
        return self.source.evaluate(x + dx, y + dy)
    }

    public
    func evaluate(_ x: Double, _ y: Double, _ z: Double) -> Double
    {
        let dx:Double = self.strength * self.displacement.evaluate(x, y, z),
            dy:Double = self.strength * self.displacement.evaluate(y, z, x),
            dz:Double = self.strength * self.displacement.evaluate(z, x, y)
        return self.source.evaluate(x + dx, y + dy, z + dz)
    }

    public
    func evaluate(_ x: Double, _ y: Double, _ z: Double, _ w:Double) -> Double
    {
        let dx:Double = self.strength * self.displacement.evaluate(x, y, z, w),
            dy:Double = self.strength * self.displacement.evaluate(y, z, w, x),
            dz:Double = self.strength * self.displacement.evaluate(z, w, x, y),
            dw:Double = self.strength * self.displacement.evaluate(w, x, y, z)
        return self.source.evaluate(x + dx, y + dy, z + dz, w + dw)
    }
}

extension DistortedNoise where Source == Displacement
{
    public
    init(_ source:Source, strength:Double = 1)
    {
        self.source       = source
        self.displacement = source
        self.strength     = strength
    }
}
