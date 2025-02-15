// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "AssetManager",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "AssetManager",
            targets: ["AssetManager"]),
    ],
    dependencies: [
        .package(url: "https://github.com/heestand-xyz/MultiViews", from: "3.0.0"),
        .package(url: "https://github.com/heestand-xyz/TextureMap", from: "2.1.0"),
    ],
    targets: [
        .target(
            name: "AssetManager",
            dependencies: [
                "MultiViews",
                "TextureMap",
            ]),
    ]
)
