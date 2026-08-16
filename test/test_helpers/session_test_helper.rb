module SessionTestHelper
  # Signs a test-only JWT the same way the Rust service would, using the
  # test-environment keypair (see config/credentials/test.yml.enc) whose public
  # half matches config/store_jwt_public_key.pem. Production Rails code never
  # signs anything — this is test-only tooling to simulate a Rust-issued login.
  def sign_in_as(user)
    payload = {
      sub: user.id.to_s,
      email: user.email_address,
      admin: user.admin?,
      iss: JsonWebToken::ISSUER,
      aud: JsonWebToken::AUDIENCE,
      iat: Time.now.to_i,
      exp: 15.minutes.from_now.to_i
    }

    private_key = OpenSSL::PKey::RSA.new(Rails.application.credentials.jwt_private_key)
    cookies["access_token"] = JWT.encode(payload, private_key, "RS256")
  end

  def sign_out
    cookies.delete("access_token")
  end
end

ActiveSupport.on_load(:action_dispatch_integration_test) do
  include SessionTestHelper
end
