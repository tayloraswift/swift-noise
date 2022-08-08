// swift-tools-version:5.4

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
        .package(url: "https://github.com/kelvin13/swift-png", .upToNextMinor(from: "4.0.1"))
    ],
    targets: 
    [
        .target(name: "Noise"),

        .executableTarget(name: "NoiseTests", 
            dependencies: 
            [
                .target(name: "Noise"), 
                .product(name: "PNG", package: "swift-png"), 
            ],
            path: "Tests/NoiseTests")
    ]
)
