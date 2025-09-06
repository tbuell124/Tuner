// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PedalTuner",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "PedalTuner", targets: ["PedalTuner"])
    ],
    targets: [
        .target(
            name: "PedalTuner",
            path: "Sources/PedalTuner"
        ),
        .testTarget(
            name: "PedalTunerTests",
            dependencies: ["PedalTuner"],
            path: "Tests/PedalTunerTests"
        )
    ]
)
