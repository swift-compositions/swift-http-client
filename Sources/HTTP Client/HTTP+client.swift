public import Client
public import Coder_Primitive
public import Either_Primitives
public import HTTP
public import HTTP_Coder
public import Optic_Primitives
public import Parser_Primitive
public import Serializer_Primitive

extension HTTP {

    /// The generic remote arrow: print the call through the router, execute
    /// over the transport, parse through the operation's response coder.
    ///
    /// The failure row keeps the ruled association —
    /// `(transport + coding) + domain refusal` — with the coding channel
    /// the plain `Either` of the route and response taxonomies.
    public static func client<
        Router, Call, Input, Response, TransportFailure, Refusal, Output
    >(
        router: Router,
        case prism: Optic.Prism<Call, Input>,
        response: Response,
        transport: HTTP.Client<TransportFailure>
    ) -> Client::Client<
        Input,
        Output,
        Either<
            Either<TransportFailure, Either<HTTP.Route.Error, HTTP.Response.Coder.Error>>,
            Refusal
        >
    >
    where
        Router: Coder.`Protocol`,
        Router.Input == HTTP.Route.Input,
        Router.Output == Call,
        Router.Buffer == HTTP.Route.Input,
        Router.Failure == HTTP.Route.Error,
        Response: Coder.`Protocol`,
        Response.Input == HTTP.Response?,
        Response.Buffer == HTTP.Response?,
        Response.Output == Either<Refusal, Output>,
        Response.Failure == HTTP.Response.Coder.Error,
        TransportFailure: Swift.Error,
        Refusal: Swift.Error
    {
        .init(
            run: { input throws(
                Either<
                    Either<
                        TransportFailure,
                        Either<HTTP.Route.Error, HTTP.Response.Coder.Error>
                    >,
                    Refusal
                >
            ) in
                let request: HTTP.Request
                do throws(HTTP.Route.Error) {
                    var record = HTTP.Route.Input()
                    try router.serialize(prism.embed(input), into: &record)
                    request = try record.request()
                } catch {
                    throw .left(.right(.left(error)))
                }

                let received: HTTP.Response
                do throws(TransportFailure) {
                    received = try await transport(request)
                } catch {
                    throw .left(.left(error))
                }

                let outcome: Either<Refusal, Output>
                do throws(HTTP.Response.Coder.Error) {
                    var buffered = Optional(received)
                    outcome = try response.parse(&buffered)
                    guard case nil = buffered else {
                        throw .malformed
                    }
                } catch {
                    throw .left(.right(.right(error)))
                }

                switch outcome {
                case .left(let refusal):
                    throw .right(refusal)
                case .right(let output):
                    return output
                }
            }
        )
    }

    /// The `Refusal == Never` overload pre-collapses the impossible domain
    /// row, so an infallible operation's arrow carries only the transport
    /// and coding channels.
    public static func client<
        Router, Call, Input, Response, TransportFailure, Output
    >(
        router: Router,
        case prism: Optic.Prism<Call, Input>,
        response: Response,
        transport: HTTP.Client<TransportFailure>
    ) -> Client::Client<
        Input,
        Output,
        Either<TransportFailure, Either<HTTP.Route.Error, HTTP.Response.Coder.Error>>
    >
    where
        Router: Coder.`Protocol`,
        Router.Input == HTTP.Route.Input,
        Router.Output == Call,
        Router.Buffer == HTTP.Route.Input,
        Router.Failure == HTTP.Route.Error,
        Response: Coder.`Protocol`,
        Response.Input == HTTP.Response?,
        Response.Buffer == HTTP.Response?,
        Response.Output == Either<Swift.Never, Output>,
        Response.Failure == HTTP.Response.Coder.Error,
        TransportFailure: Swift.Error
    {
        .init(
            run: { input throws(
                Either<
                    TransportFailure,
                    Either<HTTP.Route.Error, HTTP.Response.Coder.Error>
                >
            ) in
                let request: HTTP.Request
                do throws(HTTP.Route.Error) {
                    var record = HTTP.Route.Input()
                    try router.serialize(prism.embed(input), into: &record)
                    request = try record.request()
                } catch {
                    throw .right(.left(error))
                }

                let received: HTTP.Response
                do throws(TransportFailure) {
                    received = try await transport(request)
                } catch {
                    throw .left(error)
                }

                let outcome: Either<Swift.Never, Output>
                do throws(HTTP.Response.Coder.Error) {
                    var buffered = Optional(received)
                    outcome = try response.parse(&buffered)
                    guard case nil = buffered else {
                        throw .malformed
                    }
                } catch {
                    throw .right(.right(error))
                }

                switch outcome {
                case .right(let output):
                    return output
                }
            }
        )
    }
}
