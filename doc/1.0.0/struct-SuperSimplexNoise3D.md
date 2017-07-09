###### Structure 

# `SuperSimplexNoise3D`
A type of three-dimensional gradient noise (sometimes called [Perlin noise](https://en.wikipedia.org/wiki/Perlin_noise)), suitable for texturing arbitrary three-dimensional objects.

Three-dimensional super-simplex noise generally looks somewhat better visually than its [two-dimensional](struct-SuperSimplexNoise2D) counterpart, but runs about 20% slower.

`SuperSimplexNoise3D` is *similar* (but not identical) to [Blender Perlin noise](https://docs.blender.org/manual/en/dev/render/cycles/nodes/types/textures/noise.html). The *Scale* of Blender Perlin noise is approximately equivalent to `5/4` the `frequency` of `SuperSimplexNoise3D`. The range of Blender Perlin noise is approximately `0.1875 ... 0.8125` in `SuperSimplexNoise3D` units.

![](https://github.com/kelvin13/noise/blob/master/tests/banner_supersimplex3d.png)
*** 

## Symbols 

### Initializers

#### [`init`](protocol-Noise#initamplitudedouble-frequencydouble-seedint)`(amplitude:Double, frequency:Double, seed:Int = 0)`
> Creates an instance with the given `amplitude`, `frequency`, and random `seed` values. Creating an instance generates a new pseudo-random permutation table for that instance, and a new instance does not need to be regenerated to sample the same procedural noise field.

> The given amplitude is adjusted internally to produce output approximately within the range of `-amplitude ... amplitude`, however this is not strictly guaranteed.

### Instance methods 

#### `func` [`evaluate`](protocol-Noise#func-evaluate_-xdouble-_-ydouble---double)`(_ x:Double, _ y:Double) -> Double`
> Evaluates the super-simplex noise field at the given `x, y` coordinates, supplying `0` for the missing `z` coordinate.

#### `func` [`evaluate`](protocol-Noise#func-evaluate_-xdouble-_-ydouble-_-zdouble---double)`(_ x:Double, _ y:Double, _ z:Double) -> Double`
> Evaluates the super-simplex noise field at the given coordinates.

#### `func` [`evaluate`](protocol-Noise#func-evaluate_-xdouble-_-ydouble-_-zdouble-_-wdouble---double)`(_ x:Double, _ y:Double, _ z:Double, _:Double) -> Double`
> Evaluates the super-simplex noise field at the given coordinates. The fourth coordinate is ignored.

#### `func` [`sample_area`](protocol-Noise#func-sample_areawidthint-heightint---double-double-double)`(width:Int, height:Int) -> [(Double, Double, Double)]` 
> Evaluates the noise field over the given area, starting from the origin, and extending over the first quadrant, taking unit steps in both directions. Although the `x` and `y` coordinates are returned, the output vector is guaranteed to be in row-major order.

#### `func` [`sample_area_saturated_to_u8`](protocol-Noise#func-sample_area_saturated_to_u8widthint-heightint-offsetdouble--05---uint8)`(width:Int, height:Int, offset:Double = 0.5) -> [UInt8]` 
> Evaluates the noise field over the given area, starting from the origin, and extending over the first quadrant, storing the values in a row-major array of samples. The samples are clamped, but not scaled, to the range `0 ... 255`.

#### `func` [`sample_volume`](protocol-Noise#func-sample_volumewidthint-heightint-depthint---double-double-double-double)`(width:Int, height:Int, depth:Int) -> [(Double, Double, Double, Double)]` 
> Evaluates the noise field over the given volume, starting from the origin, and extending over the first octant, taking unit steps in all three directions. Although the `x`, `y`, and `z` coordinates are returned, the output vector is guaranteed to be in `xy`-plane-major, and then row-major order.

#### `func` [`sample_volume_saturated_to_u8`](protocol-Noise#func-sample_volume_saturated_to_u8widthint-heightint-depthint-offsetdouble--05---uint8)`(width:Int, height:Int, depth:Int, offset:Double = 0.5) -> [UInt8]` 
> Evaluates the noise field over the given volume, starting from the origin, and extending over the first octant, storing the values in a `xy`-plane-major, and then row-major order array of samples. The samples are clamped, but not scaled, to the range `0 ... 255`.

## Relationships 

### Conforms to

#### [`Noise`](protocol-Noise)