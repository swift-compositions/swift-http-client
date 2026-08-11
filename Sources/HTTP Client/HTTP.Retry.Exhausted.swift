extension RFC_9110.Retry {
    /// The retry budget was consumed by failures eligible for retry.
    public struct Exhausted: Swift.Error, Sendable, Equatable {
        public let attempts: Int

        public init(attempts: Int) {
            self.attempts = attempts
        }
    }
}
