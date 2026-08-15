# The identity of the currently signed-in visitor, resolved from the claims of a
# Rust-issued JWT. Not an ActiveRecord model: Rails has no local users table, so
# this only ever exists for the duration of a request and is never persisted.
AuthenticatedUser = Data.define(:id, :email_address)
