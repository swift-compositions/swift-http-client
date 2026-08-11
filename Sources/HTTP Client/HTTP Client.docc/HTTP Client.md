# HTTP Client

`HTTP.Client` is the L3 concrete executor of the structural `HTTP.Transport` witness. It owns only exchange execution, bounded retries, and the return-or-destroy decision for a checked-out `Pool.Bounded` resource.

It does not define HTTP messages or bodies, perform DNS resolution, open sockets, implement TLS, verify certificates, or reimplement pooling. Those responsibilities remain in `HTTP Transport`, `DNS`, `Sockets`/`IO`, `TLS`, and `Pool Bounded Primitives`.

## Connection identity

Install a distinct bounded pool for each `HTTP.Client.Connection.Key` (`scheme`, `port`, `identity`). `TLS.Peer.Identity` is the sole relation between the DNS question and the hostname used for SNI and certificate authentication; neither `HTTP.Client.Network` nor the connection key repeats either projection. A key is not shared across authorities or security modes. The adapter must reject any request whose selected authority does not match its pool.

## Retry and reuse

The default policy retries only body-free idempotent methods, only for pool or connection failures, and no more than three times. A body-free request is reconstructed from its client-owned copyable head for each attempt. Byte and stream bodies are consumed by exactly one attempt because HTTP Body exposes no replay factory. A wire adapter returns `.reusable` only after it has proved that the response framing and connection state permit a later exchange; it returns `.invalid` for close-delimited, failed, cancelled, or streaming exchanges.

Checkout transfers a deliberately non-Sendable `Pool.Bounded.Handle` into the executing region. The client borrows its move-only connection for one attempt and consumes `resolve` on every success or failure path. A produced move-only response is carried through `.reusable` or `.invalid`, so concurrent shutdown cannot erase it. Cancellation before checkout reaches the pool lifecycle error; cancellation during an attempt invalidates the connection before the client returns or throws. `shutdown` remains owned by `Pool.Bounded`; no new connections are checked out after it begins.

## Pending producer seam

The current producer APIs do not expose a typed client-facing factory that can atomically: resolve `TLS.Configuration.identity.query`, race or select `IP.Address` values, connect through `IO<Sockets.Capabilities>`, hand a `Sockets.TCP.Connection` to `TLS.Engine.Witness`, and map its typed failures into `HTTP.Client.Error` while preserving bounded-pool creation failure semantics. This package therefore accepts an already-configured `Pool.Bounded<HTTP.Client.Connection>` and records the exact network inputs as `HTTP.Client.Network`. It does not fabricate that adapter locally.

The pinned TLS producer makes `TLS.Session` a non-Sendable, uniquely owned value transferred by `sending` into its owning region. HTTP Client does not construct, store, or transfer a session: its public network context retains only the reusable `TLS.Configuration` and `TLS.Engine.Witness` values. The external connection factory that eventually owns the wire adapter must receive the session into one owning region and must not erase that ownership with an unchecked conformance, box, or compatibility shim.
