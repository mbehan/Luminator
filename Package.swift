// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Luminator",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "Luminator",
            targets: ["Luminator"]
        ),
    ],
    targets: [
        .target(
            name: "Luminator"
        ),
    ],
    swiftLanguageModes: [.v6]
)
