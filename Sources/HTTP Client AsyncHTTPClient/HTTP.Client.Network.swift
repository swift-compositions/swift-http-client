#if AsyncHTTPClient
    import AsyncHTTPClient
    import HTTP
    import HTTP_Client
    import NIOCore

    extension HTTP.Client {
        enum Network {}
    }

    extension HTTP.Client.Network {
        static let client = HTTPClient(
            eventLoopGroupProvider: .singleton,
            configuration: HTTPClient.Configuration(
                redirectConfiguration: .disallow,
                timeout: .init(connect: .seconds(5), read: .seconds(10))
            )
        )

        static func nanoseconds(_ duration: Duration) -> Int64 {
            duration.components.seconds * 1_000_000_000 + duration.components.attoseconds / 1_000_000_000
        }
    }
#endif
