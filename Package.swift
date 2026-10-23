// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MenuBarKit",
    defaultLocalization: "en",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "MenuBarKit", targets: ["MenuBarKit"])
    ],
    targets: [
        .target(
            name: "MenuBarKit",
            resources: [
                .process("Resources")
            ]),
        .testTarget(name: "MenuBarKitTests", dependencies: ["MenuBarKit"]),
    ]
)
