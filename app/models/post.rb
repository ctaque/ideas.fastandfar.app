class Post < ApplicationRecord
  # The posts table has a real "type" column for Idea/Feature/Bug, not
  # Rails single-table inheritance, so disable the STI discriminator.
  self.inheritance_column = :_type_disabled

  Participant = Data.define(:user_id, :user_email, :user_nickname, :user_avatar_url)

  has_many :comments, dependent: :destroy
  has_many :votes, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_rich_text :content

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
  validate :not_flagged_by_moderation, if: -> { title.present? || content? }

  def score
    votes.sum(&:value)
  end

  def vote_by(user)
    votes.find { |vote| vote.user_id == user.id }
  end

  def subscribed_by?(user)
    subscriptions.any? { |subscription| subscription.user_id == user.id }
  end

  # The post's author, everyone who commented, and everyone subscribed to
  # updates, deduped by user, in order of first appearance. Later records
  # (e.g. a comment made after the post) fill in a nickname/avatar the
  # earlier one didn't have, without ever overwriting one with a blank.
  def participants
    entries = {}

    add_participant = lambda do |user_id, user_email, user_nickname, user_avatar_url|
      existing = entries[user_id]
      entries[user_id] = Participant.new(
        user_id: user_id,
        user_email: user_email,
        user_nickname: user_nickname.presence || existing&.user_nickname,
        user_avatar_url: user_avatar_url.presence || existing&.user_avatar_url
      )
    end

    add_participant.call(user_id, user_email, user_nickname, user_avatar_url)
    comments.order(:created_at).each { |comment| add_participant.call(comment.user_id, comment.user_email, comment.user_nickname, comment.user_avatar_url) }
    subscriptions.each { |subscription| add_participant.call(subscription.user_id, subscription.user_email, subscription.user_nickname, subscription.user_avatar_url) }

    entries.values
  end

  # Nicknames of everyone already part of this post's conversation, for seeding the
  # "@mention" autocomplete with people relevant to this post even when the composer
  # doesn't follow them (the fastandfarapp-backed autocomplete only knows about follow
  # connections, not who's actually in this thread).
  def participant_nicknames
    participants.filter_map { |participant| participant.user_nickname.presence }
  end

  private
    def not_flagged_by_moderation
      result = PostModerator.call(title, content.to_plain_text)
      errors.add(:base, "was flagged as #{result.category} and can't be posted") if result.flagged
    end
end
