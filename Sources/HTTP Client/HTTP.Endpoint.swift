public import Client
public import Either_Primitives
public import HTTP
public import HTTP_Coder
public import Parser_Primitive
import Serializer_Primitive

extension HTTP.Endpoint {

    public func client<TransportFailure: Swift.Error, Output, DomainFailure: Swift.Error>(
        using transport: HTTP.Client<TransportFailure>
    ) -> Client::Client<
        RequestCoder.Output,
        Output,
        Either<Either<TransportFailure, HTTP.Coding.Error>, DomainFailure>
    > where ResponseCoder.Output == Either<DomainFailure, Output> {
        .init(
            run: { input throws(
                Either<Either<TransportFailure, HTTP.Coding.Error>, DomainFailure>
            ) in
                var request: HTTP.Request?

                do throws(HTTP.Coding.Error) {
                    try self.request.serialize(input, into: &request)
                } catch {
                    throw .left(.right(error))
                }

                guard let request else {
                    throw .left(.right(.request))
                }

                let response: HTTP.Response

                do throws(TransportFailure) {
                    response = try await transport(request)
                } catch {
                    throw .left(.left(error))
                }

                var buffered = Optional(response)
                let outcome: Either<DomainFailure, Output>

                do throws(HTTP.Coding.Error) {
                    outcome = try self.response.parse(&buffered)
                } catch {
                    throw .left(.right(error))
                }
                guard case nil = buffered else {
                    throw .left(.right(.response))
                }

                switch outcome {
                case .left(let failure):
                    throw .right(failure)

                case .right(let output):
                    return output
                }
            }
        )
    }

}
