# ``Noise``

Generate and combine commonly used procedural noise patterns and distributions.

*This wiki documents features present in* [Noise *1.0.0*](https://github.com/tayloraswift/noise/releases/tag/1.0.0). *Many new features are currently being added to* [`master`](https://github.com/tayloraswift/noise/tree/master) *for* Noise *2.0.0, and several types and methods will be deprecated or removed for 2.0.0, including* [`SimplexNoise2D`](struct-SimplexNoise2D.md).
***

## Symbols

### Protocols

#### `protocol` [`Noise`](protocol-Noise.md)
> A procedural noise generator.

### Structures

#### `struct` [`SimplexNoise2D`](struct-SimplexNoise2D.md)
> A type of two-dimensional gradient noise (sometimes called [Perlin noise](https://en.wikipedia.org/wiki/Perlin_noise)), suitable for texturing two-dimensional planes. Simplex noise is supported in the library mainly because it has historical significance; it has since been superseded by the less popular, but more powerful and more efficient super-simplex noise.

#### `struct` [`SuperSimplexNoise2D`](struct-SuperSimplexNoise2D.md)
> A type of two-dimensional gradient noise (sometimes called [Perlin noise](https://en.wikipedia.org/wiki/Perlin_noise)), suitable for texturing two-dimensional planes. Super-simplex noise is an improved version of simplex noise which runs faster and scales better to higher dimensions.


#### `struct` [`SuperSimplexNoise3D`](struct-SuperSimplexNoise3D.md)
> A type of three-dimensional gradient noise (sometimes called [Perlin noise](https://en.wikipedia.org/wiki/Perlin_noise)), suitable for texturing arbitrary three-dimensional objects.

#### `struct` [`CellNoise2D`](struct-CellNoise2D.md)
> A type of two-dimensional cellular noise (sometimes called [Worley noise](https://en.wikipedia.org/wiki/Worley_noise), or Voronoi noise), suitable for texturing two-dimensional planes.

#### `struct` [`CellNoise3D`](struct-CellNoise3D.md)
> A type of three-dimensional cellular noise (sometimes called [Worley noise](https://en.wikipedia.org/wiki/Worley_noise), or Voronoi noise), suitable for texturing arbitrary three-dimensional objects.

#### `struct` [`DiskSampler2D`](struct-DiskSampler2D.md)
> A point sampler capable of producing uniform and roughly-evenly spaced pseudo-random point distributions in the plane. Disk sampling is sometimes referred to as [Poisson sampling](https://en.wikipedia.org/wiki/Supersampling#Poisson_disc).

#### `struct` [`FBM`](struct-FBM.md)
> A generic [fractal brownian motion](https://thebookofshaders.com/13/) noise generator, capable of overlaying multiple instances of procedural [noise](protocol-Noise.md) at increasing frequencies.

#### `struct` [`PermutationTable`](struct-PermutationTable.md)
> An 8-bit permutation table useful for generating pseudo-random hash values.

#### `struct` [`RandomXorshift`](struct-RandomXorshift.md)
> A cryptographically unsecure 128-bit [Xorshift](https://en.wikipedia.org/wiki/Xorshift) pseudo-random number generator.
