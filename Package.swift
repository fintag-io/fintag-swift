// swift-tools-version:5.6
import PackageDescription

let package = Package(
    name: "FinTag",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "FinTag",
            targets: ["FinTag"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.7.0")
    ],
    targets: [
        .target(
            name: "FinTag",
            dependencies: ["CryptoSwift"]
        ),
        .testTarget(
            name: "FinTagTests",
            dependencies: ["FinTag"]
        ),
    ]
)
