# Asks fastandfarapp to email everyone subscribed to a post's updates whenever a new
# comment is added, via PostSubscriptionNotificationJob. Subscriptions live entirely in
# this app's database, so unlike MentionNotifier there's no lookup to defer to
# fastandfarapp — it's handed the subscriber emails directly.
class PostSubscriptionNotifier
  EXCERPT_LENGTH = 280

  class << self
    def notify(comment, access_token:)
      return if access_token.blank?

      post = comment.post
      subscriber_emails = post.subscriptions.where.not(user_id: comment.user_id).pluck(:user_email)
      return if subscriber_emails.empty?

      PostSubscriptionNotificationJob.perform_later(
        post_id: post.id,
        comment_id: comment.id,
        excerpt: comment.comment.to_plain_text.truncate(EXCERPT_LENGTH),
        subscriber_emails: subscriber_emails,
        access_token: access_token
      )
    end
  end
end
