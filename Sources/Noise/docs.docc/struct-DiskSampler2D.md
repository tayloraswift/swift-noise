# ``DiskSampler2D``

A point sampler capable of producing uniform and roughly-evenly spaced pseudo-random point distributions in the plane. Disk sampling is sometimes referred to as [Poisson sampling](https://en.wikipedia.org/wiki/Supersampling#Poisson_disc).

Disk samples are not a noise field — its generation is inherently sequential, as opposed to most procedural noise fields which are embarrassingly parallel. Thus, disk samples have no concept of *evaluation*; the entire sample set must be generated as a whole.

Disk samples have an internal state, which is advanced every time the point generator is run. In many ways, disk samples have more in common with pseudo-random number generators than they do with procedural noise fields.

![](png/banner_disk2d.png)
***

## Symbols

### Initializers

#### `init(seed:Int = 0)`
> Creates an instance with the given fixed random `seed`. This process calculates a random table used internally in the sample generation step. The same instance can be reused to generate multiple, different point distributions.

### Instance methods

#### `mutating func` `generate(radius:Double, width:Int, height:Int, k:Int = 32, seed:(Double, Double)? = nil) -> [(Double, Double)]`
> Generates a set of sample points that are spaced no less than `radius` apart over a region sized `width` by `height` . Up to `k` candidate points will be used to generate each sample point; higher values of `k` yield more compact point distributions, but take longer to run. The `seed` point specifies the first point that is added to the distribution, and influences where subsequent sample points are added. This `seed` is orthogonal to the `seed` supplied in the initializer. If `seed` is left `nil`, the seed point is placed at the center of the region.
