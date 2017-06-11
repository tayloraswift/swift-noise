# noise

[![Build](https://travis-ci.org/kelvin13/noise.svg?branch=master)](https://travis-ci.org/kelvin13/noise)
[![Issues](https://img.shields.io/github/issues/kelvin13/noise.svg)](https://github.com/kelvin13/noise/issues?state=open)
[![Language](https://img.shields.io/badge/version-swift_4-ffa020.svg)](https://swift.org/)
[![License](https://img.shields.io/badge/license-GPL3-ff3079.svg)](https://github.com/kelvin13/noise/blob/master/LICENSE.gpl3)
[![Queen](https://img.shields.io/badge/taylor-swift-e030ff.svg)](https://www.google.com/search?q=where+is+ts6&oq=where+is+ts6)

![](tests/banner_FBM.png)

**Noise** is a free, pure Swift procedural noise generation library. It is free of Foundation or any other Apple framework, and has no dependencies. All popular types of procedural noise are supported, including three [gradient noises](https://en.wikipedia.org/wiki/Perlin_noise) (often called Perlin or simplex noises), and two [cellular noises](https://en.wikipedia.org/wiki/Worley_noise) (sometimes called Worley or Voronoi noises). *Noise* includes a [fractal brownian motion](https://thebookofshaders.com/13/) (FBM) noise composition framework, and a [disk point sampler](https://en.wikipedia.org/wiki/Supersampling#Poisson_disc) (often called a Poisson sampler), for generating visually even point distributions in the plane. *Noise* also includes pseudo-random number generation and hashing tools.

***Noise*’s entire public API is [documented](https://github.com/kelvin13/noise/wiki).**

## Building

Build *Noise* with the Swift Package Manager. *Noise* itself has no dependencies, but the tests depend on [MaxPNG](https://github.com/kelvin13/maxpng), my free Swift PNG library, to view the generated noise.
