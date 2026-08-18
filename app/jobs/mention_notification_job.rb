require "net/http"
require "json"

# Asks fastandfarapp to email a user @mentioned in a post or comment. Runs out-of-band
# (enqueued by MentionNotifier) so a slow or unreachable fastandfarapp never delays the
# post/comment save it's reporting on.
class MentionNotificationJob < ApplicationJob
  queue_as :default

  def perform(nickname:, post_id:, access_token:, comment_id: nil, excerpt: nil)
    uri = URI.join(Rails.application.config.x.fastandfarapp_origin, "/api/store/mentions")

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    # fastandfarapp resolves the mentioning user from this cookie (the same one Rails
    # itself authenticates the request with) rather than Rails forging an identity.
    request["Cookie"] = "access_token=#{access_token}"
    request.body = { nickname: nickname, post_id: post_id, comment_id: comment_id, excerpt: excerpt }.to_json

    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 5, read_timeout: 5) do |http|
      http.request(request)
    end
  rescue StandardError => e
    Rails.logger.warn("MentionNotificationJob: failed to notify @#{nickname} (#{e.class}: #{e.message})")
  end
end
