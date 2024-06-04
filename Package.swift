// swift-tools-version:5.8

import PackageDescription

let package = Package(
    name: "swift-noise",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6)],
    products: 
    [
        .library(name: "Noise", targets: ["Noise"]),
        .executable(name: "generate-noise", targets: ["GenNoise"])
    ],
    dependencies: 
    [
        .package(url: "https://github.com/tayloraswift/swift-png", from: "4.4.0")
    ],
    targets: 
    [
        .target(
            name: "Noise"
        ),
//        .testTarget(name: "NoiseTests", dependencies: ["Noise"])
        .executableTarget(name: "GenNoise",
                          dependencies: [
                            .target(name: "Noise"),
                            .product(name: "PNG", package: "swift-png"),
                          ],
                          exclude:[
                            "calibrate.blend",
                            "calibrate.blend1"
                          ])
    ]
)
