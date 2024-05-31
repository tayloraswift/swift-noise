// swift-tools-version:5.8

import PackageDescription

let package = Package(
    name: "swift-noise",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6)],
    products: 
    [
        .library(name: "Noise", targets: ["Noise"]),
        .executable(name: "noise-tests", targets: ["NoiseTests"])
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

        .executableTarget(name: "NoiseTests",
                          dependencies: [
                            .target(name: "Noise"),
                            .product(name: "PNG", package: "swift-png"),
                          ],
                          path: "Tests/NoiseTests",
                          exclude:[
                            "calibrate.blend",
                            "calibrate.blend1"
                          ])
    ]
)
