extension RFC_9110 {
    /// The terminal disposition of a leased connection after one exchange.
    public enum ConnectionReuse: Sendable, Equatable {
        /// Return the resource to the lease coordinator.
        case reusable
        /// Destroy the resource; no later exchange may observe it.
        case invalid
    }
}
