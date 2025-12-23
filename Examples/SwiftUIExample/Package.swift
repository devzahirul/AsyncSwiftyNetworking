// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwiftUIExample",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)  // Required for dependency resolution
    ],
    dependencies: [
        .package(path: "../..")  // Reference to AsyncSwiftyNetworking
    ],
    targets: [
        .executableTarget(
            name: "SwiftUIExample",
            dependencies: [
                .product(name: "AsyncSwiftyNetworking", package: "AsyncSwiftyNetworking")
            ],
            path: "SwiftUIExample"
        )
    ]
)

