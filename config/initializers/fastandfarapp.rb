# The Rust "fastandfarapp" service's own origin, derived from the same URL already used
# for the SSO bridge (see Authentication::BRIDGE_URL) since it's always the same instance —
# avoids a second env var to keep in sync with it. Used for the @mention nickname search
# (called from the browser) and mention notification (called server-to-server).
bridge_url = ENV.fetch("STORE_LOGIN_BRIDGE_URL", "http://localhost:8080/api/store/bridge")
Rails.application.config.x.fastandfarapp_origin = URI.join(bridge_url, "/").to_s.chomp("/")
