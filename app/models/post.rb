class Post < ApplicationRecord
  # The posts table has a real "type" column for Idea/Feature/Bug, not
  # Rails single-table inheritance, so disable the STI discriminator.
  self.inheritance_column = :_type_disabled

  has_many :comments, dependent: :destroy
  has_many :votes, dependent: :destroy

  enum :status, {
    open: "open",
    planned: "planned",
    in_progress: "in_progress",
    completed: "completed",
    closed: "closed"
  }, validate: true

  enum :type, {
    idea: "idea",
    feature: "feature",
    bug: "bug"
  }, validate: true

  validates :user_id, :user_email, presence: true
  validate :not_flagged_by_moderation, if: -> { title.present? || content.present? }

  def score
    votes.sum(&:value)
  end

  def vote_by(user)
    votes.find { |vote| vote.user_id == user.id }
  end

  private
    def not_flagged_by_moderation
      result = PostModerator.call(title, content)
      errors.add(:base, "was flagged as #{result.category} and can't be posted") if result.flagged
    end
end
