<div align="center">
  
***`noise`***<br>`2.0.0`
  
[![ci build status](https://github.com/kelvin13/swift-noise/actions/workflows/build.yml/badge.svg)](https://github.com/kelvin13/swift-noise/actions/workflows/build.yml)

[![swift package index versions](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fkelvin13%2Fswift-noise%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/kelvin13/swift-noise)
[![swift package index platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fkelvin13%2Fswift-noise%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/kelvin13/swift-noise)

</div>

![](doc/1.0.0/png/banner_FBM.png)

**`swift-noise`** is a free, pure Swift procedural noise generation library. The library product has no dependencies and does not import Foundation or any system frameworks. 

All popular types of procedural noise are supported, including three [gradient noises](https://en.wikipedia.org/wiki/Perlin_noise) (often called Perlin or simplex noises), and two [cellular noises](https://en.wikipedia.org/wiki/Worley_noise) (sometimes called Worley or Voronoi noises). 

`swift-noise` includes a [fractal brownian motion](https://thebookofshaders.com/13/) (FBM) noise composition framework, and a [disk point sampler](https://en.wikipedia.org/wiki/Supersampling#Poisson_disc) (often called a Poisson sampler), for generating visually even point distributions in the plane. `swift-noise` also includes pseudo-random number generation and hashing tools.

`swift-noise`’s entire public API is [documented](doc/1.0.0).

## Building

Build *Noise* with the Swift Package Manager. *Noise* itself has no dependencies, but the tests use [`swift-png`](https://github.com/kelvin13/swift-png) to view the generated noise.
