# Scans a rich text body for "@nickname" mentions and asks fastandfarapp (which owns the
# users table) to email each one, via MentionNotificationJob. fastandfarapp is the source
# of truth for whether a nickname exists, so Rails doesn't validate mentions itself — it
# just forwards every @token that looks like a nickname and lets the unknown ones no-op.
class MentionNotifier
  # Requires a preceding start-of-string/whitespace so "bob@example.com" pasted into a
  # post doesn't get parsed as a mention of "@example".
  MENTION_PATTERN = /(?:^|\s)@([a-zA-Z0-9_-]{1,30})/
  EXCERPT_LENGTH = 280

  class << self
    def notify(rich_text, post_id:, access_token:, comment_id: nil)
      return if access_token.blank?

      plain_text = rich_text.to_plain_text
      nicknames = plain_text.scan(MENTION_PATTERN).flatten.uniq
      return if nicknames.empty?

      excerpt = plain_text.truncate(EXCERPT_LENGTH)

      nicknames.each do |nickname|
        MentionNotificationJob.perform_later(
          nickname: nickname,
          post_id: post_id,
          comment_id: comment_id,
          excerpt: excerpt,
          access_token: access_token
        )
      end
    end
  end
end
