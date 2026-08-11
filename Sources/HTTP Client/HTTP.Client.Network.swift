extension RFC_9110.Client {
    /// The exact public producer values an external connection factory receives.
    ///
    /// `Context` names composition, not a second socket/DNS/TLS implementation.
    /// A factory resolves `tls.identity.query`, connects through `io`, and hands the socket to
    /// `engine`; its resulting `Connection` is installed in a `Pool.Bounded` by
    /// the application boundary.
    public struct Network: Sendable {
        public let io: IO<Sockets.Capabilities>
        public let tls: TLS.Configuration
        public let engine: TLS.Engine.Witness

        public init(
            io: IO<Sockets.Capabilities>,
            tls: TLS.Configuration,
            engine: TLS.Engine.Witness
        ) {
            self.io = io
            self.tls = tls
            self.engine = engine
        }
    }
}
