// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Bullpen",
    platforms: [
        .macOS(.v15)
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-testing.git", exact: "6.2.3"),
    ],
    targets: [
        .executableTarget(
            name: "BullpenApp",
            dependencies: [
                "LogReaders",
                "Models",
                "SpriteWorld",
                "Services",
            ],
            path: "Sources/BullpenApp"
        ),
        .target(
            name: "LogReaders",
            dependencies: ["Models"],
            path: "Sources/LogReaders"
        ),
        .target(
            name: "Models",
            path: "Sources/Models"
        ),
        .target(
            name: "SpriteWorld",
            dependencies: ["Models", "Services"],
            path: "Sources/SpriteWorld"
        ),
        .target(
            name: "Services",
            dependencies: ["Models", "LogReaders"],
            path: "Sources/Services"
        ),
        .testTarget(
            name: "BullpenTests",
            dependencies: [
                "Models",
                "LogReaders",
                "Services",
                .product(name: "Testing", package: "swift-testing"),
            ],
            path: "Tests/BullpenTests"
        ),
    ]
)
