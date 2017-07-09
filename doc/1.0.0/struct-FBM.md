###### Structure

# `FBM`
A generic [fractal brownian motion](https://thebookofshaders.com/13/) noise generator, capable of overlaying multiple instances of procedural [noise](protocol-Noise.md) at increasing frequencies.

![](png/banner_FBM.png)
***

## Symbols

### Initializers

#### [`init`](protocol-Noise.md#initamplitudedouble-frequencydouble-seedint)`(amplitude:Double, frequency:Double, seed:Int = 0)`
> Creates an instance with the given `amplitude`, `frequency`, and random `seed` values. This initializer creates an instance of fractal noise with a single octave, and is equivalent to creating an instance of the underlying noise generator.

#### `init(amplitude:Double, frequency:Double, octaves:Int, persistence:Double = 0.75, lacunarity:Double = 2, seed:Int = 0)`
> Creates an instance with the given number of `octaves` of noise. The given `amplitude` is the amplitude of the first octave of noise, and is multiplied by `persistence` for each successive octave. The given `frequency` is the frequency of the first octave of noise, and is multiplied by the `lacunarity` for each successive octave. The `seed` value is passed through to the first octave of noise, and is incremented for each successive octave.

### Instance methods

#### `func` [`evaluate`](protocol-Noise.md#func-evaluate_-xdouble-_-ydouble---double)`(_ x:Double, _ y:Double) -> Double`
> Evaluates the noise field at the given coordinate. For three-dimensional and higher noise fields, the `z` and `w` coordinates, if applicable, are set to zero.

#### `func` [`evaluate`](protocol-Noise.md#func-evaluate_-xdouble-_-ydouble-_-zdouble---double)`(_ x:Double, _ y:Double, _ z:Double) -> Double`
> Evaluates the noise field at the given coordinate. For two-dimensional noise fields, the `z` coordinate is ignored. For four-dimensional noise fields, the `w` coordinate is set to zero.

#### `func` [`evaluate`](protocol-Noise.md#func-evaluate_-xdouble-_-ydouble-_-zdouble-_-wdouble---double)`(_ x:Double, _ y:Double, _ z:Double, _ w:Double) -> Double`
> Evaluates the noise field at the given coordinate. For three-dimensional and lower noise fields, the `z` and `w` coordinates are ignored, if necessary. No existing noise generator in the library currently supports true four-dimensional evaluation.

#### `func` [`sample_area`](protocol-Noise.md#func-sample_areawidthint-heightint---double-double-double)`(width:Int, height:Int) -> [(Double, Double, Double)]`
> Evaluates the noise field over the given area, starting from the origin, and extending over the first quadrant, taking unit steps in both directions. Although the `x` and `y` coordinates are returned, the output vector is guaranteed to be in row-major order.

#### `func` [`sample_area_saturated_to_u8`](protocol-Noise.md#func-sample_area_saturated_to_u8widthint-heightint-offsetdouble--05---uint8)`(width:Int, height:Int, offset:Double = 0.5) -> [UInt8]`
> Evaluates the noise field over the given area, starting from the origin, and extending over the first quadrant, storing the values in a row-major array of samples. The samples are clamped, but not scaled, to the range `0 ... 255`.

#### `func` [`sample_volume`](protocol-Noise.md#func-sample_volumewidthint-heightint-depthint---double-double-double-double)`(width:Int, height:Int, depth:Int) -> [(Double, Double, Double, Double)]`
> Evaluates the noise field over the given volume, starting from the origin, and extending over the first octant, taking unit steps in all three directions. Although the `x`, `y`, and `z` coordinates are returned, the output vector is guaranteed to be in `xy`-plane-major, and then row-major order.

#### `func` [`sample_volume_saturated_to_u8`](protocol-Noise.md#func-sample_volume_saturated_to_u8widthint-heightint-depthint-offsetdouble--05---uint8)`(width:Int, height:Int, depth:Int, offset:Double = 0.5) -> [UInt8]`
> Evaluates the noise field over the given volume, starting from the origin, and extending over the first octant, storing the values in a `xy`-plane-major, and then row-major order array of samples. The samples are clamped, but not scaled, to the range `0 ... 255`.

## Relationships

### Generic constraints

#### `Generator:`[`Noise`](protocol-Noise.md)

### Conforms to

#### [`Noise`](protocol-Noise.md)
