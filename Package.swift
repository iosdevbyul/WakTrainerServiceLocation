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
        .package(path: "../WakTrainerCoreModels")
    ],
    targets: [
        .target(
            name: "WakTrainerServiceLocation",
            dependencies: ["WakTrainerCoreModels"]
        )
    ]
)
