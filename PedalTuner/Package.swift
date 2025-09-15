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
        .package(url: "https://github.com/alladinian/Tuna.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "TunePlay",
            dependencies: ["Tuna"],
            path: "Sources/TunePlay"
        ),
        .testTarget(
            name: "TunePlayTests",
            dependencies: ["TunePlay"],
            path: "Tests/TunePlayTests"
        )
    ]
)
