// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DataFramework",
    platforms: [.iOS(.v12)],
    products: [
        .library(
            name: "DataFramework",
            targets: ["DataFramework"]),
    ],
    dependencies: [
        .package(url: "https://github.com/onmyway133/DeepDiff.git", from: "2.0.0"),
        .package(url: "https://github.com/ReactiveCocoa/ReactiveCocoa.git", from: "11.0.0")
    ],
    targets: [
        .target(
            name: "DataFramework",
            dependencies: ["ReactiveCocoa", "DeepDiff"],
            path: "DataFramework/Classes"),
        .testTarget(
            name: "DataFramework_Tests",
            dependencies: ["DataFramework", "ReactiveCocoa", "DeepDiff"],
            path: "Example/Tests"),
    ]
)
