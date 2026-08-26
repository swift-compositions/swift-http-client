import Byte_Primitive
import Client
import Coder_Primitive
import Either_Primitives
import HTTP
import HTTP_Client
import HTTP_Coder
import Optic_Primitives
import Parser_Primitive
import Parser_Skip_Primitives
import RFC_3986
import Serializer_Primitive
import Testing

private enum Call {
    case echo(String)
}

private enum Refusal: Swift.Error, Equatable {
    case tooMuch
}

private enum Outage: Swift.Error, Equatable {
    case unavailable
}

/// A `[Byte]? <-> String` payload coder for the route fixture's body.
private struct Text: Coder.`Protocol` {

    enum Error: Swift.Error {
        case unreadable
    }

    typealias Input = [Byte]?
    typealias Output = String
    typealias Buffer = [Byte]?
    typealias Failure = Error
    typealias Body = Never

    func parse(_ input: inout [Byte]?) throws(Error) -> String {
        guard
            let bytes = input,
            let text = String(validating: bytes.lazy.map(\.underlying), as: UTF8.self)
        else {
            throw .unreadable
        }
        input = nil
        return text
    }

    func serialize(_ output: String, into buffer: inout [Byte]?) {
        buffer = output.utf8.map(Byte.init)
    }
}

/// A choice-shaped response coder: `.ok` carries the text, `.badRequest`
/// the refusal.
private struct Choice: Coder.`Protocol` {

    typealias Input = HTTP.Response?
    typealias Output = Either<Refusal, String>
    typealias Buffer = HTTP.Response?
    typealias Failure = HTTP.Response.Coder.Error
    typealias Body = Never

    func parse(
        _ input: inout HTTP.Response?
    ) throws(HTTP.Response.Coder.Error) -> Either<Refusal, String> {
        guard let response = input else {
            throw .noMatch
        }
        switch response.status {
        case .badRequest:
            input = nil
            return .left(.tooMuch)
        case .ok:
            guard
                let bytes = response.body,
                let text = String(
                    validating: bytes.lazy.map(\.underlying),
                    as: UTF8.self
                )
            else {
                throw .malformed
            }
            input = nil
            return .right(text)
        default:
            throw .noMatch
        }
    }

    func serialize(
        _ output: Either<Refusal, String>,
        into buffer: inout HTTP.Response?
    ) {
        switch output {
        case .left:
            buffer = .init(status: .badRequest)
        case .right(let text):
            buffer = .init(status: .ok, body: text.utf8.map(Byte.init))
        }
    }
}

/// The success-only shape: the refusal row is `Never`.
private struct Success: Coder.`Protocol` {

    typealias Input = HTTP.Response?
    typealias Output = Either<Swift.Never, String>
    typealias Buffer = HTTP.Response?
    typealias Failure = HTTP.Response.Coder.Error
    typealias Body = Never

    func parse(
        _ input: inout HTTP.Response?
    ) throws(HTTP.Response.Coder.Error) -> Either<Swift.Never, String> {
        guard let response = input, response.status == .ok else {
            throw .noMatch
        }
        guard
            let bytes = response.body,
            let text = String(
                validating: bytes.lazy.map(\.underlying),
                as: UTF8.self
            )
        else {
            throw .malformed
        }
        input = nil
        return .right(text)
    }

    func serialize(
        _ output: Either<Swift.Never, String>,
        into buffer: inout HTTP.Response?
    ) {
        switch output {
        case .right(let text):
            buffer = .init(status: .ok, body: text.utf8.map(Byte.init))
        }
    }
}

private func echoPrism() -> Optic.Prism<Call, String> {
    Optic.Prism(
        embed: Call.echo,
        extract: { call in
            guard case .echo(let text) = call else { return nil }
            return text
        }
    )
}

private func router() -> some Coder.`Protocol`<
    HTTP.Route.Input, Call, HTTP.Route.Input, HTTP.Route.Error
> {
    HTTP.Route.Case(
        echoPrism(),
        body: Parser.Skip.First(
            HTTP.Route.Method(.post),
            Parser.Skip.First(
                HTTP.Route.Path.Literal("echo"),
                HTTP.Route.Body(Text())
            )
        )
    )
}

/// Accepts only `POST /echo` and echoes the payload; anything else is 404,
/// so a mis-printed request surfaces as a coding failure in the tests.
private func echoing() -> HTTP.Client<Swift.Never> {
    .init(
        run: { request in
            guard
                request.method == .post,
                request.path?.segments == ["echo"]
            else {
                return .init(status: .notFound)
            }
            return .init(status: .ok, body: request.body)
        }
    )
}

@Test
func `the arrow prints the call, executes, and parses the outcome`() async throws {
    let echo = HTTP.client(
        router: router(),
        case: echoPrism(),
        response: Choice(),
        transport: echoing()
    )
    #expect(try await echo("Ada") == "Ada")
}

@Test
func `the arrow surfaces a domain refusal in the domain row`() async {
    let refusing = HTTP.client(
        router: router(),
        case: echoPrism(),
        response: Choice(),
        transport: HTTP.Client<Swift.Never>(
            run: { _ in .init(status: .badRequest) }
        )
    )

    do throws(
        Either<
            Either<Swift.Never, Either<HTTP.Route.Error, HTTP.Response.Coder.Error>>,
            Refusal
        >
    ) {
        _ = try await refusing("Ada")
        Issue.record("expected the domain refusal")
    } catch {
        #expect(error == .right(.tooMuch))
    }
}

@Test
func `the arrow keeps transport and coding failures distinguishable`() async {
    let unavailable = HTTP.client(
        router: router(),
        case: echoPrism(),
        response: Choice(),
        transport: HTTP.Client<Outage>(
            run: { _ throws(Outage) in throw .unavailable }
        )
    )
    do throws(
        Either<
            Either<Outage, Either<HTTP.Route.Error, HTTP.Response.Coder.Error>>,
            Refusal
        >
    ) {
        _ = try await unavailable("Ada")
        Issue.record("expected the transport failure")
    } catch {
        #expect(error == .left(.left(.unavailable)))
    }

    let foreign = HTTP.client(
        router: router(),
        case: echoPrism(),
        response: Choice(),
        transport: HTTP.Client<Swift.Never>(
            run: { _ in .init(status: .notFound) }
        )
    )
    do throws(
        Either<
            Either<Swift.Never, Either<HTTP.Route.Error, HTTP.Response.Coder.Error>>,
            Refusal
        >
    ) {
        _ = try await foreign("Ada")
        Issue.record("expected the coding failure")
    } catch {
        #expect(error == .left(.right(.right(.noMatch))))
    }
}

@Test
func `the never overload collapses the impossible domain row`() async throws {
    let collapsed = HTTP.client(
        router: router(),
        case: echoPrism(),
        response: Success(),
        transport: echoing()
    )
    #expect(try await collapsed("Ada") == "Ada")

    let foreign = HTTP.client(
        router: router(),
        case: echoPrism(),
        response: Success(),
        transport: HTTP.Client<Swift.Never>(
            run: { _ in .init(status: .notFound) }
        )
    )
    do throws(
        Either<Swift.Never, Either<HTTP.Route.Error, HTTP.Response.Coder.Error>>
    ) {
        _ = try await foreign("Ada")
        Issue.record("expected the coding failure")
    } catch {
        #expect(error == .right(.right(.noMatch)))
    }
}
