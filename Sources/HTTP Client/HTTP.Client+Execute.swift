extension RFC_9110.Client {
    /// Executes one exchange through an exclusively checked-out connection.
    public func execute(
        _ request: consuming HTTP.Exchange.Request<HTTP.Client.Error>
    ) async throws(HTTP.Client.Error) -> sending HTTP.Exchange.Response<HTTP.Client.Error> {
        let head = request.head
        switch consume request.body {
        case .none:
            return try await execute(head: head, attempt: 1)
        case .bytes(let bytes):
            return try await executeOnce(.init(head: head, body: .bytes(bytes)))
        case .stream(let stream):
            return try await executeOnce(.init(head: head, body: .stream(stream)))
        }
    }
}

extension RFC_9110.Client {
    @usableFromInline
    func execute(
        head: HTTP.Request.Head,
        attempt: Int
    ) async throws(HTTP.Client.Error) -> sending HTTP.Exchange.Response<HTTP.Client.Error> {
        guard !Task.isCancelled else { throw .cancelled }

        do throws(HTTP.Client.Error) {
            return try await executeOnce(.init(head: head))
        } catch let failure {
            guard retry.shouldRetry(head, failure) else { throw failure }
            guard attempt < retry.maximumAttempts else { throw .retry(.init(attempts: attempt)) }
            return try await execute(head: head, attempt: attempt + 1)
        }
    }

    @usableFromInline
    func executeOnce(
        _ request: consuming HTTP.Exchange.Request<HTTP.Client.Error>
    ) async throws(HTTP.Client.Error) -> sending HTTP.Exchange.Response<HTTP.Client.Error> {
        let handle: Pool.Bounded<Connection>.Handle
        do throws(Pool.Lifecycle.Error) {
            handle = try await connections.checkout()
        } catch {
            throw .pool(error)
        }

        do throws(HTTP.Client.Error) {
            let result = try await handle.resource.execute(consume request)
            switch consume result {
            case .reusable(let response):
                return await handle.resolve(.reusable(response))
            case .invalid(let response):
                return await handle.resolve(.invalid(response))
            }
        } catch {
            let failure = await handle.resolve(.invalid(error))
            throw failure
        }
    }
}
