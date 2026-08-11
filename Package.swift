// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WakTrainerServiceLocation",
    platforms: [
        .iOS(.v14),
        .macOS(.v13)
    ],
    products: [
        .library(name: "WakTrainerServiceLocation", targets: ["WakTrainerServiceLocation"])
    ],
    dependencies: [
        .package(url: "https://github.com/iosdevbyul/WakTrainerCoreModels", branch: "main")
    ],
    targets: [
        .target(
            name: "WakTrainerServiceLocation",
            dependencies: [
                .product(name: "WakTrainerCoreModels", package: "WakTrainerCoreModels")
            ]
        )
    ]
)
