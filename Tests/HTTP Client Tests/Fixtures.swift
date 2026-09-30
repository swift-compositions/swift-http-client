public import Byte
import Coder
import Client
import Client_Macro
import Either
import HTTP
import HTTP_Client
import HTTP_Reply
import HTTP_Router
import Operation
import Optic
import Parser
import RFC_3986
import RFC_9110
import Serializer
import Interface_Macro
public import Tagged

func bytes(_ text: String) -> [Byte] {
    text.utf8.map(Byte.init(bitPattern:))
}

enum Text {}

typealias Word = Tagged<Text, String>

enum Size {}

typealias Limit = Tagged<Size, Int>

extension Tagged: @retroactive LosslessStringConvertible where Underlying: LosslessStringConvertible {
    public init?(_ description: String) {
        guard let underlying = Underlying(description) else { return nil }
        self.init(underlying)
    }
}

enum Refusal: Swift.Error, Equatable {

    case refused

    struct Coder: Coding {
        var body: some Coding<ArraySlice<Byte>, Refusal, [Byte], Swift.String.Coder.Error> {
            return Swift.String.Coder().map(
                to: { _ in Refusal.refused }, from: { _ in "refused" }
            )
        }
    }
}

@Interface
struct Counter: Counter.Interface {

    @Client
    protocol Interface {
        func measure(_ limit: Limit) async throws(Refusal) -> Word
        func reset() async
    }
}

extension Counter: HTTP.Routable {

    static var router: some HTTP.Router.`Protocol`<Call> {
        Coder::Case(Call.cases.measure.prism, Call.cases.measure.fold, absent: .mismatch) {
            .post
            HTTP.Target(unchecked: "/measure")
            HTTP.Content(Swift.String.Coder.Lossless<Limit>().map(to: { Counter.Measure.Input($0) }, from: { $0.limit }))
        }
        Coder::Case(Call.cases.reset.prism, Call.cases.reset.fold, absent: .mismatch) {
            .post
            HTTP.Target(unchecked: "/reset").map(to: { _ in Counter.Reset.Input() }, from: { _ in () })
        }
    }
}

extension Counter {

    static var measureReply: some Coding<HTTP.Router.Response, Either<Refusal, Word>, HTTP.Router.Response, HTTP.Router.Error> {
        HTTP.reply {
            HTTP.ok(Swift.String.Coder.Lossless<Word>())
            HTTP.badRequest(Refusal.Coder())
        }
    }

    static var resetReply: some Coding<HTTP.Router.Response, Either<Never, Void>, HTTP.Router.Response, HTTP.Router.Error> {
        HTTP.reply {
            HTTP.ok()
        }
    }
}

enum Departure: Swift.Error, Equatable {
    case unreachable
}
