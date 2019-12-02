// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GitInfo",
    platforms: [.macOS("10.12")],
    products: [
        .library(name: "GitInfo", targets: ["GitInfo"]),
    ],
    dependencies: [
        .package(url: "https://github.com/johnno1962/Parallel.git", .branch("master")),
        .package(url: "https://github.com/johnno1962/SwiftRegex5.git", .branch("master")),
    ],
    targets: [
        .target(name: "GitInfo", dependencies: ["Parallel", "SwiftRegex"], path: "Sources/"),
//        .testTarget(name: "ParallelTests", dependencies: ["Parallel"], path: "ParallelTests/"),
    ]
)
