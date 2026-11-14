#if arch(wasm32)
    public import Byte
    public import HTTP
    public import HTTP_Client
    public import RFC_9110

    extension HTTP.Client {
        public static var fetch: Self {
            Self { request throws(HTTP.Client.Error) in
                let frame = HTTP.Client.Fetch.Frame.request(request)
                let bytes = await withUnsafeContinuation { (continuation: UnsafeContinuation<[UInt8]?, Never>) in
                    let id = HTTP.Client.Fetch.Pending.add(continuation)
                    frame.withUnsafeBytes { buffer in
                        unsafe _send(id, buffer.baseAddress, Int32(buffer.count))
                    }
                }
                guard let bytes else { throw .unreachable }
                return try HTTP.Client.Fetch.Frame.response(bytes)
            }
        }
    }

    extension HTTP.Client.Fetch {
        enum Pending {
            nonisolated(unsafe) static var next: Int32 = 0
            nonisolated(unsafe) static var waiting: [Int32: UnsafeContinuation<[UInt8]?, Never>] = [:]

            static func add(_ continuation: UnsafeContinuation<[UInt8]?, Never>) -> Int32 {
                next += 1
                unsafe waiting[next] = continuation
                return next
            }

            static func complete(_ id: Int32, _ count: Int32) {
                guard let continuation = unsafe waiting.removeValue(forKey: id) else { return }
                guard count >= 0 else {
                    continuation.resume(returning: nil)
                    return
                }
                var bytes = [UInt8](repeating: 0, count: Int(count))
                bytes.withUnsafeMutableBytes { buffer in
                    _ = unsafe _take(id, buffer.baseAddress, count)
                }
                continuation.resume(returning: bytes)
            }
        }
    }

    @_extern(wasm, module: "http_client_fetch", name: "send")
    private func _send(_ id: Int32, _ pointer: UnsafeRawPointer?, _ count: Int32)

    @_extern(wasm, module: "http_client_fetch", name: "take")
    private func _take(_ id: Int32, _ pointer: UnsafeMutableRawPointer?, _ capacity: Int32) -> Int32

    @_expose(wasm, "http_client_fetch_complete")
    public func _complete(_ id: Int32, _ count: Int32) {
        HTTP.Client.Fetch.Pending.complete(id, count)
    }
#endif
