extension RFC_9110.Client {
    /// One already-authenticated HTTP connection supplied by the owned network stack.
    ///
    /// The client does not implement DNS, sockets, TLS, framing, or bodies. A
    /// connection adapter supplies those operations at this witness seam and
    /// reports whether the completed exchange may return to its `Pool.Lease`.
    public final class Connection: Sendable {
        /// A semantic transport failure, deliberately not a leaked substrate error.
        public enum Failure: Swift.Error, Sendable {
            case resolution
            case socket
            case tls
            case framing
            case closed
        }

        /// A stable pool partition. Connections never cross this identity.
        public struct Key: Sendable, Equatable, Hashable {
            public let scheme: String
            public let hostname: String
            public let port: Int
            public let peerIdentity: String

            public init(scheme: String, hostname: String, port: Int, peerIdentity: String) {
                self.scheme = scheme
                self.hostname = hostname
                self.port = port
                self.peerIdentity = peerIdentity
            }
        }

        /// Result metadata supplied by the wire adapter after it has determined framing safety.
        public struct Result: Sendable {
            public let response: HTTP.Exchange.Response<HTTP.Client.Error>
            public let reuse: HTTP.ConnectionReuse

            public init(response: HTTP.Exchange.Response<HTTP.Client.Error>, reuse: HTTP.ConnectionReuse) {
                self.response = response
                self.reuse = reuse
            }
        }

        public let key: Key
        public let execute: @Sendable (HTTP.Exchange.Request<HTTP.Client.Error>) async throws(HTTP.Client.Error) -> Result

        public init(
            key: Key,
            execute: @escaping @Sendable (HTTP.Exchange.Request<HTTP.Client.Error>) async throws(HTTP.Client.Error) -> Result
        ) {
            self.key = key
            self.execute = execute
        }
    }
}
