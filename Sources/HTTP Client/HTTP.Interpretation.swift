public import HTTP
import HTTP_Router

extension HTTP {

    public struct Interpretation<Transport: Swift.Error> {

        public let transport: HTTP.Client<Transport>

        public init(_ transport: HTTP.Client<Transport>) {
            self.transport = transport
        }
    }
}
