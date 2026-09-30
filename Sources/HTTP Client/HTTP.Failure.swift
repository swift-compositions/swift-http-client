public import HTTP
public import HTTP_Router

extension HTTP {

    public enum Failure<Transport: Swift.Error>: Swift.Error {

        case transport(Transport)

        case coding(HTTP.Router.Error)
    }
}

extension HTTP.Failure: Equatable where Transport: Equatable {}
