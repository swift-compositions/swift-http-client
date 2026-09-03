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
            url: "https://github.com/swift-compositions/swift-client.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-compositions/swift-http.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-compositions/swift-http-coder.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-compositions/swift-http-router.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-ietf/swift-rfc-9110.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-either.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-parser.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-serializer.git",
            branch: "main"
        ),
    ],
    targets: [
        .target(
            name: "HTTP Client",
            dependencies: [
                .product(name: "Client", package: "swift-client"),
                .product(name: "HTTP", package: "swift-http"),
                .product(name: "HTTP Coder", package: "swift-http-coder"),
                .product(name: "HTTP Router", package: "swift-http-router"),
                .product(name: "Either", package: "swift-either"),
                .product(name: "RFC 9110", package: "swift-rfc-9110"),
                .product(name: "Parser", package: "swift-parser"),
                .product(name: "Serializer", package: "swift-serializer"),
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
