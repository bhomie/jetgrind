// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "JetGrind",
    platforms: [
        .macOS(.v26)
    ],
    dependencies: [
        .package(url: "https://github.com/soffes/HotKey", from: "0.2.0")
    ],
    targets: [
        .executableTarget(
            name: "JetGrind",
            dependencies: ["HotKey"]
        )
    ]
)
