// swift-tools-version: 6.3.3

import PackageDescription

let package = Package(
    name: "swift-http-client",
    platforms: [.macOS(.v26), .iOS(.v26), .tvOS(.v26), .watchOS(.v26), .visionOS(.v26)],
    products: [.library(name: "HTTP Client", targets: ["HTTP Client"])],
    dependencies: [
        .package(url: "https://github.com/swift-foundations/swift-http-body.git", branch: "feature/tx-n5-n7a-http-body-transport"),
        .package(url: "https://github.com/swift-foundations/swift-pools.git", revision: "4ace862"),
        .package(url: "https://github.com/swift-foundations/swift-io.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-sockets.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-domain-name-system.git", revision: "4bd74b5"),
        .package(url: "https://github.com/swift-foundations/swift-tls.git", branch: "feature/tx-n4-tls-core-engines"),
        .package(url: "https://github.com/swift-primitives/swift-either-primitives.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "HTTP Client",
            dependencies: [
                .product(name: "HTTP Transport", package: "swift-http-body"),
                .product(name: "Pools", package: "swift-pools"),
                .product(name: "IO", package: "swift-io"),
                .product(name: "Sockets", package: "swift-sockets"),
                .product(name: "Domain Name System", package: "swift-domain-name-system"),
                .product(name: "TLS", package: "swift-tls"),
                .product(name: "TLS Engine Interface", package: "swift-tls"),
                .product(name: "Either Primitives", package: "swift-either-primitives"),
            ]
        ),
        .testTarget(name: "HTTP Client Tests", dependencies: ["HTTP Client"]),
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
        .enableExperimentalFeature("LifetimeDependence"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]
}
