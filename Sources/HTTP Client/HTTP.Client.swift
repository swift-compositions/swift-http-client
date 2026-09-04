public import Client
public import HTTP
public import HTTP_Router

extension HTTP {

    public typealias Client<Failure: Swift.Error> = Client::Client<
        HTTP.Router.Request,
        HTTP.Router.Response,
        Failure
    >
}
