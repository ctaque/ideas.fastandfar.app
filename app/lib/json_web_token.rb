# Verifies RS256 JWTs issued by the Rust "fastandfarapp" service in the shared
# `access_token` cookie. Rails holds only the public key: it can read who is
# authenticated but can never mint a token itself — identity is owned by Rust.
class JsonWebToken
  ALGORITHM = "RS256"
  ISSUER = "fastandfar-rust"
  AUDIENCE = "store-rails"
  PUBLIC_KEY_PATH = Rails.root.join("config/store_jwt_public_key.pem")

  class << self
    def decode(token)
      return if token.blank?

      payload, = JWT.decode(
        token, public_key, true,
        algorithm: ALGORITHM, iss: ISSUER, verify_iss: true, aud: AUDIENCE, verify_aud: true
      )
      payload
    rescue JWT::DecodeError
      nil
    end

    private
      def public_key
        @public_key ||= OpenSSL::PKey::RSA.new(public_key_pem)
      end

      def public_key_pem
        ENV["STORE_JWT_PUBLIC_KEY"].presence || PUBLIC_KEY_PATH.read
      end
  end
end
