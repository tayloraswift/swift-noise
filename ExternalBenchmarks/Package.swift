// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ExternalBenchmarks",
    platforms: [
        .macOS(.v13),
    ],
    dependencies: [
        .package(url: "https://github.com/ordo-one/package-benchmark", .upToNextMajor(from: "1.0.0")),
        .package(path: "../"),
    ],
    targets: [
        .executableTarget(
            name: "ExternalBenchmarks",
            dependencies: [
                .product(name: "Benchmark", package: "package-benchmark"),
                .product(name: "BenchmarkPlugin", package: "package-benchmark"),
                .product(name: "Noise", package: "swift-noise"),
            ],
            path: "Benchmarks/ExternalBenchmarks"
        )
    ]
)
