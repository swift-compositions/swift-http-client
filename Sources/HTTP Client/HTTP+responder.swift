public import Client
public import HTTP
public import HTTP_Coder

extension HTTP {

    public static func responder<Domain: HTTP.Routable>(
        _: Domain.Type,
        response: @escaping (consuming Domain.Router.Output) async throws(HTTP.Router.Error) -> HTTP.Router.Response
    ) -> HTTP.Client<HTTP.Router.Error>
    where Domain.Router.Output: ~Copyable {
        .init(
            run: { request throws(HTTP.Router.Error) in
                try await response(HTTP.route(Domain.self, request))
            }
        )
    }
}
