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
        .package(url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git", from: "11.0.0")
    ],
    targets: [
        .target(
            name: "TunePlay",
            dependencies: [
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads")
            ],
            path: "Sources/TunePlay"
        ),
        .testTarget(
            name: "TunePlayTests",
            dependencies: ["TunePlay"],
            path: "Tests/TunePlayTests"
        )
    ]
)
