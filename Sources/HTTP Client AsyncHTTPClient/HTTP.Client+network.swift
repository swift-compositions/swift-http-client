#if AsyncHTTPClient
    import AsyncHTTPClient
    import Byte
    public import HTTP
    public import HTTP_Client
    import NIOCore
    import NIOHTTP1
    import RFC_9110

    extension HTTP.Client {
        public static func network(
            limit: Int,
            timeout: Duration,
            clock: any Clock<Duration> = ContinuousClock()
        ) -> Self {
            Self { request throws(HTTP.Client.Error) in
                guard let address = request.target.reference else { throw .malformed }
                var sent = HTTPClientRequest(url: address)
                sent.method = HTTPMethod(rawValue: request.method.description)
                for field in request.headers {
                    sent.headers.add(name: field.name.description, value: field.value.description)
                }
                if let content = request.content { sent.body = .bytes(ByteBuffer(bytes: content.map(\.bitPattern))) }
                let deadline = NIODeadline.now() + .nanoseconds(Network.nanoseconds(timeout))
                let outgoing = sent
                do {
                    return try await withThrowingTaskGroup(of: IETF.RFC.`9110`.Message.Response<[Byte]>?.self) { group in
                        group.addTask {
                            let response = try await Network.client.execute(outgoing, deadline: deadline)
                            var body: [Byte] = []
                            for try await chunk in response.body {
                                body.append(
                                    contentsOf: chunk.readableBytesView.prefix(limit + 1 - body.count).map(
                                        Byte.init(bitPattern:)
                                    )
                                )
                                if body.count > limit { break }
                            }
                            var headers = IETF.RFC.`9110`.Message.Headers()
                            for (name, value) in response.headers {
                                headers.append(
                                    IETF.RFC.`9110`.Field(name: .init(unchecked: name), value: .init(unchecked: value))
                                )
                            }
                            return IETF.RFC.`9110`.Message.Response(
                                status: .init(Int(response.status.code)),
                                headers: headers,
                                content: body
                            )
                        }
                        group.addTask {
                            try await clock.sleep(for: timeout)
                            return nil
                        }
                        defer { group.cancelAll() }
                        guard case let response?? = try await group.next() else { throw HTTP.Client.Error.unreachable }
                        return response
                    }
                } catch {
                    throw .unreachable
                }
            }
        }
    }
#endif
