// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GhrianKit",
    platforms: [
        .macOS("26.0"),
        .iOS("26.0")
    ],
    products: [
        .library(name: "GhrianKit", targets: ["GhrianKit"])
    ],
    targets: [
        .target(name: "GhrianKit"),
        .testTarget(
            name: "GhrianKitTests",
            dependencies: ["GhrianKit"],
            resources: [.process("Fixtures")]
        )
    ]
)
