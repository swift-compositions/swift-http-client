import Client
import HTTP
import HTTP_Client
import Testing

@Test
func `transport preserves content`() async throws {
    let transport = HTTP.Client<String, Never>(
        run: { request in
            .init(status: .ok, content: request.content)
        }
    )
    let request = HTTP.Message.Request(
        method: .post,
        target: .resource(.init(unchecked: "/")),
        content: "value"
    )
    #expect(try await transport(request).content == "value")
}
