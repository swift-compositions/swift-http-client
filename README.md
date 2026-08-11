# swift-http-client

Concrete pooled HTTP client implementation. This feature branch is unverified: it has not yet been resolved, built, tested, linted, or observed in CI.

## Installation

Add the package dependency using its current branch:

```swift
.package(
    url: "https://github.com/swift-foundations/swift-http-client.git",
    branch: "feature/tx-n7b-http-client"
)
```

Then add the `HTTP Client` product to the target that executes HTTP exchanges:

```swift
.product(name: "HTTP Client", package: "swift-http-client")
```

## Key features

- `HTTP.Client` exposes its work as `HTTP.Transport<HTTP.Client.Error>`.
- `HTTP.Retry.Policy` bounds retries to replayable, idempotent exchanges.
- `HTTP.ConnectionReuse` makes the return-or-destroy decision explicit for every `Pool.Lease` resource.
- `HTTP.Client.Network` records the `IO`/`Sockets` and `TLS` values a connection factory composes; DNS resolution uses the configuration's sole `TLS.Peer.Identity`.

## Architecture

The client owns exchange execution, retry, and lease disposition. HTTP message and body structure remains in `HTTP Transport`; DNS, sockets, TLS, certificate verification, and pools remain at their respective owners. The current public producer seams require callers to supply an already-configured `Pool.Lease<HTTP.Client.Connection>`; the pending atomic connection-factory signature is documented in the package's DocC article.

The exact TLS dependency exposes `TLS.Session` as a non-Sendable, uniquely owned value transferred into one owning region. HTTP Client retains only reusable TLS configuration and engine-witness values, so this producer transition requires no client source adapter or compatibility shim.

## License

Apache License 2.0.
