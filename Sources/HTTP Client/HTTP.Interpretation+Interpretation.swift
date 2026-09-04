public import Client_Derivation
public import HTTP
public import HTTP_Router

extension HTTP.Interpretation: Client_Derivation::Interpretation {

    public typealias External = HTTP.Interpretation<Transport>.Error

    public typealias Routing = HTTP.Router.Error

    public typealias Message = HTTP.Router.Request

    public typealias Reply = HTTP.Router.Response

    public var blank: HTTP.Router.Request {
        .blank
    }

    public func external(_ failure: HTTP.Router.Error) -> HTTP.Interpretation<Transport>.Error {
        .coding(failure)
    }

    public func send(
        _ message: HTTP.Router.Request
    ) async throws(HTTP.Interpretation<Transport>.Error) -> HTTP.Router.Response {
        do throws(Transport) {
            return try await transport(message)
        } catch {
            throw .transport(error)
        }
    }
}
