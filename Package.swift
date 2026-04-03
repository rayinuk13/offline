// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Offline",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "OfflineCore", targets: ["OfflineCore"])
    ],
    targets: [
        // Pure-Swift core: models + services with no UIKit/AVFoundation dependencies.
        // This target is buildable on Linux for CI test runs.
        .target(
            name: "OfflineCore",
            path: "OfflineCore"
        ),
        .testTarget(
            name: "OfflineTests",
            dependencies: ["OfflineCore"],
            path: "OfflineTests"
        )
    ]
)
