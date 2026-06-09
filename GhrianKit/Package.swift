// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GhrianKit",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
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
