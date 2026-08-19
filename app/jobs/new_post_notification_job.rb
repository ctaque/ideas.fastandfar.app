require "net/http"
require "json"

# Notifies the FastAndFar team by email (via fastandfarapp) whenever a new post is
# created. Runs out-of-band (enqueued right after the post is saved) so a slow or
# unreachable fastandfarapp never delays the post save it's reporting on.
class NewPostNotificationJob < ApplicationJob
  queue_as :default

  def perform(post_id:, title:, excerpt:, access_token:)
    uri = URI.join(Rails.application.config.x.fastandfarapp_origin, "/api/store/posts/notify")

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    # fastandfarapp resolves the posting user from this cookie (the same one Rails
    # itself authenticates the request with) rather than Rails forging an identity.
    request["Cookie"] = "access_token=#{access_token}"
    request.body = { post_id: post_id, title: title, excerpt: excerpt }.to_json

    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 5, read_timeout: 5) do |http|
      http.request(request)
    end
  rescue StandardError => e
    Rails.logger.warn("NewPostNotificationJob: failed to notify about post #{post_id} (#{e.class}: #{e.message})")
  end
end
