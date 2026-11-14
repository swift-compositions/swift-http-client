public import HTTP

extension HTTP.Client {
    public enum Error: Swift.Error, Sendable, Equatable {
        case unreachable
        case malformed
    }
}
