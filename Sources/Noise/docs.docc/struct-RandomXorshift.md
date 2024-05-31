# ``RandomXorshift``

A cryptographically unsecure 128-bit [Xorshift](https://en.wikipedia.org/wiki/Xorshift) pseudo-random number generator.

***

## Symbols

### Instance properties

#### `var` `max:UInt32 { get }`
> The maximum unsigned integer value the random number generator is capable of producing.

### Instance methods

#### `mutating func` `generate() -> UInt32`
> Generates a pseudo-random 32 bit unsigned integer, and advances the random number generator state.

#### `mutating func` `generate(less_than maximum:UInt32) -> UInt32`
> Generates a pseudo-random 32 bit unsigned integer less than `maximum`, and advances the random number generator state. This function should be preferred over using the plain [`generate()`](#mutating-func-generate---uint32) method with the modulo operator to avoid modulo biasing. However, if `maximum` is a power of two, a bit mask may be faster.