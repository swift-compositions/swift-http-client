public import Byte
public import HTTP
public import RFC_9110

extension HTTP.Client {
    public static func inProcess(
        _ answer: @escaping @Sendable (IETF.RFC.`9110`.Message.Request<[Byte]>) async -> IETF.RFC.`9110`.Message.Response<[Byte]>
    ) -> Self {
        Self { request throws(HTTP.Client.Error) in
            await answer(request)
        }
    }
}
