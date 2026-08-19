# The identity of the currently signed-in visitor, resolved from the claims of a
# Rust-issued JWT. Not an ActiveRecord model: Rails has no local users table, so
# this only ever exists for the duration of a request and is never persisted.
AuthenticatedUser = Data.define(:id, :email_address, :nickname, :avatar_url, :admin) do
  def initialize(nickname: nil, avatar_url: nil, **rest)
    super(nickname: nickname, avatar_url: avatar_url, **rest)
  end

  def admin?
    admin
  end

  def display_name
    nickname.presence || email_address
  end
end
