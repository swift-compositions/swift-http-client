import Byte
import HTTP
import HTTP_Client
import HTTP_Client_Fetch
import RFC_9110
import Testing

@Suite struct `HTTP.Client` {
    @Test func `an in-process client hands the request to the answer and returns its response`() async throws {
        let client = HTTP.Client.inProcess { request in
            RFC_9110.Message.Response(status: 200, content: request.content.map { Array($0.reversed()) })
        }
        let response = try await client.send(
            RFC_9110.Message.Request(
                method: .post,
                target: RFC_9110.Target(unchecked: "/echo"),
                content: Array("abc".utf8).map { Byte(bitPattern: $0) }
            )
        )
        #expect(response.status.code == 200)
        #expect(response.content.map { String(decoding: $0.map { $0.bitPattern }, as: UTF8.self) } == "cba")
    }

    @Test func `a request frame is the method, the target, one line per field, a blank line, then the body`() throws {
        let request = RFC_9110.Message.Request<[Byte]>(
            method: .post,
            target: RFC_9110.Target(unchecked: "/law"),
            headers: RFC_9110.Message.Headers([try RFC_9110.Field(name: "Content-Type", value: "text/plain")]),
            content: Array("x=1".utf8).map { Byte(bitPattern: $0) }
        )
        let frame = String(decoding: HTTP.Client.Fetch.Frame.request(request), as: UTF8.self)
        #expect(frame.hasPrefix("POST\n/law\n"))
        #expect(frame.hasSuffix(": text/plain\n\nx=1"))
    }

    @Test func `a response frame is the status, one line per field, a blank line, then the body`() throws {
        let frame = Array("201\ncontent-type: text/plain\n\nhello\nworld".utf8)
        let response = try HTTP.Client.Fetch.Frame.response(frame)
        #expect(response.status.code == 201)
        #expect(response.headers.count == 1)
        #expect(response.content.map { String(decoding: $0.map { $0.bitPattern }, as: UTF8.self) } == "hello\nworld")
    }

    @Test func `a response frame without a blank line or a status is malformed`() {
        #expect(throws: HTTP.Client.Error.malformed) { try HTTP.Client.Fetch.Frame.response(Array("200\n".utf8)) }
        #expect(throws: HTTP.Client.Error.malformed) { try HTTP.Client.Fetch.Frame.response(Array("ok\n\n".utf8)) }
    }

    @Test func `a response frame with no body has no content`() throws {
        #expect(try HTTP.Client.Fetch.Frame.response(Array("204\n\n".utf8)).content == nil)
    }
}
