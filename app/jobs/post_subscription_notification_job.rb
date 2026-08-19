require "net/http"
require "json"

# Asks fastandfarapp to email everyone subscribed to a post's updates about a new
# comment. Runs out-of-band (enqueued by PostSubscriptionNotifier) so a slow or
# unreachable fastandfarapp never delays the comment save it's reporting on.
class PostSubscriptionNotificationJob < ApplicationJob
  queue_as :default

  def perform(post_id:, comment_id:, excerpt:, subscriber_emails:, access_token:)
    uri = URI.join(Rails.application.config.x.fastandfarapp_origin, "/api/store/posts/comments/notify")

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    # fastandfarapp resolves the commenting user from this cookie (the same one Rails
    # itself authenticates the request with) rather than Rails forging an identity.
    request["Cookie"] = "access_token=#{access_token}"
    request.body = { post_id: post_id, comment_id: comment_id, excerpt: excerpt, subscriber_emails: subscriber_emails }.to_json

    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 5, read_timeout: 5) do |http|
      http.request(request)
    end
  rescue StandardError => e
    Rails.logger.warn("PostSubscriptionNotificationJob: failed to notify subscribers of post #{post_id} (#{e.class}: #{e.message})")
  end
end
