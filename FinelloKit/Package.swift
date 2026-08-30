// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FinelloKit",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "FinelloKit", targets: ["FinelloKit"])
    ],
    targets: [
        .target(name: "FinelloKit"),
        .testTarget(name: "FinelloKitTests", dependencies: ["FinelloKit"]),
    ]
)
