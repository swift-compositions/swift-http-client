public import Client
public import HTTP

extension HTTP {
    public typealias Client<Content, Failure: Swift.Error> =
        Client::Client<
            HTTP.Message.Request<Content>,
            HTTP.Message.Response<Content>,
            Failure
        >
}
