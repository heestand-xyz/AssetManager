// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "AssetManager",
    platforms: [
        .iOS(.v14),
        .macOS(.v11),
    ],
    products: [
        .library(
            name: "AssetManager",
            targets: ["AssetManager"]),
    ],
    targets: [
        .target(
            name: "AssetManager",
            dependencies: []),
    ]
)
