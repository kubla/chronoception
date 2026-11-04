// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ChronoceptionShared",
    platforms: [.iOS(.v17), .watchOS(.v10), .macOS(.v14)],
    products: [
        .library(name: "ChronoceptionCore", targets: ["ChronoceptionCore"]),
        .library(name: "ChronoceptionStorage", targets: ["ChronoceptionStorage"]),
    ],
    targets: [
        .target(name: "ChronoceptionCore"),
        .target(name: "ChronoceptionStorage", dependencies: ["ChronoceptionCore"]),
        .testTarget(
            name: "ChronoceptionCoreTests", dependencies: ["ChronoceptionCore", "ChronoceptionStorage"]),
    ]
)
