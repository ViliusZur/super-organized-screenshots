// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SuperOrganizedScreenshots",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "SuperOrganizedScreenshots",
            targets: ["SuperOrganizedScreenshots"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/soffes/HotKey", from: "0.2.0")
    ],
    targets: [
        .executableTarget(
            name: "SuperOrganizedScreenshots",
            dependencies: ["HotKey"],
            path: "Sources/SuperOrganizedScreenshots",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
