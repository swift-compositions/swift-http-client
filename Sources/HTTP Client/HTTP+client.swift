public import Client
public import Either
public import HTTP
public import HTTP_Coder
public import HTTP_Router
import Parser
public import RFC_9110
import Serializer

extension HTTP {
    public static func client<Route, Response, Content, Failure>(
        route: Route,
        response: Response,
        transport: HTTP.Client<Content, Failure>
    ) -> Client::Client<
        Route.Operation.Input,
        Route.Operation.Output,
        Either<
            Either<Failure, HTTP.Coder.Error>,
            Route.Operation.Failure
        >
    >
    where
        Route: HTTP.Routing,
        Response: HTTP.Coding,
        Route.Domain == Response.Domain,
        Route.Operation == Response.Operation,
        Route.Content == Content,
        Response.Content == Content,
        Failure: Swift.Error
    {
        .init(
            run: { input throws(
                Either<
                    Either<Failure, HTTP.Coder.Error>,
                    Route.Operation.Failure
                >
            ) in
                let request: HTTP.Message.Request<Content>
                do throws(HTTP.Coder.Error) {
                    var buffer: HTTP.Message.Request<Content>?
                    try route.serialize(input, into: &buffer)
                    guard let buffer else { throw .unprintable }
                    request = buffer
                } catch {
                    throw .left(.right(error))
                }

                let received: HTTP.Message.Response<Content>
                do throws(Failure) {
                    received = try await transport(request)
                } catch {
                    throw .left(.left(error))
                }

                let result: Swift.Result<
                    Route.Operation.Output,
                    Route.Operation.Failure
                >
                do throws(HTTP.Coder.Error) {
                    var buffer = Optional(received)
                    result = try response.parse(&buffer)
                    guard case nil = buffer else {
                        throw .malformed
                    }
                } catch {
                    throw .left(.right(error))
                }

                switch result {
                case .success(let output):
                    return output
                case .failure(let refusal):
                    throw .right(refusal)
                }
            }
        )
    }
}
