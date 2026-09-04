import Byte
import Client
import Client_Derivation
import Either
import HTTP
import HTTP_Client
import HTTP_Coder
import Tagged
import Tagged_Standard_Library_Integration
import Testing

private func responder() -> HTTP.Interpretation<HTTP.Router.Error> {
    .init(
        HTTP.responder(Counter.self) { call throws(HTTP.Router.Error) in
            switch call {
            case .measure(let application):
                guard application.input.underlying < 5 else {
                    return try .badRequest(Refusal.refused)
                }
                return try .ok(Word(String(repeating: "x", count: application.input.underlying)))

            case .reset:
                return .ok()
            }
        }
    )
}

private func client<Transport: Swift.Error>(
    over interpretation: HTTP.Interpretation<Transport>
) -> Counter.Client<HTTP.Interpretation<Transport>.Error> {
    Counter.Client.client(
        routing: Counter.router,
        replying: Counter.Replies(
            measure: HTTP.reply {
                HTTP.ok(Word.self)
                HTTP.badRequest(Refusal.self)
            },
            reset: HTTP.reply {
                HTTP.ok()
            }
        ),
        over: interpretation
    )
}

@Suite
struct `HTTP.Interpretation Tests` {

    @Test
    func `a client and a server exchange one domain's calls`() async throws {
        let request = try HTTP.request(Counter.self, for: .measure(Limit(3)))
        #expect(request.target == HTTP.Target(unchecked: "/measure"))
        #expect(request.content == bytes("3"))

        let counter = client(over: responder())
        #expect(try await counter.measure(Limit(3)) == Word("xxx"))
    }

    @Test
    func `a refusal comes back as the operation's own failure`() async throws {
        let counter = client(over: responder())
        do throws(Either<HTTP.Interpretation<HTTP.Router.Error>.Error, Refusal>) {
            _ = try await counter.measure(Limit(7))
            Issue.record("expected the refusal")
        } catch {
            #expect(error == .right(.refused))
        }
    }

    @Test
    func `a transport failure stays outside the domain`() async throws {
        let counter = client(
            over: HTTP.Interpretation<Departure>(.init { _ throws(Departure) in throw .unreachable })
        )
        do throws(Either<HTTP.Interpretation<Departure>.Error, Refusal>) {
            _ = try await counter.measure(Limit(1))
            Issue.record("expected the transport failure")
        } catch {
            #expect(error == .left(.transport(.unreachable)))
        }
    }

    @Test
    func `an unexpected status is a coding mismatch`() async throws {
        let counter = client(
            over: HTTP.Interpretation<HTTP.Router.Error>(
                .init { _ throws(HTTP.Router.Error) in HTTP.Router.Response(status: 500) }
            )
        )
        do throws(Either<HTTP.Interpretation<HTTP.Router.Error>.Error, Refusal>) {
            _ = try await counter.measure(Limit(1))
            Issue.record("expected a mismatch")
        } catch {
            #expect(error == .left(.coding(.mismatch)))
        }
    }

    @Test
    func `an infallible operation without content has a client too`() async throws {
        let counter = client(over: responder())
        try await counter.reset()
    }
}
