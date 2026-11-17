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
        .library(name: "HTTP Client", targets: ["HTTP Client"]),
        .library(name: "HTTP Client Fetch", targets: ["HTTP Client Fetch"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-compositions/swift-http-router.git", branch: "main"),
        .package(url: "https://github.com/swift-ietf/swift-rfc-9110.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-byte.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "HTTP Client",
            dependencies: [
                .product(name: "HTTP", package: "swift-http-router"),
                .product(name: "RFC 9110", package: "swift-rfc-9110"),
                .product(name: "Byte", package: "swift-byte"),
            ]
        ),
        .target(
            name: "HTTP Client Fetch",
            dependencies: [
                .target(name: "HTTP Client"),
                .product(name: "HTTP", package: "swift-http-router"),
                .product(name: "RFC 9110", package: "swift-rfc-9110"),
                .product(name: "Byte", package: "swift-byte"),
            ],
            swiftSettings: [.enableExperimentalFeature("Extern")]
        ),
        .testTarget(
            name: "HTTP Client Tests",
            dependencies: [
                .target(name: "HTTP Client"),
                .target(name: "HTTP Client Fetch"),
                .product(name: "HTTP", package: "swift-http-router"),
                .product(name: "RFC 9110", package: "swift-rfc-9110"),
                .product(name: "Byte", package: "swift-byte"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    target.swiftSettings =
        (target.swiftSettings ?? []) + [
            .strictMemorySafety(),
            .enableUpcomingFeature("ExistentialAny"),
            .enableUpcomingFeature("InternalImportsByDefault"),
            .enableUpcomingFeature("MemberImportVisibility"),
            .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
            .enableUpcomingFeature("InferIsolatedConformances"),
        ]
}
