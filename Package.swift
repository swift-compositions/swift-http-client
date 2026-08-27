// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-http-client",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(
            name: "HTTP Client",
            targets: ["HTTP Client"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-foundations/swift-client.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-foundations/swift-http.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-foundations/swift-http-router.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-coder-primitives.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-either-primitives.git",
            branch: "main"
        ),
    ],
    targets: [
        .target(
            name: "HTTP Client",
            dependencies: [
                .product(name: "Client", package: "swift-client"),
                .product(name: "Coder Primitive", package: "swift-coder-primitives"),
                .product(name: "HTTP", package: "swift-http"),
                .product(name: "HTTP Router", package: "swift-http-router"),
                .product(name: "Either Primitives", package: "swift-either-primitives"),
            ]
        ),
        .testTarget(
            name: "HTTP Client Tests",
            dependencies: [
                "HTTP Client",
                .product(name: "Client", package: "swift-client"),
                .product(name: "HTTP", package: "swift-http"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    target.swiftSettings = (target.swiftSettings ?? []) + [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]
}
