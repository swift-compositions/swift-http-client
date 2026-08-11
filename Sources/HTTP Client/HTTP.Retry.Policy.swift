extension RFC_9110.Retry {
    /// A finite retry policy for idempotent, replayable exchanges.
    public struct Policy: Sendable {
        public let maximumAttempts: Int
        public let shouldRetry: @Sendable (HTTP.Request.Head, HTTP.Client.Error) -> Bool

        public init(
            maximumAttempts: Int = 3,
            shouldRetry: @escaping @Sendable (HTTP.Request.Head, HTTP.Client.Error) -> Bool = { head, failure in
                guard HTTP.Retry.Policy.idempotent(head.method) else { return false }
                switch failure {
                case .cancelled, .retry: false
                case .pool, .connection: true
                }
            }
        ) {
            precondition(maximumAttempts > 0, "An HTTP retry policy needs at least one attempt.")
            self.maximumAttempts = maximumAttempts
            self.shouldRetry = shouldRetry
        }
    }
}

extension RFC_9110.Retry.Policy {
    /// Whether RFC-defined request semantics permit automatic replay.
    public static func idempotent(_ method: HTTP.Method) -> Bool {
        method == .get || method == .head || method == .put || method == .delete || method == .options || method == .trace
    }
}
