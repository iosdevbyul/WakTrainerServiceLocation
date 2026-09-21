// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "WakTrainerServiceLocation",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "WakTrainerServiceLocation",
            targets: [
                "WakTrainerServiceLocation"
            ]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/iosdevbyul/WakTrainerCoreModels",
            branch: "main"
        ),
        .package(
            url: "https://github.com/iosdevbyul/TrisLocationKit",
            branch: "main"
        )
    ],
    targets: [
        .target(
            name: "WakTrainerServiceLocation",
            dependencies: [
                .product(
                    name: "WakTrainerCoreModels",
                    package: "WakTrainerCoreModels"
                ),
                .product(
                    name: "TrisLocationKit",
                    package: "TrisLocationKit"
                )
            ]
        ),
        .testTarget(
            name: "WakTrainerServiceLocationTests",
            dependencies: [
                "WakTrainerServiceLocation",
                .product(
                    name: "TrisLocationKit",
                    package: "TrisLocationKit"
                )
            ]
        )
    ]
)
