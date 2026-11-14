public import Byte
public import HTTP
public import RFC_9110

extension HTTP.Client {
    public static func inProcess(
        _ answer: @escaping @Sendable (RFC_9110.Message.Request<[Byte]>) async -> RFC_9110.Message.Response<[Byte]>
    ) -> Self {
        Self { request throws(HTTP.Client.Error) in
            await answer(request)
        }
    }
}
