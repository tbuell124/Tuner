// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TunePlay",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "TunePlay", targets: ["TunePlay"])
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "TunePlay",
            dependencies: [],
            path: "Sources/TunePlay"
        ),
        .testTarget(
            name: "TunePlayTests",
            dependencies: ["TunePlay"],
            path: "Tests/TunePlayTests"
        )
    ]
)
