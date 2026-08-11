// swift-tools-version: 6.3.3

import PackageDescription

let package = Package(
    name: "swift-http-client",
    platforms: [.macOS(.v26), .iOS(.v26), .tvOS(.v26), .watchOS(.v26), .visionOS(.v26)],
    products: [.library(name: "HTTP Client", targets: ["HTTP Client"])],
    dependencies: [
        .package(url: "https://github.com/swift-foundations/swift-http-body.git", revision: "0f670ceb05701fbaaea9141342ba295d20ca4ee8"),
        .package(url: "https://github.com/swift-primitives/swift-pool-primitives.git", revision: "b7c710c945b7c8467b4521c3a2d5b00539275593"),
        .package(url: "https://github.com/swift-foundations/swift-io.git", revision: "271da4dee53063379776337a6a3b1be21751babb"),
        .package(url: "https://github.com/swift-foundations/swift-sockets.git", revision: "74a57fa388e07e09f985fee89075577993c75c5b"),
        .package(url: "https://github.com/swift-foundations/swift-tls.git", revision: "e27e99f5c841170593dde7b0396e9090a7515f62"),
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
