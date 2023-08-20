// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "AssetManager",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "AssetManager",
            targets: ["AssetManager"]),
    ],
    dependencies: [
        .package(url: "https://github.com/heestand-xyz/MultiViews", from: "2.0.0"),
        .package(url: "https://github.com/heestand-xyz/TextureMap", from: "0.7.5"),
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
