import Byte
import Byte_Coder
import Byte_Standard_Library_Integration
import Client
import Client_Derivation
import Coder
import Either
import HTTP
import HTTP_Client
import HTTP_Coder
import Operation
import Operation_Coder
import Optic
import Optic_Coder
import Parser
import Parser_Skip
import RFC_3986
import Serializer
import Signature_Derivation
import String_Coder
import Tagged
import Tagged_Coder
import Tagged_Standard_Library_Integration

func bytes(_ text: String) -> [Byte] {
    text.utf8.map(Byte.init(bitPattern:))
}

enum Text {}

typealias Word = Tagged<Text, String>

enum Size {}

typealias Limit = Tagged<Size, Int>

enum Refusal: Swift.Error, Equatable, Coder.Codable {

    case refused

    static var coder: Coder.Map<Swift.String.Coder, Refusal> {
        Swift.String.coder.map(to: { _ in Refusal.refused }, from: { _ in "refused" })
    }
}

enum Counter {
    @Signature
    @Client
    protocol `Protocol` {
        func measure(_ limit: Limit) async throws(Refusal) -> Word
        func reset() async
    }
}

extension Counter: HTTP.Routable {

    static var router: some HTTP.Router.`Protocol`<Call> {
        Call.Router(
            absent: .mismatch,
            measure: HTTP.route {
                .post
                HTTP.Target(unchecked: "/measure")
                HTTP.Content(Limit.self)
            },
            reset: HTTP.route {
                .post
                HTTP.Target(unchecked: "/reset")
            }
        )
    }
}

enum Departure: Swift.Error, Equatable {

    case unreachable
}
