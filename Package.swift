// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "AssetManager",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "AssetManager",
            targets: ["AssetManager"]),
    ],
    dependencies: [
        .package(url: "https://github.com/heestand-xyz/MultiViews", from: "2.0.0"),
    ],
    targets: [
        .target(
            name: "AssetManager",
            dependencies: [
                "MultiViews",
            ]),
    ]
)
