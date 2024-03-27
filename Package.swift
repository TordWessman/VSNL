// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VSNL",
    platforms: [
        .iOS("13.0"),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "VSNL",
            targets: ["VSNL"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "VSNL",
            dependencies: []),
        .testTarget(
            name: "VSNLTests",
            dependencies: ["VSNL"]),
    ]
)
