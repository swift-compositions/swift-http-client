public import Byte
public import HTTP
public import RFC_9110

extension HTTP {
    public struct Client: Sendable {
        public let send:
            @Sendable (RFC_9110.Message.Request<[Byte]>) async throws(HTTP.Client.Error) -> RFC_9110.Message.Response<
                [Byte]
            >

        public init(
            send: @escaping @Sendable (RFC_9110.Message.Request<[Byte]>) async throws(HTTP.Client.Error) -> RFC_9110
                .Message.Response<[Byte]>
        ) {
            self.send = send
        }
    }
}
