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
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-atoms/swift-byte.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-coder.git", branch: "main", traits: ["Optic", "Skip", "Byte", "Operation", "Map"]),
        .package(url: "https://github.com/swift-atoms/swift-either.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-operation.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-optic.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-parser.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-serializer.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-tagged.git", branch: "main"),
        .package(url: "https://github.com/swift-molecules/swift-client.git", branch: "main"),
        .package(url: "https://github.com/swift-standards/swift-http.git", branch: "main"),
        .package(url: "https://github.com/swift-compositions/swift-http-router.git", branch: "main"),
        .package(url: "https://github.com/swift-molecules/swift-interface.git", branch: "main"),
        .package(url: "https://github.com/swift-ietf/swift-rfc-3986.git", branch: "main"),
        .package(url: "https://github.com/swift-ietf/swift-rfc-9110.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "HTTP Client",
            dependencies: [
                .product(name: "Client", package: "swift-client"),
                .product(name: "Client Macro", package: "swift-client"),
                .product(name: "HTTP", package: "swift-http"),
                .product(name: "HTTP Router", package: "swift-http-router"),
            ]
        ),
        .testTarget(
            name: "HTTP Client Tests",
            dependencies: [
                "HTTP Client",
                .product(name: "Byte", package: "swift-byte"),
                .product(name: "Byte", package: "swift-byte"),
                .product(name: "Client", package: "swift-client"),
                .product(name: "Client Macro", package: "swift-client"),
                .product(name: "Coder", package: "swift-coder"),
                .product(name: "Either", package: "swift-either"),
                .product(name: "HTTP", package: "swift-http"),
                .product(name: "HTTP Reply", package: "swift-http-router"),
                .product(name: "HTTP Router", package: "swift-http-router"),
                .product(name: "Operation", package: "swift-operation"),
                .product(name: "Optic", package: "swift-optic"),
                .product(name: "Parser", package: "swift-parser"),
                .product(name: "RFC 3986", package: "swift-rfc-3986"),
                .product(name: "RFC 9110", package: "swift-rfc-9110"),
                .product(name: "Serializer", package: "swift-serializer"),
                .product(name: "Interface Macro", package: "swift-interface"),
                .product(name: "Tagged", package: "swift-tagged"),
                .product(name: "Tagged", package: "swift-tagged"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
