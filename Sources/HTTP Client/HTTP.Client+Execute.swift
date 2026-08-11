extension RFC_9110.Client {
    /// Executes one exchange through an exclusive connection lease.
    public func execute(
        _ request: HTTP.Exchange.Request<HTTP.Client.Error>
    ) async throws(HTTP.Client.Error) -> HTTP.Exchange.Response<HTTP.Client.Error> {
        try await execute(request, attempt: 1)
    }
}

extension RFC_9110.Client {
    @usableFromInline
    func execute(
        _ request: HTTP.Exchange.Request<HTTP.Client.Error>,
        attempt: Int
    ) async throws(HTTP.Client.Error) -> HTTP.Exchange.Response<HTTP.Client.Error> {
        guard !Task.isCancelled else { throw .cancelled }

        do throws(Either<Pool.Lifecycle.Error, HTTP.Client.Error>) {
            return try await connections.acquire { connection in
                let result = try await connection.execute(request)
                switch result.reuse {
                case .reusable: .reusable(result.response)
                case .invalid: .invalid(result.response)
                }
            }
        } catch {
            let failure: HTTP.Client.Error
            switch error {
            case .left(let pool): failure = .pool(pool)
            case .right(let connection): failure = connection
            }
            guard retry.shouldRetry(request, failure) else { throw failure }
            guard attempt < retry.maximumAttempts else { throw .retry(.init(attempts: attempt)) }
            return try await execute(request, attempt: attempt + 1)
        }
    }
}
