// swift-tools-version: 6.3.3

import PackageDescription

let package = Package(
    name: "swift-http-client",
    platforms: [.macOS(.v26), .iOS(.v26), .tvOS(.v26), .watchOS(.v26), .visionOS(.v26)],
    products: [.library(name: "HTTP Client", targets: ["HTTP Client"])],
    dependencies: [
        .package(url: "https://github.com/swift-foundations/swift-http-body.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-pool-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-io.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-sockets.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-tls.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "HTTP Client",
            dependencies: [
                .product(name: "HTTP Transport", package: "swift-http-body"),
                .product(name: "Pool Bounded Primitives", package: "swift-pool-primitives"),
                .product(name: "IO", package: "swift-io"),
                .product(name: "Sockets", package: "swift-sockets"),
                .product(name: "TLS", package: "swift-tls"),
                .product(name: "TLS Engine Interface", package: "swift-tls"),
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
