import HTTP_Client
import Testing

extension RFC_9110.Retry.Policy {
    @Suite struct Test {
        @Suite struct Unit {}
    }
}

extension RFC_9110.Retry.Policy.Test.Unit {
    @Test
    func `defaults to a bounded attempt count`() {
        #expect(HTTP.Retry.Policy().maximumAttempts == 3)
    }

    @Test
    func `retry policy observes only replayable request head state`() {
        let policy = HTTP.Retry.Policy()
        let _: @Sendable (HTTP.Request.Head, HTTP.Client.Error) -> Bool = policy.shouldRetry
    }

    @Test
    func `recognizes idempotent request methods`() {
        #expect(HTTP.Retry.Policy.idempotent(.get))
        #expect(!HTTP.Retry.Policy.idempotent(.post))
    }
}
