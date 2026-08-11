extension RFC_9110.Client {
    /// Failures whose recovery policy belongs to one HTTP client execution.
    public enum Error: Swift.Error, Sendable {
        /// The caller cancelled before a response was returned.
        case cancelled
        /// The configured connection pool refused or could not complete a lease.
        case pool(Pool.Lifecycle.Error)
        /// A connection could not safely execute one exchange.
        case connection(Connection.Failure)
        /// A bounded, eligible retry budget was exhausted.
        case retry(Retry.Exhausted)
    }
}
