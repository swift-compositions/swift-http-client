extension RFC_9110 {
    /// A concrete, pooled HTTP exchange executor.
    public final class Client: Sendable {
        public let retry: HTTP.Retry.Policy

        @usableFromInline
        let connections: Pool.Bounded<Connection>

        public init(connections: Pool.Bounded<Connection>, retry: HTTP.Retry.Policy = .init()) {
            self.connections = connections
            self.retry = retry
        }
    }
}

extension RFC_9110.Client {
    /// The structural transport view of this client.
    public var transport: HTTP.Transport<HTTP.Client.Error> {
        .init(execute: execute)
    }
}
