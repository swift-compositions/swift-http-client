public import Client
public import Coder_Primitive
public import Either_Primitives
public import HTTP
public import HTTP_Router

extension HTTP {
    public static func client<Domain, Response, Content, TransportFailure>(
        _ domain: Domain.Type,
        response: Response,
        transport: HTTP.Client<Content, TransportFailure>
    ) -> Client::Client<
        Domain.Call,
        Domain.Call.Result,
        Either<TransportFailure, Either<HTTP.Router.Error, Response.Failure>>
    >
    where
        Domain: HTTP.Routable,
        Domain.Route.Content == Content,
        Response: Coder.`Protocol`,
        Response.Input == HTTP.Message.Response<Content>?,
        Response.Buffer == HTTP.Message.Response<Content>?,
        Response.Output == Domain.Call.Result,
        TransportFailure: Swift.Error
    {
        .init(
            run: { call throws(
                Either<TransportFailure, Either<HTTP.Router.Error, Response.Failure>>
            ) in
                let request: HTTP.Message.Request<Content>
                do throws(HTTP.Router.Error) {
                    var buffer: HTTP.Message.Request<Content>?
                    try Domain.router.serialize(call, into: &buffer)
                    guard let buffer else { throw .unprintable }
                    request = buffer
                } catch {
                    throw .right(.left(error))
                }

                let received: HTTP.Message.Response<Content>
                do throws(TransportFailure) {
                    received = try await transport(request)
                } catch {
                    throw .left(error)
                }

                do throws(Response.Failure) {
                    var buffer = Optional(received)
                    return try response.parse(&buffer)
                } catch {
                    throw .right(.right(error))
                }
            }
        )
    }
}
