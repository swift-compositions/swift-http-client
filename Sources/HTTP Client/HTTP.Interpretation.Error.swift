public import HTTP
public import HTTP_Router

extension HTTP.Interpretation {

    public enum Error: Swift.Error {

        case transport(Transport)

        case coding(HTTP.Router.Error)
    }
}

extension HTTP.Interpretation.Error: Equatable where Transport: Equatable {}
