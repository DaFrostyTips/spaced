// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Spaced",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .executable(
            name: "Spaced",
            targets: ["Spaced"]
        )
    ],
    targets: [
        .executableTarget(
            name: "Spaced"
        ),
        .testTarget(
            name: "SpacedTests",
            dependencies: ["Spaced"]
        )
    ]
)
