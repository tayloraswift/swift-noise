// required: `libz-dev`, `libcairo-dev`
// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "Noise",
    targets: [Target(name: "Noise")],
    dependencies: [.Package(url: "https://github.com/kelvin13/maxpng", Version("2.0.0"))],
    swiftLanguageVersions: [3, 4]
)
