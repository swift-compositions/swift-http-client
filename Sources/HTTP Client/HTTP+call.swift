public import Client
public import Coder
public import Either
public import HTTP
public import HTTP_Router

extension HTTP {

    public static func call<Domain: HTTP.Routable, Transport: Swift.Error, Reply: Coding, Value, Reason: Swift.Error>(
        _: Domain.Type,
        _ call: consuming Domain.Router.Output,
        reply: Reply,
        over transport: HTTP.Client<Transport>
    ) async throws(Either<HTTP.Failure<Transport>, Reason>) -> Value
    where
        Domain.Router.Output: ~Copyable,
        Reply.Input == HTTP.Router.Response,
        Reply.Buffer == HTTP.Router.Response,
        Reply.Failure == HTTP.Router.Error,
        Reply.Output == Either<Reason, Value>
    {
        let request: HTTP.Router.Request
        do throws(HTTP.Router.Error) {
            request = try HTTP.request(Domain.self, for: call)
        } catch {
            throw .left(.coding(error))
        }
        var response: HTTP.Router.Response
        do throws(Transport) {
            response = try await transport(request)
        } catch {
            throw .left(.transport(error))
        }
        let outcome: Either<Reason, Value>
        do throws(HTTP.Router.Error) {
            outcome = try reply.parse(&response)
        } catch {
            throw .left(.coding(error))
        }
        switch outcome {
        case .left(let reason): throw .right(reason)
        case .right(let value): return value
        }
    }
}
