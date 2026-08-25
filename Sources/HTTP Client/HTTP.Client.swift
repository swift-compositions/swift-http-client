public import Client
public import HTTP

extension HTTP {

    public typealias Client<Failure: Swift.Error> =
        Client::Client<HTTP.Request, HTTP.Response, Failure>
}
