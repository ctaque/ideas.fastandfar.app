module Authentication
  extend ActiveSupport::Concern

  # The Rust service's SSO bridge: mints a fresh access_token and bounces back to
  # return_to when the visitor already has a valid Rust session, otherwise sends
  # them to the login page. Rails has no local login form of its own — identity is
  # entirely owned by fastandfarapp.
  BRIDGE_URL = ENV.fetch("STORE_LOGIN_BRIDGE_URL", "http://localhost:8080/api/store/bridge")

  included do
    before_action :require_authentication
    helper_method :authenticated?, :sso_bridge_url
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private
    def authenticated?
      resume_authentication
    end

    def require_authentication
      resume_authentication || request_authentication
    end

    # Reads and verifies the `access_token` cookie minted by the Rust service. Rails
    # never writes this cookie — it only ever trusts what it can verify with the
    # public key, and defers to Rust for everything else (issuance, revocation).
    def resume_authentication
      Current.user ||= user_from_access_token
    end

    def user_from_access_token
      claims = JsonWebToken.decode(cookies[:access_token])
      return unless claims

      AuthenticatedUser.new(id: claims["sub"].to_i, email_address: claims["email"])
    end

    def request_authentication
      redirect_to sso_bridge_url, allow_other_host: true
    end

    def sso_bridge_url(return_to: request.original_url)
      "#{BRIDGE_URL}?return_to=#{CGI.escape(return_to)}"
    end
end
