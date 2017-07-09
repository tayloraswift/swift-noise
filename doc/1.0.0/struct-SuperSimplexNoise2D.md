###### Structure

# `SuperSimplexNoise2D`
A type of two-dimensional gradient noise (sometimes called [Perlin noise](https://en.wikipedia.org/wiki/Perlin_noise)), suitable for texturing two-dimensional planes. Super-simplex noise is an improved version of [simplex noise](struct-SimplexNoise2D.md) which runs faster and scales better to higher dimensions. (Simplex noise in turn is an improvement on the classical Perlin gradient noise algorithm.)

In almost all cases, super-simplex noise should be preferred over its predecessors. Super-simplex noise runs about 25% faster than its simplex predecessor, and produces higher quality gradient noise. Super-simplex noise also comes in a [three-dimensional](struct-SuperSimplexNoise3D.md) version.

![](png/banner_supersimplex2d.png)
***

## Symbols

### Initializers

#### [`init`](protocol-Noise.md#initamplitudedouble-frequencydouble-seedint)`(amplitude:Double, frequency:Double, seed:Int = 0)`
> Creates an instance with the given `amplitude`, `frequency`, and random `seed` values. Creating an instance generates a new pseudo-random permutation table for that instance, and a new instance does not need to be regenerated to sample the same procedural noise field.

> The given amplitude is adjusted internally to produce output approximately within the range of `-amplitude ... amplitude`, however this is not strictly guaranteed.

### Instance methods

#### `func` [`evaluate`](protocol-Noise.md#func-evaluate_-xdouble-_-ydouble---double)`(_ x:Double, _ y:Double) -> Double`
> Evaluates the super-simplex noise field at the given coordinates.

#### `func` [`evaluate`](protocol-Noise.md#func-evaluate_-xdouble-_-ydouble-_-zdouble---double)`(_ x:Double, _ y:Double, _:Double) -> Double`
> Evaluates the super-simplex noise field at the given coordinates. The third coordinate is ignored.

#### `func` [`evaluate`](protocol-Noise.md#func-evaluate_-xdouble-_-ydouble-_-zdouble-_-wdouble---double)`(_ x:Double, _ y:Double, _:Double, _:Double) -> Double`
> Evaluates the super-simplex noise field at the given coordinates. The third and fourth coordinates are ignored.

#### `func` [`sample_area`](protocol-Noise.md#func-sample_areawidthint-heightint---double-double-double)`(width:Int, height:Int) -> [(Double, Double, Double)]`
> Evaluates the noise field over the given area, starting from the origin, and extending over the first quadrant, taking unit steps in both directions. Although the `x` and `y` coordinates are returned, the output vector is guaranteed to be in row-major order.

#### `func` [`sample_area_saturated_to_u8`](protocol-Noise.md#func-sample_area_saturated_to_u8widthint-heightint-offsetdouble--05---uint8)`(width:Int, height:Int, offset:Double = 0.5) -> [UInt8]`
> Evaluates the noise field over the given area, starting from the origin, and extending over the first quadrant, storing the values in a row-major array of samples. The samples are clamped, but not scaled, to the range `0 ... 255`.

#### `func` [`sample_volume`](protocol-Noise.md#func-sample_volumewidthint-heightint-depthint---double-double-double-double)`(width:Int, height:Int, depth:Int) -> [(Double, Double, Double, Double)]`
> Evaluates the noise field over the given volume, starting from the origin, and extending over the first octant, taking unit steps in all three directions. Although the `x`, `y`, and `z` coordinates are returned, the output vector is guaranteed to be in `xy`-plane-major, and then row-major order.

#### `func` [`sample_volume_saturated_to_u8`](protocol-Noise.md#func-sample_volume_saturated_to_u8widthint-heightint-depthint-offsetdouble--05---uint8)`(width:Int, height:Int, depth:Int, offset:Double = 0.5) -> [UInt8]`
> Evaluates the noise field over the given volume, starting from the origin, and extending over the first octant, storing the values in a `xy`-plane-major, and then row-major order array of samples. The samples are clamped, but not scaled, to the range `0 ... 255`.

## Relationships

### Conforms to

#### [`Noise`](protocol-Noise.md)
