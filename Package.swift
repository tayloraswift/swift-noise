// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "Noise",
    products: 
    [
        .library(name: "Noise", targets: ["Noise"]),
        .executable(name: "noise-tests", targets: ["NoiseTests"])
    ],
    dependencies: 
    [
        .package(url: "https://github.com/kelvin13/png", .exact("3.0.0"))
    ],
    targets: 
    [
        .target(name: "Noise", path: "sources/noise"),
        .target(name: "NoiseTests", dependencies: ["Noise", "PNG"], path: "tests/noise")
    ]
)
