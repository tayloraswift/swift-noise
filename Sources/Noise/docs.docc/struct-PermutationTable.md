###### Structure

# `PermutationTable`
An 8-bit permutation table useful for generating pseudo-random hash values.

![](png/banner_voronoi2d.png)
> *Permutation tables can be used, among other things, to hash [cell noise](struct-CellNoise2D.md#func-closest_point_-xdouble-_-ydouble---pointint-int-r2double) to produce a [Voronoi diagram](https://en.wikipedia.org/wiki/Voronoi_diagram).*
***

## Symbols

### Initializers

#### `init(seed:Int)`
> Creates an instance with the given random `seed` containing the values `0 ... 255` shuffled in a random order.

### Instance methods

#### `func` `hash(_ h1:Int) -> UInt8`
> Hash a single integer value.

#### `func` `hash(_ h1:Int, _ h2:Int) -> UInt8`
> Hash two integer values.

#### `func` `hash(_ h1:Int, _ h2:Int, _ h3:Int) -> UInt8`
> Hash three integer values.
