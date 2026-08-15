class Post < ApplicationRecord
  has_many :comments, dependent: :destroy
  has_many :votes, dependent: :destroy

  validates :user_id, :user_email, presence: true

  def score
    votes.sum(&:value)
  end

  def vote_by(user)
    votes.find { |vote| vote.user_id == user.id }
  end
end
