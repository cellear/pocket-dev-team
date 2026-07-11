// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PocketDevTeam",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "PocketDevTeam",
            targets: ["PocketDevTeam"]
        ),
    ],
    targets: [
        .target(
            name: "PocketDevTeam",
            path: "Sources"
        ),
    ]
)
