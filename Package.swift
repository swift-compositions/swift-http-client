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
        .library(name: "HTTP Client AsyncHTTPClient", targets: ["HTTP Client AsyncHTTPClient"]),
    ],
    traits: [
        .trait(name: "AsyncHTTPClient", description: "A network transport for macOS and Linux, over AsyncHTTPClient")
    ],
    dependencies: [
        .package(url: "https://github.com/swift-compositions/swift-http-router.git", branch: "main"),
        .package(url: "https://github.com/swift-ietf/swift-rfc-9110.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-byte.git", branch: "main"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.37.1"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.80.0"),
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
        .target(
            name: "HTTP Client AsyncHTTPClient",
            dependencies: [
                .target(name: "HTTP Client"),
                .product(name: "HTTP", package: "swift-http-router"),
                .product(name: "RFC 9110", package: "swift-rfc-9110"),
                .product(name: "Byte", package: "swift-byte"),
                .product(name: "AsyncHTTPClient", package: "async-http-client", condition: .when(traits: ["AsyncHTTPClient"])),
                .product(name: "NIOCore", package: "swift-nio", condition: .when(traits: ["AsyncHTTPClient"])),
                .product(name: "NIOHTTP1", package: "swift-nio", condition: .when(traits: ["AsyncHTTPClient"])),
            ]
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
