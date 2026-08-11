extension RFC_9110.Client {
    /// One already-authenticated HTTP connection supplied by the owned network stack.
    ///
    /// The client does not implement DNS, sockets, TLS, framing, or bodies. A
    /// connection adapter supplies those operations at this witness seam and
    /// reports whether the completed exchange may return to its `Pool.Bounded`.
    public struct Connection: ~Copyable {
        /// A semantic transport failure, deliberately not a leaked substrate error.
        public enum Failure: Swift.Error, Sendable {
            case resolution
            case socket
            case tls
            case framing
            case closed
        }

        /// A stable pool partition. Connections never cross this identity.
        public struct Key: Sendable {
            public let scheme: String
            public let port: Int
            public let identity: TLS.Peer.Identity

            public init(scheme: String, port: Int, identity: TLS.Peer.Identity) {
                self.scheme = scheme
                self.port = port
                self.identity = identity
            }
        }

        /// A response and the connection disposition proved by the wire adapter.
        public enum Result: ~Copyable, Sendable {
            case reusable(HTTP.Exchange.Response<HTTP.Client.Error>)
            case invalid(HTTP.Exchange.Response<HTTP.Client.Error>)

            public init(
                response: consuming HTTP.Exchange.Response<HTTP.Client.Error>,
                reuse: HTTP.ConnectionReuse
            ) {
                switch reuse {
                case .reusable:
                    self = .reusable(response)
                case .invalid:
                    self = .invalid(response)
                }
            }
        }

        /// One exclusively owned HTTP exchange operation.
        public struct Operation: ~Copyable {
            @usableFromInline
            let call: (consuming HTTP.Exchange.Request<HTTP.Client.Error>) async throws(HTTP.Client.Error) -> sending Result

            public init(
                _ call: sending @escaping (consuming HTTP.Exchange.Request<HTTP.Client.Error>) async throws(HTTP.Client.Error) -> sending Result
            ) {
                self.call = call
            }

            public borrowing func callAsFunction(
                _ request: consuming HTTP.Exchange.Request<HTTP.Client.Error>
            ) async throws(HTTP.Client.Error) -> sending Result {
                try await call(consume request)
            }
        }

        public let key: Key
        public let operation: Operation

        public init(
            key: Key,
            operation: consuming Operation
        ) {
            self.key = key
            self.operation = consume operation
        }

        public borrowing func execute(
            _ request: consuming HTTP.Exchange.Request<HTTP.Client.Error>
        ) async throws(HTTP.Client.Error) -> sending Result {
            try await operation(consume request)
        }
    }
}
