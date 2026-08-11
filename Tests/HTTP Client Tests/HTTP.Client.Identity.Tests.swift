import HTTP_Client
import Testing

extension RFC_9110.Client {
    @Suite struct IdentityTests {
        @Test
        func `network reaches resolution only through TLS identity`() {
            let _: KeyPath<HTTP.Client.Network, TLS.Configuration> = \.tls
            let _: KeyPath<TLS.Configuration, TLS.Peer.Identity> = \.identity
            _ = \TLS.Peer.Identity.query
        }

        @Test
        func `connection key stores the canonical TLS identity`() {
            let _: KeyPath<HTTP.Client.Connection.Key, TLS.Peer.Identity> = \.identity
        }
    }
}
