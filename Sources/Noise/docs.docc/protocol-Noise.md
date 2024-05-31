###### Protocol

# `Noise`
A procedural noise generator.

***

## Symbols 

### Initializers

#### `init(amplitude:Double, frequency:Double, seed:Int)`
> Creates an instance with the given `amplitude`, `frequency`, and random `seed` values. Creating an instance generates a new pseudo-random permutation table for that instance, and a new instance does not need to be regenerated to sample the same procedural noise field.

### Instance methods 

#### `func` `evaluate(_ x:Double, _ y:Double) -> Double`
> Evaluates the noise field at the given coordinate. For three-dimensional and higher noise fields, the `z` and `w` coordinates, if applicable, are set to zero.

#### `func` `evaluate(_ x:Double, _ y:Double, _ z:Double) -> Double`
> Evaluates the noise field at the given coordinate. For two-dimensional noise fields, the `z` coordinate is ignored. For four-dimensional noise fields, the `w` coordinate is set to zero.

#### `func` `evaluate(_ x:Double, _ y:Double, _ z:Double, _ w:Double) -> Double`
> Evaluates the noise field at the given coordinate. For three-dimensional and lower noise fields, the `z` and `w` coordinates are ignored, if necessary. No existing noise generator in the library currently supports true four-dimensional evaluation.

#### `func` `sample_area(width:Int, height:Int) -> [(Double, Double, Double)]` 
> Evaluates the noise field over the given area, starting from the origin, and extending over the first quadrant, taking unit steps in both directions. Although the `x` and `y` coordinates are returned, the output vector is guaranteed to be in row-major order.

#### `func` `sample_area_saturated_to_u8(width:Int, height:Int, offset:Double = 0.5) -> [UInt8]` 
> Evaluates the noise field over the given area, starting from the origin, and extending over the first quadrant, storing the values in a row-major array of samples. The samples are clamped, but not scaled, to the range `0 ... 255`.

#### `func` `sample_volume(width:Int, height:Int, depth:Int) -> [(Double, Double, Double, Double)]` 
> Evaluates the noise field over the given volume, starting from the origin, and extending over the first octant, taking unit steps in all three directions. Although the `x`, `y`, and `z` coordinates are returned, the output vector is guaranteed to be in `xy`-plane-major, and then row-major order.

#### `func` `sample_volume_saturated_to_u8(width:Int, height:Int, depth:Int, offset:Double = 0.5) -> [UInt8]` 
> Evaluates the noise field over the given volume, starting from the origin, and extending over the first octant, storing the values in a `xy`-plane-major, and then row-major order array of samples. The samples are clamped, but not scaled, to the range `0 ... 255`.