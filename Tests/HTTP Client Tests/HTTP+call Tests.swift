import Byte
import Client
import Either
import HTTP
import HTTP_Client
import HTTP_Reply
import HTTP_Router
import Tagged
import Operation
import RFC_9110
import Serializer
import Testing

private func responder() -> HTTP.Client<HTTP.Router.Error> {
    HTTP.responder(Counter.self) { call throws(HTTP.Router.Error) in
        var response = HTTP.Router.Response.blank
        switch call {
        case .measure(let application):
            let limit = application.input.limit.underlying
            try Counter.measureReply.serialize(
                limit < 5 ? .right(Word(String(repeating: "x", count: limit))) : .left(.refused),
                into: &response
            )

        case .reset:
            try Counter.resetReply.serialize(.right(()), into: &response)
        }
        return response
    }
}

private func client<Transport: Swift.Error>(
    over transport: HTTP.Client<Transport>
) -> Counter.Client<HTTP.Failure<Transport>> {
    Counter.Client<HTTP.Failure<Transport>>(
        measure: { input throws(Either<HTTP.Failure<Transport>, Refusal>) in
            try await HTTP.call(Counter.self, Counter.Measure.call(input), reply: Counter.measureReply, over: transport)
        },
        reset: { input throws(Either<HTTP.Failure<Transport>, Never>) in
            try await HTTP.call(Counter.self, Counter.Reset.call(input), reply: Counter.resetReply, over: transport)
        }
    )
}

@Suite
struct `HTTP.call Tests` {

    @Test
    func `a client and a server exchange one domain's calls`() async throws {
        let request = try HTTP.request(Counter.self, for: Counter.Measure.call(.init(Limit(3))))
        #expect(request.target == HTTP.Target(unchecked: "/measure"))
        #expect(request.content == bytes("3"))

        let counter = client(over: responder())
        #expect(try await counter.measure(.init(Limit(3))) == Word("xxx"))
    }

    @Test
    func `a refusal comes back as the operation's own failure`() async throws {
        let counter = client(over: responder())
        do throws(Either<HTTP.Failure<HTTP.Router.Error>, Refusal>) {
            _ = try await counter.measure(.init(Limit(7)))
            Issue.record("expected the refusal")
        } catch {
            #expect(error == .right(.refused))
        }
    }

    @Test
    func `a transport failure stays outside the domain`() async throws {
        let counter = client(over: HTTP.Client<Departure>(run: { _ throws(Departure) in throw .unreachable }))
        do throws(Either<HTTP.Failure<Departure>, Refusal>) {
            _ = try await counter.measure(.init(Limit(1)))
            Issue.record("expected the transport failure")
        } catch {
            #expect(error == .left(.transport(.unreachable)))
        }
    }

    @Test
    func `an unexpected status is a coding mismatch`() async throws {
        let counter = client(
            over: HTTP.Client<HTTP.Router.Error>(run: { _ throws(HTTP.Router.Error) in HTTP.Router.Response(status: 500) })
        )
        do throws(Either<HTTP.Failure<HTTP.Router.Error>, Refusal>) {
            _ = try await counter.measure(.init(Limit(1)))
            Issue.record("expected a mismatch")
        } catch {
            #expect(error == .left(.coding(.mismatch)))
        }
    }

    @Test
    func `an infallible operation without content has a client too`() async throws {
        let counter = client(over: responder())
        try await counter.reset(.init())
    }
}
