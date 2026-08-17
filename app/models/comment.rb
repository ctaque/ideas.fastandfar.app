class Comment < ApplicationRecord
  belongs_to :post
  has_rich_text :comment

  validates :user_id, :user_email, presence: true
  validate :not_flagged_by_moderation, if: -> { comment? }

  private
    def not_flagged_by_moderation
      result = CommentModerator.call(comment.to_plain_text)
      errors.add(:comment, "was flagged as #{result.category} and can't be posted") if result.flagged
    end
end
