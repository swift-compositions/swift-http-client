public import Client
public import HTTP
public import RFC_9110

extension HTTP {
    public typealias Client<Content, Failure: Swift.Error> =
        Client::Client<
            HTTP.Message.Request<Content>,
            HTTP.Message.Response<Content>,
            Failure
        >
}
